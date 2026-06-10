function out = compare_sex_stability_reward(fd)
% Compare male vs female stability probability across 3 tests:
% Reward competition / Tube Test / Warm spot
% One figure per test (200 x 300)
% Y: proportion of stable pairs
% Bars: Female vs Male
% Save PDFs under fd/plots

%% ---- Colors (WuLab style) ----
sexes = {'female','male'};
fill_colors = [239,154,154;129,212,250] / 255;     % female, male
line_colors = [183,28,28;  1,87,155] / 255;        % female, male

%% ---- Locate file ----
filePath = fullfile(fd, '/data/social_hierarchy/stability_data.xlsx');
if ~exist(filePath, 'file')
    error('File not found: %s', filePath);
end

%% ---- Read data ----
T = readtable(filePath, 'VariableNamingRule','preserve');
vars = T.Properties.VariableNames;

%% ---- Find required columns ----
sexCol = find(strcmp(vars, 'sex'), 1);
if isempty(sexCol)
    error('Cannot find required column: sex');
end
sexRaw = lower(strtrim(string(T{:, sexCol})));

% test columns (exact headers)
testNames = {'Reward competition','Tube Test','Warm spot'};
testShort = {'Reward','Tube','Warm'};
nTests = numel(testNames);

stabCol = nan(1,nTests);
for t = 1:nTests
    c = find(strcmp(vars, testNames{t}), 1);
    if isempty(c)
        error('Cannot find test column: "%s"', testNames{t});
    end
    if c+1 > width(T)
        error('Stability column out of range for "%s".', testNames{t});
    end
    stabCol(t) = c + 1;

    % optional sanity check
    if ~contains(lower(vars{stabCol(t)}), 'stability')
        warning('Column after "%s" is "%s" (does not contain "stability"). Proceed anyway.', ...
            testNames{t}, vars{stabCol(t)});
    end
end

%% ---- Compute proportions ----
out = struct();
out.tests = testNames;

pStable = nan(nTests, 2);   % rows=test, cols=sex (female, male)
nStable = zeros(nTests, 2);
nTotal  = zeros(nTests, 2);

for t = 1:nTests
    stab = lower(strtrim(string(T{:, stabCol(t)})));
    isStable = (stab == "stable");

    for s = 1:2
        isSex = (sexRaw == sexes{s});
        nTotal(t,s)  = sum(isSex);
        nStable(t,s) = sum(isSex & isStable);
        pStable(t,s) = nStable(t,s) / max(nTotal(t,s), 1);
    end
end

out.pStable = pStable;
out.nStable = nStable;
out.nTotal  = nTotal;

%% ---- Plot: one figure per test ----
outDir = fullfile(fd, 'plots');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

barWidth = 0.6;

for t = 1:nTests
    fig = figure('Color','w','Units','pixels','Position',[100 100 200 300]);
    ax = axes(fig); %#ok<LAXES>
    hold(ax,'on');

    vals = pStable(t, :);  % [female, male]

    % Female bar (x=1)
    bar(ax, 1, vals(1), barWidth, ...
        'FaceColor', fill_colors(1,:), ...
        'EdgeColor', line_colors(1,:), ...
        'LineWidth', 1.2);

    % Male bar (x=2)
    bar(ax, 2, vals(2), barWidth, ...
        'FaceColor', fill_colors(2,:), ...
        'EdgeColor', line_colors(2,:), ...
        'LineWidth', 1.2);

    set(ax, ...
        'XTick', 1:2, ...
        'XTickLabel', {'Female','Male'}, ...
        'TickDir','out', ...
        'FontSize', 10);

    ylabel(ax, 'Proportion of stable pairs');
    title(ax, testShort{t});
    ylim(ax, [0 1]);
    box(ax, 'on');
    grid(ax, 'off');

    % annotate counts in the middle of each bar
    for s = 1:2
        y = vals(s) / 2;
        txt = sprintf('%d/%d', nStable(t,s), nTotal(t,s));
        text(ax, s, y, txt, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'FontSize',8);
    end

    % legend (use dummy handles so it always works)
    hF = plot(ax, nan, nan, 's', 'MarkerFaceColor', fill_colors(1,:), 'MarkerEdgeColor', line_colors(1,:));
    hM = plot(ax, nan, nan, 's', 'MarkerFaceColor', fill_colors(2,:), 'MarkerEdgeColor', line_colors(2,:));
    legend(ax, [hF hM], {'Female','Male'}, 'Location','northoutside', 'Box','off');

    hold(ax,'off');

    % save
    figName = sprintf('Stability_sex_%s', testShort{t});
    set(fig, 'PaperPositionMode','auto');
    print(fig, fullfile(outDir, figName), '-dpdf', '-painters');
end

out.outDir = outDir;

%% ---- Command window summary ----
fprintf('\nStability proportions (stable/total):\n');
for t = 1:nTests
    fprintf('%s\n', testNames{t});
    fprintf('  Female: %d/%d (%.3f)\n', nStable(t,1), nTotal(t,1), pStable(t,1));
    fprintf('  Male:   %d/%d (%.3f)\n', nStable(t,2), nTotal(t,2), pStable(t,2));
end

end
