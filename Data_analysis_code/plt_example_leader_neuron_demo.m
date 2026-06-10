function plt_example_leader_neuron_demo(fd)

%% plot example neurons with phase 4a data
animals = {'YC069','YC069','YC074','YC072'};
dates = {'20240601';'20240602';'20240806';'20240806'};
cell_num = [37,39,35,24];
for i = 1:4
    clear params
    animal = animals{i};
    cur_date = dates{i};
    params.animal = animal;
    params.fd = fd;
    params.date = cur_date;    
    params.id = get_mouse_id(animal); 
    params.role = get_role_demo(animal);
    dff = load([fd 'Data/' animal '/' cur_date '/' animal '_' cur_date '_f_data.mat']).dff;

    % load stable_sel
    stable_sel = load([fd 'Data/' animal '/' cur_date '/' animal '_' cur_date '_stable_sel.mat']).stable_sel;

    % keep short trials for plotting purpose
    stable_sel.self_rt = stable_sel.([params.id '_last_arr']) - stable_sel.led_init;
    stable_sel.self_wait = stable_sel.led_end - stable_sel.([params.id '_last_arr']);
    sel_trials = ~isnan(stable_sel.([params.id '_last_arr'])) & stable_sel.self_rt < 90 ...
        & stable_sel.self_wait < 100; 
    stable_sel = stable_sel(sel_trials,:);

    % get f_array and mask aligned by alignBy
    finput = dff'; % transpose to n_frames x n_cells

    % params.alignBy = 'TrialEnd'; 
    params.alignBy = 'SelfArrival'; % TrialStart, SelfArrival, OtherArrival, TrialEnd
    [f_array, mask, params] = get_f_array_v2(finput, stable_sel, params);
    % params.t_range = [-90 90];

    % plot trial-by-trial dff
    params.mask_opt = 'off'; % remove datapoints outside a trial?
    % params.sortBy = 'SelfZone & Leader';  % plot self arrival zone separately
    params.sortBy = 'Leader'; 
    % params.cell_list = 37; % YC069 20240601 follower prefer other lead
    % params.cell_list = 39; % YC069 20240602 follower prefer self lead
    % params.cell_list = 35; % YC074 20240806 leader prefer other lead idx_fd = 4
    % params.cell_list = 24; % YC072 20240806 leader prefer other lead idx_fd = 4
    params.cell_list = cell_num(i);
    plt_f_byTrial_v1(f_array,mask,stable_sel,params);

    % plot mean dff and SEM
    params.val_trial_cutoff = 2; % minimal no. of trials in a group
    plt_mean_f_v1(f_array,mask,stable_sel,params);
end