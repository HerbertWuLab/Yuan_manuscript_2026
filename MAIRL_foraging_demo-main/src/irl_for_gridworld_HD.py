import os
import numpy as np
import pickle
from src.helpers import *
from src.optimize_weights import getMAP_weights
from src.optimize_goal_maps import getMAP_goalmaps
from src.compute_validation_ll import get_validation_ll


def fit_irl_gridworld_HD(num_trajs, lr_maps, max_iters, gamma, N_MAPS_INDIVIDUAL, N_MAPS_INTERACTION,
                      seed, GEN_DIR_NAME, save_dir, lam1=5, lam2=1, TAG_TRAIN=0, info={'Neval': 0}):
    """ ONLY update goal maps
        FIX the number of maps to 1
        args:
        version (int): choose which version of the simulated trajectories to use
        num_trajs (int): choose how many trajectories to use
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
    if not os.path.isdir(save_dir): 
        os.makedirs(save_dir, exist_ok = True)

    N_MAPS = 2*N_MAPS_INDIVIDUAL + N_MAPS_INTERACTION

    # load expert trajs
    all_expert_trajectories = pickle.load(file_trajs)
    # assert len(all_expert_trajectories)+1 > num_trajs, "Not enough expert trajectories available!"
    N_traj = min(num_trajs,len(all_expert_trajectories))
    # slice to only the # of trajs that we need
    all_expert_trajectories = all_expert_trajectories[:N_traj]
    print("Loaded "+str(N_traj)+" expert trajectories for gridworld!", flush=True)
    T = len(all_expert_trajectories[0]["actions"])
    print("Using "+str(T)+" state-action pairs per trajectory.", flush=True)

    # split into train and val sets
    val_indices = np.arange(start=0, stop=N_traj, step=5)
    train_indices = np.delete(np.arange(N_traj), val_indices)
    val_expert_trajectories = [all_expert_trajectories[val_idx] for val_idx in val_indices]
    expert_trajectories = [all_expert_trajectories[train_idx] for train_idx in train_indices]
    print("# of validation trajs: " +str(len(val_expert_trajectories)))
    print("# of training trajs: " +str(len(expert_trajectories)))

    # loading some relevant generative parameters known to the inference algorithm
    generative_params = pickle.load(file)
    P_a = generative_params['P_a'] # permutation matrix
    N_STATES = P_a.shape[0] # no of joint states in gridworld
    N_GRID = int(np.sqrt(N_STATES))
    N = N_GRID
    sigma = generative_params['sigmas'] # all map weights have same prior variance
    sigmas = [sigma] * N_MAPS
    N_ANGLES = int(360/generative_params['angle_bin'])

    # choose a random initial guess
    weights = np.ones(shape=(N_MAPS,1))
    goal_maps = np.random.uniform(size=(2*N_MAPS_INDIVIDUAL,N))
    individual_map1 = goal_maps[:N_MAPS_INDIVIDUAL,:] 
    individual_map2 = goal_maps[N_MAPS_INDIVIDUAL:2*N_MAPS_INDIVIDUAL,:]
    if 'init_tag' in info and info['init_tag'] == 1:
        occ1 = generative_params['occ1']
        occ2 = generative_params['occ2']
        individual_map1[:,:N_GRID] = np.reshape(occ1, (N_MAPS_INDIVIDUAL, N_GRID),order='F')
        individual_map2[:,:N_GRID] = np.reshape(occ2, (N_MAPS_INDIVIDUAL, N_GRID),order='F')        
    
    height, width = int(np.sqrt(N_GRID)), int(np.sqrt(N_GRID)) # default for a square arena
    if 'height' in generative_params:
        height, width = generative_params['height'], generative_params['width']
    diff_map = init_diff_map(info, generative_params, height, width)
    diff_map = diff_map[:, :, np.newaxis]
    for i in range(1, N_ANGLES**2):
        tmp = init_diff_map(info, generative_params, height, width)
        diff_map = np.concatenate((diff_map, tmp[:, :, np.newaxis]), axis=-1)
        
    # save things
    rec_ind1_maps = []
    rec_ind2_maps = []
    rec_inter_maps = []
    losses_all_maps = []
    val_lls = []

    for i in range(20):
        print("At iteration: "+str(i), flush=True)
        print("-------------------------------------------------", flush=True)
        
        # get the optimal estimates of the goal maps and list of losses at every time step
        ind1_maps_MLE, ind2_maps_MLE, inter_maps_MLE, losses =  getMAP_goalmaps(seed, P_a, expert_trajectories, hyperparams = sigmas, a=weights, 
                                                        individual_map1=individual_map1, individual_map2=individual_map2, diff_map=diff_map,
                                                        max_iters=max_iters, lr=lr_maps, gamma=gamma, lam1=lam1,lam2=lam2, tag=TAG_TRAIN,
                                                        info=info, width=width, height=height)
        individual_map1, individual_map2, diff_map = ind1_maps_MLE[-1], ind2_maps_MLE[-1], inter_maps_MLE[-1]
        rec_ind1_maps.append(ind1_maps_MLE[-1])
        rec_ind2_maps.append(ind2_maps_MLE[-1])
        rec_inter_maps.append(inter_maps_MLE[-1])
        losses_all_maps = losses_all_maps + losses

        # save recovered goal maps as well as training loss
        np.save(save_dir + "/ind1_maps_trajs_"+str(num_trajs)+"_seed_"+str(seed)+"_iters_"+str(max_iters)+".npy", rec_ind1_maps)
        np.save(save_dir + "/ind2_maps_trajs_"+str(num_trajs)+"_seed_"+str(seed)+"_iters_"+str(max_iters)+".npy", rec_ind2_maps)
        np.save(save_dir + "/inter_maps_trajs_"+str(num_trajs)+"_seed_"+str(seed)+"_iters_"+str(max_iters)+".npy", rec_inter_maps)
        np.save(save_dir + "/losses_maps_trajs_"+str(num_trajs)+"_seed_"+str(seed)+"_iters_"+str(max_iters)+".npy", losses_all_maps)

        val_ll = get_validation_ll(seed, P_a, val_expert_trajectories, hyperparams = sigmas, a=weights, 
                                   individual_map1=individual_map1, individual_map2=individual_map2, diff_map=diff_map, 
                                   gamma=gamma, tag=TAG_TRAIN, info=info, width=width, height=height)
        val_lls.append(val_ll)
        # save validation LL on held-out trajectories
        np.save(save_dir + "/validation_lls_trajs_"+str(num_trajs)+"_seed_"+str(seed)+"_iters_"+str(max_iters)+".npy", val_lls) 


