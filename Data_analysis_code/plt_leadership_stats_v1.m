function plt_leadership_stats_v1(rtable, params)
fd = params.fd; 
hoy = char(datetime('now','Format','yyyyMMdd'));
pcut = params.pcut;
role = params.role;
if strcmp(role,'leader')
    m_colors = {'#c2a5cf','#969696'}; % leader
elseif strcmp(role,'follower')
    m_colors = {'#a6dba0','#969696'}; % follower
end
time_bin = params.time_bin;
bin_str = [time_bin{1} '-' time_bin{2}];

fig = figure('Position',[600 300 400 400]);
si = rtable.SI_leader_data;
edges = -1:0.05:1;
p_sel = rtable.p_leader<pcut;
prop_sel = mean(p_sel);
sig_si = si(p_sel);
n_cells = length(si);
counts = histcounts(si,edges)/n_cells;
sig_counts = histcounts(sig_si,edges)/n_cells;
h(1) = histogram('BinEdges',edges,'BinCounts',counts,'EdgeColor','k',...
    'LineWidth',0.5,'FaceColor',m_colors{1},'FaceAlpha',0.1);
hold on;
h(2) = histogram('BinEdges',edges,'BinCounts',sig_counts,'EdgeColor','k',...
    'LineWidth',0.5,'FaceColor',m_colors{1},'FaceAlpha',1);
xlabel('Selectivity index')
ylabel('Proportion')
title([role ' SI for leader identity (N=' num2str(n_cells) ' cells)'])
set(gca,'FontSize',28,'TickDir','out');
box off
ylim([0 0.13])
text(0.9,0.1,'Prefer leading','Units','normalized','FontSize',20,...
    'Rotation',90,'HorizontalAlignment','left');
text(0.1,0.1,'Prefer following','Units','normalized','FontSize',20,...
    'Rotation',90,'HorizontalAlignment','left');
text(0.05,0.95,sprintf('Prop selective = %.3f',prop_sel),...
    'Units','normalized','FontSize',20,'HorizontalAlignment','left');
figname = [fd '/plots/' hoy 'p_' role '_SI_leader_identity_' bin_str];
% set(fig,'PaperOrientation','landscape','PaperUnits','normalized','PaperPosition', [0 0 1 1]);
print(fig,figname,'-dpdf');

