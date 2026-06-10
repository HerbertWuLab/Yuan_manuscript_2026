function plot_syllable_proportions_pairs(syllable_table, fd)

if ~ismember('sex', syllable_table.Properties.VariableNames)
    error('syllable_table is missing column "sex". Please run add_sex_column_key first.');
end

save_dir = fd;
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

sel_table = syllable_table(~strcmp(syllable_table.manipulation, 'cno'), :);

num_name = {'n_sharp_Lead', 'n_sharp_Foll', ...
    'n_track_Lead', 'n_track_Foll', ...
    'n_sync', ...
    'n_join_Lead', 'n_join_Foll'};

sessions = sel_table.session;
pair = cellfun(@(x) x(1:min(10, end)), sessions, 'UniformOutput', false);
pair = unique(pair);

Prop_syllable = NaN(length(pair), length(num_name));
pair_sex = strings(length(pair), 1);

for p = 1:length(pair)
    ptable = sel_table(contains(sel_table.session, pair{p}), :);

    for j = 1:length(num_name)
        Prop_syllable(p, j) = mean(ptable.(['proportion_' num_name{j}]), 'omitnan');
    end

    sx = string(ptable.sex);
    sx = lower(strtrim(sx));
    sx = sx(~ismissing(sx) & sx ~= "");

    if isempty(sx)
        pair_sex(p) = "unknown";
    else
        u = unique(sx);
        if numel(u) == 1
            pair_sex(p) = u(1);
        else
            pair_sex(p) = "mixed";
        end
    end
end

Prop_syllable = array2table(Prop_syllable, 'VariableNames', num_name);

source_data_prop = table();

for p = 1:length(pair)
    for j = 1:length(num_name)
        T = table( ...
            string(pair{p}), ...
            pair_sex(p), ...
            string(num_name{j}), ...
            Prop_syllable{p,j}, ...
            'VariableNames', ...
            {'Pair','Sex','Syllable','Proportion'});
        source_data_prop = [source_data_prop; T];
    end
end

assignin('base','source_data_prop',source_data_prop);

fprintf('\n========================================\n')
fprintf('Pair-level syllable proportions\n')
fprintf('========================================\n')
fprintf('N pairs = %d\n', length(pair))
disp(source_data_prop)

X = table2array(Prop_syllable);
Z = linkage(X, 'ward');

figure('Visible','off');
[~, ~, sort_idx] = dendrogram(Z, 0, 'Orientation', 'top');
close;

Prop_syllable_sorted = Prop_syllable(sort_idx, :);
pair_sorted = pair(sort_idx);
pair_sex_sorted = pair_sex(sort_idx);

source_data_clustering = table( ...
    string(pair_sorted(:)), ...
    pair_sex_sorted(:), ...
    sort_idx(:), ...
    'VariableNames', ...
    {'Pair','Sex','ClusterOrder'});

assignin('base','source_data_clustering',source_data_clustering);

fprintf('\n========================================\n')
fprintf('Clustering source data\n')
fprintf('========================================\n')
disp(source_data_clustering)

figure('Position', [100, 100, 400, 300]);

ax1 = subplot(1, 2, 1);
dendrogram(Z, 0, 'Orientation', 'left');
set(gca, 'TickDir', 'out', 'YDir', 'reverse');

ax2 = subplot(1, 2, 2);

new_order = [6, 1, 3, 7, 2, 4, 5];
data_matrix = table2array(Prop_syllable_sorted(:, new_order));
num_name_reordered = num_name(new_order);

custom_colors = [
    hex2rgb('#531e5c');
    hex2rgb('#9970ab');
    hex2rgb('#e7d4e8');

    hex2rgb('#0f4d2b');
    hex2rgb('#5aae61');
    hex2rgb('#d9f0d3');

    hex2rgb('#c7b3a4')
];

bar_handle = barh(data_matrix, 'stacked', 'EdgeColor', 'none');

for k = 1:size(data_matrix, 2)
    bar_handle(k).FaceColor = 'flat';
    bar_handle(k).CData = custom_colors(k, :);
end

set(gca, 'YTick', 1:length(pair_sorted), 'YTickLabel', sort_idx, ...
    'TickDir', 'out', 'YDir', 'reverse');

xlabel('Proportion', 'FontSize', 11);
title('Syllable Proportions', 'FontSize', 12);

legend(strrep(num_name_reordered, '_', '\_'), ...
    'Location', 'eastoutside', 'FontSize', 9);

ylim(ax1, [0.5, length(pair_sorted)+0.5]);
ylim(ax2, [0.5, length(pair_sorted)+0.5]);

set(ax1, 'Position', [0.1, 0.1, 0.1, 0.8]);
set(ax2, 'Position', [0.2, 0.1, 0.5, 0.8]);

axes(ax2);
ax2.Units = 'normalized';
n = length(pair_sorted);

for i = 1:n
    y_norm = 1 - (i - 0.5) / n;

    text( ...
        1.02, y_norm, char(pair_sex_sorted(i)), ...
        'Units', 'normalized', ...
        'FontSize', 9, ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle' ...
    );
end

print(fullfile(save_dir, 'combined_vertical_dendrogram_horizontal_bar_sex.pdf'), '-dpdf');

X = table2array(Prop_syllable);
Z = linkage(X, 'ward');

figure('Visible','off');
[~, ~, sort_idx] = dendrogram(Z, 0, 'Orientation', 'top');
close;

Prop_syllable_sorted = Prop_syllable(sort_idx, :);
pair_sorted = pair(sort_idx);
pair_sex_sorted = pair_sex(sort_idx);

figure('Position', [100, 100, 350, 350]);

ax1 = subplot(2,1,1);
dendrogram(Z, 0, 'Orientation', 'top');
set(ax1,'TickDir','out','YTick',[],'XTick',1:numel(sort_idx));
xticklabels(ax1, sort_idx);

ax2 = subplot(2,1,2);

new_order = [6, 1, 3, 7, 2, 4, 5];
data_matrix = table2array(Prop_syllable_sorted(:, new_order));

custom_colors = [
    hex2rgb('#531e5c');
    hex2rgb('#9970ab');
    hex2rgb('#e7d4e8');
    hex2rgb('#0f4d2b');
    hex2rgb('#5aae61');
    hex2rgb('#d9f0d3');
    hex2rgb('#c7b3a4');
];

bh = bar(ax2, data_matrix, 'stacked', ...
    'EdgeColor','none', ...
    'BarWidth', 0.85);

for k = 1:size(data_matrix,2)
    bh(k).FaceColor = 'flat';
    bh(k).CData = repmat(custom_colors(k,:), size(data_matrix,1), 1);
end

ylabel(ax2,'Proportion')
set(ax2,'TickDir','out','XTick',1:numel(sort_idx),'XTickLabel',[])
ylim(ax2,[0 1])

xlim(ax1,[0.5 numel(sort_idx)+0.5])
xlim(ax2,[0.5 numel(sort_idx)+0.5])

set(ax1,'Position',[0.14 0.72 0.78 0.16])
set(ax2,'Position',[0.14 0.18 0.78 0.46])

sgtitle('Syllable Proportions','FontSize',14,'FontWeight','bold');

fill_colors = [239,154,154;129,212,250]/255;

sx = lower(string(pair_sex_sorted));
sx(sx=="f" | sx=="0") = "female";
sx(sx=="m" | sx=="1") = "male";

axes(ax2); 
hold(ax2,'on');

for i = 1:numel(sort_idx)
    if sx(i)=="female"
        symb = '♀';
        col  = fill_colors(1,:);
    elseif sx(i)=="male"
        symb = '♂';
        col  = fill_colors(2,:);
    else
        symb = '?';
        col  = [0 0 0];
    end

    text(i, -0.025, num2str(sort_idx(i)), ...
        'Rotation',90, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','top', ...
        'FontWeight','bold', ...
        'FontSize',9, ...
        'Color',col, ...
        'Clipping','off');

    text(i, -0.085, symb, ...
        'Rotation',90, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','top', ...
        'FontSize',12, ...
        'FontWeight','bold', ...
        'Color',col, ...
        'Clipping','off');
end

print(fullfile(save_dir,'combined_horizontal_dendrogram_vertical_bar_sex_compact.pdf'),'-dpdf');

sexes = {'female';'male'};
fill_colors = [239,154,154;129, 212, 250]/255;
line_colors = [183, 28, 28;1, 87, 155]/255;

norm_cols = {'norm_n_sharp_Lead','norm_n_sharp_Foll', ...
    'norm_n_track_Lead','norm_n_track_Foll', ...
    'norm_n_sync', ...
    'norm_n_join_Lead','norm_n_join_Foll'};

missingCols = setdiff(norm_cols, sel_table.Properties.VariableNames);

if ~isempty(missingCols)
    error("Missing normalized-count columns: %s\nPlease generate these columns in syllable_table first.", ...
        strjoin(missingCols, ", "));
end

PairNorm = NaN(length(pair), length(norm_cols));

for p = 1:length(pair)
    ptable = sel_table(contains(sel_table.session, pair{p}), :);
    for j = 1:length(norm_cols)
        PairNorm(p,j) = mean(ptable.(norm_cols{j}), 'omitnan');
    end
end

sx = lower(strtrim(string(pair_sex)));
keep = (sx == "female") | (sx == "male");

sx2 = sx(keep);
PairNorm2 = PairNorm(keep, :);
pair2 = string(pair(keep));

grp = categorical(sx2, ["female","male"]);

source_data_norm_sex = table();
stats_table_norm_sex = table();

for j = 1:length(norm_cols)

    y = PairNorm2(:, j);

    y_f = y(grp=="female");
    y_m = y(grp=="male");

    pair_f = pair2(grp=="female");
    pair_m = pair2(grp=="male");

    valid_f = ~isnan(y_f);
    valid_m = ~isnan(y_m);

    y_f = y_f(valid_f);
    y_m = y_m(valid_m);

    pair_f = pair_f(valid_f);
    pair_m = pair_m(valid_m);

    n_f = numel(y_f);
    n_m = numel(y_m);

    if n_m >= 2 && n_f >= 2
        [pval,~,stats_rs] = ranksum(y_m, y_f);
    else
        pval = NaN;
        stats_rs.ranksum = NaN;
        stats_rs.zval = NaN;
    end

    mean_f = mean(y_f, 'omitnan');
    mean_m = mean(y_m, 'omitnan');
    median_f = median(y_f, 'omitnan');
    median_m = median(y_m, 'omitnan');
    sd_f = std(y_f, 'omitnan');
    sd_m = std(y_m, 'omitnan');
    sem_f = sd_f / sqrt(n_f);
    sem_m = sd_m / sqrt(n_m);

    T_f = table( ...
        repmat({norm_cols{j}},n_f,1), ...
        pair_f(:), ...
        repmat({'female'},n_f,1), ...
        (1:n_f)', ...
        y_f(:), ...
        'VariableNames', ...
        {'Syllable','Pair','Sex','PairIndex','NormalizedCount'});

    T_m = table( ...
        repmat({norm_cols{j}},n_m,1), ...
        pair_m(:), ...
        repmat({'male'},n_m,1), ...
        (1:n_m)', ...
        y_m(:), ...
        'VariableNames', ...
        {'Syllable','Pair','Sex','PairIndex','NormalizedCount'});

    source_data_norm_sex = [source_data_norm_sex; T_f; T_m];

    T_stats = table( ...
        {norm_cols{j}}, ...
        {'female_vs_male'}, ...
        {'ranksum'}, ...
        n_f, ...
        n_m, ...
        mean_f, ...
        mean_m, ...
        median_f, ...
        median_m, ...
        sd_f, ...
        sd_m, ...
        sem_f, ...
        sem_m, ...
        stats_rs.ranksum, ...
        stats_rs.zval, ...
        pval, ...
        'VariableNames', ...
        {'Syllable','Comparison','Test', ...
        'NFemale','NMale', ...
        'MeanFemale','MeanMale', ...
        'MedianFemale','MedianMale', ...
        'SDFemale','SDMale', ...
        'SEMFemale','SEMMale', ...
        'RankSumStatistic','Z','PValue'});

    stats_table_norm_sex = [stats_table_norm_sex; T_stats];

    fprintf('\n========================================\n')
    fprintf('%s\n', norm_cols{j})
    fprintf('========================================\n')
    fprintf('Test: Wilcoxon rank-sum test, female vs male\n')
    fprintf('Female n = %d, mean = %.4f, median = %.4f, SEM = %.4f\n', ...
        n_f, mean_f, median_f, sem_f)
    fprintf('Male n = %d, mean = %.4f, median = %.4f, SEM = %.4f\n', ...
        n_m, mean_m, median_m, sem_m)
    fprintf('Ranksum statistic = %.4f\n', stats_rs.ranksum)

    if ~isnan(stats_rs.zval)
        fprintf('Z = %.4f\n', stats_rs.zval)
    end

    fprintf('P = %.6g\n', pval)

    figure('Position',[600 300 250 400]);
    hold on;

    bar(1, mean_f, 0.45, 'FaceColor', 'none', 'EdgeColor', line_colors(1,:), 'LineWidth', 2);
    bar(2, mean_m, 0.45, 'FaceColor', 'none', 'EdgeColor', line_colors(2,:), 'LineWidth', 2);

    jit = 0.10;
    xf = 1 + (rand(n_f,1)-0.5)*2*jit;
    xm = 2 + (rand(n_m,1)-0.5)*2*jit;

    scatter(xf, y_f, 25, 'filled', ...
        'MarkerFaceColor', fill_colors(1,:), ...
        'MarkerEdgeColor', line_colors(1,:), ...
        'MarkerFaceAlpha', 0.75);

    scatter(xm, y_m, 25, 'filled', ...
        'MarkerFaceColor', fill_colors(2,:), ...
        'MarkerEdgeColor', line_colors(2,:), ...
        'MarkerFaceAlpha', 0.75);

    xlim([0.5 2.5]);
    xticks([1 2]);
    xticklabels({'female','male'});
    ylabel('Normalized syllable count per pair');

    title(sprintf('%s  (female n=%d, male n=%d)', ...
        strrep(norm_cols{j}, '_', '\_'), n_f, n_m));

    box off;
    set(gca,'FontSize',32,'TickDir','out');

    if ~isnan(pval)
        text(0.38,0.98,sprintf('P=%.2g', pval), ...
            'FontSize',28,'Units','normalized');
    else
        text(0.38,0.98,'P=NA', ...
            'FontSize',28,'Units','normalized');
    end

    hold off;

    syll_name = strrep(norm_cols{j}, '_', '-');
    figname = fullfile(save_dir, ...
        ['syllable_' syll_name '_female_vs_male_normalized.pdf']);

    print(gcf, figname, '-dpdf', '-painters');
end

assignin('base','source_data_norm_sex',source_data_norm_sex);
assignin('base','stats_table_norm_sex',stats_table_norm_sex);

data_matrix_pca = table2array(Prop_syllable);

[num_samples, num_features] = size(data_matrix_pca);
disp(['Number of samples: ', num2str(num_samples)]);
disp(['Number of features: ', num2str(num_features)]);

[coeff, score, latent] = pca(data_matrix_pca);

variance_explained = latent ./ sum(latent) * 100;
disp('Variance explained by each PC (%):');
disp(variance_explained');

cumulative_variance = cumsum(variance_explained);
disp('Cumulative variance explained (%):');
disp(cumulative_variance');

pc1_loadings = coeff(:, 1);
pc2_loadings = coeff(:, 2);

disp('PC1 loadings:');
for i = 1:length(num_name)
    fprintf('%s: %.4f\n', num_name{i}, pc1_loadings(i));
end

disp('PC2 loadings:');
for i = 1:length(num_name)
    fprintf('%s: %.4f\n', num_name{i}, pc2_loadings(i));
end

source_data_pca_scores = table( ...
    string(pair(:)), ...
    pair_sex(:), ...
    score(:,1), ...
    score(:,2), ...
    'VariableNames', ...
    {'Pair','Sex','PC1','PC2'});

stats_table_pca_variance = table( ...
    (1:length(variance_explained))', ...
    variance_explained(:), ...
    cumulative_variance(:), ...
    'VariableNames', ...
    {'PC','VarianceExplained','CumulativeVarianceExplained'});

source_data_pca_loadings = table();

for j = 1:length(num_name)
    T = table( ...
        string(num_name{j}), ...
        pc1_loadings(j), ...
        pc2_loadings(j), ...
        'VariableNames', ...
        {'Syllable','PC1Loading','PC2Loading'});
    source_data_pca_loadings = [source_data_pca_loadings; T];
end

assignin('base','source_data_pca_scores',source_data_pca_scores);
assignin('base','source_data_pca_loadings',source_data_pca_loadings);
assignin('base','stats_table_pca_variance',stats_table_pca_variance);

fprintf('\n========================================\n')
fprintf('PCA source data and variance\n')
fprintf('========================================\n')
disp(stats_table_pca_variance)
disp(source_data_pca_loadings)

figure('Position', [100, 100, 400, 400]);

subplot(2, 2, 1);
bar(variance_explained);
set(gca, 'TickDir', 'out');
xlabel('Principal component');
ylabel('Variance explained (%)');
title('Variance explained by each PC');

subplot(2, 2, 2);
plot(cumulative_variance, 'ro-', 'LineWidth', 2);
set(gca, 'TickDir', 'out');
xlabel('Principal component');
ylabel('Cumulative variance explained (%)');
title('Cumulative variance explained');

subplot(2, 2, 3);
bar(pc1_loadings);
set(gca, 'XTick', 1:length(num_name), 'TickDir', 'out', 'XTickLabel', strrep(num_name, '_', '\_'));
xlabel('Features');
ylabel('Loadings');
title('PC1 loadings');

subplot(2, 2, 4);
bar(pc2_loadings);
set(gca, 'XTick', 1:length(num_name), 'TickDir', 'out', 'XTickLabel', strrep(num_name, '_', '\_'));
xlabel('Features');
ylabel('Loadings');
title('PC2 loadings');

print(fullfile(save_dir, 'pca_analysis_sorted_sex.pdf'), '-dpdf');

figure('Position', [100, 100, 400, 400]);

female_fill = [239,154,154] / 255;
female_edge = [183,28,28]   / 255;

male_fill   = [129,212,250] / 255;
male_edge   = [1,87,155]    / 255;

other_fill  = [0.7, 0.7, 0.7];
other_edge  = [0.4, 0.4, 0.4];

hold on;

for i = 1:num_samples
    sx_i = lower(strtrim(pair_sex(i)));

    if sx_i == "female"
        fill_c = female_fill;
        edge_c = female_edge;
    elseif sx_i == "male"
        fill_c = male_fill;
        edge_c = male_edge;
    else
        fill_c = other_fill;
        edge_c = other_edge;
    end

    scatter(score(i, 1), score(i, 2), 50, ...
        'MarkerFaceColor', fill_c, ...
        'MarkerEdgeColor', edge_c, ...
        'LineWidth', 0.8);
end

xlim([-0.20, 0.53]);
ylim([-0.30, 0.38]);

set(gca, 'FontSize', 24, 'TickDir', 'out');

xlabel('PC1');
ylabel('PC2');
title('PCA scores (colored by sex)');

labels = 1:num_samples;

text(score(:, 1), score(:, 2), num2str(labels'), 'FontSize', 10, ...
    'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');

h_female = scatter(NaN, NaN, 50, ...
    'MarkerFaceColor', female_fill, ...
    'MarkerEdgeColor', female_edge, ...
    'LineWidth', 0.8);

h_male = scatter(NaN, NaN, 50, ...
    'MarkerFaceColor', male_fill, ...
    'MarkerEdgeColor', male_edge, ...
    'LineWidth', 0.8);

legend([h_male, h_female], {'Male', 'Female'}, ...
    'Location', 'southeast', ...
    'FontSize', 16, ...
    'Box', 'off');

set(gcf, 'PaperUnits', 'points');
set(gcf, 'PaperSize', [400, 400]);

print(fullfile(save_dir, 'pca_scores_sorted_sex.pdf'), '-dpdf');

XY = score(:, 1:2);
sx_all = lower(strtrim(string(pair_sex(:))));

valid = (sx_all == "female") | (sx_all == "male");
XY = XY(valid, :);
sx = sx_all(valid);
pair_valid = string(pair(valid));
n = size(XY, 1);

D = squareform(pdist(XY, 'euclidean'));

mean_same = nan(n, 1);
mean_diff = nan(n, 1);

for i = 1:n
    same_idx = (sx == sx(i));
    diff_idx = (sx ~= sx(i));

    same_idx(i) = false;

    if any(same_idx)
        mean_same(i) = mean(D(i, same_idx), 'omitnan');
    end
    if any(diff_idx)
        mean_diff(i) = mean(D(i, diff_idx), 'omitnan');
    end
end

keep = ~isnan(mean_same) & ~isnan(mean_diff);

mean_same_k = mean_same(keep);
mean_diff_k = mean_diff(keep);
delta = mean_diff_k - mean_same_k;

pair_k = pair_valid(keep);
sx_k = sx(keep);

p_dist = NaN;
signedrank_stat = NaN;
zval = NaN;

if numel(delta) >= 3
    [p_dist,~,stats_dist] = signrank(mean_same_k, mean_diff_k, 'tail','left');

    if isfield(stats_dist,'signedrank')
        signedrank_stat = stats_dist.signedrank;
    end

    if isfield(stats_dist,'zval')
        zval = stats_dist.zval;
    end
else
    warning('Not enough points for signrank distance test (n<3).');
end

source_data_pca_distance = table( ...
    pair_k(:), ...
    sx_k(:), ...
    (1:length(mean_same_k))', ...
    mean_same_k(:), ...
    mean_diff_k(:), ...
    delta(:), ...
    'VariableNames', ...
    {'Pair','Sex','PointIndex','MeanSameSexDistance','MeanDifferentSexDistance','Delta_DiffMinusSame'});

stats_table_pca_distance = table( ...
    {'PCA_distance_same_vs_diff'}, ...
    {'paired signrank, tail left'}, ...
    length(delta), ...
    median(mean_same_k,'omitnan'), ...
    median(mean_diff_k,'omitnan'), ...
    median(delta,'omitnan'), ...
    mean(mean_same_k,'omitnan'), ...
    mean(mean_diff_k,'omitnan'), ...
    mean(delta,'omitnan'), ...
    signedrank_stat, ...
    zval, ...
    p_dist, ...
    'VariableNames', ...
    {'Comparison','Test','N', ...
    'MedianSameSexDistance','MedianDifferentSexDistance','MedianDelta_DiffMinusSame', ...
    'MeanSameSexDistance','MeanDifferentSexDistance','MeanDelta_DiffMinusSame', ...
    'SignedRankStatistic','Z','PValue'});

assignin('base','source_data_pca_distance',source_data_pca_distance);
assignin('base','stats_table_pca_distance',stats_table_pca_distance);

fprintf('\n=== PCA distance analysis ===\n');
fprintf('N valid points (male/female): %d\n', n);
fprintf('N used for paired test: %d\n', numel(delta));
fprintf('median(mean_same)=%.4g, median(mean_diff)=%.4g, median(delta)=%.4g\n', ...
    median(mean_same_k,'omitnan'), median(mean_diff_k,'omitnan'), median(delta,'omitnan'));
fprintf('mean(mean_same)=%.4g, mean(mean_diff)=%.4g, mean(delta)=%.4g\n', ...
    mean(mean_same_k,'omitnan'), mean(mean_diff_k,'omitnan'), mean(delta,'omitnan'));
fprintf('Signed-rank statistic = %.4f\n', signedrank_stat);
if ~isnan(zval)
    fprintf('Z = %.4f\n', zval);
end
fprintf('signrank p (same vs diff) = %.3g\n', p_dist);

m_all = mean(delta, 'omitnan');
sem_all = std(delta, 'omitnan') / sqrt(max(1, sum(~isnan(delta))));

figure('Position', [100, 100, 360, 320], 'Color', 'w');
hold on;

bar(1, m_all, 'FaceColor', 'none', 'LineWidth', 1.8);

errorbar(1, m_all, sem_all, 'k.', 'LineWidth', 1.2);

jitter = 0.08;

xj = 1 + (rand(numel(delta),1)-0.5)*2*jitter;

scatter(xj, delta, 40, ...
    'MarkerFaceColor', [0.7 0.7 0.7], ...
    'MarkerEdgeColor', [0.3 0.3 0.3], ...
    'LineWidth', 0.8);

set(gca, 'XTick', 1, 'XTickLabel', {'All'}, ...
    'TickDir', 'out', 'Box', 'off', 'FontSize', 18);

ylabel('\Delta distance = mean(diff-sex) - mean(same-sex)', 'FontSize', 14);

yline(0, '--', 'LineWidth', 1);

if ~isnan(p_dist)
    title(sprintf('All points: signrank(same vs diff), p=%.3g', p_dist), ...
        'FontSize', 12, 'Interpreter', 'tex');
else
    title('All points: signrank(same vs diff), p=NA', ...
        'FontSize', 12, 'Interpreter', 'tex');
end

set(gcf, 'PaperUnits', 'points');
set(gcf, 'PaperSize', [360, 320]);

print(fullfile(save_dir, 'pca_distance_bar_all.pdf'), '-dpdf');

fprintf('\nSaved to base workspace:\n')
fprintf('source_data_prop\n')
fprintf('source_data_clustering\n')
fprintf('source_data_norm_sex\n')
fprintf('stats_table_norm_sex\n')
fprintf('source_data_pca_scores\n')
fprintf('source_data_pca_loadings\n')
fprintf('stats_table_pca_variance\n')
fprintf('source_data_pca_distance\n')
fprintf('stats_table_pca_distance\n')

end

function rgb = hex2rgb(hex)
hex = strrep(hex, '#', '');
rgb = sscanf(hex, '%2x%2x%2x', [1, 3]) / 255;
end