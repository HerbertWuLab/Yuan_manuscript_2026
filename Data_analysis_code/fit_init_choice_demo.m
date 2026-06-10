function fit_init_choice_v2(fd,ctable)
% calculate and plot the beta coefficients from the glm fit of the psych curves, 
% for well-trained phase, only using phase 4a and cp_rate>=0.75 sessions
% (to include more trials for the leader)

%% get the glm and beta coefficients
uni_pairs = unique(ctable.pair);
n_uni_pairs = length(uni_pairs);
threshold = 1; % threshold for calling a consistent leader in a cohort
% condition_grps = {'in_north'}; 
condition_grps = {'in_east','in_south','in_west','in_north'}; 
% condition_grps = {'in_east','in_south','in_west','in_north','face_ez','face_sz','face_wz','face_nz'}; 

% condition_grps = {'face_east','face_south','face_west','face_north'}; 
% condition_grps = {'in_east','in_south','in_west','in_north','face_east','face_south','face_west','face_north'}; 
% n_conditions = length(condition_grps);
% mdls_lead = cell(n_uni_pairs,n_conditions); 
% mdls_foll = cell(n_uni_pairs,n_conditions);

mstable = [];
stable_cbd = [];
for p = 1:n_uni_pairs
% for p = 10
    cur_pair = uni_pairs{p};
    % get the phase 2b baseline data
    file_phase2b = fullfile(fd, 'Data', 'phase2b', [cur_pair '_batch_table_phase2b.mat']);

    if ~isfile(file_phase2b)
        fprintf('Phase 2b file not found for %s. Skip\n', cur_pair);
        continue;
    end

    btable_phase2b = load(file_phase2b).btable_phase2b;
    % rotate phase 2b data into trial type 1 or 5 config
    btable_phase2b = rotate_coords_phase2b(btable_phase2b);
    % get phase 2b psych table
    btable_phase2b = get_psych_table_phase2b(btable_phase2b);

    % process the ctable
    cur_ctable = ctable(strcmp(cur_pair,ctable.pair),:);

    if strcmp(cur_pair,'YC017YC018') % only use sessions before extended phase4b+cno sessions
        cur_ctable = cur_ctable(str2double(cur_ctable.date)<=20231017,:);
    end

    % filter the sessions and get well-trained phase data
    % have to relax the criterion to 0.75 cooperation rate to include more trials
    s_range = cur_ctable.cno==0 & cur_ctable.cp_rate>=0.75 & strcmp(cur_ctable.phase,'phase4a');
    btable = cur_ctable(s_range,:); % well-trained

    % % filter the sessions and get early learning phase data
    % btable = extract_ltable(cur_ctable);
    % btable = btable(btable.cp_rate<0.65,:);

    % rotate phase 4a data into trial type 1 or 5 config
    % cur_ctable = rotate_coords(cur_ctable);
    % btable = rotate_coords_v5(btable);

    % get phase 4a psych table
    % btable = get_psych_table(btable);
    % btable = get_psych_table_v2(btable); % responder zone defined with dis to zone center
    btable = get_psych_table_v3(btable); % responder heading defined as angle from zone center instead of cardinal directions

    % determine which mouse is the consistent leader across sessions
    s_range = cur_ctable.cno==0 & cur_ctable.cp_rate>=0.8 & strcmpi(cur_ctable.phase,'phase4a');
    btable_wt = cur_ctable(s_range,:); % well-trained
    n_ses = height(btable_wt);
    n_ledBy_m1 = sum(strcmp(btable_wt.sLead,'m1'));
    n_ledBy_m2 = sum(strcmp(btable_wt.sLead,'m2'));
    if n_ledBy_m1 >= n_ses * threshold
        pLead = 1; pFoll = 2;
    elseif n_ledBy_m2 >= n_ses * threshold
        pLead = 2; pFoll = 1;
    else
        fprintf(['No mouse leads more than prop=%.2f of well-trained, phase4a,'...
            ' control sessions in ' cur_pair '. Check data!\n'],threshold)
        continue; % skip the rest of the current iter and go to the next iter
    end
    p_lead_foll = [pLead pFoll];
    animals = {btable{1,'m1'};btable{1,'m2'}}; % get the animal names
    
    % get the all stable combined for fit with phase 2b
    cur_stable = get_allstable_for_fit(btable,btable_phase2b, animals, p_lead_foll); % include phase 2b
    stable_cbd = [stable_cbd; vertcat(btable.stable{:})];
    mstable = [mstable;cur_stable];
end
mstable_all = mstable;
mstable_all.angle_east = mstable_all.angle_east/180;
mstable_all.angle_north = mstable_all.angle_north/180;
% mstable_all.angle_dif = (mstable_all.angle_dif+90)/180;

%% simple logistic model with angle difference
cur_role = 'pLead';
cond = 4; % in which zone
rspd_cond = condition_grps{cond};
% must remove trials where animals are in other conditions
sel_role = strcmp(mstable.role,cur_role);
sel_cond = strcmp(mstable.phase,'phase2b') | (strcmp(mstable.phase,'phase4a') & mstable.(rspd_cond)==1);
cur_mstable = mstable(sel_role & sel_cond,:);
modelspec = ['init_choose_n ~ angle_dif*' rspd_cond];
mdl = fitglm(cur_mstable,modelspec,Distribution="Binomial");
disp(mdl)

% sel_phase = strcmp(allstable.phase,'phase2b');
% allstable_2b = allstable(sel_role & sel_phase,:);
% modelspec = ['init_choose_n ~ angle_dif'];
% mdl = fitglm(allstable_2b,modelspec,Distribution="Binomial");
% disp(mdl)

%% plot fitting for every pair
% conditions = {'in_east','in_south','in_west','in_north'}; cond_label = 'in';
conditions = {'face_ez','face_sz','face_wz','face_nz'}; cond_label = 'face';
n_cond = length(conditions);
cur_role = 'pFoll';
% sel_role = strcmp(mstable.role,cur_role);
if strcmp(cur_role,'pLead')
    m_colors = {'#e7d4e8';'#c2a5cf';'#9970ab';'#762a83'}; % leader
elseif strcmp(cur_role,'pFoll')
    m_colors = {'#d9f0d3';'#a6dba0';'#5aae61';'#1b7837'}; % follower
end

% plot single pair if needed
uni_pairs_sel = unique(mstable_all.pair);
n_pairs = length(uni_pairs_sel);

% for p = 1:n_pairs
for p = 5
    cur_pair = uni_pairs_sel{p};
    % cur_pair = 'YC043YC044';
    sel_pair = strcmp(cur_pair,mstable_all.pair);
    mstable = mstable_all(sel_pair,:);
    
    angle_array = (0:1:360)';
    length_array = length(angle_array);
    stable_sim = table(angle_array,'VariableNames',{'init_hd_sim'});
    angle_east = angle_array;
    angle_east(angle_east>180) = angle_east(angle_east>180) - 360;
    stable_sim.angle_east = abs(angle_east);
    angle_north = angle_array - 90;
    angle_north(angle_array>270) = angle_north(angle_array>270) - 360;
    stable_sim.angle_north = abs(angle_north);
    % stable_sim.angle_dif = stable_sim.angle_east - stable_sim.angle_north;
    
    fig = figure('Position',[600 300 800 600],'Visible','on'); 
    hold on;
    pl = [];
    Ps_north = nan(8,n_cond);
    sel_role = strcmp(mstable.role,cur_role);
    
    % plot fitting of phase 2b
    rspd_cond = conditions{1}; % same for any condition
    sel_cond = strcmp(mstable.phase,'phase2b') | (strcmp(mstable.phase,'phase4a') & mstable.(rspd_cond)==1);
    cur_mstable = mstable(sel_role & sel_cond,:);
    
    % modelspec = ['init_choose_n ~ angle_dif*' rspd_cond];
    modelspec = ['init_choose_n ~ (angle_east + angle_north)*' rspd_cond];
    mdl = fitglm(cur_mstable,modelspec,'Distribution','binomial');
    
    stable_sim.(rspd_cond) = zeros(length_array,1);
    stable_sim.p_north = predict(mdl, stable_sim);
    pl(1) = plot(angle_array,stable_sim.p_north,...
        'Color','k','LineStyle','-','LineWidth',2);
    % plot real data
    sel_phase2b = strcmp(cur_mstable.phase,'phase2b');
    stable_phase2b = cur_mstable(sel_phase2b,:);
    n_trials = nan(8,1);
    p_north = nan(8,1);
    % n_bins = 8;
    % hd_bin_width = 360/n_bins;
    % angles = [0 45 90 135 180 225 270 315 360];
    % allstable_phase2b.init_hd_bin_rot = floor(allstable_phase2b.init_hd_rot/hd_bin_width) + 1; % make it into 8bins, 1st bin center on 22.5
    % allstable_phase2b.init_hd_bin_rot(allstable_phase2b.init_hd_bin_rot==9) = 1;
    for b = 1:8 % 8 bins
        cur_sel = stable_phase2b.init_hd_bin_rot == b;
        n_trials(b) = sum(cur_sel); % number of current trials
        p_north(b) = mean(stable_phase2b.init_choose_n(cur_sel));
        % north_choices(b) = sum(mstable.init_choose_n(cur_sel),"omit");
    end
    % pl(i) = plot(0:45:360,[p_north; p_north(1)],'Color',m_colors{j+1});
    scatter(0:45:360,[p_north; p_north(1)],60,...
        'MarkerFaceColor','k','MarkerEdgeColor','none','MarkerFaceAlpha',1);
    % text(angles,[p_north; p_north(1)],string([n_trials; n_trials(1)]),'FontSize',14)
    
    for cond = 1:n_cond
    % for cond = 1
        rspd_cond = conditions{cond};
        % must remove phase 4a trials where animals are in other conditions
        sel_cond = strcmp(mstable.phase,'phase2b') | (strcmp(mstable.phase,'phase4a') & mstable.(rspd_cond)==1);
        cur_mstable = mstable(sel_role & sel_cond,:);
    
        modelspec = ['init_choose_n ~ (angle_east + angle_north)*' rspd_cond];
        mdl = fitglm(cur_mstable,modelspec,'Distribution','binomial');
    
        % plot each of the responder conditions
        stable_sim.(rspd_cond) = ones(length_array,1);
        stable_sim.p_north = predict(mdl, stable_sim);
        pl(cond+1) = plot(angle_array,stable_sim.p_north,...
            'Color',m_colors{cond},'LineStyle','-','LineWidth',2);
        % calculate and plot the real data
        sel_phase4a = strcmp(cur_mstable.phase,'phase4a');
        stable_phase4 = cur_mstable(sel_phase4a,:);
        n_trials = nan(8,1);
        p_north = nan(8,1);
        % n_bins = 8;
        % hd_bin_width = 360/n_bins;
        % angles = [0 45 90 135 180 225 270 315 360];
        % allstable_phase4.init_hd_bin_rot = floor(allstable_phase4.init_hd_rot/hd_bin_width+0.5) + 1; % make it into 8bins, 1st bin center on 0
        % allstable_phase4.init_hd_bin_rot(allstable_phase4.init_hd_bin_rot==9) = 1;
        for b = 1:8 % 8 bins
            cur_sel = stable_phase4.init_hd_bin_rot == b;
            n_trials(b) = sum(cur_sel); % number of current trials
            p_north(b) = mean(stable_phase4.init_choose_n(cur_sel));
            % north_choices(b) = sum(mstable.init_choose_n(cur_sel),"omit");
        end
        Ps_north(:,cond) = p_north;
        % pl(i) = plot(0:45:360,[p_north; p_north(1)],'Color',m_colors{j+1});
        % plot(22.5:45:360,p_north,'LineStyle','none','Marker','.','MarkerSize',30,...
        %     'MarkerEdgeColor',);
        scatter(0:45:360,[p_north; p_north(1)],60,...
            'MarkerFaceColor',m_colors{cond},'MarkerEdgeColor','none','MarkerFaceAlpha',1);
        % text(angles,[p_north; p_north(1)],string([n_trials; n_trials(1)]),'FontSize',14)
    end
    % angles = 0:45:360;
    xticks(0:45:360)
    % xticklabels(angles);
    % xlim([-10 370])
    xlim([0 360])
    ylim([0 1])
    xlabel('Initiating HD')
    ylabel('Prob choosing north');
    % oc_caption = strrep(other_condition,'_',' ');
    title([cur_pair ' ' cur_role ' respder ' cond_label ' zone'])
    conditions_lgd = cellfun(@(x) strrep(x, '_', ' '), conditions, 'UniformOutput', false);
    conditions_lgd = cellfun(@(x) ['Responder ' x], conditions_lgd, 'UniformOutput', false);
    legend(pl,['Solo',conditions_lgd],'location','south')
    legend boxoff
    box off
    set(gca,'FontSize',24,'TickDir','out')
    hoy = char(datetime('now','Format','yyyyMMdd'));
    % figname = [fd 'plots/' hoy '_psych_curves_well-trained_all_pairs_' cur_role '_rspd_faceZone'];
    figname = [fd 'plots/' hoy '_psych_curves_well-trained_' cur_pair '_' cur_role '_rspd_' cond_label '_zone'];
    set(fig,'PaperOrientation','landscape','PaperUnits','normalized','PaperPosition', [0 0 1 1]);
    print(fig,figname,'-dpdf');
end


%% plot fitting for all pairs combined
conditions = {'in_east','in_south','in_west','in_north'}; cond_label = 'in';
% conditions = {'face_ez','face_sz','face_wz','face_nz'}; cond_label = 'face';
conditions_lgd = {'E','S','W','N'};
n_cond = length(conditions);

cur_role = 'pLead';
% cur_role = 'pFoll';
sel_role = strcmp(mstable.role,cur_role);

if strcmp(cur_role,'pLead')
    m_colors = {'#e7d4e8';'#c2a5cf';'#9970ab';'#762a83'}; % leader
elseif strcmp(cur_role,'pFoll')
    m_colors = {'#d9f0d3';'#a6dba0';'#5aae61';'#1b7837'}; % follower
end

% plot single pair if needed
uni_pairs_sel = unique(mstable_all.pair);
n_pairs = length(uni_pairs_sel);

mstable = mstable_all;

angle_array = (0:1:360)';
length_array = length(angle_array);

stable_sim = table(angle_array,'VariableNames',{'init_hd_sim'});

angle_east = angle_array;
angle_east(angle_east>180) = angle_east(angle_east>180) - 360;
stable_sim.angle_east = abs(angle_east);

angle_north = angle_array - 90;
angle_north(angle_array>270) = angle_north(angle_array>270) - 360;
stable_sim.angle_north = abs(angle_north);

% stable_sim.angle_dif = stable_sim.angle_east - stable_sim.angle_north;
stable_sim.angle_east = stable_sim.angle_east/180;
stable_sim.angle_north = stable_sim.angle_north/180;

source_data = table();

fig = figure('Position',[600 300 300 300],'Visible','on'); 
hold on;

pl = [];
Ps_north = nan(8,n_cond);
sel_role = strcmp(mstable.role,cur_role);

% plot fitting of phase 2b
rspd_cond = conditions{1}; % same for any condition
sel_cond = strcmp(mstable.phase,'phase2b') | ...
    (strcmp(mstable.phase,'phase4a') & mstable.(rspd_cond)==1);

cur_mstable = mstable(sel_role & sel_cond,:);

% modelspec = ['init_choose_n ~ angle_dif*' rspd_cond];
modelspec = ['init_choose_n ~ (angle_east + angle_north)*' rspd_cond];

mdl = fitglm(cur_mstable,modelspec,'Distribution','binomial');

stable_sim.(rspd_cond) = zeros(length_array,1);
stable_sim.p_north = predict(mdl, stable_sim);

pl(1) = plot(angle_array,stable_sim.p_north,...
    'Color','k','LineStyle','-','LineWidth',2);

tmp_pred = table();
tmp_pred.Role = repmat(string(cur_role),length_array,1);
tmp_pred.Phase = repmat("phase2b_model",length_array,1);
tmp_pred.Condition = repmat("Solo",length_array,1);
tmp_pred.ConditionVariable = repmat(string(rspd_cond),length_array,1);
tmp_pred.DataType = repmat("ModelPrediction",length_array,1);
tmp_pred.AngleDeg = angle_array;
tmp_pred.PredictedPNorth = stable_sim.p_north;
tmp_pred.PObservedNorth = nan(length_array,1);
tmp_pred.NTrials = nan(length_array,1);

source_data = [source_data; tmp_pred];

% plot observed phase 2b data
sel_phase2b = strcmp(cur_mstable.phase,'phase2b');
stable_phase2b = cur_mstable(sel_phase2b,:);

n_trials = nan(8,1);
p_north = nan(8,1);

for b = 1:8 % 8 bins
    cur_sel = stable_phase2b.init_hd_bin_rot == b;
    n_trials(b) = sum(cur_sel); % number of current trials
    p_north(b) = mean(stable_phase2b.init_choose_n(cur_sel));
    % north_choices(b) = sum(mstable.init_choose_n(cur_sel),"omit");
end

% pl(i) = plot(0:45:360,[p_north; p_north(1)],'Color',m_colors{j+1});
% scatter(0:45:360,[p_north; p_north(1)],60,'MarkerFaceColor','k','MarkerEdgeColor','none','MarkerFaceAlpha',1);
fill_color = [0.6,0.6,0.6];

scatter(0:45:360,[p_north; p_north(1)],80,...
    'MarkerFaceColor',fill_color,...
    'MarkerEdgeColor','k',...
    'LineWidth',0.1,...
    'MarkerFaceAlpha',1);

% text(angles,[p_north; p_north(1)],string([n_trials; n_trials(1)]),'FontSize',14)

tmp_obs = table();
tmp_obs.Role = repmat(string(cur_role),9,1);
tmp_obs.Phase = repmat("phase2b",9,1);
tmp_obs.Condition = repmat("Solo",9,1);
tmp_obs.ConditionVariable = repmat(string(rspd_cond),9,1);
tmp_obs.DataType = repmat("ObservedData",9,1);
tmp_obs.AngleDeg = (0:45:360)';
tmp_obs.PredictedPNorth = nan(9,1);
tmp_obs.PObservedNorth = [p_north; p_north(1)];
tmp_obs.NTrials = [n_trials; n_trials(1)];

source_data = [source_data; tmp_obs];

n_total_trials = nan(n_cond,1);

% plot phase 4a data
for cond = 1:n_cond
% for cond = 1

    rspd_cond = conditions{cond};

    % must remove phase 4a trials where animals are in other conditions
    sel_cond = strcmp(mstable.phase,'phase2b') | ...
        (strcmp(mstable.phase,'phase4a') & mstable.(rspd_cond)==1);

    cur_mstable = mstable(sel_role & sel_cond,:);

    modelspec = ['init_choose_n ~ (angle_east + angle_north)*' rspd_cond];

    mdl = fitglm(cur_mstable,modelspec,'Distribution','binomial');

    disp(mdl)

    n_total_trials(cond) = height(cur_mstable);

    % plot each of the responder conditions
    stable_sim.(rspd_cond) = ones(length_array,1);
    stable_sim.p_north = predict(mdl, stable_sim);

    pl(cond+1) = plot(angle_array,stable_sim.p_north,...
        'Color',m_colors{cond},...
        'LineStyle','-',...
        'LineWidth',2);

    tmp_pred = table();
    tmp_pred.Role = repmat(string(cur_role),length_array,1);
    tmp_pred.Phase = repmat("phase4a_model",length_array,1);
    tmp_pred.Condition = repmat(string(conditions_lgd{cond}),length_array,1);
    tmp_pred.ConditionVariable = repmat(string(rspd_cond),length_array,1);
    tmp_pred.DataType = repmat("ModelPrediction",length_array,1);
    tmp_pred.AngleDeg = angle_array;
    tmp_pred.PredictedPNorth = stable_sim.p_north;
    tmp_pred.PObservedNorth = nan(length_array,1);
    tmp_pred.NTrials = nan(length_array,1);

    source_data = [source_data; tmp_pred];

    % calculate and plot the observed data
    sel_phase4a = strcmp(cur_mstable.phase,'phase4a');
    stable_phase4 = cur_mstable(sel_phase4a,:);

    n_trials = nan(8,1);
    p_north = nan(8,1);

    for b = 1:8 % 8 bins
        cur_sel = stable_phase4.init_hd_bin_rot == b;
        n_trials(b) = sum(cur_sel); % number of current trials
        p_north(b) = mean(stable_phase4.init_choose_n(cur_sel));
        % north_choices(b) = sum(mstable.init_choose_n(cur_sel),"omit");
    end

    Ps_north(:,cond) = p_north;

    % pl(i) = plot(0:45:360,[p_north; p_north(1)],'Color',m_colors{j+1});
    % plot(22.5:45:360,p_north,'LineStyle','none','Marker','.','MarkerSize',30,...
    %     'MarkerEdgeColor',);
    % scatter(0:45:360,[p_north; p_north(1)],60,'MarkerFaceColor',m_colors{cond},'MarkerEdgeColor','none','MarkerFaceAlpha',1);
    scatter(0:45:360,[p_north; p_north(1)],80,...
        'MarkerFaceColor',m_colors{cond},...
        'MarkerEdgeColor','k',...
        'LineWidth',0.1,...
        'MarkerFaceAlpha',0.5);

    % text(0:45:360,[p_north; p_north(1)],string([n_trials; n_trials(1)]),'FontSize',14)

    tmp_obs = table();
    tmp_obs.Role = repmat(string(cur_role),9,1);
    tmp_obs.Phase = repmat("phase4a",9,1);
    tmp_obs.Condition = repmat(string(conditions_lgd{cond}),9,1);
    tmp_obs.ConditionVariable = repmat(string(rspd_cond),9,1);
    tmp_obs.DataType = repmat("ObservedData",9,1);
    tmp_obs.AngleDeg = (0:45:360)';
    tmp_obs.PredictedPNorth = nan(9,1);
    tmp_obs.PObservedNorth = [p_north; p_north(1)];
    tmp_obs.NTrials = [n_trials; n_trials(1)];

    source_data = [source_data; tmp_obs];

end

assignin('base','source_data',source_data);

xticks(0:90:360)

% xticklabels(angles);
xlim([-10 370])
% xlim([0 360])

ylim([0 1])

xlabel('HD at trial onset')
ylabel('P(north)');

title(['All pairs ' cur_role ' respder ' cond_label ' zone'])

% conditions_lgd = cellfun(@(x) strrep(x, '_', ' '), conditions, 'UniformOutput', false);
% conditions_lgd = cellfun(@(x) ['Rspdr ' x], conditions_lgd, 'UniformOutput', false);
% conditions_lgd = {'East','South','West','North'};
% conditions_lgd = {'E','S','W','N'};

legend(pl,['Solo', conditions_lgd],'location','south')
legend boxoff

box off

set(gca,'FontSize',20,'TickDir','out')

hoy = char(datetime('now','Format','yyyyMMdd'));

figname = [fd 'plots/' hoy '_psych_curves_well-trained_all_pairs_' ...
    cur_role '_rspd_' cond_label '_zone'];

% set(fig,'PaperOrientation','landscape','PaperUnits','normalized','PaperPosition', [0 0 1 1]);

print(fig,figname,'-dpdf');

%% plot impact on sensitivity vs bias, separate leader and follower
% for the old scatter plot
% get coefficients of every animal
uni_pairs = unique(mstable.pair);
n_uni_pairs = length(uni_pairs);
cond = 1; % in which zone
rspd_cond = condition_grps{cond};
% must remove trials when animals are in all the other conditions
sel_cond = strcmp(mstable.phase,'phase2b') | (strcmp(mstable.phase,'phase4a') & mstable.(rspd_cond)==1);
roles = {'pLead','pFoll'};
est_bias = nan(n_uni_pairs,2);
est_sensitivity = nan(n_uni_pairs,2);
bias_SE = nan(n_uni_pairs,2);
sensi_SE = nan(n_uni_pairs,2);
for r = 1:2
    cur_role = roles{r};
    sel_role = strcmp(mstable.role,cur_role);
    cur_mstable = mstable(sel_role & sel_cond,:);
    for p = 1:n_uni_pairs
        cur_pair = uni_pairs{p};
        sel_pair = strcmp(cur_pair,cur_mstable.pair);
        cur_stable_pair = cur_mstable(sel_pair,:);
        modelspec = ['init_choose_n ~ angle_dif*' rspd_cond];
        mdl = fitglm(cur_stable_pair,modelspec,Distribution="Binomial");
        est_bias(p,r) = mdl.Coefficients.Estimate(2);
        est_sensitivity(p,r) = mdl.Coefficients.Estimate(4);
        bias_SE(p,r) = mdl.Coefficients.SE(2);
        sensi_SE(p,r) = mdl.Coefficients.SE(4);
    end
end

% plot
m_colors = {'#c2a5cf','#a6dba0','#969696'}; % leader vs follower 
fig = figure('Position',[600 300 600 600]);
hold on;
hdl = [];
for r = 1:2
    x = est_bias(:,r); % bias by the other animal
    y = est_sensitivity(:,r); % impairment on sensitivity by the other animal
    x_se = bias_SE(:,r);
    y_se = sensi_SE(:,r);
    sel = x_se<30 & y_se<30;
    x = x(sel); y = y(sel); x_se = x_se(sel); y_se = y_se(sel);
    h = errorbar(x,y,x_se,'o','horizontal',"MarkerSize",10,'color',m_colors{r},...
        'LineWidth',2,"MarkerEdgeColor","k","MarkerFaceColor",m_colors{r},'CapSize',0);
    hdl = [hdl h];
    errorbar(x,y,y_se,'o',"MarkerSize",10,'color',m_colors{r},...
        'LineWidth',2,"MarkerEdgeColor","k","MarkerFaceColor",m_colors{r},'CapSize',0);
end
xline(0,'k:')
yline(0,'k:')
legend(hdl,{'leader';'follower'},'Location','northeast')
legend box off
xlabel('Bias induced by the responder (log-odds)')
ylabel('Impairment on sensitivity by the responder (log-odds/rad)')
% title('Impact on sensitivity by the other mouse in north zone/learning')
caption = ['Impact on initiator choice by the responder ' rspd_cond ];
caption = strrep(caption,'_', ' ');
title(caption);
set(gca,'FontSize',24,'TickDir','out')
xlim([-2 3]); ylim([-3 4]); legend('Location','northeast'); % other in north
% xlim([-1.8 3]); ylim([-3 2]); legend('Location','northwest'); % other face north

hoy = char(datetime('now','Format','yyyyMMdd'));
% figname = [fd 'plots/' hoy '_sensitivity_psy_curve_logistic_coef_learning_all_pairs'];
figname = [fd 'plots/' hoy '_impact_by_responder_' rspd_cond '_every_pair'];
set(fig,'PaperOrientation','landscape','PaperUnits','normalized','PaperPosition', [0 0 1 1]);
print(fig,figname,'-dpdf');

[h,p] = ttest(est_bias(:,1),est_bias(:,2));
fprintf('paired t-test of bias of leader and follower has a p=%.2g\n',p)
[h,p] = ttest(est_sensitivity(:,1),est_sensitivity(:,2));
fprintf('paired t-test of impairment on sensitivity of leader and follower has a p=%.2g\n',p)

%% plot impact on sensitivity vs bias, separate leader and follower
% for the new bar plots
% get coefficients of every animal
% conditions = {'in_east','in_south','in_west','in_north'}; cond_label = 'in';
conditions = {'face_ez','face_sz','face_wz','face_nz'}; cond_label = 'face';
% conditions = {'in_east','in_south','in_west','in_north','face_ez','face_sz','face_wz','face_nz'}; 
n_cond = length(conditions);
uni_pairs = unique(mstable.pair);
n_uni_pairs = length(uni_pairs);
est_bias = nan(n_uni_pairs,2,n_cond);
est_sensitivity = nan(n_uni_pairs,2,n_cond);
% bias_SE = nan(n_uni_pairs,2,n_cond);
% sensi_SE = nan(n_uni_pairs,2,n_cond);
for cond = 1:n_cond
    % cond = 1; % in which zone
    rspd_cond = conditions{cond};
    % must remove trials when animals are in all the other conditions
    sel_cond = strcmp(mstable.phase,'phase2b') | (strcmp(mstable.phase,'phase4a') & mstable.(rspd_cond)==1);
    roles = {'pLead','pFoll'};
    for r = 1:2
        cur_role = roles{r};
        sel_role = strcmp(mstable.role,cur_role);
        cur_mstable = mstable(sel_role & sel_cond,:);
        for p = 2:n_uni_pairs
        % for p = 1
            cur_pair = uni_pairs{p};
            sel_pair = strcmp(cur_pair,cur_mstable.pair);
            cur_stable_pair = cur_mstable(sel_pair,:);
            modelspec = ['init_choose_n ~ angle_dif*' rspd_cond];
            mdl = fitglm(cur_stable_pair,modelspec,Distribution="Binomial");
            est_bias(p,r,cond) = mdl.Coefficients.Estimate(2);
            est_sensitivity(p,r,cond) = mdl.Coefficients.Estimate(4);
            % bias_SE(p,r,cond) = mdl.Coefficients.SE(2);
            % sensi_SE(p,r,cond) = mdl.Coefficients.SE(4);
        end
    end
end
%% estimates of the all pairs combined
condition_grps = {'face_ez','face_sz','face_wz','face_nz'}; 
% condition_grps = {'in_east','in_south','in_west','in_north'}; 

n_cond = length(condition_grps);
mstable = mstable_all;
est_bias_all = nan(2,n_cond);
est_sensitivity_all = nan(2,n_cond);
p_bias_all = nan(2,n_cond);
p_sensitivity_all = nan(2,n_cond);
se_bias_all = nan(2,n_cond);
se_sensitivity_all = nan(2,n_cond);
for cond = 1:n_cond % in which zone
% for cond = 3
    rspd_cond = condition_grps{cond};
    % must remove trials when animals are in all the other conditions
    sel_cond = strcmp(mstable.phase,'phase2b') | (strcmp(mstable.phase,'phase4a') & mstable.(rspd_cond)==1);
    roles = {'pLead','pFoll'};
    for r = 1:2
        cur_role = roles{r};
        sel_role = strcmp(mstable.role,cur_role);
        cur_mstable = mstable(sel_role & sel_cond,:);
        % if r==1
        %     if ismember(cond, [1 3 4 5 6 7 8])
        %         sel_pair = ~ismember(cur_mstable.pair,{'YC017YC018'});
        %     elseif cond==2
        %         sel_pair = ~ismember(cur_mstable.pair,{'YC017YC018','YC021YC022'});
        %     end
        %     cur_mstable = cur_mstable(sel_pair,:);   
        % else
        %     if cond==3
        % 
        % end
        % modelspec1 = ['init_choose_n ~ angle_dif*' rspd_cond ' + (angle_dif*' rspd_cond '|pair)'];
        % glme1 = fitglme(cur_mstable,modelspec1,Distribution="Binomial");
        % modelspec = ['init_choose_n ~ angle_dif*' rspd_cond ' + (1|pair) + (angle_dif-1|pair) + (' rspd_cond '-1|pair) + (angle_dif:' rspd_cond '-1|pair)'];
        modelspec = ['init_choose_n ~ angle_dif*' rspd_cond ' + (1|pair) + (angle_dif-1|pair)'];
        glme = fitglme(cur_mstable,modelspec,Distribution="Binomial");
        disp(glme)
        % modelspec3 = ['init_choose_n ~ angle_dif*' rspd_cond ' + (1|pair) + (angle_dif-1|pair)'];
        % glme3 = fitglme(cur_mstable,modelspec3,Distribution="Binomial");
        % modelspec4 = ['init_choose_n ~ angle_dif*' rspd_cond ' + (' rspd_cond '-1|pair) + (angle_dif:' rspd_cond '-1|pair)'];
        % glme4 = fitglme(cur_mstable,modelspec4,Distribution="Binomial");
        % modelspec5 = ['init_choose_n ~ angle_dif*' rspd_cond ' + (' rspd_cond '-1|pair)'];
        % glme5 = fitglme(cur_mstable,modelspec5,Distribution="Binomial");
        est_bias_all(r,cond) = glme.Coefficients.Estimate(2);
        est_sensitivity_all(r,cond) = glme.Coefficients.Estimate(4); 
        se_bias_all(r,cond) = glme.Coefficients.SE(2);
        se_sensitivity_all(r,cond) = glme.Coefficients.SE(4);  
        p_bias_all(r,cond) = glme.Coefficients.pValue(2);
        p_sensitivity_all(r,cond) = glme.Coefficients.pValue(4); 
    end
end
%% paired bar plot. use mixed-effects glm beta estimates and SE from the population
% m_colors = {'#c2a5cf','#a6dba0','#969696'}; % leader vs follower 
m_colors = [194, 165, 207; 166, 219, 160] / 255;
% pvals = nan(n_cond,3);
fig = figure('Position',[600 300 250 400]);
hold on;
x = (1:n_cond);
which_term = 'sensitivity';
switch which_term
    case 'bias'
        % estimate = est_bias; % for single animals
        estimate_all = est_bias_all; 
        se_all = se_bias_all; p_all = p_bias_all;
        % ylims = [-1.8 2.1]; % for 8 groups
        % ylims = [-0.6 1.2]; y_ticks = -0.5:0.5:1; % for face groups
        ylims = [-2.3 2.1]; y_ticks = -2:2; % for in groups
        y_label = 'Bias (log odds)';
    case 'sensitivity'
        % estimate = est_sensitivity; % for single animals
        estimate_all = est_sensitivity_all; 
        se_all = se_sensitivity_all; p_all = p_sensitivity_all;
        ylims = [-0.035 0.005];
        y_ticks = -0.03:0.01:0;
        y_label = 'Log odds/degree';
end
% estimate = estimate(~isnan(estimate(:,1,1)),:,:); % for single animals
b = bar(x,estimate_all,'FaceColor','flat','EdgeColor','none','GroupWidth',0.8); 
b(1).FaceColor = m_colors(1,:);
b(2).FaceColor = m_colors(2,:);
for cond = 1:n_cond
    % y = estimate(:,:,cond); % for single animals
    % h = plot([b(1).XEndPoints(cond) b(2).XEndPoints(cond)], y','LineWidth',1,'Color',0.4*[1 1 1],...
    %     'Marker','.','MarkerSize',10);
    for r = 1:2
        if estimate_all(r,cond) > 0
            errorbar(b(r).XEndPoints(cond),estimate_all(r,cond),[],se_all(r,cond),'Color',m_colors(r,:),'LineWidth',2);
        else
            errorbar(b(r).XEndPoints(cond),estimate_all(r,cond),se_all(r,cond),[],'Color',m_colors(r,:),'LineWidth',2);
        end
        if p_all(r,cond) < 0.001
            text(b(r).XEndPoints(cond),0.95*ylims(2),'***','HorizontalAlignment','center',...
                'VerticalAlignment','middle','Rotation',90,'Units','data','FontSize',18) 
        elseif p_all(r,cond) < 0.01
            text(b(r).XEndPoints(cond),0.95*ylims(2),'**','HorizontalAlignment','center',...
                'Rotation',90,'Units','data','FontSize',18) 
        elseif p_all(r,cond) < 0.05
            text(b(r).XEndPoints(cond),0.95*ylims(2),'*','HorizontalAlignment','center',...
                'Rotation',90,'Units','data','FontSize',18) 
        end
    end   
    % text(b(1).XEndPoints(cond),0.9*ymax,sprintf('P=%.2g', p_all(1,cond)),'HorizontalAlignment','center',...
    %     'Rotation',90,'Units','data','FontSize',14)
    % text(b(2).XEndPoints(cond),0.9*ymax,sprintf('P=%.2g', p_all(2,cond)),'HorizontalAlignment','center',...
    %     'Rotation',90,'Units','data','FontSize',14)
end
xlim([0.5 n_cond+0.5])
ylim(ylims)
xticks(1:n_cond);
yticks(y_ticks);
xticklabels({'E','S','W','N'});
% xticklabels({'E','S','W','N','E','S','W','N'});
ylabel(y_label);
legend(b,{'Leader','Follower'},'Location','southeast');
legend box off
box off
ax = gca;
set(ax,'FontSize',18,'TickDir','out');
caption = 'Beta estimate';
title(caption,'FontSize',24)
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_bar_' which_term '_estimate_all_pairs'];
print(fig,figname,'-dpdf');
%% ===== source data for population beta estimate bar plot =====

condition_names = {'E';'S';'W';'N'};
role_names = {'Leader';'Follower'};

source_data_beta_pop = table();

for cond = 1:n_cond
    for r = 1:2

        T = table( ...
            {which_term}, ...
            condition_names(cond), ...
            role_names(r), ...
            estimate_all(r,cond), ...
            se_all(r,cond), ...
            p_all(r,cond), ...
            'VariableNames', ...
            {'Term','Condition','Role','Estimate','SE','PValue'});

        source_data_beta_pop = [source_data_beta_pop; T];

    end
end

source_name = [fd 'plots/' hoy ...
    '_source_data_bar_' which_term '_estimate_all_pairs.csv'];

%% paired bar plot. use mean and std of single animal values
% m_colors = {'#c2a5cf','#a6dba0','#969696'}; % leader vs follower 
m_colors = [194, 165, 207; 166, 219, 160] / 255;
pvals = nan(n_cond,3);
fig = figure('Position',[600 300 400 400]);
hold on;
x = (1:n_cond);
estimate = est_bias; term = 'bias';
% estimate = est_sensitivity; term = 'sensitivity';
estimate = estimate(~isnan(estimate(:,1,1)),:,:);
b = bar(x,squeeze(mean(estimate)),'FaceColor','flat','EdgeColor','none','GroupWidth',0.8); 
b(1).FaceColor = m_colors(1,:);
b(2).FaceColor = m_colors(2,:);
ymax = 4;
for cond = 1:n_cond
    y = estimate(:,:,cond);
    h = plot([b(1).XEndPoints(cond) b(2).XEndPoints(cond)], y','LineWidth',1,'Color',0.4*[1 1 1],...
        'Marker','.','MarkerSize',10);
    if mean(y(:,1)) > 0
        errorbar(b(1).XEndPoints(cond),mean(y(:,1)),[],std(y(:,1))/sqrt(size(y,1)),'Color',m_colors(1,:),'LineWidth',2);
    else
        errorbar(b(1).XEndPoints(cond),mean(y(:,1)),std(y(:,1))/sqrt(size(y,1)),[],'Color',m_colors(1,:),'LineWidth',2);
    end
    if mean(y(:,2)) > 0
        errorbar(b(2).XEndPoints(cond),mean(y(:,2)),[],std(y(:,2))/sqrt(size(y,1)),'Color',m_colors(2,:),'LineWidth',2);
    else
        errorbar(b(2).XEndPoints(cond),mean(y(:,2)),std(y(:,2))/sqrt(size(y,1)),[],'Color',m_colors(2,:),'LineWidth',2);
    end    
    [~,pvals(cond,1)] = ttest(y(:,1));
    [~,pvals(cond,2)] = ttest(y(:,2));
    [~,pvals(cond,3)] = ttest(y(:,1), y(:,2));
    % text(b(1).XEndPoints(cond),0.9*ymax,sprintf('P=%.2g', pvals(cond,1)),'HorizontalAlignment','center',...
    %     'Rotation',90,'Units','data','FontSize',14)
    % text(b(2).XEndPoints(cond),0.9*ymax,sprintf('P=%.2g', pvals(cond,2)),'HorizontalAlignment','center',...
    %     'Rotation',90,'Units','data','FontSize',14)
end
xlim([0.5 n_cond+0.5])
xticks(1:n_cond);
xticklabels({'E','S','W','N','E','S','W','N'});
ylabel('Bias (log-likelihood)');
% ylabel('Sensitivity (log-likelihood/degree)');
legend(b,{'Leader','Follower'},'Location','southeast');
legend box off
box off
ax = gca;
set(ax,'FontSize',18,'TickDir','out');
caption = 'Beta estimate';
title(caption,'FontSize',24)
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_bar_' term '_estimate_all_pairs'];
print(fig,figname,'-dpdf');
%% ===== show source data in command window =====

condition_names = {'E';'S';'W';'N';'E2';'S2';'W2';'N2'};
role_names = {'Leader';'Follower'};

source_data = table();

for cond = 1:n_cond
    y = estimate(:,:,cond);

    for pair_i = 1:size(y,1)
        for r = 1:2

            T = table( ...
                pair_i, ...
                condition_names(cond), ...
                role_names(r), ...
                y(pair_i,r), ...
                'VariableNames', ...
                {'PairIndex','Condition','Role','Estimate'});

            source_data = [source_data; T];

        end
    end
end

disp(source_data)

%% testing different models below
% 
% %% mixed logistic model
% cond = 1; % i
% rspd_cond = condition_grps{cond};
% % allstable_foll = allstable(strcmp(allstable.subject,'sFoll'),:);
% cur_mstable = mstable(strcmp(mstable.subject,'sLead'),:);
% % modelspec = ['init_choose_n ~ (angle_east + angle_north)*' other_condition ' + (1|pair) +' ...
% %     '(in_north-1|pair) + (angle_east-1|pair) + (angle_north-1|pair)'];
% modelspec = ['init_choose_n ~ (angle_east + angle_north)*' rspd_cond ' + (1|pair) +' ...
%     '(in_north-1|pair) + (angle_east-1|pair) + (angle_north-1|pair) +' ...
%     '(in_north:angle_east-1|pair) + (in_north:angle_north-1|pair)'];
% % glme = fitglme(allstable_foll,modelspec,Distribution="Binomial");
% glme = fitglme(cur_mstable,modelspec,Distribution="Binomial");
% disp(glme)
% [~,~,statsRandom] = randomEffects(glme);
% disp(statsRandom)
% 
% %% full mixed model include everything
% cond = 1; % in which zone
% mstable = allstable_conds{cond};
% rspd_cond = condition_grps{cond};
% modelspec = ['init_choose_n ~ (angle_east + angle_north)*' rspd_cond '*subject + (1|pair) +' ...
%     '(' rspd_cond '-1|pair) + (angle_east-1|pair) + (angle_north-1|pair)'];
% % modelspec = ['init_choose_n ~ angle_dif *' other_condition '*subject + (1|pair) +' ...
% %     '(' other_condition '-1|pair) + (angle_dif-1|pair)'];
% % modelspec = ['init_choose_n ~ (angle_east + angle_north)*in_north*subject + (1|pair) +' ...
% %     '(in_north-1|pair) + (angle_east-1|pair) + (angle_north-1|pair) +' ...
% %     '(in_north:angle_east-1|pair) + (in_north:angle_north-1|pair)'];
% glme = fitglme(mstable,modelspec,Distribution="Binomial");
% disp(glme)
% [~,~,statsRandom] = randomEffects(glme);
% disp(statsRandom)
% 
% %% simple logistic model
% cond = 1; % in which zone
% mstable = allstable_conds{cond};
% rspd_cond = condition_grps{cond};
% modelspec = ['init_choose_n ~ (angle_east + angle_north)*' rspd_cond '*subject'];
% mdl = fitglm(mstable,modelspec,Distribution="Binomial");
% disp(mdl)
% 
% %% simple logistic model separating leader from follower
% cond = 4; % in which zone
% rspd_cond = condition_grps{cond};
% sel_trials = (strcmp(mstable.phase,'phase4a') & mstable.in_north==1 & mstable.face_north==1) | strcmp(mstable.phase,'phase2b');
% allstable_sel = mstable(sel_trials,:);
% cur_mstable = allstable_sel(strcmp(allstable_sel.subject,'sLead'),:);
% modelspec = ['init_choose_n ~ angle_dif*' rspd_cond ];
% mdl_lead = fitglm(cur_mstable,modelspec,Distribution="Binomial");
% disp(mdl_lead)

% allstable_foll = allstable(strcmp(allstable.subject,'sFoll'),:);
% other_condition = condition_grps{cond};
% modelspec = ['init_choose_n ~ (angle_east + angle_north)*' other_condition];
% mdl_foll = fitglm(allstable_foll,modelspec,Distribution="Binomial");
% disp(mdl_foll)

