function plt_choice_SI_demo(fd)
% plot choice SIs

params.pcut = 0.05;
mrtable = load([fd 'Data/mrtable_choice_end-15_end+15.mat']).mrtable;
params.time_bin = {'led_end-15';'led_end+15'};
sel_leader = strcmp(mrtable.role,'leader');
mrtable_lead = mrtable(sel_leader,:);
mean(mrtable_lead.p_self_choice<params.pcut)
params.fd = '/Users/herbert/Wulab Dropbox/Lab/Yuan/imaging_analysis/';
params.role = 'leader';
plt_choice_stats_demo(mrtable_lead,params);

sel_follower = strcmp(mrtable.role,'follower');
mrtable_foll = mrtable(sel_follower,:);
mean(mrtable_foll.p_self_choice<params.pcut)
params.role = 'follower';
plt_choice_stats_demo(mrtable_foll,params);

[h,p,stats] = ranksum(mrtable_foll.SI_self_choice, mrtable_lead.SI_self_choice)