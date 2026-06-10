function fig = plt_port_choice_demo(fd)
% plot port choices when animal leads vs follows
%
% Outputs to base workspace:
%   source_data
%   stats_table

%% get params
hoy = char(datetime('now','Format','yyyyMMdd'));
mstable = load([fd 'Data/mstable_phase4a.mat']).mstable;

%% get prop choosing left
uni_animals = unique(mstable.animal);
n_uni_animals = length(uni_animals);

Pleft_when_lead = nan(n_uni_animals,1);
Pleft_when_foll = nan(n_uni_animals,1);

for a = 1:n_uni_animals

    cur_animal = uni_animals(a);
    cur_stable = mstable(strcmp(mstable.animal,cur_animal),:);

    cur_id = cur_stable.id{1};
    cur_id_num = str2double(cur_id(2));

    Pleft_when_lead(a) = mean(cur_stable.port(cur_stable.leader==cur_id_num)==1);
    Pleft_when_foll(a) = mean(cur_stable.port(cur_stable.leader==3-cur_id_num)==1);

end

%% source data
source_data = table( ...
    uni_animals, ...
    Pleft_when_lead, ...
    Pleft_when_foll, ...
    Pleft_when_foll - Pleft_when_lead, ...
    'VariableNames', ...
    {'Animal','Pleft_when_lead','Pleft_when_follow','Difference_follow_minus_lead'});

assignin('base','source_data',source_data);

%% stats
[p,h,stats] = signrank(Pleft_when_lead,Pleft_when_foll);

diff_val = Pleft_when_foll - Pleft_when_lead;

signedrank_stat = NaN;
zval = NaN;

if isfield(stats,'signedrank')
    signedrank_stat = stats.signedrank;
end

if isfield(stats,'zval')
    zval = stats.zval;
end

fprintf('\n========================================\n')
fprintf('Port choice: lead vs follow\n')
fprintf('========================================\n')
fprintf('Test: paired Wilcoxon signed-rank test\n')
fprintf('N animals = %d\n\n', n_uni_animals)

fprintf('Pleft when leading median = %.4f\n', median(Pleft_when_lead,'omitnan'))
fprintf('Pleft when following median = %.4f\n', median(Pleft_when_foll,'omitnan'))
fprintf('Median difference follow - lead = %.4f\n\n', median(diff_val,'omitnan'))

fprintf('Pleft when leading mean = %.4f\n', mean(Pleft_when_lead,'omitnan'))
fprintf('Pleft when following mean = %.4f\n', mean(Pleft_when_foll,'omitnan'))
fprintf('Mean difference follow - lead = %.4f\n\n', mean(diff_val,'omitnan'))

fprintf('Signed-rank statistic = %.4f\n', signedrank_stat)

if ~isnan(zval)
    fprintf('Z = %.4f\n', zval)
end

fprintf('P = %.6g\n', p)

stats_table = table( ...
    {'Lead_vs_Follow'}, ...
    {'paired Wilcoxon signed-rank'}, ...
    n_uni_animals, ...
    median(Pleft_when_lead,'omitnan'), ...
    median(Pleft_when_foll,'omitnan'), ...
    median(diff_val,'omitnan'), ...
    mean(Pleft_when_lead,'omitnan'), ...
    mean(Pleft_when_foll,'omitnan'), ...
    mean(diff_val,'omitnan'), ...
    signedrank_stat, ...
    zval, ...
    p, ...
    'VariableNames', ...
    {'Comparison','Test','N', ...
    'MedianLead','MedianFollow','MedianDifference_FollowMinusLead', ...
    'MeanLead','MeanFollow','MeanDifference_FollowMinusLead', ...
    'SignedRankStatistic','Z','PValue'});

assignin('base','stats_table',stats_table);

%% plot
fig = figure('Position',[300 300 400 400]); 

fill_color = [0.9,0.9,0.9];

scatter(Pleft_when_lead,Pleft_when_foll,100, ...
    'MarkerFaceColor',fill_color, ...
    'MarkerEdgeColor','k', ...
    'LineWidth',0.1);

hold on;

xlims = [-0.05 1.05];
plot(xlims,xlims,'k--')

xlabel('P(left port | leading)')
ylabel('P(left port | following)')
title(['Reward port preference (N=' num2str(n_uni_animals) ' animals)'])

set(gca,'TickDir','out','FontSize',32);

box off
axis equal
xlim(xlims)
ylim(xlims)
yticks([0 0.5 1])

figname = [fd '/plots/' hoy 'p_port_choice_lead_vs_follow'];
print(fig,figname,'-dpdf');

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end