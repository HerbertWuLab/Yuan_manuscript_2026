function plot_samerole_pairing_demo(note_table, fd, sexTag)
% plot_samerole_pairing
%
% Outputs to base workspace:
%   source_data_samerole_pairing
%   stats_table_samerole_pairing

if nargin < 3 || isempty(sexTag)
    sexTag = 'all';
end

sexTag = lower(string(sexTag));

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

groups_females = {
    'T2321T2322', 'T2322T2323', 'T2323T2324', 'T2321T2324';
    'TY001TY002', 'TY003TY004', 'TY001TY003', 'TY002TY004';
    'YC159YC160', 'YC161YC162', 'YC159YC162', 'YC161YC160';
    'AK118AK119', 'AK118AK121', 'AK120AK119', 'AK120AK121';
    'AS001AS002', 'AS001AS003', 'AS002AS004', 'AS003AS004'
    };

groups_males = {
    'YC191YC192', 'YC191YC194', 'YC193YC192', 'YC193YC194';
    'YC199YC200', 'YC199YC202', 'YC201YC200', 'YC201YC202';
    'YC207YC208', 'YC207YC210', 'YC209YC208', 'YC209YC210'
    };

if sexTag == "female"
    groups = groups_females;
elseif sexTag == "male"
    groups = groups_males;
elseif sexTag == "all"
    groups = [groups_females; groups_males];
else
    error('sexTag must be ''female'', ''male'', or ''all''.');
end

n_group = size(groups, 1);

fig = figure('Position', [100 100 400 400]);
ax = axes('Position', [0.15 0.15 0.7 0.7]);
hold on;

axis([0 1 0 1]);
grid off;
box on;

xlabel('p\_ledBy\_m1');
ylabel('p\_ledBy\_m2');

set(gca, ...
    'TickDir', 'out', ...
    'XTick', 0:0.5:1, ...
    'YTick', 0:0.5:1, ...
    'FontSize',20);

colors = {[153, 112, 171]/255, [90, 174, 97]/255};

plot([0 1], [1 0], '--r', 'LineWidth', 1.5);
plot([0.5 0.5], [0 1], ':k', 'LineWidth', 1);
plot([0 1], [0.5 0.5], ':k', 'LineWidth', 1);

data2norm = @(x, y) [ ...
    (x - ax.XLim(1)) / (ax.XLim(2) - ax.XLim(1)) * ax.Position(3) + ax.Position(1), ...
    (y - ax.YLim(1)) / (ax.YLim(2) - ax.YLim(1)) * ax.Position(4) + ax.Position(2)];

source_data_samerole_pairing = table();

leader_shift = [];
follower_shift = [];

for g = 1:n_group

    current_pairs = groups(g, :);

    s_range = false(height(note_table), 1);

    for i = 1:length(current_pairs)
        s_range = s_range | contains(note_table.pair, current_pairs{i});
    end

    data = note_table(s_range, :);

    need_types = {'original_pair','LL_pairing','FF_pairing'};

    if ~all(ismember(need_types, unique(data.role_type)))
        warning('Skip group %d: missing role_type rows (sex=%s).', g, sexTag);
        continue;
    end

    original_Lead = data(strcmp(data.role_type, 'original_pair'), :).p_ledBy_sLead;
    original_Foll = data(strcmp(data.role_type, 'original_pair'), :).p_ledBy_sFoll;

    p_LL = [ ...
        data(strcmp(data.role_type, 'LL_pairing'), :).p_ledBy_sLead; ...
        data(strcmp(data.role_type, 'LL_pairing'), :).p_ledBy_sFoll];

    p_FF = [ ...
        data(strcmp(data.role_type, 'FF_pairing'), :).p_ledBy_sLead; ...
        data(strcmp(data.role_type, 'FF_pairing'), :).p_ledBy_sFoll];

    start_points = [original_Lead(1), original_Lead(2); ...
        original_Foll(1), original_Foll(2)];

    end_points = [p_LL(1), p_LL(2); ...
        p_FF(1), p_FF(2)];

    tmp = table( ...
        repmat({char(sexTag)},2,1), ...
        repmat(g,2,1), ...
        ["Leader"; "Follower"], ...
        start_points(:,1), ...
        start_points(:,2), ...
        end_points(:,1), ...
        end_points(:,2), ...
        end_points(:,1)-start_points(:,1), ...
        end_points(:,2)-start_points(:,2), ...
        'VariableNames', ...
        {'SexGroup','Group','Role', ...
        'Start_X','Start_Y', ...
        'End_X','End_Y', ...
        'Delta_X','Delta_Y'});

    source_data_samerole_pairing = [source_data_samerole_pairing; tmp];

    leader_shift = [leader_shift; ...
        sqrt(sum((end_points(1,:) - start_points(1,:)).^2))];

    follower_shift = [follower_shift; ...
        sqrt(sum((end_points(2,:) - start_points(2,:)).^2))];

    for i = 1:2

        start_norm = data2norm(start_points(i,1), start_points(i,2));
        end_norm = data2norm(end_points(i,1), end_points(i,2));

        annotation('arrow', ...
            [start_norm(1), end_norm(1)], ...
            [start_norm(2), end_norm(2)], ...
            'Color', colors{i}, ...
            'LineWidth', 2, ...
            'HeadWidth', 10, ...
            'HeadLength', 10);

        plot(start_points(i,1), start_points(i,2), 'o', ...
            'Color', colors{i}, ...
            'LineWidth', 2, ...
            'MarkerSize', 8, ...
            'MarkerFaceColor', 'w');
    end
end

h_arrow(1) = plot(nan, nan, '-', ...
    'Color', colors{1}, ...
    'LineWidth', 2, ...
    'DisplayName', 'swapped Leader');

h_arrow(2) = plot(nan, nan, '-', ...
    'Color', colors{2}, ...
    'LineWidth', 2, ...
    'DisplayName', 'swapped Follower');

h_circle(1) = plot(nan, nan, 'o', ...
    'Color', colors{1}, ...
    'LineWidth', 2, ...
    'MarkerSize', 8, ...
    'MarkerFaceColor', 'w', ...
    'DisplayName', 'original Leader');

h_circle(2) = plot(nan, nan, 'o', ...
    'Color', colors{2}, ...
    'LineWidth', 2, ...
    'MarkerSize', 8, ...
    'MarkerFaceColor', 'w', ...
    'DisplayName', 'original Follower');

legend([h_arrow, h_circle], 'Location', 'best');

hoy = char(datetime('now','Format','yyyyMMdd'));

figname = fullfile(plot_dir,[hoy '_LLFF_pairing_' char(sexTag)]);

print(fig, figname, '-dpdf');

[p_shift,h_shift,stats_shift] = ranksum(leader_shift,follower_shift);

rank_stat = NaN;
zval = NaN;

if isfield(stats_shift,'ranksum')
    rank_stat = stats_shift.ranksum;
end

if isfield(stats_shift,'zval')
    zval = stats_shift.zval;
end

stats_table_samerole_pairing = table( ...
    {char(sexTag)}, ...
    numel(leader_shift), ...
    numel(follower_shift), ...
    mean(leader_shift,'omitnan'), ...
    median(leader_shift,'omitnan'), ...
    mean(follower_shift,'omitnan'), ...
    median(follower_shift,'omitnan'), ...
    rank_stat, ...
    zval, ...
    p_shift, ...
    h_shift, ...
    'VariableNames', ...
    {'SexGroup','NLeader','NFollower', ...
    'LeaderShiftMean','LeaderShiftMedian', ...
    'FollowerShiftMean','FollowerShiftMedian', ...
    'RankSumStatistic','Z','PValue','RejectH'});

fprintf('\n========================================\n')
fprintf('Same-role pairing | %s\n', char(sexTag))
fprintf('========================================\n')

fprintf('Figure saved: %s\n', figname)

fprintf('Leader shift:\n')
fprintf('N = %d\n', numel(leader_shift))
fprintf('Mean = %.4f\n', mean(leader_shift,'omitnan'))
fprintf('Median = %.4f\n\n', median(leader_shift,'omitnan'))

fprintf('Follower shift:\n')
fprintf('N = %d\n', numel(follower_shift))
fprintf('Mean = %.4f\n', mean(follower_shift,'omitnan'))
fprintf('Median = %.4f\n\n', median(follower_shift,'omitnan'))

fprintf('Ranksum test\n')
fprintf('Statistic = %.4f\n', rank_stat)
if ~isnan(zval)
    fprintf('Z = %.4f\n', zval)
end
fprintf('P = %.6g\n', p_shift)
fprintf('Reject H = %d\n', h_shift)

assignin('base','source_data_samerole_pairing',source_data_samerole_pairing);
assignin('base','stats_table_samerole_pairing',stats_table_samerole_pairing);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data_samerole_pairing\n')
fprintf('stats_table_samerole_pairing\n')

end