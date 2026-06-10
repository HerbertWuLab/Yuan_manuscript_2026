function plt_pos_control_demo(fd)
pos_table = load([fd 'Data/pos_table.mat']).pos_table;
params.fd = fd;
params.role = 'both';
fig = plot_pos_time_cohort_demo(pos_table,params);