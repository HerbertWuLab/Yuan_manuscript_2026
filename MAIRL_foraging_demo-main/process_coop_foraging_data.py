# Data processing stream:
#   Main_traj_preprocessing.m:  ptable  -->  *_traj_neck.txt
#   process_coop_foraging_data.py: *_traj_neck.txt --> 

import pickle
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from src.envs import gridworld
import argparse, os
from plot_utils.plot_simulated_data_gridworld import plot_gridworld_trajectories


def to_grid(x, y, grid_size):
    x_trunc = np.clip(x, -45/2, 45/2) + 45/2
    y_trunc = np.clip(y, -45/2, 45/2) + 45/2
    return np.floor(x_trunc / grid_size).astype(int), np.floor(y_trunc / grid_size).astype(int)

def to_angle_bin(angle, angle_bin):
    # angle: 0-360 degree
    # if angle_bin = 180, then [90-270) degree is 1, [270,360) and [0,90) degree is 0
    angle_bz = int(360 / angle_bin)
    angle_idx = np.floor((angle+angle_bin/2) / angle_bin).astype(int)
    return np.mod(angle_idx, angle_bz)

def remove_repetitive_rows(array):
    result = [array[0]] 
    idx = [0]
    for i in range(1, len(array)):
        if not np.array_equal(array[i], result[-1]):  # Check if the current row is not identical to the last kept row
            result.append(array[i])
            idx.append(i)
    return np.array(result), idx

def angle2idx(angle1,angle2,angle_bin):
    return angle1 * angle_bin + angle2

def idx2angle(idx,angle_bin):
    return idx // angle_bin, idx % angle_bin

def generate_expert_trajs(m1_trials, m2_trials, correct_trials, gw, grid_size, args):
    m1_grid = [to_grid(x, y, grid_size) for x, y in m1_trials]
    m2_grid = [to_grid(x, y, grid_size) for x, y in m2_trials]
    if args.remove_rep:
        m1_grid_nonrep, m2_grid_nonrep = [], []
        for i in range(len(m1_grid)):
            combined = np.stack((m1_grid[i][0], m1_grid[i][1], m2_grid[i][0], m2_grid[i][1]), axis=1)
            combined_nonrep, _ = remove_repetitive_rows(combined)
            m1_grid_nonrep.append((combined_nonrep[:,0], combined_nonrep[:,1]))
            m2_grid_nonrep.append((combined_nonrep[:,2], combined_nonrep[:,3]))
        m1_grid, m2_grid = m1_grid_nonrep, m2_grid_nonrep
        
    trajs_all_experts = []
    action_list = [(i,j) for i in range(len(gw.actions)) for j in range(len(gw.actions))]
    for expert in range(len(m1_grid)):
        actions, actions2d = [], []
        rewards = [0]
        states4d = [(m1_grid[expert][0][0], m1_grid[expert][1][0], m2_grid[expert][0][0], m2_grid[expert][1][0])]
        states = [gw.pos2idx1(states4d[0])]
        for i in range(1, len(m1_grid[expert][0])):
            s = (m1_grid[expert][0][i], m1_grid[expert][1][i], m2_grid[expert][0][i], m2_grid[expert][1][i])
            s_idx = gw.pos2idx1(s)
            s_previous = states4d[-1]
            # inc1 = (s_previous[0] - s[0], s_previous[1] - s[1])
            # inc2 = (s_previous[2] - s[2], s_previous[3] - s[3])
            inc1 = (s[0] - s_previous[0], s[1] - s_previous[1])
            inc2 = (s[2] - s_previous[2], s[3] - s_previous[3])
            if inc1 not in gw.neighbors or inc2 not in gw.neighbors:
                print('Invalid action:', inc1, inc2)
                break
            action_idx1 = gw.neighbors.index(inc1)
            action_idx2 = gw.neighbors.index(inc2)
            a2d = (action_idx1, action_idx2)
            actions2d.append(a2d)
            actions.append(action_list.index(a2d))
            states4d.append(s)
            states.append(s_idx)
            rewards.append(0)
        if correct_trials[expert] == 1:
            rewards[-1] = 1
        traj = {'states': np.array(states), 'states4d': np.array(states4d),
                'actions': np.array(actions), 'actions2d': np.array(actions2d),
                'rewards': np.array(rewards)}
        trajs_all_experts.append(traj)
    return trajs_all_experts


def generate_expert_trajs_HD(m1_trials, m2_trials, ego1_trials, ego2_trials, correct_trials, gw, args):
    # generate expert trajectories with head direction information 
    m1_grid = [to_grid(x, y, args.grid_size) for x, y in m1_trials]
    m2_grid = [to_grid(x, y, args.grid_size) for x, y in m2_trials]
    ego1_grid = [to_angle_bin(angle, args.angle_bin) for angle in ego1_trials]
    ego2_grid = [to_angle_bin(angle, args.angle_bin) for angle in ego2_trials]
    if args.remove_rep:
        m1_grid_nonrep, m2_grid_nonrep = [], []
        ego1_grid_nonrep, ego2_grid_nonrep = [], []
        for i in range(len(m1_grid)): # loop over trials
            combined = np.stack((m1_grid[i][0], m1_grid[i][1], m2_grid[i][0], m2_grid[i][1], ego1_grid[i], ego2_grid[i]), axis=1)
            combined_nonrep,_ = remove_repetitive_rows(combined)
            m1_grid_nonrep.append((combined_nonrep[:,0], combined_nonrep[:,1]))
            m2_grid_nonrep.append((combined_nonrep[:,2], combined_nonrep[:,3]))
            ego1_grid_nonrep.append(combined_nonrep[:,4])
            ego2_grid_nonrep.append(combined_nonrep[:,5])
        m1_grid, m2_grid = m1_grid_nonrep, m2_grid_nonrep
        ego1_grid, ego2_grid = ego1_grid_nonrep, ego2_grid_nonrep
    if args.remove_state_rep:
        m1_grid_nonrep, m2_grid_nonrep = [], []
        ego1_grid_nonrep, ego2_grid_nonrep = [], []
        for i in range(len(m1_grid)): # loop over trials
            combined = np.stack((m1_grid[i][0], m1_grid[i][1], m2_grid[i][0], m2_grid[i][1]), axis=1)
            combined_nonrep, idx = remove_repetitive_rows(combined)
            m1_grid_nonrep.append((combined_nonrep[:,0], combined_nonrep[:,1]))
            m2_grid_nonrep.append((combined_nonrep[:,2], combined_nonrep[:,3]))
            ego1_grid_nonrep.append(ego1_grid[i][idx])
            ego2_grid_nonrep.append(ego2_grid[i][idx])
        m1_grid, m2_grid = m1_grid_nonrep, m2_grid_nonrep
        ego1_grid, ego2_grid = ego1_grid_nonrep, ego2_grid_nonrep


    trajs_all_experts = []
    action_list = [(i,j) for i in range(len(gw.actions)) for j in range(len(gw.actions))]
    for expert in range(len(m1_grid)):
        actions, actions2d = [], []
        rewards = [0]
        states4d = [(m1_grid[expert][0][0], m1_grid[expert][1][0], m2_grid[expert][0][0], m2_grid[expert][1][0])]
        states = [gw.pos2idx1(states4d[0])]
        angles2d = [(ego1_grid[expert][0], ego2_grid[expert][0])]
        angles = [angle2idx(ego1_grid[expert][0], ego2_grid[expert][0], int(360/args.angle_bin))]
        for i in range(1, len(m1_grid[expert][0])):
            s = (m1_grid[expert][0][i], m1_grid[expert][1][i], m2_grid[expert][0][i], m2_grid[expert][1][i])
            s_idx = gw.pos2idx1(s)
            s_previous = states4d[-1]
            # inc1 = (s_previous[0] - s[0], s_previous[1] - s[1])
            # inc2 = (s_previous[2] - s[2], s_previous[3] - s[3])
            inc1 = (s[0] - s_previous[0], s[1] - s_previous[1])
            inc2 = (s[2] - s_previous[2], s[3] - s_previous[3])
            if inc1 not in gw.neighbors or inc2 not in gw.neighbors:
                print('Invalid action:', inc1, inc2)
                break
            action_idx1 = gw.neighbors.index(inc1)
            action_idx2 = gw.neighbors.index(inc2)
            a2d = (action_idx1, action_idx2)
            actions2d.append(a2d)
            actions.append(action_list.index(a2d))
            states4d.append(s)
            states.append(s_idx)
            angles2d.append((ego1_grid[expert][i], ego2_grid[expert][i]))
            angles.append(angle2idx(ego1_grid[expert][i], ego2_grid[expert][i], int(360/args.angle_bin)))
            rewards.append(0)
        if correct_trials[expert] == 1:
            rewards[-1] = 1
        traj = {'states': np.array(states), 'states4d': np.array(states4d),
                'actions': np.array(actions), 'actions2d': np.array(actions2d),
                'angles': np.array(angles), 'angles2d': np.array(angles2d),
                'rewards': np.array(rewards)}
        trajs_all_experts.append(traj)
    return trajs_all_experts


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--name', type=str, default='YC027YC028_20231002_traj_neck')
    parser.add_argument('--grid_size', type=int, default=5, help='grid size (cm) for discretization, the whole arena is 45cm x 45 cm (default: 5)')
    parser.add_argument('--remove_rep', action='store_true', help='remove repeated trials')
    parser.add_argument('--remove_state_rep', action='store_true', help='remove repeated states in trials')
    parser.add_argument('--save_tag', type=str, default='', help='tag for saving after data name')
    parser.add_argument('--HD', action='store_true', help='use egocentric angle representation of others')
    parser.add_argument('--AHD', action='store_true', help='use allocentric angle representation of others')
    parser.add_argument('--angle_bin', type=int, default=180, help='angle bin size for discretization (default: 180 degree)')
    args = parser.parse_args()

    name = args.name
    grid_size = args.grid_size
    generative_parameters = {}
    generative_parameters['grid_size'] = grid_size
    generative_parameters['angle_bin'] = args.angle_bin
    angle_sz = int(360/args.angle_bin)
    save_tag = args.save_tag
    if args.HD:
        save_tag = '_HD'+str(angle_sz)+args.save_tag
    elif args.AHD:
        save_tag = '_AHD'+str(angle_sz)+args.save_tag
    save_dir = 'data/experiment_coop_foraging/'+name+'_gz'+str(grid_size) + save_tag
    os.makedirs(save_dir, exist_ok=True)

    data = pd.read_csv('data/experiment_coop_foraging/'+name+'.txt', delimiter='\t')
    data_select = data
    print('Number of trials:', len(data_select['trial_no'].unique()))
    print('Column names:', data_select.columns.values)   

    m1_trials, m2_trials, correct_trials = [], [], []
    trial_uniques = data_select['trial_no'].unique()
    for trial in trial_uniques:
        traj_trial = data_select[data_select['trial_no'] == trial]
        # x1, y1, x2, y2 = traj_trial.iloc[:, 2].values, traj_trial.iloc[:, 3].values, traj_trial.iloc[:, 4].values, traj_trial.iloc[:, 5].values
        x1, y1 = traj_trial['m1_neck_x'].values, traj_trial['m1_neck_y'].values
        x2, y2 = traj_trial['m2_neck_x'].values, traj_trial['m2_neck_y'].values
        m1_trials.append([x1,y1])
        m2_trials.append([x2,y2])
        correct_trials.append(traj_trial.correct.values[0])

    height, width = int(45/grid_size)+1, int(45/grid_size)+1
    r_map = np.zeros((height, width)).astype(int)
    r_map[int(width/2), height-1] = 1
    r_map[width-1, int(height/2)] = 1
    gw = gridworld.GridWorld_9action(height,width,r_map,{})
    action_list = [(i,j) for i in range(len(gw.actions)) for j in range(len(gw.actions))]
    P_a = gw.get_permutation_mat(action_list)

    if args.HD:
        HD1_trials, HD2_trials = [], [] # egocentric representation of other's location
        for trial in trial_uniques:
            traj_trial = data_select[data_select['trial_no'] == trial]
            allo_x = traj_trial['m2_neck_x'].values - traj_trial['m1_neck_y'].values
            allo_y = traj_trial['m2_neck_y'].values - traj_trial['m1_neck_y'].values
            allo1_dg = np.mod(np.rad2deg(np.arctan2(allo_y, allo_x)), 360)
            allo2_dg = np.mod(np.rad2deg(np.arctan2(-allo_y, -allo_x)), 360)
            hd1_x, hd1_y = traj_trial['m1_nose_x'].values - traj_trial['m1_neck_x'].values, traj_trial['m1_nose_y'].values - traj_trial['m1_neck_y'].values
            hd2_x, hd2_y = traj_trial['m2_nose_x'].values - traj_trial['m2_neck_x'].values, traj_trial['m2_nose_y'].values - traj_trial['m2_neck_y'].values
            hd1_dg = np.rad2deg(np.arctan2(hd1_y, hd1_x))
            hd2_dg = np.rad2deg(np.arctan2(hd2_y, hd2_x))
            ego1_dg = np.mod(allo1_dg - hd1_dg, 360)
            ego2_dg = np.mod(allo2_dg - hd2_dg, 360)
            HD1_trials.append(ego1_dg)
            HD2_trials.append(ego2_dg)
        
    if args.AHD:
        HD1_trials, HD2_trials = [], [] # allocentric 
        for trial in trial_uniques:
            traj_trial = data_select[data_select['trial_no'] == trial]
            allo_x = traj_trial['m2_neck_x'].values - traj_trial['m1_neck_y'].values
            allo_y = traj_trial['m2_neck_y'].values - traj_trial['m1_neck_y'].values
            allo1_dg = np.mod(np.rad2deg(np.arctan2(allo_y, allo_x)), 360)
            allo2_dg = np.mod(np.rad2deg(np.arctan2(-allo_y, -allo_x)), 360)
            HD1_trials.append(allo1_dg)
            HD2_trials.append(allo2_dg)

    if args.HD or args.AHD:
        trajs_all_experts = generate_expert_trajs_HD(m1_trials, m2_trials, HD1_trials, HD2_trials, correct_trials, gw, args)
    else:
        trajs_all_experts = generate_expert_trajs(m1_trials, m2_trials, correct_trials, gw, grid_size, args)

    # get stats and save into *.pickle
    occ1 = np.zeros((height, width))
    occ2 = np.zeros((height, width))
    dist = np.zeros((height,1))
    for traj in trajs_all_experts:
        for (a,b,c,d) in traj['states4d']:
            occ1[a,b] += 1
            occ2[c,d] += 1
            dist_idx = max(abs(a-c), abs(b-d))
            if dist_idx > height-1:
                print(a,b,c,d)
            dist[dist_idx] += 1

    generative_parameters['P_a'] = P_a
    generative_parameters['success_rate'] = np.mean(correct_trials)
    print('Success rate:', generative_parameters['success_rate'])
    generative_parameters['sigmas'] = 0.01
    generative_parameters['occ1'] = occ1 / max(occ1.flatten())
    generative_parameters['occ2'] = occ2 / max(occ2.flatten())
    generative_parameters['dist'] = dist / max(dist.flatten())


    with open(save_dir+'/expert_trajectories.pickle','wb') as handle:
        pickle.dump(trajs_all_experts, handle, protocol=pickle.HIGHEST_PROTOCOL)
    with open(save_dir+'/generative_parameters.pickle', 'wb') as handle:
        pickle.dump(generative_parameters, handle,protocol=pickle.HIGHEST_PROTOCOL)


    # Begin plotting
    fig = plt.figure(figsize=(5, 5))
    for i in [0, 5, 10, 15, 20]:
        x1, y1 = m1_trials[i]
        x2, y2 = m2_trials[i]
        plt.plot(x1, y1, label='m1', color='blue', alpha=0.5)
        plt.plot(x2, y2, label='m2', color='orange', alpha=0.5)
        plt.scatter([x1[0], x2[0]], [y1[0], y2[0]], color='red', zorder=5)
        plt.scatter([x1[-1], x2[-1]], [y1[-1], y2[-1]], color='red', marker='x', zorder=5)
    plt.xlim([-45/2,45/2]); plt.ylim([-45/2,45/2])
    plt.grid(True, which='both', linestyle='--', linewidth=0.5)
    plt.xlabel('X Coordinate')
    plt.ylabel('Y Coordinate')
    # plt.legend()
    plt.title('Trajectory Plot: {:.2f}'.format(generative_parameters['success_rate']))
    fig.savefig(save_dir+'/traj_actual.png')

    # Plot gridworld
    for i in [0, 5, 10, 15, 20]:
        traj = trajs_all_experts[i]
        traj1 = np.array([(a,b) for (a,b,c,d) in traj['states4d']])
        traj2 = np.array([(c,d) for (a,b,c,d) in traj['states4d']])
        fig, ax = plt.subplots(1,3, figsize=(15,4))
        x1, y1 = m1_trials[i]
        x2, y2 = m2_trials[i]
        ax[0].plot(y1, x1, label='m1', color='blue', alpha=0.5)
        ax[0].plot(y2, x2, label='m2', color='orange', alpha=0.5)
        ax[0].scatter([y1[0], y2[0]], [x1[0], x2[0]], color='red', zorder=5)
        ax[0].scatter([y1[-1], y2[-1]], [x1[-1], x2[-1]], color='red', marker='x', zorder=5)
        ax[0].set_xlim([-45/2,45/2]); ax[0].set_ylim([-45/2,45/2])
        ax[0].grid(True, which='both', linestyle='--', linewidth=0.5)
        plot_gridworld_trajectories(height, width, {'states2d':traj1}, fig, ax[1])
        plot_gridworld_trajectories(height, width, {'states2d':traj2}, fig, ax[2])
        ax[1].invert_yaxis()
        ax[2].invert_yaxis()
        ax[1].set_title('Step#: {}'.format(len(traj1)))
        plt.tight_layout()
        fig.savefig(save_dir+'/traj{}.png'.format(i))

    # Plot HD 
    if args.HD or args.AHD:
        for i in [0, 5, 10, 15, 20]:
            traj = trajs_all_experts[i]
            traj1 = np.array([(a,b) for (a,b,c,d) in traj['states4d']])
            traj2 = np.array([(c,d) for (a,b,c,d) in traj['states4d']])
            fig, ax = plt.subplots(1,3, figsize=(15,4))
            x1, y1 = m1_trials[i]
            x2, y2 = m2_trials[i]
            hd_angle1, hd_angle2 = HD1_trials[i], HD2_trials[i]
            for step in range(0,len(hd_angle1),3):
                ax[0].arrow(x1[step], y1[step], 2 * np.cos(np.deg2rad(hd_angle1[step])), 2 * np.sin(np.deg2rad(hd_angle1[step])), 
                        head_width=1, head_length=1, fc='blue', ec='blue')
                ax[0].arrow(x2[step], y2[step], 2 * np.cos(np.deg2rad(hd_angle2[step])), 2 * np.sin(np.deg2rad(hd_angle2[step])), 
                        head_width=1, head_length=1, fc='orange', ec='orange')
            ax[0].plot(x1, y1, label='m1', color='blue', alpha=0.5)
            ax[0].plot(x2, y2, label='m2', color='orange', alpha=0.5)
            ax[0].scatter([x1[0], x2[0]], [y1[0], y2[0]], color='red', zorder=5)
            ax[0].scatter([x1[-1], x2[-1]], [y1[-1], y2[-1]], color='red', marker='x', zorder=5)
            ax[0].set_xlim([-45/2,45/2]); ax[0].set_ylim([-45/2,45/2])
            ax[0].grid(True, which='both', linestyle='--', linewidth=0.5)
            ax[0].set_xlabel('X Coordinate'); ax[0].set_ylabel('Y Coordinate')
            ax[0].set_aspect('equal', 'box')
            plot_gridworld_trajectories(height, width, {'states2d':traj1}, fig, ax[1])
            plot_gridworld_trajectories(height, width, {'states2d':traj2}, fig, ax[2])
            ax[1].invert_yaxis()
            ax[2].invert_yaxis()
            ax[1].set_title('Step#: {}'.format(len(traj1)))
            text = 'Ego other' if args.HD else 'Allo other'
            ax[1].text(-1, 11, text, fontsize=10, color='red')
            ax[2].text(-1, 11, text, fontsize=10, color='red')
            if args.HD or args.AHD:
                for j, (angle1, angle2) in enumerate(traj['angles2d']):
                    ax[1].text(2+j/2, 11, f'{angle1}', fontsize=10, color='blue')
                    ax[2].text(2+j/2, 11, f'{angle2}', fontsize=10, color='orange')
            plt.tight_layout()
            fig.savefig(save_dir+'/traj_HD{}.png'.format(i))

            angle1 = np.concatenate([traj['angles2d'][:, 0] for traj in trajs_all_experts])
            angle2 = np.concatenate([traj['angles2d'][:, 1] for traj in trajs_all_experts])
            fig, ax = plt.subplots(1,1, figsize=(3,3))
            ax.hist(angle1, color='blue', alpha=0.5)
            ax.hist(angle2 + 0.3, color='orange', alpha=0.5)
            ax.set_xlabel('Angle bin')
            ax.set_ylabel('Count')
            ax.legend(['m1', 'm2'])
            ax.set_title(text)
            plt.tight_layout()
            fig.savefig(save_dir+'/angle_bin_hist.png')



    # plot occupancies of the trajectories
    fig, ax = plt.subplots(1,2, figsize=(6,3))
    im1 = ax[0].imshow(occ1, interpolation='nearest')
    ax[0].set_title('Occupancy of m1')
    fig.colorbar(im1, ax=ax[0])
    im2 = ax[1].imshow(occ2, interpolation='nearest')
    ax[1].set_title('Occupancy of m2')
    fig.colorbar(im2, ax=ax[1])
    plt.tight_layout()
    fig.savefig(save_dir+'/occupancy.png')

    # plot distance occupancy
    fig, ax = plt.subplots(1,1,figsize=(5,2.5))
    ax.plot(dist)
    ax.set_ylabel('Occupancy'); ax.set_xlabel('Circular distance')
    plt.tight_layout()
    fig.savefig(save_dir+'/occupancy_circular_dist.png')
