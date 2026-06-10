import numpy as np
import time
from src.value_iteration_torchversion import policy_vi
from src.helpers import extract_state_action_pair, create_joint_maps_pytorch_v2
import torch
torch.autograd.set_detect_anomaly(True)

def getMAP_goalmaps_minibatch(seed, P_a, trajectories, hyperparams, a, individual_map1, individual_map2, diff_map, 
                    lam1, lam2, max_iters = 500, lr = 0.01, gamma=0.9, info={'Neval': 0}, tag=0, width=None, height=None):
    """ obtain the MAP estimates of model parameters
        Adopts minibatch optimization for faster convergence
        For two agent collaborative foraging in a square arena (Y.C. Dec 2024)
        Note: N_STATES, N_ACTIONS live in the state-space for single agent
        args:
            seed (int); initialization seed
            P_a (N_STATES**2 X N_ACTIONS**2): labyrinth/gridworld transition matrix
            trajectories (list): list of expert trajectories; each trajectory is a dictionary with 'states (int)' and 'actions (int)' as keys.
            hyperparams (tensor list): current setting of sigmas, of size N_MAPS
            a (array of size N_MAPS x 1): current setting of weights, a[-1] is the weight for the interaction map
            individual_map1 (array of size N_MAPS_INDIVIDUAL x N_STATES): intial guess for agent 1 maps
            individual_map2 (array of size N_MAPS_INDIVIDUAL x N_STATES): intial guess for agent 2 maps
            diff_map (array of size N_MAPS_INTERACTION x N_diff): intial guess for the difference map 
            max_iters (int): number of SGD iterations to optimize this for
            lr (float): learning rate
            gamma (float): discount factor in value iteration
            lam1 (float): l2 coefficient for individual maps
            lam2 (float): l2 coefficient for interaction map
            info: dict with anything that we'd like to store for printing purposes
            tag (int): 0 for centralized control, 1 for independent control, 2 for independent control with prediction
        returns:
            individual_map1_MLEs (3-d array: (max_iters/10) x N_MAPS_INDIVIDUAL x N_STATES): MAP estimates of the individual maps saved after every 10 iterations
            individual_map2_MLEs (3-d array: (max_iters/10) x N_MAPS_INDIVIDUAL x N_STATES): MAP estimates of the individual maps saved after every 10 iterations
            diff_map_MLEs (3-d array: (max_iters/10) x N_MAPS_INTERACTION x N_diff): MAP estimates of the difference maps saved after every 10 iterations
            losses (list): values of the negative log posterior after every iteration
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
    sigmas = torch.tensor(hyperparams).float()
    individual_map1 = torch.from_numpy(individual_map1.astype(float)).float()
    individual_map2 = torch.from_numpy(individual_map2.astype(float)).float()
    diff_map = torch.from_numpy(diff_map.astype(float)).float()
    individual_map1.requires_grad = True
    individual_map2.requires_grad = True
    diff_map.requires_grad = True
    if info['inter_tag'] == 6: # self map + interaction map
        if info['SingleAgent'] == 1:
            individual_map2.requires_grad = False
        elif info['SingleAgent'] == 2:
            individual_map1.requires_grad = False
    if info['inter_tag'] == 7: #  self map (simpliest one)
        diff_map.requires_grad = False
        if info['SingleAgent'] == 1:
            individual_map2.requires_grad = False
        elif info['SingleAgent'] == 2:
            individual_map1.requires_grad = False
    if info['inter_tag'] == 8: # two individual maps
        diff_map.requires_grad = False

    print("Minimizing the negative log likelihood ...")
    print('{0} {1}'.format('# n_iters', 'neg LL'))
    optimizer = torch.optim.Adam([individual_map1, individual_map2, diff_map], lr=lr)
    losses = []
    individual_map1_MLEs = []
    individual_map2_MLEs = []
    diff_map_MLEs = []

    Batch_Size = info['batch_size'] # size of each batch
    Batch_N = int(len(state_action_pairs)/Batch_Size) + 1 # number of batches
    for i in range(max_iters):
        time1 = time.time()
        loss_b = []
        for b in range(Batch_N):
            loss_prior = lam1*torch.sum(individual_map1**2)+lam1*torch.sum(individual_map2**2)+lam2*torch.sum(diff_map**2)
            loss = neglogll(individual_map1, individual_map2, diff_map, 
                            state_action_pairs[b*Batch_Size:min((b+1)*Batch_Size,len(state_action_pairs))],
                              sigmas, a, P_a, gamma, info, tag, width=width, height=height) + loss_prior
            loss.backward(retain_graph=True)
            optimizer.step()
            optimizer.zero_grad()
            loss_b.append(loss.detach().numpy())
        time2 = time.time()
        losses.append(np.mean(loss_b)) 
        print('{}, full batch loss {:.2f}'.format(i, losses[-1]))   
        print('Time taken for this iteration: {:.2f} minutes'.format((time2-time1)/60))
        if i%10 == 0 or i==max_iters-1:
            individual_map1_MLE = individual_map1.detach().numpy()
            individual_map2_MLE = individual_map2.detach().numpy()
            diff_map_MLE = diff_map.detach().numpy()
            individual_map1_MLEs.append(individual_map1_MLE.copy())
            individual_map2_MLEs.append(individual_map2_MLE.copy())
            diff_map_MLEs.append(diff_map_MLE.copy())
        
    return individual_map1_MLEs, individual_map2_MLEs, diff_map_MLEs, losses


def neglogll(individual_map1, individual_map2, diff_map, state_action_pairs, hyperparams, a, P_a, gamma, info, tag, width, height):
    '''Returns negative log posterior 

        args:
            state_action_pairs (list of len(trajectories), with each element an array: T x (STATE_DIM + ACTION_DIM ))
            hyperparams (tensor): current setting of hyperparams, contains key 'sigmas' which is array of size N_MAPS
            a (2-d tensor: N_MAPS x T) or (N_MAPS x 1)
            P_a (tensor: N_STATES X N_STATES X N_ACTIONS): transition matrix 
            gamma (float): discount 
            info: dict with anything that we'd like to store for printing purposes
            tag (int): 0 for centralized control, 1 for independent control, 2 for independent control with prediction
        returns:
            negL : negative log posterior
    '''
    
    num_trajectories = len(state_action_pairs)

    log_likelihood = getLL(individual_map1, individual_map2, diff_map, state_action_pairs, hyperparams, a, P_a, gamma, info, tag, width, height)
    negL = (-log_likelihood)/num_trajectories

    info['Neval'] += 1

    return negL


def getLL(individual_map1, individual_map2, diff_map, state_action_pairs, hyperparams, a, P_a, gamma, info, tag, width, height):

    joint_map = create_joint_maps_pytorch_v2(individual_map1, individual_map2, diff_map, info=info, width=width, height=height)
    rewards = a.T @ joint_map # 1 x N_states

    policy, p1, p2 = policy_vi(P_a, rewards, gamma, tag) # policies: N_STATES X N_ACTIONS
    if 'SingleAgent' in info:
        if info['SingleAgent'] == 1:
            policy = p1
        elif info['SingleAgent'] == 2:
            policy = p2
    
    log_policies = torch.log(policy)
    num_trajectories = len(state_action_pairs)
    log_likelihood = 0
    for i in range(num_trajectories):
        states, actions = torch.tensor(state_action_pairs[i][:,0], dtype=torch.long), torch.tensor(state_action_pairs[i][:,1], dtype=torch.long)
        log_likelihood += log_policies[states, actions].sum()
    
    return log_likelihood


def getMAP_goalmaps_full(seed, P_a, trajectories, hyperparams, a, goal_maps, lam,
                    max_iters = 500, lr = 0.01, gamma=0.9, info={'Neval': 0}, tag=0, width=None, height=None):

    torch.manual_seed(seed)
    np.random.seed(seed)

    N_STATES = int(np.sqrt(P_a.shape[0]))
    if width==None and height == None:
        width, height = int(np.sqrt(N_STATES)), int(np.sqrt(N_STATES))

    state_action_pairs = extract_state_action_pair(trajectories)

    # converting to tensors
    P_a = torch.from_numpy(P_a).float()
    a = torch.from_numpy(a).float()
    sigmas = torch.tensor(hyperparams).float()

    # initial value of goal maps
    goal_maps = torch.from_numpy(goal_maps.astype(float)).float()
    goal_maps.requires_grad = True

    print("Minimizing the negative log likelihood ...")
    print('{0} {1}'.format('# n_iters', 'neg LL'))
    optimizer = torch.optim.Adam([goal_maps], lr=lr)
    # saving the losses
    losses = []
    rec_maps_MLE = []

    for i in range(max_iters):
        loss_prior = lam*torch.sum(goal_maps**2)
        loss = neglogll_full(goal_maps, state_action_pairs, sigmas, a, P_a, gamma, info, tag, 
                        width=width, height=height) + loss_prior
        losses.append(loss.detach().numpy())
        loss.backward(retain_graph=True)
        optimizer.step()
        optimizer.zero_grad()
        if i%10 == 0 or i==max_iters-1:
            map_MLE = goal_maps.detach().numpy()
            rec_maps_MLE.append(map_MLE.copy())
        
    return rec_maps_MLE, losses


def neglogll_full(goal_maps, state_action_pairs, hyperparams, a, P_a, gamma, info, tag, width, height):
    '''Returns negative log posterior 
        args:
            goal_maps (tensor: N_MAPS x N_STATES**2): current setting of goal maps
        returns:
            negL : negative log posterior
    '''
    
    num_trajectories = len(state_action_pairs)
    log_likelihood = getLL_full(goal_maps, state_action_pairs, hyperparams, a, P_a, gamma, info, tag, width, height)
    negL = (-log_likelihood)/num_trajectories

    info['Neval'] += 1
    n_eval = info['Neval']

    print('{0}, {1}'.format(n_eval, negL))
    return negL


def getLL_full(goal_maps, state_action_pairs, hyperparams, a, P_a, gamma, info, tag, width, height):
    N_STATES = P_a.shape[0]
    N_MAPS = a.shape[0]

    assert(goal_maps.shape[0]==N_MAPS), "goal maps are not of the appropriate shape"

    rewards = a.T @ goal_maps # 1 x N_states

    assert rewards.shape[0]==1 and rewards.shape[1]==N_STATES,"rewards not computed correctly"

    # policies should be N_STATES x N_ACTIONS
    policy, p1, p2 = policy_vi(P_a, rewards, gamma, tag) # policies: N_STATES X N_ACTIONS
    log_policies = torch.log(policy)

    # compute the ll for all trajectories
    num_trajectories = len(state_action_pairs)
    log_likelihood = 0
    for i in range(num_trajectories):
        states, actions = torch.tensor(state_action_pairs[i][:,0], dtype=torch.long), torch.tensor(state_action_pairs[i][:,1], dtype=torch.long)
        for t in range(len(states)):
            log_likelihood += torch.sum(log_policies[states[t], actions[t]])
    
    return log_likelihood