import numpy as np
from src.value_iteration_torchversion import *
from src.helpers import extract_state_action_pair
from src.optimize_goal_maps import getLL, getLL_full
import torch

def get_validation_ll(seed, P_a, trajectories, hyperparams, 
                      individual_map1, individual_map2, diff_map, a, 
                      gamma=0.9, info={'Neval': 0}, tag=0, width=None, height=None):
    """ obtain the ll of the held-out trajectories using a given parameter setting
        Time-invariant
        Two agent collaborative task 
        (Y.C. April 2024)
        args:
            P_a (N_STATES**2 X N_ACTIONS**2): permutation matrix
            trajectories (list): list of expert trajectories; each trajectory is a dictionary with 'states' and 'actions' as keys.
            hyperparams (list): current setting of hyperparams, of size N_MAPS
            a (array of size N_MAPS x T or 1): current setting of weights 
            goal_maps(array of size N_MAPS x N_STATES): goal maps columns contains u_e, u_th, u_ho etc
            gamma (float): discount factor
        returns:
           val_ll (float): validation ll of held-out trajectories
    """   

    torch.manual_seed(seed)
    np.random.seed(seed)

    N_STATES = int(np.sqrt(P_a.shape[0]))
    if width==None and height == None:
        width, height = int(np.sqrt(N_STATES)), int(np.sqrt(N_STATES))

    # concatenate expert trajectories
    state_action_pairs = extract_state_action_pair(trajectories, info)

    # converting to tensors
    P_a = torch.from_numpy(P_a).float()
    a = torch.from_numpy(a).float()
    individual_map1 = torch.from_numpy(individual_map1).float()
    individual_map2 = torch.from_numpy(individual_map2).float()
    diff_map = torch.from_numpy(diff_map).float()

    log_likelihood_pairwise = getLL(individual_map1, individual_map2, diff_map, state_action_pairs, hyperparams, a, P_a,
                                        gamma, info, tag, width=width, height=height)

    return log_likelihood_pairwise.item()


def get_validation_ll_full(seed, P_a, trajectories, hyperparams, goal_maps, a, 
                      gamma=0.9, info={'Neval': 0}, tag=0, width=None, height=None):
    """ obtain the ll of the held-out trajectories using a given parameter setting
        args:
            goal_maps(array of size N_MAPS x N_STATES**2): goal maps columns contains u_e, u_th, u_ho etc
    """   

    torch.manual_seed(seed)
    np.random.seed(seed)

    N_STATES = int(np.sqrt(P_a.shape[0]))
    if width==None and height == None:
        width, height = int(np.sqrt(N_STATES)), int(np.sqrt(N_STATES))

    # concatenate expert trajectories
    state_action_pairs = extract_state_action_pair(trajectories)

    # converting to tensors
    P_a = torch.from_numpy(P_a).float()
    a = torch.from_numpy(a).float()
    goal_maps = torch.from_numpy(goal_maps).float()

    log_likelihood_pairwise = getLL_full(goal_maps, state_action_pairs, hyperparams, a, P_a,
                                        gamma, info, tag, width=width, height=height)

    return log_likelihood_pairwise.item()


