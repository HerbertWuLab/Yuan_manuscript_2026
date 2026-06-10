function fig = plt_prop_spatial_selectivity_med(prop_table,params)
% plot proportion of cells selective for self, other, other_allo and
% other_ego frame of reference, by each recorded animal
%
% Outputs to base workspace:
%   source_data
%   stats_table

%% params
phase = params.phase;
fd = params.fd;

idx_pos = {'p_self';'p_other';'p_other_allo';'p_other_ego'};
positions = {'Allo self','Allo other','Ego other w/o HD','Ego other w/ HD'};

prop_lead = table2array(prop_table(strcmp(prop_table.role,'leader'),idx_pos));
prop_foll = table2array(prop_table(strcmp(prop_table.role,'follower'),idx_pos));

prop_med = [median(prop_lead,'omitnan'); median(prop_foll,'omitnan')];

%% source data
source_data = table();

for i = 1:length(idx_pos)

    y_lead = prop_lead(:,i);
    y_foll = prop_foll(:,i);

    T_lead = table( ...
        repmat({'leader'},length(y_lead),1), ...
        repmat(idx_pos(i),length(y_lead),1), ...
        repmat(positions(i),length(y_lead),1), ...
        (1:length(y_lead))', ...
        y_lead, ...
        'VariableNames', ...
        {'Role','Measure','Position','AnimalIndex','Proportion'});

    T_foll = table( ...
        repmat({'follower'},length(y_foll),1), ...
        repmat(idx_pos(i),length(y_foll),1), ...
        repmat(positions(i),length(y_foll),1), ...
        (1:length(y_foll))', ...
        y_foll, ...
        'VariableNames', ...
        {'Role','Measure','Position','AnimalIndex','Proportion'});

    source_data = [source_data; T_lead; T_foll];

end

assignin('base','source_data',source_data);

%% plot
m_colors = [194, 165, 207; 166, 219, 160] / 255;

fig = figure('Position',[600 300 250 400]);
hold on;

x = 1:4;

b = bar(x,prop_med, ...
    'FaceColor','none', ...
    'GroupWidth',0.8, ...
    'LineWidth',1); 

b(1).EdgeColor = m_colors(1,:);
b(2).EdgeColor = m_colors(2,:);

stats_table = table();

for i = 1:length(idx_pos)

    y_lead = prop_lead(:,i);
    y_foll = prop_foll(:,i);

    x_lead = b(1).XEndPoints(i) * ones(size(y_lead));
    s(1) = scatter(x_lead,y_lead,50, ...
        'MarkerFaceColor',m_colors(1,:), ...
        'MarkerEdgeColor','k', ...
        'LineWidth',0.1);

    x_foll = b(2).XEndPoints(i) * ones(size(y_foll));
    s(2) = scatter(x_foll,y_foll,50, ...
        'MarkerFaceColor',m_colors(2,:), ...
        'MarkerEdgeColor','k', ...
        'LineWidth',0.1);

    valid_lead = ~isnan(y_lead);
    valid_foll = ~isnan(y_foll);

    y_lead_valid = y_lead(valid_lead);
    y_foll_valid = y_foll(valid_foll);

    [p,~,stats] = ranksum(y_lead_valid,y_foll_valid);

    ranksum_stat = NaN;
    zval = NaN;

    if isfield(stats,'ranksum')
        ranksum_stat = stats.ranksum;
    end

    if isfield(stats,'zval')
        zval = stats.zval;
    end

    fprintf('\n========================================\n')
    fprintf('%s\n', positions{i})
    fprintf('========================================\n')
    fprintf('Test: Wilcoxon rank-sum test, leader vs follower\n')
    fprintf('N leader = %d\n', length(y_lead_valid))
    fprintf('N follower = %d\n', length(y_foll_valid))
    fprintf('Leader median = %.4f\n', median(y_lead_valid,'omitnan'))
    fprintf('Follower median = %.4f\n', median(y_foll_valid,'omitnan'))
    fprintf('Leader mean = %.4f\n', mean(y_lead_valid,'omitnan'))
    fprintf('Follower mean = %.4f\n', mean(y_foll_valid,'omitnan'))
    fprintf('Ranksum statistic = %.4f\n', ranksum_stat)
    if ~isnan(zval)
        fprintf('Z = %.4f\n', zval)
    end
    fprintf('P = %.6g\n', p)

    T_stat = table( ...
        idx_pos(i), ...
        positions(i), ...
        {'leader_vs_follower'}, ...
        {'ranksum'}, ...
        length(y_lead_valid), ...
        length(y_foll_valid), ...
        median(y_lead_valid,'omitnan'), ...
        median(y_foll_valid,'omitnan'), ...
        mean(y_lead_valid,'omitnan'), ...
        mean(y_foll_valid,'omitnan'), ...
        ranksum_stat, ...
        zval, ...
        p, ...
        'VariableNames', ...
        {'Measure','Position','Comparison','Test', ...
        'NLeader','NFollower', ...
        'MedianLeader','MedianFollower', ...
        'MeanLeader','MeanFollower', ...
        'RankSumStatistic','Z','PValue'});

    stats_table = [stats_table; T_stat];

    text(i,0.23,sprintf('P=%.2g', p), ...
        'HorizontalAlignment','center', ...
        'Units','data', ...
        'FontSize',18)

end

assignin('base','stats_table',stats_table);

xlim([0.5 4.5])
xticks(1:4);
xticklabels(positions);

ylabel('Proportion');

legend(s,{'Leader','Follower'},'Location','north');
legend box off

box off

set(gca,'FontSize',24,'TickDir','out');

caption = 'Spatially selective cells';
title(caption,'FontSize',24)

hoy = char(datetime('now','Format','yyyyMMdd'));

figname = [fd 'plots/' hoy 'p_prop_spatial_selective_' phase];

print(fig,figname,'-dpdf');

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

%% ego vs allo
[p,h,stats] = signrank(prop_table.p_other_ego,...
                       prop_table.p_other_allo);

n = sum(~isnan(prop_table.p_other_ego) & ...
        ~isnan(prop_table.p_other_allo));

fprintf('\n===== Ego vs Allo =====\n');
fprintf('N = %d animals\n', n);
fprintf('Median ego  = %.4f\n', ...
    median(prop_table.p_other_ego,'omitnan'));
fprintf('Median allo = %.4f\n', ...
    median(prop_table.p_other_allo,'omitnan'));
fprintf('signrank statistic = %.1f\n', stats.signedrank);
fprintf('p = %.4g\n', p);
fprintf('=======================\n');


%% ego vs other
[p,h,stats] = signrank(prop_table.p_other_ego,...
                       prop_table.p_other);

n = sum(~isnan(prop_table.p_other_ego) & ...
        ~isnan(prop_table.p_other));

fprintf('\n===== Ego vs Other =====\n');
fprintf('N = %d animals\n', n);
fprintf('Median ego   = %.4f\n', ...
    median(prop_table.p_other_ego,'omitnan'));
fprintf('Median other = %.4f\n', ...
    median(prop_table.p_other,'omitnan'));
fprintf('signrank statistic = %.1f\n', stats.signedrank);
fprintf('p = %.4g\n', p);
fprintf('========================\n');

end