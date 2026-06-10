function [ALL, corr_tbl, pval_tbl, r_pdf, p_pdf] = ...
    elo_rankings_and_correlations_cohort(fd, varargin)
%ELO_RANKINGS_AND_CORRELATIONS_COHORT
%
% Outputs to base workspace:
%   source_data
%   stats_table

%% ---------- parse inputs ----------
p = inputParser;

addRequired(p, 'fd', @(s)ischar(s)||isstring(s));

addParameter(p, 'FilePattern', '*_elo_results.xlsx', @(s)ischar(s)||isstring(s));
addParameter(p, 'EloSheet', 'elo_by_mouse', @(s)ischar(s)||isstring(s));
addParameter(p, 'OutExcel', 'elo_correlation_across_groups.xlsx', @(s)ischar(s)||isstring(s));
addParameter(p, 'OnlyUpper', false, @(x)islogical(x)&&isscalar(x));
addParameter(p, 'AssayCols', {}, @(c)iscellstr(c) || isstring(c));

parse(p, fd, varargin{:});

opt = p.Results;
fd = char(opt.fd);

%% ---------- set data dir + output dir ----------
results_dir = fullfile(fd, 'data', 'social_hierarchy');
out_dir     = fullfile(fd, 'plots');

if ~exist(results_dir, 'dir')
    error('Data folder not found: %s', results_dir);
end

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

file_pattern = fullfile(results_dir, char(opt.FilePattern));
elo_sheet    = char(opt.EloSheet);
out_all      = fullfile(out_dir, char(opt.OutExcel));

%% ---------- colors ----------
femaleRGB = [239,154,154]/255;
maleRGB   = [129,212,250]/255;

txtColor  = [1 1 0];
blackText = [0 0 0];

%% ---------- scan files ----------
files = dir(file_pattern);

if isempty(files)
    error('No files matched %s (searched in %s).', ...
        opt.FilePattern, results_dir);
end

%% ---------- cohort groups ----------
males   = {'YC191-194','YC195-198','YC199-202'};
females = {'AK118-121','AS001-004','YC211-214'};

male_prefixes   = lower(strtrim(string(males)));
female_prefixes = lower(strtrim(string(females)));

%% ---------- merge tables ----------
ALL = table();

for i = 1:numel(files)

    fn = fullfile(files(i).folder, files(i).name);

    T  = readtable(fn, 'Sheet', elo_sheet);

    [~, base, ~] = fileparts(fn);

    cohort   = regexprep(base, '_elo_results.*$', '');
    cohort_l = lower(strtrim(string(cohort)));

    T.cohort = repmat(string(cohort), height(T), 1);

    if any(startsWith(cohort_l, male_prefixes))
        sx = "male";
    elseif any(startsWith(cohort_l, female_prefixes))
        sx = "female";
    else
        warning('Cohort "%s" did not match groups.', cohort);
        sx = "unknown";
    end

    T.sex = repmat(sx, height(T), 1);

    ALL = [ALL; T];

end

%% ---------- source_data ----------
source_data = ALL;
assignin('base','source_data',source_data);

%% ---------- identify assay columns ----------
non_assay = {'mouse','group','strain','sex','cohort'};

all_cols  = ALL.Properties.VariableNames;

if isempty(opt.AssayCols)

    cand  = setdiff(all_cols, non_assay);

    isnum = varfun(@(c)isnumeric(c), ...
        ALL(:,cand), ...
        'OutputFormat','uniform');

    elo_cols = cand(isnum);

else

    elo_cols = intersect( ...
        cellstr(string(opt.AssayCols)), ...
        all_cols, ...
        'stable');

end

if isempty(elo_cols)
    error('No numeric assay columns found.');
end

labels = elo_cols;
labels_short = shorten_labels(labels);

n = numel(labels);

%% ---------- subsets ----------
subs = struct( ...
    'name', {'all','male','female'}, ...
    'mask', { ...
        true(height(ALL),1), ...
        ALL.sex=="male", ...
        ALL.sex=="female" ...
    });

%% ---------- colormaps ----------
darkGray  = [0.25 0.25 0.25];

cmap_all    = white_to_tint(darkGray, 256);
cmap_male   = white_to_tint(maleRGB, 256);
cmap_female = white_to_tint(femaleRGB, 256);

%% ---------- outputs ----------
r_pdf = strings(1,3);
p_pdf = strings(1,3);

corr_tbl = table();
pval_tbl = table();

stats_table = table();

writetable(ALL, out_all, 'Sheet', 'elo_by_mouse_all');

%% ============================================================
for g = 1:3

    S = subs(g);

    Tsub = ALL(S.mask, :);

    if height(Tsub) < 2

        warning('Subset "%s" has <2 rows (%d). Skip.', ...
            S.name, height(Tsub));

        r_pdf(g) = "";
        p_pdf(g) = "";

        continue;
    end

    X = table2array(Tsub(:, elo_cols));

    [R, P] = corrcoef(X, 'Rows','pairwise');

    if g == 1

        corr_tbl = array2table(R, ...
            'VariableNames', labels, ...
            'RowNames', labels);

        pval_tbl = array2table(P, ...
            'VariableNames', labels, ...
            'RowNames', labels);

    end

    writetable(array2table(R, ...
        'VariableNames',labels, ...
        'RowNames',labels), ...
        out_all, ...
        'Sheet', sprintf('elo_r_%s', S.name), ...
        'WriteRowNames', true);

    writetable(array2table(P, ...
        'VariableNames',labels, ...
        'RowNames',labels), ...
        out_all, ...
        'Sheet', sprintf('elo_p_%s', S.name), ...
        'WriteRowNames', true);

    %% ---------- stats table ----------
    fprintf('\n========================================\n');
    fprintf('Correlation statistics (%s)\n', S.name);
    fprintf('========================================\n');

    for i = 1:n

        for j = i+1:n

            r_val = R(i,j);
            p_val = P(i,j);

            fprintf('%s vs %s\n', labels{i}, labels{j});
            fprintf('r = %.4f\n', r_val);
            fprintf('p = %.6g\n\n', p_val);

            T_stat = table( ...
                string(S.name), ...
                string(labels{i}), ...
                string(labels{j}), ...
                r_val, ...
                p_val, ...
                height(Tsub), ...
                'VariableNames', ...
                {'Subset','Variable1','Variable2', ...
                'CorrelationR','PValue','N'});

            stats_table = [stats_table; T_stat];

        end
    end

    %% ---------- upper triangle ----------
    Rplot = R;
    Pplot = P;

    if opt.OnlyUpper

        L = tril(true(n), -1);

        Rplot(L) = NaN;
        Pplot(L) = NaN;

    end

    %% ---------- choose colors ----------
    if S.name == "all"

        cmap_r = cmap_all;
        thisTxtColor = blackText;

    elseif S.name == "male"

        cmap_r = cmap_male;
        thisTxtColor = txtColor;

    else

        cmap_r = cmap_female;
        thisTxtColor = txtColor;

    end

    %% ---------- r heatmap ----------
    fig1 = figure( ...
        'Color','w', ...
        'Units','pixels', ...
        'Position',[100 100 300 300]);

    imagesc(Rplot, 'AlphaData', ~isnan(Rplot));

    axis equal tight

    colormap(fig1, cmap_r);

    maxR = max(Rplot(~isnan(Rplot)), [], 'all');

    if isempty(maxR) || ~isfinite(maxR) || maxR <= 0
        maxR = 1;
    end

    clim([0 maxR]);

    cb = colorbar;
    cb.Label.String = 'r';

    set(gca, ...
        'XTick', 1:n, ...
        'XTickLabel', labels_short, ...
        'XTickLabelRotation', 45, ...
        'YTick', 1:n, ...
        'YTickLabel', labels_short, ...
        'TickDir','out', ...
        'FontSize', 7);

    title(sprintf('Elo r (%s)', S.name), ...
        'Interpreter','none');

    hold on

    for i2 = 1:n

        for j2 = 1:n

            if isnan(Rplot(i2,j2))
                continue;
            end

            stars = local_sigstars(Pplot(i2,j2));

            text(j2, i2, ...
                sprintf('%.2f%s', Rplot(i2,j2), stars), ...
                'HorizontalAlignment','center', ...
                'Color', thisTxtColor, ...
                'FontSize', 7, ...
                'FontWeight','bold');

        end
    end

    hold off

    r_pdf(g) = fullfile(out_dir, ...
        sprintf('elo_r_%s.pdf', S.name));

    set(fig1, 'PaperPositionMode','auto');

    print(fig1, '-dpdf', '-vector', r_pdf(g));

    %% ---------- p heatmap ----------
    fig2 = figure( ...
        'Color','w', ...
        'Units','pixels', ...
        'Position',[420 100 300 300]);

    neglogP = -log10(Pplot);

    imagesc(neglogP, 'AlphaData', ~isnan(neglogP));

    axis equal tight

    colormap(fig2, parula(256));

    cb2 = colorbar;
    cb2.Label.String = '-log10(p)';

    set(gca, ...
        'XTick', 1:n, ...
        'XTickLabel', labels_short, ...
        'XTickLabelRotation', 45, ...
        'YTick', 1:n, ...
        'YTickLabel', labels_short, ...
        'TickDir','out', ...
        'FontSize', 7);

    title(sprintf('-log10(p) (%s)', S.name), ...
        'Interpreter','none');

    hold on

    for i2 = 1:n

        for j2 = 1:n

            if isnan(Pplot(i2,j2))
                continue;
            end

            stars = local_sigstars(Pplot(i2,j2));

            if ~isempty(stars)

                text(j2, i2, stars, ...
                    'HorizontalAlignment','center', ...
                    'Color', txtColor, ...
                    'FontSize', 9, ...
                    'FontWeight','bold');

            end
        end
    end

    hold off

    p_pdf(g) = fullfile(out_dir, ...
        sprintf('elo_p_%s.pdf', S.name));

    set(fig2, 'PaperPositionMode','auto');

    print(fig2, '-dpdf', '-vector', p_pdf(g));

end

assignin('base','stats_table',stats_table);

fprintf('\n========================================\n');
fprintf('N (all)    = %d\n', sum(subs(1).mask));
fprintf('N (male)   = %d\n', sum(subs(2).mask));
fprintf('N (female) = %d\n', sum(subs(3).mask));
fprintf('========================================\n');

fprintf('Exported excel:\n%s\n', out_all);

disp(r_pdf);
disp(p_pdf);

fprintf('\nSaved to base workspace:\n');
fprintf('source_data\n');
fprintf('stats_table\n');

end

%% ===== local helper: p -> stars =====
function s = local_sigstars(p)

if isnan(p)

    s = '';

    return;

end

if p < 0.001

    s = '***';

elseif p < 0.01

    s = '**';

elseif p < 0.05

    s = '*';

elseif p < 0.10

    s = '#';

else

    s = '';

end

end

%% ===== shorten labels =====
function lbl2 = shorten_labels(lbl)

lbl2 = string(lbl);

lbl2 = replace(lbl2, "Reward competition", "Reward");
lbl2 = replace(lbl2, "Tube Test",          "Tube");
lbl2 = replace(lbl2, "Warm spot",          "Warm");

lbl2 = replace(lbl2, "_", " ");
lbl2 = replace(lbl2, "proportion", "prop");
lbl2 = replace(lbl2, "Probability", "Prob");
lbl2 = replace(lbl2, "percentage", "pct");

lbl2 = cellstr(lbl2);

end

%% ===== white -> tint colormap =====
function cmap = white_to_tint(tintRGB, n)

tintRGB = reshape(tintRGB, 1, 3);

x = linspace(0, 1, n)';

cmap = (1 - x) .* 1 + x .* tintRGB;

end