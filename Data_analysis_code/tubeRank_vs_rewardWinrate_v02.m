function [mean_rank, sem_rank, rank_winpct, groups, figH, mismatchCountByRank, mismatchPairs] = ...
    tubeRank_vs_rewardWinrate_v02(fd, xlsxName, useStableOnly)
% tubeRank_vs_rewardWinrate_v02
%
% Outputs to base workspace:
%   source_data
%   stats_table

if nargin < 2 || isempty(xlsxName)
    xlsxName = "/data/social_hierarchy/reward_competition_Tube_test.xlsx";
end

if nargin < 3
    useStableOnly = false;
end

fname = fullfile(fd, xlsxName);
T = readtable(fname);

requiredCols = {'Group','Mouse1','Mouse2','Trials_won_m1','Trials_won_m2','stability'};

for i = 1:numel(requiredCols)
    if ~ismember(requiredCols{i}, T.Properties.VariableNames)
        error("Missing required column: %s", requiredCols{i});
    end
end

tubeCol = 'tube_test_result';

if ~ismember(tubeCol, T.Properties.VariableNames)
    error("Missing required column: %s", tubeCol);
end

groups = unique(T.Group);
nGroups = numel(groups);

rank_winpct = nan(nGroups, 2);

mismatchCountByRank = zeros(1,4);
mismatchPairs = table();

source_data = table();

stablePairsUsed = 0;
stableNonTie    = 0;
stableAgree     = 0;
stableTie       = 0;

for g = 1:nGroups

    Tg_all = T(strcmp(T.Group, groups{g}), :);

    mice = unique([Tg_all.Mouse1; Tg_all.Mouse2]);

    tubeWins = zeros(numel(mice), 1);

    for m = 1:numel(mice)
        tubeWins(m) = sum(strcmp(Tg_all.(tubeCol), mice{m}));
    end

    [~, order] = sort(tubeWins, 'descend');

    rankNum = containers.Map();

    for ii = 1:numel(order)
        rankNum(mice{order(ii)}) = ii;
    end

    if useStableOnly
        stab = strtrim(lower(string(Tg_all.stability)));
        Tg = Tg_all(stab == "stable", :);
    else
        Tg = Tg_all;
    end

    domWins = 0;
    domTrials = 0;

    subWins = 0;
    subTrials = 0;

    for rr = 1:height(Tg)

        m1 = Tg.Mouse1{rr};
        m2 = Tg.Mouse2{rr};

        tTot = Tg.Trials_won_m1(rr) + Tg.Trials_won_m2(rr);

        if tTot == 0
            continue;
        end

        r1 = rankNum(m1);
        r2 = rankNum(m2);

        if r1 < r2

            dominantMouse = m1;
            subordinateMouse = m2;

            domRank = r1;
            subRank = r2;

            domW = Tg.Trials_won_m1(rr);
            subW = Tg.Trials_won_m2(rr);

        else

            dominantMouse = m2;
            subordinateMouse = m1;

            domRank = r2;
            subRank = r1;

            domW = Tg.Trials_won_m2(rr);
            subW = Tg.Trials_won_m1(rr);

        end

        domWins   = domWins + domW;
        domTrials = domTrials + tTot;

        subWins   = subWins + subW;
        subTrials = subTrials + tTot;

        T_row = table( ...
            groups(g), ...
            {m1}, ...
            {m2}, ...
            {dominantMouse}, ...
            {subordinateMouse}, ...
            r1, ...
            r2, ...
            domRank, ...
            subRank, ...
            Tg.Trials_won_m1(rr), ...
            Tg.Trials_won_m2(rr), ...
            domW, ...
            subW, ...
            tTot, ...
            domW/tTot*100, ...
            subW/tTot*100, ...
            string(Tg.stability(rr)), ...
            useStableOnly, ...
            'VariableNames', ...
            {'Group','Mouse1','Mouse2','TubeDominantMouse','TubeSubordinateMouse', ...
            'Mouse1TubeRank','Mouse2TubeRank','DominantTubeRank','SubordinateTubeRank', ...
            'TrialsWonM1','TrialsWonM2','DominantWins','SubordinateWins','TotalTrials', ...
            'DominantWinPercent','SubordinateWinPercent','Stability','UseStableOnly'});

        source_data = [source_data; T_row];

    end

    rank_winpct(g,1) = (domWins / domTrials) * 100;
    rank_winpct(g,2) = (subWins / subTrials) * 100;

end

assignin('base','source_data',source_data);

mean_rank = mean(rank_winpct, 1, 'omitnan');
sem_rank  = std(rank_winpct, 0, 1, 'omitnan') ./ sqrt(nGroups);

[p_sr,~,stats_sr] = signrank(rank_winpct(:,1), rank_winpct(:,2));

signedrank_stat = NaN;
zval = NaN;

if isfield(stats_sr,'signedrank')
    signedrank_stat = stats_sr.signedrank;
end

if isfield(stats_sr,'zval')
    zval = stats_sr.zval;
end

stats_table = table( ...
    {'Tube dominant vs subordinate'}, ...
    {'paired Wilcoxon signed-rank'}, ...
    nGroups, ...
    mean_rank(1), ...
    mean_rank(2), ...
    median(rank_winpct(:,1),'omitnan'), ...
    median(rank_winpct(:,2),'omitnan'), ...
    mean(rank_winpct(:,1)-rank_winpct(:,2),'omitnan'), ...
    median(rank_winpct(:,1)-rank_winpct(:,2),'omitnan'), ...
    sem_rank(1), ...
    sem_rank(2), ...
    signedrank_stat, ...
    zval, ...
    p_sr, ...
    useStableOnly, ...
    'VariableNames', ...
    {'Comparison','Test','NGroups', ...
    'MeanDominant','MeanSubordinate', ...
    'MedianDominant','MedianSubordinate', ...
    'MeanDifference_DomMinusSub','MedianDifference_DomMinusSub', ...
    'SEMDominant','SEMSubordinate', ...
    'SignedRankStatistic','Z','PValue','UseStableOnly'});

assignin('base','stats_table',stats_table);

fprintf('\nTube rank vs reward win rate\n')
fprintf('========================================\n')
fprintf('Use stable only = %d\n', useStableOnly)
fprintf('N groups = %d\n', nGroups)
fprintf('Dominant mean = %.4f, SEM = %.4f\n', mean_rank(1), sem_rank(1))
fprintf('Subordinate mean = %.4f, SEM = %.4f\n', mean_rank(2), sem_rank(2))
fprintf('Dominant median = %.4f\n', median(rank_winpct(:,1),'omitnan'))
fprintf('Subordinate median = %.4f\n', median(rank_winpct(:,2),'omitnan'))
fprintf('Mean difference = %.4f\n', mean(rank_winpct(:,1)-rank_winpct(:,2),'omitnan'))
fprintf('Median difference = %.4f\n', median(rank_winpct(:,1)-rank_winpct(:,2),'omitnan'))
fprintf('Test: paired Wilcoxon signed-rank test\n')
fprintf('Signed-rank statistic = %.4f\n', signedrank_stat)

if ~isnan(zval)
    fprintf('Z = %.4f\n', zval)
end

fprintf('P = %.6g\n', p_sr)

figH = figure('Color','w','Units','pixels','Position',[100 100 300 300]);
hold on;

bar(1:2, mean_rank, 0.6, ...
    'FaceColor','none', ...
    'EdgeColor','k', ...
    'LineWidth',1.3);

errorbar(1:2, mean_rank, sem_rank, ...
    'k.', ...
    'LineWidth', 1.5);

set(gca, ...
    'XTick', 1:2, ...
    'XTickLabel', {'Dominant','Subordinate'}, ...
    'TickDir','out', ...
    'FontSize', 10);

ylabel('Percentage of trials won (%)');
xlabel('Tube-test status within each pair');
title('Reward competition win rate by tube-test rank');

ylim([0 100]);
box off;

text(0.38,0.98,sprintf('P=%.2g',p_sr), ...
    'Units','normalized', ...
    'FontSize',12);

plotDir = fullfile(fd, 'plots');

if ~exist(plotDir, 'dir')
    mkdir(plotDir);
end

outName = fullfile(plotDir, 'tubeRank_vs_rewardWinrate_v02.pdf');

set(figH, 'PaperPositionMode', 'auto');

print(figH, outName, '-dpdf', '-painters');

fprintf('\nSaved figure: %s\n', outName)
fprintf('Saved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end