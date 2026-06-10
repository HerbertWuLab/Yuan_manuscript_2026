function plot_cprate_indiv(ltable, fd, maxDays)
% Plot individual-pair curves (long table), style matched to your example.
% Lines only (no markers).
% Colors:
%   leader:   #9970ab
%   follower: #58ae5f

if nargin < 3 || isempty(maxDays), maxDays = 25; end

leaderColor   = [153 112 171] / 255;   % #9970ab
followerColor = [88 174 95]  / 255;    % #58ae5f

pair = ltable.pair;
if iscategorical(pair), pair = cellstr(pair); end
if isstring(pair), pair = cellstr(pair); end

pairs = unique(pair, 'stable');
num_pairs = numel(pairs);

source_data = table();

figure('Position',[600 300 200 300]); 
hold on;

for i = 1:num_pairs
    idx = strcmp(pair, pairs{i});

    yL = ltable.cp_rate_ledBy_sLead(idx); 
    yL = yL(:);

    yF = ltable.cp_rate_ledBy_sFoll(idx); 
    yF = yF(:);

    n = min([numel(yL), numel(yF), maxDays]);
    if n < 1, continue; end

    x = 1:n;

    T_leader = table( ...
        repmat(pairs(i),n,1), ...
        repmat(i,n,1), ...
        x(:), ...
        repmat({'LedByLeader'},n,1), ...
        yL(1:n), ...
        'VariableNames', ...
        {'Pair','PairIndex','TrainingDay','Condition','CooperationRate'});

    T_follower = table( ...
        repmat(pairs(i),n,1), ...
        repmat(i,n,1), ...
        x(:), ...
        repmat({'LedByFollower'},n,1), ...
        yF(1:n), ...
        'VariableNames', ...
        {'Pair','PairIndex','TrainingDay','Condition','CooperationRate'});

    source_data = [source_data; T_leader; T_follower];

    plot(x, yL(1:n), 'LineWidth', 1, 'Color', leaderColor);
    plot(x, yF(1:n), 'LineWidth', 1, 'Color', followerColor);
end

assignin('base','source_data',source_data);

stats_table = table();

conditions = {'LedByLeader';'LedByFollower'};

for c = 1:length(conditions)

    cur_condition = conditions{c};
    cur_data = source_data(strcmp(source_data.Condition,cur_condition),:);

    days = unique(cur_data.TrainingDay);

    for d = 1:length(days)

        cur_day = days(d);
        vals = cur_data.CooperationRate(cur_data.TrainingDay==cur_day);
        vals = vals(~isnan(vals));

        if isempty(vals)
            continue
        end

        T_stat = table( ...
            {cur_condition}, ...
            cur_day, ...
            length(vals), ...
            mean(vals,'omitnan'), ...
            median(vals,'omitnan'), ...
            std(vals,'omitnan'), ...
            std(vals,'omitnan')/sqrt(length(vals)), ...
            'VariableNames', ...
            {'Condition','TrainingDay','N', ...
            'Mean','Median','SD','SEM'});

        stats_table = [stats_table; T_stat];

    end
end

assignin('base','stats_table',stats_table);

fprintf('\nCooperation rate individual curves\n')
fprintf('N pairs = %d\n', num_pairs)
fprintf('Max days plotted = %d\n', maxDays)
fprintf('\nSummary by condition/day saved in stats_table\n')
disp(stats_table)

yline(0.8, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5);

xlim([0.5 maxDays+0.5]);
xlabel('Training day');
ylabel('Cooperation rate');
title('Cooperation rate across training days (individual pairs)');

hL = plot(nan, nan, '-', 'LineWidth', 2, 'Color', leaderColor);
hF = plot(nan, nan, '-', 'LineWidth', 2, 'Color', followerColor);
legend([hL hF], {'Led by leader','Led by follower'}, 'Location','best');

ylim([0 1]);
yticks(0:0.5:1);

set(gca,'FontSize',18,'TickDir','out');
box off;

if ~isempty(fd)
    filename = fullfile(fd, 'cooperation_rate_individual_pairs.pdf');
    print(gcf, filename, '-dpdf', '-painters');
end

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end