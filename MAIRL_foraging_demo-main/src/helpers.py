import numpy as np
import torch
import time

def Dv(v, K):
    '''
    Computes D @ v, where D is the blocked difference matrix much more quickly
    '''
    v2 = v.reshape(K, -1)
    v3 = np.hstack((v2[:, 0:1], np.diff(v2, axis=1)))
    v4 = v3.flatten()
    return v4

def Dv_torch(v, K):
    '''
    Computes D @ v, where D is the blocked difference matrix much more quickly
    '''
    v2 = v.reshape(K, -1)
    v3 = torch.hstack((v2[:, 0:1], torch.diff(v2, axis=1)))
    v4 = v3.flatten()
    return v4


def normalize(vals):
    """
    normalize to (0, max_val)
    input:
      vals: 1d array
    """
    min_val = np.min(vals)
    max_val = np.max(vals)
    return (vals - min_val) / (max_val - min_val)


def get_diff_idx(diff_sq,width,height):
    """
    Compute the index in a joint space vector using difference measure on a grid
    INPUT:
        diff_sq: square of grid difference, computed as Euclidean difference
        N: number of states in a single agent space (i.e. height x width)
    OUTPUT:
        an index array such that grid_diff(s(i//N), s(i%N)) = diff
    """
    N = width * height
    idx = []
    for i in range(N**2):
        s1_idx, s2_idx = i // N, i % N
        y1,x1,y2,x2 = s1_idx % height, s1_idx // height, s2_idx % height, s2_idx // height
        if (y1-y2)**2+(x1-x2)**2 == diff_sq:
            idx.append(i)
    return idx


def create_joint_maps(individual_map1, individual_map2, diff_maps, width=None,height=None):
    """
    INPUT:
        individual_map1: (K1 x N_STATES) - m(s1)
        individual_map2: (K2 x N_STATES) - n(s2)
        diff_maps: (N_MAPS x N_diff) - \phi(abs(s1-s2))
    OUTPUT:
        joint_map: ((N_MAPS+K1+K2) X N_STATES**2) 
    """
    K1,N = individual_map1.shape
    K2,N = individual_map2.shape
    if width == None and height == None:
        height, width = int(np.sqrt(N)), int(np.sqrt(N))
    diff_square = np.unique([i**2+j**2 for i in range(height) for j in range(width)])
    K3,diff_N = diff_maps.shape
    assert diff_square.shape[0] == diff_N, 'incampitible size between diff_maps and individual_maps'
    joint_maps = np.zeros((K1+K2+K3, N**2))
    joint_maps[:K1,:] = np.repeat(individual_map1, N, axis=1)
    joint_maps[K1:(K1+K2),:] = np.tile(individual_map2, N)
    for i, diff_sq in enumerate(diff_square):
        idx = get_diff_idx(diff_sq, width,height)
        joint_maps[(K1+K2):(K1+K2+K3),idx] = diff_maps[:,i]
    return joint_maps



def create_joint_maps_pytorch(individual_map1, individual_map2, diff_maps, width=None,height=None):
    """
    INPUT:
        individual_map1: (K1 x N_STATES) - m(s1)
        individual_map2: (K2 x N_STATES) - n(s2)
        diff_maps: (N_MAPS x N_diff) - \phi(abs(s1-s2))
    OUTPUT:
        joint_map: ((N_MAPS+K1+K2) X N_STATES**2) 
    """
    input_type = individual_map1.dtype
    K1, N = individual_map1.shape
    K2, N = individual_map2.shape
    if width == None and height == None:
        height, width = int(torch.sqrt(torch.tensor(N))), int(torch.sqrt(torch.tensor(N)))
    diff_square = torch.unique(torch.tensor([i**2+j**2 for i in range(height) for j in range(width)], dtype=input_type))
    K3, diff_N = diff_maps.shape
    assert diff_square.shape[0] == diff_N, 'incompatible size between diff_maps and individual_maps'
    joint_maps = torch.zeros((K1+K2+K3, N**2),dtype=input_type)
    joint_maps[:K1, :] = individual_map1.repeat_interleave(N, dim=1)
    joint_maps[K1:(K1+K2), :] = individual_map2.repeat(1, N)
    for i, diff_sq in enumerate(diff_square):
        idx = get_diff_idx(diff_sq, width, height)
        joint_maps[(K1+K2):(K1+K2+K3), idx] = diff_maps[:, i]
    return joint_maps

## Version 2 of the interaction map: column difference between two agents

def get_diff_idx_v2(diff,width,height):
    """
    Compute the index in a joint space vector using difference measure on a grid
    INPUT:
        diff: column/row difference, 0 to (height-1)/(width-1)
        N: number of states in a SINGLE agent space (i.e. height x width)
    OUTPUT:
        an index array such that for element i, col_diff(col(i//N), col(i%N)) = diff_col
    """
    N = width * height
    idx_col, idx_relative_col, idx_row = [], [], []
    for i in range(N**2):
        s1_idx, s2_idx = i // N, i % N
        y1,x1,y2,x2 = s1_idx % height, s1_idx // height, s2_idx % height, s2_idx // height
        if abs(y1-y2) == diff:
            idx_row.append(i)
        if abs(x1-x2) == diff:
            idx_col.append(i)
        if x1-x2 == diff:
            idx_relative_col.append(i)
    return idx_row, idx_col, idx_relative_col

def get_diff_idx_v3(row_diff,col_diff,width,height):
    """
    Compute the index in a joint space vector using difference measure on a grid
    INPUT:
        row_diff: row difference, 0 to (height-1)
        col_diff: column difference, 0 to (width-1)
        N: number of states in a SINGLE agent space (i.e. height x width)
    OUTPUT:
        an index array such that for element i, 
            col_diff(i // N, i % N) = col_diff
            row_diff(i // N, i % N) = row_diff
    """
    N = width * height
    idx = []
    for i in range(N**2):
        s1_idx, s2_idx = i // N, i % N
        y1,x1,y2,x2 = s1_idx % height, s1_idx // height, s2_idx % height, s2_idx // height
        if abs(y1-y2) == row_diff and abs(x1-x2) == col_diff:
            idx.append(i)
    return idx

def get_diff_idx_v4(diff,width,height):
    """
    Compute the index in a joint state space using difference measure on a grid
    diff = max(row_diff, col_diff)
    INPUT:
        diff: max(row_diff, col_diff), 0 to max((height-1), (width-1))
        height: height of the grid
        width: width of the grid
        N = height * width
    OUTPUT:
        an index array such that for element i, 
            diff = max(col_diff(i // N, i % N),row_diff(i // N, i % N))
    IMPLEMENTATION:
        s1 = i // N, s2 = i % N
        y1,x1,y2,x2 = s1 % height, s1 // height, s2 % height, s2 // height
        diff = max(abs(y1-y2), abs(x1-x2))
    """
    N = width * height
    idx = []
    for i in range(N**2):
        s1_idx, s2_idx = i // N, i % N
        y1,x1,y2,x2 = s1_idx % height, s1_idx // height, s2_idx % height, s2_idx // height
        if diff == max(abs(y1-y2), abs(x1-x2)):
            idx.append(i)
    return idx


def create_joint_maps_v2(individual_map1, individual_map2, diff_maps, info, width=None,height=None):
    """
    Create joint maps using row different indices
    INPUT:
        individual_map1: (K1 x N_STATES) - m(s1)
        individual_map2: (K2 x N_STATES) - n(s2)
        diff_maps: (N_MAPS x N_diff) - \phi(d(s1,s2))
    OUTPUT:
        joint_map: ((N_MAPS+K1+K2) X N_STATES**2) 
    inter_tag:
        1: absolute row distance
        2: absolute column distance
        3: relative column distance
        4: joint absolute column distance and row distance
        5: absolute circular distance
        6: absolute circular distance and neglect the other agent's map
        7: neglect the other agent's map and the interaction map
        8: neglect the interaction map
    """
    assert 'inter_tag' in info, 'interaction tag not found in info'
    K1,N = individual_map1.shape
    K2,N = individual_map2.shape
    K3 = diff_maps.shape[0]
    if width == None and height == None:
        height, width = int(np.sqrt(N)), int(np.sqrt(N))
    
    # plug in individual maps
    joint_maps = np.zeros((K1+K2+K3, N**2))
    joint_maps[:K1,:] = np.repeat(individual_map1, N, axis=1)
    joint_maps[K1:(K1+K2),:] = np.tile(individual_map2, N)
    if info['inter_tag'] == 6 or info['inter_tag'] == 7: # only keep the self map, zero out the other map
        if info['SingleAgent'] == 1:
            joint_maps[K1:(K1+K2),:] = np.zeros((K2,N**2))
        if info['SingleAgent'] == 2:
            joint_maps[:K1,:] = np.zeros((K1,N**2))

    # plug in the interaction map
    if info['inter_tag'] == 0: # Euclidean distance map
        diff_square = np.unique([i**2+j**2 for i in range(height) for j in range(width)])
        for i, diff_sq in enumerate(diff_square):
            idx = get_diff_idx(diff_sq, width,height)
            joint_maps[(K1+K2):(K1+K2+K3),idx] = diff_maps[:,i]
    if info['inter_tag'] == 1:  # absolute row difference map
        diff_row = np.unique([abs(i-j) for i in range(height) for j in range(height)])
        diff = diff_row
        for i, d in enumerate(diff):
            idx_row,idx_col,idx_relative_col = get_diff_idx_v2(d, width,height)
            joint_maps[(K1+K2):(K1+K2+K3),idx_row] = diff_maps[:,i]
    if info['inter_tag'] == 2: # absolute column difference map
        diff_col = np.unique([abs(i-j) for i in range(width) for j in range(width)])
        diff = diff_col
        for i, d in enumerate(diff):
            idx_row,idx_col,idx_relative_col = get_diff_idx_v2(d, width,height)
            joint_maps[(K1+K2):(K1+K2+K3),idx_col] = diff_maps[:,i]
    if info['inter_tag'] == 3: # relative column difference map
        diff_relative_col = np.unique([i-j for i in range(width) for j in range(width)])
        diff = diff_relative_col
        for i, d in enumerate(diff):
            idx_row,idx_col,idx_relative_col = get_diff_idx_v2(d, width,height)
            joint_maps[(K1+K2):(K1+K2+K3),idx_relative_col] = diff_maps[:,i]
    if info['inter_tag'] == 4: # joint row and column difference map
        diff_row = np.unique([abs(i-j) for i in range(height) for j in range(height)])
        diff_col = np.unique([abs(i-j) for i in range(width) for j in range(width)])
        diff = [(r, c) for r in diff_row for c in diff_col]
        for i, d in enumerate(diff):
            idx = get_diff_idx_v3(d[0], d[1], width, height)
            joint_maps[(K1+K2):(K1+K2+K3),idx] = diff_maps[:,i]
    if info['inter_tag'] == 5 or info['inter_tag'] == 6: # circular distance map
        diff_row = np.unique([abs(i-j) for i in range(height) for j in range(height)])
        diff = diff_row
        for i, d in enumerate(diff):
            idx = get_diff_idx_v4(d, width, height)
            joint_maps[(K1+K2):(K1+K2+K3),idx] = diff_maps[:,i]
    if info['inter_tag'] == 7 or info['inter_tag'] == 8: # zero out the interaction map
        joint_maps[(K1+K2):(K1+K2+K3),:] = np.zeros((K3,N**2))
        
    return joint_maps


def create_joint_maps_pytorch_v2(individual_map1, individual_map2, diff_maps, info, width=None, height=None):
    """
    Create joint maps using row different indices - PYTORCH version
    INPUT:
        individual_map1: (K1 x N_STATES) - m(s1)
        individual_map2: (K2 x N_STATES) - n(s2)
        diff_maps: (N_MAPS x N_diff) - \phi(d(s1,s2))
    OUTPUT:
        joint_map: ((N_MAPS+K1+K2) X N_STATES**2)
    inter_tag:
        1: absolute row distance
        2: absolute column distance
        3: relative column distance
        4: joint absolute column distance and row distance
        5: absolute circular distance
        6: absolute circular distance and neglect the other agent's map
        7: neglect the other agent's map and the interaction map
        8: neglect the interaction map
    """
    assert 'inter_tag' in info, 'interaction tag not found in info'
    K1, N = individual_map1.shape
    K2, N = individual_map2.shape
    K3, diff_N = diff_maps.shape
    if width is None and height is None:
        height, width = int(torch.sqrt(torch.tensor(N))), int(torch.sqrt(torch.tensor(N)))

    input_type = individual_map1.dtype
    joint_maps = torch.zeros((K1 + K2 + K3, N**2), dtype=input_type)

    # plug in individual maps
    joint_maps[:K1, :] = individual_map1.repeat_interleave(N, dim=1)
    joint_maps[K1:(K1 + K2), :] = individual_map2.repeat(1, N)
    if info['inter_tag'] == 6 or info['inter_tag'] == 7:  # only keep the self map, zero out the other map
        if info['SingleAgent'] == 1:
            joint_maps[K1:(K1 + K2), :] = torch.zeros((K2, N**2), dtype=input_type)
        if info['SingleAgent'] == 2:
            joint_maps[:K1, :] = torch.zeros((K1, N**2), dtype=input_type)

    # plug in the interaction map
    if info['inter_tag'] == 0:  # Euclidean distance map
        diff_square = torch.unique(torch.tensor([i**2 + j**2 for i in range(height) for j in range(width)], dtype=input_type))
        for i, diff_sq in enumerate(diff_square):
            idx = get_diff_idx(diff_sq.item(), width, height)
            joint_maps[(K1 + K2):(K1 + K2 + K3), idx] = diff_maps[:, i]
    if info['inter_tag'] == 1:  # absolute row difference map
        diff_row = torch.unique(torch.tensor([abs(i - j) for i in range(height) for j in range(height)], dtype=input_type))
        for i, d in enumerate(diff_row):
            idx_row, _, _ = get_diff_idx_v2(d.item(), width, height)
            joint_maps[(K1 + K2):(K1 + K2 + K3), idx_row] = diff_maps[:, i]
    if info['inter_tag'] == 2:  # absolute column difference map
        diff_col = torch.unique(torch.tensor([abs(i - j) for i in range(width) for j in range(width)], dtype=input_type))
        for i, d in enumerate(diff_col):
            _, idx_col, _ = get_diff_idx_v2(d.item(), width, height)
            joint_maps[(K1 + K2):(K1 + K2 + K3), idx_col] = diff_maps[:, i]
    if info['inter_tag'] == 3:  # relative column difference map
        diff_relative_col = torch.unique(torch.tensor([i - j for i in range(width) for j in range(width)], dtype=input_type))
        for i, d in enumerate(diff_relative_col):
            _, _, idx_relative_col = get_diff_idx_v2(d.item(), width, height)
            joint_maps[(K1 + K2):(K1 + K2 + K3), idx_relative_col] = diff_maps[:, i]
    if info['inter_tag'] == 4:  # joint row and column difference map
        diff_row = torch.unique(torch.tensor([abs(i - j) for i in range(height) for j in range(height)], dtype=input_type))
        diff_col = torch.unique(torch.tensor([abs(i - j) for i in range(width) for j in range(width)], dtype=input_type))
        diff = [(r, c) for r in diff_row for c in diff_col]
        for i, d in enumerate(diff):
            idx = get_diff_idx_v3(d[0].item(), d[1].item(), width, height)
            joint_maps[(K1 + K2):(K1 + K2 + K3), idx] = diff_maps[:, i]
    if info['inter_tag'] == 5 or info['inter_tag'] == 6:  # circular distance map
        diff_row = torch.unique(torch.tensor([abs(i - j) for i in range(height) for j in range(height)], dtype=input_type))
        for i, d in enumerate(diff_row):
            idx = get_diff_idx_v4(d.item(), width, height)
            joint_maps[(K1 + K2):(K1 + K2 + K3), idx] = diff_maps[:, i]
    if info['inter_tag'] == 7 or info['inter_tag'] == 8:  # zero out the interaction map
        joint_maps[(K1 + K2):(K1 + K2 + K3), :] = torch.zeros((K3, N**2), dtype=input_type)

    return joint_maps



def create_joint_maps_HD(individual_map1, individual_map2, diff_maps, info, width, height):
    """
    ONLY WORKS FOR N_MPAS = 1 & inter_tag = 5 and 6
    r(s_1,s_2|θ) = m(s_1) + n(s_2) + φ(d|θ)
    INPUT:
        individual_map1: (1 x N_STATES) numpy array
        individual_map2: (1 x N_STATES) numpy array
        diff_maps: (1 x N_diff x N_ANGLES(**2)) numpy array
        info: dictionary with key 'inter_tag'
        width: grid width
        height: grid height
    OUTPUT:
        joint_map: (3 x N_STATES**2 x N_ANGLES(**2)) numpy array
    inter_tag:
        5: absolute circular distance map
    """
    assert 'inter_tag' in info, 'interaction tag not found in info'
    K1, n2 = individual_map1.shape
    K2, n4 = individual_map2.shape
    assert K1 == 1 and K2 == 1 and n2 == n4 and n2 == width * height, 'individual map size mismatch'
    N_STATES = n2
    K3, n_diff, N_ANGLES = diff_maps.shape
    assert K3 == 1, 'diff_maps size mismatch'

    # Initialize joint maps: agent 1, agent 2, and interaction map.
    joint_maps = np.zeros((3, N_STATES**2, N_ANGLES), dtype=individual_map1.dtype)

    # Plug in agent maps: repeat and tile to fill the angle dimension
    agent1_full = np.repeat(individual_map1, N_STATES, axis=1).reshape(-1, 1)
    agent2_full = np.tile(individual_map2, (1, N_STATES)).reshape(-1, 1)
    joint_maps[:1,:,:] = np.repeat(agent1_full, N_ANGLES, axis=1)
    joint_maps[1:2,:,:] = np.repeat(agent2_full, N_ANGLES, axis=1)

    if info['inter_tag'] == 5 or info['inter_tag'] == 6:
        diff_row = np.unique(np.array([abs(i - j) for i in range(height) for j in range(height)],
                                        dtype=individual_map1.dtype))
        for i, d in enumerate(diff_row):
            idx = get_diff_idx_v4(d, width, height)
            for angle in range(N_ANGLES):
                joint_maps[2, idx, angle] = diff_maps[0, i, angle]
    else:
        raise ValueError('interaction tag not supported')
                
    return joint_maps


def create_joint_maps_HD_pytorch(individual_map1, individual_map2, diff_maps, info, width, height):
    """
    ONLY WORKS FOR N_MPAS = 1 & inter_tag = 5 and 6
    r(s_1,s_2|\theta) = m(s_1) + n(s_2) + \phi(d|\theta)
    INPUT:
        individual_map1: (1 x N_STATES) 
        individual_map2: (1 x N_STATES)
        diff_maps: (1 x N_diff x N_ANGLES(**2)
    OUTPUT:
        joint_map: (3 X N_STATES**2 x N_ANGLES(**2) 
    inter_tag:
        5: absolute circular distance
    """
    assert 'inter_tag' in info, 'interaction tag not found in info'
    K1,n2 = individual_map1.shape
    K2,n4 = individual_map2.shape
    assert K1 == 1 and K2 == 1 and n2 == n4 and n2 == width*height, 'individual map size mismatch'
    N_STATES = n2
    K3,n4,n5 = diff_maps.shape
    assert K3 == 1, 'individual map size mismatch'

    # plug in individual maps
    joint_maps = torch.zeros((3, N_STATES**2, n5), dtype=individual_map1.dtype)
    joint_maps[:1, :, :] = individual_map1.repeat_interleave(N_STATES, dim=1).unsqueeze(2)
    joint_maps[1:2, :, :] = individual_map2.repeat(1, N_STATES).unsqueeze(2)
    if info['inter_tag'] == 5 or info['inter_tag'] == 6:  # circular distance map
        diff_row = torch.unique(torch.tensor([abs(i - j) for i in range(height) for j in range(height)], dtype=individual_map1.dtype))
        diff = diff_row
        for i, d in enumerate(diff):
            idx = get_diff_idx_v4(d, width, height)
            for angle in range(n5):
                joint_maps[2:3, idx, angle] = diff_maps[:,i,angle].unsqueeze(1)
    else:
        raise ValueError('interaction tag not supported')
        
    return joint_maps













def init_diff_map(info, generative_params, height, width):
    if info['inter_tag'] == 0:
        print('Using square difference interaction function')
        diff_square = np.unique([i**2+j**2 for i in range(height) for j in range(width)])
        diff_map = diff_square.reshape((1,diff_square.shape[0]))
        diff_map = 1 / (diff_map+1) # default for a collaborative task
        if 'diff_map_guess' in generative_params: # if pre-specified, use that
            diff_map = generative_params['diff_map_guess']
    elif info['inter_tag'] == 1:
        print('Using column difference interaction function')
        diff_col = np.unique([abs(i-j) for i in range(height) for j in range(height)])
        diff_map = np.random.uniform(size=(1, diff_col.shape[0]))
    elif info['inter_tag'] == 2:
        print('Using row difference interaction function')
        diff_row = np.unique([abs(i-j) for i in range(width) for j in range(width)])
        diff_map = np.random.uniform(size=(1, diff_row.shape[0]))
    elif info['inter_tag'] == 3:
        print('Using relative column difference interaction function')
        diff_col = np.unique([i-j for i in range(width) for j in range(width)])
        diff_map = np.random.uniform(size=(1, diff_col.shape[0]))
    elif info['inter_tag'] == 4:
        print('Using both row diff and column diff as interaction function')
        diff_row = np.unique([abs(i-j) for i in range(height) for j in range(height)])
        diff_col = np.unique([abs(i-j) for i in range(width) for j in range(width)])
        diff_map = np.random.uniform(size=(1,diff_row.shape[0]*diff_col.shape[0]))
    elif info['inter_tag'] == 5 or info['inter_tag'] == 6:
        print('Using the maximum of row and column difference as interaction function (equivalent to circular distance)')
        diff_row = np.unique([abs(i-j) for i in range(height) for j in range(height)])
        diff_col = np.unique([abs(i-j) for i in range(width) for j in range(width)])
        diff_map = np.random.uniform(size=(1,max(diff_row.shape[0],diff_col.shape[0])))
    elif info['inter_tag'] == 7 or info['inter_tag'] == 8 or info['inter_tag'] == 9:
        diff_map = np.zeros((1, height))
    return diff_map



def collapse_permutation_matrix(P_a, i):
    '''
    collapse the joint permutation matrix to a single agent
    INPUT:
        i (= 1 or 2): agent index to keep
    '''
    assert i in [1,2], 'error in agent index'
    n1,n2 = P_a.shape
    N_STATES, N_ACTIONS = int(np.sqrt(n1)), int(np.sqrt(n2))
    if i == 2:
        P_a_single = (P_a % N_STATES)[:N_STATES,:N_ACTIONS]
    elif i == 1:
        P_a_single = (P_a // N_STATES)[::N_STATES,::N_ACTIONS]
    return P_a_single


def collapse_permutation_matrix_pytorch(P_a, i):
    '''
    collapse the joint permutation matrix to a single agent
    INPUT:
        i (= 1 or 2): agent index to keep
    '''
    assert i in [1,2], 'error in agent index'
    n1,n2 = P_a.shape
    N_STATES, N_ACTIONS = int(torch.sqrt(torch.tensor(n1))), int(torch.sqrt(torch.tensor(n2)))
    if i == 2:
        P_a_single = (P_a % N_STATES)[:N_STATES,:N_ACTIONS]
    elif i == 1:
        P_a_single = (P_a // N_STATES)[::N_STATES,::N_ACTIONS]
    return P_a_single


def collapse_reward(reward, agent):
    '''
    collapse the joint reward to a single agent
    INPUT:
        reward: (N_STATES**2 x 1)
        agent (= 1 or 2): agent index to keep
    '''
    N_STATES = int(np.sqrt(reward.shape[0]))
    reward_single = np.zeros((N_STATES,1))
    if agent == 1:
        for i in range(N_STATES):
            reward_single[i,:] = np.sum(reward[i*N_STATES:(i+1)*N_STATES,:])
    elif agent == 2:
        for i in range(N_STATES):
            reward_single[i,:] = np.sum(reward[i::N_STATES,:])
    return reward_single


def collapse_reward_pytorch(reward,agent):
    '''
    collapse the joint reward to a single agent
    INPUT:
        reward: (N_STATES**2 x 1)
        agent (= 1 or 2): agent index to keep
    '''
    N_STATES = int(torch.sqrt(torch.tensor(reward.shape[0])))
    reward_single = torch.zeros((N_STATES,1))
    if agent == 1:
        for i in range(N_STATES):
            reward_single[i,0] = torch.sum(reward[i*N_STATES:(i+1)*N_STATES,0])
    elif agent == 2:
        for i in range(N_STATES):
            reward_single[i,0] = torch.sum(reward[i::N_STATES,0])
    return reward_single

def compute_marginals_and_conditionals(policy_joint, action_list):
    '''
    INPUT:
        policy_joint: (N_STATES**2 x N_ACTIONS**2) - joint policy
        action_list: list of tuples, each tuple is a joint action
    OUTPUT:
        p1: (N_STATES**2 x N_ACTIONS) - marginal, \pi(a1|s1,s2)
        p2: (N_STATES**2 x N_ACTIONS) - marginal, \pi(a2|s1,s2)
        c1: (N_STATES**2 x N_ACTIONS x N_ACTIONS) - c1(s,a1,a2) = \pi(a1|a2,s)
        c2: (N_STATES**2 x N_ACTIONS x N_ACTIONS) - c2(s,a2,a1) = \pi(a2|a1,s)
    '''
    n1,n2 = policy_joint.shape
    N_STATES, N_ACTIONS = int(np.sqrt(n1)), int(np.sqrt(n2))
    
    idx1 = []
    for a1 in range(N_ACTIONS):
      idx1.append([i for i, ele in enumerate(action_list) if ele[0] == a1])
    idx2 = []
    for a2 in range(N_ACTIONS):
      idx2.append([i for i, ele in enumerate(action_list) if ele[1] == a2])

    p1 = np.hstack([np.sum(policy_joint[:, idx1[i]], axis=1)[:, None] for i in range(N_ACTIONS)])  # marginal, \pi(a1|s1,s2)
    p2 = np.hstack([np.sum(policy_joint[:, idx2[i]], axis=1)[:, None] for i in range(N_ACTIONS)])  # marginal, \pi(a2|s1,s2)
    c1 = np.zeros((N_STATES**2, N_ACTIONS, N_ACTIONS))  # c1(s,a1,a2) = \pi(a1|a2,s)
    c2 = np.zeros((N_STATES**2, N_ACTIONS, N_ACTIONS))  # c2(s,a2,a1) = \pi(a2|a1,s)
    for a_idx in range(N_ACTIONS):
      c1[:, :, a_idx] = policy_joint[:, idx2[a_idx]] / np.hstack([p2[:, a_idx][:, None] for _ in range(N_ACTIONS)])
      c2[:, :, a_idx] = policy_joint[:, idx1[a_idx]] / np.hstack([p1[:, a_idx][:, None] for _ in range(N_ACTIONS)])
    
    return p1, p2, c1, c2


def compute_marginals_and_conditionals_pytorch(policy_joint, action_list):
    '''
    INPUT:
        policy_joint: (N_STATES**2 x N_ACTIONS**2) - joint policy
        action_list: list of tuples, each tuple is a joint action
    OUTPUT:
        p1: (N_STATES**2 x N_ACTIONS) - marginal, \pi(a1|s1,s2)
        p2: (N_STATES**2 x N_ACTIONS) - marginal, \pi(a2|s1,s2)
        c1: (N_STATES**2 x N_ACTIONS x N_ACTIONS) - c1(s,a1,a2) = \pi(a1|a2,s)
        c2: (N_STATES**2 x N_ACTIONS x N_ACTIONS) - c2(s,a2,a1) = \pi(a2|a1,s)
    '''
    n1, n2 = policy_joint.shape
    N_STATES, N_ACTIONS = int(torch.sqrt(torch.tensor(n1))), int(torch.sqrt(torch.tensor(n2)))
    
    idx1 = []
    for a1 in range(N_ACTIONS):
        idx1.append([i for i, ele in enumerate(action_list) if ele[0] == a1])
    idx2 = []
    for a2 in range(N_ACTIONS):
        idx2.append([i for i, ele in enumerate(action_list) if ele[1] == a2])

    p1 = torch.hstack([torch.sum(policy_joint[:, idx1[i]], dim=1, keepdim=True) for i in range(N_ACTIONS)])  # marginal, \pi(a1|s1,s2)
    p2 = torch.hstack([torch.sum(policy_joint[:, idx2[i]], dim=1, keepdim=True) for i in range(N_ACTIONS)])  # marginal, \pi(a2|s1,s2)
    c1 = torch.zeros((N_STATES**2, N_ACTIONS, N_ACTIONS))  # c1(s,a1,a2) = \pi(a1|a2,s)
    c2 = torch.zeros((N_STATES**2, N_ACTIONS, N_ACTIONS))  # c2(s,a2,a1) = \pi(a2|a1,s)
    for a_idx in range(N_ACTIONS):
        c1[:, :, a_idx] = policy_joint[:, idx2[a_idx]] / p2[:, a_idx].unsqueeze(1)
        c2[:, :, a_idx] = policy_joint[:, idx1[a_idx]] / p1[:, a_idx].unsqueeze(1)
    
    return p1, p2, c1, c2



def extract_state_action_pair(trajectories, info):
    state_action_pairs = []
    if info['HD']:
        for _, traj in enumerate(trajectories):
            actions = np.array(traj['actions'])[:,np.newaxis]
            states = np.array(traj['states'][:-1])[:,np.newaxis]
            angles = np.array(traj['angles'][:-1])[:,np.newaxis]
            assert len(states) == len (actions), "states and action sequences dont have the same length"
            state_action_pairs_this_traj = np.concatenate((states, actions, angles), axis=1)
            state_action_pairs.append(state_action_pairs_this_traj)
    else:
        for _, traj in enumerate(trajectories):
            actions = np.array(traj['actions'])[:,np.newaxis]
            states = np.array(traj['states'][:-1])[:,np.newaxis]
            assert len(states) == len (actions), "states and action sequences dont have the same length"
            state_action_pairs_this_traj = np.concatenate((states, actions), axis=1)
            state_action_pairs.append(state_action_pairs_this_traj)
    return state_action_pairs
