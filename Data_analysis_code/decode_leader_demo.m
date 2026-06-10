function decode_leader_demo(fd)

dc_table = load([fd 'Data/dc_table_leadership_log_reg_alignBy_SelfArrival.mat']).dc_table;
params.fd = '/Users/herbert/Wulab Dropbox/Lab/Yuan/imaging_analysis/';
params.alignBy = 'SelfArrival'; 
params.role = 'both_per_animal';
params.t_array_binned = -60:3:87;
params.Ninput = 100;
plt_leadership_decoding_v2(dc_table, params);
