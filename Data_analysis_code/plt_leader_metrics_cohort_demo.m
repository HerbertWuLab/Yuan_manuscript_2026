function fig = plt_leader_metrics_cohort_demo(fd,ltable)
% plot leader/initiator metrics on the btable level
% generate the figures for the paper
% cohort plot of every pair
% fd = '/Users/herbert/Wulab Dropbox/Herbert/Research/Projects/SocialForaging/Behavior';
ltable = recalc_leader_disp(ltable);

%% plot the correlations between leader disparity and coop rate
uni_pairs = unique(ltable.pair);
n_uni_pairs = length(uni_pairs);
fig = figure('Position',[600 300 400 400]);
hold on;
fill_color = [0.9,0.9,0.9];
line_color = [0.6,0.6,0.6];
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    cur_ltable = ltable(strcmp(cur_pair,ltable.pair),:);
    x = cur_ltable.lead_dsp;
    y = cur_ltable.cp_rate;
    scatter(x,y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
end
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    cur_ltable = ltable(strcmp(cur_pair,ltable.pair),:);
    x = cur_ltable.lead_dsp;
    y = cur_ltable.cp_rate;
    % linear fit
    yCalc = linear_fit(x, y);
    p_ind = plot(x,yCalc,'Color',line_color, 'LineWidth',1);
end
X = ltable.lead_dsp;
Y = ltable.cp_rate;
% linear fit
yCalc = linear_fit(X,Y);
p_all = plot(X,yCalc,'Color','k', 'LineWidth',3);
legend([p_ind p_all],{'Individual pair','Combined'},'Location','southeast')
legend box off
% text(0.5,0.2,sprintf('R=%.2f P=%.2g', r_lead, p_lead),'FontSize',20,'Units','normalized')
xlim([-0.03 0.88]);
ylim([0.17 1.03]);
xlabel('Leader disparity')
ylabel('Cooperation rate')
title(['Leader disparity vs. coop rate all pairs (N=' num2str(n_uni_pairs) ')'])
box off
set(gca,'FontSize',24,'TickDir','out')
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_scat_leader_disparity_vs_coop_rate_all_pairs'];
print(fig,figname,'-dpdf');

%% stats for correlation between leader disparity and cooperation rate
lme1 = fitlme(ltable, 'cp_rate ~ lead_dsp + (1|pair)');
disp(lme1); 

lme2 = fitlme(ltable, 'cp_rate ~ lead_dsp + (lead_dsp-1|pair)');
disp(lme2);

lme3 = fitlme(ltable, 'cp_rate ~ lead_dsp + (1|pair) + (lead_dsp-1|pair)');
disp(lme3);

lme4 = fitlme(ltable, 'cp_rate ~ lead_dsp + (lead_dsp|pair)');
disp(lme4); % this is the best model based on AIC

%% plot the correlations betwen initiator disparity and coop rate
uni_pairs = unique(ltable.pair);
n_uni_pairs = length(uni_pairs);
fig = figure('Position',[600 300 400 400]);
fill_color = [0.9,0.9,0.9];
line_color = [0.6,0.6,0.6];
hold on;
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    cur_ltable = ltable(strcmp(cur_pair,ltable.pair),:);
    x = cur_ltable.init_dsp;
    y = cur_ltable.cp_rate;
    scatter(x,y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
end
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    cur_ltable = ltable(strcmp(cur_pair,ltable.pair),:);
    x = cur_ltable.init_dsp;
    y = cur_ltable.cp_rate;
    % linear fit
    yCalc = linear_fit(x, y);
    p_ind = plot(x,yCalc,'Color',line_color, 'LineWidth',1);
end
X = ltable.init_dsp;
Y = ltable.cp_rate;
% linear fit
yCalc = linear_fit(X,Y);
p_all = plot(X,yCalc,'Color','k', 'LineWidth',3);
legend([p_ind p_all],{'Individual pair','Combined'},'Location','southeast')
legend box off
% text(0.5,0.2,sprintf('R=%.2f P=%.2g', r_lead, p_lead),'FontSize',20,'Units','normalized')
xlim([-0.03 1.03]);
ylim([0.17 1.03]);
xlabel('Initiator disparity')
ylabel('Cooperation rate')
title(['Initiator disparity vs. coop rate all pairs (N=' num2str(n_uni_pairs) ')'])
box off
set(gca,'FontSize',24,'TickDir','out')
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_scat_initiator_disparity_vs_coop_rate_all_pairs'];
print(fig,figname,'-dpdf');

%% stats for correlation between initiator disparity and cooperation rate

lme1 = fitlme(ltable, 'cp_rate ~ init_dsp + (1|pair)');
disp(lme1); 

lme2 = fitlme(ltable, 'cp_rate ~ init_dsp + (init_dsp-1|pair)');
disp(lme2);

lme3 = fitlme(ltable, 'cp_rate ~ init_dsp + (1|pair) + (init_dsp-1|pair)');
disp(lme3);

lme4 = fitlme(ltable, 'cp_rate ~ init_dsp + (init_dsp|pair)');
disp(lme4); % this is the best model based on AIC
% 
% lme1 = fitlme(ltable, 'cp_rate ~ init_dsp + (init_dsp|pair)');
% disp(lme1);
% 
% lme2 = fitlme(ltable, 'cp_rate ~ init_dsp + (1|pair) + (init_dsp-1|pair)');
% disp(lme2);
% 
% lme3 = fitlme(ltable, 'cp_rate ~ init_dsp + (1|pair)');
% disp(lme3);
% 
% lme4 = fitlme(ltable, 'cp_rate ~ init_dsp + (init_dsp-1|pair)');
% disp(lme4);

% lme5 = fitlm(ltable, 'cp_rate ~ init_dsp');
% disp(lme5);
% lme5.ModelCriterion.AIC

% %% correlation betwen the cooperation rate of trials led by the two mice
% x = btable.cp_rate_ledBy_m1;
% y = btable.cp_rate_ledBy_m2;
% [r_cp_rate,p_cp_rate] = corr(x,y);
% fig = figure('Position',[600 300 600 600]);
% hold on;
% scatter(x, y, 50,'k','filled')
% % linear fit
% yCalc = linear_fit(x,y);
% plot(x,yCalc,'Color',[0.2 0.2 0.2],'LineStyle',':', 'LineWidth',1);
% text(0.52,0.98,sprintf('R=%.2f P=%.2g', r_cp_rate, p_cp_rate),'FontSize',16)
% ylim([0.5 1.02]);
% xlim([0.5 1.02]);
% xticks(0.5:0.1:1);
% yticks(0.5:0.1:1);
% xlabel('coop rate of trials led by m1')
% ylabel('coop rate of trials led by m2')
% title([pair_name ' coop rates of trials led by either animal'])
% box off
% set(gca,'FontSize',20,'TickDir','out')
% hoy = char(datetime('now','Format','yyyyMMdd'));
% figname = [fd 'plots/' hoy '_' pair_name '_scat_coop_rate_led_by_either_animal'];
% print(fig,figname,'-dpdf');

%% scatter plot comparing coop rate of trials led by the two animals
uni_pairs = unique(ltable.pair);
n_uni_pairs = length(uni_pairs);
axis_range = [0.22 1.03];
fig = figure('Position',[600 300 400 400]);
hold on;
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    cur_ltable = ltable(strcmp(cur_pair,ltable.pair),:);
    x = cur_ltable.cp_rate_ledBy_sFoll;
    y = cur_ltable.cp_rate_ledBy_sLead;
    sel = ~isnan(x);
    x = x(sel); y = y(sel);
    scatter(x,y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
end
plot(axis_range,axis_range,'r--','LineWidth',1);
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    cur_ltable = ltable(strcmp(cur_pair,ltable.pair),:);
    x = cur_ltable.cp_rate_ledBy_sFoll;
    y = cur_ltable.cp_rate_ledBy_sLead;
    sel = ~isnan(x);
    x = x(sel); y = y(sel);
    % linear fit
    yCalc = linear_fit(x, y);
    p_ind = plot(x,yCalc,'Color',[0.2 0.2 0.2], 'LineWidth',1);
end
X = ltable.cp_rate_ledBy_sFoll;
Y = ltable.cp_rate_ledBy_sLead;
sel = ~isnan(X);
X = X(sel); Y = Y(sel);
% linear fit
yCalc = linear_fit(X,Y);
% p_all = plot(X,yCalc,'Color','k', 'LineWidth',3);
legend(p_ind,{'Individual pair fit'},'Location','southeast')
% legend([p_ind p_all],{'Individual pairs','All pairs combined'},'Location','southeast')
legend box off
% text(0.5,0.2,sprintf('R=%.2f P=%.2g', r_lead, p_lead),'FontSize',20,'Units','normalized')
xlabel('Follower-led trials')
ylabel('Leader-led trials')
title(['Leader advantage (N=' num2str(n_uni_pairs) ' pairs)'])
box off
set(gca,'FontSize',24,'TickDir','out')
axis equal
xlim(axis_range);
ylim(axis_range);
x_ticks = xticks;
yticks(x_ticks);
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_coop_rate_led_by_mice_all_pairs'];
print(fig,figname,'-dpdf');

%% scatter plot of cooperation rate difference as a function of training days. not used in paper
% to show the cooperation rate is higher when led by the leader
ltable.cp_rate_diff = ltable.cp_rate_ledBy_sLead - ltable.cp_rate_ledBy_sFoll;
uni_pairs = unique(ltable.pair);
n_uni_pairs = length(uni_pairs);
fig = figure('Position',[600 300 600 600]);
axis_range = [-0.2 0.5];
hold on;
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    cur_ltable = ltable(strcmp(cur_pair,ltable.pair),:);
    x = cur_ltable.days;
    y = cur_ltable.cp_rate_diff;
    sel = ~isnan(y);
    x = x(sel); y = y(sel);
    % linear fit
    yCalc = linear_fit(x, y);
    p_ind = plot(x,yCalc,'Color',[0.2 0.2 0.2], 'LineWidth',0.5);
    scatter(x,y,20,[0.5 0.5 0.5])
end
X = ltable.days;
Y = ltable.cp_rate_diff;
sel = ~isnan(Y);
X = X(sel); Y = Y(sel);
% linear fit
yCalc = linear_fit(X,Y);
% p_all = plot(X,yCalc,'Color','k', 'LineWidth',3);
yline(0,'k:','LineWidth',0.5);
legend([p_ind p_all],{'Individual pairs','All pairs combined'},'Location','southeast')
legend box off
% text(0.5,0.2,sprintf('R=%.2f P=%.2g', r_lead, p_lead),'FontSize',20,'Units','normalized')
xlabel('Training days')
ylabel('Coop rate difference when led by leader vs follower')
title(['Coop rate difference all pairs (N=' num2str(n_uni_pairs) ')'])
box off
set(gca,'FontSize',24,'TickDir','out')
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_coop_rate_diff_across_days_all_pairs'];

%% stats
% for a simple comparison of coop rates
ltable.cp_rate_diff = ltable.cp_rate_ledBy_sLead - ltable.cp_rate_ledBy_sFoll;
lme1 = fitlme(ltable, 'cp_rate_diff ~ 1 + (1|pair)');
disp(lme1);

%% compare models when taking training days into account
lme2 = fitlme(ltable, 'cp_rate_diff ~ days + (days|pair)');
disp(lme2);

lme3 = fitlme(ltable, 'cp_rate_diff ~ days + (days-1|pair) + (1|pair)');
disp(lme3);

lme4 = fitlme(ltable, 'cp_rate_diff ~ days + (days-1|pair)');
disp(lme4);

lme5 = fitlme(ltable, 'cp_rate_diff ~ days - 1 + (days-1|pair)');
disp(lme5);

%% scatter plot comparing coop rate of trials initiated by the two animals
uni_pairs = unique(ltable.pair);
n_uni_pairs = length(uni_pairs);
fig = figure('Position',[600 300 400 400]);
axis_range = [0.11 1.03];
hold on;
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    cur_ltable = ltable(strcmp(cur_pair,ltable.pair),:);
    x = cur_ltable.cp_rate_initBy_sResp;
    y = cur_ltable.cp_rate_initBy_sInit;
    sel = ~isnan(x);
    x = x(sel); y = y(sel);
    scatter(x,y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
end
plot(axis_range,axis_range,'r--','LineWidth',1);
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    cur_ltable = ltable(strcmp(cur_pair,ltable.pair),:);
    x = cur_ltable.cp_rate_initBy_sResp;
    y = cur_ltable.cp_rate_initBy_sInit;
    sel = ~isnan(x);
    x = x(sel); y = y(sel);
    % linear fit
    yCalc = linear_fit(x, y);
    p_ind = plot(x,yCalc,'Color',[0.2 0.2 0.2], 'LineWidth',1);
end
X = ltable.cp_rate_initBy_sResp;
Y = ltable.cp_rate_initBy_sInit;
sel = ~isnan(X);
X = X(sel); Y = Y(sel);
% linear fit
yCalc = linear_fit(X,Y);
% p_all = plot(X,yCalc,'Color','k', 'LineWidth',3);
legend(p_ind,{'Individual pair fit'},'Location','southeast')
% legend([p_ind p_all],{'Individual pairs','All pairs combined'},'Location','southeast')
legend box off
% text(0.5,0.2,sprintf('R=%.2f P=%.2g', r_lead, p_lead),'FontSize',20,'Units','normalized')
xlabel('Responder-initiated trials')
ylabel('Initiator-initiated trials')
title(['Initiator advantage (N=' num2str(n_uni_pairs) ' pairs)'])
box off
set(gca,'FontSize',24,'TickDir','out')
axis equal
xlim(axis_range);
ylim(axis_range);
x_ticks = xticks;
yticks(x_ticks);
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_coop_rate_init_by_mice_all_pairs'];
print(fig,figname,'-dpdf');

%% stats
% for a simple comparison of coop rates depending on the initiator
ltable.cp_rate_init_diff = ltable.cp_rate_initBy_sInit - ltable.cp_rate_initBy_sResp;
lme1 = fitlme(ltable, 'cp_rate_init_diff ~ 1 + (1|pair)');
disp(lme1);

%% plot the correlations betwen leader and initiator disparity. not used in paper
uni_pairs = unique(ltable.pair);
n_uni_pairs = length(uni_pairs);
fig = figure('Position',[600 300 600 600]);
hold on;
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    cur_ltable = ltable(strcmp(cur_pair,ltable.pair),:);
    x = cur_ltable.init_dsp;
    y = cur_ltable.lead_dsp;
    % linear fit
    yCalc = linear_fit(x, y);
    p_ind = plot(x,yCalc,'Color',[0.2 0.2 0.2], 'LineWidth',0.5);
    scatter(x,y,50,[0.5 0.5 0.5])
end
X = ltable.init_dsp;
Y = ltable.lead_dsp;
% linear fit
yCalc = linear_fit(X,Y);
p_all = plot(X,yCalc,'Color','k', 'LineWidth',3);
legend([p_ind p_all],{'Individual pairs','All pairs combined'},'Location','northwest')
legend box off
% text(0.5,0.2,sprintf('R=%.2f P=%.2g', r_lead, p_lead),'FontSize',20,'Units','normalized')
xlabel('Initiator disparity')
ylabel('Leader disparity')
title(['Initiator vs. leader disparity all pairs (N=' num2str(n_uni_pairs) ')'])
box off
set(gca,'FontSize',24,'TickDir','out')
axis equal
xlim([-0.08 1]);
ylim([-0.08 1]);
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_scat_initiator_vs_leader_disparity_all_pairs'];
% print(fig,figname,'-dpdf');
%% stats
lme1 = fitlme(ltable, 'lead_dsp ~ init_dsp + (1|pair) + (init_dsp - 1|pair)');
disp(lme1);

lme2 = fitlme(ltable, 'lead_dsp ~ init_dsp + (1|pair)');
disp(lme2);

%% get how many pairs have true leaders at criterion
uni_pairs = unique(ltable.pair);
n_uni_pairs = length(uni_pairs);
pair_table = table;
pair_table.pair = cell(n_uni_pairs,1);
pair_table.true_lead_pval = zeros(n_uni_pairs,1); 
pair_table.true_lead = zeros(n_uni_pairs,1); 
pair_table.true_init = zeros(n_uni_pairs,1); 
pcut = 0.01;
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    pair_table.pair{p} = cur_pair;
    cur_ltable = ltable(strcmp(cur_pair,ltable.pair),:);
    pair_table.sex{p} = cur_ltable.sex{1};
    pair_table.true_lead_pval(p) = cur_ltable.pval_lead(end) < pcut;
    pair_table.true_lead(p) = cur_ltable.true_lead(end);
    pair_table.true_init(p) = cur_ltable.true_init(end);
end
mean(pair_table.true_lead)
mean(pair_table.true_init)
mean(pair_table.true_lead & pair_table.true_init)

sum(pair_table.true_lead)
sum(pair_table.true_init)

%% %%% split by sex %%%

%% plot the correlations between leader disparity and coop rate
sexes = {'female';'male'};
fill_colors = [239,154,154;129, 212, 250]/255;
line_colors = [183, 28, 28;1, 87, 155]/255;
for se = 2
    cur_sex = sexes{se};
    ltable_sex = ltable(strcmp(ltable.sex,cur_sex),:);
    uni_pairs = unique(ltable_sex.pair);
    n_uni_pairs = length(uni_pairs);
    fig = figure('Position',[600 300 400 400]);
    hold on;
    fill_color = fill_colors(se,:);
    line_color = line_colors(se,:)*0.8;
    for p = 1:n_uni_pairs
        cur_pair = uni_pairs{p};
        cur_ltable = ltable_sex(strcmp(cur_pair,ltable_sex.pair),:);
        x = cur_ltable.lead_dsp;
        y = cur_ltable.cp_rate;
        scatter(x,y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
    end
    for p = 1:n_uni_pairs
        cur_pair = uni_pairs{p};
        cur_ltable = ltable_sex(strcmp(cur_pair,ltable_sex.pair),:);
        x = cur_ltable.lead_dsp;
        y = cur_ltable.cp_rate;
        % linear fit
        yCalc = linear_fit(x, y);
        p_ind = plot(x,yCalc,'Color',line_color, 'LineWidth',1);
    end
    X = ltable_sex.lead_dsp;
    Y = ltable_sex.cp_rate;
    % linear fit
    yCalc = linear_fit(X,Y);
    p_all = plot(X,yCalc,'Color',line_color, 'LineWidth',3);
    legend([p_ind p_all],{'Individual pair','Combined'},'Location','southeast')
    legend box off
    % text(0.5,0.2,sprintf('R=%.2f P=%.2g', r_lead, p_lead),'FontSize',20,'Units','normalized')
    xlim([-0.03 0.88]);
    ylim([0.17 1.03]);
    xlabel('Leader disparity')
    ylabel('Cooperation rate')
    title(['Leader disparity vs. coop rate (N=' num2str(n_uni_pairs) ' ' cur_sex ' pairs)'])
    box off
    set(gca,'FontSize',24,'TickDir','out')
    hoy = char(datetime('now','Format','yyyyMMdd'));
    figname = [fd 'plots/' hoy '_scat_leader_disparity_vs_coop_rate_' cur_sex];
    print(fig,figname,'-dpdf');
    lme_sex = fitlme(ltable_sex, 'cp_rate ~ lead_dsp + (lead_dsp|pair)')
end
lme5 = fitlme(ltable, 'cp_rate ~ lead_dsp + sex + (lead_dsp|pair)')

%% correlations between leader disparity and coop rate, both sexes in the same plot
sexes = {'female';'male'};
fill_colors = [239,154,154;129, 212, 250]/255;
line_colors = [183, 28, 28;1, 87, 155]/255;
fig = figure('Position',[600 300 400 400]);
hold on;
for se = 1:2
    cur_sex = sexes{se};
    ltable_sex = ltable(strcmp(ltable.sex,cur_sex),:);
    uni_pairs = unique(ltable_sex.pair);
    n_uni_pairs = length(uni_pairs);
    fill_color = fill_colors(se,:);
    line_color = line_colors(se,:)*0.8;
    for p = 1:n_uni_pairs
        cur_pair = uni_pairs{p};
        cur_ltable = ltable_sex(strcmp(cur_pair,ltable_sex.pair),:);
        x = cur_ltable.lead_dsp;
        y = cur_ltable.cp_rate;
        scatter(x,y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor','none','LineWidth',0.1);
    end
    for p = 1:n_uni_pairs
        cur_pair = uni_pairs{p};
        cur_ltable = ltable_sex(strcmp(cur_pair,ltable_sex.pair),:);
        x = cur_ltable.lead_dsp;
        y = cur_ltable.cp_rate;
        % linear fit
        yCalc = linear_fit(x, y);
        p_ind = plot(x,yCalc,'Color',line_color, 'LineWidth',1);
    end
    X = ltable_sex.lead_dsp;
    Y = ltable_sex.cp_rate;
    % linear fit
    yCalc = linear_fit(X,Y);
    % p_all = plot(X,yCalc,'Color',line_color, 'LineWidth',3);
    legend([p_ind p_all],{'Individual pair','Combined'},'Location','southeast')
    legend box off
    % text(0.5,0.2,sprintf('R=%.2f P=%.2g', r_lead, p_lead),'FontSize',20,'Units','normalized')
    xlim([-0.03 0.88]);
    ylim([0.17 1.03]);
    xlabel('Leader disparity')
    ylabel('Cooperation rate')
    title('Leader disparity vs. coop rate')
    box off
    set(gca,'FontSize',24,'TickDir','out')
    hoy = char(datetime('now','Format','yyyyMMdd'));
    figname = [fd 'plots/' hoy '_scat_leader_disparity_vs_coop_rate_both_sex'];
    print(fig,figname,'-dpdf');
end
% lme5 = fitlme(ltable, 'cp_rate ~ lead_dsp + sex + (lead_dsp|pair)')

%% plot the correlations betwen initiator disparity and coop rate
for se = 2
    fill_color = fill_colors(se,:);
    line_color = line_colors(se,:)*0.8;
    cur_sex = sexes{se};
    ltable_sex = ltable(strcmp(ltable.sex,cur_sex),:);
    uni_pairs = unique(ltable_sex.pair);
    n_uni_pairs = length(uni_pairs);
    fig = figure('Position',[600 300 400 400]);
    hold on;
    for p = 1:n_uni_pairs
        cur_pair = uni_pairs{p};
        cur_ltable = ltable_sex(strcmp(cur_pair,ltable_sex.pair),:);
        x = cur_ltable.init_dsp;
        y = cur_ltable.cp_rate;
        scatter(x,y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
    end
    for p = 1:n_uni_pairs
        cur_pair = uni_pairs{p};
        cur_ltable = ltable_sex(strcmp(cur_pair,ltable_sex.pair),:);
        x = cur_ltable.init_dsp;
        y = cur_ltable.cp_rate;
        % linear fit
        yCalc = linear_fit(x, y);
        p_ind = plot(x,yCalc,'Color',line_color, 'LineWidth',1);
    end
    X = ltable_sex.init_dsp;
    Y = ltable_sex.cp_rate;
    % linear fit
    yCalc = linear_fit(X,Y);
    p_all = plot(X,yCalc,'Color',line_color, 'LineWidth',3);
    legend([p_ind p_all],{'Individual pair','Combined'},'Location','southeast')
    legend box off
    % text(0.5,0.2,sprintf('R=%.2f P=%.2g', r_lead, p_lead),'FontSize',20,'Units','normalized')
    xlim([-0.03 1.03]);
    ylim([0.17 1.03]);
    xlabel('Initiator disparity')
    ylabel('Cooperation rate')
    title(['Initiator disparity vs. coop rate (N=' num2str(n_uni_pairs) ' ' cur_sex ' pairs)'])
    box off
    set(gca,'FontSize',24,'TickDir','out')
    hoy = char(datetime('now','Format','yyyyMMdd'));
    figname = [fd 'plots/' hoy '_scat_initiator_disparity_vs_coop_rate_' cur_sex];
    print(fig,figname,'-dpdf');
    lme_sex = fitlme(ltable_sex, 'cp_rate ~ init_dsp + (init_dsp|pair)')
end
lme5 = fitlme(ltable, 'cp_rate ~ init_dsp + sex + (init_dsp|pair)')

%% scatter plot comparing coop rate of trials led by the two animals
for se = 2
    fill_color = fill_colors(se,:);
    line_color = line_colors(se,:)*0.8;
    cur_sex = sexes{se};
    ltable_sex = ltable(strcmp(ltable.sex,cur_sex),:);
    uni_pairs = unique(ltable_sex.pair);
    n_uni_pairs = length(uni_pairs);
    axis_range = [0.22 1.03];
    fig = figure('Position',[600 300 400 400]);
    hold on;
    for p = 1:n_uni_pairs
        cur_pair = uni_pairs{p};
        cur_ltable = ltable_sex(strcmp(cur_pair,ltable_sex.pair),:);
        x = cur_ltable.cp_rate_ledBy_sFoll;
        y = cur_ltable.cp_rate_ledBy_sLead;
        sel = ~isnan(x);
        x = x(sel); y = y(sel);
        scatter(x,y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor',line_color,'LineWidth',0.1);
    end
    plot(axis_range,axis_range,'k--','LineWidth',1);
    for p = 1:n_uni_pairs
        cur_pair = uni_pairs{p};
        cur_ltable = ltable_sex(strcmp(cur_pair,ltable_sex.pair),:);
        x = cur_ltable.cp_rate_ledBy_sFoll;
        y = cur_ltable.cp_rate_ledBy_sLead;
        sel = ~isnan(x);
        x = x(sel); y = y(sel);
        % linear fit
        yCalc = linear_fit(x, y);
        p_ind = plot(x,yCalc,'Color',line_color, 'LineWidth',1);
    end
    X = ltable_sex.cp_rate_ledBy_sFoll;
    Y = ltable_sex.cp_rate_ledBy_sLead;
    sel = ~isnan(X);
    X = X(sel); Y = Y(sel);
    % linear fit
    yCalc = linear_fit(X,Y);
    % p_all = plot(X,yCalc,'Color','k', 'LineWidth',3);
    legend(p_ind,{'Individual pair fit'},'Location','southeast')
    % legend([p_ind p_all],{'Individual pairs','All pairs combined'},'Location','southeast')
    legend box off
    % text(0.5,0.2,sprintf('R=%.2f P=%.2g', r_lead, p_lead),'FontSize',20,'Units','normalized')
    xlabel('Follower-led trials')
    ylabel('Leader-led trials')
    title(['Leader advantage (N=' num2str(n_uni_pairs) ' ' cur_sex ' pairs)'])
    box off
    set(gca,'FontSize',24,'TickDir','out')
    axis equal
    xlim(axis_range);
    ylim(axis_range);
    x_ticks = xticks;
    yticks(x_ticks);
    hoy = char(datetime('now','Format','yyyyMMdd'));
    figname = [fd 'plots/' hoy '_coop_rate_led_by_mice_' cur_sex];
    print(fig,figname,'-dpdf');
    ltable_sex.cp_rate_diff = ltable_sex.cp_rate_ledBy_sLead - ltable_sex.cp_rate_ledBy_sFoll;
    lme_sex = fitlme(ltable_sex, 'cp_rate_diff ~ 1 + (1|pair)')
end
ltable.cp_rate_diff = ltable.cp_rate_ledBy_sLead - ltable.cp_rate_ledBy_sFoll;
lme1 = fitlme(ltable, 'cp_rate_diff ~ sex + (1|pair)')

%% scatter plot comparing coop rate of trials initiated by the two animals
for se = 2
    fill_color = fill_colors(se,:);
    line_color = line_colors(se,:)*0.8;
    cur_sex = sexes{se};
    ltable_sex = ltable(strcmp(ltable.sex,cur_sex),:);
    uni_pairs = unique(ltable_sex.pair);
    n_uni_pairs = length(uni_pairs);
    fig = figure('Position',[600 300 400 400]);
    axis_range = [0.11 1.03];
    hold on;
    for p = 1:n_uni_pairs
        cur_pair = uni_pairs{p};
        cur_ltable = ltable_sex(strcmp(cur_pair,ltable_sex.pair),:);
        x = cur_ltable.cp_rate_initBy_sResp;
        y = cur_ltable.cp_rate_initBy_sInit;
        sel = ~isnan(x);
        x = x(sel); y = y(sel);
        scatter(x,y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor',line_color,'LineWidth',0.1);
    end
    plot(axis_range,axis_range,'k--','LineWidth',1);
    for p = 1:n_uni_pairs
        cur_pair = uni_pairs{p};
        cur_ltable = ltable_sex(strcmp(cur_pair,ltable_sex.pair),:);
        x = cur_ltable.cp_rate_initBy_sResp;
        y = cur_ltable.cp_rate_initBy_sInit;
        sel = ~isnan(x);
        x = x(sel); y = y(sel);
        % linear fit
        yCalc = linear_fit(x, y);
        p_ind = plot(x,yCalc,'Color',line_color, 'LineWidth',1);
    end
    X = ltable_sex.cp_rate_initBy_sResp;
    Y = ltable_sex.cp_rate_initBy_sInit;
    sel = ~isnan(X);
    X = X(sel); Y = Y(sel);
    % linear fit
    yCalc = linear_fit(X,Y);
    % p_all = plot(X,yCalc,'Color','k', 'LineWidth',3);
    legend(p_ind,{'Individual pair fit'},'Location','southeast')
    % legend([p_ind p_all],{'Individual pairs','All pairs combined'},'Location','southeast')
    legend box off
    % text(0.5,0.2,sprintf('R=%.2f P=%.2g', r_lead, p_lead),'FontSize',20,'Units','normalized')
    xlabel('Responder-initiated trials')
    ylabel('Initiator-initiated trials')
    title(['Initiator advantage (N=' num2str(n_uni_pairs) ' pairs)'])
    box off
    set(gca,'FontSize',24,'TickDir','out')
    axis equal
    xlim(axis_range);
    ylim(axis_range);
    x_ticks = xticks;
    yticks(x_ticks);
    hoy = char(datetime('now','Format','yyyyMMdd'));
    figname = [fd 'plots/' hoy '_coop_rate_init_by_mice_' cur_sex];
    print(fig,figname,'-dpdf');
    ltable_sex.cp_rate_init_diff = ltable_sex.cp_rate_initBy_sInit - ltable_sex.cp_rate_initBy_sResp;
    lme_sex = fitlme(ltable_sex, 'cp_rate_init_diff ~ 1 + (1|pair)')
end
%% stats
% for a simple comparison of coop rates depending on the initiator
ltable.cp_rate_init_diff = ltable.cp_rate_initBy_sInit - ltable.cp_rate_initBy_sResp;
lme1 = fitlme(ltable, 'cp_rate_init_diff ~ sex + (1|pair)');
disp(lme1);

%% proportion of true leader and initiator
% female
mean(pair_table(strcmp(pair_table.sex,'female'),:).true_lead)
mean(pair_table(strcmp(pair_table.sex,'female'),:).true_init)

% male
mean(pair_table(strcmp(pair_table.sex,'male'),:).true_lead)
mean(pair_table(strcmp(pair_table.sex,'male'),:).true_init)