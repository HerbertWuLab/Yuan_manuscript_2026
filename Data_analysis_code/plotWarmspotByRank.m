function [mean_time, sem_time, rank_time, figH] = plotWarmspotByRank(fd, xlsxName)
% plotWarmspotByRank
% X: tube_test_result rank (1-4)
% Y: mean warmspot time across two tests (warmspot_1 & warmspot_2)
%
% Outputs to base workspace:
%   source_data
%   stats_table

if nargin < 2 || isempty(xlsxName)
    xlsxName = "/data/social_hierarchy/warmspot_Tube_test.xlsx";
end

fname = fullfile(fd, xlsxName);
T = readtable(fname);

req = {'mouse','warmspot_1','warmspot_2','tube_test_result'};

for i = 1:numel(req)
    if ~ismember(req{i}, T.Properties.VariableNames)
        error("Missing required column: %s", req{i});
    end
end

meanPerMouse = mean([T.warmspot_1, T.warmspot_2], 2, 'omitnan');

ranks = 1:4;

rank_time = cell(1,4);
mean_time = nan(1,4);
sem_time  = nan(1,4);
sd_time   = nan(1,4);
median_time = nan(1,4);
n_time = nan(1,4);

source_data = table();

for r = ranks

    idx = (T.tube_test_result == r);
    vals = meanPerMouse(idx);

    rank_time{r} = vals;

    mean_time(r) = mean(vals, 'omitnan');
    median_time(r) = median(vals, 'omitnan');
    sd_time(r) = std(vals, 0, 'omitnan');
    n_time(r) = sum(~isnan(vals));
    sem_time(r) = sd_time(r) / sqrt(n_time(r));

    T_source = table( ...
        T.mouse(idx), ...
        T.tube_test_result(idx), ...
        T.warmspot_1(idx), ...
        T.warmspot_2(idx), ...
        meanPerMouse(idx), ...
        'VariableNames', ...
        {'Mouse','TubeTestRank','Warmspot1','Warmspot2','MeanWarmspotTime'});

    source_data = [source_data; T_source];

end

assignin('base','source_data',source_data);

p_kw = NaN;
chi2_kw = NaN;
df_kw = NaN;

group = T.tube_test_result;
valid = ~isnan(meanPerMouse) & ~isnan(group);

if sum(valid) >= 3
    [p_kw,~,stats_kw] = kruskalwallis(meanPerMouse(valid), group(valid), 'off');

    if isfield(stats_kw,'chi2stat')
        chi2_kw = stats_kw.chi2stat;
    end

    if isfield(stats_kw,'df')
        df_kw = stats_kw.df;
    end
end

stats_table = table( ...
    ranks(:), ...
    n_time(:), ...
    mean_time(:), ...
    median_time(:), ...
    sd_time(:), ...
    sem_time(:), ...
    repmat({'Kruskal-Wallis across ranks'},4,1), ...
    repmat(chi2_kw,4,1), ...
    repmat(df_kw,4,1), ...
    repmat(p_kw,4,1), ...
    'VariableNames', ...
    {'TubeTestRank','N','Mean','Median','SD','SEM', ...
    'OmnibusTest','ChiSquare','DF','PValue'});

assignin('base','stats_table',stats_table);

fprintf('\nWarmspot time by tube-test rank\n')
fprintf('========================================\n')

for r = ranks
    fprintf('Rank %d: n = %d, mean = %.4f, median = %.4f, SD = %.4f, SEM = %.4f\n', ...
        r, n_time(r), mean_time(r), median_time(r), sd_time(r), sem_time(r));
end

fprintf('\nOmnibus test: Kruskal-Wallis across ranks\n')
fprintf('Chi-square = %.4f\n', chi2_kw)
fprintf('df = %.4f\n', df_kw)
fprintf('P = %.6g\n', p_kw)

figH = figure('Color','w','Units','pixels','Position',[100 100 300 300]);
hold on;

bar(1:4, mean_time, 0.6, ...
    'FaceColor','none', ...
    'EdgeColor','k', ...
    'LineWidth',1.3);

errorbar(1:4, mean_time, sem_time, ...
    'k.', ...
    'LineWidth', 1.5);

set(gca, ...
    'XTick', 1:4, ...
    'XTickLabel', {'Rank 1','Rank 2','Rank 3','Rank 4'}, ...
    'TickDir','out', ...
    'FontSize', 10);

xlabel('Tube test ranking');
ylabel('Time in warm spot (s)');
title('Warmspot time by tube-test rank');

box off;

if ~isnan(p_kw)
    text(0.38,0.98,sprintf('P=%.2g',p_kw), ...
        'Units','normalized', ...
        'FontSize',12);
end

plotDir = fullfile(fd, 'plots');

if ~exist(plotDir, 'dir')
    mkdir(plotDir);
end

outName = fullfile(plotDir, 'warmspot_time_by_rank.pdf');

set(figH, 'PaperPositionMode', 'auto');

print(figH, outName, '-dpdf', '-painters');

fprintf('\nSaved figure: %s\n', outName)
fprintf('Saved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end