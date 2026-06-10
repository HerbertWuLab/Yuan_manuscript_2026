function compare_correct_rate(criterion_table, pool_table, fd)
% COMPARE_CORRECT_RATE
% Compare OP session-level correct rate against a pooled SF reference.
%
% Outputs to base workspace:
%   source_data
%   stats_table

%% ---------- output directory ----------
plot_dir = fullfile(fd, 'plots');
if ~exist(plot_dir, 'dir')
    mkdir(plot_dir);
end

%% ---------- colors ----------
fill_colors = [239,154,154;129,212,250]/255;
line_colors = [183,28,28;1,87,155]/255;

gray_fc = [0.75 0.75 0.75];
gray_ec = [0.25 0.25 0.25];

source_data = table();
stats_table = table();

%% ---------- pool reference ----------
Correct_pool = sum(pool_table.correct == 1) / ...
    (height(pool_table) - sum(pool_table.miss == 1));

%% ---------- stable cells ----------
if istable(criterion_table)
    if ~ismember('stable', criterion_table.Properties.VariableNames)
        error('criterion_table is a table but missing column "stable".');
    end
    stable_cells = criterion_table.stable;
elseif isstruct(criterion_table)
    if ~isfield(criterion_table,'stable')
        error('criterion_table is a struct but missing field "stable".');
    end
    stable_cells = criterion_table.stable;
else
    error('criterion_table must be a table or a struct.');
end

nBlocks = numel(stable_cells);

%% ---------- OP correct rate per session ----------
Correct_OP_all = nan(nBlocks,1);

for i = 1:nBlocks
    stable = stable_cells{i};
    Correct_OP_all(i) = sum(stable.correct == 1) / ...
        (sum(stable.correct == 1) + sum(stable.unreward == 1));
end

%% ---------- sex ----------
sex = categorical(repmat({''}, nBlocks, 1));

if istable(criterion_table)
    if ismember('sex', criterion_table.Properties.VariableNames) && height(criterion_table) == nBlocks
        sex = categorical(criterion_table.sex);
    end
elseif isstruct(criterion_table)
    if isfield(criterion_table,'sex') && numel(criterion_table.sex) == nBlocks
        sex = categorical(criterion_table.sex);
    end
end

%% ---------- pair ----------
pair = strings(nBlocks,1);

if istable(criterion_table)
    if ismember('pair', criterion_table.Properties.VariableNames) && height(criterion_table) == nBlocks
        pair = string(criterion_table.pair);
    end
elseif isstruct(criterion_table)
    if isfield(criterion_table,'pair') && numel(criterion_table.pair) == nBlocks
        pair = string(criterion_table.pair);
    end
end

%% ---------- source data: session level ----------
source_session = table( ...
    repmat({'SessionLevel'},nBlocks,1), ...
    pair, ...
    string(sex), ...
    (1:nBlocks)', ...
    Correct_OP_all, ...
    repmat(Correct_pool,nBlocks,1), ...
    'VariableNames', ...
    {'Analysis','Pair','Sex','Index','CorrectRate','PoolReference'});

source_data = [source_data; source_session];

%% ---------- statistics vs pool: session level ----------
valid_ses = ~isnan(Correct_OP_all);

[p_signrank,~,stats_ses] = signrank(Correct_OP_all(valid_ses) - Correct_pool);

fprintf('\n========================================\n')
fprintf('OP correct rate vs pool reference: session level\n')
fprintf('========================================\n')
fprintf('Test: Wilcoxon signed-rank test vs pool reference\n')
fprintf('N sessions = %d\n', sum(valid_ses))
fprintf('Pool reference = %.4f\n', Correct_pool)
fprintf('OP mean = %.4f\n', mean(Correct_OP_all(valid_ses),'omitnan'))
fprintf('OP median = %.4f\n', median(Correct_OP_all(valid_ses),'omitnan'))
fprintf('P = %.6g\n', p_signrank)

signedrank_ses = NaN;
z_ses = NaN;

if isfield(stats_ses,'signedrank')
    signedrank_ses = stats_ses.signedrank;
    fprintf('Signed-rank statistic = %.4f\n', signedrank_ses)
end

if isfield(stats_ses,'zval')
    z_ses = stats_ses.zval;
    fprintf('Z = %.4f\n', z_ses)
end

T_ses = table( ...
    {'OP_vs_pool_session_level'}, ...
    {'signrank'}, ...
    sum(valid_ses), ...
    mean(Correct_OP_all(valid_ses),'omitnan'), ...
    median(Correct_OP_all(valid_ses),'omitnan'), ...
    Correct_pool, ...
    signedrank_ses, ...
    z_ses, ...
    p_signrank, ...
    'VariableNames', ...
    {'Comparison','Test','N','Mean','Median','ReferenceValue', ...
    'Statistic','Z','PValue'});

stats_table = [stats_table; T_ses];

%% ============================================================
%% FIG 1: OP correct rate vs pool, pair-level mean

if all(strlength(pair) == 0)

    warning('No pair column/field found in criterion_table; cannot make pair-level Fig1. Using session-level only.');

else

    Gpair = findgroups(pair);

    pair_ids = splitapply(@(x) string(x(1)), pair, Gpair);
    pair_sex_str = splitapply(@(x) string(x(find(strlength(string(x))>0,1,'first'))), string(sex), Gpair);
    pair_sex_str(pair_sex_str=="") = "unknown";

    Correct_OP_pair = splitapply(@(x) mean(x,'omitnan'), Correct_OP_all, Gpair);

    valid_pair = ~isnan(Correct_OP_pair);

    [p_signrank_pair,~,stats_pair] = signrank(Correct_OP_pair(valid_pair) - Correct_pool);

    signedrank_pair = NaN;
    z_pair = NaN;

    if isfield(stats_pair,'signedrank')
        signedrank_pair = stats_pair.signedrank;
    end

    if isfield(stats_pair,'zval')
        z_pair = stats_pair.zval;
    end

    fprintf('\n========================================\n')
    fprintf('OP correct rate vs pool reference: pair mean\n')
    fprintf('========================================\n')
    fprintf('Test: Wilcoxon signed-rank test vs pool reference\n')
    fprintf('N pairs = %d\n', sum(valid_pair))
    fprintf('Pool reference = %.4f\n', Correct_pool)
    fprintf('OP pair mean: mean = %.4f\n', mean(Correct_OP_pair(valid_pair),'omitnan'))
    fprintf('OP pair mean: median = %.4f\n', median(Correct_OP_pair(valid_pair),'omitnan'))
    fprintf('Signed-rank statistic = %.4f\n', signedrank_pair)
    if ~isnan(z_pair)
        fprintf('Z = %.4f\n', z_pair)
    end
    fprintf('P = %.6g\n', p_signrank_pair)

    source_pair_mean = table( ...
        repmat({'PairMean'},numel(Correct_OP_pair),1), ...
        pair_ids, ...
        pair_sex_str, ...
        (1:numel(Correct_OP_pair))', ...
        Correct_OP_pair, ...
        repmat(Correct_pool,numel(Correct_OP_pair),1), ...
        'VariableNames', ...
        {'Analysis','Pair','Sex','Index','CorrectRate','PoolReference'});

    source_data = [source_data; source_pair_mean];

    T_pair = table( ...
        {'OP_vs_pool_pair_mean'}, ...
        {'signrank'}, ...
        sum(valid_pair), ...
        mean(Correct_OP_pair(valid_pair),'omitnan'), ...
        median(Correct_OP_pair(valid_pair),'omitnan'), ...
        Correct_pool, ...
        signedrank_pair, ...
        z_pair, ...
        p_signrank_pair, ...
        'VariableNames', ...
        {'Comparison','Test','N','Mean','Median','ReferenceValue', ...
        'Statistic','Z','PValue'});

    stats_table = [stats_table; T_pair];

    %% --- plot ---
    fig = figure('Color','w', 'Position',[600 300 200 400]);
    ax = axes('Parent', fig); hold(ax,'on');

    median_OP_pair = median(Correct_OP_pair, 'omitnan');

    bar(ax, 1, median_OP_pair, 0.5, ...
        'FaceColor','none', ...
        'EdgeColor','k', ...
        'LineWidth', 1.8, ...
        'HandleVisibility','off');

    jit = 0.10 * (rand(numel(Correct_OP_pair),1) - 0.5);
    PT_SIZE = 25;

    for i = 1:numel(Correct_OP_pair)
        scatter(ax, 1 + jit(i), Correct_OP_pair(i), PT_SIZE, ...
            'MarkerFaceColor', gray_fc, ...
            'MarkerEdgeColor', gray_ec, ...
            'LineWidth', 1.2, ...
            'HandleVisibility','off');
    end

    yline(ax, Correct_pool, 'k--', 'LineWidth', 2);

    xlim(ax, [0.5 1.5]);
    ylim(ax, [0 1]);
    yticks(ax, 0:0.2:1);

    set(ax, ...
        'XTick', 1, ...
        'XTickLabel', {'Object pursuit'}, ...
        'TickDir','out', ...
        'LineWidth',1.2, ...
        'FontSize',12);

    ylabel(ax, 'Correct rate');
    box(ax, 'off');

    title(ax, sprintf('OP correct rate vs pool (pair mean; signrank p = %.3g)', p_signrank_pair), ...
        'FontWeight','normal');

    hP = plot(ax, nan,nan,'k--','LineWidth',2);
    legend(ax, hP, {'pool reference'}, 'Location','best', 'Box','off');

    print(fig, fullfile(plot_dir, 'op_correct_rate_vs_pool.pdf'), ...
        '-dpdf', '-painters');

end

%% ============================================================
%% FIG 2: OP correct rate by sex, pair median

if all(strlength(pair) == 0)

    warning('No pair column/field found in criterion_table; skip sex comparison by pair.');

else

    G = findgroups(pair);

    pair_ids = splitapply(@(x) string(x(1)), pair, G);
    pair_med = splitapply(@(x) median(x,'omitnan'), Correct_OP_all, G);

    sex_str = string(sex);

    pair_sex = splitapply(@(x) string(x(find(strlength(string(x))>0,1,'first'))), sex_str, G);
    pair_sex(pair_sex=="") = "unknown";
    pair_sex = categorical(pair_sex);

    sx = lower(strtrim(string(pair_sex)));

    valsF = pair_med(sx=="female");
    valsM = pair_med(sx=="male");

    pairF = pair_ids(sx=="female");
    pairM = pair_ids(sx=="male");

    source_female = table( ...
        repmat({'PairMedianBySex'},numel(valsF),1), ...
        pairF, ...
        repmat("female",numel(valsF),1), ...
        (1:numel(valsF))', ...
        valsF, ...
        repmat(Correct_pool,numel(valsF),1), ...
        'VariableNames', ...
        {'Analysis','Pair','Sex','Index','CorrectRate','PoolReference'});

    source_male = table( ...
        repmat({'PairMedianBySex'},numel(valsM),1), ...
        pairM, ...
        repmat("male",numel(valsM),1), ...
        (1:numel(valsM))', ...
        valsM, ...
        repmat(Correct_pool,numel(valsM),1), ...
        'VariableNames', ...
        {'Analysis','Pair','Sex','Index','CorrectRate','PoolReference'});

    source_data = [source_data; source_female; source_male];

    p_sex = NaN;
    ranksum_stat = NaN;
    z_sex = NaN;

    if ~isempty(valsF) && ~isempty(valsM)

        [p_sex,~,stats_sex] = ranksum(valsF, valsM);

        if isfield(stats_sex,'ranksum')
            ranksum_stat = stats_sex.ranksum;
        end

        if isfield(stats_sex,'zval')
            z_sex = stats_sex.zval;
        end

        fprintf('\n========================================\n')
        fprintf('Female vs male OP correct rate: pair median\n')
        fprintf('========================================\n')
        fprintf('Test: Wilcoxon rank-sum test\n')
        fprintf('N female pairs = %d\n', numel(valsF))
        fprintf('N male pairs = %d\n', numel(valsM))
        fprintf('Female mean = %.4f\n', mean(valsF,'omitnan'))
        fprintf('Male mean = %.4f\n', mean(valsM,'omitnan'))
        fprintf('Female median = %.4f\n', median(valsF,'omitnan'))
        fprintf('Male median = %.4f\n', median(valsM,'omitnan'))
        fprintf('Ranksum statistic = %.4f\n', ranksum_stat)
        if ~isnan(z_sex)
            fprintf('Z = %.4f\n', z_sex)
        end
        fprintf('P = %.6g\n', p_sex)

    else

        warning('Not enough female/male pairs to compute ranksum p.');

    end

    T_sex = table( ...
        {'Female_vs_male_pair_median'}, ...
        {'ranksum'}, ...
        numel(valsF) + numel(valsM), ...
        mean([valsF; valsM],'omitnan'), ...
        median([valsF; valsM],'omitnan'), ...
        NaN, ...
        ranksum_stat, ...
        z_sex, ...
        p_sex, ...
        'VariableNames', ...
        {'Comparison','Test','N','Mean','Median','ReferenceValue', ...
        'Statistic','Z','PValue'});

    stats_table = [stats_table; T_sex];

    fig2 = figure('Color','w', 'Position',[850 300 200 400]);
    ax2 = axes('Parent', fig2); hold(ax2,'on');

    bar(ax2, 1, median(valsF,'omitnan'), 0.6, ...
        'FaceColor','none','EdgeColor','k','LineWidth',1.8,'HandleVisibility','off');

    bar(ax2, 2, median(valsM,'omitnan'), 0.6, ...
        'FaceColor','none','EdgeColor','k','LineWidth',1.8,'HandleVisibility','off');

    jitF = 0.15 * (rand(numel(valsF),1) - 0.5);
    jitM = 0.15 * (rand(numel(valsM),1) - 0.5);

    PT_SIZE_SEX = 25;

    for i = 1:numel(valsF)
        scatter(ax2, 1 + jitF(i), valsF(i), PT_SIZE_SEX, ...
            'MarkerFaceColor', fill_colors(1,:), ...
            'MarkerEdgeColor', line_colors(1,:), ...
            'LineWidth',1.2,'HandleVisibility','off');
    end

    for i = 1:numel(valsM)
        scatter(ax2, 2 + jitM(i), valsM(i), PT_SIZE_SEX, ...
            'MarkerFaceColor', fill_colors(2,:), ...
            'MarkerEdgeColor', line_colors(2,:), ...
            'LineWidth',1.2,'HandleVisibility','off');
    end

    xlim(ax2, [0.5 2.5]);
    ylim(ax2, [0 1]);
    yticks(ax2, 0:0.2:1);

    set(ax2, ...
        'XTick',[1 2], ...
        'XTickLabel',{'female','male'}, ...
        'TickDir','out', ...
        'LineWidth',1.2, ...
        'FontSize',12);

    ylabel(ax2, 'Correct rate');
    box(ax2, 'off');

    if ~isnan(p_sex)
        text(0.10, 0.98, sprintf('ranksum p = %.3g', p_sex), ...
            'Units','normalized','FontSize',12);
    else
        text(0.10, 0.98, 'ranksum p = n/a', ...
            'Units','normalized','FontSize',12);
    end

    title(ax2, 'OP correct rate by sex (pair median)', 'FontWeight','normal');

    print(fig2, fullfile(plot_dir, 'op_correct_rate_by_sex_pairMedian.pdf'), ...
        '-dpdf', '-painters');

end

%% ---------- send to base workspace ----------
assignin('base','source_data',source_data);
assignin('base','stats_table',stats_table);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end