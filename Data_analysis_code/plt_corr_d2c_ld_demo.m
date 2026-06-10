function plt_corr_d2c_ld_v2(ltable,fd)
% plot correlation between days to criterion and leader disparity at criterion
ltable = recalc_leader_disp(ltable);

%% correlation between days to criterion and lead disparity at criterion
uni_pairs = unique(ltable.pair);
n_uni_pairs = length(uni_pairs);
crit_table = table;
% crit_table.pair = cell(n_uni_pairs,1);
crit_table.days2crit = nan(n_uni_pairs,1);
crit_table.lead_dsp = nan(n_uni_pairs,1);
crit_table.init_dsp = nan(n_uni_pairs,1);
crit_table.sex = cell(n_uni_pairs,1);
for n = 1:n_uni_pairs
    cur_pair = uni_pairs{n};
    cur_ltable = ltable(strcmp(cur_pair,ltable.pair),:);
    % crit_table.pair{n} = cur_pair;
    crit_table.sex{n} = cur_ltable.sex{end};
    crit_table.days2crit(n) = cur_ltable.days(end);
    crit_table.lead_dsp(n) = cur_ltable.lead_dsp(end);
    crit_table.init_dsp(n) = cur_ltable.init_dsp(end);
end
x = crit_table.lead_dsp;
% x = crit_table.init_dsp;
y = crit_table.days2crit;
fig = figure('Position',[600 300 400 400]);
hold on
fill_color = [0.9,0.9,0.9];
scatter(x,y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
yCalc = linear_fit(x, y);    % linear fit
plot(x,yCalc,'Color',[0.2 0.2 0.2],'LineStyle','-', 'LineWidth',2);
[r,p] = corr(x,y);
text(0.03,0.95,sprintf('R=%.2f P=%.2g', r, p),'FontSize',24,'Units','normalized')
xlabel('Leader disparity at criterion')
ylabel('Days to criterion')
title(['Disparity correlates with learning rate (N=' num2str(n_uni_pairs) ' pairs)'])
box off
set(gca,'FontSize',24,'TickDir','out')
ylim([0 55])
xlim([-0.03 0.92])
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_disparity_corr_learning_rate'];
print(fig,figname,'-dpdf');
%% stats
mdl = fitglm(crit_table, 'days2crit ~ lead_dsp + sex')
mdl.ModelCriterion.BIC

mdl2 = fitglm(crit_table, 'days2crit ~ lead_dsp*sex')
mdl2.ModelCriterion.BIC

% mdl = stepwiseglm(crit_table,'days2crit ~ lead_dsp','Upper','interactions')
mdl3 =  stepwiseglm(crit_table,'constant','ResponseVar','days2crit',...
    'PredictorVars',{'lead_dsp','sex'},'Criterion','Deviance','Verbose',2)
%% split by sex 
% correlation between days to criterion and lead disparity at criterion
sexes = {'female';'male'};
fill_colors = [239,154,154;129, 212, 250]/255;
line_colors = [183, 28, 28;1, 87, 155]/255;

for se = 1:2
    cur_sex = sexes{se};
    fill_color = fill_colors(se,:);
    line_color = line_colors(se,:)*0.8;
    ltable_sex = ltable(strcmp(ltable.sex,cur_sex),:);
    uni_pairs = unique(ltable_sex.pair);
    n_uni_pairs = length(uni_pairs);
    days2crit = nan(n_uni_pairs,1);
    lead_dsp = nan(n_uni_pairs,1);
    pairs = cell(n_uni_pairs,1);
    for n = 1:n_uni_pairs
        cur_pair = uni_pairs{n};
        cur_ltable = ltable_sex(strcmp(cur_pair,ltable_sex.pair),:);
        days2crit(n) = cur_ltable.days(end);
        lead_dsp(n) = cur_ltable.lead_dsp(end);
        pairs{n} = cur_pair;
    end
    x = lead_dsp;
    y = days2crit;
    fig = figure('Position',[600 300 400 400]);
    hold on
    scatter(x,y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
    yCalc = linear_fit(x, y);    % linear fit
    plot(x,yCalc,'Color',line_color,'LineStyle','-', 'LineWidth',2);
    [r,p] = corr(x,y);
    text(0.03,0.95,sprintf('R=%.2f P=%.2g', r, p),'FontSize',24,'Units','normalized')
    xlabel('Leader disparity at criterion')
    ylabel('Days to criterion')
    title(['Disparity correlates with learning rate (N=' num2str(n_uni_pairs) ' ' cur_sex ' pairs)'])
    box off
    set(gca,'FontSize',24,'TickDir','out')
    ylim([0 55])
    xlim([-0.03 0.92])
    hoy = char(datetime('now','Format','yyyyMMdd'));
    figname = [fd 'plots/' hoy '_disparity_corr_learning_rate_' cur_sex];
    print(fig,figname,'-dpdf');
end

%% all pairs with males and females separated colored
uni_pairs = unique(ltable.pair);
n_uni_pairs = length(uni_pairs);
crit_table = table;
crit_table.pair = cell(n_uni_pairs,1);
crit_table.days2crit = nan(n_uni_pairs,1);
crit_table.lead_dsp = nan(n_uni_pairs,1);
crit_table.init_dsp = nan(n_uni_pairs,1);
crit_table.sex = cell(n_uni_pairs,1);
fig = figure('Position',[600 300 400 400]);
hold on
sexes = {'female';'male'};
fill_colors = [239,154,154;129, 212, 250]/255;
line_colors = [183, 28, 28;1, 87, 155]/255;
for n = 1:n_uni_pairs
    cur_pair = uni_pairs{n};
    cur_ltable = ltable(strcmp(cur_pair,ltable.pair),:);
    crit_table.pair{n} = cur_pair;
    crit_table.sex{n} = cur_ltable.sex{end};
    crit_table.days2crit(n) = cur_ltable.days(end);
    crit_table.lead_dsp(n) = cur_ltable.lead_dsp(end);
    crit_table.init_dsp(n) = cur_ltable.init_dsp(end);
    cur_sex = crit_table.sex{n};
    idx_sex = find(strcmp(sexes,cur_sex));
    fill_color = fill_colors(idx_sex,:);
    line_color = line_colors(idx_sex,:);
    scatter(crit_table.lead_dsp(n),crit_table.days2crit(n),100,...
        'MarkerFaceColor',fill_color,'MarkerEdgeColor',line_color,'LineWidth',0.1);
end
x = crit_table.lead_dsp;
y = crit_table.days2crit;
yCalc = linear_fit(x, y);    % linear fit
plot(x,yCalc,'Color',[0.2 0.2 0.2],'LineStyle','-', 'LineWidth',2);
[r,p] = corr(x,y);
text(0.03,0.95,sprintf('R=%.2f P=%.2g', r, p),'FontSize',24,'Units','normalized')
xlabel('Leader disparity at criterion')
ylabel('Days to criterion')
title(['Disparity correlates with learning rate (N=' num2str(n_uni_pairs) ' pairs)'])
box off
set(gca,'FontSize',24,'TickDir','out')
ylim([0 55])
xlim([-0.03 0.92])
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_disparity_corr_learning_rate_sexes'];
print(fig,figname,'-dpdf');

%% correlation between init_prop and days2crit
x = crit_table.init_dsp;
y = crit_table.days2crit;
fig = figure('Position',[600 300 400 400]);
hold on
fill_color = [0.9,0.9,0.9];
scatter(x,y,100,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
yCalc = linear_fit(x, y);    % linear fit
plot(x,yCalc,'Color',[0.2 0.2 0.2],'LineStyle','-', 'LineWidth',2);
[r,p] = corr(x,y);
text(0.03,0.95,sprintf('R=%.2f P=%.2g', r, p),'FontSize',24,'Units','normalized')
xlabel('Initiator disparity at criterion')
ylabel('Days to criterion')
title(['Disparity correlates with learning rate (N=' num2str(n_uni_pairs) ' pairs)'])
box off
set(gca,'FontSize',24,'TickDir','out')
ylim([0 55])
xlim([-0.03 0.92])
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_init_dsp_corr_learning_rate'];
print(fig,figname,'-dpdf');
mdl = fitglm(crit_table, 'days2crit ~ lead_dsp + init_dsp')
