function fit_all_choice_cno_demo(fd,inact_ses_info_fname,ctable)

%% clean up table
ctable.cno(isnan(ctable.cno)) = 0;

%% get CNO table
which_mouse = {'m1','m2','both'};
which_phase = {'phase4a'}; 
which_dose = 5;

cno_table = extract_cno_table_demo(inact_ses_info_fname,ctable,which_mouse,which_phase,which_dose);
[~,ia,~] = unique(cno_table(:, {'pair', 'date'}), 'rows');
cno_table_uniq = cno_table(ia,:);

%% set params
coords_north = [0 22.5];
coords_east = [22.5 0];

uni_pairs = unique(cno_table_uniq.pair);
n_uni_pairs = length(uni_pairs);

threshold = 0.8;
mstable = [];

%% build master table
for p = 1:n_uni_pairs

    cur_pair = uni_pairs{p};

    btable = cno_table_uniq(strcmp(cur_pair,cno_table_uniq.pair),:);

    if strcmp(cur_pair,'YC057YC058')
        btable = btable(str2double(btable.date)~=20240415,:);
    end

    n_ses = height(btable);

    n_ledBy_m1 = sum(strcmp(btable.sLead,'m1'));
    n_ledBy_m2 = sum(strcmp(btable.sLead,'m2'));

    if n_ledBy_m1 >= n_ses * threshold
        cLead = 1; 
        cFoll = 2;
    elseif n_ledBy_m2 >= n_ses * threshold
        cLead = 2; 
        cFoll = 1;
    else
        fprintf(['No mouse leads more than prop=%.2f of well-trained, phase4a,'...
            ' control sessions in ' cur_pair '. Check data!\n'],threshold)
        continue;
    end

    for s = 1:height(btable)

        stable = btable.stable{s};
        n_trials = height(stable);

        if btable.cno(s)==0

            stable.cno_lead = zeros(n_trials,1); 
            stable.cno_foll = zeros(n_trials,1);

        elseif btable.cno(s)==1 && strcmp(btable.subject(s),'both')

            stable.cno_lead = ones(n_trials,1); 
            stable.cno_foll = ones(n_trials,1);

        elseif btable.cno(s)==1 && strcmp(btable.subject(s),btable.sLead(s))

            stable.cno_lead = ones(n_trials,1); 
            stable.cno_foll = zeros(n_trials,1);    

        elseif btable.cno(s)==1 && strcmp(btable.subject(s),btable.sFoll(s))

            stable.cno_lead = zeros(n_trials,1); 
            stable.cno_foll = ones(n_trials,1);  

        else
            disp([cur_pair ' ' btable.date{s}])
        end

        btable.stable{s} = stable;

    end

    stable = vertcat(btable.stable{:});

    sel_co_mm = stable.correct == 1 | stable.mismatch == 1;
    sel_trial_dur = stable.dur_f < 150;
    sel_trial_type = stable.trial_type >=1 & stable.trial_type <=4;
    sel_trials1 = sel_co_mm & sel_trial_dur & sel_trial_type;
    sel_trials2 = ~isnan(stable.m1_choose_n) & ~isnan(stable.m2_choose_n);

    stable_sel = stable(sel_trials1 & sel_trials2,:);

    for m = 1:2

        id_self = ['m' num2str(m)];

        angle_zero = stable_sel.([id_self '_hd_rot']);

        angle_east = angle_zero;
        angle_east(angle_east>180) = angle_east(angle_east>180) - 360;
        stable_sel.([id_self '_angle_east']) = abs(angle_east);

        angle_north = angle_zero - 90;
        angle_north(angle_zero>270) = angle_north(angle_zero>270) - 360;
        stable_sel.([id_self '_angle_north']) = abs(angle_north);

        stable_sel.([id_self '_angle_dif']) = ...
            (stable_sel.([id_self '_angle_east']) - ...
            stable_sel.([id_self '_angle_north']))/90;

        stable_sel.([id_self '_angle_rz_dif']) = ...
            (stable_sel.([id_self '_angle_ez_rot']) - ...
            stable_sel.([id_self '_angle_nz_rot']))/180;

        x_coords = stable_sel.([id_self '_x_rot']);
        y_coords = stable_sel.([id_self '_y_rot']);

        stable_sel.([id_self '_d2east']) = ...
            sqrt((x_coords-coords_east(1)).^2 + ...
            (y_coords-coords_east(2)).^2);

        stable_sel.([id_self '_d2north']) = ...
            sqrt((x_coords-coords_north(1)).^2 + ...
            (y_coords-coords_north(2)).^2);

        stable_sel.([id_self '_dis_dif']) = ...
            stable_sel.([id_self '_d2east']) - ...
            stable_sel.([id_self '_d2north']);

    end

    leader = ['m' num2str(cLead)];

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

    follower = ['m' num2str(cFoll)];

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

mstable = movevars(mstable,{'pair','cno_lead','cno_foll'},'Before','trial_no');

mstable.lead_angle_rz_dif = standardize_hw(mstable.lead_angle_rz_dif);
mstable.lead_dis_dif = standardize_hw(mstable.lead_dis_dif);
mstable.foll_angle_rz_dif = standardize_hw(mstable.foll_angle_rz_dif);
mstable.foll_dis_dif = standardize_hw(mstable.foll_dis_dif);

mstable.lead_sees_foll_angle_abs = abs(mstable.lead_sees_foll_angle_rot);
mstable.foll_sees_lead_angle_abs = abs(mstable.foll_sees_lead_angle_rot);

mstable.lead_sees_foll_angle_bin = mstable.lead_sees_foll_angle_abs < 120;
mstable.foll_sees_lead_angle_bin = mstable.foll_sees_lead_angle_abs < 120;

%% get beta coefficients of all pairs combined

% which_mouse = 'both'; % Fig. 3i
% which_mouse = 'lead'; % Fig. 3m
which_mouse = 'foll'; % Fig. 3q

switch which_mouse

    case 'both'
        sel = mstable.cno_lead == mstable.cno_foll;
        caption = 'Impact of inactivation in both animals on sensitivity';
        cno_term = 'cno_lead';
        ylims = [-1.8 1.9];

    case 'lead'
        sel = (mstable.cno_lead==0 & mstable.cno_foll==0) | ...
              (mstable.cno_lead==1 & mstable.cno_foll==0);
        caption = 'Impact of inactivation in leader on sensitivity';
        cno_term = 'cno_lead';
        ylims = [-2.2 1.6];

    case 'foll'
        sel = (mstable.cno_lead==0 & mstable.cno_foll==0) | ...
              (mstable.cno_lead==0 & mstable.cno_foll==1);
        caption = 'Impact of inactivation in follower on sensitivity';
        cno_term = 'cno_foll';
        ylims = [-2.2 2.6];

end

mstable_sel = mstable(sel,:);

roles = {'lead','foll'};

beta_estimate = nan(2,4);
se_estimate = nan(2,4);
p_estimate = nan(2,4);

stats_table = table();

for r = 1:2

    cur_role = roles{r};
    which_choose_n = [cur_role '_choose_n'];

    modelspec = [which_choose_n ...
        ' ~ (lead_angle_rz_dif + lead_dis_dif + foll_angle_rz_dif + foll_dis_dif) * ' ...
        cno_term];

    mdl = fitglm(mstable_sel,modelspec,Distribution="Binomial");

    fprintf('\n====================================\n')
    fprintf('%s choice model | %s inactivation\n',cur_role,which_mouse)
    fprintf('====================================\n')
    disp(mdl.Coefficients)

    beta_estimate(r,:) = mdl.Coefficients.Estimate(7:10);
    se_estimate(r,:) = mdl.Coefficients.SE(7:10);
    p_estimate(r,:) = mdl.Coefficients.pValue(7:10);

    coef_names = mdl.CoefficientNames';

    T_stats = table( ...
        repmat({which_mouse},length(coef_names),1), ...
        repmat({cur_role},length(coef_names),1), ...
        coef_names, ...
        mdl.Coefficients.Estimate, ...
        mdl.Coefficients.SE, ...
        mdl.Coefficients.tStat, ...
        mdl.Coefficients.pValue, ...
        'VariableNames', ...
        {'WhichMouse','ChoiceRole','Coefficient', ...
        'Estimate','SE','TStat','PValue'});

    stats_table = [stats_table; T_stats];

end

%% source data for bar plot

predictor_names = {'lead_angle_rz_dif'; ...
                   'lead_dis_dif'; ...
                   'foll_angle_rz_dif'; ...
                   'foll_dis_dif'};

role_names = {'Leader';'Follower'};

source_data = table();

for r = 1:2
    for i = 1:4

        T_source = table( ...
            {which_mouse}, ...
            role_names(r), ...
            predictor_names(i), ...
            beta_estimate(r,i), ...
            se_estimate(r,i), ...
            p_estimate(r,i), ...
            'VariableNames', ...
            {'WhichMouse','ChoiceRole','Predictor', ...
            'BetaEstimate','SE','PValue'});

        source_data = [source_data; T_source];

    end
end

assignin('base','source_data',source_data);
assignin('base','stats_table',stats_table);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

%% paired bar plot

m_colors = [194, 165, 207; 166, 219, 160] / 255;

fig = figure('Position',[600 300 300 400]);
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

ylabel('Beta coefficient (log-likelihood)');

legend(b,{'Leader','Follower'},'Location','south');
legend box off

box off

ax = gca;
set(ax,'FontSize',24,'TickDir','out');

hoy = char(datetime('now','Format','yyyyMMdd'));

figname = [fd 'plots/' hoy '_beta_all_pairs_cno_' which_mouse];

title(caption,'FontSize',24)

print(fig,figname,'-dpdf');

end