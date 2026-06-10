%% for Figure 1b
% Read Excel data
fd = '/Users/herbert/Wulab Dropbox/Herbert/Research/Projects/SocialForaging/Yuan_manuscript_demo/';
filename = [fd 'cumulative_data.xlsx']; 
data = readtable(filename);

% Extract cumulative distribution data for Female and Male mice
female_days = data{:, 1};  % First column represents training days for Female mice
female_cdf = data{:, 3};   % Third column represents cumulative rate for Female mice
male_days = data{:, 5};    % Fifth column represents training days for Male mice
male_cdf = data{:, 7};     % Seventh column represents cumulative rate for Male mice

% Remove NaN values
female_valid = ~isnan(female_days) & ~isnan(female_cdf);
male_valid = ~isnan(male_days) & ~isnan(male_cdf);
female_days = female_days(female_valid);
female_cdf = female_cdf(female_valid);
male_days = male_days(male_valid);
male_cdf = male_cdf(male_valid);
n_females = length(female_days);
n_males = length(male_days);

% Calculate failure rates (more than 30 days without reaching the standard is considered a failure)
female_failed = sum(female_days > 30) / length(female_days);
male_failed = sum(male_days > 30) / length(male_days);

% Generate failure rates table
failure_rates = table(female_failed, male_failed, 'VariableNames', {'Female_Failure_Rate', 'Male_Failure_Rate'});
disp(failure_rates);

% Perform KS test (based on the original days data)
[h, p, ks_stat] = kstest2(female_days, male_days);

% Output KS test results table
results = table(h, p, ks_stat, 'VariableNames', {'Hypothesis_Rejected', 'P_value', 'KS_Statistic'});
disp(results);

%% Plot cumulative distribution curves
fig = figure('Position',[800 200 400 600]);
% plot(female_days, female_cdf, 'Color', "#d7191c", 'LineWidth', 2, 'DisplayName', 'Female');
plot(female_days, female_cdf, 'Color', "#b31f2c", 'LineWidth', 2, 'DisplayName', 'Female');
hold on;
plot(male_days, male_cdf, 'Color', "#2166ac", 'LineWidth', 2, 'DisplayName', 'Male');
% plot(male_days, male_cdf, 'Color', "#2b83ba", 'LineWidth', 2, 'DisplayName', 'Male');
hold off;
legend('Location','southeast');
xlim([0 50]);
xlabel('Training days');
ylabel('Proportion reaching criterion');
title('Culumative learning curve');
legend({['Female (' num2str(n_females) ' pairs)']; ['Male (' num2str(n_males) ' pairs)']},'Location','southeast');
legend box off
box off
set(gca,'FontSize',24,'TickDir','out')

% Display P-value above the cumulative distribution plot
text(32, 0.3, sprintf('P = %.3f (KS test)', p), 'HorizontalAlignment', 'center',...
    'FontSize',20,'Color', 'k');
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd hoy 'p_cumu_learning_curve'];
print(fig,figname,'-dpdf');

%% Cooperation Rate of Mice When Reaching the Criterion
% Read cooperation rate data (assuming Female in column 2, Male in column 4)
female_coop_rate = data{:, 4}; % Fourth column for cooperation rate of Female mice
male_coop_rate = data{:, 8};   % Eighth column for cooperation rate of Male mice

% Remove NaN values
female_coop_rate = female_coop_rate(~isnan(female_coop_rate));
male_coop_rate = male_coop_rate(~isnan(male_coop_rate));

% Remove points less than 80%
female_coop_rate = female_coop_rate(female_coop_rate >= 0.8);
male_coop_rate = male_coop_rate(male_coop_rate >= 0.8);

% % If cooperation rate is a percentage (0-100), convert to decimal (0-1)
% if max(female_coop_rate) > 1 || max(male_coop_rate) > 1
%     female_coop_rate = female_coop_rate / 100;
%     male_coop_rate = male_coop_rate / 100;
% end

% Calculate mean and standard error (SE = std / sqrt(n))
female_mean = mean(female_coop_rate);
male_mean = mean(male_coop_rate);
female_se = std(female_coop_rate) / sqrt(length(female_coop_rate));
male_se = std(male_coop_rate) / sqrt(length(male_coop_rate));

% Create data table for plotting
means = [female_mean, male_mean] * 100; % Convert back to percentage
errors = [female_se, male_se] * 100; % Convert back to percentage

% Color definitions
female_color = [1, 0.75, 0.8]; % Pink
male_color = [0, 0, 1]; % Blue

% Plot bar graph
figure;
hold on;
bar_width = 0.5; % Set bar width

% Draw Female and Male bar graphs (no fill, just borders)
bar(1, means(1), bar_width, 'FaceColor', 'none', 'EdgeColor', female_color, 'LineWidth', 2);
bar(2, means(2), bar_width, 'FaceColor', 'none', 'EdgeColor', male_color, 'LineWidth', 2);

% Add error bars (only showing the upper half)
errorbar(1:2, means, errors, 'k', 'LineStyle', 'none', 'CapSize', 8, 'LineWidth', 1.5, 'YNegativeDelta', []);

% Plot scatter plot (center aligned)
scatter(ones(size(female_coop_rate)), female_coop_rate * 100, 10, female_color, 'filled');
scatter(2 * ones(size(male_coop_rate)), male_coop_rate * 100, 10, male_color, 'filled');

% Set X-axis labels
xticks([1 2]);
xticklabels({'Female', 'Male'});

% Set Y-axis range (percentage display)
ylim([0 100]);
ylabel('Cooperation Rate (%)');
title('Cooperation Rate of Mice When Reaching the Criterion'); % Updated title

% Beautify the image
grid off;
box off;
hold off;

% Perform independent samples t-test
[h_coop, p_coop] = ttest2(female_coop_rate, male_coop_rate);

% Display P-value above the bar graph
text(1.5, means(1) + 1, sprintf('P = %.3f', p_coop), 'HorizontalAlignment', 'center', 'Color', 'k');


%% Proportion of Mice Trained Under 30 Days
% Read days data
female_days = data{:, 1}; % First column for Female mice days
male_days = data{:, 5};   % Fifth column for Male mice days

% Remove NaN data
female_days = female_days(~isnan(female_days));
male_days = male_days(~isnan(male_days));

% Calculate the proportion of days less than 30
female_below_30 = sum(female_days < 30) / length(female_coop_rate > 0.8);
male_below_30 = sum(male_days < 30) / length(male_coop_rate > 0.8);

% Store proportions
proportions = [female_below_30, male_below_30] * 100; % Convert to percentage

% Perform independent samples t-test
[h_days, p_days] = ttest2(female_days, male_days);

% Plot bar graph showing the proportion of days less than 30
figure;
bar_width = 0.4; % Set bar width
hold on; % Hold the graph

% Draw Female and Male bar graphs (no fill, just borders)
b1 = bar(1, proportions(1), bar_width, 'FaceColor', 'none', 'EdgeColor', female_color, 'LineWidth', 2);
b2 = bar(2, proportions(2), bar_width, 'FaceColor', 'none', 'EdgeColor', male_color, 'LineWidth', 2);
hold off; % Release the graph

% Set X-axis labels
xticks([1 2]);
xticklabels({'Female', 'Male'});

% Set Y-axis range (percentage display)
ylabel('Proportion of Mice < 30 Days (%)');
title('Proportion of Mice Trained Under 30 Days'); % Updated title
ylim([0 100]);
grid off;

% Display bar values on top of the bars
text(1, proportions(1) + 2, sprintf('%.1f%%', proportions(1)), ...
    'HorizontalAlignment', 'center', 'Color', female_color);
text(2, proportions(2) + 2, sprintf('%.1f%%', proportions(2)), ...
    'HorizontalAlignment', 'center', 'Color', male_color);

% Display P-value above the bar graph
text(1.5, max(proportions) + 1, sprintf('P = %.3f', p_days), ...
    'HorizontalAlignment', 'center', 'Color', 'k');

