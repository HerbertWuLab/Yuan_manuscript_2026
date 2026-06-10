% plot correlation between ranking and leader/initiator dynamics
function plt_ranking_corr_v2(fd,ctable)

%% get the hierachy data from ctable
htable = extract_htable_v2(ctable); % h for hierarchy
x = htable.p_ledBy_dom;
y = htable.p_initBy_dom;
n_pairs = height(htable);

fig = figure(Position=[600 600 400 400]);
hold on
p = signrank(x,0.5);
text(0.5,1.04,sprintf('P=%.2g', p),'HorizontalAlignment','center','FontSize',20,'Units','normalized');
p = signrank(y,0.5);
text(1.04,0.5,sprintf('P=%.2g', p),'Rotation',90,'HorizontalAlignment','center','FontSize',20,'Units','normalized');
fill_color = [0.9,0.9,0.9];
scatter(x,y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
text(0.22,1.03,'Follower','HorizontalAlignment','center','FontSize',20,'Units','data')
text(0.78,1.03,'Leader','HorizontalAlignment','center','FontSize',20,'Units','data')
text(1.03,0.22,'Responder','Rotation',90,'HorizontalAlignment','center','FontSize',20,'Units','data')
text(1.03,0.78,'Initiator','Rotation',90,'HorizontalAlignment','center','FontSize',20,'Units','data')
axis equal;
xlim([-0.03 1.03]);
ylim([-0.03 1.03]);
xline(0.5,'LineStyle','--','LineWidth',2)
yline(0.5,'LineStyle','--','LineWidth',2)
yticks(0:0.5:1);
xlabel('Prop trials led')
ylabel('Prop trials initiated')
title(['Role of Dominant mice (N=' num2str(n_pairs) ' animals)'])
box off
set(gca,'FontSize',24,'TickDir','out')
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_scat_role_dominant'];
print(fig,figname,'-dpdf');
p = 2*binocdf(2,n_pairs,0.25)

%% split by sex
htable = extract_htable_v2(ctable); % h for hierarchy
sexes = {'female';'male'};
fill_colors = [239,154,154;129, 212, 250]/255;
line_colors = [183, 28, 28;1, 87, 155]/255;
for se = 1:2
    cur_sex = sexes{se};
    fill_color = fill_colors(se,:);
    line_color = line_colors(se,:)*0.8;
    htable_sex = htable(strcmp(htable.sex,cur_sex),:);
    x = htable_sex.p_ledBy_dom;
    y = htable_sex.p_initBy_dom;
    n_pairs = height(htable_sex);

    fig = figure(Position=[600 600 400 400]);
    hold on
    p = signrank(x,0.5);
    text(0.5,1.04,sprintf('P=%.2g', p),'HorizontalAlignment','center','FontSize',20,'Units','normalized');
    p = signrank(y,0.5);
    text(1.04,0.5,sprintf('P=%.2g', p),'Rotation',90,'HorizontalAlignment','center','FontSize',20,'Units','normalized');
    scatter(x,y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor',line_color,'LineWidth',0.1);
    text(0.22,1.03,'Follower','HorizontalAlignment','center','FontSize',20,'Units','data')
    text(0.78,1.03,'Leader','HorizontalAlignment','center','FontSize',20,'Units','data')
    text(1.03,0.22,'Responder','Rotation',90,'HorizontalAlignment','center','FontSize',20,'Units','data')
    text(1.03,0.78,'Initiator','Rotation',90,'HorizontalAlignment','center','FontSize',20,'Units','data')
    axis equal;
    xlim([-0.03 1.03]);
    ylim([-0.03 1.03]);
    xline(0.5,'LineStyle','--','LineWidth',2)
    yline(0.5,'LineStyle','--','LineWidth',2)
    yticks(0:0.5:1);
    xlabel('Prop trials led')
    ylabel('Prop trials initiated')
    title(['Role of Dominant mice (N=' num2str(n_pairs) ' ' cur_sex ' pairs)'])
    box off
    set(gca,'FontSize',24,'TickDir','out')
    hoy = char(datetime('now','Format','yyyyMMdd'));
    figname = [fd 'plots/' hoy '_scat_role_dominant_' cur_sex];
    print(fig,figname,'-dpdf');
    p = 2*binocdf(1,n_pairs,0.25)
end
%% same plot, different colors for the two sexes
htable = extract_htable_v2(ctable); % h for hierarchy
sexes = {'female';'male'};
fill_colors = [239,154,154;129, 212, 250]/255;
line_colors = [183, 28, 28;1, 87, 155]/255;
x = htable.p_ledBy_dom;
y = htable.p_initBy_dom;
n_pairs = height(htable);

fig = figure(Position=[600 600 400 400]);
hold on
p = signrank(x,0.5);
text(0.5,1.04,sprintf('P=%.2g', p),'HorizontalAlignment','center','FontSize',20,'Units','normalized');
p = signrank(y,0.5);
text(1.04,0.5,sprintf('P=%.2g', p),'Rotation',90,'HorizontalAlignment','center','FontSize',20,'Units','normalized');
fill_color = [0.9,0.9,0.9];
for n = 1:n_pairs
    cur_sex = htable.sex{n};
    idx_sex = find(strcmp(sexes,cur_sex));
    fill_color = fill_colors(idx_sex,:);
    line_color = line_colors(idx_sex,:);
    scatter(x(n),y(n),100,'MarkerFaceColor',fill_color,'MarkerEdgeColor',line_color,'LineWidth',0.1);
end
text(0.22,1.03,'Follower','HorizontalAlignment','center','FontSize',20,'Units','data')
text(0.78,1.03,'Leader','HorizontalAlignment','center','FontSize',20,'Units','data')
text(1.03,0.22,'Responder','Rotation',90,'HorizontalAlignment','center','FontSize',20,'Units','data')
text(1.03,0.78,'Initiator','Rotation',90,'HorizontalAlignment','center','FontSize',20,'Units','data')
axis equal;
xlim([-0.03 1.03]);
ylim([-0.03 1.03]);
xline(0.5,'LineStyle','--','LineWidth',2)
yline(0.5,'LineStyle','--','LineWidth',2)
yticks(0:0.5:1);
xlabel('Prop trials led')
ylabel('Prop trials initiated')
title(['Role of Dominant mice (N=' num2str(n_pairs) ' animals)'])
box off
set(gca,'FontSize',24,'TickDir','out')
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_scat_role_dominant_sexes'];
print(fig,figname,'-dpdf');
