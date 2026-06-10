import os
import numpy as np
import pickle
from src.helpers import *
from src.optimize_weights import getMAP_weights_full
from src.optimize_goal_maps import getMAP_goalmaps_full
from src.compute_validation_ll import get_validation_ll_full


def fit_irl_gridworld_full(num_trajs, lr_weights, lr_maps, max_iters, gamma, N_MAPS,
                      seed, GEN_DIR_NAME, save_dir, lam, TAG_TRAIN=0, info={'Neval': 0}):
    """ fits IRL on simulated trajectories from the gridworld environment given hyperparameters
        and saves all recovered parameters
        Modified for a collaborative task 
        (Y.C. April 2024)
        Modified to estimate the joint reward function
        (Y.C. September 2024)
   """
    np.random.seed(seed)
    # load the files to obtain the simulated trajectories from
    file = open(GEN_DIR_NAME + '/generative_parameters.pickle', 'rb')
    file_trajs = open(GEN_DIR_NAME +'/expert_trajectories.pickle', 'rb')

    # check if save_dir exists, else create it 
    if not os.path.isdir(save_dir): 
        os.makedirs(save_dir, exist_ok = True)

    # load expert trajs
    all_expert_trajectories = pickle.load(file_trajs)
    assert len(all_expert_trajectories)+1 > num_trajs, "Not enough expert trajectories available!"
    N_traj = num_trajs
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
    N_STATES = P_a.shape[0] # no of states in gridworld
    N = int(np.sqrt(N_STATES))
    sigma = generative_params['sigmas'] # all map weights have same prior variance
    sigmas = [sigma] * N_MAPS

    # choose a random initial guess
    weights = (np.random.normal(1., scale=sigma, size=(N_MAPS,1)))
    goal_maps = np.random.uniform(size=(N_MAPS,N_STATES))
    height, width = int(np.sqrt(N)), int(np.sqrt(N)) # default for a square arena
    if 'height' in generative_params:
        height, width = generative_params['height'], generative_params['width']
  
    # save things
    rec_weights = []
    rec_maps = []
    losses_all_weights = []
    losses_all_maps = []
    val_lls = []

    for i in range(20):
        print("At iteration: "+str(i), flush=True)
        print("-------------------------------------------------", flush=True)
        # get the MAP estimates of time-varying weights and list of losses at every time step
        a_MAPs, losses =  getMAP_weights_full(seed, P_a, expert_trajectories, hyperparams = sigmas, 
                                         goal_maps=goal_maps, a_init=weights, 
                                         max_iters=max_iters, lr=lr_weights, gamma=gamma, tag=TAG_TRAIN, 
                                         info=info, height = height, width = width)
        weights = a_MAPs[-1]
        rec_weights.append(weights)
        losses_all_weights = losses_all_weights + losses

        # save recovered time-varying weights as well as training loss
        np.save(save_dir + "/weights_trajs_"+str(num_trajs)+"_seed_"+str(seed)+"_iters_"+str(max_iters)+".npy", rec_weights)
        np.save(save_dir + "/losses_weights_trajs_"+str(num_trajs)+"_seed_"+str(seed)+"_iters_"+str(max_iters)+".npy", losses_all_weights)

        # get the optimal estimates of the goal maps and list of losses at every time step
        maps_MLE, losses =  getMAP_goalmaps_full(seed, P_a, expert_trajectories, hyperparams = sigmas, a=weights, 
                                                        goal_maps=goal_maps, max_iters=max_iters, 
                                                        lr=lr_maps, gamma=gamma, lam=lam, tag=TAG_TRAIN,
                                                        info=info, width=width, height=height)
        goal_maps = maps_MLE[-1]
        rec_maps.append(goal_maps)
        losses_all_maps = losses_all_maps + losses

        # save recovered goal maps as well as training loss
        np.save(save_dir + "/maps_trajs_"+str(num_trajs)+"_seed_"+str(seed)+"_iters_"+str(max_iters)+".npy", rec_maps)
        np.save(save_dir + "/losses_maps_trajs_"+str(num_trajs)+"_seed_"+str(seed)+"_iters_"+str(max_iters)+".npy", losses_all_maps)

        val_ll = get_validation_ll_full(seed, P_a, val_expert_trajectories, hyperparams = sigmas, a=weights, 
                                   goal_maps=goal_maps, gamma=gamma, tag=TAG_TRAIN, info=info, width=width, height=height)
        val_lls.append(val_ll)
        
        # save validation LL on held-out trajectories
        np.save(save_dir + "/validation_lls_"+str(num_trajs)+"_seed_"+str(seed)+"_iters_"+str(max_iters)+".npy", val_lls) 


