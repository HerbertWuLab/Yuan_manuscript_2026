function plt_example_position_neuron_demo(fd)
%% plot example neurons from allocentric and egocentric frame of reference
animals = {'YC069'};
dates = {'20240601'};
cell_num = 6;
n_cells = length(cell_num);
for i = 1:n_cells
    clear params
    animal = animals{i};
    cur_date = dates{i};
    params.animal = animal;
    params.fd = fd;
    params.date = cur_date;    
    params.role = get_role_demo(animal);
    params.pcut = 0.05;
    positions = {'self','other','other_allo','other_ego'};
    max_distances = [20,20,35,35];
    params.spatial_binsize = 5;
    params.id = get_mouse_id(animal); 
    params.which_frames = 'both_outside_arrival_zone';
    for p = 1:4
        params.which_pos = positions{p};
        params.max_dist = max_distances(p);
        spk = load([fd 'Data/' animal '/' cur_date '/' animal '_' cur_date '_spk_data_GC6_25ms.mat']).spike_prob; % n_cells x n_frames
        ftable = load([fd 'Data/' animal '/' cur_date '/' animal '_' cur_date '_ftable.mat']).ftable;
        stable_sel = load([fd 'Data/' animal '/' cur_date '/' animal '_' cur_date '_stable_sel.mat']).stable_sel;
        params.roi_range = cell_num(i);
        [rtable,params] = get_spatial_selectivity_demo(stable_sel,ftable,spk,params); % normal plots
    end
end

