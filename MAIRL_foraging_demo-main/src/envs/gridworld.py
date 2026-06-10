import numpy as np
import random


class GridWorld(object):
  """
  Grid world environment for two agents in a collaborative env
  Deterministic transition
  """

  def __init__(self, grid, terminals):
    """
    input:
      grid        2-d list of the grid including the reward as 1: still a marginal map
      terminals   a set of all the terminal states
      trans_prob  transition probability when given a certain action
    """
    self.height = len(grid)
    self.width = len(grid[0])
    self.n_states = self.height*self.width
    for i in range(self.height):
      for j in range(self.width):
        grid[i][j] = str(grid[i][j])

    self.terminals = terminals
    self.grid = grid
    self.neighbors = [(0, 1), (0, -1), (1, 0), (-1, 0), (0, 0)] 
    self.actions = [0, 1, 2, 3, 4]
    self.n_actions = len(self.actions)**2
    self.dirs = {0: 'r', 1: 'l', 2: 'd', 3: 'u', 4: 's'}

  def get_reward(self, state):
    """
    returns the reward on current state
    """
    if state[1] == state[3] and state[0] == state[2]: # only when agent1 and agent2 stay together, there is reward
      if not self.grid[state[0]][state[1]] == 'x': # i.e. that grid element is a number
        return float(self.grid[state[0]][state[1]])
    else:
      return 0
    
  def valid_action(self, action):
    """
    returns
      True if the current move is not going to be out of the grid
      action: (action1, action2)
    """
    inc = self.neighbors[action[0]] + self.neighbors[action[1]]
    nei_s = [int(self._cur_state[i] + inc[i]) for i in range(4)]
    if nei_s[0] < 0 or nei_s[0] >= self.height or nei_s[1] < 0 or nei_s[1] >= self.width:
      return False
    if nei_s[2] < 0 or nei_s[2] >= self.height or nei_s[3] < 0 or nei_s[3] >= self.width:
      return False
    return True
  

  def get_transition_states_and_probs(self, state, action):
    """
    get all the possible transition states and their probabilities with [action] on [state]
    args
      state     (y1, x1, y2, x2)
      action    (action1, action2)
    returns
      a list of (state, probability) pair
    """
    if self.is_terminal(tuple(state)):
      return [(tuple(state), 1)]

    inc = self.neighbors[action[0]] + self.neighbors[action[1]]
    nei_s = [int(state[i] + inc[i]) for i in range(4)]
    if nei_s[0] < 0 or nei_s[0] >= self.height or nei_s[1] < 0 or nei_s[1] >= self.width:
      nei_s[0], nei_s[1] = state[0], state[1]
    if nei_s[2] < 0 or nei_s[2] >= self.height or nei_s[3] < 0 or nei_s[3] >= self.width:
      nei_s[2], nei_s[3] = state[2], state[3]
    return [(tuple(nei_s), 1)]


  def is_terminal(self, state):
    """
    returns
      True if the [state] is terminal
    """
    if tuple(state) in self.terminals:
      return True
    else:
      return False


  def reset(self, start_pos):
    """
    args
      start_pos     (y1,x1,y2,x2) pair of the start location
    """
    self._cur_state = start_pos


  def get_current_state(self):
    return self._cur_state


  def step(self, action):
    """
    Step function for the agent to interact with gridworld
    args
      action        action taken by the agents (2d vector)
    returns
      current_state current state (4d vector)
      action        input action (2d vector)
      next_state    next_state (4d vector)
      reward        reward on the next state
      is_done       True/False - if the agent is already on the terminal states
    """
    if self.is_terminal(self._cur_state):
      self._is_done = True
      return self._cur_state, action, self._cur_state, self.get_reward(self._cur_state), True

    st_prob = self.get_transition_states_and_probs(self._cur_state, action) # (state, prob)
    sampled_idx = np.random.choice(np.arange(0, len(st_prob)), p=[prob for st, prob in st_prob]) # this is deterministic transition 
    last_state = self._cur_state
    next_state = st_prob[sampled_idx][0]
    reward = self.get_reward(next_state)
    self._cur_state = next_state
    return last_state, action, next_state, reward, False


  def get_permutation_mat(self,action_list):
    """
    Generate a permutation matrix V_a(s,a) where V_new = V[V_a[:,a]] for a given action a
    INPUT:
      action_list: a list of tuple (a1,a2)
    OUTPUT:
      P_a: N_STATES^2 X len(action_list)
    """
    N_STATES = self.height**2*self.width**2
    N_ACTIONS = len(action_list)
    P_a = np.zeros((N_STATES, N_ACTIONS))
    for i in range(N_STATES):
      cur = self.idx12pos(i)
      for j, (a1, a2) in enumerate(action_list):
          st_prob = self.get_transition_states_and_probs(cur, (a1,a2))
          nei_s = st_prob[0][0] # only works for deterministic transition
          idx_next = self.pos2idx1(nei_s)
          P_a[i,j] = idx_next
    return P_a


  def pos2idx(self, pos):
    """
    input:
      column-major 4d position
    returns:
      2d index
    """
    return (pos[0]+pos[1]*self.height, pos[2]+pos[3]*self.height)
  
  def idx2pos(self, idx):
    """
    input:
      2d idx
    returns:
      4d column-major position (x1,y1,x2,y2)
    """
    return (idx[0]%self.height, idx[0]//self.height, idx[1]%self.height, idx[1]//self.height)

  def pos2idx1(self,pos):
     """
    input:
      column-major 4d position
    returns:
      1d index (agent1_idx * N^2 + agent2_idx)
    """ 
     idx2 = self.pos2idx(pos)
     return idx2[0] * self.height * self.width + idx2[1]


  def idx12pos(self,idx):
    """
    input:
      1d idx
    returns:
      4d column-major position
    """ 
    idx2 = (idx // (self.height * self.width), idx % (self.height * self.width))
    return self.idx2pos(idx2)
  

class GridWorld_wrapped(GridWorld):
  """
  Grid world environment for two agents in a collaborative env
  Deterministic transition
  With boundaries wrapped to avoid stuck in the corner
  """
  def __init__(self, grid, terminals):
    super().__init__(grid, terminals)

  def get_transition_states_and_probs(self, state, action):
    """
    get all the possible transition states and their probabilities with [action] on [state]
    args
      state     (y1, x1, y2, x2)
      action    (action1, action2)
    returns
      a list of (state, probability) pair
    """
    if self.is_terminal(tuple(state)):
      return [(tuple(state), 1)]

    inc = self.neighbors[action[0]] + self.neighbors[action[1]]
    nei_s = [int(state[i] + inc[i]) for i in range(4)]
    nei_s[0], nei_s[2] = nei_s[0] % self.height, nei_s[2] % self.height
    nei_s[1], nei_s[3] = nei_s[1] % self.width, nei_s[3] % self.width
    return [(tuple(nei_s), 1)]


class GridWorld_SingleAgent(object):
  """
  One Agent
  Deterministic transition
  """

  def __init__(self, grid, terminals):
    """
    input:
      grid        2-d list of the grid including the reward as 1:
      terminals   a set of all the terminal states
    """
    self.height = len(grid)
    self.width = len(grid[0])
    self.n_states = self.height*self.width
    for i in range(self.height):
      for j in range(self.width):
        grid[i][j] = str(grid[i][j])

    self.terminals = terminals
    self.grid = grid
    self.neighbors = [(0, 1), (0, -1), (1, 0), (-1, 0), (0, 0)] 
    self.actions = [0, 1, 2, 3, 4]
    self.n_actions = len(self.actions)
    self.dirs = {0: 'r', 1: 'l', 2: 'd', 3: 'u', 4: 's'}

  def get_reward(self, state):
    """
    returns the reward on current state
    """
    if not self.grid[state[0]][state[1]] == 'x': # i.e. that grid element is a number
      return float(self.grid[state[0]][state[1]])
    else:
      return 0
    
  def get_transition_states_and_probs(self, state, action):
    """
    get all the possible transition states and their probabilities with [action] on [state]
    args
      state     (y,x)
      action    
    returns
      a list of (state, probability) pair
    """
    if self.is_terminal(tuple(state)):
      return [(tuple(state), 1)]

    inc = self.neighbors[action]
    nei_s = [int(state[i] + inc[i]) for i in range(len(state))]
    if nei_s[0] < 0 or nei_s[0] >= self.height or nei_s[1] < 0 or nei_s[1] >= self.width:
      nei_s[0], nei_s[1] = state[0], state[1]
    return [(tuple(nei_s), 1)]


  def is_terminal(self, state):
    """
    returns
      True if the [state] is terminal
    """
    if tuple(state) in self.terminals:
      return True
    else:
      return False


  def reset(self, start_pos):
    """
    Reset the gridworld for model-free learning. It assumes only 1 agent in the gridworld.
    args
      start_pos     (y,x) pair of the start location
    """
    self._cur_state = start_pos


  def get_current_state(self):
    return self._cur_state


  def step(self, action):
    """
    Step function for the agent to interact with gridworld
    args
      action        action taken by the agents (int)
    returns
      current_state current state (2d vector)
      action        input action (int)
      next_state    next_state (2d vector)
      reward        reward on the next state
      is_done       True/False - if the agent is already on the terminal states
    """
    if self.is_terminal(self._cur_state):
      self._is_done = True
      return self._cur_state, action, self._cur_state, self.get_reward(self._cur_state), True

    st_prob = self.get_transition_states_and_probs(self._cur_state, action) # (state, prob)
    sampled_idx = np.random.choice(np.arange(0, len(st_prob)), p=[prob for st, prob in st_prob]) # this is deterministic transition 
    last_state = self._cur_state
    next_state = st_prob[sampled_idx][0]
    reward = self.get_reward(next_state)
    self._cur_state = next_state
    return last_state, action, next_state, reward, False

  def get_permutation_mat(self,action_list=None):
    """
    Generate a permutation matrix V_a(s,a) where V_new = V[V_a[:,a]] for a given action a
    INPUT:
      action_list: a list of tuple (a1,a2)
    OUTPUT:
      P_a: N_STATES^2 X len(action_list)
    """
    if action_list == None:
      action_list = self.actions
    N_STATES = self.height*self.width
    N_ACTIONS = len(action_list)
    P_a = np.zeros((N_STATES, N_ACTIONS))
    for i in range(N_STATES):
      cur = self.idx2pos(i)
      for j, a in enumerate(action_list):
          st_prob = self.get_transition_states_and_probs(cur, a)
          nei_s = st_prob[0][0] # only works for deterministic transition
          idx_next = self.pos2idx(nei_s)
          P_a[i,j] = idx_next
    
    return P_a

  def pos2idx(self, pos):
    """
    input:
      column-major 2d position
    returns:
      index (int)
    """
    return pos[0]+pos[1]*self.height
  
  def idx2pos(self, idx):
    """
    input:
      idx (int)
    returns:
      2d column-major position
    """
    return (idx%self.height, idx//self.height)
  

class GridWorld_v2(GridWorld):
  """
  Grid world environment for two agents in a collaborative env
  Deterministic transition
  Takes height, width, joint reward location and joint terminal locations in as input
  """

  def __init__(self, height, width, r_map, terminals):
    """
    input:
      height, width: dimensions of the grid
      r_map: a joint reward map (N_STATES**2 x 1)
      terminals: a set of all the terminal states
    """
    self.height = height
    self.width = width
    self.n_states = self.height*self.width
    self.terminals = terminals
    self.r_map = r_map
    self.neighbors = [(0, 1), (0, -1), (1, 0), (-1, 0), (0, 0)] 
    self.actions = [0, 1, 2, 3, 4]
    self.n_actions = len(self.actions)
    self.dirs = {0: 'r', 1: 'l', 2: 'd', 3: 'u', 4: 's'}

  def get_reward(self, state):
    """
    returns the reward on current state
    """
    idx = self.pos2idx1(state)
    return self.r_map[idx,0]

  def get_transition_states_and_probs(self, state, action):
    """
    get all the possible transition states and their probabilities with [action] on [state]
    args
    state     (y1, x1, y2, x2)
    action    (action1, action2)
    returns
    a list of (state, probability) pair
    """

    if self.is_terminal(tuple(state)):
      return [(tuple(state), 1)]

    inc = self.neighbors[action[0]] + self.neighbors[action[1]]
    nei_s = [int(state[i] + inc[i]) for i in range(4)]
    if nei_s[0] < 0 or nei_s[0] >= self.height or nei_s[1] < 0 or nei_s[1] >= self.width: # agent1 hits boundary, reset to current_state
      nei_s[0], nei_s[1] = state[0], state[1]
    if nei_s[2] < 0 or nei_s[2] >= self.height or nei_s[3] < 0 or nei_s[3] >= self.width: # agent2 hits boundary, reset to current_state
      nei_s[2], nei_s[3] = state[2], state[3]
    if nei_s[0] == nei_s[2] and nei_s[1] == nei_s[3]: # agent1 and agent2 collide after action, reset to current_state
      nei_s = state
    if nei_s[0] == state[2] and nei_s[1] == state[3] and nei_s[2] == state[0] and nei_s[3] == state[1]: # agent 1 and agent 2 swap positions
      nei_s = state
    
    return [(tuple(nei_s), 1)]


class GridWorld_9action(GridWorld):
  """
  Grid world environment for two agents in a collaborative env
  Deterministic transition
  Nine actions: including the diagonal neighboring states
  """

  def __init__(self, height, width, r_map, terminals):
    """
    State: (y1,x1,y2,x2)
    input:
      height, width: dimensions of the grid
      r_map: a joint reward map (N_STATES**2 x 1)
      terminals: a set of all the terminal states
    """
    self.height = height
    self.width = width
    self.n_states = self.height*self.width
    self.terminals = terminals
    self.grid = r_map
    self.neighbors = [(0, 1), (0, -1), (1, 0), (-1, 0), (0, 0), (1, 1), (-1, 1), (1, -1), (-1, -1)] 
    self.actions = [0, 1, 2, 3, 4, 5, 6, 7, 8]
    self.n_actions = len(self.actions)
    self.dirs = {0: 'r', 1: 'l', 2: 'd', 3: 'u', 4: 's', 5: 'ur', 6: 'dr', 7: 'ul', 8: 'dl'}







class GridWorld_3A(object):
  """
  Grid world environment for THREE agents in a collaborative env
  only contains index transitions
  """

  def __init__(self, height, width, r_map, terminals):
    """
    input:
      grid        2-d list of the grid including the reward as 1: still a marginal map
      terminals   a set of all the terminal states
      trans_prob  transition probability when given a certain action
    """
    self.height = height
    self.width = width
    self.n_states = self.height*self.width
    self.terminals = terminals
    self.r_map = r_map
    self.neighbors = [(0, 1), (0, -1), (1, 0), (-1, 0), (0, 0)] 
    self.actions = [0, 1, 2, 3, 4]
    self.n_actions = len(self.actions)
    self.dirs = {0: 'r', 1: 'l', 2: 'd', 3: 'u', 4: 's'}


  def pos2idx(self, pos):
    """
    input:
      column-major 6d position 
    returns:
      3d index
    """
    return (pos[0]+pos[1]*self.height, pos[2]+pos[3]*self.height, pos[4]+pos[5]*self.height)
  
  def idx2pos(self, idx):
    """
    input:
      3d idx
    returns:
      6d column-major position
    """
    return (idx[0]%self.height, idx[0]//self.height, idx[1]%self.height, idx[1]//self.height, idx[2]%self.height, idx[2]//self.height)

  def pos2idx1(self,pos):
     """
    input:
      column-major 6d position
    returns:
      1d index (agent1_idx * N^2 + agent2_idx * N + agent3_idx)
    """ 
     N = self.height * self.width
     idx3 = self.pos2idx(pos)
     return idx3[0] * N * N + idx3[1] * N + idx3[2]


  def idx12pos(self,idx):
    """
    input:
      1d idx
    returns:
      6d column-major position
    """ 
    N = self.height * self.width
    tmp1, tmp2 = idx // (N * N), idx % (N * N)
    idx = (tmp1, tmp2 // N, tmp2 % N)
    return self.idx2pos(idx)