function fig = plt_spd_time_cohort_demo(spd_table,params)
%% plot speed of leader and follower separately per animal
%
% Outputs to base workspace:
%   source_data
%   stats_table

fd = params.fd; 
role = params.role;

hoy = char(datetime('now','Format','yyyyMMdd'));

switch role
    case 'both'
        spd_table_sel_role = spd_table;
        m_colors = [0.5490 0.3176 0.0392; 0.5 0.5 0.5];

    case 'leader'
        spd_table_sel_role = spd_table(strcmp(spd_table.role,'leader'),:);
        m_colors = [0.6000 0.4392 0.6706; 0.5 0.5 0.5];

    case 'follower'
        spd_table_sel_role = spd_table(strcmp(spd_table.role,'follower'),:);
        m_colors = [0.3529 0.6824 0.3804; 0.5 0.5 0.5]; 
end

t_array = 0:30;
t_length = length(t_array);

uni_animals = unique(spd_table_sel_role.animal);
n_uni_animals = length(uni_animals);

spd_self_lead = nan(n_uni_animals,t_length);
spd_other_lead = nan(n_uni_animals,t_length);

for a = 1:n_uni_animals

    cur_animal = uni_animals{a};

    sel_animal = strcmp(spd_table_sel_role.animal,cur_animal);
    spd_table_sel_animal = spd_table_sel_role(sel_animal,:);

    spd_self_lead(a,:) = mean(vertcat(spd_table_sel_animal.self_lead{:}));
    spd_other_lead(a,:) = mean(vertcat(spd_table_sel_animal.other_lead{:}));

end

%% source data
source_data = table();

for a = 1:n_uni_animals

    T_self = table( ...
        repmat({role},t_length,1), ...
        repmat(uni_animals(a),t_length,1), ...
        repmat({'SelfLead'},t_length,1), ...
        t_array(:), ...
        spd_self_lead(a,:)', ...
        'VariableNames', ...
        {'Role','Animal','Condition','Frame','Speed'});

    T_other = table( ...
        repmat({role},t_length,1), ...
        repmat(uni_animals(a),t_length,1), ...
        repmat({'OtherLead'},t_length,1), ...
        t_array(:), ...
        spd_other_lead(a,:)', ...
        'VariableNames', ...
        {'Role','Animal','Condition','Frame','Speed'});

    source_data = [source_data; T_self; T_other];

end

assignin('base','source_data',source_data);

%% pointwise paired t-tests
pvals = nan(t_length,1);
tstats = nan(t_length,1);
dfs = nan(t_length,1);
mean_self = nan(t_length,1);
mean_other = nan(t_length,1);
mean_diff = nan(t_length,1);
sem_self = nan(t_length,1);
sem_other = nan(t_length,1);
sem_diff = nan(t_length,1);

stats_table = table();

for t = 1:t_length

    y1 = spd_self_lead(:,t);
    y2 = spd_other_lead(:,t);

    valid = ~isnan(y1) & ~isnan(y2);
    y1 = y1(valid);
    y2 = y2(valid);

    [~,p,ci,stats] = ttest(y1,y2);

    pvals(t) = p;
    tstats(t) = stats.tstat;
    dfs(t) = stats.df;

    diff_val = y1 - y2;

    mean_self(t) = mean(y1,'omitnan');
    mean_other(t) = mean(y2,'omitnan');
    mean_diff(t) = mean(diff_val,'omitnan');

    sem_self(t) = std(y1,'omitnan')/sqrt(length(y1));
    sem_other(t) = std(y2,'omitnan')/sqrt(length(y2));
    sem_diff(t) = std(diff_val,'omitnan')/sqrt(length(diff_val));

    T_stat = table( ...
        {role}, ...
        t_array(t), ...
        length(y1), ...
        mean_self(t), ...
        mean_other(t), ...
        mean_diff(t), ...
        sem_self(t), ...
        sem_other(t), ...
        sem_diff(t), ...
        stats.tstat, ...
        stats.df, ...
        p, ...
        ci(1), ...
        ci(2), ...
        'VariableNames', ...
        {'Role','Frame','N','MeanSelfLead','MeanOtherLead','MeanDifference', ...
        'SEMSelfLead','SEMOtherLead','SEMDifference', ...
        'TStat','DF','PValue','CI95_Lower','CI95_Upper'});

    stats_table = [stats_table; T_stat];

end

%% plot
fig = figure('Position',[500 500 400 400]);
hold on;

for a = 1:n_uni_animals
    h1 = plot(t_array,spd_self_lead(a,:), ...
        'Color',[m_colors(1,:) 0.5], ...
        'LineWidth',2);

    h2 = plot(t_array,spd_other_lead(a,:), ...
        'Color',[m_colors(2,:) 0.5], ...
        'LineWidth',2);
end

xticks(0:15:30)
xticklabels(0:0.5:1)

axis padded

xlabel('Time from arrival (s)')
ylabel('Speed (cm/s)')

legend([h1 h2], ...
    {['Self lead (' num2str(n_uni_animals) ' animals)'], ...
    ['Other lead (' num2str(n_uni_animals) ' animals)']}, ...
    'Location','northeast');

legend boxoff

caption = 'Speed at arrival';
title(caption);

set(gca,'FontSize',24,'TickDir','out')

figname = [fd '/plots/' hoy 'p_arrival_spd_' role];
print(fig,figname,'-dpdf');

%% stats for speed difference: linear mixed-effects model
n_animals = size(spd_self_lead, 1);
n_timepoints = size(spd_self_lead, 2);

speed = [spd_self_lead(:); spd_other_lead(:)];

condition = [repmat({'Self'}, n_animals * n_timepoints, 1); ...
             repmat({'Other'}, n_animals * n_timepoints, 1)];

subject_ids = repmat((1:n_animals)', n_timepoints, 1);
subject = repmat(subject_ids, 2, 1);

frame_vector = repmat(0:(n_timepoints-1), n_animals, 1);
frame = repmat(frame_vector(:), 2, 1);

tbl = table(speed, categorical(condition), frame, categorical(subject), ...
            'VariableNames', {'Speed', 'Condition', 'Frame', 'Subject'});

lme = fitlme(tbl, 'Speed ~ Condition + Frame + (1|Subject)');

disp(lme)

lme_coef = lme.Coefficients;

fprintf('\n========================================\n')
fprintf('Speed over time | %s\n', role)
fprintf('========================================\n')
fprintf('Linear mixed-effects model:\n')
fprintf('Speed ~ Condition + Frame + (1|Subject)\n')
fprintf('N animals = %d\n', n_animals)
fprintf('N observations = %d\n\n', height(tbl))
disp(lme_coef)

lme_stats = table( ...
    repmat({role},height(lme_coef),1), ...
    lme_coef.Name, ...
    lme_coef.Estimate, ...
    lme_coef.SE, ...
    lme_coef.tStat, ...
    lme_coef.DF, ...
    lme_coef.pValue, ...
    lme_coef.Lower, ...
    lme_coef.Upper, ...
    'VariableNames', ...
    {'Role','Term','Estimate','SE','TStat','DF','PValue','Lower','Upper'});

stats_table.LME_Term = repmat({''},height(stats_table),1);
stats_table.LME_Estimate = nan(height(stats_table),1);
stats_table.LME_SE = nan(height(stats_table),1);
stats_table.LME_TStat = nan(height(stats_table),1);
stats_table.LME_DF = nan(height(stats_table),1);
stats_table.LME_PValue = nan(height(stats_table),1);
stats_table.LME_Lower = nan(height(stats_table),1);
stats_table.LME_Upper = nan(height(stats_table),1);

assignin('base','stats_table',stats_table);
assignin('base','lme_stats_table',lme_stats);
assignin('base','lme_model',lme);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')
fprintf('lme_stats_table\n')
fprintf('lme_model\n')

end