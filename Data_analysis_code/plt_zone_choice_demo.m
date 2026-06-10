function fig = plt_zone_choice_demo(fd)
% plot the port choices of a mouse when it arrives first or second
%
% Outputs to base workspace:
%   source_data
%   stats_table

mstable = load([fd 'Data/mstable_phase4a.mat']).mstable;

%% get prop choosing one of the four zones
uni_animals = unique(mstable.animal);
n_uni_animals = length(uni_animals);

n_zones = 4;
zone_choices = nan(n_uni_animals,2,n_zones); % animal x lead condition x zone

for a = 1:n_uni_animals

    cur_animal = uni_animals(a);
    cur_stable = mstable(strcmp(mstable.animal,cur_animal),:);

    cur_id = cur_stable.id{1};
    cur_id_num = str2double(cur_id(2));

    for z = 1:4
        zone_choices(a,1,z) = mean(cur_stable.self_zone(cur_stable.leader==cur_id_num)==z);
        zone_choices(a,2,z) = mean(cur_stable.self_zone(cur_stable.leader==3-cur_id_num)==z);
    end

end

%% source data
zone_names = {'E';'S';'W';'N'};
lead_names = {'SelfLead';'OtherLead'};

source_data = table();

for a = 1:n_uni_animals
    for lead_i = 1:2
        for z = 1:n_zones

            T_source = table( ...
                uni_animals(a), ...
                a, ...
                lead_names(lead_i), ...
                zone_names(z), ...
                zone_choices(a,lead_i,z), ...
                'VariableNames', ...
                {'Animal','AnimalIndex','LeadCondition','Zone','PropChoice'});

            source_data = [source_data; T_source];

        end
    end
end

assignin('base','source_data',source_data);

%% paired bar plot
m_colors = [0.5490 0.3176 0.0392; 0.5 0.5 0.5];

n_est = size(zone_choices,3);
pvals = nan(n_est,3);

fig = figure('Position',[600 300 300 300]);
hold on;

x = 1:n_est;

b = bar(x,squeeze(mean(zone_choices)), ...
    'FaceColor','flat', ...
    'EdgeColor','none', ...
    'GroupWidth',0.8, ...
    'FaceAlpha',0.4); 

b(1).FaceColor = m_colors(1,:);
b(2).FaceColor = m_colors(2,:);

stats_table = table();

for i = 1:n_est

    y = zone_choices(:,:,i);

    h = plot([b(1).XEndPoints(i) b(2).XEndPoints(i)], y', ...
        'LineWidth',1, ...
        'Color',0.4*[1 1 1], ...
        'Marker','.', ...
        'MarkerSize',16);

    for r = 1:2

        yy = y(:,r);
        yy = yy(~isnan(yy));

        if mean(yy) > 0
            errorbar(b(r).XEndPoints(i),mean(yy),[],std(yy)/sqrt(length(yy)), ...
                'Color',m_colors(r,:), ...
                'LineWidth',2);
        else
            errorbar(b(r).XEndPoints(i),mean(yy),std(yy)/sqrt(length(yy)),[], ...
                'Color',m_colors(r,:), ...
                'LineWidth',2);
        end

        [~,p,ci,stats] = ttest(yy);
        pvals(i,r) = p;

        T_stats = table( ...
            zone_names(i), ...
            lead_names(r), ...
            {'one-sample t-test vs 0'}, ...
            length(yy), ...
            mean(yy), ...
            median(yy), ...
            std(yy), ...
            std(yy)/sqrt(length(yy)), ...
            stats.tstat, ...
            stats.df, ...
            p, ...
            ci(1), ...
            ci(2), ...
            'VariableNames', ...
            {'Zone','LeadCondition','Test','N','Mean','Median','SD','SEM', ...
            'TStat','DF','PValue','CI95_Lower','CI95_Upper'});

        stats_table = [stats_table; T_stats];

        fprintf('\n%s | %s\n', zone_names{i}, lead_names{r})
        fprintf('One-sample t-test vs 0: t(%d) = %.4f, p = %.6g\n', ...
            stats.df, stats.tstat, p)
        fprintf('Mean = %.4f, SEM = %.4f, 95%% CI = [%.4f, %.4f]\n', ...
            mean(yy), std(yy)/sqrt(length(yy)), ci(1), ci(2))

    end

    y1 = y(:,1);
    y2 = y(:,2);

    valid = ~isnan(y1) & ~isnan(y2);
    y1 = y1(valid);
    y2 = y2(valid);

    [~,p_pair,ci_pair,stats_pair] = ttest(y1,y2);
    pvals(i,3) = p_pair;

    T_pair = table( ...
        zone_names(i), ...
        {'SelfLead_vs_OtherLead'}, ...
        {'paired t-test'}, ...
        length(y1), ...
        mean(y1-y2), ...
        median(y1-y2), ...
        std(y1-y2), ...
        std(y1-y2)/sqrt(length(y1)), ...
        stats_pair.tstat, ...
        stats_pair.df, ...
        p_pair, ...
        ci_pair(1), ...
        ci_pair(2), ...
        'VariableNames', ...
        {'Zone','LeadCondition','Test','N','Mean','Median','SD','SEM', ...
        'TStat','DF','PValue','CI95_Lower','CI95_Upper'});

    stats_table = [stats_table; T_pair];

    fprintf('\n%s | SelfLead vs OtherLead\n', zone_names{i})
    fprintf('Paired t-test: t(%d) = %.4f, p = %.6g\n', ...
        stats_pair.df, stats_pair.tstat, p_pair)
    fprintf('Mean difference = %.4f, SEM = %.4f, 95%% CI = [%.4f, %.4f]\n', ...
        mean(y1-y2), std(y1-y2)/sqrt(length(y1)), ci_pair(1), ci_pair(2))

end

assignin('base','stats_table',stats_table);

xlim([0.5 n_est+0.5])
xticks(1:n_est);
xticklabels({'E','S','W','N'});

ylabel('Prop choice');

legend(b,{'Self lead','Other lead'},'Location','northeast');
legend box off

box off

ax = gca;
set(ax,'FontSize',18,'TickDir','out');

caption = 'Reward Zone choice when led by self or other';
title(caption,'FontSize',24)

hoy = char(datetime('now','Format','yyyyMMdd'));

figname = [fd 'plots/' hoy '_zone_choice_control'];

print(fig,figname,'-dpdf');

%% repeated-measure ANOVA

data_reshaped = reshape(zone_choices, n_uni_animals, []);

varNames = {};
for dir = 1:4
    for lead = 1:2
        varNames{end+1} = sprintf('Dir%d_Lead%d', dir, lead);
    end
end

T = array2table(data_reshaped, 'VariableNames', varNames);
T.Subject = (1:n_uni_animals)';

Direction = repelem((1:4)', 2);
Lead = repmat((1:2)', 4, 1);

Within = table(categorical(Direction), categorical(Lead), ...
    'VariableNames', {'Direction','Lead'});

rm = fitrm(T, 'Dir1_Lead1-Dir4_Lead2 ~ 1', 'WithinDesign', Within);

ranovatbl = ranova(rm, 'WithinModel', 'Direction*Lead');

disp(ranovatbl);

assignin('base','ranovatbl',ranovatbl);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')
fprintf('ranovatbl\n')

end