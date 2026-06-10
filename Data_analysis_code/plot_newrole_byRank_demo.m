function plot_newrole_byRank_v02(summaryData, fd)
% plot_newrole_byRank_v02
%
% Outputs to base workspace:
%   source_data_newrole_byRank
%   stats_table_newrole_byRank

if nargin < 2 || isempty(fd)
    fd = pwd;
end

fd = char(fd);
fd = regexprep(fd, '[\\/]+$', '');

[~, last_folder] = fileparts(fd);
if strcmpi(last_folder,'plots')
    plot_dir = fd;
else
    plot_dir = fullfile(fd,'plots');
end

if ~exist(plot_dir,'dir')
    mkdir(plot_dir);
end

rk = string(summaryData.rank);
sx = string(summaryData.sex);

hasData   = ~isnan(summaryData.date);
validRank = (rk=="m1") | (rk=="m2");
hasSex    = (sx=="female") | (sx=="male");

use = hasData & validRank & hasSex;
T = summaryData(use,:);

x = nan(height(T),1);
y = nan(height(T),1);
sex = string(T.sex);
role_type = string(T.role_type);

idx_m1 = string(T.rank)=="m1";
idx_m2 = string(T.rank)=="m2";

x(idx_m1) = T.p_ledBy_m1(idx_m1);
y(idx_m1) = T.p_initBy_m1(idx_m1);

x(idx_m2) = T.p_ledBy_m2(idx_m2);
y(idx_m2) = T.p_initBy_m2(idx_m2);

source_data_newrole_byRank = table( ...
    role_type, ...
    sex, ...
    string(T.rank), ...
    x, ...
    y, ...
    x > 0.5, ...
    y > 0.5, ...
    'VariableNames', ...
    {'RoleType','Sex','DominantMouseRank', ...
    'P_ledBy_Dominant','P_initBy_Dominant', ...
    'DominantIsLeader','DominantIsInitiator'});

assignin('base','source_data_newrole_byRank',source_data_newrole_byRank);

stats_table_newrole_byRank = table();

idx_orig = role_type=="original_pair";

[stats_table_newrole_byRank] = add_quadrant_stats( ...
    stats_table_newrole_byRank, ...
    'original training', ...
    x(idx_orig), y(idx_orig), sex(idx_orig));

make_quadrant_scatter_bySex( ...
    x(idx_orig), y(idx_orig), sex(idx_orig), ...
    'original training', ...
    fullfile(plot_dir,'v02_quadrant_original_training_bySex.pdf'));

idx_swap = role_type=="LL_pairing" | role_type=="FF_pairing";

[stats_table_newrole_byRank] = add_quadrant_stats( ...
    stats_table_newrole_byRank, ...
    'swapped training (LL+FF)', ...
    x(idx_swap), y(idx_swap), sex(idx_swap));

make_quadrant_scatter_bySex( ...
    x(idx_swap), y(idx_swap), sex(idx_swap), ...
    'swapped training (LL+FF)', ...
    fullfile(plot_dir,'v02_quadrant_swapped_training_bySex.pdf'));

assignin('base','stats_table_newrole_byRank',stats_table_newrole_byRank);

fprintf('\nNew role by rank quadrant summary\n')
fprintf('========================================\n')
disp(stats_table_newrole_byRank)

fprintf('\nSaved to base workspace:\n')
fprintf('source_data_newrole_byRank\n')
fprintf('stats_table_newrole_byRank\n')

end

function stats_table = add_quadrant_stats(stats_table, group_name, x, y, sex)

ok = ~isnan(x) & ~isnan(y);
x = x(ok);
y = y(ok);
sex = string(sex(ok));

groups = ["all"; "female"; "male"];

for g = 1:numel(groups)

    if groups(g) == "all"
        idx = true(size(x));
    else
        idx = sex == groups(g);
    end

    xx = x(idx);
    yy = y(idx);

    n = numel(xx);

    n_leader = sum(xx > 0.5);
    n_initiator = sum(yy > 0.5);
    n_leader_initiator = sum(xx > 0.5 & yy > 0.5);
    n_leader_responder = sum(xx > 0.5 & yy <= 0.5);
    n_follower_initiator = sum(xx <= 0.5 & yy > 0.5);
    n_follower_responder = sum(xx <= 0.5 & yy <= 0.5);

    if n > 0
        prop_leader = n_leader / n;
        prop_initiator = n_initiator / n;
        prop_leader_initiator = n_leader_initiator / n;
    else
        prop_leader = NaN;
        prop_initiator = NaN;
        prop_leader_initiator = NaN;
    end

    p_leader = NaN;
    p_initiator = NaN;

    if n > 0
        p_leader = 2 * binocdf(min(n_leader,n-n_leader), n, 0.5);
        p_leader = min(p_leader,1);

        p_initiator = 2 * binocdf(min(n_initiator,n-n_initiator), n, 0.5);
        p_initiator = min(p_initiator,1);
    end

    T_stat = table( ...
        {group_name}, ...
        groups(g), ...
        n, ...
        mean(xx,'omitnan'), ...
        median(xx,'omitnan'), ...
        mean(yy,'omitnan'), ...
        median(yy,'omitnan'), ...
        n_leader, ...
        n_initiator, ...
        n_leader_initiator, ...
        n_leader_responder, ...
        n_follower_initiator, ...
        n_follower_responder, ...
        prop_leader, ...
        prop_initiator, ...
        prop_leader_initiator, ...
        p_leader, ...
        p_initiator, ...
        'VariableNames', ...
        {'TrainingType','SexGroup','N', ...
        'MeanPledByDominant','MedianPledByDominant', ...
        'MeanPinitByDominant','MedianPinitByDominant', ...
        'NLeader','NInitiator','NLeaderInitiator', ...
        'NLeaderResponder','NFollowerInitiator','NFollowerResponder', ...
        'PropLeader','PropInitiator','PropLeaderInitiator', ...
        'BinomialP_LeaderVsChance','BinomialP_InitiatorVsChance'});

    stats_table = [stats_table; T_stat];

    fprintf('\n%s | %s\n', group_name, groups(g))
    fprintf('N = %d\n', n)
    fprintf('Dominant leader: %d/%d, p = %.6g\n', n_leader, n, p_leader)
    fprintf('Dominant initiator: %d/%d, p = %.6g\n', n_initiator, n, p_initiator)
    fprintf('Leader+initiator quadrant: %d/%d\n', n_leader_initiator, n)

end

end

function make_quadrant_scatter_bySex(x, y, sex, figTitle, outFile)

sexes = {'female';'male'};
fill_colors = [239,154,154;129, 212, 250]/255;
line_colors = [183, 28, 28;  1, 87, 155]/255;

ok = ~isnan(x) & ~isnan(y);
x = x(ok);
y = y(ok);
sex = string(sex(ok));

n = numel(x);

fig = figure('Color','w','Position',[600 300 330 330]); 
hold on;

for i = 1:numel(sexes)
    s = string(sexes{i});
    idx = (sex == s);

    if any(idx)
        scatter(x(idx), y(idx), 45, ...
            'MarkerFaceColor', fill_colors(i,:), ...
            'MarkerEdgeColor', line_colors(i,:), ...
            'LineWidth', 1);
    end
end

xline(0.5,'--','LineWidth',1.5);
yline(0.5,'--','LineWidth',1.5);

xlim([0 1]); 
ylim([0 1]);

axis square;

xlabel('Prop trials led (dominant)');
ylabel('Prop trials initiated (dominant)');

text(0.25, 1.04, 'Follower', ...
    'HorizontalAlignment','center');

text(0.75, 1.04, 'Leader', ...
    'HorizontalAlignment','center');

text(1.04, 0.75, 'Initiator', ...
    'Rotation',90, ...
    'HorizontalAlignment','center');

text(1.04, 0.25, 'Responder', ...
    'Rotation',90, ...
    'HorizontalAlignment','center');

title(sprintf('%s | n=%d', figTitle, n));

legend(sexes, ...
    'Location','southoutside', ...
    'Orientation','horizontal');

set(gca,'FontSize',18,'TickDir','out');

box off;

set(fig,'PaperPositionMode','auto');

print(fig, outFile, '-dpdf', '-vector');

fprintf('Saved figure: %s\n', outFile)

end