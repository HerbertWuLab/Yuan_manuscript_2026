function plt_position_tuning_demo(fd)
% plot angle tuning and distance tuning by role for phase 4a
mrtable = load([fd 'Data/mrtable_4a_other_ego_both_outside_arrival_zone_svc_tuning.mat']).mrtable;
params.pcut = 0.05;
uni_roles = unique(mrtable.role);
n_uni_roles = length(uni_roles);
% for a = 1:2
for a = 2
    cur_role = uni_roles{a};
    sel_role = strcmp(mrtable.role,cur_role);
    params.role = cur_role;  
    mrtable_sel_role = mrtable(sel_role,:);
    params.phase = '4a';
    params.which_frames = 'both_outside_arrival_zone';
    params.which2plot = [cur_role '_' params.phase];
    params.n_bins_angle = 15; 
    params.n_bins_dist = 7;
    params.max_dist = 35;  
    params.min_dist = 0;
    params.spatial_binsize = 5;
    params.pcut = 0.05;
    params.fd = fd;
    [fig_angle,fig_dist] = plt_svc_tuning_demo(mrtable_sel_role,params); % plot phase 4d
end
%%
mrtable = load([fd 'Data/mrtable_4d_other_ego_both_outside_arrival_zone_svc_tuning.mat']).mrtable;
% for a = 1:2
    for a = 1
    cur_role = uni_roles{a};
    sel_role = strcmp(mrtable.role,cur_role);
    params.role = cur_role;  
    mrtable_sel_role = mrtable(sel_role,:);
    params.phase = '4d';
    params.which_frames = 'both_outside_arrival_zone';
    params.which2plot = [cur_role '_' params.phase];
    params.n_bins_angle = 15; 
    params.n_bins_dist = 7;
    params.max_dist = 35;  
    params.min_dist = 0;
    params.spatial_binsize = 5;
    params.pcut = 0.05;
    params.fd = fd;
    [fig_angle,fig_dist] = plt_svc_tuning_demo(mrtable_sel_role,params); % plot phase 4d
end