function plt_dist_rt_Traj_SF(criterion_table, fd)
% plt_dist_rt_Traj_SF
%
% (1) trajectory replay vs social foraging RT (paired; pair median)
% (2) trajectory replay RT by sex (bar + scatter)
%
% Outputs to base workspace:
%   source_data
%   stats_table

fps = 30;

if nargin < 2 || isempty(fd)
    fd = pwd;
end

plot_dir = fullfile(string(fd), "plots");

if ~isfolder(plot_dir)
    mkdir(plot_dir);
end

pair_col = string(criterion_table.pair);
pairs = unique(pair_col);
num_pairs = numel(pairs);

pair_sex = categorical(strings(num_pairs,1));

for p = 1:num_pairs
    idx = (pair_col == pairs(p));
    pair_sex(p) = criterion_table.sex(find(idx,1,'first'));
end

traj_med_rt = nan(num_pairs,1);
sf_med_rt = nan(num_pairs,1);

for p = 1:num_pairs

    idx = (pair_col == pairs(p));

    traj_all = vertcat(criterion_table.stable{idx});
    sf_all = vertcat(criterion_table.SF_stable{idx});

    rt = nan(height(traj_all),1);

    if ismember('m2_rt', traj_all.Properties.VariableNames)
        rt = double(traj_all.m2_rt) ./ fps;

    elseif all(ismember({'m2_last_arr','led_init'}, traj_all.Properties.VariableNames))
        rt = (double(traj_all.m2_last_arr) - double(traj_all.led_init)) ./ fps;
    end

    traj_med_rt(p) = median(rt,'omitnan');

    sf_pool = [];

    if ismember('m1_rt', sf_all.Properties.VariableNames) && ...
       ismember('m2_rt', sf_all.Properties.VariableNames)

        sf_pool = [double(sf_all.m1_rt(:)); ...
                   double(sf_all.m2_rt(:))] ./ fps;
    end

    sf_med_rt(p) = median(sf_pool,'omitnan');

end

source_data = table();
stats_table = table();

color_single = [0.6 0.6 0.6];
color_med = [0.2 0.2 0.2];

valid = ~isnan(traj_med_rt) & ~isnan(sf_med_rt);

temp = [traj_med_rt(valid) sf_med_rt(valid)];
pairs_valid = pairs(valid);
sex_valid = string(pair_sex(valid));

diff_val = temp(:,2) - temp(:,1);

T_source = table( ...
    pairs_valid(:), ...
    sex_valid(:), ...
    (1:size(temp,1))', ...
    temp(:,1), ...
    temp(:,2), ...
    diff_val, ...
    'VariableNames', ...
    {'Pair','Sex','PairIndex','TrajectoryReplayRT','SocialForagingRT','Difference_SF_minus_Traj'});

source_data = [source_data; T_source];

[pval,~,stat] = signrank(temp(:,1), temp(:,2));

signedrank_stat = NaN;
zval = NaN;

if isfield(stat,'signedrank')
    signedrank_stat = stat.signedrank;
end

if isfield(stat,'zval')
    zval = stat.zval;
end

T_stats = table( ...
    {'TrajectoryReplay_vs_SocialForaging_RT'}, ...
    {'paired Wilcoxon signed-rank'}, ...
    size(temp,1), ...
    median(temp(:,1),'omitnan'), ...
    median(temp(:,2),'omitnan'), ...
    median(diff_val,'omitnan'), ...
    mean(temp(:,1),'omitnan'), ...
    mean(temp(:,2),'omitnan'), ...
    mean(diff_val,'omitnan'), ...
    std(temp(:,1),'omitnan'), ...
    std(temp(:,2),'omitnan'), ...
    std(diff_val,'omitnan'), ...
    std(temp(:,1),'omitnan')/sqrt(size(temp,1)), ...
    std(temp(:,2),'omitnan')/sqrt(size(temp,1)), ...
    std(diff_val,'omitnan')/sqrt(size(temp,1)), ...
    signedrank_stat, ...
    zval, ...
    pval, ...
    'VariableNames', ...
    {'Comparison','Test','N', ...
    'MedianTrajectoryReplay','MedianSocialForaging','MedianDifference_SF_minus_Traj', ...
    'MeanTrajectoryReplay','MeanSocialForaging','MeanDifference_SF_minus_Traj', ...
    'SDTrajectoryReplay','SDSocialForaging','SDDifference', ...
    'SETrajectoryReplay','SESocialForaging','SEDifference', ...
    'SignedRankStatistic','Z','PValue'});

stats_table = [stats_table; T_stats];

fprintf('\n========================================\n')
fprintf('Trajectory replay vs social foraging RT\n')
fprintf('========================================\n')
fprintf('Test: paired Wilcoxon signed-rank test\n')
fprintf('N pairs = %d\n', size(temp,1))
fprintf('Median trajectory replay RT = %.4f\n', median(temp(:,1),'omitnan'))
fprintf('Median social foraging RT = %.4f\n', median(temp(:,2),'omitnan'))
fprintf('Median difference SF - Traj = %.4f\n', median(diff_val,'omitnan'))
fprintf('Mean trajectory replay RT = %.4f\n', mean(temp(:,1),'omitnan'))
fprintf('Mean social foraging RT = %.4f\n', mean(temp(:,2),'omitnan'))
fprintf('Mean difference SF - Traj = %.4f\n', mean(diff_val,'omitnan'))
fprintf('Signed-rank statistic = %.4f\n', signedrank_stat)
if ~isnan(zval)
    fprintf('Z = %.4f\n', zval)
end
fprintf('P = %.6g\n', pval)

figure('Position',[600 300 400 400],'Color','w'); 
hold on

plot(temp','LineWidth',1,'Color',color_single,...
     'Marker','.', 'MarkerSize',10);

y = median(temp,'omitnan');

plot(y','LineWidth',3,'Color',color_med,...
     'Marker','.', 'MarkerSize',16);

xlim([0.5 2.5]);
ylim([0 4]);

xticks([1 2]);
xticklabels({'trajectory replay','social foraging'});

ylabel('Reaction time (s; pair median; ALL trials)', ...
       'Interpreter','none');

box off;

text(0.38,0.98,sprintf('P=%.2g',pval),...
     'Units','normalized','FontSize',28);

set(gca,'FontSize',32,'TickDir','out');

print(gcf, fullfile(plot_dir,'Traj_vs_SF_RT_paired.pdf'), ...
      '-dpdf','-vector');

sexes = {'female';'male'};
fill_colors = [239,154,154;129,212,250]/255;
line_colors = [183,28,28; 1,87,155]/255;

sx = lower(string(pair_sex));

valsF = traj_med_rt(sx=="female");
valsM = traj_med_rt(sx=="male");

valsF = valsF(~isnan(valsF));
valsM = valsM(~isnan(valsM));

T_source_sex = table( ...
    [repmat({'female'},numel(valsF),1); repmat({'male'},numel(valsM),1)], ...
    [(1:numel(valsF))'; (1:numel(valsM))'], ...
    [valsF(:); valsM(:)], ...
    'VariableNames', ...
    {'Sex','PairIndex','TrajectoryReplayRT'});

source_data = [source_data; table( ...
    repmat({''},height(T_source_sex),1), ...
    string(T_source_sex.Sex), ...
    T_source_sex.PairIndex, ...
    T_source_sex.TrajectoryReplayRT, ...
    nan(height(T_source_sex),1), ...
    nan(height(T_source_sex),1), ...
    'VariableNames', ...
    {'Pair','Sex','PairIndex','TrajectoryReplayRT','SocialForagingRT','Difference_SF_minus_Traj'})];

psex = NaN;
ranksum_stat = NaN;
zval_sex = NaN;

if ~isempty(valsF) && ~isempty(valsM)
    [psex,~,stat_sex] = ranksum(valsF, valsM);

    if isfield(stat_sex,'ranksum')
        ranksum_stat = stat_sex.ranksum;
    end

    if isfield(stat_sex,'zval')
        zval_sex = stat_sex.zval;
    end
end

T_stats_sex = table( ...
    {'TrajectoryReplayRT_female_vs_male'}, ...
    {'Wilcoxon rank-sum'}, ...
    numel(valsF), ...
    numel(valsM), ...
    median(valsF,'omitnan'), ...
    median(valsM,'omitnan'), ...
    mean(valsF,'omitnan'), ...
    mean(valsM,'omitnan'), ...
    std(valsF,'omitnan'), ...
    std(valsM,'omitnan'), ...
    std(valsF,'omitnan')/sqrt(numel(valsF)), ...
    std(valsM,'omitnan')/sqrt(numel(valsM)), ...
    ranksum_stat, ...
    zval_sex, ...
    psex, ...
    'VariableNames', ...
    {'Comparison','Test','NFemale','NMale', ...
    'MedianFemale','MedianMale', ...
    'MeanFemale','MeanMale', ...
    'SDFemale','SDMale', ...
    'SEFemale','SEMale', ...
    'RankSumStatistic','Z','PValue'});

fprintf('\n========================================\n')
fprintf('Trajectory replay RT by sex\n')
fprintf('========================================\n')
fprintf('Test: Wilcoxon rank-sum test\n')
fprintf('Female n = %d\n', numel(valsF))
fprintf('Male n = %d\n', numel(valsM))
fprintf('Female median = %.4f\n', median(valsF,'omitnan'))
fprintf('Male median = %.4f\n', median(valsM,'omitnan'))
fprintf('Female mean = %.4f\n', mean(valsF,'omitnan'))
fprintf('Male mean = %.4f\n', mean(valsM,'omitnan'))
fprintf('Ranksum statistic = %.4f\n', ranksum_stat)
if ~isnan(zval_sex)
    fprintf('Z = %.4f\n', zval_sex)
end
fprintf('P = %.6g\n', psex)

figure('Color','w','Position',[600 300 200 400]); 
hold on

bar(1, median(valsF,'omitnan'), 0.6, ...
    'FaceColor','none', 'EdgeColor','k', 'LineWidth',1.8);

bar(2, median(valsM,'omitnan'), 0.6, ...
    'FaceColor','none', 'EdgeColor','k', 'LineWidth',1.8);

jitF = 0.15*(rand(numel(valsF),1)-0.5);
jitM = 0.15*(rand(numel(valsM),1)-0.5);

scatter(1+jitF, valsF, 22, ...
    'MarkerFaceColor', fill_colors(1,:), ...
    'MarkerEdgeColor', line_colors(1,:), 'LineWidth',1.2);

scatter(2+jitM, valsM, 22, ...
    'MarkerFaceColor', fill_colors(2,:), ...
    'MarkerEdgeColor', line_colors(2,:), 'LineWidth',1.2);

xlim([0.5 2.5]);

xticks([1 2]);
xticklabels({'female','male'});

ylabel('trajectory replay reaction time (s; pair median; ALL trials)', ...
       'Interpreter','none');

box off;

set(gca,'TickDir','out','LineWidth',1.2,'FontSize',12);

if ~isnan(psex)
    text(0.10,0.98,sprintf('ranksum p = %.3g',psex),...
         'Units','normalized','FontSize',12);
else
    text(0.10,0.98,'ranksum p = n/a',...
         'Units','normalized','FontSize',12);
end

title('trajectory replay RT by sex', 'FontWeight','normal');

print(gcf, fullfile(plot_dir,'Traj_RT_by_sex_scatterbar.pdf'), ...
      '-dpdf','-vector');

assignin('base','source_data',source_data);
assignin('base','stats_table',stats_table);
assignin('base','stats_table_sex',T_stats_sex);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')
fprintf('stats_table_sex\n')

end