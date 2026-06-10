function plt_leader_metrics_demo(fd,ltable)
% plot leader/initiator metrics on the btable level
% generate the figures for the paper

%% make leader/follower prop curves in one plot, Fig. 1d
pair_name = 'YC011YC012'; % example pair one
btable = ltable(strcmp(ltable.pair,pair_name),:);
m_colors = {'#41b6c4','#fc8d59','#878787'}; % mouse colors
pair_name = btable.pair{1};
n_ses = height(btable);
fs = 20;
line_width = 4;
marker_size = 16;
% make figures
fig = figure('Position',[600 300 300 300]);
hold on
h(1) = plot(btable.p_ledBy_m2,LineWidth=line_width,Color=m_colors{2},Marker=".",MarkerFaceColor='k',MarkerSize=marker_size);
h(2) = plot(btable.p_initBy_m2,LineStyle=':',LineWidth=line_width,Color=m_colors{2},Marker=".",MarkerFaceColor='k',MarkerSize=marker_size);
h(3) = plot(btable.cp_rate,LineWidth=line_width,Color=m_colors{3},Marker=".",MarkerFaceColor='k',MarkerSize=marker_size);
ylim([0 1.05]);
lgd_labels = {'Trials led by m2','Trials init by m2','Cooperation rate'};
legend(h,lgd_labels,'Location','northwest')
legend boxoff
title('Leader disparity')
box off
xlabel('Training days')
ylabel('Proportion');
set(gca,'FontSize',fs,'TickDir','out');
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_' pair_name '_line_leader_initiator_learning_one_plot'];
% set(fig,'PaperUnits','normalized','PaperPosition', [0 0 1 1]);
print(fig,figname,'-dpdf');

%% Correlation between leader disparity and CP rate of example pair 1. Fig. 1e
% calculate the correlations
x = btable.lead_dsp;
y = btable.cp_rate;
[r_lead,p_lead] = corr(x,y);
fill_color = [0.9,0.9,0.9];
% linear fit
yCalc = linear_fit(x, y);
fig = figure('Position',[600 300 400 400]);
hold on;
plot(x,yCalc,'Color',[0.2 0.2 0.2], 'LineWidth',2);
scatter(btable.lead_dsp, btable.cp_rate,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
text(0.05,0.9,sprintf('R=%.2f P=%.2g', r_lead, p_lead),'FontSize',20,'Units','normalized')
xlim([-0.05 0.8]); % YC011YC012
ylim([0.36 0.92]); 
xlabel('Leader disparity')
ylabel('Cooperation rate')
title([pair_name ' leader disparity vs. coop rate'])
box off
set(gca,'FontSize',24,'TickDir','out')
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_' pair_name '_scat_leader_disparity_vs_coop_rate'];
print(fig,figname,'-dpdf');

%% Correlation betwen initiator disparity and CP rate, example pair 1. Fig. 1f
x = btable.init_dsp;
y = btable.cp_rate;
[r_init,p_init] = corr(x,y);
fig = figure('Position',[600 300 400 400]);
hold on;
scatter(x, y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
% linear fit
yCalc = linear_fit(x, y);
plot(x,yCalc,'Color',[0.2 0.2 0.2],'LineStyle','-', 'LineWidth',2);
text(0.05,0.9,sprintf('R=%.2f P=%.2g', r_init, p_init),'FontSize',20,'Units','normalized')
xlim([-0.03 0.4]); % YC011YC012
ylim([0.36 0.92]);
xlabel('Initiator disparity')
ylabel('Cooperation rate')
title([pair_name ' initiator disparity vs. coop rate'])
box off
set(gca,'FontSize',24,'TickDir','out')
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_' pair_name '_scat_initiator_disparity_vs_coop_rate'];
print(fig,figname,'-dpdf');

%% make leader/follower prop curves in one plot, example pair 2. Sup Fig. 1h
pair_name = 'YC017YC018'; % example pair 2
btable = ltable(strcmp(ltable.pair,pair_name),:);
m_colors = {'#41b6c4','#fc8d59','#878787'}; % mouse colors
pair_name = btable.pair{1};
n_ses = height(btable);
fig = figure('Position',[600 300 300 300]);
hold on
h(1) = plot(btable.p_ledBy_m1,LineWidth=line_width,Color=m_colors{1},Marker=".",MarkerFaceColor='k',MarkerSize=marker_size);
h(2) = plot(btable.p_initBy_m1,LineStyle=':',LineWidth=line_width,Color=m_colors{1},Marker=".",MarkerFaceColor='k',MarkerSize=marker_size);
h(3) = plot(btable.cp_rate,LineWidth=line_width,Color=m_colors{3},Marker=".",MarkerFaceColor='k',MarkerSize=marker_size);
ylim([0 1.05]);
lgd_labels = {'Trials led by m1','Trials init by m1','Cooperation rate'};
legend(h,lgd_labels,'Location','northwest')
legend boxoff
title('Leader disparity')
box off
xlabel('Training days')
ylabel('Proportion');
set(gca,'FontSize',fs,'TickDir','out');
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_' pair_name '_line_leader_initiator_learning_one_plot'];
print(fig,figname,'-dpdf');

%% Correlation between leader disparity and CP rate of example pair 2. Sup Fig. 1i
% calculate the correlations
x = btable.lead_dsp;
y = btable.cp_rate;
[r_lead,p_lead] = corr(x,y);
fill_color = [0.9,0.9,0.9];
% linear fit
yCalc = linear_fit(x, y);
fig = figure('Position',[600 300 400 400]);
hold on;
plot(x,yCalc,'Color',[0.2 0.2 0.2], 'LineWidth',2);
scatter(btable.lead_dsp, btable.cp_rate,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
text(0.05,0.9,sprintf('R=%.2f P=%.2g', r_lead, p_lead),'FontSize',20,'Units','normalized')
xlim([0 0.8]); % YC017YC018
ylim([0.36 0.92]); % YC017YC018
xlabel('Leader disparity')
ylabel('Cooperation rate')
title([pair_name ' leader disparity vs. coop rate'])
box off
set(gca,'FontSize',24,'TickDir','out')
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_' pair_name '_scat_leader_disparity_vs_coop_rate'];
print(fig,figname,'-dpdf');

%% Correlation betwen initiator disparity and CP rate, example pair 2. Sup Fig. 1j
x = btable.init_dsp;
y = btable.cp_rate;
[r_init,p_init] = corr(x,y);
fig = figure('Position',[600 300 400 400]);
hold on;
% scatter(x, y, 50,'k','filled')
scatter(x, y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
% linear fit
yCalc = linear_fit(x, y);
plot(x,yCalc,'Color',[0.2 0.2 0.2],'LineStyle','-', 'LineWidth',2);
text(0.05,0.9,sprintf('R=%.2f P=%.2g', r_init, p_init),'FontSize',20,'Units','normalized')
xlim([0.75 1]); % YC017YC018
ylim([0.36 0.92]);
xlabel('Initiator disparity')
ylabel('Cooperation rate')
title([pair_name ' initiator disparity vs. coop rate'])
box off
set(gca,'FontSize',24,'TickDir','out')
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_' pair_name '_scat_initiator_disparity_vs_coop_rate'];
print(fig,figname,'-dpdf');