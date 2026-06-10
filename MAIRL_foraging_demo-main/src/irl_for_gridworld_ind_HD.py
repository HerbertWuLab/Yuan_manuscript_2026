# Modified based on irl_for_girdworld.py
# Assuming individual agents act independently
# Y.C. May 2024

import os
import numpy as np
import pickle
from src.helpers import init_diff_map
from src.optimize_weights import getMAP_weights
from src.optimize_goal_maps import getMAP_goalmaps
from src.compute_validation_ll import get_validation_ll


def fit_irl_gridworld_ind_HD(num_trajs, lr_maps, max_iters, gamma, N_MAPS_INDIVIDUAL, N_MAPS_INTERACTION,
                      seed, GEN_DIR_NAME, save_dir, lam1=5, lam2=1, TAG_TRAIN=0, info={'Neval': 0}):
    """ fits IRL on simulated trajectories from the gridworld environment given hyperparameters
        and saves all recovered parameters
        Fit two agents one by one
        Modified for a collaborative task (Y.C. April 2024)

        args:
        version (int): choose which version of the simulated trajectories to use
        num_trajs (int): choose how many trajectories to use
        lr_weights (float): choose learning rate for weights
        lr_maps (float): choose learning rate for goal maps
        max_iters (int): num iterations to run the optimization for weights/goal maps per outer loop of dirl
        gamma (float): value iteration discount parameter
        N_MAPS_INTERACTION (int): # of joint maps [\phi]
        N_MAPS_INDIVIDUAL (int): # of individual maps per agent (default to 1)
        seed (int): initialization seed
        GEN_DIR_NAME (str): name of the folder that contains the trajectories and generative parameters
        REC_DIR_NAME (str): name of the folder to store recovered parameters
        TAG_TRAIN: (default: 0) controls which model to fit (0: centralized control, 1: independent control, 2: independent control with prediction)
    """
    np.random.seed(seed)
    # load the files to obtain the simulated trajectories from
    file = open(GEN_DIR_NAME + '/generative_parameters.pickle', 'rb')
    file_trajs = open(GEN_DIR_NAME +'/expert_trajectories.pickle', 'rb')

    # loading some relevant generative parameters known to the inference algorithm
    N_MAPS = 2*N_MAPS_INDIVIDUAL + N_MAPS_INTERACTION
    generative_params = pickle.load(file)
    sigma = generative_params['sigmas'] 
    sigmas = [sigma] * N_MAPS
    P_a = generative_params['P_a'] 
    N = int(np.sqrt(P_a.shape[0]))
    N_ACTIONS = int(np.sqrt(P_a.shape[1]))
    N_ANGLES = int(360/generative_params['angle_bin'])

    # check if save_dir exists, else create it 
    agent = info['SingleAgent']
    save_dir_agent = save_dir + "agent_{}".format(agent)
    if not os.path.isdir(save_dir_agent):
        os.makedirs(save_dir_agent, exist_ok = True)
    print(save_dir_agent)

    # load expert trajs
    all_expert_trajectories = pickle.load(file_trajs)
    N_traj = min(len(all_expert_trajectories), num_trajs)
    all_expert_trajectories = all_expert_trajectories[:N_traj]
    print("Loaded "+str(N_traj)+" expert trajectories for gridworld!", flush=True)
    T = len(all_expert_trajectories[0]["actions"])
    print("Using "+str(T)+" state-action pairs per trajectory.", flush=True)

    # prepare 'expert_trajectories' to only have one agent's action and angles
    all_expert_trajectories_single = []
    for traj in all_expert_trajectories:
        joint_action = traj['actions']
        joint_angle = traj['angles']
        if agent == 1:
            traj['actions'] = [a // N_ACTIONS for a in joint_action]
            traj['angles'] = [a // N_ANGLES for a in joint_angle]
        elif agent == 2:
            traj['actions'] = [a % N_ACTIONS for a in joint_action]
            traj['angles'] = [a % N_ANGLES for a in joint_angle]
        all_expert_trajectories_single.append(traj)
    
    # split into train and val sets
    val_indices = np.arange(start=0, stop=N_traj, step=5)
    train_indices = np.delete(np.arange(N_traj), val_indices)
    val_expert_trajectories_single = [all_expert_trajectories_single[val_idx] for val_idx in val_indices]
    expert_trajectories_single = [all_expert_trajectories_single[train_idx] for train_idx in train_indices]
    print("# of validation trajs: " +str(len(val_expert_trajectories_single)))
    print("# of training trajs: " +str(len(expert_trajectories_single)))

    # initialization
    height, width = int(np.sqrt(N)), int(np.sqrt(N))
    if 'height' in generative_params:
        height, width = generative_params['height'], generative_params['width']
    weights = np.ones(shape=(N_MAPS,1))
    goal_maps = np.random.uniform(size=(2*N_MAPS_INDIVIDUAL,N))
    individual_map1 = goal_maps[:N_MAPS_INDIVIDUAL,:]
    individual_map2 = goal_maps[N_MAPS_INDIVIDUAL:2*N_MAPS_INDIVIDUAL,:]
    if 'init_tag' in info and info['init_tag'] == 1:
        occ1 = generative_params['occ1']
        occ2 = generative_params['occ2']
        individual_map1 = np.reshape(occ1, (N_MAPS_INDIVIDUAL, N),order='F')
        individual_map2 = np.reshape(occ2, (N_MAPS_INDIVIDUAL, N),order='F')
    diff_map = init_diff_map(info, generative_params, height, width)
    diff_map = diff_map[:, :, np.newaxis]
    for i in range(1, N_ANGLES):
        tmp = init_diff_map(info, generative_params, height, width)
        diff_map = np.concatenate((diff_map, tmp[:, :, np.newaxis]), axis=-1)

    # save things
    rec_ind1_maps = []
    rec_ind2_maps = []
    rec_inter_maps = []
    losses_all_maps = []
    val_lls = []
    train_lls = []

    for i in range(20):
        print("At iteration: "+str(i), flush=True)
        print(info)
        print("-------------------------------------------------", flush=True)
    
        ind1_maps_MLE, ind2_maps_MLE, inter_maps_MLE, losses =  getMAP_goalmaps(seed, P_a, expert_trajectories_single, hyperparams = sigmas, a=weights, 
                                                        individual_map1=individual_map1, individual_map2=individual_map2, diff_map=diff_map,
                                                        max_iters=max_iters, lr=lr_maps, gamma=gamma, lam1=lam1,lam2=lam2, info=info, tag=TAG_TRAIN,
                                                        width=width, height=height)
        
        individual_map1, individual_map2, diff_map = ind1_maps_MLE[-1], ind2_maps_MLE[-1], inter_maps_MLE[-1]
        rec_ind1_maps.append(ind1_maps_MLE[-1])
        rec_ind2_maps.append(ind2_maps_MLE[-1])
        rec_inter_maps.append(inter_maps_MLE[-1])
        losses_all_maps = losses_all_maps + losses

        np.save("{}/ind1_maps_trajs_{}_seed_{}_iters_{}.npy".format(save_dir_agent, num_trajs, seed, max_iters), rec_ind1_maps)
        np.save("{}/ind2_maps_trajs_{}_seed_{}_iters_{}.npy".format(save_dir_agent, num_trajs, seed, max_iters), rec_ind2_maps)
        np.save("{}/inter_maps_trajs_{}_seed_{}_iters_{}.npy".format(save_dir_agent, num_trajs, seed, max_iters), rec_inter_maps)
        np.save("{}/losses_maps_trajs_{}_seed_{}_iters_{}.npy".format(save_dir_agent, num_trajs, seed, max_iters), losses_all_maps)

        train_ll = get_validation_ll(seed, P_a, expert_trajectories_single, hyperparams = sigmas, a=weights, 
                                individual_map1=individual_map1, individual_map2=individual_map2, diff_map=diff_map, 
                                gamma=gamma, info=info, tag=TAG_TRAIN, width=width, height=height)
        train_lls.append(train_ll)
        np.save("{}/training_lls_trajs_{}_seed_{}_iters_{}.npy".format(save_dir_agent, num_trajs, seed, max_iters), train_lls)

        val_ll = get_validation_ll(seed, P_a, val_expert_trajectories_single, hyperparams = sigmas, a=weights, 
                                individual_map1=individual_map1, individual_map2=individual_map2, diff_map=diff_map, 
                                gamma=gamma, info=info, tag=TAG_TRAIN, width=width, height=height)
        val_lls.append(val_ll)
        np.save("{}/validation_lls_trajs_{}_seed_{}_iters_{}.npy".format(save_dir_agent, num_trajs, seed, max_iters), val_lls)


