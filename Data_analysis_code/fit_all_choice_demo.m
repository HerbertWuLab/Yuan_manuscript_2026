function mstable = fit_all_choice_demo(fd,ctable)
% fit all trials at all times
% get combined mstable for fitting 
% exclude phase2b data and no filtering criterion for initiator, etc
% the "everything" model
%% initial calculation
% fd = '/Users/herbert/Wulab Dropbox/Lab/Yuan/ctable/ctable_20251201/';
% ctable = combine_ctable(fd);
% save([fd 'ctable_light_combined.mat'],'ctable','-v7.3');

%% load after initial calculation
% fd = '/Users/herbert/Wulab Dropbox/Lab/Yuan/ctable/ctable_20251201/';
ctable = load([fd 'Data\ctable_light_combined.mat']).ctable;

%% set params
coords_north = [0 22.5];
coords_east = [22.5 0];
uni_pairs = unique(ctable.pair);
n_uni_pairs = length(uni_pairs);
threshold = 0.6; % threshold for calling a consistent leader in a cohort
mstable = []; % combined master stable to include all pairs
dis_threshold = 10;
ltable = extract_ltable(ctable);

for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};

    % process the ctable
    btable = ctable(strcmp(cur_pair,ctable.pair),:);
    
    if strcmp(cur_pair,'YC013YC014') % only use sessions before extended phase4b+cno sessions
        btable = btable(str2double(btable.date)<=20230804,:);
    elseif strcmp(cur_pair,'YC015YC016') % only use sessions before extended phase4b+cno sessions
        btable = btable(str2double(btable.date)<=20230831,:);
    elseif strcmp(cur_pair,'YC017YC018') % only use sessions before extended phase4b+cno sessions
        btable = btable(str2double(btable.date)<=20231017,:);    
    end
    cur_ltable = ltable(strcmp(cur_pair, ltable.pair), :);
  
    % get criterion day 1
    if isempty(cur_ltable.true_lead) % the pair is not in ltable
        continue
    else
        crit_day1 = cur_ltable.date(end-2);
        sel_date = str2double(btable.date) >= str2double(crit_day1);
    
        s_range = btable.cno==0 & btable.cp_rate>=0.795 & strcmpi(btable.phase,'phase4a')...
            & (btable.p_ledBy_m1+btable.p_ledBy_m2)>=0.8 & sel_date;
        btable = btable(s_range,:); % well-trained
        n_ses = height(btable);
    end

    % determine which mouse is the consistent leader across sessions
    n_ledBy_m1 = sum(strcmp(btable.sLead,'m1'));
    n_ledBy_m2 = sum(strcmp(btable.sLead,'m2'));
    if n_ledBy_m1 >= n_ses * threshold
        cLead = 1; cFoll = 2;
    elseif n_ledBy_m2 >= n_ses * threshold
        cLead = 2; cFoll = 1;
    else
        fprintf(['Leading %d vs %d in %d sessions, less than prop=%.2f of well-trained, phase4a,'...
            ' control sessions in ' cur_pair '. Check data!\n'],n_ledBy_m1,n_ledBy_m2,n_ses,threshold)
        continue; % skip the rest of the current iter and go to the next iter
    end

    stable = vertcat(btable.stable{:});
    stable.sex = repmat(btable.sex(1),height(stable),1);

    % apply selection criteria. don't need the distance filter now
    sel_co_mm = stable.correct == 1 | stable.mismatch == 1; % correct or mismatch
    init_dis_sel = stable.init_dis<dis_threshold; % distance filter
    sel_trial_dur = stable.dur_f < 150; % trial is less than 5s
    sel_trial_type =  stable.trial_type >=1 & stable.trial_type <=4; % only neighboring trial types
    sel_trials1 = sel_co_mm & sel_trial_dur & sel_trial_type & init_dis_sel; % combine and save
    
    sel_trials2 = ~isnan(stable.m1_choose_n) & ~isnan(stable.m2_choose_n); % when both make valid choices
    sel_trials3 = ~isnan(stable.initiator);

    stable_sel = stable(sel_trials1 & sel_trials2 & sel_trials3,:);

    for m = 1:2
        cur_animal = ['m' num2str(m)];
        %%% calculate the angles from east and from north
        angle_zero = stable_sel.([cur_animal '_hd_rot']);
        
        % absolute angular distance to east
        angle_east = angle_zero;
        angle_east(angle_east>180) = angle_east(angle_east>180) - 360;
        stable_sel.([cur_animal '_angle_east']) = abs(angle_east); % take the abs
        
        % absolute angular distance to north
        angle_north = angle_zero - 90;
        angle_north(angle_zero>270) = angle_north(angle_zero>270) - 360;
        stable_sel.([cur_animal '_angle_north']) = abs(angle_north); % take the abs
    
        stable_sel.([cur_animal '_angle_dif']) = (stable_sel.([cur_animal '_angle_east']) - ...
            stable_sel.([cur_animal '_angle_north']))/90; % normalize by max=90
        
        stable_sel.([cur_animal '_angle_rz_dif']) = (stable_sel.([cur_animal '_angle_ez_rot']) - ...
            stable_sel.([cur_animal '_angle_nz_rot']))/180; % normalize by max=180
        % stable_sel.([cur_animal '_angle_rz_dif3']) = (stable_sel.([cur_animal '_angle_ez_rot3']) - ...
        %     stable_sel.([cur_animal '_angle_nz_rot3']))/180*pi;
        % stable_sel.([cur_animal '_angle_rz_dif4']) = (stable_sel.([cur_animal '_angle_ez_rot4']) - ...
        %     stable_sel.([cur_animal '_angle_nz_rot4']))/180*pi;

        % calculate the distance to north and east zones
        x_coords = stable_sel.([cur_animal '_x_rot']);
        y_coords = stable_sel.([cur_animal '_y_rot']);
        stable_sel.([cur_animal '_d2east']) = sqrt((x_coords-coords_east(1)).^2 + (y_coords-coords_east(2)).^2);
        stable_sel.([cur_animal '_d2north']) = sqrt((x_coords-coords_north(1)).^2 + (y_coords-coords_north(2)).^2);
        stable_sel.([cur_animal '_dis_dif']) = stable_sel.([cur_animal '_d2east']) - stable_sel.([cur_animal '_d2north']);

        % % more accurate distance to north and east zone centers
        % stable_sel.([cur_animal '_dis_rz_dif']) = stable_sel.([cur_animal '_d2ez']) - stable_sel.([cur_animal '_d2nz']);
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
    stable_sel.ledBysLead = stable_sel.leader==cLead;

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
    
    stable_sel.dis_btwn_mice = vecnorm([stable_sel.m1_x_rot - stable_sel.m2_x_rot,...
        stable_sel.m1_y_rot - stable_sel.m2_y_rot],2,2);
    stable_sel.lead_sees_foll_angle_rot = stable_sel.([leader '_sees_' follower '_angle_rot']);
    stable_sel.foll_sees_lead_angle_rot = stable_sel.([follower '_sees_' leader '_angle_rot']);

    stable_sel.pair = repmat({cur_pair},height(stable_sel),1);
    mstable = [mstable;stable_sel];
end
mstable.lead_angle_rz_dif = standardize_hw(mstable.lead_angle_rz_dif); % scale 1d data in the 0-1 range
mstable.lead_angle_ez_rot = standardize_hw(mstable.lead_angle_ez_rot);
mstable.lead_angle_nz_rot = standardize_hw(mstable.lead_angle_nz_rot);
mstable.lead_dis_dif = standardize_hw(mstable.lead_dis_dif);
mstable.lead_d2north = standardize_hw(mstable.lead_d2north);
mstable.lead_d2east = standardize_hw(mstable.lead_d2east);

mstable.foll_angle_rz_dif = standardize_hw(mstable.foll_angle_rz_dif);
mstable.foll_angle_ez_rot = standardize_hw(mstable.foll_angle_ez_rot);
mstable.foll_angle_nz_rot = standardize_hw(mstable.foll_angle_nz_rot);  
mstable.foll_dis_dif = standardize_hw(mstable.foll_dis_dif);
mstable.foll_d2north = standardize_hw(mstable.foll_d2north);
mstable.foll_d2east = standardize_hw(mstable.foll_d2east);

mstable.dis_btwn_mice = standardize_hw(mstable.dis_btwn_mice);
mstable.lead_sees_foll_angle_abs = 1-abs(mstable.lead_sees_foll_angle_rot)/180;
mstable.foll_sees_lead_angle_abs = 1-abs(mstable.foll_sees_lead_angle_rot)/180;
mstable.lead_sees_foll_angle_bin = abs(mstable.lead_sees_foll_angle_rot)<120;
mstable.foll_sees_lead_angle_bin = abs(mstable.foll_sees_lead_angle_rot)<120;

%% get coefficients of every animal
uni_pairs = unique(mstable.pair);
n_uni_pairs = length(uni_pairs);
roles = {'lead','foll'};
intercept_estimate = nan(n_uni_pairs,2);
lead_hd_estimate = nan(n_uni_pairs,2);
lead_pos_estimate = nan(n_uni_pairs,2);
foll_hd_estimate = nan(n_uni_pairs,2);
foll_pos_estimate = nan(n_uni_pairs,2);
beta_estimate = nan(n_uni_pairs,2,4);
n_trials_pair = nan(n_uni_pairs,1); 
for r = 1:2
    cur_role = roles{r};
    which_choose_n = [cur_role '_choose_n'];
    for p = 1:n_uni_pairs
        cur_pair = uni_pairs{p};
        sel_pair = strcmp(cur_pair,mstable.pair);
        cur_mstable_pair = mstable(sel_pair,:);
        modelspec = [which_choose_n ' ~ lead_angle_rz_dif + lead_dis_dif + foll_angle_rz_dif + foll_dis_dif'];
        mdl = fitglm(cur_mstable_pair,modelspec,Distribution="Binomial");
        n_trials_pair(p) = height(cur_mstable_pair);
        intercept_estimate(p,r) = mdl.Coefficients.Estimate(1);
        lead_hd_estimate(p,r) = mdl.Coefficients.Estimate(2);
        lead_pos_estimate(p,r) = mdl.Coefficients.Estimate(3);
        foll_hd_estimate(p,r) = mdl.Coefficients.Estimate(4);
        foll_pos_estimate(p,r) = mdl.Coefficients.Estimate(5);
        beta_estimate(p,r,:) = mdl.Coefficients.Estimate(2:5);
    end
end
% beta_estimate = beta_estimate(:,:,2:5); % remove intercept

% paired bar plot of the beta estimates
% m_colors = {'#c2a5cf','#a6dba0','#969696'}; % leader vs follower 
m_colors = [194, 165, 207; 166, 219, 160] / 255;
n_est = size(beta_estimate,3);
pvals = nan(n_est,3);
fig = figure('Position',[600 300 300 300]);
hold on;
x = 1:n_est;
b = bar(x,squeeze(mean(beta_estimate)),'FaceColor','flat',...
    'EdgeColor','none','GroupWidth',0.8); 
b(1).FaceColor = m_colors(1,:);
b(2).FaceColor = m_colors(2,:);
ylims = [-4 22];
for i = 1:n_est
    y = beta_estimate(:,:,i);
    x = [1 2] + 2*(i-1);
    h = plot([b(1).XEndPoints(i) b(2).XEndPoints(i)], y','LineWidth',1,'Color',0.4*[1 1 1],...
        'Marker','.','MarkerSize',14);
    for r = 1:2
        if mean(y(:,r)) > 0
            errorbar(b(r).XEndPoints(i),mean(y(:,r)),[],std(y(:,r))/sqrt(size(y,1)),'Color',m_colors(r,:),'LineWidth',2);
        else
            errorbar(b(r).XEndPoints(i),mean(y(:,r)),std(y(:,r))/sqrt(size(y,1)),[],'Color',m_colors(r,:),'LineWidth',2);
        end
        [~,pvals(i,r)] = ttest(y(:,r));
        % pvals(i,r) = signrank(y(:,r));
        % text(i,0.95*20,sprintf('P=%.2g', p),'HorizontalAlignment','center',...
        %     'Units','data','FontSize',18)
        if pvals(i,r) < 0.001
            text(b(r).XEndPoints(i),0.95*ylims(2),'***','HorizontalAlignment','center',...
                'Rotation',90,'Units','data','FontSize',18) 
        elseif pvals(i,r) < 0.01
            text(b(r).XEndPoints(i),0.95*ylims(2),'**','HorizontalAlignment','center',...
                'Rotation',90,'Units','data','FontSize',18) 
        elseif pvals(i,r) < 0.05
            text(b(r).XEndPoints(i),0.95*ylims(2),'*','HorizontalAlignment','center',...
                'Rotation',90,'Units','data','FontSize',18) 
        end
    end
    [~,pvals(i,3)] = ttest(y(:,1), y(:,2));
end
% plts = [h(1) h_means];
% legend(plts,{'Individual','Mean with SE'},'Location','northeastoutside');
% legend boxoff;
xlim([0.5 n_est+0.5])
% ylim([0 max(max(y))*1.05])
ylim(ylims)
xticks(1:n_est);
xticklabels({'\Delta\theta','\Deltad','\Delta\theta','\Deltad'});
ylabel('Standardized log odds');
legend(b,{'Leader','Follower'},'Location','east');
legend box off
box off
ax = gca;
set(ax,'FontSize',18,'TickDir','out');
caption = ['Beta coefficients (N=' num2str(n_uni_pairs) ' pairs)'];
title(caption,'FontSize',24)
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_beta_all_choice_all_pairs'];
print(fig,figname,'-dpdf');

%% predict correct or error 
% modelspec1 = 'correct ~ dis_btwn_mice + lead_sees_foll_angle_abs + foll_sees_lead_angle_abs';
modelspec1 = 'correct ~ dis_btwn_mice + lead_sees_foll_angle_bin + foll_sees_lead_angle_bin';
mdl = fitglm(mstable,modelspec1,'Distribution','binomial')

n_fold = 50;
corr_nFold = zeros(n_fold,1);
for fi = 1:n_fold
    partition = cvpartition(mstable.correct,"HoldOut",0.1);
    mstable_train = mstable(partition.training,:);
    mstable_test = mstable(partition.test,:);
    mdl = fitglm(mstable_train,modelspec1,'Distribution','binomial');
    yPred = predict(mdl, mstable_test)>0.5;
    corr_nFold(fi) = mean(yPred==mstable_test.correct); 
end
mean_corr = mean(corr_nFold)

%% predict who is the leader
mstable_sel = mstable(~isnan(mstable.leader),:);
modelspec = ['ledBysLead ~ foll_angle_east + foll_angle_north + foll_d2north + foll_d2east + ' ...
    ' lead_angle_east + lead_angle_north + lead_d2north + lead_d2east'];
modelspec_shuf = ['shuffled ~ foll_angle_east + foll_angle_north + foll_d2north + foll_d2east + ' ...
    ' lead_angle_east + lead_angle_north + lead_d2north + lead_d2east'];
mdl = fitglm(mstable_sel,modelspec,'Distribution','binomial');
% mdl_shuf = fitglm(mstable_sel,modelspec_shuf,'Distribution','binomial');
disp(mdl)
n_trials = height(mstable_sel);
n_fold = 50;
corr_nFold = zeros(n_fold,1);
corr_nFold_shuf = zeros(n_fold,1);
for fi = 1:n_fold
    % make shuffled data
    rs_idx = randsample(n_trials,n_trials);
    mstable_sel.shuffled = mstable_sel.ledBysLead(rs_idx);
    % original data
    partition = cvpartition(mstable_sel.ledBysLead,"HoldOut",0.1);
    mstable_train = mstable_sel(partition.training,:);
    mstable_test = mstable_sel(partition.test,:);
    mdl = fitglm(mstable_train,modelspec,'Distribution','binomial');
    yPred = predict(mdl, mstable_test)>0.5;
    corr_nFold(fi) = mean(yPred==mstable_test.ledBysLead); 

    % shuffled data
    mdl_shuf = fitglm(mstable_train,modelspec_shuf,'Distribution','binomial');
    yPred = predict(mdl_shuf, mstable_test)>0.5;
    corr_nFold_shuf(fi) = mean(yPred==mstable_test.shuffled); 
end
mean_corr = mean(corr_nFold)
mean_corr_shuf = mean(corr_nFold_shuf)

%% predict choice using correct or error trials
cur_role = 'lead';
which_choose_n = [cur_role '_choose_n'];
mstable_corr = mstable(mstable.correct==1,:);
modelspec1 = [which_choose_n ' ~ lead_angle_rz_dif + lead_dis_dif + foll_angle_rz_dif + foll_dis_dif'];
mdl_corr = fitglm(mstable_corr,modelspec1,'Distribution','binomial')

n_fold = 50;
corr_nFold = zeros(n_fold,1);
for fi = 1:n_fold
    partition = cvpartition(mstable_corr.(which_choose_n),"HoldOut",0.1);
    mstable_train = mstable_corr(partition.training,:);
    mstable_test = mstable_corr(partition.test,:);
    mdl = fitglm(mstable_train,modelspec1,'Distribution','binomial');
    % mdl = fitglm(mstable_train,modelspec4,'Distribution','binomial');
    yPred = predict(mdl, mstable_test)>0.5;
    corr_nFold(fi) = mean(yPred==mstable_test.(which_choose_n)); 
end
mean_cor_corr = mean(corr_nFold);

mstable_err = mstable(mstable.mismatch==1,:);
modelspec1 = [which_choose_n ' ~ foll_angle_rz_dif + foll_dis_dif + lead_angle_rz_dif + lead_dis_dif'];
mdl_err = fitglm(mstable_err,modelspec1,'Distribution','binomial')

n_fold = 50;
corr_nFold = zeros(n_fold,1);
for fi = 1:n_fold
    partition = cvpartition(mstable_err.(which_choose_n),"HoldOut",0.1);
    mstable_train = mstable_err(partition.training,:);
    mstable_test = mstable_err(partition.test,:);
    mdl = fitglm(mstable_train,modelspec1,'Distribution','binomial');
    % mdl = fitglm(mstable_train,modelspec4,'Distribution','binomial');
    yPred = predict(mdl, mstable_test)>0.5;
    corr_nFold(fi) = mean(yPred==mstable_test.(which_choose_n)); 
end
mean_cor_err = mean(corr_nFold);
[mean_cor_corr mean_cor_err]

%% error rate in correct trials vs mismatch trials
cur_role = 'foll';
which_choose_n = [cur_role '_choose_n'];
modelspec1 = [which_choose_n ' ~ foll_angle_rz_dif + foll_dis_dif + lead_angle_rz_dif + lead_dis_dif'];
mdl1 = fitglm(mstable,modelspec1,'Distribution','binomial'); % course angle from reward zone + coarse dis
disp(mdl1)

n_fold = 100;
corr_nFold = zeros(n_fold,1);
err_nFold_corr = zeros(n_fold,1);
err_nFold_err = zeros(n_fold,1);
for fi = 1:n_fold
    partition = cvpartition(mstable.(which_choose_n),"HoldOut",0.1);
    mstable_train = mstable(partition.training,:);
    mstable_test = mstable(partition.test,:);
    mdl = fitglm(mstable_train,modelspec1,'Distribution','binomial');
    yPred = predict(mdl, mstable_test)>0.5;
    corr_nFold(fi) = mean(yPred~=mstable_test.(which_choose_n)); 
    sel_corr = mstable_test.correct==1;
    err_nFold_corr(fi) = mean(yPred(sel_corr)~=mstable_test.(which_choose_n)(sel_corr)); 
    sel_err = mstable_test.mismatch==1;
    err_nFold_err(fi) = mean(yPred(sel_err)~=mstable_test.(which_choose_n)(sel_err)); 
end
mean_err = mean(corr_nFold);
mean_cor_corr = mean(err_nFold_corr);
mean_cor_err = mean(err_nFold_err);
[mean_err mean_cor_corr mean_cor_err]

%% compare performance to shuffled data. all pairs
n_fold = 100;
roles = {'lead','foll'};
corrs = nan(2,2);
stds = nan(2,2);
Ps = nan(2,1);
for r = 1:2
    cur_role = roles{r};   
    n_trials = height(mstable);
    corr_nFold_data = zeros(n_fold,1);
    corr_nFold_shuf = zeros(n_fold,1);
    which_choose_n = [cur_role '_choose_n'];
    modelspec_data = [which_choose_n ' ~ lead_angle_rz_dif + lead_dis_dif + foll_angle_rz_dif + foll_dis_dif'];
    modelspec_shuf = ['shuffled_choice ~ lead_angle_rz_dif + lead_dis_dif + foll_angle_rz_dif + foll_dis_dif'];
    for fi = 1:n_fold
        % make shuffled data
        rs_idx = randsample(n_trials,n_trials);
        mstable.shuffled_choice = mstable.(which_choose_n)(rs_idx);
    
        partition = cvpartition(mstable.(which_choose_n),"HoldOut",0.1);
        mstable_train = mstable(partition.training,:);
        mstable_test = mstable(partition.test,:);
        mdl_data = fitglm(mstable_train,modelspec_data,'Distribution','binomial');
        yPred = predict(mdl_data, mstable_test)>0.5;
        corr_nFold_data(fi) = mean(yPred==mstable_test.(which_choose_n)); 
    
        % shuffled data
        mdl_shuf = fitglm(mstable_train,modelspec_shuf,'Distribution','binomial');
        yPred = predict(mdl_shuf, mstable_test)>0.5;
        corr_nFold_shuf(fi) = mean(yPred==mstable_test.shuffled_choice);     
    end
    corr_data = mean(corr_nFold_data);
    corr_shuf = mean(corr_nFold_shuf);
    std_data = std(corr_nFold_data);
    std_shuf = std(corr_nFold_shuf);
    % [corr_data corr_shuf]
    corrs(r,1) = corr_data;
    corrs(r,2) = corr_shuf;
    stds(r,1) = std_data;
    stds(r,2) = std_shuf;

    % stats
    obs_diff = mean(corr_data) - mean(corr_shuf);
    % Bootstrap settings
    B = 10000;  % Number of bootstrap iterations
    combined = [corr_nFold_data; corr_nFold_shuf];  % Pool both samples
    
    % Preallocate for speed
    boot_diffs = zeros(B, 1);
    
    % Perform bootstrap resampling
    for i = 1:B
        % Shuffle the combined data
        shuffled = combined(randperm(2*n_fold));
        
        % Split into two new samples
        boot_sample1 = shuffled(1:n_fold);
        boot_sample2 = shuffled(n_fold+1:end);
        
        % Calculate the difference in means for this bootstrap sample
        boot_diffs(i) = mean(boot_sample1) - mean(boot_sample2);
    end
    
    % Calculate p-value: proportion of |boot_diffs| >= |obs_diff|
    Ps(r) = mean(abs(boot_diffs) >= abs(obs_diff));
end

% plot
m_colors = [194, 165, 207; 166, 219, 160] / 255;
x = [1 2];
fig = figure('Position',[200 200 200 300]); hold on
b = bar(x,corrs,0.8,'LineStyle','none','FaceColor','flat','GroupWidth',0.8);
b(1).CData(1,:) = m_colors(1,:);
b(2).CData(1,:) = m_colors(1,:);
b(1).CData(2,:) = m_colors(2,:);
b(2).CData(2,:) = m_colors(2,:);
leader_xcoords = [b(1).XEndPoints(1) b(2).XEndPoints(1)];
follower_xcoords = [b(1).XEndPoints(2) b(2).XEndPoints(2)];
errorbar(leader_xcoords,corrs(1,:),[],stds(1,:),...
    'Color',m_colors(1,:),'LineStyle','none','LineWidth',2);
errorbar(follower_xcoords,corrs(2,:),[],stds(2,:),...
    'Color',m_colors(2,:),'LineStyle','none','LineWidth',2);
xlim([0.6 2.4])
ylim([0 1])
yline(0.5,'k--')
yticks(0:0.2:1)
xticks([leader_xcoords follower_xcoords]);
xticklabels({'L obs','L shuf','F obs','F shuf'});
ylabel('Prop correct');
box off
ax = gca;
set(ax,'FontSize',20,'TickDir','out');
% text([1 2],[0.88 0.88],sprintf('P<%.2g', 1/B),'HorizontalAlignment','center',...
%     'Units','data','FontSize',18)
text([1 2],[0.92 0.92],'***','HorizontalAlignment','center',...
    'Rotation',90,'Units','data','FontSize',18)
caption = 'Choice Pred using initial condition';
title(caption,'FontSize',24)
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_choice_prediction_all_pairs'];
print(fig,figname,'-dpdf');

%% predicting choice comparing males to females
sexes = {'female';'male'};
n_sex = 2;
for se = 2
    sex = sexes{se};
    mstable_sex = mstable(strcmp(mstable.sex,sex),:);
    n_fold = 100;
    roles = {'lead','foll'};
    corrs = nan(2,2);
    stds = nan(2,2);
    Ps = nan(2,1);
    for r = 1:2
        cur_role = roles{r};   
        n_trials = height(mstable_sex);
        corr_nFold_data = zeros(n_fold,1);
        corr_nFold_shuf = zeros(n_fold,1);
        which_choose_n = [cur_role '_choose_n'];
        modelspec_data = [which_choose_n ' ~ lead_angle_rz_dif + lead_dis_dif + foll_angle_rz_dif + foll_dis_dif'];
        modelspec_shuf = ['shuffled_choice ~ lead_angle_rz_dif + lead_dis_dif + foll_angle_rz_dif + foll_dis_dif'];
        for fi = 1:n_fold
            % make shuffled data
            rs_idx = randsample(n_trials,n_trials);
            mstable_sex.shuffled_choice = mstable_sex.(which_choose_n)(rs_idx);
        
            partition = cvpartition(mstable_sex.(which_choose_n),"HoldOut",0.1);
            mstable_train = mstable_sex(partition.training,:);
            mstable_test = mstable_sex(partition.test,:);
            mdl_data = fitglm(mstable_train,modelspec_data,'Distribution','binomial');
            yPred = predict(mdl_data, mstable_test)>0.5;
            corr_nFold_data(fi) = mean(yPred==mstable_test.(which_choose_n)); 
        
            % shuffled data
            mdl_shuf = fitglm(mstable_train,modelspec_shuf,'Distribution','binomial');
            yPred = predict(mdl_shuf, mstable_test)>0.5;
            corr_nFold_shuf(fi) = mean(yPred==mstable_test.shuffled_choice);     
        end
        corr_data = mean(corr_nFold_data);
        corr_shuf = mean(corr_nFold_shuf);
        std_data = std(corr_nFold_data);
        std_shuf = std(corr_nFold_shuf);
        % [corr_data corr_shuf]
        corrs(r,1) = corr_data;
        corrs(r,2) = corr_shuf;
        stds(r,1) = std_data;
        stds(r,2) = std_shuf;
    
        % stats
        obs_diff = mean(corr_data) - mean(corr_shuf);
        % Bootstrap settings
        B = 10000;  % Number of bootstrap iterations
        combined = [corr_nFold_data; corr_nFold_shuf];  % Pool both samples
        
        % Preallocate for speed
        boot_diffs = zeros(B, 1);
        
        % Perform bootstrap resampling
        for i = 1:B
            % Shuffle the combined data
            shuffled = combined(randperm(2*n_fold));
            
            % Split into two new samples
            boot_sample1 = shuffled(1:n_fold);
            boot_sample2 = shuffled(n_fold+1:end);
            
            % Calculate the difference in means for this bootstrap sample
            boot_diffs(i) = mean(boot_sample1) - mean(boot_sample2);
        end
        
        % Calculate p-value: proportion of |boot_diffs| >= |obs_diff|
        Ps(r) = mean(abs(boot_diffs) >= abs(obs_diff));
    end
    
    % plot
    m_colors = [194, 165, 207; 166, 219, 160] / 255;
    x = [1 2];
    fig = figure('Position',[200 200 200 300]); hold on
    b = bar(x,corrs,0.8,'LineStyle','none','FaceColor','flat','GroupWidth',0.8);
    b(1).CData(1,:) = m_colors(1,:);
    b(2).CData(1,:) = m_colors(1,:);
    b(1).CData(2,:) = m_colors(2,:);
    b(2).CData(2,:) = m_colors(2,:);
    leader_xcoords = [b(1).XEndPoints(1) b(2).XEndPoints(1)];
    follower_xcoords = [b(1).XEndPoints(2) b(2).XEndPoints(2)];
    errorbar(leader_xcoords,corrs(1,:),[],stds(1,:),...
        'Color',m_colors(1,:),'LineStyle','none','LineWidth',2);
    errorbar(follower_xcoords,corrs(2,:),[],stds(2,:),...
        'Color',m_colors(2,:),'LineStyle','none','LineWidth',2);
    xlim([0.6 2.4])
    ylim([0 1])
    % yline(0.5,'k--')
    yticks(0:0.2:1)
    xticks([leader_xcoords follower_xcoords]);
    xticklabels({'L obs','L shuf','F obs','F shuf'});
    ylabel('Prop correct');
    box off
    ax = gca;
    set(ax,'FontSize',20,'TickDir','out');
    % text([1 2],[0.88 0.88],sprintf('P<%.2g', 1/B),'HorizontalAlignment','center',...
    %     'Units','data','FontSize',18)
    text([1 2],[0.92 0.92],'***','HorizontalAlignment','center',...
        'Rotation',90,'Units','data','FontSize',18)
    caption = ['Choice prediction ' sex ' pairs'];
    title(caption,'FontSize',24)
    hoy = char(datetime('now','Format','yyyyMMdd'));
    figname = [fd 'plots/' hoy '_choice_prediction_' sex];
    print(fig,figname,'-dpdf');
end

%% run prediction on individual mice
cur_role = 'foll';
which_choose_n = [cur_role '_choose_n'];
uni_pairs = unique(mstable.pair);
n_uni_pairs = length(uni_pairs);
mean_cor = nan(n_uni_pairs,1);
for p = 1:n_uni_pairs
% for p = 1:3
    cur_pair = uni_pairs{p};
    mstable_pair = mstable(strcmp(cur_pair,mstable.pair),:);
    modelspec1 = [which_choose_n ' ~ lead_angle_rz_dif + lead_dis_dif + foll_angle_rz_dif + foll_dis_dif'];
    
    n_fold = 50;
    corr_nFold = zeros(n_fold,1);
    for fi = 1:n_fold
        partition = cvpartition(mstable_pair.(which_choose_n),"HoldOut",0.1);
        mstable_train = mstable_pair(partition.training,:);
        mstable_test = mstable_pair(partition.test,:);
        mdl = fitglm(mstable_train,modelspec1,'Distribution','binomial');
        yPred = predict(mdl, mstable_test)>0.5;
        corr_nFold(fi) = mean(yPred==mstable_test.(which_choose_n)); 
    end
    mean_cor(p) = mean(corr_nFold);
end

%% compare performance to shuffled data on individual mice
n_fold = 50;
roles = {'lead','foll'};
n_roles = length(roles);
uni_pairs = unique(mstable.pair);
n_uni_pairs = length(uni_pairs);
corrs = nan(n_uni_pairs,n_roles,2);

for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    mstable_pair = mstable(strcmp(cur_pair,mstable.pair),:);

    for r = 1:2
        cur_role = roles{r};   
        n_trials = height(mstable_pair);
        corr_nFold_data = zeros(n_fold,1);
        corr_nFold_shuf = zeros(n_fold,1);
        which_choose_n = [cur_role '_choose_n'];
        modelspec_data = [which_choose_n ' ~ lead_angle_rz_dif + lead_dis_dif + foll_angle_rz_dif + foll_dis_dif'];
        modelspec_shuf = ['shuffled_choice ~ lead_angle_rz_dif + lead_dis_dif + foll_angle_rz_dif + foll_dis_dif'];
        for fi = 1:n_fold
            % make shuffled data
            rs_idx = randsample(n_trials,n_trials);
            mstable_pair.shuffled_choice = mstable_pair.(which_choose_n)(rs_idx);
        
            partition = cvpartition(mstable_pair.(which_choose_n),"HoldOut",0.1);
            mstable_train = mstable_pair(partition.training,:);
            mstable_test = mstable_pair(partition.test,:);
            mdl_data = fitglm(mstable_train,modelspec_data,'Distribution','binomial');
            yPred = predict(mdl_data, mstable_test)>0.5;
            corr_nFold_data(fi) = mean(yPred==mstable_test.(which_choose_n)); 
        
            % shuffled data
            mdl_shuf = fitglm(mstable_train,modelspec_shuf,'Distribution','binomial');
            yPred = predict(mdl_shuf, mstable_test)>0.5;
            corr_nFold_shuf(fi) = mean(yPred==mstable_test.shuffled_choice);     
        end
        corr_data = mean(corr_nFold_data);
        corr_shuf = mean(corr_nFold_shuf);
        corrs(p,r,1) = corr_data;
        corrs(p,r,2) = corr_shuf;
    end
end

%% beta estimates compare females to males
estimate_sexes = cell(2,1);
sexes = {'female';'male'};
n_pairs = nan(2,1);
n_sex = 2;
n_trials_pair_sex = nan(n_uni_pairs,2); 

for se = 1:2
    sex = sexes{se};
coords_north = [0 22.5];
coords_east = [22.5 0];
uni_pairs = unique(ctable.pair);
n_uni_pairs = length(uni_pairs);
threshold = 0.6; % threshold for calling a consistent leader in a cohort
mstable = []; % combined master stable to include all pairs
ltable = extract_ltable(ctable);

for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};

    % process the ctable
    btable = ctable(strcmp(cur_pair,ctable.pair),:);

    % select sex
    cur_sex = btable.sex{1};
    if ~strcmp(cur_sex,sex)
        continue
    end
    
    if strcmp(cur_pair,'YC017YC018') % only use sessions before extended phase4b+cno sessions
        btable = btable(str2double(btable.date)<=20231017,:);
    elseif strcmp(cur_pair,'YC013YC014') % only use sessions before extended phase4b+cno sessions
        btable = btable(str2double(btable.date)<=20230804,:);
    elseif strcmp(cur_pair,'YC015YC016') % only use sessions before extended phase4b+cno sessions
        btable = btable(str2double(btable.date)<=20230831,:);
    end
    cur_ltable = ltable(strcmp(cur_pair, ltable.pair), :);
  
    % get criterion day 1
    if isempty(cur_ltable.true_lead) % the pair is not in ltable
        continue
    else
        crit_day1 = cur_ltable.date(end-2);
        sel_date = str2double(btable.date) >= str2double(crit_day1);
    
        s_range = btable.cno==0 & btable.cp_rate>=0.795 & strcmpi(btable.phase,'phase4a')...
            & (btable.p_ledBy_m1+btable.p_ledBy_m2)>=0.8 & sel_date;
        btable = btable(s_range,:); % well-trained
        n_ses = height(btable);
    end

    % determine which mouse is the consistent leader across sessions
    n_ledBy_m1 = sum(strcmp(btable.sLead,'m1'));
    n_ledBy_m2 = sum(strcmp(btable.sLead,'m2'));
    if n_ledBy_m1 >= n_ses * threshold
        cLead = 1; cFoll = 2;
    elseif n_ledBy_m2 >= n_ses * threshold
        cLead = 2; cFoll = 1;
    else
        fprintf(['Leading %d vs %d in %d sessions, less than prop=%.2f of well-trained, phase4a,'...
            ' control sessions in ' cur_pair '. Check data!\n'],n_ledBy_m1,n_ledBy_m2,n_ses,threshold)
        continue; % skip the rest of the current iter and go to the next iter
    end

    stable = vertcat(btable.stable{:});

    % apply selection criteria. don't need the distance filter now
    sel_co_mm = stable.correct == 1 | stable.mismatch == 1; % correct or mismatch
    init_dis_sel = stable.init_dis<dis_threshold; % distance filter
    sel_trial_dur = stable.dur_f < 150; % trial is less than 5s
    sel_trial_type =  stable.trial_type >=1 & stable.trial_type <=4; % only neighboring trial types
    sel_trials1 = sel_co_mm & sel_trial_dur & sel_trial_type & init_dis_sel; % combine and save
    sel_trials2 = ~isnan(stable.m1_choose_n) & ~isnan(stable.m2_choose_n); % when both make valid choices
    sel_trials3 = ~isnan(stable.initiator);

    stable_sel = stable(sel_trials1 & sel_trials2 & sel_trials3,:);

    for m = 1:2
        cur_animal = ['m' num2str(m)];
        %%% calculate the angles from east and from north
        angle_zero = stable_sel.([cur_animal '_hd_rot']);
        
        % absolute angular distance to east
        angle_east = angle_zero;
        angle_east(angle_east>180) = angle_east(angle_east>180) - 360;
        stable_sel.([cur_animal '_angle_east']) = abs(angle_east); % take the abs
        
        % absolute angular distance to north
        angle_north = angle_zero - 90;
        angle_north(angle_zero>270) = angle_north(angle_zero>270) - 360;
        stable_sel.([cur_animal '_angle_north']) = abs(angle_north); % take the abs
    
        stable_sel.([cur_animal '_angle_dif']) = (stable_sel.([cur_animal '_angle_east']) - ...
            stable_sel.([cur_animal '_angle_north']))/90; % normalize by max=90
        
        stable_sel.([cur_animal '_angle_rz_dif']) = (stable_sel.([cur_animal '_angle_ez_rot']) - ...
            stable_sel.([cur_animal '_angle_nz_rot']))/180; % normalize by max=180

        % calculate the distance to north and east zones
        x_coords = stable_sel.([cur_animal '_x_rot']);
        y_coords = stable_sel.([cur_animal '_y_rot']);
        stable_sel.([cur_animal '_d2east']) = sqrt((x_coords-coords_east(1)).^2 + (y_coords-coords_east(2)).^2);
        stable_sel.([cur_animal '_d2north']) = sqrt((x_coords-coords_north(1)).^2 + (y_coords-coords_north(2)).^2);
        stable_sel.([cur_animal '_dis_dif']) = stable_sel.([cur_animal '_d2east']) - stable_sel.([cur_animal '_d2north']);

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
    stable_sel.ledBysLead = stable_sel.leader==cLead;

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
    
    stable_sel.dis_btwn_mice = vecnorm([stable_sel.m1_x_rot - stable_sel.m2_x_rot,...
        stable_sel.m1_y_rot - stable_sel.m2_y_rot],2,2);
    stable_sel.lead_sees_foll_angle_rot = stable_sel.([leader '_sees_' follower '_angle_rot']);
    stable_sel.foll_sees_lead_angle_rot = stable_sel.([follower '_sees_' leader '_angle_rot']);

    stable_sel.pair = repmat({cur_pair},height(stable_sel),1);
    mstable = [mstable;stable_sel];
end
mstable.lead_angle_rz_dif = standardize_hw(mstable.lead_angle_rz_dif); % scale 1d data in the 0-1 range
mstable.lead_angle_ez_rot = standardize_hw(mstable.lead_angle_ez_rot);
mstable.lead_angle_nz_rot = standardize_hw(mstable.lead_angle_nz_rot);
mstable.lead_dis_dif = standardize_hw(mstable.lead_dis_dif);
mstable.lead_d2north = standardize_hw(mstable.lead_d2north);
mstable.lead_d2east = standardize_hw(mstable.lead_d2east);

mstable.foll_angle_rz_dif = standardize_hw(mstable.foll_angle_rz_dif);
mstable.foll_angle_ez_rot = standardize_hw(mstable.foll_angle_ez_rot);
mstable.foll_angle_nz_rot = standardize_hw(mstable.foll_angle_nz_rot);  
mstable.foll_dis_dif = standardize_hw(mstable.foll_dis_dif);
mstable.foll_d2north = standardize_hw(mstable.foll_d2north);
mstable.foll_d2east = standardize_hw(mstable.foll_d2east);

mstable.dis_btwn_mice = standardize_hw(mstable.dis_btwn_mice);
mstable.lead_sees_foll_angle_abs = 1-abs(mstable.lead_sees_foll_angle_rot)/180;
mstable.foll_sees_lead_angle_abs = 1-abs(mstable.foll_sees_lead_angle_rot)/180;
mstable.lead_sees_foll_angle_bin = abs(mstable.lead_sees_foll_angle_rot)<120;
mstable.foll_sees_lead_angle_bin = abs(mstable.foll_sees_lead_angle_rot)<120;

% get coefficients of every animal

uni_pairs = unique(mstable.pair);
n_uni_pairs = length(uni_pairs);
roles = {'lead','foll'};
intercept_estimate = nan(n_uni_pairs,2);
lead_hd_estimate = nan(n_uni_pairs,2);
lead_pos_estimate = nan(n_uni_pairs,2);
foll_hd_estimate = nan(n_uni_pairs,2);
foll_pos_estimate = nan(n_uni_pairs,2);
beta_estimate = nan(n_uni_pairs,2,4);
for r = 1:2
    cur_role = roles{r};
    which_choose_n = [cur_role '_choose_n'];
    for p = 1:n_uni_pairs
        cur_pair = uni_pairs{p};
        sel_pair = strcmp(cur_pair,mstable.pair);
        cur_mstable_pair = mstable(sel_pair,:);
        modelspec = [which_choose_n ' ~ lead_angle_rz_dif + lead_dis_dif + foll_angle_rz_dif + foll_dis_dif'];
        mdl = fitglm(cur_mstable_pair,modelspec,Distribution="Binomial");
        n_trials_pair_sex(p,se) = height(cur_mstable_pair);
        intercept_estimate(p,r) = mdl.Coefficients.Estimate(1);
        lead_hd_estimate(p,r) = mdl.Coefficients.Estimate(2);
        lead_pos_estimate(p,r) = mdl.Coefficients.Estimate(3);
        foll_hd_estimate(p,r) = mdl.Coefficients.Estimate(4);
        foll_pos_estimate(p,r) = mdl.Coefficients.Estimate(5);
        beta_estimate(p,r,:) = mdl.Coefficients.Estimate(2:5);
    end
end
estimate_sexes{se} = beta_estimate;
n_pairs(se) = n_uni_pairs;
end

%% plot
% paired bar plot of the beta estimates
% m_colors = {'#c2a5cf','#a6dba0','#969696'}; % leader vs follower 
sexes = {'female';'male'};
n_sex = 2;
for se = 2
    sex = sexes{se};
    m_colors = [194, 165, 207; 166, 219, 160] / 255;
    beta_estimate = estimate_sexes{se};
    n_est = size(beta_estimate,3);
    pvals = nan(n_est,3);
    fig = figure('Position',[600 300 300 300]);
    hold on;
    x = 1:n_est;
    b = bar(x,squeeze(mean(beta_estimate)),'FaceColor','flat',...
        'EdgeColor','none','GroupWidth',0.8); 
    b(1).FaceColor = m_colors(1,:);
    b(2).FaceColor = m_colors(2,:);
    ylims = [-4 22];
    for i = 1:n_est
        y = beta_estimate(:,:,i);
        x = [1 2] + 2*(i-1);
        h = plot([b(1).XEndPoints(i) b(2).XEndPoints(i)], y','LineWidth',1,'Color',0.4*[1 1 1],...
            'Marker','.','MarkerSize',14);
        for r = 1:2
            if mean(y(:,r)) > 0
                errorbar(b(r).XEndPoints(i),mean(y(:,r)),[],std(y(:,r))/sqrt(size(y,1)),'Color',m_colors(r,:),'LineWidth',2);
            else
                errorbar(b(r).XEndPoints(i),mean(y(:,r)),std(y(:,r))/sqrt(size(y,1)),[],'Color',m_colors(r,:),'LineWidth',2);
            end
            [~,pvals(i,r)] = ttest(y(:,r));
            % pvals(i,r) = signrank(y(:,r));
            % text(i,0.95*20,sprintf('P=%.2g', p),'HorizontalAlignment','center',...
            %     'Units','data','FontSize',18)
            if pvals(i,r) < 0.001
                text(b(r).XEndPoints(i),0.95*ylims(2),'***','HorizontalAlignment','center',...
                    'Rotation',90,'Units','data','FontSize',18) 
            elseif pvals(i,r) < 0.01
                text(b(r).XEndPoints(i),0.95*ylims(2),'**','HorizontalAlignment','center',...
                    'Rotation',90,'Units','data','FontSize',18) 
            elseif pvals(i,r) < 0.05
                text(b(r).XEndPoints(i),0.95*ylims(2),'*','HorizontalAlignment','center',...
                    'Rotation',90,'Units','data','FontSize',18) 
            end
        end
        [~,pvals(i,3)] = ttest(y(:,1), y(:,2));
    end
    % plts = [h(1) h_means];
    % legend(plts,{'Individual','Mean with SE'},'Location','northeastoutside');
    % legend boxoff;
    xlim([0.5 n_est+0.5])
    % ylim([0 max(max(y))*1.05])
    ylim(ylims)
    xticks(1:n_est);
    xticklabels({'\Delta\theta','\Deltad','\Delta\theta','\Deltad'});
    ylabel('Standardized log odds');
    legend(b,{'Leader','Follower'},'Location','east');
    legend box off
    box off
    ax = gca;
    set(ax,'FontSize',18,'TickDir','out');
    n_uni_pairs = n_pairs(se);
    caption = ['Beta coefficients (N=' num2str(n_uni_pairs) ' ' sex ' pairs)'];
    title(caption,'FontSize',24)
    hoy = char(datetime('now','Format','yyyyMMdd'));
    figname = [fd 'plots/' hoy '_beta_all_choice_' sex];
    print(fig,figname,'-dpdf');
end

%% plot females to males side by side
pvals = nan(4,2);
estimate_female = estimate_sexes{1};
n_females = size(estimate_female,1);
estimate_female_rs = reshape(estimate_female,[n_females 4*2]);
mean_estimate_female = mean(estimate_female_rs);

estimate_male = estimate_sexes{2};
n_males = size(estimate_male,1);
estimate_male_rs = reshape(estimate_male,[n_males 4*2]);
mean_estimate_male = mean(estimate_male_rs);

% paired bar plot of the beta estimates comparing males to females
fill_colors = [239,154,154;129, 212, 250]/255;
line_colors = [183, 28, 28;1, 87, 155]/255;

n_est = 8;
fig = figure('Position',[600 300 600 400]);
hold on;
x = 1:n_est;
b = bar(x,[mean_estimate_female;mean_estimate_male],'FaceColor','none',...
    'EdgeColor','k','GroupWidth',0.8); 
b(1).EdgeColor = line_colors(1,:);
b(2).EdgeColor = line_colors(2,:);
%
ylims = [-4 22];
for i = 1:n_est
    h1 = scatter(b(1).XEndPoints(i), estimate_female_rs(:,i),100,...
        'MarkerFaceColor',fill_colors(1,:),'MarkerEdgeColor',line_colors(1,:),'LineWidth',0.1);
    h2 = scatter(b(2).XEndPoints(i), estimate_male_rs(:,i),100,...
        'MarkerFaceColor',fill_colors(2,:),'MarkerEdgeColor',line_colors(2,:),'LineWidth',0.1);
    for r = 1:2
        errorbar(b(1).XEndPoints(i),mean(estimate_female_rs(:,i)),[],std(estimate_female_rs(:,i))/sqrt(n_females),'Color',fill_colors(1,:),'LineWidth',2);
        errorbar(b(2).XEndPoints(i),mean(estimate_male_rs(:,i)),[],std(estimate_male_rs(:,i))/sqrt(n_males),'Color',fill_colors(2,:),'LineWidth',2);
        [h,pvals(i,r)] = ttest2(estimate_female_rs(:,i),estimate_male_rs(:,i));
        if pvals(i,r) < 0.001
            text(i,0.95*ylims(2),'***','HorizontalAlignment','center',...
                'Rotation',90,'Units','data','FontSize',18) 
        elseif pvals(i,r) < 0.01
            text(i,0.95*ylims(2),'**','HorizontalAlignment','center',...
                'Rotation',90,'Units','data','FontSize',18) 
        elseif pvals(i,r) < 0.05
            text(i,0.95*ylims(2),'*','HorizontalAlignment','center',...
                'Rotation',90,'Units','data','FontSize',18) 
        end
    end
end
xlim([0.5 n_est+0.5])
ylim(ylims)
xticks([1.5 3.5 5.5 7.5]);
xticklabels({'Leader \Delta\theta','Leader \Deltad','Follower \Delta\theta','Follower \Deltad'});
ylabel('Standardized log odds');
legend([h1(1) h2(1)],{'Female','Male'},'Location','east');
legend box off
box off
ax = gca;
set(ax,'FontSize',18,'TickDir','out');
caption = 'beta coefficients comparing sexes';
title(caption,'FontSize',24)
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_beta_compare_sexes'];
print(fig,figname,'-dpdf');


