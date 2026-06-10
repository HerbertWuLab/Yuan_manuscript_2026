function fig = cumulative_curve_demo(fd)
% Read Excel data
filename = [fd 'Data/cumulative_data.xlsx']; 
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
figname = [fd 'plots/' hoy 'p_cumu_learning_curve'];
print(fig,figname,'-dpdf');

