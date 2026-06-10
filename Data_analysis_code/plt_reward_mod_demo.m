function plt_reward_mod_demo(fd)
%
% Outputs to base workspace:
%   source_data
%   stats_table

mrtable_leadership = load([fd 'Data/mrtable_leadership_selfarr_selfarr+30.mat']).mrtable;
mrtable_rwd = load([fd 'Data/mrtable_corr_rwd.mat']).mrtable;

mrtable = [mrtable_leadership mrtable_rwd(:,end-1:end)];

for i = 1:height(mrtable)
    mrtable.animal2{i} = mrtable.animal(i,:);
end

mrtable.animal = [];
mrtable = renamevars(mrtable,"animal2","animal");
mrtable = movevars(mrtable,"animal","Before","date");

pcut = 0.05;

uni_animals = unique(mrtable.animal);
n_uni_animals = length(uni_animals);

prop_rwd_sel = nan(n_uni_animals,1);
prop_rwd_sel_ctrl = nan(n_uni_animals,1);
prop_rwd_sel_leadership = nan(n_uni_animals,1);
p_double = nan(n_uni_animals,1);
p_chance = nan(n_uni_animals,1);

n_cells_total = nan(n_uni_animals,1);
n_cells_leader_sel = nan(n_uni_animals,1);
n_cells_ctrl = nan(n_uni_animals,1);

for a = 1:n_uni_animals

    animal = uni_animals{a};

    sel_animal = strcmp(mrtable.animal,animal);
    mrtable_sel_animal = mrtable(sel_animal,:);

    n_cells_total(a) = height(mrtable_sel_animal);

    prop_rwd_sel(a) = mean(mrtable_sel_animal.p_cor_wait<pcut);

    mrtable_sel_animal_ctrl = mrtable_sel_animal(mrtable_sel_animal.p_leader>=pcut,:);
    n_cells_ctrl(a) = height(mrtable_sel_animal_ctrl);
    prop_rwd_sel_ctrl(a) = mean(mrtable_sel_animal_ctrl.p_cor_wait<pcut);

    mrtable_sel_animal_sel_leadership = mrtable_sel_animal(mrtable_sel_animal.p_leader<pcut,:);
    n_cells_leader_sel(a) = height(mrtable_sel_animal_sel_leadership);
    prop_rwd_sel_leadership(a) = mean(mrtable_sel_animal_sel_leadership.p_cor_wait<pcut);

    p_double(a) = mean(mrtable_sel_animal.p_cor_wait<pcut & mrtable_sel_animal.p_leader<pcut);
    p_chance(a) = mean(mrtable_sel_animal.p_cor_wait<pcut) * mean(mrtable_sel_animal.p_leader<pcut);

end

props = [prop_rwd_sel prop_rwd_sel_leadership];

source_data = table( ...
    uni_animals(:), ...
    n_cells_total, ...
    n_cells_ctrl, ...
    n_cells_leader_sel, ...
    prop_rwd_sel, ...
    prop_rwd_sel_ctrl, ...
    prop_rwd_sel_leadership, ...
    prop_rwd_sel_leadership - prop_rwd_sel, ...
    p_double, ...
    p_chance, ...
    p_double - p_chance, ...
    'VariableNames', ...
    {'Animal','NCellsTotal','NCellsNonLeaderSelective','NCellsLeaderSelective', ...
    'PropRewardSelective_AllNeurons', ...
    'PropRewardSelective_NonLeaderSelective', ...
    'PropRewardSelective_LeaderSelective', ...
    'Difference_LeaderSelectiveMinusAll', ...
    'PropDoubleSelectiveObserved', ...
    'PropDoubleSelectiveChance', ...
    'Difference_DoubleObservedMinusChance'});

assignin('base','source_data',source_data);

valid = ~isnan(prop_rwd_sel) & ~isnan(prop_rwd_sel_leadership);

[p,~,stat] = signrank(prop_rwd_sel(valid),prop_rwd_sel_leadership(valid));

signedrank_stat = NaN;
zval = NaN;

if isfield(stat,'signedrank')
    signedrank_stat = stat.signedrank;
end

if isfield(stat,'zval')
    zval = stat.zval;
end

diff_val = prop_rwd_sel_leadership(valid) - prop_rwd_sel(valid);

stats_table = table( ...
    {'RewardSelective_AllNeurons_vs_LeaderSelective'}, ...
    {'paired Wilcoxon signed-rank'}, ...
    sum(valid), ...
    median(prop_rwd_sel(valid),'omitnan'), ...
    median(prop_rwd_sel_leadership(valid),'omitnan'), ...
    median(diff_val,'omitnan'), ...
    mean(prop_rwd_sel(valid),'omitnan'), ...
    mean(prop_rwd_sel_leadership(valid),'omitnan'), ...
    mean(diff_val,'omitnan'), ...
    std(prop_rwd_sel(valid),'omitnan'), ...
    std(prop_rwd_sel_leadership(valid),'omitnan'), ...
    std(diff_val,'omitnan'), ...
    std(prop_rwd_sel(valid),'omitnan')/sqrt(sum(valid)), ...
    std(prop_rwd_sel_leadership(valid),'omitnan')/sqrt(sum(valid)), ...
    std(diff_val,'omitnan')/sqrt(sum(valid)), ...
    signedrank_stat, ...
    zval, ...
    p, ...
    'VariableNames', ...
    {'Comparison','Test','N', ...
    'MedianAllNeurons','MedianLeaderSelective','MedianDifference_LeaderSelectiveMinusAll', ...
    'MeanAllNeurons','MeanLeaderSelective','MeanDifference_LeaderSelectiveMinusAll', ...
    'SDAllNeurons','SDLeaderSelective','SDDifference', ...
    'SEMAllNeurons','SEMLeaderSelective','SEMDifference', ...
    'SignedRankStatistic','Z','PValue'});

assignin('base','stats_table',stats_table);

fprintf('\n========================================\n')
fprintf('Reward modulation in all vs leader-selective neurons\n')
fprintf('========================================\n')
fprintf('Test: paired Wilcoxon signed-rank test\n')
fprintf('N animals = %d\n', sum(valid))
fprintf('Median all neurons = %.4f\n', median(prop_rwd_sel(valid),'omitnan'))
fprintf('Median leader selective = %.4f\n', median(prop_rwd_sel_leadership(valid),'omitnan'))
fprintf('Median difference leader selective - all = %.4f\n', median(diff_val,'omitnan'))
fprintf('Mean all neurons = %.4f\n', mean(prop_rwd_sel(valid),'omitnan'))
fprintf('Mean leader selective = %.4f\n', mean(prop_rwd_sel_leadership(valid),'omitnan'))
fprintf('Mean difference leader selective - all = %.4f\n', mean(diff_val,'omitnan'))
fprintf('Signed-rank statistic = %.4f\n', signedrank_stat)
if ~isnan(zval)
    fprintf('Z = %.4f\n', zval)
end
fprintf('P = %.6g\n', p)

color_single = [0.6 0.6 0.6];
color_med = [0.2 0.2 0.2];

N = size(props,1);
x = [1 2];

fig = figure('Position',[600 300 300 400]);
hold on;

y = median(props,"omitnan");

plot(props','LineWidth',1,'Color',color_single,...
    'Marker','.','MarkerSize',10);

plot(y','LineWidth',3,'Color',color_med,...
    'Marker','.','MarkerSize',16); 

xlim([0.5 2.5])

xticks(1:2);
xticklabels({'All neurons','Leader selective'});

ylabel('Prop modulated by reward exp');

title('Modulation by reward expectation');

box off

text(0.38,0.98,sprintf('P=%.2g', p), ...
    'FontSize',28, ...
    'Units','normalized')

set(gca,'FontSize',28,'TickDir','out');

hoy = char(datetime('now','Format','yyyyMMdd'));

figname = [fd 'plots/' hoy '_prop_leader_sel_modulated_by_reward_exp'];

print(fig,figname,'-dpdf');

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end