function op_table = comparision_OP_SF_cohort(ltable, fd)
% comparision_OP_SF_cohort
% Outputs to base workspace:
%   source_data
%   stats_table

%% ---------- output directory ----------
plot_dir = fullfile(fd, 'plots');
if ~exist(plot_dir, 'dir')
    mkdir(plot_dir);
end

%% ---------- load dsp_table ----------
dsp_path = fullfile(fd, 'data/trajectory_replay', 'dsp_table.mat');
S = load(dsp_path);

if ~isfield(S, 'dsp_table')
    error('dsp_table not found in %s', dsp_path);
end

dsp_table = S.dsp_table;

%% ---------- sanity checks ----------
if ~istable(ltable)
    error('ltable must be a table.');
end

reqVars = {'at_crit','pair'};
missing = setdiff(reqVars, ltable.Properties.VariableNames);

if ~isempty(missing)
    error('ltable is missing variables: %s', strjoin(missing, ', '));
end

%% ---------- filter criterion_table ----------
criterion_table = ltable(ltable.at_crit > 0, :);

%% ---------- metrics ----------
targetCols = {'p_ledBy_sLead','cp_rate_ledBy_sFoll','cp_rate_ledBy_sLead'};

missing = setdiff([{'pair'}, targetCols], criterion_table.Properties.VariableNames);

if ~isempty(missing)
    error('criterion_table is missing columns: %s', strjoin(missing, ', '));
end

%% ---------- build op_table ----------
T = criterion_table(:, [{'pair'}, targetCols]);
T.pair = string(T.pair);

op_table = groupsummary(T, "pair", @(x) mean(x, 'omitnan'), targetCols);

vn = string(op_table.Properties.VariableNames);
for i = 1:numel(targetCols)
    vn(vn == "fun1_" + targetCols{i}) = targetCols{i};
end
op_table.Properties.VariableNames = cellstr(vn);

%% ---------- check dsp_table ----------
missingDSP = setdiff(targetCols, dsp_table.Properties.VariableNames);

if ~isempty(missingDSP)
    error('dsp_table is missing columns: %s', strjoin(missingDSP, ', '));
end

%% ---------- labels ----------
metricLabelMap = containers.Map;

metricLabelMap('p_ledBy_sLead') = ...
    'prop trials of follower follows';

metricLabelMap('cp_rate_ledBy_sLead') = ...
    'correct rate in trials of followers follow';

metricLabelMap('cp_rate_ledBy_sFoll') = ...
    'correct rate in trials of followers lead';

%% ---------- initialize source data and stats ----------
source_data = table();
stats_table = table();

%% ---------- plotting ----------
xLabels = {'traj replay','social foraging'};

color_single = [0.6 0.6 0.6];
color_bar = [0 0 0];

jitterWidth = 0.15;
markerSize = 10;

for i = 1:numel(targetCols)

    m = targetCols{i};
    ylab = metricLabelMap(m);

    y_op = op_table.(m);
    y_dsp = dsp_table.(m);

    pair_op = string(op_table.pair);

    if ismember('pair', dsp_table.Properties.VariableNames)
        pair_dsp = string(dsp_table.pair);
    else
        pair_dsp = strings(height(dsp_table),1);
    end

    valid_op = ~isnan(y_op);
    valid_dsp = ~isnan(y_dsp);

    y_op_valid = y_op(valid_op);
    y_dsp_valid = y_dsp(valid_dsp);

    pair_op_valid = pair_op(valid_op);
    pair_dsp_valid = pair_dsp(valid_dsp);

    mu_op = mean(y_op_valid,'omitnan');
    mu_dsp = mean(y_dsp_valid,'omitnan');

    med_op = median(y_op_valid,'omitnan');
    med_dsp = median(y_dsp_valid,'omitnan');

    sd_op = std(y_op_valid,'omitnan');
    sd_dsp = std(y_dsp_valid,'omitnan');

    sem_op = sd_op / sqrt(numel(y_op_valid));
    sem_dsp = sd_dsp / sqrt(numel(y_dsp_valid));

    %% ---------- source data ----------
    T_op = table( ...
        repmat({'OP'},numel(y_op_valid),1), ...
        repmat({m},numel(y_op_valid),1), ...
        repmat({ylab},numel(y_op_valid),1), ...
        pair_op_valid, ...
        (1:numel(y_op_valid))', ...
        y_op_valid, ...
        'VariableNames', ...
        {'Group','Metric','MetricLabel','Pair','Index','Value'});

    T_dsp = table( ...
        repmat({'SF'},numel(y_dsp_valid),1), ...
        repmat({m},numel(y_dsp_valid),1), ...
        repmat({ylab},numel(y_dsp_valid),1), ...
        pair_dsp_valid, ...
        (1:numel(y_dsp_valid))', ...
        y_dsp_valid, ...
        'VariableNames', ...
        {'Group','Metric','MetricLabel','Pair','Index','Value'});

    source_data = [source_data; T_op; T_dsp];

    %% ---------- stats ----------
    [p,~,stats] = ranksum(y_op_valid, y_dsp_valid);

    ranksum_stat = NaN;
    zval = NaN;

    if isfield(stats,'ranksum')
        ranksum_stat = stats.ranksum;
    end

    if isfield(stats,'zval')
        zval = stats.zval;
    end

    fprintf('\n========================================\n')
    fprintf('%s\n', m)
    fprintf('========================================\n')
    fprintf('Test: Wilcoxon rank-sum test, OP vs SF\n')
    fprintf('N OP = %d\n', numel(y_op_valid))
    fprintf('N SF = %d\n\n', numel(y_dsp_valid))

    fprintf('OP mean = %.4f\n', mu_op)
    fprintf('SF mean = %.4f\n', mu_dsp)
    fprintf('Mean difference OP - SF = %.4f\n\n', mu_op - mu_dsp)

    fprintf('OP median = %.4f\n', med_op)
    fprintf('SF median = %.4f\n', med_dsp)
    fprintf('Median difference OP - SF = %.4f\n\n', med_op - med_dsp)

    fprintf('OP SD = %.4f\n', sd_op)
    fprintf('SF SD = %.4f\n', sd_dsp)
    fprintf('OP SEM = %.4f\n', sem_op)
    fprintf('SF SEM = %.4f\n\n', sem_dsp)

    fprintf('Ranksum statistic = %.4f\n', ranksum_stat)
    if ~isnan(zval)
        fprintf('Z = %.4f\n', zval)
    end
    fprintf('P = %.6g\n', p)

    T_stats = table( ...
        {m}, ...
        {ylab}, ...
        {'OP_vs_SF'}, ...
        {'ranksum'}, ...
        numel(y_op_valid), ...
        numel(y_dsp_valid), ...
        mu_op, ...
        mu_dsp, ...
        mu_op - mu_dsp, ...
        med_op, ...
        med_dsp, ...
        med_op - med_dsp, ...
        sd_op, ...
        sd_dsp, ...
        sem_op, ...
        sem_dsp, ...
        ranksum_stat, ...
        zval, ...
        p, ...
        'VariableNames', ...
        {'Metric','MetricLabel','Comparison','Test', ...
        'N_OP','N_SF', ...
        'Mean_OP','Mean_SF','MeanDifference_OP_minus_SF', ...
        'Median_OP','Median_SF','MedianDifference_OP_minus_SF', ...
        'SD_OP','SD_SF','SEM_OP','SEM_SF', ...
        'RankSumStatistic','Z','PValue'});

    stats_table = [stats_table; T_stats];

    %% ---------- plot ----------
    figure('Position',[600 300 280 400]);
    hold on;

    b = bar([1 2], [med_op med_dsp]);
    b.FaceColor = 'none';
    b.EdgeColor = color_bar;
    b.LineWidth = 2;

    x1 = 1 + (rand(size(y_op_valid)) - 0.5) * jitterWidth;
    x2 = 2 + (rand(size(y_dsp_valid)) - 0.5) * jitterWidth;

    scatter(x1, y_op_valid, markerSize, ...
        'filled', ...
        'MarkerFaceColor', color_single);

    scatter(x2, y_dsp_valid, markerSize, ...
        'filled', ...
        'MarkerFaceColor', color_single);

    xlim([0.5 2.5]);
    ylim([0 1]);

    xticks([1 2]);
    xticklabels(xLabels);

    ylabel(ylab, 'Interpreter','none');
    box off;

    text(0.38, 0.98, sprintf('P=%.2g', p), ...
        'Units','normalized', ...
        'FontSize',28);

    set(gca,'FontSize',32,'TickDir','out');

    dateStr = datestr(now,'yyyymmdd');

    safeName = regexprep(m, '[^a-zA-Z0-9_]', '');

    out_pdf = fullfile(plot_dir, ...
        sprintf('OPvsSF_%s_%s.pdf', safeName, dateStr));

    print(gcf, out_pdf, '-dpdf', '-painters');

end

%% ---------- send to base workspace ----------
assignin('base','source_data',source_data);
assignin('base','stats_table',stats_table);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end