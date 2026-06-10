function plt_spd_control_demo(fd)

spd_table = load([fd 'Data/spd_table_remove_st=selfarr.mat']).spd_table;
params.fd = fd;
params.role = 'both';
fig = plt_spd_time_cohort_demo(spd_table,params);