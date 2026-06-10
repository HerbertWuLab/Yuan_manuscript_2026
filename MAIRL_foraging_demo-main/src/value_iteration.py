import numpy as np
from scipy.special import logsumexp, softmax
from src.helpers import collapse_permutation_matrix, collapse_reward, compute_marginals_and_conditionals


def two_agent_value_iteration(P_a, rewards, gamma, error=0.001):
  """
  Soft value iteration function (to ensure that the policy is differentiable)
  deterministic transition 

  N_STATES, N_ACTIONS refers to single agent case (i.e. N_STATES = grid_H*grid_W; N_ACTIONS = 5)
  
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
  N_STATES, N_ACTIONS = int(np.sqrt(n1)), int(np.sqrt(n2))

  values = np.zeros((N_STATES**2, 1))
  q_values = np.zeros((N_STATES**2, N_ACTIONS**2))

  # estimate values and q-values iteratively
  while True:
    values_tmp = values.copy()
    q_values = np.hstack([values_tmp[P_a[:,i]] for i in range(N_ACTIONS**2)])
    values = rewards + gamma* logsumexp(q_values, axis=1)[:,np.newaxis]
    if max([abs(values[i,0] - values_tmp[i,0]) for i in range(N_STATES**2)]) < error:
      break

  # generate policy
  policy = softmax(q_values, axis=1)

  return values, policy


def two_agent_value_iteration_independent_control(P_a, rewards, gamma, action_list=None, error=0.001):
  """
  time-invariant soft value iteration function (to ensure that the policy is differentiable)
  policy probability is derived from a independent control policy w.o. prediction of the other agent's policy
  N_STATES, N_ACTIONS refers to single agent case (i.e. N_STATES = grid_H*grid_W; N_ACTIONS = 5)
  
  inputs:
    P_a        N_STATES**2 x N_ACTIONS**2, a permutation matrix P_a(s,a) to convert V(s) to V(s') based on action a
                                            i.e. V_new = V[P_a[:,a]], P_a[s,a] = s'         
    rewards     N_STATES**2 X 1 - R(s1,s2) where s1 is the location index of agent1
    gamma       float - RL discount
    error       float - threshold for a stop

  returns:
    values    N_STATES**2 x 1 matrix - V(s1,s2)
    policy_independent    N_STATES**2 x N_ACTIONS**2
  """
  n1, n2 = P_a.shape
  N_ACTIONS = int(np.sqrt(n2))
  values, jointpolicy = two_agent_value_iteration(P_a, rewards, gamma, error)

  if action_list is None:
    action_list = [[a1, a2] for a1 in range(N_ACTIONS) for a2 in range(N_ACTIONS)]

  idx1 = []
  for a1 in range(5):
      idx1.append([i for i,ele in enumerate(action_list) if ele[0] == a1])
  idx2 = []
  for a2 in range(5):
      idx2.append([i for i,ele in enumerate(action_list) if ele[1] == a2])
  p1 = np.hstack([np.sum(jointpolicy[:,idx1[i]],axis=1)[:,None] for i in range(N_ACTIONS)])
  p2 = np.hstack([np.sum(jointpolicy[:,idx2[i]],axis=1)[:,None] for i in range(N_ACTIONS)])

  policy_independent = np.zeros(jointpolicy.shape)
  for i, a in enumerate(action_list):
      policy_independent[:,i] = p1[:,a[0]]*p2[:,a[1]]

  return values, policy_independent, p1, p2


def one_agent_value_iteration(P_a, rewards, gamma, error=0.001):
  """
  time-invariant soft value iteration function (to ensure that the policy is differentiable)
  deterministic transition 
  for ONE AGENT case

  N_STATES, N_ACTIONS refers to single agent case (i.e. N_STATES = grid_H*grid_W; N_ACTIONS = 5)
  
  inputs:
    P_a        N_STATES x N_ACTIONS, a permutation matrix P_a(s,a) to convert V(s) to V(s') based on action a
                                            i.e. V_new = V[P_a[:,a]]
                                            
    rewards     N_STATES X 1 - R(s1,s2) where s1 is the location index of agent1
    gamma       float - RL discount
    error       float - threshold for a stop

  returns:
    values    N_STATES x 1 matrix 
    policy    N_STATES x N_ACTIONS
  """
  N_STATES, N_ACTIONS = P_a.shape

  values = np.ones((N_STATES, 1))

  # estimate values and q-values iteratively
  while True:
    values_tmp = values.copy()
    q_values = np.hstack([values_tmp[P_a[:,i]] for i in range(N_ACTIONS)])
    values = rewards + gamma* logsumexp(q_values, axis=1)[:,np.newaxis]
    if max([abs(values[i,0] - values_tmp[i,0]) for i in range(N_STATES)]) < error:
      break
  
  # generate policy
  policy = softmax(q_values, axis=1)
  return values, policy


def two_agent_value_iteration_independent_control_uniform_prediction(P_a, rewards, gamma, action_list=None, error=0.001):
    n1, n2 = P_a.shape
    N_STATES, N_ACTIONS = int(np.sqrt(n1)), int(np.sqrt(n2))
    if action_list is None:
        action_list = [[a1, a2] for a1 in range(N_ACTIONS) for a2 in range(N_ACTIONS)]

    values, policy_joint = two_agent_value_iteration(P_a, rewards, gamma, error)
    p1, p2, c1, c2 = compute_marginals_and_conditionals(policy_joint, action_list)

    policy1 = 1/N_ACTIONS * np.sum(c1, axis=2)
    policy2 = 1/N_ACTIONS * np.sum(c2, axis=2)
    policy_independent = np.zeros(policy_joint.shape)
    for i, a in enumerate(action_list):
        policy_independent[:,i] = policy1[:,a[0]]*policy2[:,a[1]]

    return values, policy_independent, policy1, policy2



def two_agent_value_iteration_independent_control_ego_uniform(P_a, reward_joint, gamma, action_list=None):
  '''
  ASSUMPTION: 
    Agent 1: egocentric P(a1|s1,s2) = \pi1(a1|s1)
    Agent 2: ToM1-uniform P(a2|s1,s2) = \sum_a1 1/cardinality(A1) \pi(a2|s,a1) 
  NOTATION:
    Individual optimal policy: \pi1(a1|s1), \pi2(a2|s2)
    Joint optimal policy: \pi(a1,a2|s1,s2)
  INPUT:
    P_a: permutation matrix, P_a(s,a) = s'
    P_a_single: permutation matrix for single agent, P_a_single(s1,a1) = s1'
    reward_joint: 
  OUTPUT:
    values: from VI of joint policy
    policy_independent: p1 * p1
    policy1: p1
    policy2: p2
  
  '''

  n1,n2 = P_a.shape
  N_STATES, N_ACTIONS = int(np.sqrt(n1)), int(np.sqrt(n2))
  if action_list is None:
      action_list = [[a1, a2] for a1 in range(N_ACTIONS) for a2 in range(N_ACTIONS)]

  P_a_single = collapse_permutation_matrix(P_a,1)
  marginal_reward = collapse_reward(reward_joint,1)

  _, policy_single = one_agent_value_iteration(P_a_single.astype(int), marginal_reward, gamma) # \pi1(a1|s1)
  values, policy_joint = two_agent_value_iteration(P_a.astype(int), reward_joint, gamma) # \pi(a1,a2|s1,s2)

  p1, p2, c1, c2 = compute_marginals_and_conditionals(policy_joint, action_list)

  policy_single_expand1 = np.repeat(policy_single,N_STATES,axis=0) # P(a1|s), i.e. added s2 states, agent2's prediction of agent1 policy
  policy1 = policy_single_expand1 # P(a1|s)
  policy2 = 1 / N_ACTIONS * np.sum(c2, axis=2)
  policy_independent = np.zeros(policy_joint.shape)
  for i, a in enumerate(action_list):
      policy_independent[:,i] = policy1[:,a[0]]*policy2[:,a[1]]

  return values, policy_independent, policy1, policy2



def two_agent_value_iteration_independent_control_ego_ToM1(P_a, reward_joint, gamma, action_list=None):
  '''
  ASSUMPTION: 
    Agent 1: egocentric P(a1|s1,s2) = \pi1(a1|s1)
    Agent 2: ToM1 P(a2|s1,s2) = \sum_a1 \pi(a2|s,a1) \pi1(a1|s)
  NOTATION:
    Individual optimal policy: \pi1(a1|s1), \pi2(a2|s2)
    Joint optimal policy: \pi(a1,a2|s1,s2)
  INPUT:
    P_a: permutation matrix, P_a(s,a) = s'
    P_a_single: permutation matrix for single agent, P_a_single(s1,a1) = s1'
    reward_joint: 
  OUTPUT:
    values: from VI of joint policy
    policy_independent: p1 * p1
    policy1: p1
    policy2: p2
  
  '''

  n1,n2 = P_a.shape
  N_STATES, N_ACTIONS = int(np.sqrt(n1)), int(np.sqrt(n2))

  if action_list is None:
      action_list = [[a1, a2] for a1 in range(N_ACTIONS) for a2 in range(N_ACTIONS)]

  P_a_single = collapse_permutation_matrix(P_a,1)
  marginal_reward = collapse_reward(reward_joint,1)

  _, policy_single = one_agent_value_iteration(P_a_single.astype(int), marginal_reward, gamma) # \pi1(a1|s1)
  values, policy_joint = two_agent_value_iteration(P_a.astype(int), reward_joint, gamma) # \pi(a1,a2|s1,s2)

  idx1 = []
  for a1 in range(5):
      idx1.append([i for i,ele in enumerate(action_list) if ele[0] == a1])
  idx2 = []
  for a2 in range(5):
      idx2.append([i for i,ele in enumerate(action_list) if ele[1] == a2])

  p1 = np.hstack([np.sum(policy_joint[:,idx1[i]],axis=1)[:,None] for i in range(N_ACTIONS)]) # marginal, \pi(a1|s1,s2)
  p2 = np.hstack([np.sum(policy_joint[:,idx2[i]],axis=1)[:,None] for i in range(N_ACTIONS)]) # marginal, \pi(a2|s1,s2)
  c1 = np.zeros((N_STATES**2, N_ACTIONS, N_ACTIONS)) # c1(s,a1,a2) = \pi(a1|a2,s)
  c2 = np.zeros((N_STATES**2, N_ACTIONS, N_ACTIONS)) # c2(s,a2,a1) = \pi(a2|a1,s)
  for a_idx in range(N_ACTIONS):
      c1[:, :, a_idx] = policy_joint[:,idx2[a_idx]] / np.hstack([p2[:,a_idx][:,None] for _ in range(N_ACTIONS)])
      c2[:, :, a_idx] = policy_joint[:,idx1[a_idx]] / np.hstack([p1[:,a_idx][:,None] for _ in range(N_ACTIONS)])

  # policy_single_expand2 = np.tile(policy_single,(N_STATES,1))      # P(a2|s), i.e. added s1 states, agent1's prediction of agent2 policy
  policy_single_expand1 = np.repeat(policy_single,N_STATES,axis=0) # P(a1|s), i.e. added s2 states, agent2's prediction of agent1 policy

  # policy1 = np.sum(c1 * policy_single_expand2[:,None,:], axis=2)
  policy1 = policy_single_expand1 # P(a1|s)
  policy2 = np.sum(c2 * policy_single_expand1[:,None,:], axis=2)
  policy_independent = np.zeros(policy_joint.shape)
  for i, a in enumerate(action_list):
      policy_independent[:,i] = policy1[:,a[0]]*policy2[:,a[1]]

  return values, policy_independent, policy1, policy2





def two_agent_value_iteration_independent_control_ToM1(P_a, P_a_single, reward_joint, time_invariant_rewards, gamma, action_list=None):
  # Agent 1: ToM1
  # Agent 2: ToM1

  n1,n2 = P_a.shape
  N_STATES, N_ACTIONS = int(np.sqrt(n1)), int(np.sqrt(n2))

  if action_list is None:
      action_list = [[a1, a2] for a1 in range(N_ACTIONS) for a2 in range(N_ACTIONS)]

  assert P_a_single.shape[0] == N_STATES and P_a_single.shape[1] == N_ACTIONS, 'P_a dimension match error'
  assert time_invariant_rewards.shape[0] == N_STATES and time_invariant_rewards.shape[1] == 1, 'single agent reward dimension match error'

  _, policy_single = one_agent_value_iteration(P_a_single.astype(int), time_invariant_rewards, gamma)
  values, policy_joint = two_agent_value_iteration(P_a.astype(int), reward_joint, gamma)

  idx1 = []
  for a1 in range(5):
      idx1.append([i for i,ele in enumerate(action_list) if ele[0] == a1])
  idx2 = []
  for a2 in range(5):
      idx2.append([i for i,ele in enumerate(action_list) if ele[1] == a2])
  p1 = np.hstack([np.sum(policy_joint[:,idx1[i]],axis=1)[:,None] for i in range(N_ACTIONS)]) # marginal
  p2 = np.hstack([np.sum(policy_joint[:,idx2[i]],axis=1)[:,None] for i in range(N_ACTIONS)]) # marginal
  c1 = np.zeros((N_STATES**2, N_ACTIONS, N_ACTIONS)) # c1(s,a1,a2) = P(a1|a2,s)
  c2 = np.zeros((N_STATES**2, N_ACTIONS, N_ACTIONS)) # c2(s,a2,a1) = P(a2|a1,s)
  for a_idx in range(N_ACTIONS):
      c1[:, :, a_idx] = policy_joint[:,idx2[a_idx]] / np.hstack([p2[:,a_idx][:,None] for _ in range(N_ACTIONS)])
      c2[:, :, a_idx] = policy_joint[:,idx1[a_idx]] / np.hstack([p1[:,a_idx][:,None] for _ in range(N_ACTIONS)])

  policy_single_expand2 = np.tile(policy_single,(N_STATES,1))      # P(a2|s), i.e. added s1 states, agent1's prediction of agent2 policy
  policy_single_expand1 = np.repeat(policy_single,N_STATES,axis=0) # P(a1|s), i.e. added s2 states, agent2's prediction of agent1 policy

  policy1 = np.sum(c1 * policy_single_expand2[:,None,:], axis=2)
  policy2 = np.sum(c2 * policy_single_expand1[:,None,:], axis=2)
  policy_independent = np.zeros(policy_joint.shape)
  for i, a in enumerate(action_list):
      policy_independent[:,i] = policy1[:,a[0]]*policy2[:,a[1]]

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
  N_STATES, N_ACTIONS = int(np.sqrt(n1)), int(np.sqrt(n2))
  if action_list is None:
      action_list = [[a1, a2] for a1 in range(N_ACTIONS) for a2 in range(N_ACTIONS)]

  P_a_single1 = collapse_permutation_matrix(P_a,1)
  P_a_single2 = collapse_permutation_matrix(P_a,2)

  reward1 = collapse_reward(rewards,1)
  reward2 = collapse_reward(rewards,2)

  _, single_policy1 = one_agent_value_iteration(P_a_single1, reward1, gamma, error)
  _, single_policy2 = one_agent_value_iteration(P_a_single2, reward2, gamma, error)

  p1 = np.repeat(single_policy1,N_STATES,axis=0)
  p2 = np.tile(single_policy2,(N_STATES,1))

  policy = np.zeros((p1.shape[0], p1.shape[1]*p2.shape[1]))
  for i, a in enumerate(action_list):
      policy[:,i] = p1[:,a[0]]*p2[:,a[1]]

  return None, policy, p1, p2