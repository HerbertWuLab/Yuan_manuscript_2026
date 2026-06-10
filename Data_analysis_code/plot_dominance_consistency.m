function out = plot_dominance_consistency(fd)
% Plot pairwise dominance consistency with stacked bars
%
% Outputs to base workspace:
%   source_data
%   stats_table

filePath = fullfile(fd, '/data/social_hierarchy/stability_data.xlsx');

if ~exist(filePath, 'file')
    error('File not found: %s', filePath);
end

T = readtable(filePath, 'VariableNamingRule','preserve');
vars = T.Properties.VariableNames;

rewardW = find(strcmp(vars, 'Reward competition'));
tubeW   = find(strcmp(vars, 'Tube Test'));
warmW   = find(strcmp(vars, 'Warm spot'));

if isempty(rewardW) || isempty(tubeW) || isempty(warmW)
    error('Cannot find winner columns. Check Excel headers exactly.');
end

rewardS = rewardW + 1;
tubeS   = tubeW   + 1;
warmS   = warmW   + 1;

Reward      = T{:, rewardW};
Reward_stab = T{:, rewardS};
Tube        = T{:, tubeW};
Tube_stab   = T{:, tubeS};
Warm        = T{:, warmW};
Warm_stab   = T{:, warmS};

Reward_stab = strtrim(lower(Reward_stab));
Tube_stab   = strtrim(lower(Tube_stab));
Warm_stab   = strtrim(lower(Warm_stab));

isStable = @(s) strcmp(s, 'stable');

compCounts = @(A, As, B, Bs) local_comp_counts(A, As, B, Bs, isStable);

out.RT = compCounts(Reward, Reward_stab, Tube, Tube_stab);
out.TW = compCounts(Tube, Tube_stab, Warm, Warm_stab);
out.RW = compCounts(Reward, Reward_stab, Warm, Warm_stab);

labels = {'Reward & Tube','Tube & Warm','Reward & Warm'};

cons   = [out.RT.consistent, out.TW.consistent, out.RW.consistent];
both   = [out.RT.bothStable, out.TW.bothStable, out.RW.bothStable];
incons = both - cons;

vals = [cons(:), incons(:)];

source_data = table( ...
    labels(:), ...
    both(:), ...
    cons(:), ...
    incons(:), ...
    cons(:)./both(:), ...
    incons(:)./both(:), ...
    'VariableNames', ...
    {'Comparison','BothStable','Consistent','Inconsistent', ...
    'PropConsistent','PropInconsistent'});

assignin('base','source_data',source_data);

stats_table = source_data;
assignin('base','stats_table',stats_table);

fprintf('\nDominance consistency\n')
fprintf('========================================\n')
for i = 1:3
    fprintf('%s: bothStable=%d, consistent=%d, inconsistent=%d, prop consistent=%.4f\n', ...
        labels{i}, both(i), cons(i), incons(i), cons(i)/both(i));
end

fig = figure('Color','w','Units','pixels','Position',[100 100 300 300]);
ax = axes(fig);
hold(ax,'on');

barWidth = 0.6;
grey = [0.6 0.6 0.6];

hb = bar(ax, vals, 'stacked', 'BarWidth', barWidth);

hb(1).FaceColor = 'none';
hb(1).EdgeColor = 'k';
hb(1).LineWidth = 1.2;

hb(2).FaceColor = grey;
hb(2).EdgeColor = 'k';
hb(2).LineWidth = 1.2;

set(ax, 'XTick', 1:3, 'XTickLabel', labels, ...
    'TickDir','out', 'FontSize',10, ...
    'YLim',[0 40]);

ylabel(ax, 'No. of stable pairs');
title(ax, 'Pairwise dominance consistency');

box(ax,'on');
grid(ax,'off');

for i = 1:3
    text(ax, i, both(i), num2str(both(i)), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',9);
end

legend(ax, {'Consistent','Inconsistent'}, ...
    'Location','northoutside', 'Box','off');

hold(ax,'off');

outDir = fullfile(fd, 'plots');

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

figName = 'Pairwise_dominance_consistency_stable_pairs';

set(fig, 'PaperPositionMode','auto');
print(fig, fullfile(outDir, figName), '-dpdf', '-painters');

fprintf('\nSaved figure: %s\n', fullfile(outDir, figName))
fprintf('Saved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end

function s = local_comp_counts(A, As, B, Bs, isStable)

stableA = cellfun(isStable, As);
stableB = cellfun(isStable, Bs);

bothStable = stableA & stableB;
sameWinner = strcmp(A, B);

s.stableA    = sum(stableA);
s.stableB    = sum(stableB);
s.bothStable = sum(bothStable);
s.consistent = sum(bothStable & sameWinner);

end