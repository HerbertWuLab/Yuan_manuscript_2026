function plot_leader_trace_vs_follower_trace(criterion_table, metrics, fd)
% plot_leader_trace_vs_follower_trace
%
% Compare trials split by dot-trace source:
%   leader trace   : initiator == leader
%   follower trace : initiator ~= leader
%
% Outputs to base workspace:
%   source_data
%   stats_table

if nargin < 2 || isempty(metrics)
    metrics = {'cp_rate'};
end

if ischar(metrics) || isstring(metrics)
    metrics = cellstr(metrics);
end

if nargin < 3 || isempty(fd)
    error('Please provide output folder fd.');
end

radius_cm = 10;

plot_dir = fullfile(fd, 'plots');

if ~exist(plot_dir, 'dir')
    mkdir(plot_dir);
end

idx = find(~cellfun(@isempty, criterion_table.landmks), 1, 'first');
lm_OP = criterion_table.landmks{idx};

rz_center = pix2cm_landmks([lm_OP.mt; lm_OP.mr; lm_OP.mb; lm_OP.ml], lm_OP);

nSession = height(criterion_table);

cp_leaderTrace_ses = nan(nSession,1);
cp_followerTrace_ses = nan(nSession,1);

p_m1_all_leaderTrace_ses = nan(nSession,1);
p_m1_all_followerTrace_ses = nan(nSession,1);

p_m2_all_leaderTrace_ses = nan(nSession,1);
p_m2_all_followerTrace_ses = nan(nSession,1);

p_m1_corr_leaderTrace_ses = nan(nSession,1);
p_m1_corr_followerTrace_ses = nan(nSession,1);

p_m2_corr_leaderTrace_ses = nan(nSession,1);
p_m2_corr_followerTrace_ses = nan(nSession,1);

visit_m2_leaderTrace_ses = nan(nSession,1);
visit_m2_followerTrace_ses = nan(nSession,1);

visit_m2_all_leaderTrace_ses = nan(nSession,1);
visit_m2_all_followerTrace_ses = nan(nSession,1);

for s = 1:nSession

    stable = criterion_table.stable{s};
    SF_stable = criterion_table.SF_stable{s};

    isLeaderTrace = (SF_stable.initiator == SF_stable.leader);
    isFollowerTrace = ~isLeaderTrace;

    if any(isLeaderTrace)
        cp_leaderTrace_ses(s) = mean(stable.correct(isLeaderTrace), 'omitnan');
        p_m1_all_leaderTrace_ses(s) = mean(stable.leader(isLeaderTrace) == 1, 'omitnan');
        p_m2_all_leaderTrace_ses(s) = mean(stable.leader(isLeaderTrace) == 2, 'omitnan');
    end

    if any(isFollowerTrace)
        cp_followerTrace_ses(s) = mean(stable.correct(isFollowerTrace), 'omitnan');
        p_m1_all_followerTrace_ses(s) = mean(stable.leader(isFollowerTrace) == 1, 'omitnan');
        p_m2_all_followerTrace_ses(s) = mean(stable.leader(isFollowerTrace) == 2, 'omitnan');
    end

    isCorrect = (stable.correct == 1);

    idx_leader_corr = isLeaderTrace & isCorrect;
    idx_follower_corr = isFollowerTrace & isCorrect;

    if any(idx_leader_corr)
        p_m1_corr_leaderTrace_ses(s) = mean(stable.leader(idx_leader_corr) == 1, 'omitnan');
        p_m2_corr_leaderTrace_ses(s) = mean(stable.leader(idx_leader_corr) == 2, 'omitnan');
    end

    if any(idx_follower_corr)
        p_m1_corr_followerTrace_ses(s) = mean(stable.leader(idx_follower_corr) == 1, 'omitnan');
        p_m2_corr_followerTrace_ses(s) = mean(stable.leader(idx_follower_corr) == 2, 'omitnan');
    end

    if any(idx_leader_corr)
        stable_leader_corr = stable(idx_leader_corr, :);
        [Num_visitZs, ~] = count_zone_visits_and_dists(stable_leader_corr, rz_center, radius_cm);
        visit_m2_leaderTrace_ses(s) = mean(Num_visitZs, 'omitnan');
    end

    if any(idx_follower_corr)
        stable_follower_corr = stable(idx_follower_corr, :);
        [Num_visitZs, ~] = count_zone_visits_and_dists(stable_follower_corr, rz_center, radius_cm);
        visit_m2_followerTrace_ses(s) = mean(Num_visitZs, 'omitnan');
    end

    if any(isLeaderTrace)
        stable_leader_all = stable(isLeaderTrace, :);
        [Num_visitZs, ~] = count_zone_visits_and_dists(stable_leader_all, rz_center, radius_cm);
        visit_m2_all_leaderTrace_ses(s) = mean(Num_visitZs, 'omitnan');
    end

    if any(isFollowerTrace)
        stable_follower_all = stable(isFollowerTrace, :);
        [Num_visitZs, ~] = count_zone_visits_and_dists(stable_follower_all, rz_center, radius_cm);
        visit_m2_all_followerTrace_ses(s) = mean(Num_visitZs, 'omitnan');
    end

end

G = findgroups(criterion_table.pair);
pair_names = splitapply(@(x) x(1), string(criterion_table.pair), G);

cp_leader_pair = splitapply(@(x) mean(x,'omitnan'), cp_leaderTrace_ses, G);
cp_follower_pair = splitapply(@(x) mean(x,'omitnan'), cp_followerTrace_ses, G);

p_m1_all_leader_pair = splitapply(@(x) mean(x,'omitnan'), p_m1_all_leaderTrace_ses, G);
p_m1_all_follower_pair = splitapply(@(x) mean(x,'omitnan'), p_m1_all_followerTrace_ses, G);

p_m2_all_leader_pair = splitapply(@(x) mean(x,'omitnan'), p_m2_all_leaderTrace_ses, G);
p_m2_all_follower_pair = splitapply(@(x) mean(x,'omitnan'), p_m2_all_followerTrace_ses, G);

p_m1_corr_leader_pair = splitapply(@(x) mean(x,'omitnan'), p_m1_corr_leaderTrace_ses, G);
p_m1_corr_follower_pair = splitapply(@(x) mean(x,'omitnan'), p_m1_corr_followerTrace_ses, G);

p_m2_corr_leader_pair = splitapply(@(x) mean(x,'omitnan'), p_m2_corr_leaderTrace_ses, G);
p_m2_corr_follower_pair = splitapply(@(x) mean(x,'omitnan'), p_m2_corr_followerTrace_ses, G);

visit_m2_leader_pair = splitapply(@(x) mean(x,'omitnan'), visit_m2_leaderTrace_ses, G);
visit_m2_follower_pair = splitapply(@(x) mean(x,'omitnan'), visit_m2_followerTrace_ses, G);

visit_m2_all_leader_pair = splitapply(@(x) mean(x,'omitnan'), visit_m2_all_leaderTrace_ses, G);
visit_m2_all_follower_pair = splitapply(@(x) mean(x,'omitnan'), visit_m2_all_followerTrace_ses, G);

source_data = table();
stats_table = table();

for im = 1:numel(metrics)

    m = lower(string(metrics{im}));

    switch m

        case "cp_rate"

            temp = [cp_leader_pair, cp_follower_pair];
            ylab = 'cp_rate (all trials)';
            fname = 'cp_rate_leaderTrace_vs_followerTrace.pdf';

        case "p_ledby_m1"

            temp = [p_m1_all_leader_pair, p_m1_all_follower_pair];
            ylab = 'p(followed by m2)(all trials)';
            fname = 'p_followedBy_m2_leaderTrace_vs_followerTrace.pdf';

        case "p_ledby_m2"

            temp = [p_m2_all_leader_pair, p_m2_all_follower_pair];
            ylab = 'p(led by mouse2) (all trials)';
            fname = 'p_ledBy_m2_leaderTrace_vs_followerTrace.pdf';

        case "p_ledby_m1_in_correct"

            temp = [p_m1_corr_leader_pair, p_m1_corr_follower_pair];
            ylab = 'p(led by mouse1) (correct trials)';
            fname = 'p_ledBy_m1_in_correct_leaderTrace_vs_followerTrace.pdf';

        case "p_ledby_m2_in_correct"

            temp = [p_m2_corr_leader_pair, p_m2_corr_follower_pair];
            ylab = 'p(led by mouse2) (correct trials)';
            fname = 'p_ledBy_m2_in_correct_leaderTrace_vs_followerTrace.pdf';

        case "visit_m2"

            temp = [visit_m2_leader_pair, visit_m2_follower_pair];
            ylab = sprintf('zone visits (m2, correct trials), r=%.1f cm', radius_cm);
            fname = sprintf('visit_m2_in_correct_leaderTrace_vs_followerTrace_r%.1f.pdf', radius_cm);

        case "visit_m2_all"

            temp = [visit_m2_all_leader_pair, visit_m2_all_follower_pair];
            ylab = sprintf('zone visits (m2, all trials), r=%.1f cm', radius_cm);
            fname = sprintf('visit_m2_all_leaderTrace_vs_followerTrace_r%.1f.pdf', radius_cm);

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
        {'Metric','Pair','PairIndex', ...
        'LeaderTrace','FollowerTrace','Difference_FollowerMinusLeader'});

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
        'Median_LeaderTrace','Median_FollowerTrace','MedianDifference_FollowerMinusLeader', ...
        'Mean_LeaderTrace','Mean_FollowerTrace','MeanDifference_FollowerMinusLeader', ...
        'SD_LeaderTrace','SD_FollowerTrace','SDDifference', ...
        'SEM_LeaderTrace','SEM_FollowerTrace','SEMDifference', ...
        'SignedRankStatistic','Z','PValue'});

    stats_table = [stats_table; T_stats];

    fprintf('\n========================================\n')
    fprintf('leader trace vs follower trace | %s\n', char(m))
    fprintf('========================================\n')
    fprintf('Test: paired Wilcoxon signed-rank test\n')
    fprintf('N pairs = %d\n', size(temp_valid,1))
    fprintf('Median leader trace = %.4f\n', median(temp_valid(:,1),'omitnan'))
    fprintf('Median follower trace = %.4f\n', median(temp_valid(:,2),'omitnan'))
    fprintf('Median difference follower - leader = %.4f\n', median(diff_valid,'omitnan'))
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

    x1 = ones(size(temp,1),1);
    x2 = 2*ones(size(temp,1),1);

    scatter(x1, temp(:,1), 8, color_single, 'filled');
    scatter(x2, temp(:,2), 8, color_single, 'filled');

    y_med = median(temp, 'omitnan');

    plot([1 2], y_med, '-', ...
        'Color', color_med, ...
        'LineWidth', 3);

    plot([1 2], y_med, '.', ...
        'Color', color_med, ...
        'MarkerSize', 12);

    xlim([0.5 2.5]);

    xticks([1 2]);
    xticklabels({'leader trace','follower trace'});

    ylabel(ylab, 'Interpreter','none');

    if m == "cp_rate"
        ylim([0 1]);
    end

    box off;

    set(gca,'FontSize',26,'TickDir','out');

    text(0.38,0.98,sprintf('P=%.3g',p), ...
         'Units','normalized', ...
         'FontSize',22);

    print(fig, fullfile(plot_dir, fname), '-dpdf', '-vector');

end

assignin('base','source_data',source_data);
assignin('base','stats_table',stats_table);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end