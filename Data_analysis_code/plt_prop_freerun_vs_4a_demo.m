function plt_prop_freerun_vs_4a_demo(fd)

%% prop of selective cells compare free run vs phase 4a
prop_table_freerun = load([fd 'Data/prop_table_freerun']).prop_table;
prop_table_4a = load([fd 'Data/prop_table_phase4a']).prop_table;

% bar plot angle decoding performance
x = prop_table_freerun.p_other_ego(prop_table_freerun.n_cells>=100);
y = prop_table_4a.p_other_ego;
xlabels = {'Free run';'In context'};
ylabels = 'Prop';
caption = 'Cells selective for other egocentric';
fig = figure('Position',[600 300 200 400]);
hold on;
color_single = [0.6 0.6 0.6];
fill_color = 0.9*[1 1 1];
bar(1,mean(x,"omitnan"),0.6,'EdgeColor',color_single,'FaceColor','none','LineWidth',1);
bar(2,mean(y,"omitnan"),0.6,'EdgeColor','#cb7831','FaceColor','none','LineWidth',1);
scatter(1*ones(size(x)),x,60,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
scatter(2*ones(size(y)),y,60,'MarkerFaceColor','#cb7831','MarkerEdgeColor','k','LineWidth',0.1);
[h,p,stats] = ranksum(x,y);

fprintf('\n===== Rank-sum test =====\n');
fprintf('Group X: N=%d, median=%.4f\n', ...
    length(x), median(x,'omitnan'));
fprintf('Group Y: N=%d, median=%.4f\n', ...
    length(y), median(y,'omitnan'));
fprintf('ranksum statistic = %.1f\n', stats.ranksum);
fprintf('p = %.4g\n', p);
fprintf('h = %d\n', h);
fprintf('=========================\n');
title(caption)
text(0.1,0.98,sprintf('P=%.2g', p),'FontSize',28,'Units','normalized')
xlim([0.5 2.5])
% ylim([0 0.3])
yticks([0 0.1])
set(gca,'FontSize',32,'TickDir','out');
box off
xticks([1 2]);
xticklabels(xlabels)
ylabel(ylabels);
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_prop_table_freerun_vs_4a'];
print(fig,figname,'-dpdf');