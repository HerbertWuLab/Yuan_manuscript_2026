function plot_ledBy_dot_vs_mouse(criterion_table, radius_cm, metrics, fd, fps)
% plot_ledBy_dot_vs_mouse
%
% Compare ledBy conditions within OP stable:
%   ledBy dot   (leader==1)
%   ledBy mouse (leader==2)
%
% Metrics:
%   'cp_rate' : pair value = MEAN across sessions within pair
%               summary    = MEDIAN across pairs paired-valid only
%   'rt'      : follower RT seconds; ALL trials; computed from stable
%               pair value = MEAN across sessions within pair
%               summary    = MEDIAN across pairs paired-valid only
%
% Outputs to base workspace:
%   source_data
%   stats_table

if nargin < 3 || isempty(metrics)
    metrics = {'cp_rate'};
end

if ischar(metrics) || isstring(metrics)
    metrics = cellstr(metrics);
end

if nargin < 4 || isempty(fd)
    error('Please provide output folder fd.');
end

if nargin < 5 || isempty(fps)
    fps = 30;
end

plot_dir = fullfile(fd, 'plots');

if ~exist(plot_dir, 'dir')
    mkdir(plot_dir);
end

nSession = height(criterion_table);

rt_ledByDot = nan(nSession,1);
rt_ledByMouse = nan(nSession,1);

for s = 1:nSession

    stable0 = criterion_table.stable{s};

    if isempty(stable0) || ~istable(stable0)
        continue
    end

    dot_all = stable0(stable0.leader == 1, :);
    mouse_all = stable0(stable0.leader == 2, :);

    if ~isempty(dot_all)

        if ismember('m2_rt', dot_all.Properties.VariableNames)
            rt_sec = double(dot_all.m2_rt) ./ fps;

        elseif all(ismember({'m2_last_arr','led_init'}, dot_all.Properties.VariableNames))
            rt_sec = (double(dot_all.m2_last_arr) - double(dot_all.led_init)) ./ fps;

        else
            rt_sec = [];
        end

        if ~isempty(rt_sec)
            rt_ledByDot(s) = median(rt_sec, 'omitnan');
        end

    end

    if ~isempty(mouse_all)

        if ismember('m2_rt', mouse_all.Properties.VariableNames)
            rt_sec = double(mouse_all.m2_rt) ./ fps;

        elseif all(ismember({'m2_last_arr','led_init'}, mouse_all.Properties.VariableNames))
            rt_sec = (double(mouse_all.m2_last_arr) - double(mouse_all.led_init)) ./ fps;

        else
            rt_sec = [];
        end

        if ~isempty(rt_sec)
            rt_ledByMouse(s) = median(rt_sec, 'omitnan');
        end

    end

end

G = findgroups(criterion_table.pair);
pair_names = splitapply(@(x) x(1), string(criterion_table.pair), G);

rt_dot_p = splitapply(@(x) mean(x,'omitnan'), rt_ledByDot, G);
rt_mouse_p = splitapply(@(x) mean(x,'omitnan'), rt_ledByMouse, G);

source_data = table();
stats_table = table();

for im = 1:numel(metrics)

    m = lower(string(metrics{im}));

    switch m

        case "cp_rate"

            if ~ismember('cp_rate_ledBy_m1', criterion_table.Properties.VariableNames) || ...
               ~ismember('cp_rate_ledBy_m2', criterion_table.Properties.VariableNames)
                error('criterion_table must contain cp_rate_ledBy_m1 and cp_rate_ledBy_m2.');
            end

            cp_dot_p = splitapply(@(x) mean(x,'omitnan'), criterion_table.cp_rate_ledBy_m1, G);
            cp_mouse_p = splitapply(@(x) mean(x,'omitnan'), criterion_table.cp_rate_ledBy_m2, G);

            temp = [cp_dot_p cp_mouse_p];

            ylab = 'cp_rate (all trials; pair mean of sessions)';
            fname = 'cp_rate_ledBy_dot_vs_mouse_allTrials_pairMeanOfSessions.pdf';

        case "rt"

            temp = [rt_dot_p rt_mouse_p];

            ylab = sprintf('Follower RT (s; all trials; session median; pair mean; %g fps)', fps);
            fname = sprintf('followerRT_s_ledBy_dot_vs_mouse_allTrials_pairMean_%gfps.pdf', fps);

        otherwise

            warning('Unknown metric: %s (skip)', m);
            continue

    end

    valid = ~isnan(temp(:,1)) & ~isnan(temp(:,2));

    temp_valid = temp(valid,:);
    pair_valid = pair_names(valid);

    if any(valid)
        [p,~,stat] = signrank(temp_valid(:,1), temp_valid(:,2));
    else
        p = NaN;
        stat.signedrank = NaN;
        stat.zval = NaN;
    end

    signedrank_stat = NaN;
    zval = NaN;

    if isfield(stat,'signedrank')
        signedrank_stat = stat.signedrank;
    end

    if isfield(stat,'zval')
        zval = stat.zval;
    end

    diff_valid = temp_valid(:,2) - temp_valid(:,1);

    T_source = table( ...
        repmat({char(m)},size(temp_valid,1),1), ...
        pair_valid(:), ...
        (1:size(temp_valid,1))', ...
        temp_valid(:,1), ...
        temp_valid(:,2), ...
        diff_valid, ...
        'VariableNames', ...
        {'Metric','Pair','PairIndex','LedByDot','LedByMouse','Difference_MouseMinusDot'});

    source_data = [source_data; T_source];

    T_stats = table( ...
        {char(m)}, ...
        {'paired Wilcoxon signed-rank'}, ...
        size(temp_valid,1), ...
        median(temp_valid(:,1),'omitnan'), ...
        median(temp_valid(:,2),'omitnan'), ...
        median(diff_valid,'omitnan'), ...
        mean(temp_valid(:,1),'omitnan'), ...
        mean(temp_valid(:,2),'omitnan'), ...
        mean(diff_valid,'omitnan'), ...
        std(temp_valid(:,1),'omitnan'), ...
        std(temp_valid(:,2),'omitnan'), ...
        std(diff_valid,'omitnan'), ...
        std(temp_valid(:,1),'omitnan')/sqrt(size(temp_valid,1)), ...
        std(temp_valid(:,2),'omitnan')/sqrt(size(temp_valid,1)), ...
        std(diff_valid,'omitnan')/sqrt(size(temp_valid,1)), ...
        signedrank_stat, ...
        zval, ...
        p, ...
        'VariableNames', ...
        {'Metric','Test','N', ...
        'Median_LedByDot','Median_LedByMouse','MedianDifference_MouseMinusDot', ...
        'Mean_LedByDot','Mean_LedByMouse','MeanDifference_MouseMinusDot', ...
        'SD_LedByDot','SD_LedByMouse','SDDifference', ...
        'SEM_LedByDot','SEM_LedByMouse','SEMDifference', ...
        'SignedRankStatistic','Z','PValue'});

    stats_table = [stats_table; T_stats];

    fprintf('\n========================================\n')
    fprintf('ledBy dot vs mouse | %s\n', char(m))
    fprintf('========================================\n')
    fprintf('Test: paired Wilcoxon signed-rank test\n')
    fprintf('N pairs = %d\n', size(temp_valid,1))
    fprintf('Median ledBy dot = %.4f\n', median(temp_valid(:,1),'omitnan'))
    fprintf('Median ledBy mouse = %.4f\n', median(temp_valid(:,2),'omitnan'))
    fprintf('Median difference mouse - dot = %.4f\n', median(diff_valid,'omitnan'))
    fprintf('Mean ledBy dot = %.4f\n', mean(temp_valid(:,1),'omitnan'))
    fprintf('Mean ledBy mouse = %.4f\n', mean(temp_valid(:,2),'omitnan'))
    fprintf('Mean difference mouse - dot = %.4f\n', mean(diff_valid,'omitnan'))
    fprintf('Signed-rank statistic = %.4f\n', signedrank_stat)

    if ~isnan(zval)
        fprintf('Z = %.4f\n', zval)
    end

    fprintf('P = %.6g\n', p)

    fig = figure('Position',[600 300 200 400]); 
    hold on;

    color_single = [0.6 0.6 0.6];
    color_med = [0.2 0.2 0.2];

    for i = 1:size(temp,1)
        if any(isnan(temp(i,:)))
            continue
        end

        plot([1 2], temp(i,:), '-', ...
            'Color', color_single, ...
            'LineWidth', 1);
    end

    scatter(ones(size(temp,1),1), temp(:,1), 8, color_single, 'filled');
    scatter(2*ones(size(temp,1),1), temp(:,2), 8, color_single, 'filled');

    y_med = median(temp(valid,:), 1);

    plot([1 2], y_med, '-', ...
        'Color', color_med, ...
        'LineWidth', 3);

    plot([1 2], y_med, '.', ...
        'Color', color_med, ...
        'MarkerSize', 12);

    xlim([0.5 2.5]);

    xticks([1 2]);
    xticklabels({'Mice follow','Mice lead'});

    ylabel(ylab, 'Interpreter','none');

    if m == "cp_rate"
        set(gca, 'YLim', [0 1]);
    end

    box off;

    set(gca,'FontSize',26,'TickDir','out');

    text(1.5, max(temp(valid,:),[],'all','omitnan')*1.05, ...
        sprintf('P = %.2g', p), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',22);

    print(fig, fullfile(plot_dir, fname), '-dpdf', '-vector');

end

assignin('base','source_data',source_data);
assignin('base','stats_table',stats_table);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end