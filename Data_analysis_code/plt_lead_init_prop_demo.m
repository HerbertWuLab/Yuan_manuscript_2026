function plt_lead_init_prop_v2(fd, ltable)
% division of roles: do leaders initiate less trials? 
% v2: organized ctable for same role and different role swapping

%% by pair at criterion (the 3rd session above 80% correct for each pair)
% m_colors = {'#df65b0','#a6bddb','#969696'}; % mouse colors
m_colors = {'#c2a5cf','#a6dba0','#969696'}; % for leader vs follower

uni_pairs = unique(ltable.pair);
n_uni_pairs = length(uni_pairs);
init_props = nan(n_uni_pairs,2);
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    cur_ltable = ltable(strcmp(cur_pair,ltable.pair),:);
    idx_end = height(cur_ltable);    
    lead_at_crit = cur_ltable.sLead{idx_end};
    foll_at_crit = cur_ltable.sFoll{idx_end};
    init_props(p,1) = cur_ltable.(['p_initBy_' lead_at_crit])(idx_end);
    init_props(p,2) = cur_ltable.(['p_initBy_' foll_at_crit])(idx_end);
end
init_props = init_props./sum(init_props,2);
[~,idx_sort] = sort(init_props(:,1));
init_props = init_props(idx_sort,:);
fig = figure('Position',[600 300 600 600]);
hold on;
b = bar(init_props,'stacked');
b(1).FaceColor = m_colors{1};
b(2).FaceColor = m_colors{2};

yline(0.5,'k:')
xlabel('Mouse pairs')
ylabel('Proportion trials')
title(['How leadership impacts initiatorship (N=' num2str(n_uni_pairs) ' pairs)'])
legend(b,{'Initiated by leader','Initiated by follower'},'Location','northeastoutside');
legend box off
% xlim([0.3 n_uni_pairs+0.7])
axis padded
set(gca,'FontSize',24,'TickDir','out')
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_leadership_impacts_initiatorship_all_pairs_phase4'];
% set(fig,'PaperUnits','normalized','PaperPosition', [0 0 1 1]);
print(fig,figname,'-dpdf');

% %% stats
% % chi-square test comparing chance to the prop of leaders that are initiators
% [~,p_chi,~,dF] = prop_test([8 6], [12 12], 0);
% fprintf('chi square test P=%.4f df=%d\n', p_chi, dF);

%%
ltable = recalc_leader_disp(ltable);
m_colors = {'#c2a5cf','#a6dba0'}; % leader, follower
uni_pairs = unique(ltable.pair);
n_uni_pairs = length(uni_pairs);
pair_table = table;
pair_table.pair = cell(n_uni_pairs,1);
init_props = nan(n_uni_pairs,2);
lead_props = nan(n_uni_pairs,2);
select_pairs = cell(n_uni_pairs,1);
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    pair_table.pair{p} = cur_pair;
    cur_ltable = ltable(strcmp(cur_pair,ltable.pair),:);
    idx_end = height(cur_ltable); 

    if cur_ltable.true_lead(idx_end) && cur_ltable.true_init(idx_end)
    lead_at_crit = cur_ltable.sLead{idx_end};
    init_props(p,1) = cur_ltable.(['p_initBy_' lead_at_crit '_adj'])(idx_end);
    lead_props(p,1) = cur_ltable.(['p_ledBy_' lead_at_crit '_adj'])(idx_end);

    foll_at_crit = cur_ltable.sFoll{idx_end};
    init_props(p,2) = cur_ltable.(['p_initBy_' foll_at_crit '_adj'])(idx_end);
    lead_props(p,2) = cur_ltable.(['p_ledBy_' foll_at_crit '_adj'])(idx_end);
    select_pairs{p} = cur_pair;
    end
end
pair_table.lead_props = lead_props;
pair_table.init_props = init_props;

fig = figure(Position=[600 600 400 400]);
hold on
clear s;
for m = 1:2 % plot both m1 and m2: their proportions should mirror each other
    x = lead_props(:,m);
    y = init_props(:,m);
    % [r1,p1] = corr(x,y,'Rows','complete');
    s(m) = scatter(x,y,100,'MarkerFaceColor',m_colors{m},'MarkerEdgeColor','k','LineWidth',0.1);
    % yCalc = linear_fit(x, y);    % linear fit
    % plot(x,yCalc,'Color',[0.2 0.2 0.2],'LineStyle','-', 'LineWidth',2);
    % fprintf('R=%.2f P=%.2g\n', r1, p1)
end
text(0.22,1.03,'Follower','HorizontalAlignment','center','FontSize',20,'Units','data')
text(0.78,1.03,'Leader','HorizontalAlignment','center','FontSize',20,'Units','data')
text(1.03,0.22,'Responder','Rotation',90,'HorizontalAlignment','center','FontSize',20,'Units','data')
text(1.03,0.78,'Initiator','Rotation',90,'HorizontalAlignment','center','FontSize',20,'Units','data')
% text(0.03,0.95,sprintf('R=%.2f P=%.2g', r1, p1),'FontSize',16,'Units','normalized')
axis equal;
xlim([-0.03 1.03]);
ylim([-0.03 1.03]);
% xlim([0 1])
% ylim([0 1])
xline(0.5,'LineStyle','--','LineWidth',2)
yline(0.5,'LineStyle','--','LineWidth',2)
yticks(0:0.5:1);
xlabel('Prop trials led')
ylabel('Prop trials initiated')
n_valid_pairs = sum(~isnan(x));
title(['Division of labor (N=' num2str(n_valid_pairs) ' pairs)'])
box off
% legend(s,{'leader','follower'},'Location','southwest','FontSize',20);
% legend box off
set(gca,'FontSize',24,'TickDir','out')
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_scat_division_of_labor_all_pairs'];
print(fig,figname,'-dpdf');

%% stats
data = init_props(:,1); % init proportion of leaders
data = data(~isnan(data));
[p,h] = signrank(data,0.5)

%% split by sex

%%
sexes = {'female';'male'};
% fill_colors = [239,154,154;129, 212, 250]/255;
% line_colors = [183, 28, 28;1, 87, 155]/255;
for se = 2
    cur_sex = sexes{se};
    ltable_sex = ltable(strcmp(ltable.sex,cur_sex),:);
    m_colors = {'#c2a5cf','#a6dba0'}; % leader, follower
    uni_pairs = unique(ltable_sex.pair);
    n_uni_pairs = length(uni_pairs);
    init_props = nan(n_uni_pairs,2);
    lead_props = nan(n_uni_pairs,2);
    select_pairs = cell(n_uni_pairs,1);
    for p = 1:n_uni_pairs
        cur_pair = uni_pairs{p};
        cur_ltable = ltable_sex(strcmp(cur_pair,ltable_sex.pair),:);
        idx_end = height(cur_ltable); 
    
        if cur_ltable.true_lead(idx_end) && cur_ltable.true_init(idx_end)
        lead_at_crit = cur_ltable.sLead{idx_end};
        init_props(p,1) = cur_ltable.(['p_initBy_' lead_at_crit '_adj'])(idx_end);
        lead_props(p,1) = cur_ltable.(['p_ledBy_' lead_at_crit '_adj'])(idx_end);
    
        foll_at_crit = cur_ltable.sFoll{idx_end};
        init_props(p,2) = cur_ltable.(['p_initBy_' foll_at_crit '_adj'])(idx_end);
        lead_props(p,2) = cur_ltable.(['p_ledBy_' foll_at_crit '_adj'])(idx_end);
        select_pairs{p} = cur_pair;
        end
    end
    fig = figure(Position=[600 600 400 400]);
    hold on
    clear s;
    for m = 1:2 % plot both m1 and m2: their proportions should mirror each other
        x = lead_props(:,m);
        y = init_props(:,m);
        % [r1,p1] = corr(x,y,'Rows','complete');
        s(m) = scatter(x,y,100,'MarkerFaceColor',m_colors{m},'MarkerEdgeColor','k','LineWidth',0.1);
        % yCalc = linear_fit(x, y);    % linear fit
        % plot(x,yCalc,'Color',[0.2 0.2 0.2],'LineStyle','-', 'LineWidth',2);
        % fprintf('R=%.2f P=%.2g\n', r1, p1)
    end
    text(0.22,1.03,'Follower','HorizontalAlignment','center','FontSize',20,'Units','data')
    text(0.78,1.03,'Leader','HorizontalAlignment','center','FontSize',20,'Units','data')
    text(1.03,0.22,'Responder','Rotation',90,'HorizontalAlignment','center','FontSize',20,'Units','data')
    text(1.03,0.78,'Initiator','Rotation',90,'HorizontalAlignment','center','FontSize',20,'Units','data')
    % text(0.03,0.95,sprintf('R=%.2f P=%.2g', r1, p1),'FontSize',16,'Units','normalized')
    axis equal;
    xlim([-0.03 1.03]);
    ylim([-0.03 1.03]);
    % xlim([0 1])
    % ylim([0 1])
    xline(0.5,'LineStyle','--','LineWidth',2)
    yline(0.5,'LineStyle','--','LineWidth',2)
    yticks(0:0.5:1);
    xlabel('Prop trials led')
    ylabel('Prop trials initiated')
    n_valid_pairs = sum(~isnan(x));
    title(['Division of labor (N=' num2str(n_valid_pairs) ' ' cur_sex ' pairs)'])
    box off
    % legend(s,{'leader','follower'},'Location','southwest','FontSize',20);
    % legend box off
    set(gca,'FontSize',24,'TickDir','out')
    hoy = char(datetime('now','Format','yyyyMMdd'));
    figname = [fd 'plots/' hoy '_scat_division_of_labor_' cur_sex];
    print(fig,figname,'-dpdf');

    data = init_props(:,1); % init proportion of leaders
    data = data(~isnan(data));
    [p,h] = signrank(data,0.5)
end