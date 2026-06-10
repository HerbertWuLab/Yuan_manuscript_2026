function plot_corro_disp_syllable(syllable_table, fd, sex_sel)
% plot_corro_disp_syllable(syllable_table, fd, sex_sel)
%
% sex_sel:
%   - 'male'   : only male
%   - 'female' : only female
%   - 'both'   : pooled sexes
%   - or a list like {'female','male','both'} / ["female","male","both"]
%
% Outputs to base workspace:
%   source_data
%   stats_table

if nargin < 3 || isempty(sex_sel)
    sex_sel = "both";
end

sex_sel = lower(string(sex_sel));
sex_sel = sex_sel(:)';

valid_modes = ["male","female","both"];
if ~all(ismember(sex_sel, valid_modes))
    bad = sex_sel(~ismember(sex_sel, valid_modes));
    error("sex_sel must be 'male', 'female', or 'both' (or a list). Invalid: %s", strjoin(bad, ", "));
end

if ~ismember('sex', syllable_table.Properties.VariableNames)
    error('syllable_table 缺少 sex 列。请先添加 sex 列。');
end

num_name = {'n_sharp_Foll','n_join_Lead','n_join_Foll','n_track_Foll','n_sync'};

required_columns = [ ...
    strcat('proportion_', num_name), ...
    {'p_ledBy_sLead','p_ledBy_sFoll','p_initBy_sInit','p_initBy_sLead'} ...
    ];

if ~all(ismember(required_columns, syllable_table.Properties.VariableNames))
    error('syllable_table is missing required columns.');
end

save_dir = fd;
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

lead_color = hex2rgb('#c2a5cf');
foll_color = hex2rgb('#a6dba0');
sync_color = hex2rgb('#cb7831');

sx_all = lower(strtrim(string(syllable_table.sex)));

source_data = table();
stats_table = table();

for s = 1:numel(sex_sel)

    mode = sex_sel(s);

    switch mode
        case "male"
            sel_idx = (sx_all == "male");
        case "female"
            sel_idx = (sx_all == "female");
        case "both"
            sel_idx = ismember(sx_all, ["male","female"]);
    end

    sex_table = syllable_table(sel_idx, :);

    if height(sex_table) == 0
        warning('No data found for sex_sel = %s. Skipping.', mode);
        continue;
    end

    for i = 1:length(num_name)

        if contains(num_name{i}, '_Lead')
            point_color = lead_color;
        elseif contains(num_name{i}, '_Foll')
            point_color = foll_color;
        else
            point_color = sync_color;
        end

        proportion = sex_table.(['proportion_' num_name{i}]);
        p_initBy_sInit = sex_table.p_initBy_sInit;
        p_initBy_sLead = sex_table.p_initBy_sLead;

        figure('Position', [100, 100, 900, 300]);

        subplot(1, 3, 1);
        if contains(num_name{i}, '_Foll')
            p_ledBy = sex_table.p_ledBy_sFoll;
            xlabel_str = 'p\_ledBy\_sFoll';
            predictor_name = 'p_ledBy_sFoll';
        else
            p_ledBy = sex_table.p_ledBy_sLead;
            xlabel_str = 'p\_ledBy\_sLead';
            predictor_name = 'p_ledBy_sLead';
        end

        [T_source,T_stats] = plot_scatter_with_regression( ...
            1 - p_ledBy, proportion, ...
            xlabel_str, ...
            ['Proportion of syllable ' strrep(num_name{i}, '_', '\_')], ...
            [strrep(num_name{i}, '_', '\_') ' vs ' xlabel_str ' (' char(mode) ')'], ...
            point_color, ...
            mode, ...
            num_name{i}, ...
            ['1_minus_' predictor_name]);

        source_data = [source_data; T_source];
        stats_table = [stats_table; T_stats];

        subplot(1, 3, 2);
        [T_source,T_stats] = plot_scatter_with_regression( ...
            p_initBy_sInit, proportion, ...
            'p\_initBy\_sInit', ...
            ['Proportion of syllable ' strrep(num_name{i}, '_', '\_')], ...
            [strrep(num_name{i}, '_', '\_') ' vs p\_initBy\_sInit (' char(mode) ')'], ...
            point_color, ...
            mode, ...
            num_name{i}, ...
            'p_initBy_sInit');

        source_data = [source_data; T_source];
        stats_table = [stats_table; T_stats];

        subplot(1, 3, 3);
        [T_source,T_stats] = plot_scatter_with_regression( ...
            p_initBy_sLead, proportion, ...
            'p\_initBy\_sLead', ...
            ['Proportion of syllable ' strrep(num_name{i}, '_', '\_')], ...
            [strrep(num_name{i}, '_', '\_') ' vs p\_initBy\_sLead (' char(mode) ')'], ...
            point_color, ...
            mode, ...
            num_name{i}, ...
            'p_initBy_sLead');

        source_data = [source_data; T_source];
        stats_table = [stats_table; T_stats];

        base = ['correlation_of_' num_name{i} '_' char(mode) '.pdf'];
        save_name = fullfile(save_dir, base);

        set(gcf, 'PaperUnits', 'points');
        set(gcf, 'PaperSize', [900, 300]);
        print(gcf, save_name, '-dpdf');
        % close(gcf);

    end
end

assignin('base','source_data',source_data);
assignin('base','stats_table',stats_table);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end

function [source_data,stats_table] = plot_scatter_with_regression(x, y, xlabel_str, ylabel_str, title_str, point_color, sex_mode, syllable_name, predictor_name)

x = x(:);
y = y(:);

valid = ~isnan(x) & ~isnan(y);
x_valid = x(valid);
y_valid = y(valid);

source_data = table( ...
    repmat({char(sex_mode)},length(x_valid),1), ...
    repmat({syllable_name},length(x_valid),1), ...
    repmat({predictor_name},length(x_valid),1), ...
    (1:length(x_valid))', ...
    x_valid, ...
    y_valid, ...
    'VariableNames', ...
    {'SexMode','Syllable','Predictor','SampleIndex','X','Y'});

scatter(x_valid, y_valid, 20, 'filled', ...
    'MarkerFaceColor', point_color, ...
    'MarkerEdgeColor', 'k', ...
    'LineWidth', 0.1);

hold on;

mdl = fitlm(x_valid, y_valid);

coeff = mdl.Coefficients.Estimate;
R = sqrt(mdl.Rsquared.Ordinary);
P = mdl.Coefficients.pValue(2);

x_fit = linspace(min(x_valid), max(x_valid), 100);
y_fit = coeff(1) + coeff(2) * x_fit;

plot(x_fit, y_fit, 'Color', point_color, 'LineWidth', 1.5);

text(0.1, 0.9, sprintf('R = %.2f\nP = %.3f', R, P), ...
    'Units', 'normalized', 'FontSize', 10, 'Color', 'k');

xlabel(xlabel_str);
ylabel(ylabel_str);
title(title_str);

set(gca,'FontSize',20,'TickDir','out');
pbaspect([1 1 1]);

fprintf('\n========================================\n')
fprintf('%s\n', title_str)
fprintf('========================================\n')
fprintf('Test: linear regression\n')
fprintf('Model: Y ~ X\n')
fprintf('N = %d\n', mdl.NumObservations)
fprintf('Intercept = %.6f\n', coeff(1))
fprintf('Slope = %.6f\n', coeff(2))
fprintf('SE slope = %.6f\n', mdl.Coefficients.SE(2))
fprintf('t slope = %.6f\n', mdl.Coefficients.tStat(2))
fprintf('P slope = %.6g\n', P)
fprintf('R = %.6f\n', R)
fprintf('R^2 = %.6f\n', mdl.Rsquared.Ordinary)

stats_table = table( ...
    {char(sex_mode)}, ...
    {syllable_name}, ...
    {predictor_name}, ...
    {'linear regression'}, ...
    mdl.NumObservations, ...
    coeff(1), ...
    coeff(2), ...
    mdl.Coefficients.SE(2), ...
    mdl.Coefficients.tStat(2), ...
    mdl.Coefficients.pValue(2), ...
    mdl.Rsquared.Ordinary, ...
    R, ...
    'VariableNames', ...
    {'SexMode','Syllable','Predictor','Test','N', ...
    'Intercept','Slope','SlopeSE','SlopeTStat','SlopePValue', ...
    'RSquared','R'});

end

function rgb = hex2rgb(hex)
hex = strrep(hex, '#', '');
rgb = sscanf(hex, '%2x%2x%2x', [1, 3]) / 255;
end