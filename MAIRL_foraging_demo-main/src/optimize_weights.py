# Optimize the weight parameter for MAP optimization 
# Adapted for two-agent collaborative task (Y.C. April 2024)
# Augumented for head direction information (Y.C. Feb 2015)
import numpy as np
from src.value_iteration_torchversion import policy_vi, policy_vi_HD
from src.helpers import create_joint_maps_v2, extract_state_action_pair, create_joint_maps_HD
import torch

def getMAP_weights(seed, P_a, trajectories, individual_map1, individual_map2, diff_map, 
                   hyperparams, a_init, max_iters = 500, lr = 0.01, gamma=0.9, info={'Neval': 0}, tag=0, 
                   width=None, height=None):
    """ obtain the MAP estimates of map parameters
        For two agent collaborative foraging in a square arena (Y.C. April 2024)
        args:
            N_STATES, N_ACTIONS: state-space for single agent
            P_a (N_STATES**2 X N_ACTIONS**2): gridworld permutation matrix
            trajectories (list): list of expert trajectories; each trajectory is a dictionary with 'states' and 'actions' as keys.
            hyperparams (list): current setting of hyperparams, of size N_MAPS
            individual_map1 (array of size N_MAPS_INDIVIDUAL x N_STATES): intial guess for agent 1 maps
            individual_map2 (array of size N_MAPS_INDIVIDUAL x N_STATES): intial guess for agent 2 maps
            diff_map (array of size N_MAPS_INTERACTION x N_diff): intial guess for the difference map 
            hyperparams (array of size 3): [sigma_individual_map1, sigma_individual_map2, sigma_diff_map]
            a_init (array of size (N_MAPS) x 1): initial guess for a (T: total # of state-action pairs across trajectories)
            max_iters (int): number of SGD iterations to optimize this for
            lr (float): learning rate
            gamma (float): discount factor in value iteration
            info: dict with anything that we'd like to store for printing purposes
            tag (int): controls which model to fit (default 0: centralized control, 1: independent control, 2: independent control with prediction)
        returns:
            a_MAP (3-d array: (max_iters/10) x (4+N_MAPS) x 1): MAP estimates of the time-varying weghts saved after every 10 iterations
            losses (list): values of the negative log posterior after every iteration
    """   

    torch.manual_seed(seed)
    np.random.seed(seed)
    
    # concatenate states and actions in expert trajectories
    state_action_pairs = extract_state_action_pair(trajectories, info)

    # converting to tensors
    P_a = torch.from_numpy(P_a).float()
    N_STATES = P_a.shape[0]
    if width == None and height == None:
        width, height = int(torch.sqrt(torch.tensor(N_STATES))), int(torch.sqrt(torch.tensor(N_STATES)))

    if info['HD']:
        goal_maps = create_joint_maps_HD(individual_map1, individual_map2, diff_map, info, width, height)
    else:
        goal_maps = create_joint_maps_v2(individual_map1, individual_map2, diff_map, info, width, height)
    
    goal_maps = torch.from_numpy(goal_maps).float()
    sigmas = torch.tensor(hyperparams).float()
    N_MAPS = goal_maps.shape[0]

    # initial value
    a_init = torch.from_numpy(a_init).float()
    a_init.requires_grad = True

    print("Minimizing the negative log posterior ...")
    print('{0} {1}'.format('# n_iters', 'neg LP'))
    optimizer = torch.optim.Adam([a_init], lr=lr)
    # saving the losses
    losses = []
    # saving MAP estimates after every 10 iterations
    a_MAPs = []

    for i in range(max_iters):
        if i%10 == 0 or i==max_iters-1:
            a_MAP = a_init.detach().numpy()
            a_MAP = np.reshape(a_MAP, (N_MAPS, -1))
            a_MAPs.append(a_MAP.copy())
        loss = neglogpost(a_init, state_action_pairs, sigmas, goal_maps, P_a,  gamma, info, tag)
        losses.append(loss.detach().numpy())
        loss.backward()
        optimizer.step()
        optimizer.zero_grad()


    return a_MAPs, losses


def neglogpost(a, state_action_pairs, hyperparams, goal_maps, P_a, gamma, info, tag):
    '''
    Returns negative log posterior 
        args:
            a (1-d tensor: 1*N_MAPS) 
            state_action_pairs (list of len(trajectories), with each element an array: T x (STATE_DIM + ACTION_DIM ))
            goal_maps (tensor of size N_MAPS x N_STATES**2 x N_ANGLES**2): 
            P_a (tensor: N_STATES**2 X N_ACTIONS**2): transition matrix 
            gamma (float): discount factor in value iteration
            info: dict with anything that we'd like to store for printing purposes
            tag: controls which model to fit (default 0: centralized control, 1: independent control, 2: independent control with prediction)
        returns:
            negL : negative log posterior
    '''
    num_trajectories = len(state_action_pairs)
    log_prior, log_likelihood = getPosterior(a, state_action_pairs, hyperparams, goal_maps, P_a, gamma, info, tag)    
    negL = (-log_prior-log_likelihood)/num_trajectories
    if 'll' in info:
        negL = (-log_likelihood)/num_trajectories
    info['Neval'] = info['Neval']+1
    n_eval = info['Neval']
    print('{0}, {1}'.format(n_eval, negL))
    return negL


def getPosterior(a, state_action_pairs, hyperparams, goal_maps, P_a,  gamma, info, tag):
    """ returns prior and likelihood 
        Time-invarianat version
        Two agent collaborative task
        assumes that 'a' has a prior mean of 1
        args:
            hyperparams (tensor list): sigmas
            a: 1 x Nmaps
            goal_maps: Nmaps x N_STATES**2 x N_ANGLES**2
            tag: controls which model to fit (default 0: centralized control, 1: independent control, 2: independent control with prediction)
        returns:
            log_prior: log prior of time-varying weights
            log_likelihood summed over all the state action terms 
    """

    N_STATES = P_a.shape[0]
    N_MAPS = goal_maps.shape[0]
    assert N_MAPS == a.shape[0], "Number of maps should be equal to the number of weights"
     
    # diagonal of inverse of the sigma matrix
    invSigma_diag = 1 / hyperparams**2
    logdet_invSigma = torch.sum(torch.log(invSigma_diag))
    # calculating the log prior
    logprior = (1 / 2) * (logdet_invSigma - ((a-torch.ones(a.shape))**2 * invSigma_diag).sum())
    # logprior = (1 / 2) * (logdet_invSigma - (a**2 * invSigma_diag).sum())


    # ------------------------------------------------------------------
    # compute the likelihood terms 
    # ------------------------------------------------------------------
    if info['HD']:
        A_reshaped = (a.T).view(1, 3, 1, 1) # (1 x 3 x 1 x 1)
        B_reshaped = goal_maps.unsqueeze(0)     # (1 x 3 x N_STATES**2 x N_ANGLES)
        rewards = (A_reshaped * B_reshaped).sum(dim=1) # (1 x N_STATES**2 x N_ANGLES)
        policy, p1, p2 = policy_vi_HD(P_a, rewards, gamma, tag)
    else:
        rewards = a.T @ goal_maps
        policy, p1, p2 = policy_vi(P_a, rewards, gamma, tag)

    if 'SingleAgent' in info:
        if info['SingleAgent'] == 1:
            policy = p1
        elif info['SingleAgent'] == 2:
            policy = p2

    log_policies = torch.log(policy)
    num_trajectories = len(state_action_pairs)
    log_likelihood = 0
    if info['HD']:
        for i in range(num_trajectories):
            states, actions, angles = torch.tensor(state_action_pairs[i][:,0], dtype=torch.long), torch.tensor(state_action_pairs[i][:,1], dtype=torch.long), torch.tensor(state_action_pairs[i][:,2], dtype=torch.long)
            for t in range(len(states)):
                log_likelihood += torch.sum(log_policies[states[t], angles[t], actions[t]])
    else:
        for i in range(num_trajectories):
            states, actions = torch.tensor(state_action_pairs[i][:,0], dtype=torch.long), torch.tensor(state_action_pairs[i][:,1], dtype=torch.long)
            for t in range(len(states)):
                log_likelihood += torch.sum(log_policies[states[t], actions[t]])

    return logprior, log_likelihood








def getMAP_weights_full(seed, P_a, trajectories, goal_maps, hyperparams, a_init, 
                        max_iters = 500, lr = 0.01, gamma=0.9, info={'Neval': 0}, tag=0, 
                        width=None, height=None):
    """ obtain the MAP estimates of FULL map parameters
    """   

    torch.manual_seed(seed)
    np.random.seed(seed)
    
    # concatenate states and actions in expert trajectories
    state_action_pairs = extract_state_action_pair(trajectories)

    # converting to tensors
    P_a = torch.from_numpy(P_a).float()
    N_STATES = P_a.shape[0]
    if width == None and height == None:
        width, height = int(torch.sqrt(torch.tensor(N_STATES))), int(torch.sqrt(torch.tensor(N_STATES)))
    goal_maps = torch.from_numpy(goal_maps).float()
    sigmas = torch.tensor(hyperparams).float()
    N_MAPS = goal_maps.shape[0]
    assert goal_maps.shape[1]==N_STATES, "goal maps should be tensors with length as no. of states"

    # initial value
    a_init = torch.from_numpy(a_init).flatten().float()
    a_init.requires_grad = True

    print("Minimizing the negative log posterior ...")
    print('{0} {1}'.format('# n_iters', 'neg LP'))
    optimizer = torch.optim.Adam([a_init], lr=lr)
    losses = []
    a_MAPs = [] # saving MAP estimates after every 10 iterations

    for i in range(max_iters):
        loss = neglogpost(a_init, state_action_pairs, sigmas, goal_maps, P_a,  gamma, info, tag)
        losses.append(loss.detach().numpy())
        loss.backward()
        optimizer.step()
        optimizer.zero_grad()
        if i%10 == 0 or i==max_iters-1:
            a_MAP = a_init.detach().numpy()
            a_MAP = np.reshape(a_MAP, (N_MAPS, -1))
            a_MAPs.append(a_MAP.copy())

    return a_MAPs, losses

