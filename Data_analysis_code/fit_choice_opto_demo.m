function fit_choice_opto_demo(fd, opto_table, which_mouse, time_window)
%% fit choice for optogenetic inactivation

switch which_mouse
    case 'both'
        opto_table_sel = opto_table(strcmp(opto_table.inact_feat,time_window) ...
            & strcmp(opto_table.subject,which_mouse),:);

    case 'leader'
        opto_table_sel = [];
        cur_table = opto_table(strcmp(opto_table.inact_feat,time_window),:);
        uni_pairs = unique(cur_table.pair);
        n_pairs = length(uni_pairs);

        for p = 1:n_pairs
            cur_pair = uni_pairs{p};
            cur_table_pair = cur_table(strcmp(cur_table.pair,cur_pair),:);
            cur_leader = cur_table_pair.sLead_N(strcmp(cur_table_pair.subject,'both'));
            cur_table_sel = cur_table_pair(strcmp(cur_table_pair.subject,cur_leader{1}),:);
            opto_table_sel = [opto_table_sel; cur_table_sel];
        end

    case 'follower'
        opto_table_sel = [];
        cur_table = opto_table(strcmp(opto_table.inact_feat,time_window),:);
        uni_pairs = unique(cur_table.pair);
        n_pairs = length(uni_pairs);

        for p = 1:n_pairs
            cur_pair = uni_pairs{p};
            cur_table_pair = cur_table(strcmp(cur_table.pair,cur_pair),:);
            cur_follower = cur_table_pair.sFoll_N(strcmp(cur_table_pair.subject,'both'));
            cur_table_sel = cur_table_pair(strcmp(cur_table_pair.subject,cur_follower{1}),:);
            opto_table_sel = [opto_table_sel; cur_table_sel];
        end
end

coords_north = [0 22.5];
coords_east = [22.5 0];

uni_pairs = unique(opto_table_sel.pair);
n_pairs = length(uni_pairs);

mstable = [];

for p = 1:n_pairs

    cur_pair = uni_pairs{p};
    stable = opto_table_sel.stable{p};

    leader = opto_table_sel.sLead_N{p};
    follower = opto_table_sel.sFoll_N{p};

    % apply selection criteria
    sel_co_mm = stable.correct == 1 | stable.mismatch == 1;
    sel_trial_dur = stable.dur_f < 150;
    sel_trial_type = stable.trial_type >= 1 & stable.trial_type <= 4;
    sel_trials1 = sel_co_mm & sel_trial_dur & sel_trial_type;
    sel_trials2 = ~isnan(stable.m1_choose_n) & ~isnan(stable.m2_choose_n);

    stable_sel = stable(sel_trials1 & sel_trials2,:);

    for m = 1:2

        id_self = ['m' num2str(m)];

        % angle to east and north
        angle_zero = stable_sel.([id_self '_hd_rot']);

        angle_east = angle_zero;
        angle_east(angle_east > 180) = angle_east(angle_east > 180) - 360;
        stable_sel.([id_self '_angle_east']) = abs(angle_east);

        angle_north = angle_zero - 90;
        angle_north(angle_zero > 270) = angle_north(angle_zero > 270) - 360;
        stable_sel.([id_self '_angle_north']) = abs(angle_north);

        stable_sel.([id_self '_angle_dif']) = ...
            (stable_sel.([id_self '_angle_east']) - ...
             stable_sel.([id_self '_angle_north'])) / 90;

        stable_sel.([id_self '_angle_rz_dif']) = ...
            (stable_sel.([id_self '_angle_ez_rot']) - ...
             stable_sel.([id_self '_angle_nz_rot'])) / 180;

        % distance to east and north zones
        x_coords = stable_sel.([id_self '_x_rot']);
        y_coords = stable_sel.([id_self '_y_rot']);

        stable_sel.([id_self '_d2east']) = ...
            sqrt((x_coords - coords_east(1)).^2 + ...
                 (y_coords - coords_east(2)).^2);

        stable_sel.([id_self '_d2north']) = ...
            sqrt((x_coords - coords_north(1)).^2 + ...
                 (y_coords - coords_north(2)).^2);

        stable_sel.([id_self '_dis_dif']) = ...
            stable_sel.([id_self '_d2east']) - ...
            stable_sel.([id_self '_d2north']);

    end

    % leader variables
    stable_sel.lead_angle_east = stable_sel.([leader '_angle_east']);
    stable_sel.lead_angle_north = stable_sel.([leader '_angle_north']);
    stable_sel.lead_angle_dif = stable_sel.([leader '_angle_dif']);
    stable_sel.lead_angle_ez_rot = stable_sel.([leader '_angle_ez_rot']);
    stable_sel.lead_angle_nz_rot = stable_sel.([leader '_angle_nz_rot']);
    stable_sel.lead_angle_rz_dif = stable_sel.([leader '_angle_rz_dif']);
    stable_sel.lead_d2north = stable_sel.([leader '_d2north']);
    stable_sel.lead_d2east = stable_sel.([leader '_d2east']);
    stable_sel.lead_dis_dif = stable_sel.([leader '_dis_dif']);
    stable_sel.lead_choose_n = stable_sel.([leader '_choose_n']);

    % follower variables
    stable_sel.foll_angle_east = stable_sel.([follower '_angle_east']);
    stable_sel.foll_angle_north = stable_sel.([follower '_angle_north']);
    stable_sel.foll_angle_dif = stable_sel.([follower '_angle_dif']);
    stable_sel.foll_angle_ez_rot = stable_sel.([follower '_angle_ez_rot']);
    stable_sel.foll_angle_nz_rot = stable_sel.([follower '_angle_nz_rot']);
    stable_sel.foll_angle_rz_dif = stable_sel.([follower '_angle_rz_dif']);
    stable_sel.foll_d2north = stable_sel.([follower '_d2north']);
    stable_sel.foll_d2east = stable_sel.([follower '_d2east']);
    stable_sel.foll_dis_dif = stable_sel.([follower '_dis_dif']);
    stable_sel.foll_choose_n = stable_sel.([follower '_choose_n']);

    stable_sel.lead_sees_foll_angle_rot = ...
        stable_sel.([leader '_sees_' follower '_angle_rot']);

    stable_sel.foll_sees_lead_angle_rot = ...
        stable_sel.([follower '_sees_' leader '_angle_rot']);

    stable_sel.dis_btwn_mice = vecnorm( ...
        [stable_sel.m1_x_rot - stable_sel.m2_x_rot, ...
         stable_sel.m1_y_rot - stable_sel.m2_y_rot],2,2);

    stable_sel.pair = repmat({cur_pair},height(stable_sel),1);

    mstable = [mstable; stable_sel];

end

mstable = movevars(mstable,{'pair'},'Before','trial_no');
mstable = renamevars(mstable,"Triger_out","inact");

mstable.lead_angle_rz_dif = standardize_hw(mstable.lead_angle_rz_dif);
mstable.lead_dis_dif = standardize_hw(mstable.lead_dis_dif);
mstable.foll_angle_rz_dif = standardize_hw(mstable.foll_angle_rz_dif);
mstable.foll_dis_dif = standardize_hw(mstable.foll_dis_dif);

mstable.lead_sees_foll_angle_abs = abs(mstable.lead_sees_foll_angle_rot);
mstable.foll_sees_lead_angle_abs = abs(mstable.foll_sees_lead_angle_rot);

mstable.lead_sees_foll_angle_bin = mstable.lead_sees_foll_angle_abs < 120;
mstable.foll_sees_lead_angle_bin = mstable.foll_sees_lead_angle_abs < 120;

%% ===== source data: every trial used in GLM =====

source_data = mstable(:, { ...
    'pair', ...
    'inact', ...
    'lead_choose_n', ...
    'foll_choose_n', ...
    'lead_angle_rz_dif', ...
    'lead_dis_dif', ...
    'foll_angle_rz_dif', ...
    'foll_dis_dif'});

source_data.WhichMouse = repmat({which_mouse},height(source_data),1);
source_data.TimeWindow = repmat({time_window},height(source_data),1);

assignin('base','source_data',source_data);

%% get beta coefficients of all pairs combined

roles = {'lead','foll'};

beta_estimate = nan(2,4);
se_estimate = nan(2,4);
p_estimate = nan(2,4);

stats_table = table();

for r = 1:2

    cur_role = roles{r};
    which_choose_n = [cur_role '_choose_n'];

    modelspec = [which_choose_n ...
        ' ~ (lead_angle_rz_dif + lead_dis_dif + foll_angle_rz_dif + foll_dis_dif) * inact'];

    mdl = fitglm(mstable,modelspec,Distribution="Binomial");

    fprintf('\n====================================\n')
    fprintf('%s choice model | opto %s | %s\n',cur_role,which_mouse,time_window)
    fprintf('====================================\n')
    disp(mdl.Coefficients)

    beta_estimate(r,:) = mdl.Coefficients.Estimate(7:10);
    se_estimate(r,:) = mdl.Coefficients.SE(7:10);
    p_estimate(r,:) = mdl.Coefficients.pValue(7:10);

    coef_names = mdl.CoefficientNames';

    T_stats = table( ...
        repmat({which_mouse},length(coef_names),1), ...
        repmat({time_window},length(coef_names),1), ...
        repmat({cur_role},length(coef_names),1), ...
        coef_names, ...
        mdl.Coefficients.Estimate, ...
        mdl.Coefficients.SE, ...
        mdl.Coefficients.tStat, ...
        mdl.Coefficients.pValue, ...
        'VariableNames', ...
        {'WhichMouse','TimeWindow','ChoiceRole','Coefficient', ...
        'Estimate','SE','TStat','PValue'});

    stats_table = [stats_table; T_stats];

end

assignin('base','stats_table',stats_table);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

%% paired bar plot

m_colors = [194, 165, 207; 166, 219, 160] / 255;

fig = figure('Position',[600 300 300 400]);

ylims = [-3.8 1.4]; % both
% ylims = [-2.8 2.8]; % leader and follower

hold on;

x = 1:4;

b = bar(x,beta_estimate, ...
    'FaceColor','flat', ...
    'EdgeColor','none', ...
    'GroupWidth',0.8); 

b(1).FaceColor = m_colors(1,:);
b(2).FaceColor = m_colors(2,:);

for i = 1:4
    for r = 1:2

        if beta_estimate(r,i)>0
            errorbar(b(r).XEndPoints(i),beta_estimate(r,i),[],se_estimate(r,i), ...
                'Color',m_colors(r,:), ...
                'LineWidth',2);
        else
            errorbar(b(r).XEndPoints(i),beta_estimate(r,i),se_estimate(r,i),[], ...
                'Color',m_colors(r,:), ...
                'LineWidth',2);
        end  

        if p_estimate(r,i) < 0.001
            text(b(r).XEndPoints(i),0.95*ylims(2),'***', ...
                'HorizontalAlignment','center', ...
                'Rotation',90, ...
                'Units','data', ...
                'FontSize',18) 
        elseif p_estimate(r,i) < 0.01
            text(b(r).XEndPoints(i),0.95*ylims(2),'**', ...
                'HorizontalAlignment','center', ...
                'Rotation',90, ...
                'Units','data', ...
                'FontSize',18) 
        elseif p_estimate(r,i) < 0.05
            text(b(r).XEndPoints(i),0.95*ylims(2),'*', ...
                'HorizontalAlignment','center', ...
                'Rotation',90, ...
                'Units','data', ...
                'FontSize',18) 
        end

    end
end

xlim([0.5 4.5])
ylim(ylims)

xticks(1:4);
xticklabels({'Dif lead hd','Dif lead dis','Dif foll hd','Dif foll dis'});

ylabel('\Deltalog odds');

legend(b,{'Leader','Follower'},'Location','south');
legend box off

box off

ax = gca;
set(ax,'FontSize',24,'TickDir','out');

hoy = char(datetime('now','Format','yyyyMMdd'));

figname = [fd 'plots/' hoy '_fitting_opto_' which_mouse];

caption = ['Opto inact in ' which_mouse ' on sensitivity'];
title(caption,'FontSize',24)

print(fig,figname,'-dpdf');

end