from torch import logsumexp, softmax
from src.helpers import collapse_permutation_matrix_pytorch, collapse_reward_pytorch, compute_marginals_and_conditionals_pytorch
import torch

def policy_vi(P_a, rewards, gamma, tag):
    if tag == 0:
        _, policy = two_agent_value_iteration(P_a, rewards=rewards.T, gamma=gamma, error=0.1)
        p1, p2 = None, None
    elif tag == 1:
        _, policy, p1, p2 = two_agent_value_iteration_independent_control(P_a, rewards=rewards.T, gamma=gamma, error=0.01)
    elif tag == 2:
        _, policy, p1, p2 = two_agent_value_iteration_independent_control(P_a, rewards=rewards.T, gamma=gamma, error=0.1)
    elif tag == 5: # selfish
        _, policy, p1, p2 = two_agent_value_iteration_selfish(P_a, rewards=rewards.T, gamma=gamma, error=0.1)
        policy += 1e-10
    elif tag == 6: # ego-uniform
        _, policy, p1, p2 = two_agent_value_iteration_independent_control_ego_uniform(P_a, rewards=rewards.T, gamma=gamma, error=0.01)
    elif tag == 7: # ego-ToM1
        _, policy, p1, p2 = two_agent_value_iteration_independent_control_ego_ToM1(P_a, rewards=rewards.T, gamma=gamma, error=0.01)
    return policy, p1, p2

def policy_vi_HD(P_a, rewards, gamma, tag):
    if tag == 0:
        _, policy = two_agent_value_iteration_HD(P_a, rewards=rewards[0,:,:], gamma=gamma, error=0.1)
        p1, p2 = None, None
    elif tag == 1:
        _, policy, p1, p2 = two_agent_value_iteration_independent_control_HD(P_a, rewards=rewards[0,:,:], gamma=gamma, error=0.1)
    return policy, p1, p2



def one_agent_value_iteration(P_a, rewards, gamma, error=0.001):
    n1, n2 = P_a.shape
    values = torch.ones((n1, 1), requires_grad=True)
    # estimate values and q-values iteratively
    while True:
        values_tmp = values.clone()
        q_values = torch.cat([values_tmp[P_a[:, i].long()] for i in range(n2)], dim=1)
        values = rewards + gamma * logsumexp(q_values, dim=1)[:, None]
        if torch.max(torch.abs(values - values_tmp)) < error:
            break
    policy = softmax(q_values, dim=1)
    return values, policy


def two_agent_value_iteration(P_a, rewards, gamma, error=0.001):
    """
    time-invariant soft value iteration function (to ensure that the policy is differentiable)
    - deterministic transition 
    - two agent collaborative foraging 
    - N_STATES, N_ACTIONS refers to single agent case (i.e. N_STATES = grid_H*grid_W)

    inputs:
        P_a        N_STATES**2 x N_ACTIONS**2, a permutation matrix P_a(s,a) to convert V(s) to V(s') based on action a
                                                i.e. V_new = V[P_a[:,a]]

        rewards     N_STATES**2 X 1 - R(s1,s2) where s1 is the location index of agent1
        gamma       float - RL discount
        error       float - threshold for a stop

    returns:
        values    N_STATES**2 x 1 matrix - V(s1,s2)
        policy    N_STATES**2 x N_ACTIONS**2
    """
    n1, n2 = P_a.shape

    values = torch.zeros((n1, 1), requires_grad=True)
    q_values = torch.zeros((n1, n2))

    # estimate values and q-values iteratively
    while True:
        values_tmp = values.clone()
        q_values = torch.cat([values_tmp[P_a[:, i].long()] for i in range(n2)], dim=1)
        values = rewards + gamma * logsumexp(q_values, dim=1)[:,None]
        if torch.max(torch.abs(values - values_tmp)) < error:
            break

    # generate policy
    policy = softmax(q_values, dim=1)

    return values, policy


def two_agent_value_iteration_independent_control(P_a, rewards, gamma, action_list=None, error=0.001):
    """
    time-invariant soft value iteration function (to ensure that the policy is differentiable)
    policy probability is derived from a independent control policy w.o. prediction of the other agent's policy
    N_STATES, N_ACTIONS refers to single agent case (i.e. N_STATES = grid_H*grid_W; N_ACTIONS = 5)

    inputs:
    P_a        N_STATES**2 x N_ACTIONS**2, a permutation matrix P_a(s,a) to convert V(s) to V(s') based on action a
                                    i.e. V_new = V[P_a[:,a]]         
    rewards     N_STATES**2 X 1 - R(s1,s2) where s1 is the location index of agent1
    gamma       float - RL discount
    error       float - threshold for a stop

    returns:
    values    N_STATES**2 x 1 matrix - V(s1,s2)
    policy_independent    N_STATES**2 x N_ACTIONS**2
    p1       N_STATES**2 x N_ACTIONS 
    p2       N_STATES**2 x N_ACTIONS 
    """
    _, n2 = P_a.shape
    N_ACTIONS = int(torch.sqrt(torch.tensor(n2)))
    values, jointpolicy = two_agent_value_iteration(P_a, rewards, gamma, error)

    if action_list is None:
        action_list = [[a1, a2] for a1 in range(N_ACTIONS) for a2 in range(N_ACTIONS)]

    idx1 = []
    for a1 in range(N_ACTIONS):
        idx1.append([i for i,ele in enumerate(action_list) if ele[0] == a1])
    idx2 = []
    for a2 in range(N_ACTIONS):
        idx2.append([i for i,ele in enumerate(action_list) if ele[1] == a2])

    p1 = torch.hstack([torch.sum(jointpolicy[:,idx1[i]],dim=1)[:,None] for i in range(N_ACTIONS)])
    p2 = torch.hstack([torch.sum(jointpolicy[:,idx2[i]],dim=1)[:,None] for i in range(N_ACTIONS)])

    policy_independent = torch.zeros(jointpolicy.shape)
    for i, a in enumerate(action_list):
        policy_independent[:,i] = p1[:,a[0]]*p2[:,a[1]]

    return values, policy_independent, p1, p2


def two_agent_value_iteration_independent_control_uniform_prediction(P_a, reward_joint, gamma, action_list=None, error=0.001):

    n1,n2 = P_a.shape
    N_STATES, N_ACTIONS = int(torch.sqrt(torch.tensor(n1))), int(torch.sqrt(torch.tensor(n2)))

    if action_list is None:
        action_list = [[a1, a2] for a1 in range(N_ACTIONS) for a2 in range(N_ACTIONS)]

    P_a_single = collapse_permutation_matrix_pytorch(P_a,1)
    marginal_reward = collapse_reward_pytorch(reward_joint,1)

    _, policy_single = one_agent_value_iteration(P_a_single, marginal_reward, gamma) # \pi1(a1|s1)
    values, policy_joint = two_agent_value_iteration(P_a, reward_joint, gamma) # \pi(a1,a2|s1,s2)

    p1, p2, c1, c2 = compute_marginals_and_conditionals_pytorch(policy_joint, action_list)

    policy1 = 1/N_ACTIONS * torch.sum(c1, dim=2)
    policy2 = 1/N_ACTIONS * torch.sum(c2, dim=2)
    policy_independent = torch.zeros(policy_joint.shape)
    for i, a in enumerate(action_list):
        policy_independent[:,i] = policy1[:,a[0]]*policy2[:,a[1]]

    return values, policy_independent, policy1, policy2


def two_agent_value_iteration_independent_control_ego_ToM1(P_a, rewards, gamma, error=0.001, action_list=None):
    '''
    agent1: ego
    agent2: ToM1    
    '''
    n1,n2 = P_a.shape
    N_STATES, N_ACTIONS = int(torch.sqrt(torch.tensor(n1))), int(torch.sqrt(torch.tensor(n2)))
    if action_list is None:
        action_list = [[a1, a2] for a1 in range(N_ACTIONS) for a2 in range(N_ACTIONS)]
    P_a_single = collapse_permutation_matrix_pytorch(P_a,1)
    marginal_reward = collapse_reward_pytorch(rewards,1)
    _, policy_single = one_agent_value_iteration(P_a_single, marginal_reward, gamma) # \pi1(a1|s1)
    values, policy_joint = two_agent_value_iteration(P_a, rewards, gamma) # \pi(a1,a2|s1,s2)
    p1, p2, c1, c2 = compute_marginals_and_conditionals_pytorch(policy_joint, action_list)

    policy_single_expand1 = policy_single.repeat(N_STATES, 1)  # P(a1|s), i.e. added s2 states, agent2's prediction of agent1 policy
    policy1 = policy_single_expand1  # P(a1|s)
    policy2 = torch.sum(c2 * policy_single_expand1[:, None, :], dim=2)
    policy_independent = torch.zeros(policy_joint.shape)
    for i, a in enumerate(action_list):
        policy_independent[:, i] = policy1[:, a[0]] * policy2[:, a[1]]

    return values, policy_independent, policy1, policy2


def two_agent_value_iteration_independent_control_ego_uniform(P_a, rewards, gamma, error=0.001, action_list=None):
    '''
    agent1: ego
    agent2: uniform    
    '''
    n1,n2 = P_a.shape
    N_STATES, N_ACTIONS = int(torch.sqrt(torch.tensor(n1))), int(torch.sqrt(torch.tensor(n2)))
    if action_list is None:
        action_list = [[a1, a2] for a1 in range(N_ACTIONS) for a2 in range(N_ACTIONS)]
    P_a_single = collapse_permutation_matrix_pytorch(P_a,1)
    marginal_reward = collapse_reward_pytorch(rewards,1)
    _, policy_single = one_agent_value_iteration(P_a_single, marginal_reward, gamma) # \pi1(a1|s1)
    values, policy_joint = two_agent_value_iteration(P_a, rewards, gamma) # \pi(a1,a2|s1,s2)
    p1, p2, c1, c2 = compute_marginals_and_conditionals_pytorch(policy_joint, action_list)

    policy_single_expand1 = policy_single.repeat(N_STATES, 1)  # P(a1|s), i.e. added s2 states, agent2's prediction of agent1 policy
    policy1 = policy_single_expand1  # P(a1|s)
    policy2 = 1/N_ACTIONS * torch.sum(c2, dim=2)
    policy_independent = torch.zeros(policy_joint.shape)
    for i, a in enumerate(action_list):
        policy_independent[:, i] = policy1[:, a[0]] * policy2[:, a[1]]

    return values, policy_independent, policy1, policy2


def two_agent_value_iteration_selfish(P_a, rewards, gamma, error=0.001, action_list=None):
    """

    N_STATES, N_ACTIONS refers to single agent case (i.e. N_STATES = grid_H*grid_W; N_ACTIONS = 5)

    inputs:
    P_a        N_STATES**2 x N_ACTIONS**2, a permutation matrix P_a(s,a) to convert V(s) to V(s') based on action a
                                            i.e. V_new = V[P_a[:,a]]
                                            
    rewards     N_STATES**2 X 1 - R(s1,s2) where s1 is the location index of agent1
    gamma       float - RL discount
    error       float - threshold for a stop

    returns:
    None
    policy    N_STATES**2 x N_ACTIONS**2 (p1 x p2)
    p1        N_STATES**2 x N_ACTIONS (p1)
    p2        N_STATES**2 x N_ACTIONS (p2)
    """
    n1, n2 = P_a.shape
    N_STATES, N_ACTIONS = int(torch.sqrt(torch.tensor(n1))), int(torch.sqrt(torch.tensor(n2)))
    if action_list is None:
        action_list = [[a1, a2] for a1 in range(N_ACTIONS) for a2 in range(N_ACTIONS)]
    P_a_single1 = collapse_permutation_matrix_pytorch(P_a,1)
    P_a_single2 = collapse_permutation_matrix_pytorch(P_a,2)
    reward1 = collapse_reward_pytorch(rewards,1)
    reward2 = collapse_reward_pytorch(rewards,2)
    _, single_policy1 = two_agent_value_iteration(P_a_single1, reward1, gamma, error)
    _, single_policy2 = two_agent_value_iteration(P_a_single2, reward2, gamma, error)

    p1 = single_policy1.repeat_interleave(N_STATES, dim=0)
    p2 = single_policy2.tile((N_STATES, 1))

    policy = torch.zeros((p1.shape[0], p1.shape[1] * p2.shape[1]))
    for i, a in enumerate(action_list):
        policy[:, i] = p1[:, a[0]] * p2[:, a[1]]

    return None, policy, p1, p2



def two_agent_value_iteration_HD(P_a, rewards, gamma, error=0.001):
    """
    - State augmented with egocentric representation of others (\theta)
    - N_STATES, N_ACTIONS refers to single agent case (i.e. N_STATES = grid_H*grid_W)
    - N_ANGLES refers to single agent case, number of angle bins
    inputs:
        P_a        N_STATES**2 x N_ACTIONS**2, a permutation matrix P_a(s,a) to convert V(s,\theta) to V(s',\theta) based on action a
                                                i.e. V_new[:,\theta] = V[P_a[:,a],\theta]

        rewards     N_STATES**2 x N_ANGLES(**2) - R(s1,s2,\theta1,\theta2) 
        gamma       float - RL discount
        error       float - threshold for a stop
    returns:
        values    N_STATES**2 x N_ANGLES(**2) - V(s1,s2,\theta1,\theta2)
        policy    N_STATES**2 x N_ANGLES(**2) x N_ACTIONS**2
    """
    n1, n2 = P_a.shape # n1 = N_STATES**2, n2 = N_ACTIONS**2
    n1_rep, n3 = rewards.shape # n3 = N_ANGLES**2
    assert n1 == n1_rep, "P_a and rewards should have the same number of states"

    values = torch.zeros((n1, n3), requires_grad=True) # N_STATES**2 x N_ANGLES**2
    q_values = torch.zeros((n1, n3, n2)) #  N_STATES**2 x N_ANGLES**2 x N_ACTIONS**2

    while True:
        values_tmp = values.clone()
        q_values = torch.stack([values_tmp[P_a[:, i].long(), :] for i in range(n2)], dim=2)
        values = rewards + gamma * logsumexp(q_values, dim=-1)
        if torch.max(torch.abs(values - values_tmp)) < error:
            break

    policy = softmax(q_values, dim=-1)
    
    return values, policy


def two_agent_value_iteration_independent_control_HD(P_a, rewards, gamma, error=0.001):
    """
    - State augmented with egocentric representation of others (\theta)
    - N_STATES, N_ACTIONS refers to single agent case (i.e. N_STATES = grid_H*grid_W)
    - N_ANGLES refers to single agent case, number of angle bins
    inputs:
        P_a        N_STATES**2 x N_ACTIONS**2, a permutation matrix P_a(s,a) to convert V(s,\theta) to V(s',\theta) based on action a
                                                i.e. V_new[:,\theta] = V[P_a[:,a],\theta]

        rewards     N_STATES**2 x N_ANGLES(**2) - R(s1,s2,\theta1,\theta2) 
        gamma       float - RL discount
        error       float - threshold for a stop
    returns:
        values    N_STATES**2 x N_ANGLES(**2) - V(s1,s2,\theta1,\theta2)
        policy    N_STATES**2 x N_ANGLES(**2) x N_ACTIONS**2
        p1        N_STATES**2 x N_ANGLES(**2) x N_ACTIONS
        p2        N_STATES**2 x N_ANGLES(**2) x N_ACTIONS
    """
    _, n2 = P_a.shape
    N_ACTIONS = int(torch.sqrt(torch.tensor(n2)))
    values, jointpolicy = two_agent_value_iteration_HD(P_a, rewards, gamma, error)

    action_list = [[a1, a2] for a1 in range(N_ACTIONS) for a2 in range(N_ACTIONS)]
    idx1 = []
    for a1 in range(N_ACTIONS):
        idx1.append([i for i,ele in enumerate(action_list) if ele[0] == a1])
    idx2 = []
    for a2 in range(N_ACTIONS):
        idx2.append([i for i,ele in enumerate(action_list) if ele[1] == a2])

    p1 = torch.stack([torch.sum(jointpolicy[:,:,idx1[i]], dim=2) for i in range(N_ACTIONS)], dim=-1)
    p2 = torch.stack([torch.sum(jointpolicy[:,:,idx2[i]], dim=2) for i in range(N_ACTIONS)], dim=-1)

    policy_independent = torch.zeros(jointpolicy.shape)
    for i, a in enumerate(action_list):
        policy_independent[:,:,i] = p1[:,:,a[0]]*p2[:,:,a[1]]

    return values, policy_independent, p1, p2