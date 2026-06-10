function plt_example_choice_neuron_demo(fd)
% plot example neurons
%%
filelist = dir([fd 'Data/YC070/']);
sel_dir = filelist.isdir;
sel_data_fd = ~ismember({filelist.name}, {'.', '..','.DS_Store','plots','registration'});
fd_list = filelist(sel_dir & sel_data_fd); % get folders only
n_fd = length(fd_list);
clear params
idx_fd = 1; % change to the first folder
cur_fd_prefix = fd_list(idx_fd).folder;
cur_date = fd_list(idx_fd).name;
cur_fd = fullfile(cur_fd_prefix,cur_date);
animal_str_idx = strfind(cur_fd,'YC');
cur_animal = cur_fd(animal_str_idx:animal_str_idx+4);
params.animal = cur_animal;
params.fd = fd;
params.date = cur_date;
params.id = get_mouse_id(cur_fd); 
params.role = get_role_demo(cur_animal);
dff = load([cur_fd '/' cur_animal '_' cur_date '_f_data.mat']).dff;
stable_sel = load([cur_fd '/' cur_animal '_' cur_date '_stable_sel.mat']).stable_sel;

% keep short trials for plotting purpose
stable_sel = stable_sel(stable_sel.dur_f<150,:);

% get f_array and mask aligned by alignBy
finput = dff'; % transpose to n_frames x n_cells
params.alignBy = 'TrialEnd'; % TrialStart, m1Arrival, m2Arrival, TrialEnd
[f_array, mask, params] = get_f_array_v2(finput, stable_sel, params);

params.cell_list = 28; % example cell in YC070 20240522
% plot trial-by-trial dff
params.mask_opt = 'off'; % remove datapoints outside a trial?
params.sortBy = 'SelfZone';
plt_f_byTrial_demo(f_array,mask,stable_sel,params);

% % plot mean dff and SEM
params.val_trial_cutoff = 2; % minimal no. of trials in a group
plt_mean_f_demo(f_array,mask,stable_sel,params);

