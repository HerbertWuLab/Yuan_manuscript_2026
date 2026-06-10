import torch
import numpy as np
from src.helpers import extract_state_action_pair
from src.value_iteration_torchversion import policy_vi
from src.helpers import create_joint_maps_pytorch,  create_joint_maps_pytorch_v2
from torch.autograd.functional import hessian


def compute_inv_hessian_weights(seed, P_a, trajectories, hyperparams, a, goal_maps, tag, gamma=0.9):
    """ returns the inverse hessian of the neglogpost w.r.t. the weights
        args:
            P_a (N_STATES X N_STATES X N_ACTIONS): labyrinth/gridworld transition matrix
            trajectories (list): list of expert trajectories; each trajectory is a dictionary with 'states' and 'actions' as keys.
            hyperparams (tensor list): [sigma_individual_map1, sigma_individual_map2, sigma_diff_map]
            a (array of size N_MAPS x 1): time-varying weights
            goal maps (array of size N_MAPS x N_STATES): columns contains the goal maps
            gamma (float): discount factor for value iteration
        returns:
            inv_hess: inverse of the hessian computed at provided goal maps
    """   

    torch.manual_seed(seed)
    np.random.seed(seed)

    def neglogll(a):
        # MAP loss function wrt weights: negative log likelihood + prior 
        # use as a handle into the hessian function

        # calculating the log prior, centered at 1
        invSigma_diag = 1 / hyperparams**2
        logdet_invSigma = torch.sum(torch.log(invSigma_diag))
        log_prior = (1 / 2) * (logdet_invSigma - ((a-torch.ones(a.shape))**2 * invSigma_diag).sum())

        a_reshaped = a.reshape(N_MAPS, -1) # N_MAPS x 1
        rewards = a_reshaped.T@goal_maps # 1 x N_states
        
        policy, p1, p2 = policy_vi(P_a, rewards, gamma, tag) # policies: N_STATES X N_ACTIONS
        log_policies = torch.log(policy)        

        state_action_pairs = extract_state_action_pair(trajectories)
        log_likelihood = 0
        for i in range(len(state_action_pairs)):
            states, actions = torch.tensor(state_action_pairs[i][:,0], dtype=torch.long), torch.tensor(state_action_pairs[i][:,1], dtype=torch.long) # make them integer for index
            for t in range(len(states)):
                log_likelihood += torch.sum(log_policies[states[t], actions[t]])

        return -log_likelihood - log_prior

    # converting to tensors
    P_a = torch.from_numpy(P_a).float()
    goal_maps = torch.from_numpy(goal_maps).float()
    a = torch.from_numpy(a).float()
    hyperparams = torch.tensor(hyperparams)
    N_STATES = P_a.shape[0]
    N_MAPS = goal_maps.shape[0]
    assert goal_maps.shape[1]==N_STATES, "goal maps should be tensors with length as no. of states"
    assert a.shape[0]==N_MAPS and a.shape[1]==1, "weights should have weights N_MAPS X T"

    a_flat = a.flatten()
    hess = hessian(neglogll, inputs=(a_flat))

    assert(torch.allclose(hess.T, hess, rtol=0.1, atol=0.1)), "hessian should be symmetric"

    inv_hess = torch.linalg.inv(hess)

    return inv_hess.detach().numpy()


def compute_conf_interval_weights(inv_hess, N_MAPS):
    assert inv_hess.shape[0]==N_MAPS*1 and inv_hess.shape[1]==N_MAPS*1, "inverse hessian has the wrong shape" 
    diag_inv_hess = np.diag(inv_hess)
    conf_weights = np.sqrt(diag_inv_hess)
    conf_weights = conf_weights.reshape((N_MAPS, 1))
    
    return conf_weights


def compute_inv_hessian_maps(seed, P_a, trajectories, hyperparams, a, 
                                   individual_map1, individual_map2, inter_maps, tag, lam1, lam2, info, width=None, height=None, gamma=0.9):

    torch.manual_seed(seed)
    np.random.seed(seed)
    N_STATES = int(np.sqrt(P_a.shape[0]))

    if width==None and height == None:
        width, height = int(np.sqrt(N_STATES)), int(np.sqrt(N_STATES))

    def neglogll(individual_map1, individual_map2, inter_maps):
        # MAP with respect to inter_maps 
        # input are flattened tensors

        # prior
        loss_prior = lam1*torch.sum(individual_map1**2)+lam1*torch.sum(individual_map2**2)+lam2*torch.sum(inter_maps**2)

        if info['inter_tag'] == 0:
            joint_map = create_joint_maps_pytorch(individual_map1.reshape(1,-1), individual_map2.reshape(1,-1), inter_maps.reshape(1,-1),
                                                   width=width, height=height)
        elif info['inter_tag'] > 0:
            joint_map = create_joint_maps_pytorch_v2(individual_map1.reshape(1,-1), individual_map2.reshape(1,-1), inter_maps.reshape(1,-1),
                                                      info=info, width=width, height=height)

        rewards = a.T @ joint_map # 1 x N_states
        policy, p1, p2 = policy_vi(P_a, rewards, gamma, tag) # policies: N_STATES X N_ACTIONS
        log_policies = torch.log(policy)

        # compute the ll for all trajectories
        state_action_pairs = extract_state_action_pair(trajectories)
        num_trajectories = len(state_action_pairs)
        log_likelihood = 0
        for i in range(num_trajectories):
            states, actions = torch.tensor(state_action_pairs[i][:,0], dtype=torch.long), torch.tensor(state_action_pairs[i][:,1], dtype=torch.long)
            for t in range(len(states)):
                log_likelihood += torch.sum(log_policies[states[t], actions[t]])

        return -log_likelihood - loss_prior

    # converting to tensors
    P_a = torch.from_numpy(P_a).double()
    a = torch.from_numpy(a).double()
    hyperparams = torch.tensor(hyperparams, dtype=torch.double)
    inter_maps = torch.from_numpy(inter_maps).double()
    individual_map1 = torch.from_numpy(individual_map1).double()
    individual_map2 = torch.from_numpy(individual_map2).double()

    inter_maps_flat = inter_maps.flatten()
    individual_map1_flat = individual_map1.flatten()
    individual_map2_flat = individual_map2.flatten()
    hess = hessian(neglogll, inputs=(individual_map1_flat, individual_map2_flat, inter_maps_flat))

    hess1 = hess[0][0]
    hess2 = hess[1][1]
    hess3 = hess[2][2]

    assert(torch.allclose(hess1.T, hess1, rtol=0.1, atol=0.1)), "hessian should be symmetric"
    assert(torch.allclose(hess2.T, hess2, rtol=0.1, atol=0.1)), "hessian should be symmetric"
    assert(torch.allclose(hess3.T, hess3, rtol=0.1, atol=0.1)), "hessian should be symmetric"

    inv_hess1 = torch.linalg.inv(hess1)
    inv_hess2 = torch.linalg.inv(hess2)
    inv_hess3 = torch.linalg.inv(hess3)

    return inv_hess1.detach().numpy(), inv_hess2.detach().numpy(), inv_hess3.detach().numpy()


def compute_conf_interval_maps(inv_hess):
    diag_inv_hess = np.diag(inv_hess)
    conf_weights = np.sqrt(diag_inv_hess)
    
    return conf_weights