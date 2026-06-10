%% Calculate trial-by-trial responses
% Plot trial-by-trial responses of example neurons.
%
% This script is provided for review purposes. The full dataset is not
% included here because of its large size, but it will be released together
% with the publication.
%
%%
% parent_fd = [fd 'Data\YC069\'];
% fd_list = get_fd_list_demo(parent_fd);
params.phase = '4a';
fd_list = get_fd_list(parent_fd, params.phase);
n_fd = length(fd_list);
params.pcut = 0.05;
positions = {'self','other','other_allo','other_ego'};
max_distances = [20,20,35,35];
p = 4;
params.which_pos = positions{p};
params.max_dist = max_distances(p);
params.spatial_binsize = 5;
% for idx_fd = 1:n_fd
% for idx_fd = 34:82
T_combined = [];
for idx_fd = 1
    cur_fd_prefix = fd_list(idx_fd).folder;
    cur_date = fd_list(idx_fd).name;
    cur_fd = fullfile(cur_fd_prefix,cur_date);
    animal_str_idx = strfind(cur_fd,'YC');
    animal = cur_fd(animal_str_idx:animal_str_idx+4);
    params.animal = animal;
    params.fd = cur_fd;
    params.date = cur_date;
    params.id = get_mouse_id(cur_fd); 
    params.role = get_role(animal);
    spk = load([cur_fd '/' animal '_' cur_date '_spk_data_GC6_25ms.mat']).spike_prob; % n_cells x n_frames
    ftable = load([cur_fd '/' animal '_' cur_date '_ftable.mat']).ftable;
    stable_sel = load([cur_fd '/' animal '_' cur_date '_stable_sel.mat']).stable_sel;
    params.which_frames = 'both_outside_arrival_zone';

    % params.roi_range = [6 10 15 16 36 37 72];
    params.roi_range = [];
    % rtable_fname = [cur_fd '/' animal '_' cur_date '_rtable_' params.which_frames ...
    % '_' params.which_pos '_coh_binsize=5_shuf=100.mat'];
    % rtable = load(rtable_fname).rtable;
    % params.roi_range = find(rtable.p_info<params.pcut & rtable.p_corr<params.pcut & rtable.p_coh<params.pcut);
    params.who_lead = 'either';
    params.perf_filter = 'all';
    % [rtable,params] = get_spatial_selectivity_v11(stable_sel,ftable,spk,params); % get the receptive field of every neuron
    % p_sel = mean(rtable.p_info<params.pcut & rtable.p_corr<params.pcut & rtable.p_coh<params.pcut)
    rtable_fname = [cur_fd '/' animal '_' cur_date '_rtable_' params.which_frames ...
        '_' params.which_pos '_RF'];
    % save(rtable_fname,'rtable');
    load(rtable_fname,'rtable');

    params.which_frames = '2-0s_before_arrival';
    T_long = get_bytrial_response(stable_sel,ftable,rtable,spk,params);
    
    %%% plot here by edit get_bytrial_response function %%%

    T_combined = [T_combined;T_long];
end

%% load rtable after initial calculation
parent_fd = 'E:\Wulab Dropbox\Lab\Yuan\imaging_analysis\YC*\';
params.phase = '4a';
fd_list = get_fd_list(parent_fd, params.phase);
n_fd = length(fd_list);
params.pcut = 0.05;
positions = {'self','other','other_allo','other_ego'};
max_distances = [20,20,35,35];
p = 4;
params.which_pos = positions{p};
params.max_dist = max_distances(p);
params.spatial_binsize = 5;
T_combined = [];
mrtable = [];
for idx_fd = 1:82
    cur_fd_prefix = fd_list(idx_fd).folder;
    cur_date = fd_list(idx_fd).name;
    cur_fd = fullfile(cur_fd_prefix,cur_date);
    animal_str_idx = strfind(cur_fd,'YC');
    animal = cur_fd(animal_str_idx:animal_str_idx+4);
    params.animal = animal;
    params.fd = cur_fd;
    params.date = cur_date;
    params.id = get_mouse_id(cur_fd); 
    params.role = get_role(animal);
    spk = load([cur_fd '/' animal '_' cur_date '_spk_data_GC6_25ms.mat']).spike_prob; % n_cells x n_frames
    ftable = load([cur_fd '/' animal '_' cur_date '_ftable.mat']).ftable;
    stable_sel = load([cur_fd '/' animal '_' cur_date '_stable_sel.mat']).stable_sel;
    params.which_frames = 'both_outside_arrival_zone';
    % params.which_frames = '2-0s_before_arrival';
    % params.roi_range = [6 10 15 16 36 37 72];
    params.roi_range = [];
    % rtable_fname = [cur_fd '/' animal '_' cur_date '_rtable_' params.which_frames ...
    % '_' params.which_pos '_coh_binsize=5_shuf=100.mat'];
    % rtable = load(rtable_fname).rtable;
    % params.roi_range = find(rtable.p_info<params.pcut & rtable.p_corr<params.pcut & rtable.p_coh<params.pcut);
    params.who_lead = 'either';
    params.perf_filter = 'all';
    rtable_fname = [cur_fd '/' animal '_' cur_date '_rtable_' params.which_frames ...
        '_' params.which_pos '_RF'];
    load(rtable_fname,'rtable');

    params.which_frames = '2-0s_before_arrival';
    [T_long,rtable] = get_bytrial_response(stable_sel,ftable,rtable,spk,params);
    T_long.animal = repmat({animal},height(T_long),1);
    T_long.role = repmat({params.role},height(T_long),1);
    T_combined = [T_combined;T_long];
    mrtable = [mrtable;rtable];
end

fd = 'E:\Wulab Dropbox\Yuan\Yuan_manuscript_demo\';

%% compare lead vs follow distribution
which_role = 'leader';
sel_role = strcmp(which_role,T_combined.role);

rf_filter = 'front';
switch rf_filter
    case 'front'
        % sel_neuron = T_combined.dist <= 10 & (T_combined.angle > -60 & T_combined.angle < 60);
        sel_neuron = (T_combined.angle > -60 & T_combined.angle < 60);
        % sel_neuron = (T_combined.angle > -45 & T_combined.angle < 45);
    case 'other'
        % sel_neuron = ~(T_combined.dist <= 10 & (T_combined.angle > -60 & T_combined.angle < 60));
        sel_neuron = ~(T_combined.angle > -60 & T_combined.angle < 60);
        % sel_neuron = ~(T_combined.angle > -45 & T_combined.angle < 45);
end
T_sel = T_combined(sel_neuron & sel_role, :);
% --- Trial role (per trial, same for all neurons)
is_leader_trial = T_sel.lead==1; % recorded mouse is leading
is_follower_trial = T_sel.follow==1;

vals_lead    = T_sel.response(is_leader_trial);
vals_follow  = T_sel.response(is_follower_trial);

vals_lead = vals_lead(~isnan(vals_lead));
vals_follow = vals_follow(~isnan(vals_follow));

% --- Visualization
figure;
subplot(1,2,1);
histogram(vals_lead, 0:5:100, 'FaceColor','r','FaceAlpha',0.5);
hold on;
histogram(vals_follow, 0:5:100, 'FaceColor','b','FaceAlpha',0.5);
xlabel('Percentile of activity'); ylabel('Count');
legend({'Lead','Follow'});
title('Distribution');
% set(gca,'FontSize',14)

subplot(1,2,2);
boxplot([vals_lead; vals_follow], ...
        [ones(size(vals_lead)); 2*ones(size(vals_follow))], ...
        'Labels',{'Lead','Follow'});

ylim([0 100]);  % optional, match your percentile scale

ylabel('Percentile of activity');
% title('Boxplot')
hold on;
[p, ~, stats] = ranksum(vals_lead, vals_follow);
fprintf('Wilcoxon rank-sum test lead vs follow: p = %.3g\n', p);
text(1.2,100,sprintf('P=%.3g\n', p))
% set(gca,'FontSize',14)
sgtitle([which_role ' lead vs follow ' rf_filter],'FontSize',16);

% compare correct vs mismatch distribution

% --- Trial outcome masks
is_correct  = T_sel.correct==1;
is_mismatch = T_sel.mismatch==1;

vals_correct    = T_sel.response(is_correct);
vals_mismatch  = T_sel.response(is_mismatch);

% Flatten and drop NaNs
vals_correct  = vals_correct(~isnan(vals_correct));
vals_mismatch = vals_mismatch(~isnan(vals_mismatch));

% --- Visualization
figure;
subplot(1,2,1);
histogram(vals_correct, 0:5:100, 'FaceColor','g','FaceAlpha',0.5);
hold on;
histogram(vals_mismatch, 0:5:100, 'FaceColor','m','FaceAlpha',0.5);
xlabel('Percentile of activity'); ylabel('Count');
legend({'Correct','Mismatch'});
title('Distribution');
% set(gca,'FontSize',16)

subplot(1,2,2);
boxplot([vals_correct; vals_mismatch], ...
        [ones(size(vals_correct)); 2*ones(size(vals_mismatch))], ...
        'Labels',{'Correct','Mismatch'});
ylabel('Percentile of activity');
% title('Boxplot')
[p, ~, stats] = ranksum(vals_correct, vals_mismatch);
fprintf('Wilcoxon rank-sum test correct vs mismatch: p = %.3g\n', p);
hold on; text(1.2,100,sprintf('P=%.3g\n', p));
% set(gca,'FontSize',16)
sgtitle([which_role ' correct vs mismatch ' rf_filter],'FontSize',18);

%% --- Heatmap: probability follower leads vs front/other neuron percentiles ---
which_role = 'follower';
sel_role = strcmp(which_role,T_combined.role);

% Define neuron groups based on receptive field location
is_front = (T_combined.angle > -60 & T_combined.angle < 60);
is_other = ~is_front;

% --- Extract percentile responses per trial for each neuron group ---
T_front = T_combined(sel_role & is_front,:);  % percentile across front neurons
T_other = T_combined(sel_role & is_other,:);  % percentile across other neurons

% --- Define percentiles (threshold ranges) ---
% range of critera
% k1min = .1; k1max = 0.5;
% k2min = .5; k2max = 0.9; 
k1min = .1; k1max = 0.9;  
k2min = .1; k2max = 0.9; 
n_k = 81;  % controls the granularity of the sampling
kVfront = linspace(k1min,k1max,n_k); % vector of kappa for pref
kVother = linspace(k2min,k2max,n_k); % vector of kappa for nonpref
[XF,XO] = meshgrid(kVfront,kVother);

x_range = kVfront*100;   % front activity percentile threshold
y_range = kVother*100;   % other activity percentile threshold

% --- Initialize heatmap matrix ---
lead_prob = nan(n_k, n_k);
N = nan(n_k,n_k);

% --- Compute leading probability for each percentile pair ---
for iy = 1:numel(y_range)
    for ix = 1:numel(x_range)
        T_front_sel = T_front(T_front.response < x_range(ix),:);
        T_other_sel = T_other(T_other.response > y_range(iy),:);
        T_sel = [T_front_sel;T_other_sel];
        N(iy,ix) = height(T_sel);
        lead_prob(iy, ix) = mean(T_sel.lead, 'omitnan');
    end
end

front_threshold_fraction = XF(:);
other_threshold_fraction = XO(:);

front_threshold_percentile = front_threshold_fraction * 100;
other_threshold_percentile = other_threshold_fraction * 100;

source_data = table( ...
    front_threshold_fraction, ...
    other_threshold_fraction, ...
    front_threshold_percentile, ...
    other_threshold_percentile, ...
    lead_prob(:), ...
    N(:), ...
    'VariableNames', ...
    {'FrontThresholdFraction','OtherThresholdFraction', ...
    'FrontThresholdPercentile','OtherThresholdPercentile', ...
    'LeadProbability','NTrials'});

source_data_trials_front = table( ...
    repmat({which_role},height(T_front),1), ...
    repmat({'front'},height(T_front),1), ...
    T_front.response, ...
    T_front.lead, ...
    T_front.angle, ...
    'VariableNames', ...
    {'Role','NeuronGroup','ResponsePercentile','Lead','Angle'});

source_data_trials_other = table( ...
    repmat({which_role},height(T_other),1), ...
    repmat({'other'},height(T_other),1), ...
    T_other.response, ...
    T_other.lead, ...
    T_other.angle, ...
    'VariableNames', ...
    {'Role','NeuronGroup','ResponsePercentile','Lead','Angle'});

source_data_trials = [source_data_trials_front; source_data_trials_other];

assignin('base','source_data',source_data);
assignin('base','source_data_trials',source_data_trials);

fig = figure;
hold on;
% imagesc(x_range/100, y_range/100, lead_prob);
pcolor(XF, XO, lead_prob);
% xticks(0.1:0.1:0.5);
% yticks(0.5:0.1:0.9);
xticks(0.1:0.1:0.9);
yticks(0.1:0.1:0.9);
set(gca,'TickDir','out','Box','off','FontSize',20);
% set(gca,'YDir','normal')
cm = viridis(100);
colormap(cm)
cb = colorbar;
clim([0.17 0.24])
% xlabel({'Percentile_{front}'; 'Response front RF < Percentile_{front}'});
% ylabel({'Percentile_{other}'; 'Response other RF > Percentile_{other}'});
xlabel('Percentile threshold (front RF)');
ylabel('Percentile threshold (other RF)');
% ylabel({'Other neuron activity > Percentile'});
title('Probability of followers lead');
axis square;
shading interp; % This interpolates colors across the faces of the cells
xlim([k1min k1max])
ylim([k2min k2max])

% stats for significant correlation between lead rate and front neuron response
modelspec1 = 'lead ~ response';
mdl_follower_lead_front = fitglm(T_front,modelspec1,'Distribution','binomial')

fprintf('\n========================================\n')
fprintf('Follower lead probability | front neurons\n')
fprintf('========================================\n')
fprintf('Model: lead ~ response\n')
fprintf('Distribution: binomial\n')
fprintf('N observations = %d\n', height(T_front))
disp(mdl_follower_lead_front.Coefficients)

text(0.5,0.13,sprintf('P=%.1e front neurons',mdl_follower_lead_front.Coefficients.pValue(2)),...
    "FontSize",16,'Color','w','HorizontalAlignment','center')

modelspec1 = 'lead ~ response';
mdl_follower_lead_other = fitglm(T_other,modelspec1,'Distribution','binomial')

fprintf('\n========================================\n')
fprintf('Follower lead probability | other neurons\n')
fprintf('========================================\n')
fprintf('Model: lead ~ response\n')
fprintf('Distribution: binomial\n')
fprintf('N observations = %d\n', height(T_other))
disp(mdl_follower_lead_other.Coefficients)

text(0.13,0.5,sprintf('P=%.1e other neurons',mdl_follower_lead_other.Coefficients.pValue(2)),...
    "FontSize",16,'Color','w','HorizontalAlignment','center','Rotation',90)

coef_front = mdl_follower_lead_front.Coefficients;
coef_other = mdl_follower_lead_other.Coefficients;

stats_front = table( ...
    repmat({which_role},height(coef_front),1), ...
    repmat({'front'},height(coef_front),1), ...
    coef_front.Properties.RowNames, ...
    coef_front.Estimate, ...
    coef_front.SE, ...
    coef_front.tStat, ...
    coef_front.pValue, ...
    'VariableNames', ...
    {'Role','NeuronGroup','Coefficient','Estimate','SE','TStat','PValue'});

stats_other = table( ...
    repmat({which_role},height(coef_other),1), ...
    repmat({'other'},height(coef_other),1), ...
    coef_other.Properties.RowNames, ...
    coef_other.Estimate, ...
    coef_other.SE, ...
    coef_other.tStat, ...
    coef_other.pValue, ...
    'VariableNames', ...
    {'Role','NeuronGroup','Coefficient','Estimate','SE','TStat','PValue'});

stats_table = [stats_front; stats_other];

assignin('base','stats_table',stats_table);
assignin('base','mdl_follower_lead_front',mdl_follower_lead_front);
assignin('base','mdl_follower_lead_other',mdl_follower_lead_other);

hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd '/plots/' hoy '_prob_follower_lead.pdf'];
% print(fig,figname,'-dpdf');
exportgraphics(fig, figname, 'ContentType', 'vector')

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('source_data_trials\n')
fprintf('stats_table\n')
fprintf('mdl_follower_lead_front\n')
fprintf('mdl_follower_lead_other\n')
%% bar plot of mean response when followers lead vs follow
m_colors = [194, 165, 207; 90, 174, 97] / 255;
which_role = 'follower'; r = 2;
sel_role = strcmp(which_role,T_combined.role);
fig = figure; 
rfs = {'front','side'};
% T_combined.response = T_combined.response*100;
for i = 1:2
    subplot(1,2,i); hold on;
    switch i
        case 1
            sel_rf = T_combined.angle > -60 & T_combined.angle < 60;
        case 2
            sel_rf = ~(T_combined.angle > -60 & T_combined.angle < 60);
    end
    T_sel = T_combined(sel_role & sel_rf,:);
    sel_lead = T_sel.response(T_sel.lead==1);
    sel_lead = sel_lead(~isnan(sel_lead));
    n_sel_lead = numel(sel_lead);
    sel_lead_mean = mean(sel_lead);
    sel_lead_se = std(sel_lead)/sqrt(n_sel_lead);
    
    sel_follow = T_sel.response(T_sel.follow==1);
    sel_follow = sel_follow(~isnan(sel_follow));
    n_sel_follow = numel(sel_follow);
    sel_follow_mean = mean(sel_follow);
    sel_follow_se = std(sel_follow)/sqrt(n_sel_follow);
    
    bar([1 2],[sel_lead_mean sel_follow_mean],'FaceColor',m_colors(r,:),'EdgeColor','none');
    errorbar(1,sel_lead_mean,sel_lead_se,[],'Color',m_colors(r,:),'LineWidth',2)
    errorbar(2,sel_follow_mean,sel_follow_se,[],'Color',m_colors(r,:),'LineWidth',2)
    xticks([1 2])
    xticklabels({[which_role ' lead']; [which_role ' follow']})
    ylabel('Mean percentile activity')
    title([rfs{i} ' RF neurons'])
    set(gca,'FontSize',18,'TickDir','out')
end
sgtitle([which_role ' response when lead or follow'],'FontSize',22,'FontWeight','bold')
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd '/plots/' hoy '_mean_activity_' which_role];
print(fig,figname,'-dpdf');

%% --- Heatmap: probability leader follows vs front/other neuron percentiles ---
which_role = 'leader';
sel_role = strcmp(which_role,T_combined.role);

% Define neuron groups based on receptive field location
is_front = T_combined.angle > -60 & T_combined.angle < 60;
is_other = ~is_front;

% --- Extract percentile responses per trial for each neuron group ---
T_front = T_combined(sel_role & is_front,:);  % percentile across front neurons
T_other = T_combined(sel_role & is_other,:);  % percentile across other neurons

% --- Define percentiles (threshold ranges) ---
% range of critera
k1min = .1; k1max = 0.9;  
k2min = .1; k2max = 0.9; 
n_k = 81;  % controls the granularity of the sampling
kVfront = linspace(k1min,k1max,n_k); % vector of kappa for pref
kVother = linspace(k2min,k2max,n_k); % vector of kappa for nonpref
[XF,XO] = meshgrid(kVfront,kVother);

x_range = kVfront*100;   % front activity percentile threshold
y_range = kVother*100;   % other activity percentile threshold

% --- Initialize heatmap matrix ---
follow_prob = nan(n_k, n_k);
N = nan(n_k,n_k);

% --- Compute leading probability for each percentile pair ---
for iy = 1:n_k
    for ix = 1:n_k
        T_front_sel = T_front(T_front.response < x_range(ix),:);
        T_other_sel = T_other(T_other.response > y_range(iy),:);
        T_sel = [T_front_sel;T_other_sel];
        N(iy,ix) = height(T_sel);
        follow_prob(iy, ix) = mean(T_sel.follow, 'omitnan');
    end
end

front_threshold_fraction = XF(:);
other_threshold_fraction = XO(:);

source_data = table( ...
    front_threshold_fraction, ...
    other_threshold_fraction, ...
    front_threshold_fraction*100, ...
    other_threshold_fraction*100, ...
    follow_prob(:), ...
    N(:), ...
    'VariableNames', ...
    {'FrontThresholdFraction','OtherThresholdFraction', ...
    'FrontThresholdPercentile','OtherThresholdPercentile', ...
    'FollowProbability','NTrials'});

source_data_trials_front = table( ...
    repmat({which_role},height(T_front),1), ...
    repmat({'front'},height(T_front),1), ...
    T_front.response, ...
    T_front.follow, ...
    T_front.angle, ...
    'VariableNames', ...
    {'Role','NeuronGroup','ResponsePercentile','Follow','Angle'});

source_data_trials_other = table( ...
    repmat({which_role},height(T_other),1), ...
    repmat({'other'},height(T_other),1), ...
    T_other.response, ...
    T_other.follow, ...
    T_other.angle, ...
    'VariableNames', ...
    {'Role','NeuronGroup','ResponsePercentile','Follow','Angle'});

source_data_trials = [source_data_trials_front; source_data_trials_other];

assignin('base','source_data',source_data);
assignin('base','source_data_trials',source_data_trials);

fig = figure;
% imagesc(x_range/100, y_range/100, lead_prob);
pcolor(XF, XO, follow_prob);
% xticks(0.5:0.1:0.9);
% yticks(0.1:0.1:0.5);
xticks(k1min:0.1:k1max);
yticks(k2min:0.1:k2max);
set(gca,'TickDir','out','Box','off','FontSize',20);
% set(gca,'YDir','normal')
cm = viridis(100); colormap(cm);
clim([0.22 0.27])
% colormap('turbo')
colorbar;
% xlabel({'Percentile_{front}'; 'Response front RF < Percentile_{front}'});
% ylabel({'Percentile_{other}'; 'Response other RF > Percentile_{other}'});
xlabel('Percentile threshold (front RF)');
ylabel('Percentile threshold (other RF)');
title('Probability of leaders follow');
axis square;
shading interp; % This interpolates colors across the faces of the cells

% stats for significant correlation between leader follow rate and front/other neuron response
modelspec1 = 'follow ~ response';
mdl_leader_follow_front = fitglm(T_front,modelspec1,'Distribution','binomial')

fprintf('\n========================================\n')
fprintf('Leader follow probability | front neurons\n')
fprintf('========================================\n')
fprintf('Model: follow ~ response\n')
fprintf('Distribution: binomial\n')
fprintf('N observations = %d\n', height(T_front))
disp(mdl_leader_follow_front.Coefficients)

modelspec1 = 'follow ~ response';
mdl_leader_follow_other = fitglm(T_other,modelspec1,'Distribution','binomial')

fprintf('\n========================================\n')
fprintf('Leader follow probability | other neurons\n')
fprintf('========================================\n')
fprintf('Model: follow ~ response\n')
fprintf('Distribution: binomial\n')
fprintf('N observations = %d\n', height(T_other))
disp(mdl_leader_follow_other.Coefficients)

T_role = T_combined(sel_role,:);
T_role.front = ones(height(T_role),1);
T_role.front = T_role.angle > -60 & T_role.angle < 60;
mdl_int = fitglm(T_role,'follow ~ 1 + response*front','Distribution','binomial')

fprintf('\n========================================\n')
fprintf('Leader follow probability | interaction model\n')
fprintf('========================================\n')
fprintf('Model: follow ~ 1 + response*front\n')
fprintf('Distribution: binomial\n')
fprintf('N observations = %d\n', height(T_role))
disp(mdl_int.Coefficients)

text(0.5,0.13,sprintf('P=%.1e front neurons',mdl_leader_follow_front.Coefficients.pValue(2)),...
    "FontSize",16,'Color','w','HorizontalAlignment','center')
text(0.13,0.5,sprintf('P=%.1e other neurons',mdl_leader_follow_other.Coefficients.pValue(2)),...
    "FontSize",16,'Color','w','HorizontalAlignment','center','Rotation',90)

coef_front = mdl_leader_follow_front.Coefficients;
coef_other = mdl_leader_follow_other.Coefficients;
coef_int = mdl_int.Coefficients;

stats_front = table( ...
    repmat({which_role},height(coef_front),1), ...
    repmat({'front'},height(coef_front),1), ...
    coef_front.Properties.RowNames, ...
    coef_front.Estimate, ...
    coef_front.SE, ...
    coef_front.tStat, ...
    coef_front.pValue, ...
    'VariableNames', ...
    {'Role','NeuronGroup','Coefficient','Estimate','SE','TStat','PValue'});

stats_other = table( ...
    repmat({which_role},height(coef_other),1), ...
    repmat({'other'},height(coef_other),1), ...
    coef_other.Properties.RowNames, ...
    coef_other.Estimate, ...
    coef_other.SE, ...
    coef_other.tStat, ...
    coef_other.pValue, ...
    'VariableNames', ...
    {'Role','NeuronGroup','Coefficient','Estimate','SE','TStat','PValue'});

stats_int = table( ...
    repmat({which_role},height(coef_int),1), ...
    repmat({'interaction'},height(coef_int),1), ...
    coef_int.Properties.RowNames, ...
    coef_int.Estimate, ...
    coef_int.SE, ...
    coef_int.tStat, ...
    coef_int.pValue, ...
    'VariableNames', ...
    {'Role','NeuronGroup','Coefficient','Estimate','SE','TStat','PValue'});

stats_table = [stats_front; stats_other; stats_int];

assignin('base','stats_table',stats_table);
assignin('base','mdl_leader_follow_front',mdl_leader_follow_front);
assignin('base','mdl_leader_follow_other',mdl_leader_follow_other);
assignin('base','mdl_int',mdl_int);

hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd '/plots/' hoy '_prob_leader_follow.pdf'];
% print(fig,figname,'-dpdf');
exportgraphics(fig, figname, 'ContentType', 'vector')

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('source_data_trials\n')
fprintf('stats_table\n')
fprintf('mdl_leader_follow_front\n')
fprintf('mdl_leader_follow_other\n')
fprintf('mdl_int\n')
%% bar plots beta coefficients leadership
m_colors = [194, 165, 207; 90, 174, 97] / 255;

betas = [mdl_follower_lead_front.Coefficients.Estimate(2), ...
    mdl_follower_lead_other.Coefficients.Estimate(2), ...
    mdl_leader_follow_front.Coefficients.Estimate(2), ...
    mdl_leader_follow_other.Coefficients.Estimate(2)]*100;

SEs = [mdl_follower_lead_front.Coefficients.SE(2), ...
    mdl_follower_lead_other.Coefficients.SE(2), ...
    mdl_leader_follow_front.Coefficients.SE(2), ...
    mdl_leader_follow_other.Coefficients.SE(2)]*100;

pvals = [mdl_follower_lead_front.Coefficients.pValue(2), ...
    mdl_follower_lead_other.Coefficients.pValue(2), ...
    mdl_leader_follow_front.Coefficients.pValue(2), ...
    mdl_leader_follow_other.Coefficients.pValue(2)];

source_data = table( ...
    {'Follower lead';'Follower lead';'Leader follow';'Leader follow'}, ...
    {'Front RF';'Other RF';'Front RF';'Other RF'}, ...
    betas(:), ...
    SEs(:), ...
    pvals(:), ...
    'VariableNames', ...
    {'Behavior','NeuronGroup','Beta_x100','SE_x100','PValue'});

assignin('base','source_data',source_data);

stats_table = source_data;
assignin('base','stats_table',stats_table);

fprintf('\n========================================\n')
fprintf('Impact of trial-by-trial activity on leadership\n')
fprintf('========================================\n')
disp(stats_table)

fig = figure;
hold on;

x = [0.8 1.2 1.8 2.2];

b = bar(x(1:2),betas(1:2),'FaceColor',m_colors(2,:),'EdgeColor','none'); 
errorbar(0.8,betas(1),SEs(1),[],'Color',m_colors(2,:),'LineWidth',2);
errorbar(1.2,betas(2),[],SEs(2),'Color',m_colors(2,:),'LineWidth',2);

b = bar(x(3:4),betas(3:4),'FaceColor',m_colors(1,:),'EdgeColor','none'); 
errorbar(1.8,betas(3),[],SEs(3),'Color',m_colors(1,:),'LineWidth',2);
errorbar(2.2,betas(4),[],SEs(4),'Color',m_colors(1,:),'LineWidth',2);

xticks([1 2])
xticklabels({'Follower lead';'Leader follow'})
ylabel('Regression weights (log odds)')
title('Impact of trial-by-trial activity on leadership')
set(gca,'FontSize',20,'TickDir','out')

figname = [fd '/plots/' hoy '_leadership_prob_weights'];
print(fig,figname,'-dpdf');

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

%% --- Heatmap: error rate vs follower front/other neuron percentiles ---

which_role = 'follower';
sel_role = strcmp(which_role,T_combined.role);

% Define neuron groups based on receptive field location
is_front = (T_combined.angle > -60 & T_combined.angle < 60);
is_other = ~is_front;

% --- Extract percentile responses per trial for each neuron group ---
T_front = T_combined(sel_role & is_front,:);  % percentile across front neurons
T_other = T_combined(sel_role & is_other,:);  % percentile across other neurons

% --- Define percentiles (threshold ranges) ---
% range of critera
% k1min = .1; k1max = 0.5;
% k2min = .5; k2max = 0.9; 
k1min = .1; k1max = 0.9;  
k2min = .1; k2max = 0.9; 
n_k = 81;  % controls the granularity of the sampling
kVfront = linspace(k1min,k1max,n_k); % vector of kappa for pref
kVother = linspace(k2min,k2max,n_k); % vector of kappa for nonpref
[XF,XO] = meshgrid(kVfront,kVother);

x_range = kVfront*100;   % front activity percentile threshold
y_range = kVother*100;   % other activity percentile threshold

% --- Initialize heatmap matrix ---
err_prob = nan(n_k, n_k);
N = nan(n_k,n_k);

% --- Compute leading probability for each percentile pair ---
for iy = 1:numel(y_range)
    for ix = 1:numel(x_range)
        T_front_sel = T_front(T_front.response < x_range(ix),:);
        T_other_sel = T_other(T_other.response > y_range(iy),:);
        T_sel = [T_front_sel;T_other_sel];
        N(iy,ix) = height(T_sel);
        err_prob(iy, ix) = mean(T_sel.mismatch, 'omitnan');
    end
end

source_data = table( ...
    XF(:), ...
    XO(:), ...
    XF(:)*100, ...
    XO(:)*100, ...
    err_prob(:), ...
    N(:), ...
    'VariableNames', ...
    {'FrontThresholdFraction','OtherThresholdFraction', ...
    'FrontThresholdPercentile','OtherThresholdPercentile', ...
    'ErrorProbability','NTrials'});

source_data_trials_front = table( ...
    repmat({which_role},height(T_front),1), ...
    repmat({'front'},height(T_front),1), ...
    T_front.response, ...
    T_front.mismatch, ...
    T_front.angle, ...
    'VariableNames', ...
    {'Role','NeuronGroup','ResponsePercentile','Mismatch','Angle'});

source_data_trials_other = table( ...
    repmat({which_role},height(T_other),1), ...
    repmat({'other'},height(T_other),1), ...
    T_other.response, ...
    T_other.mismatch, ...
    T_other.angle, ...
    'VariableNames', ...
    {'Role','NeuronGroup','ResponsePercentile','Mismatch','Angle'});

source_data_trials = [source_data_trials_front; source_data_trials_other];

assignin('base','source_data',source_data);
assignin('base','source_data_trials',source_data_trials);

fig = figure;
% imagesc(x_range/100, y_range/100, lead_prob);
pcolor(XF, XO, err_prob);
% xticks(0.1:0.1:0.5);
% yticks(0.5:0.1:0.9);
xticks(0.1:0.1:0.9);
yticks(0.1:0.1:0.9);
set(gca,'TickDir','out','Box','off','FontSize',20);
% set(gca,'YDir','normal')
cm = viridis(100);
colormap(cm)
clim([0.055 0.08])
cb = colorbar;
% xlabel({'Percentile_{front}'; 'Response front RF < Percentile_{front}'});
% ylabel({'Percentile_{other}'; 'Response other RF > Percentile_{other}'});
xlabel('Percentile threshold (front RF)');
ylabel('Percentile threshold (other RF)');
% ylabel({'Other neuron activity > Percentile'});
title('Error rate vs follower neuron response');
axis square;
shading interp; % This interpolates colors across the faces of the cells

% stats
modelspec1 = 'mismatch ~ response';
mdl_follower_error_front = fitglm(T_front,modelspec1,'Distribution','binomial')

fprintf('\nFollower error | front neurons\n')
fprintf('Model: mismatch ~ response, binomial GLM\n')
fprintf('N observations = %d\n',height(T_front))
disp(mdl_follower_error_front.Coefficients)

modelspec1 = 'mismatch ~ response';
mdl_follower_error_other = fitglm(T_other,modelspec1,'Distribution','binomial')

fprintf('\nFollower error | other neurons\n')
fprintf('Model: mismatch ~ response, binomial GLM\n')
fprintf('N observations = %d\n',height(T_other))
disp(mdl_follower_error_other.Coefficients)

coef_front = mdl_follower_error_front.Coefficients;
coef_other = mdl_follower_error_other.Coefficients;

stats_front = table( ...
    repmat({which_role},height(coef_front),1), ...
    repmat({'front'},height(coef_front),1), ...
    coef_front.Properties.RowNames, ...
    coef_front.Estimate, ...
    coef_front.SE, ...
    coef_front.tStat, ...
    coef_front.pValue, ...
    'VariableNames', ...
    {'Role','NeuronGroup','Coefficient','Estimate','SE','TStat','PValue'});

stats_other = table( ...
    repmat({which_role},height(coef_other),1), ...
    repmat({'other'},height(coef_other),1), ...
    coef_other.Properties.RowNames, ...
    coef_other.Estimate, ...
    coef_other.SE, ...
    coef_other.tStat, ...
    coef_other.pValue, ...
    'VariableNames', ...
    {'Role','NeuronGroup','Coefficient','Estimate','SE','TStat','PValue'});

stats_table = [stats_front; stats_other];

assignin('base','stats_table',stats_table);
assignin('base','mdl_follower_error_front',mdl_follower_error_front);
assignin('base','mdl_follower_error_other',mdl_follower_error_other);

text(0.5,0.13,sprintf('P=%.1e front neurons',mdl_follower_error_front.Coefficients.pValue(2)),...
    "FontSize",16,'Color','w','HorizontalAlignment','center')
text(0.13,0.5,sprintf('P=%.1e other neurons',mdl_follower_error_other.Coefficients.pValue(2)),...
    "FontSize",16,'Color','w','HorizontalAlignment','center','Rotation',90)
figname = [fd '/plots/' hoy '_error_rate_follower.pdf'];
% print(fig,figname,'-dpdf');
exportgraphics(fig, figname, 'ContentType', 'vector')

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('source_data_trials\n')
fprintf('stats_table\n')
fprintf('mdl_follower_error_front\n')
fprintf('mdl_follower_error_other\n')

%% --- Heatmap: error rate vs leader front/other neuron percentiles ---

which_role = 'leader';
sel_role = strcmp(which_role,T_combined.role);

% Define neuron groups based on receptive field location
is_front = T_combined.angle > -60 & T_combined.angle < 60;
is_other = ~is_front;

% --- Extract percentile responses per trial for each neuron group ---
T_front = T_combined(sel_role & is_front,:);  % percentile across front neurons
T_other = T_combined(sel_role & is_other,:);  % percentile across other neurons

% --- Define percentiles (threshold ranges) ---
% range of critera
k1min = .1; k1max = 0.9;  
k2min = .1; k2max = 0.9; 
n_k = 81;  % controls the granularity of the sampling
kVfront = linspace(k1min,k1max,n_k); % vector of kappa for pref
kVother = linspace(k2min,k2max,n_k); % vector of kappa for nonpref
[XF,XO] = meshgrid(kVfront,kVother);

x_range = kVfront*100;   % front activity percentile threshold
y_range = kVother*100;   % other activity percentile threshold

% --- Initialize heatmap matrix ---
err_prob = nan(n_k, n_k);
N = nan(n_k,n_k);

% --- Compute leading probability for each percentile pair ---
for iy = 1:n_k
    for ix = 1:n_k
        T_front_sel = T_front(T_front.response < x_range(ix),:);
        T_other_sel = T_other(T_other.response > y_range(iy),:);
        T_sel = [T_front_sel;T_other_sel];
        N(iy,ix) = height(T_sel);
        err_prob(iy, ix) = mean(T_sel.mismatch, 'omitnan');
    end
end

source_data = table( ...
    XF(:), ...
    XO(:), ...
    XF(:)*100, ...
    XO(:)*100, ...
    err_prob(:), ...
    N(:), ...
    'VariableNames', ...
    {'FrontThresholdFraction','OtherThresholdFraction', ...
    'FrontThresholdPercentile','OtherThresholdPercentile', ...
    'ErrorProbability','NTrials'});

source_data_trials_front = table( ...
    repmat({which_role},height(T_front),1), ...
    repmat({'front'},height(T_front),1), ...
    T_front.response, ...
    T_front.mismatch, ...
    T_front.angle, ...
    'VariableNames', ...
    {'Role','NeuronGroup','ResponsePercentile','Mismatch','Angle'});

source_data_trials_other = table( ...
    repmat({which_role},height(T_other),1), ...
    repmat({'other'},height(T_other),1), ...
    T_other.response, ...
    T_other.mismatch, ...
    T_other.angle, ...
    'VariableNames', ...
    {'Role','NeuronGroup','ResponsePercentile','Mismatch','Angle'});

source_data_trials = [source_data_trials_front; source_data_trials_other];

assignin('base','source_data',source_data);
assignin('base','source_data_trials',source_data_trials);

fig = figure;
% imagesc(x_range/100, y_range/100, lead_prob);
pcolor(XF, XO, err_prob);
% xticks(0.5:0.1:0.9);
% yticks(0.1:0.1:0.5);
xticks(k1min:0.1:k1max);
yticks(k2min:0.1:k2max);
set(gca,'TickDir','out','Box','off','FontSize',20);
% set(gca,'YDir','normal')
cm = viridis(100);
colormap(cm)
cb = colorbar;
clim([0.048 0.072])
cb.Ticks = [0.048 0.072];
% cb.TickLabels = {'0.048', '0.072'};
% xlabel({'Percentile_{front}'; 'Response front RF > Percentile_{front}'});
% ylabel({'Percentile_{other}'; 'Response other RF > Percentile_{other}'});
xlabel('Percentile threshold (front RF)');
ylabel('Percentile threshold (other RF)');
% ylabel({'Other neuron activity > Percentile'});
title('Error rate vs leader neuron response');
axis square;
shading interp; % This interpolates colors across the faces of the cells

% stats
modelspec1 = 'mismatch ~ response';
mdl_leader_error_front = fitglm(T_front,modelspec1,'Distribution','binomial')

fprintf('\nLeader error | front neurons\n')
fprintf('Model: mismatch ~ response, binomial GLM\n')
fprintf('N observations = %d\n',height(T_front))
disp(mdl_leader_error_front.Coefficients)

modelspec1 = 'mismatch ~ response';
mdl_leader_error_other = fitglm(T_other,modelspec1,'Distribution','binomial')

fprintf('\nLeader error | other neurons\n')
fprintf('Model: mismatch ~ response, binomial GLM\n')
fprintf('N observations = %d\n',height(T_other))
disp(mdl_leader_error_other.Coefficients)

coef_front = mdl_leader_error_front.Coefficients;
coef_other = mdl_leader_error_other.Coefficients;

stats_front = table( ...
    repmat({which_role},height(coef_front),1), ...
    repmat({'front'},height(coef_front),1), ...
    coef_front.Properties.RowNames, ...
    coef_front.Estimate, ...
    coef_front.SE, ...
    coef_front.tStat, ...
    coef_front.pValue, ...
    'VariableNames', ...
    {'Role','NeuronGroup','Coefficient','Estimate','SE','TStat','PValue'});

stats_other = table( ...
    repmat({which_role},height(coef_other),1), ...
    repmat({'other'},height(coef_other),1), ...
    coef_other.Properties.RowNames, ...
    coef_other.Estimate, ...
    coef_other.SE, ...
    coef_other.tStat, ...
    coef_other.pValue, ...
    'VariableNames', ...
    {'Role','NeuronGroup','Coefficient','Estimate','SE','TStat','PValue'});

stats_table = [stats_front; stats_other];

assignin('base','stats_table',stats_table);
assignin('base','mdl_leader_error_front',mdl_leader_error_front);
assignin('base','mdl_leader_error_other',mdl_leader_error_other);

text(0.5,0.13,sprintf('P=%.1e front neurons',mdl_leader_error_front.Coefficients.pValue(2)),...
    "FontSize",16,'Color','w','HorizontalAlignment','center')
text(0.13,0.5,sprintf('P=%.1e other neurons',mdl_leader_error_other.Coefficients.pValue(2)),...
    "FontSize",16,'Color','w','HorizontalAlignment','center','Rotation',90)
figname = [fd '/plots/' hoy '_error_rate_leader.pdf'];
% print(fig,figname,'-dpdf');
exportgraphics(fig, figname, 'ContentType', 'vector')

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('source_data_trials\n')
fprintf('stats_table\n')
fprintf('mdl_leader_error_front\n')
fprintf('mdl_leader_error_other\n')

%% bar plots beta coefficients for error rate
m_colors = [194, 165, 207; 90, 174, 97] / 255;
fig = figure;
hold on;
betas = [mdl_follower_error_front.Coefficients.Estimate(2), 
    mdl_follower_error_other.Coefficients.Estimate(2),
    mdl_leader_error_front.Coefficients.Estimate(2),
    mdl_leader_error_other.Coefficients.Estimate(2)]*100;
SEs = [mdl_follower_error_front.Coefficients.SE(2), 
    mdl_follower_error_other.Coefficients.SE(2),
    mdl_leader_error_front.Coefficients.SE(2),
    mdl_leader_error_other.Coefficients.SE(2)]*100;
pvals = [mdl_follower_error_front.Coefficients.pValue(2), 
    mdl_follower_error_other.Coefficients.pValue(2),
    mdl_leader_error_front.Coefficients.pValue(2),
    mdl_leader_error_other.Coefficients.pValue(2)];
source_data = table( ...
    {'Follower';'Follower';'Leader';'Leader'}, ...
    {'Front';'Other';'Front';'Other'}, ...
    betas(:), ...
    SEs(:), ...
    pvals(:), ...
    'VariableNames', ...
    {'Role','NeuronGroup','Beta_x100','SE_x100','PValue'});
stats_table = source_data;
assignin('base','source_data',source_data);
assignin('base','stats_table',stats_table);

fprintf('\nError rate beta weights\n')
disp(stats_table)

x = [0.8 1.2 1.8 2.2];
b = bar(x(1:2),betas(1:2),'FaceColor',m_colors(2,:),'EdgeColor','none'); 
errorbar(0.8,betas(1),[],SEs(1),'Color',m_colors(2,:),'LineWidth',2);
errorbar(1.2,betas(2),[],SEs(2),'Color',m_colors(2,:),'LineWidth',2);

b = bar(x(3:4),betas(3:4),'FaceColor',m_colors(1,:),'EdgeColor','none'); 
errorbar(1.8,betas(3),SEs(3),[],'Color',m_colors(1,:),'LineWidth',2);
errorbar(2.2,betas(4),[],SEs(4),'Color',m_colors(1,:),'LineWidth',2);
xticks([1 2])
ylim([-0.8 0.8])
xticklabels({'Follower';'Leader'})
ylabel('Regression weights (log odds)')
title('Impact of trial-by-trial activity on error rate')
set(gca,'FontSize',20,'TickDir','out')
figname = [fd '/plots/' hoy '_error_rate_weights'];
print(fig,figname,'-dpdf');

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

%% 
mismatch_rate = zeros(1,10);
for i = 1:10
    cur_sel = T_front.response <= i*10 & T_front.response > (i-1)*10;
    mismatch_rate(i) = mean(T_front.mismatch(cur_sel),"omitmissing");
end
