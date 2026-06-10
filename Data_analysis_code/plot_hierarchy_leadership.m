function plot_hierarchy_leadership(fd, filename)
% ============================================================
%  Function: plot_hierarchy_leadership
%
% Outputs to base workspace:
%   source_data
%   stats_table
% ============================================================

close all; clc;

input_file = fullfile(fd, filename);
output_dir = fullfile(fd, "plots");

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

fprintf("Reading data from: %s\n", input_file);

T = readtable(input_file, 'VariableNamingRule','preserve');

varNames      = T.Properties.VariableNames;
varNamesLower = lower(varNames);

getCol = @(key) get_column_by_keyword(T, varNames, varNamesLower, key);

leadProp   = getCol('leading');
initProp   = getCol('initiation');
rankReward = getCol('reward');
rankTube   = getCol('tube');
rankWarm   = getCol('warm');
pairIndex  = getCol('pair');

uniquePairs = unique(pairIndex);

leadCorrected = leadProp;
initCorrected = initProp;

for i = 1:length(uniquePairs)
    p = uniquePairs(i);
    idx = pairIndex == p;

    sumLead = sum(leadProp(idx));
    sumInit = sum(initProp(idx));

    if sumLead > 0
        leadCorrected(idx) = leadProp(idx) / sumLead;
    end

    if sumInit > 0
        initCorrected(idx) = initProp(idx) / sumInit;
    end
end

leadProp = leadCorrected;
initProp = initCorrected;

idxDomReward = (rankReward == 1);
idxDomTube   = (rankTube   == 1);
idxDomWarm   = (rankWarm   == 1);

source_data = table();

assayNames = {'Reward competition'; 'Tube test'; 'Warm spot'};
assayKeys = {'reward'; 'tube'; 'warm'};
domIdx = {idxDomReward; idxDomTube; idxDomWarm};

for i = 1:3
    cur_idx = domIdx{i};

    T_source = table( ...
        repmat(assayNames(i),sum(cur_idx),1), ...
        repmat(assayKeys(i),sum(cur_idx),1), ...
        pairIndex(cur_idx), ...
        leadProp(cur_idx), ...
        initProp(cur_idx), ...
        'VariableNames', ...
        {'Assay','AssayKey','PairIndex','LeadingProportion','InitiationProportion'});

    source_data = [source_data; T_source];
end

assignin('base','source_data',source_data);

fig = figure('Name','Dominant animals: Leading vs Initiating', ...
             'Color','w', 'Units','pixels', 'Position',[100 100 600 400]);

subplot(1,3,1);
plot_dom_axis(leadProp(idxDomReward), initProp(idxDomReward), 'Reward Competition');

subplot(1,3,2);
plot_dom_axis(leadProp(idxDomTube), initProp(idxDomTube), 'Tube Test');

subplot(1,3,3);
plot_dom_axis(leadProp(idxDomWarm), initProp(idxDomWarm), 'Warm Spot');

sgtitle('Leading and Initiating Proportions of Dominant Mice', ...
        'FontSize',12,'FontWeight','bold');

outfile = fullfile(output_dir, "lead_vs_init_dominant_only_3tests.pdf");
set(fig, 'PaperPositionMode', 'auto');
print(fig, outfile, '-dpdf', '-bestfit');

fprintf("\nPlot saved to: %s\n", outfile);

fprintf('\n===== Statistics: Dominant vs chance (0.5) =====\n');

leadSets = { ...
    leadProp(idxDomReward), ...
    leadProp(idxDomTube), ...
    leadProp(idxDomWarm)};

initSets = { ...
    initProp(idxDomReward), ...
    initProp(idxDomTube), ...
    initProp(idxDomWarm)};

stats_table = table();

for i = 1:3

    leadDom = leadSets{i};
    initDom = initSets{i};

    leadDom = leadDom(~isnan(leadDom));
    initDom = initDom(~isnan(initDom));

    [p_leader,~,stats_leader] = signrank(leadDom, 0.5, 'tail','both');
    [p_init,~,stats_init] = signrank(initDom, 0.5, 'tail','both');

    signedrank_leader = NaN;
    z_leader = NaN;
    signedrank_init = NaN;
    z_init = NaN;

    if isfield(stats_leader,'signedrank')
        signedrank_leader = stats_leader.signedrank;
    end

    if isfield(stats_leader,'zval')
        z_leader = stats_leader.zval;
    end

    if isfield(stats_init,'signedrank')
        signedrank_init = stats_init.signedrank;
    end

    if isfield(stats_init,'zval')
        z_init = stats_init.zval;
    end

    fprintf('\n[%s]\n', assayNames{i});

    fprintf('Leader / leading proportion vs 0.5\n');
    fprintf('Test: two-tailed Wilcoxon signed-rank test\n');
    fprintf('N = %d\n', numel(leadDom));
    fprintf('Median = %.4f\n', median(leadDom,'omitnan'));
    fprintf('Mean = %.4f\n', mean(leadDom,'omitnan'));
    fprintf('Signed-rank statistic = %.4f\n', signedrank_leader);
    if ~isnan(z_leader)
        fprintf('Z = %.4f\n', z_leader);
    end
    fprintf('P = %.6g\n', p_leader);

    fprintf('\nInitiator / initiation proportion vs 0.5\n');
    fprintf('Test: two-tailed Wilcoxon signed-rank test\n');
    fprintf('N = %d\n', numel(initDom));
    fprintf('Median = %.4f\n', median(initDom,'omitnan'));
    fprintf('Mean = %.4f\n', mean(initDom,'omitnan'));
    fprintf('Signed-rank statistic = %.4f\n', signedrank_init);
    if ~isnan(z_init)
        fprintf('Z = %.4f\n', z_init);
    end
    fprintf('P = %.6g\n', p_init);

    T_leader = table( ...
        assayNames(i), ...
        {'LeadingProportion_vs_0.5'}, ...
        {'two-tailed Wilcoxon signed-rank'}, ...
        numel(leadDom), ...
        median(leadDom,'omitnan'), ...
        mean(leadDom,'omitnan'), ...
        signedrank_leader, ...
        z_leader, ...
        p_leader, ...
        'VariableNames', ...
        {'Assay','Comparison','Test','N','Median','Mean', ...
        'SignedRankStatistic','Z','PValue'});

    T_init = table( ...
        assayNames(i), ...
        {'InitiationProportion_vs_0.5'}, ...
        {'two-tailed Wilcoxon signed-rank'}, ...
        numel(initDom), ...
        median(initDom,'omitnan'), ...
        mean(initDom,'omitnan'), ...
        signedrank_init, ...
        z_init, ...
        p_init, ...
        'VariableNames', ...
        {'Assay','Comparison','Test','N','Median','Mean', ...
        'SignedRankStatistic','Z','PValue'});

    stats_table = [stats_table; T_leader; T_init];

end

assignin('base','stats_table',stats_table);

fprintf('===============================================\n');

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end

function col = get_column_by_keyword(T, varNames, varNamesLower, key)

idx = find(contains(varNamesLower, lower(key)));

if isempty(idx)
    error('Cannot find a column containing "%s". Columns:\n%s', ...
        key, strjoin(varNames, ', '));
elseif numel(idx) > 1
    error('Multiple matches for "%s": %s', ...
        key, strjoin(varNames(idx), ', '));
end

col = T.(varNames{idx});

end

function plot_dom_axis(leadDom, initDom, titleStr)

scatter(leadDom, initDom, 25, 'k', 'filled');
hold on;

xline(0.5, '--k', 'LineWidth', 1);
yline(0.5, '--k', 'LineWidth', 1);

hold off;

xlabel('Proportion of Leading');
ylabel('Proportion of Initiation');
title(titleStr);

set(gca,'FontSize',10, 'TickDir','out');
xlim([0 1]); ylim([0 1]);
axis square;

text(0.25, 0.9, 'Follower', 'Units','normalized', ...
    'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontSize',8);

text(0.75, 0.9, 'Leader', 'Units','normalized', ...
    'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontSize',8);

text(0.9, 0.15, 'Responder', 'Units','normalized', ...
    'HorizontalAlignment','left', 'VerticalAlignment','middle', ...
    'Rotation',90, 'FontSize',8);

text(0.9, 0.65, 'Initiator', 'Units','normalized', ...
    'HorizontalAlignment','left', 'VerticalAlignment','middle', ...
    'Rotation',90, 'FontSize',8);

end