function plt_pledBy_mouseVSdot(criterion_table, fd)
% plt_pledBy_mouseVSdot
% Animal-level paired comparison of leadership probability:
%   - m1/dot vs m2/mouse
%
% Outputs to base workspace:
%   source_data
%   stats_table

%% ---------- output directory ----------
plot_dir = fullfile(fd, 'plots');
if ~exist(plot_dir, 'dir')
    mkdir(plot_dir);
end

%% ---------- sanity checks ----------
req_vars = {'pair','p_ledBy_m1','p_ledBy_m2'};
for i = 1:numel(req_vars)
    if ~ismember(req_vars{i}, criterion_table.Properties.VariableNames)
        error('criterion_table missing required variable: %s', req_vars{i});
    end
end

%% ---------- group by animal/pair ----------
pairv = criterion_table.pair;

if iscategorical(pairv)
    pairv = string(pairv);
end

if iscell(pairv)
    pairv = string(pairv);
end

pairv = string(pairv);

p_dot_ses   = criterion_table.p_ledBy_m1;
p_mouse_ses = criterion_table.p_ledBy_m2;

% keep session rows where both are present
valid_row = ~isnan(p_dot_ses) & ~isnan(p_mouse_ses) & (pairv ~= "");

pairv = pairv(valid_row);
p_dot_ses = p_dot_ses(valid_row);
p_mouse_ses = p_mouse_ses(valid_row);

if isempty(pairv)
    error('No valid rows found after filtering NaNs.');
end

[G, uni_pairs] = findgroups(pairv);

% aggregate sessions within each pair
p_dot_animal = splitapply(@(x) mean(x,'omitnan'), p_dot_ses, G);
p_mouse_animal = splitapply(@(x) mean(x,'omitnan'), p_mouse_ses, G);

temp = [p_dot_animal, p_mouse_animal];

% remove animals that still have NaN after aggregation
valid_animal = ~isnan(temp(:,1)) & ~isnan(temp(:,2));

temp = temp(valid_animal,:);
uni_pairs = uni_pairs(valid_animal);

if isempty(temp)
    error('No valid animal-level paired data found after aggregation.');
end

N = size(temp,1);

fprintf('\n========================================\n')
fprintf('Leadership probability: dot vs mouse\n')
fprintf('========================================\n')
fprintf('N animals / pairs = %d\n', N)

%% ---------- source data ----------
source_data = table( ...
    uni_pairs, ...
    temp(:,1), ...
    temp(:,2), ...
    temp(:,2) - temp(:,1), ...
    'VariableNames', ...
    {'Pair','MiceFollow_m1_dot','MiceLead_m2_mouse', ...
    'Difference_mouse_minus_dot'});

assignin('base','source_data',source_data);

%% ---------- statistics ----------
[p,~,stats] = signrank(temp(:,1), temp(:,2));

median_dot = median(temp(:,1),'omitnan');
median_mouse = median(temp(:,2),'omitnan');
median_diff = median(temp(:,2) - temp(:,1),'omitnan');

mean_dot = mean(temp(:,1),'omitnan');
mean_mouse = mean(temp(:,2),'omitnan');
mean_diff = mean(temp(:,2) - temp(:,1),'omitnan');

sd_dot = std(temp(:,1),'omitnan');
sd_mouse = std(temp(:,2),'omitnan');
sd_diff = std(temp(:,2) - temp(:,1),'omitnan');

sem_dot = sd_dot / sqrt(N);
sem_mouse = sd_mouse / sqrt(N);
sem_diff = sd_diff / sqrt(N);

signedrank_stat = NaN;
zval = NaN;

if isfield(stats,'signedrank')
    signedrank_stat = stats.signedrank;
end

if isfield(stats,'zval')
    zval = stats.zval;
end

fprintf('Test: paired Wilcoxon signed-rank test\n')
fprintf('Mice follow median = %.4f\n', median_dot)
fprintf('Mice lead median = %.4f\n', median_mouse)
fprintf('Median difference (lead - follow) = %.4f\n\n', median_diff)

fprintf('Mice follow mean = %.4f\n', mean_dot)
fprintf('Mice lead mean = %.4f\n', mean_mouse)
fprintf('Mean difference (lead - follow) = %.4f\n\n', mean_diff)

fprintf('Mice follow SD = %.4f\n', sd_dot)
fprintf('Mice lead SD = %.4f\n', sd_mouse)
fprintf('Difference SD = %.4f\n', sd_diff)

fprintf('Mice follow SEM = %.4f\n', sem_dot)
fprintf('Mice lead SEM = %.4f\n', sem_mouse)
fprintf('Difference SEM = %.4f\n\n', sem_diff)

fprintf('Signed-rank statistic = %.4f\n', signedrank_stat)

if ~isnan(zval)
    fprintf('Z = %.4f\n', zval)
end

fprintf('P = %.6g\n', p)

stats_table = table( ...
    {'MiceFollow_vs_MiceLead'}, ...
    {'paired Wilcoxon signed-rank'}, ...
    N, ...
    median_dot, ...
    median_mouse, ...
    median_diff, ...
    mean_dot, ...
    mean_mouse, ...
    mean_diff, ...
    sd_dot, ...
    sd_mouse, ...
    sd_diff, ...
    sem_dot, ...
    sem_mouse, ...
    sem_diff, ...
    signedrank_stat, ...
    zval, ...
    p, ...
    'VariableNames', ...
    {'Comparison','Test','N', ...
    'Median_MiceFollow','Median_MiceLead','MedianDifference_LeadMinusFollow', ...
    'Mean_MiceFollow','Mean_MiceLead','MeanDifference_LeadMinusFollow', ...
    'SD_MiceFollow','SD_MiceLead','SD_Difference', ...
    'SEM_MiceFollow','SEM_MiceLead','SEM_Difference', ...
    'SignedRankStatistic','Z','PValue'});

assignin('base','stats_table',stats_table);

%% ---------- colors ----------
color_single = [0.6 0.6 0.6];
color_med = [0.2 0.2 0.2];

%% ---------- plot ----------
figure('Position',[600 300 200 400]); 
hold on;

plot(temp', ...
    'LineWidth',1, ...
    'Color',color_single, ...
    'Marker','.', ...
    'MarkerSize',14);

y_med = median(temp,'omitnan');

plot(y_med', ...
    'LineWidth',3, ...
    'Color',color_med, ...
    'Marker','.', ...
    'MarkerSize',20);

%% ---------- axes ----------
xlim([0.5 2.5]);
xticks([1 2]);
xticklabels({'Mice follow','Mice lead'});

ylabel('Proportion');
ylim([0 1]);
yticks(0:0.25:1);

box off;
set(gca,'FontSize',28,'TickDir','out');

text(0.38,0.96,sprintf('P = %.2g', p), ...
    'Units','normalized', ...
    'FontSize',26);

title('Leadership probability','FontSize',18);

%% ---------- save ----------
print(gcf, fullfile(plot_dir, 'p_ledBy_dot_vs_mouse_paired_animalLevel.pdf'), ...
    '-dpdf','-painters');

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end