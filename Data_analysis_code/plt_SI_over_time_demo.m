function plt_SI_over_time_demo(fd)
%%
% mrtable_leadership = load([fd 'Data/mrtable_leadership_selfarr_selfarr+30.mat']).mrtable;
mrtable_leadership = load([fd 'Data/mrtable_leadership_selfarr_selfarr+30_regout_spd&pos_self.mat']).mrtable;
mrtable_si_array = load([fd 'Data/mrtable_si_over_time.mat']).mrtable;

mrtable = [mrtable_si_array mrtable_leadership(:,'p_leader')];

params.fd = fd;
params.pcut = 0.05;
params.selective_only = 1;
params.alignBy = 'SelfArrival'; 
params.t_array_sel = -60:90;

source_data = table();
stats_table = table();

params.role = 'leader';
[~,source_data_leader,stats_table_leader] = plt_SI_over_time_cohort(mrtable,params);

params.role = 'follower';
[~,source_data_follower,stats_table_follower] = plt_SI_over_time_cohort(mrtable,params);

source_data = [source_data; source_data_leader; source_data_follower];
stats_table = [stats_table; stats_table_leader; stats_table_follower];

assignin('base','source_data',source_data);
assignin('base','stats_table',stats_table);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end