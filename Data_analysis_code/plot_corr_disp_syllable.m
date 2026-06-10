function plot_corr_disp_syllable(syllable_table, fd, num_name)
%%
% plot_corro_disp_syllable - Plot correlations between syllable proportions and disparity metrics
%
% Syntax:
%   plot_corro_disp_syllable(syllable_table, fd, num_name)
%
% Inputs:
%   syllable_table - A table containing proportion and disparity columns
%   fd             - Directory path to save the plots
%   num_name       - Cell array of syllable names (e.g., {'n_join_Lead', 'n_sharp_Foll'})
%
% This function generates scatter plots with regression lines showing the
% correlation between the proportion of specified syllables and metrics like
% leader disparity (p_ledBy) and initiator disparity (p_initBy). Results are
% saved as PDF files in the specified directory.

% % Check for required columns in the input table
% required_columns = [strcat('proportion_', num_name), {'p_ledBy_sLead', 'p_initBy_sInit', 'p_initBy_sLead'}];
% if ~all(ismember(required_columns, syllable_table.Properties.VariableNames))
%     error('syllable_table is missing required columns.');
% end

% Define directory to save output plots
save_dir = fullfile(fd, 'plots');
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Define color scheme
lead_color = hex2rgb('#c2a5cf'); % Purple for Leader syllables
foll_color = hex2rgb('#a6dba0'); % Green for Follower syllables
sync_color = hex2rgb('#cb7831'); % Orange-brown for Sync syllables

% Loop through each specified syllable
for i = 1:length(num_name)
    syllable = num_name{i};

    % Assign point color based on syllable type
    if contains(syllable, '_Lead')
        point_color = lead_color;
    elseif contains(syllable, '_Foll')
        point_color = foll_color;
    else
        point_color = sync_color;
    end

    % Extract data
    proportion = syllable_table.(['proportion_' syllable]);
    p_ledBy_sLead = syllable_table.p_ledBy_sLead;
    p_ledBy_sFoll = syllable_table.p_ledBy_sFoll;
    p_initBy_sInit = syllable_table.p_initBy_sInit;
    p_initBy_sLead = syllable_table.p_initBy_sLead;

    % Create figure
    figure;
    set(gcf, 'Position', [100, 100, 300, 300]); % Set figure size

    if contains(syllable, '_Foll')
        p_ledBy = p_ledBy_sFoll;
        xlabel_str = 'p\_ledBy\_sFoll';
    else
        p_ledBy = p_ledBy_sLead;
        xlabel_str = 'p\_ledBy\_sLead';
    end
    plot_scatter_with_regression(1 - p_ledBy, proportion, ...
        xlabel_str, ['Proportion of Syllable ' strrep(syllable, '_', '\_')], ...
        [strrep(syllable, '_', '\_') ' vs ' xlabel_str], ...
        point_color);

    % Save figure as PDF
    save_name = fullfile(save_dir, ['correlation of ' syllable '.pdf']);
    set(gcf, 'PaperUnits', 'points');
    set(gcf, 'PaperSize', [900, 300]);
    print(gcf, save_name, '-dpdf');
end
end

% --- Helper function to plot scatter with regression line ---
function plot_scatter_with_regression(x, y, xlabel_str, ylabel_str, title_str, point_color)
scatter(x, y, 50, 'filled', 'MarkerFaceColor', point_color, 'MarkerEdgeColor', 'k', 'LineWidth', 0.1);
hold on;

% Fit linear regression model
mdl = fitlm(x, y);
coeff = mdl.Coefficients.Estimate;
R = sqrt(mdl.Rsquared.Ordinary);
P = mdl.Coefficients.pValue(2);

% Plot regression line
x_fit = linspace(min(x), max(x), 100);
y_fit = coeff(1) + coeff(2) * x_fit;
plot(x_fit, y_fit, 'Color', point_color, 'LineWidth', 1.5);

% Display R and P values
text(0.1, 0.9, sprintf('R = %.2f\nP = %.3f', R, P), ...
    'Units', 'normalized', 'FontSize', 10, 'Color', 'k');

% Set labels and axes properties
xlabel(xlabel_str);
ylabel(ylabel_str);
title(title_str);

xlim_vals = xlim();
ylim_vals = ylim();
x_margin = range(xlim_vals) * 0.05;
y_margin = range(ylim_vals) * 0.05;
xlim([xlim_vals(1) - x_margin, xlim_vals(2) + x_margin]);
ylim([ylim_vals(1) - y_margin, ylim_vals(2) + y_margin]);

xticks(xlim_vals(1):0.2:xlim_vals(2));
yticks(ylim_vals(1):0.2:ylim_vals(2));
xtickformat('%.1f');
ytickformat('%.1f');
set(gca, 'FontSize', 20, 'TickDir', 'out');
pbaspect([1 1 1]); % Set aspect ratio to 1:1
end

% --- Helper function to convert hex color string to RGB triplet ---
function rgb = hex2rgb(hex)
hex = strrep(hex, '#', ''); % Remove hash symbol
rgb = sscanf(hex, '%2x%2x%2x', [1, 3]) / 255;
end
