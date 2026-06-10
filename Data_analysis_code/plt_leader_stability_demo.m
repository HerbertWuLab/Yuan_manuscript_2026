function fig = plt_leader_stability_v2(fd,ctable)
% plot proportion led by batch leader - proportion led by batch follower

%% get well-trained sessions
ltable = extract_ltable(ctable);
uni_pairs = unique(ctable.pair);
n_uni_pairs = length(uni_pairs);
dsp_table = table(cell(n_uni_pairs,1),zeros(n_uni_pairs,1), zeros(n_uni_pairs,1), cell(n_uni_pairs,1), ...
    'VariableNames', {'pair','prop_ledBy_leader', 'SEM', 'LeadPropValues'});
dsp_table.p_val = zeros(n_uni_pairs, 1);
dsp_table.p_ledBy_sLead = zeros(n_uni_pairs, 1);
dsp_table.cp_rate_ledBy_sFoll = zeros(n_uni_pairs, 1);
dsp_table.cp_rate_ledBy_sLead = zeros(n_uni_pairs, 1);
dsp_table.p_chi = nan(n_uni_pairs,1);

for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    dsp_table.pair{p} = cur_pair;
    btable = ctable(strcmp(cur_pair, ctable.pair), :);
    dsp_table.sex{p} = btable.sex{1};
    switch cur_pair % only use sessions before extended phase4b+cno sessions
        case 'YC013YC014'
            btable = btable(str2double(btable.date) <= 20230804, :);
        case 'YC015YC016'
            btable = btable(str2double(btable.date) <= 20230831, :);
        case 'YC017YC018'
            btable = btable(str2double(btable.date) <= 20231017, :);    
    end

    % get criterion day performance
    cur_ltable = ltable(strcmp(cur_pair, ltable.pair), :);

    if isempty(cur_ltable.true_lead)
        disp([cur_pair ' does not have criterion day data.'])        
        continue
    elseif cur_ltable.true_lead(end)==0
        disp([cur_pair ' does not have established leader at criterion day 3.'])        
        continue
    else
        crit_day1 = cur_ltable.date(end-2);
        sel_date = str2double(btable.date) >= str2double(crit_day1);
        s_range = btable.cno==0 & btable.cp_rate>=0.795 & strcmpi(btable.phase,'phase4a')...
            & (btable.p_ledBy_m1+btable.p_ledBy_m2)>=0.8 & sel_date;
        if sum(s_range) < 5
            disp([cur_pair ' has less than 5 well-trained sessions.'])  
            continue
        end
        btable = btable(s_range, :);
       
    end
    btable = recalc_leader_disp(btable);

    dsp_table.n_ses(p) = height(btable);
    avr_ledBy_m1=mean(btable.p_ledBy_m1_adj);
    avr_ledBy_m2=mean(btable.p_ledBy_m2_adj);
    if avr_ledBy_m1>avr_ledBy_m2
        lead_prop = btable.p_ledBy_m1_adj;
    else
        lead_prop = btable.p_ledBy_m2_adj;
    end

    dsp_table.prop_ledBy_leader(p) = mean(lead_prop);
    n = length(lead_prop);
    dsp_table.SEM(p) = std(lead_prop) / sqrt(n);
    dsp_table.LeadPropValues{p} = lead_prop;  

    % binomial test of significant leader for each pair
    stable = table();
    for s = 1:height(btable)
        sel_stable = btable.stable{s};
        stable = [stable; sel_stable];
    end
    index = isnan(stable.leader);
    stable(index, :) = [];
    n_ledby_m1 = sum(stable.leader == 1);
    n_ledby_m2 = sum(stable.leader == 2);

    P_val = binocdf(n_ledby_m1, n_ledby_m1 + n_ledby_m2, 0.5);
    if P_val > 0.5
        P_val = 1 - P_val;
    end
    dsp_table.p_val(p) = 2 * P_val;
    dsp_table.pair{p} = cur_pair;
    dsp_table.n_trials(p) = n_ledby_m1 + n_ledby_m2;

    dsp_table.p_ledBy_sLead(p) = mean(btable.p_ledBy_sLead);
    dsp_table.cp_rate_ledBy_sFoll(p) = mean(btable.cp_rate_ledBy_sFoll);
    dsp_table.cp_rate_ledBy_sLead(p) = mean(btable.cp_rate_ledBy_sLead);

    % chi-square test to compare props across sessions
    observed = [btable.n_ledBy_m1, btable.n_ledBy_m2];
    % Get total number of observations
    total = sum(observed, 'all');
    % Row and column totals
    row_totals = sum(observed, 2);  % Row totals
    col_totals = sum(observed, 1);  % Column totals
    % Compute expected frequencies for each cell
    expected = (row_totals * col_totals) ./ total;
    % Compute chi-square statistic
    chi2_stat = sum(((observed - expected).^2) ./ expected, 'all');
    % Degrees of freedom = (rows - 1) * (columns - 1)
    df = (size(observed, 1) - 1) * (size(observed, 2) - 1);
    % Compute p-value using chi-squared cumulative distribution function
    p_chi = 1 - chi2cdf(chi2_stat, df);
    % fprintf('Chi-square statistic: %.3f\n', chi2_stat);
    % fprintf('Degrees of freedom: %d\n', df);
    % fprintf('P-value: %.4f\n', pval);
    dsp_table.p_chi(p) = p_chi;
end
dsp_table = sortrows(dsp_table, 'prop_ledBy_leader', 'descend');
dsp_table(dsp_table.prop_ledBy_leader == 0, :) = []; 
% save([fd 'dsp_table.mat'],'dsp_table');

%% plotting
% dsp_table(dsp_table.MeanLeadDSP == 0, :) = []; 
fig = figure('position',[600 200 300 300]);
x = 1:height(dsp_table);
y = dsp_table.prop_ledBy_leader;
sem = dsp_table.SEM;
hold on;
fill_color = [0.9,0.9,0.9];
% scatter plot
for i = 1:height(dsp_table)
    lead_prop_values = dsp_table.LeadPropValues{i};
    % scatter(ones(size(lead_dsp_values)) * x(i), lead_dsp_values, 10, 'k', 'filled', 'jitter', 'on', 'jitterAmount', 0.05);
    scatter(ones(size(lead_prop_values)) * x(i), lead_prop_values,30,'MarkerFaceColor',fill_color,'MarkerEdgeColor','k','LineWidth',0.1);
end
errorbar(x, y, sem, '.', 'LineWidth', 2, 'MarkerSize', 20, 'Color', 'k');
% xlim([0 27]);
xticks(10:10:height(dsp_table));
xlabel('Well-trained pairs (sorted)')
ylabel('Prop led by leader');
ylim([0.4 1]);
yticks(0.4:0.2:1);
set(gca,'TickDir','out','FontSize',20);
title_str='Leadership stability';
title(title_str);
box off
hold off;
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd '/plots/' hoy '_leader_stability'];
% set(fig,'PaperOrientation','landscape');
print(fig,figname,'-dpdf');

%% plotting split by sex
% dsp_table(dsp_table.MeanLeadDSP == 0, :) = []; 
dsp_table = sortrows(dsp_table, {'sex','prop_ledBy_leader'}, {'ascend','descend'});
sexes = {'female';'male'};
fill_colors = [239,154,154;129, 212, 250]/255;
line_colors = [183, 28, 28;1, 87, 155]/255;
fig = figure('position',[600 200 300 300]);
x = 1:height(dsp_table);
hold on;
for i = 1:height(dsp_table)
    lead_prop_values = dsp_table.LeadPropValues{i};
    cur_sex = dsp_table.sex{i};
    idx_sex = find(strcmp(sexes,cur_sex));
    fill_color = fill_colors(idx_sex,:);
    line_color = line_colors(idx_sex,:);
    scatter(ones(size(lead_prop_values)) * x(i), lead_prop_values,30,'MarkerFaceColor',fill_color,'MarkerEdgeColor',line_color,'LineWidth',0.1);
    errorbar(i, dsp_table.prop_ledBy_leader(i), dsp_table.SEM(i), '.', 'LineWidth', 2, 'MarkerSize', 20, 'Color', line_color);
end
xticks(10:10:height(dsp_table));
xlabel('Well-trained pairs (sorted)')
ylabel('Prop led by leader');
ylim([0.4 1]);
yticks(0.4:0.2:1);
set(gca,'TickDir','out','FontSize',20);
title_str='Leadership stability';
title(title_str);
box off
hold off;
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd '/plots/' hoy '_leader_stability_sex'];
% set(fig,'PaperOrientation','landscape');
print(fig,figname,'-dpdf');
%% stats
dsp_table(dsp_table.prop_ledBy_leader == 0, :) = []; 
p_females = dsp_table.prop_ledBy_leader(strcmp(dsp_table.sex,'female'));
p_males = dsp_table.prop_ledBy_leader(strcmp(dsp_table.sex,'male'));
[p,h] = ranksum(p_females,p_males)