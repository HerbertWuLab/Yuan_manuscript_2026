# Generate figures cooperative foraging results
# Y.C. Oct 2024


import os, torch, argparse, pickle
import numpy as np
import pandas as pd
from scipy.stats import linregress, norm, ttest_rel, ttest_ind, chi2
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap
from plot_utils.plot_simulated_data_gridworld import plot_gridworld_trajectories
from src.value_iteration_torchversion import policy_vi, policy_vi_HD
from src.helpers import create_joint_maps_v2, create_joint_maps_HD
from src.envs import gridworld
from collections import Counter
import pandas as pd
from scipy.stats import ttest_1samp



LEGEND_SIZE = 9 # others front
SMALL_SIZE = 10 # figure title
BIGGER_SIZE = 20
LineWidth = 1
MarkerSize = 3
LineWidth_marker = 0.5

plt.rc('font', family='Myriad Pro')          # change font to Myriad Pro
plt.rc('font', size=LEGEND_SIZE)          # controls default text sizes
plt.rc('axes', titlesize=SMALL_SIZE)     # fontsize of the axes title
plt.rc('axes', labelsize=SMALL_SIZE)    # fontsize of the x and y labels
plt.rc('xtick', labelsize=LEGEND_SIZE)    # fontsize of the tick labels
plt.rc('ytick', labelsize=LEGEND_SIZE)    # fontsize of the tick labels
plt.rc('legend', fontsize=SMALL_SIZE)    # legend fontsize
plt.rcParams.update({"text.usetex": True})
# colors = ['steelblue', '#D85427', 'tab:green', 'k']
# colors = ['#fdae61','#ffffbf','#abdda4','#2b83ba']
colors = ['#e41a1c','#377eb8','#4daf4a','#984ea3']
colors_role = ['#C2A5CF','#A6DBA0']
# Define the custom colormap
color_map = np.array([[103, 0, 31],[178, 24, 43],[214, 96, 77],[244, 165, 130],[253, 219, 199],
    [247, 247, 247],[209, 229, 240],[146, 197, 222],[67, 147, 195],[33, 102, 172],[5, 48, 97]]) / 255.0  
color_map = color_map[::-1,:] 
nColors = 100
customColormap = np.zeros((nColors, 3))
for i in range(3):  # Interpolate for each RGB channel
    customColormap[:, i] = np.interp(
        np.linspace(0, 1, nColors),
        np.linspace(0, 1, color_map.shape[0]),
        color_map[:, i])
customColormap = ListedColormap(customColormap)

tags_train = ['centralized', 'independent_control', 'independent_control_w_uniform_prediction',
               '', '', 'selfish',
               'independent_control_ego_uniform', 'independent_control_ego_ToM1']

plot_dir = 'figures_coop_foraging_formal/'
if not os.path.exists(plot_dir):
    os.makedirs(plot_dir)



parser = argparse.ArgumentParser()
parser.add_argument('--figure_idx', type = float, default=0, help = 'which figure to plot')
parser.add_argument('--data', type = str, default='YC069YC070_correct', help = 'which data to use')

args = parser.parse_args()

if args.figure_idx == 1:
    print('Plotting figure 1: Model selection')
    labels_inter = ['Self','Self+other','Self+distance','Self+distance+other']
    tags_inter = ['_self_map_only','_ind_maps_only','_inter_circular_dist','']
    tag_train = 1
    tag = tags_train[tag_train]
    lr_maps, lr_weights = 0.01, 0.005
    lam1, lam2 = 5.0, 1.0
    gamma, sigma = 0.9, 1.0
    n_maps_individual, n_maps_interaction = 1, 1
    num_trajs, seed, max_iters = 1000, 1, 40
    data_list = ['YC069YC070_correct', 'YC070_correct', 'YC071_correct', 'YC072_correct'][:-2]
    data_label = ['YC069','YC070','YC071','YC072'][:-2]
    fig_name = plot_dir + 'fit_ll_inter_types'
    fig, axs = plt.subplots(2,len(data_list),figsize=(len(data_list)*2,4))
    for data_idx, data in enumerate(data_list):
        for agent in [1,2]:
            ll_collect_inter = []
            for i, tag_inter in enumerate(tags_inter):
                REC_DIR_NAME = 'recovered_parameters/coop_foraging/experiment_coop_foraging/{}_traj_neck_rot_gz5_remove_rep/fit_{}_init_occu/'.format(data, tag+tag_inter)
                rec_dir_name = REC_DIR_NAME + 'maps_{}_{}_lr_{}_{}_lam_{}_{}_gamma{}_sigma{}_early_stop/agent_{}/'.format(
                    n_maps_individual, n_maps_interaction, lr_maps, lr_weights, lam1, lam2, gamma, sigma, agent)
                tmp = rec_dir_name + "validation_lls_trajs_{}_seed_{}_iters_{}.npy".format(num_trajs, seed, max_iters)
                vali_ll = np.load(tmp)[-1]
                ll_collect_inter.append(vali_ll)
            ll_diff = 2 * (ll_collect_inter[1] - ll_collect_inter[0])
            df = 100
            p_value1 = chi2.sf(ll_diff, df)
            ll_diff = 2 * (ll_collect_inter[2] - ll_collect_inter[0])
            df = 10
            p_value2 = chi2.sf(ll_diff, df)
            ll_diff = 2 * (ll_collect_inter[3] - ll_collect_inter[2])
            df = 100
            p_value3 = chi2.sf(ll_diff,df)
            ll_relative = ll_collect_inter - ll_collect_inter[0]
            ax = axs[agent-1,data_idx]
            ax.bar(labels_inter, ll_relative, color=colors[0])
            ax.set_xticks(range(len(labels_inter)))
            ax.set_xticklabels(labels_inter, rotation=30, ha='right')
            # ax.set_title('lam1={},lam2={}'.format(lam1,lam2))
            ax.set_ylim([np.min(ll_relative), np.max(ll_relative)*1.5])
            for i, p_value in enumerate([p_value1, p_value2, p_value3]):
                ax.text(i+1, ll_relative[i+1]*1.2, f'{p_value:.0e}', ha='center', va='bottom', fontsize=LEGEND_SIZE-3)
            if agent == 1:
                ax.set_title(data_label[data_idx])
                ax.set_xticks([])
    axs[0,0].set_ylabel('M1: LL Gain')
    axs[1,0].set_ylabel('M2: LL Gain')
    plt.tight_layout()
    fig.savefig(fig_name+'.png', dpi=300, bbox_inches='tight', transparent=True)
    print('Saved at ' + fig_name + '.png')

# LL gain and p-value table for imagined pairs
if args.figure_idx == 1.1:
    print('Generate LL gain and p-value tables')
    data_list = ['YC069_phase4a_correct', 'YC070_phase4a_correct', 'YC069YC070_phase4a_correct',
                 'YC071_phase4a_correct', 'YC072_phase4a_correct', 'YC071YC072_phase4a_correct',
                 'YC073_phase4a_correct', 'YC074_phase4a_correct', 'YC073YC074_phase4a_correct',
                 'YC075_phase4a_correct', 'YC076_phase4a_correct', 'YC075YC076_phase4a_correct',
                 'YC115_phase4a_correct', 'YC116_phase4a_correct', 'YC115YC116_phase4a_correct']
    data_list = ['YC069YC070_phase4a_correct', 'YC071YC072_phase4a_correct',
                 'YC073YC074_phase4a_correct', 'YC075YC076_phase4a_correct','YC115YC116_phase4a_correct']
    labels_inter = ['Self','Self+other','Self+distance','Self+distance+HD']
    tags = ['independent_control_self_map_only','independent_control_ind_maps_only',
                    'independent_control_inter_circular_dist','HD_independent_control_inter_circular_dist']
    lr_maps, lr_weights = 0.1, 0.005
    lam1, lam2 = 5.0, 1.0
    gamma, sigma = 0.9, 1.0
    n_maps_individual, n_maps_interaction = 1, 1
    max_iters = 20
    seed = 1

    summary_tab = pd.DataFrame({
        'animal': [ele for ele in data_list for _ in range(2)],
        'agent': [1, 2] * len(data_list),
        'role': ['Follower', 'Leader'] * len(data_list),
        'LL': [None] * (2 * len(data_list)),
        'p_value': [None] * (2 * len(data_list)),
        'sig': [None] * (2 * len(data_list))
    })
    summary_tab.loc[len(summary_tab)] = {
        'animal': 'YC091_phase4a_correct',
        'agent': 1,
        'role': 'Follower',
        'LL': None,
        'p_value': None,
        'sig': None
    }
    summary_tab.loc[len(summary_tab)] = {
        'animal': 'YC111_phase4a_correct',
        'agent': 1,
        'role': 'Leader',
        'LL': None,
        'p_value': None,
        'sig': None
    }
    summary_tab['LL_per_decision'] = [None] * len(summary_tab)
    summary_tab['T'] = [None] * len(summary_tab)
    summary_tab['N_trials'] = [None] * len(summary_tab)
    summary_tab['LL_gain'] = [None] * len(summary_tab)
    count = 0
    for idx in range(summary_tab.shape[0]):      
        data = summary_tab.loc[idx, 'animal']
        agent = summary_tab.loc[idx, 'agent']  
        ll_collect_inter = []
        p_value_collect = []
        sig_collect = []
        for i, tag in enumerate(tags):
            vali_ll_rep = []
            REC_DIR_NAME = 'recovered_parameters/coop_foraging/experiment_coop_foraging/{}_traj_nose_neck_rot_gz5_HD2_remove_state_rep/fit_{}_init_occu/'.format(data, tag)
            rec_dir_name = REC_DIR_NAME + 'maps_{}_{}_lr_{}_{}_lam_{}_{}_gamma{}_sigma{}_early_stop/agent_{}/'.format(
                n_maps_individual, n_maps_interaction, lr_maps, lr_weights, lam1, lam2, gamma, sigma, agent)
            tmp_1000 = rec_dir_name + "validation_lls_trajs_1000_seed_{}_iters_{}.npy".format(seed, max_iters)
            tmp_2000 = rec_dir_name + "validation_lls_trajs_2000_seed_{}_iters_{}.npy".format(seed, max_iters)
            if os.path.exists(tmp_1000):
                vali_ll = np.load(tmp_1000)[-1]
                num_trajs = 1000
            elif os.path.exists(tmp_2000):
                vali_ll = np.load(tmp_2000)[-1]
                num_trajs = 2000
            else:
                raise FileNotFoundError(f"Neither {tmp_1000} nor {tmp_2000} exists.")
            ll_collect_inter.append(vali_ll)
        ll_diff1 = 2 * (ll_collect_inter[1] - ll_collect_inter[0])
        df = 100
        p_value1 = chi2.sf(ll_diff1, df)
        ll_diff2 = 2 * (ll_collect_inter[2] - ll_collect_inter[0])
        df = 10
        p_value2 = chi2.sf(ll_diff2, df)
        ll_diff3 = 2 * (ll_collect_inter[3] - ll_collect_inter[2])
        df = 10
        p_value3 = chi2.sf(ll_diff3,df)
        # ll_diff = 2 * (ll_collect_inter[4] - ll_collect_inter[2])
        # df = 100
        # p_value4 = chi2.sf(ll_diff,df)
        # get LL value for const. prediction
        GEN_DIR_NAME = 'data/experiment_coop_foraging/{}_traj_nose_neck_rot_gz5_HD2_remove_state_rep'.format(data) 
        file_trajs = open(GEN_DIR_NAME +'/expert_trajectories.pickle', 'rb')
        all_expert_trajectories = pickle.load(file_trajs)
        N_traj = min(len(all_expert_trajectories), num_trajs)
        all_expert_trajectories = all_expert_trajectories[:N_traj]
        T = sum(len(traj["actions"]) for traj in all_expert_trajectories)
        ll0 = T / 5 * np.log(1 / 9)
        df = 100
        ll_diff0 = 2 * (ll_collect_inter[0] - ll0)
        p_value0 = chi2.sf(ll_diff0, df)
        p_value_collect = [p_value0, p_value1, p_value2, p_value3]
        ll_diff_collect = [ll_diff0, ll_diff1, ll_diff2, ll_diff3]
        sig_collect = [1 if p < 0.01 else 0 for p in p_value_collect]
        LL_per_decision = [LL/(T/5) for LL in ll_collect_inter]
        summary_tab.loc[idx, 'LL_per_decision'] = str(LL_per_decision)
        summary_tab.loc[idx, 'LL'] = str(ll_collect_inter)
        summary_tab.loc[idx,'LL_gain'] = str(ll_diff_collect)
        summary_tab.loc[idx, 'p_value'] = str(p_value_collect)
        summary_tab.loc[idx, 'sig'] = str(sig_collect)
        summary_tab.loc[idx, 'T'] = T/5
        summary_tab.loc[idx, 'N_trials'] = N_traj
    print(summary_tab)
    summary_tab.to_csv(plot_dir + 'model_comparison_LL_gain_p_value.csv', index=False)


# LL gain and p-value table for c-table
if args.figure_idx == 1.11 :
    print('Generate LL gain and p-value tables (from behavioral data, ctable)')
    labels_inter = ['Self','Self+other','Self+distance','Self+distance+HD']
    tags = ['independent_control_self_map_only','independent_control_ind_maps_only',
                  'independent_control_inter_circular_dist','HD_independent_control_inter_circular_dist']
    lr_maps, lr_weights = 0.1, 0.005
    lam1, lam2 = 5.0, 1.0
    gamma, sigma = 0.9, 1.0
    n_maps_individual, n_maps_interaction = 1, 1
    num_trajs, max_iters = 1000, 20
    seed = 1

    data = pd.read_csv('data/experiment_coop_foraging/animal_info_ctable.csv')
    print(data.head())
    data_list = data['animalpair']
    leadership_list = []
    for idx in range(len(data_list)):
        if data.loc[idx, 'leader'] == 'm1':
            leadership_list.append('Leader')
            leadership_list.append('Follower')
        else:
            leadership_list.append('Follower')
            leadership_list.append('Leader')
    summary_tab = pd.DataFrame({
        'animal': [ele for ele in data_list for _ in range(2)],
        'agent': [1, 2] * len(data_list),
        'role': leadership_list,
        'LL': [None] * (2 * len(data_list)),
        'p_value': [None] * (2 * len(data_list)),
        'sig': [None] * (2 * len(data_list))
    })
    summary_tab['LL_per_decision'] = [None] * len(summary_tab)
    summary_tab['T'] = [None] * len(summary_tab)
    count = 0
    for idx in range(summary_tab.shape[0]):      
        data = summary_tab.loc[idx, 'animal']
        agent = summary_tab.loc[idx, 'agent']  
        ll_collect_inter = []
        p_value_collect = []
        sig_collect = []
        for i, tag in enumerate(tags):
            vali_ll_rep = []
            REC_DIR_NAME = 'recovered_parameters/coop_foraging/experiment_coop_foraging/{}_phase4a_correct_traj_nose_neck_rot_gz5_HD2_remove_state_rep/fit_{}_init_occu/'.format(data, tag)
            rec_dir_name = REC_DIR_NAME + 'maps_{}_{}_lr_{}_{}_lam_{}_{}_gamma{}_sigma{}_early_stop/agent_{}/'.format(
                n_maps_individual, n_maps_interaction, lr_maps, lr_weights, lam1, lam2, gamma, sigma, agent)
            tmp = rec_dir_name + "validation_lls_trajs_{}_seed_{}_iters_{}.npy".format(num_trajs, seed, max_iters)
            try:
                vali_ll = np.load(tmp)[-1]
            except FileNotFoundError:
                print('No {} file'.format(tmp))
                continue
            vali_ll = np.load(tmp)[-1]
            ll_collect_inter.append(vali_ll)
        ll_diff = 2 * (ll_collect_inter[1] - ll_collect_inter[0])
        df = 100
        p_value1 = chi2.sf(ll_diff, df)
        ll_diff = 2 * (ll_collect_inter[2] - ll_collect_inter[0])
        df = 10
        p_value2 = chi2.sf(ll_diff, df)
        ll_diff = 2 * (ll_collect_inter[3] - ll_collect_inter[2])
        df = 10
        p_value3 = chi2.sf(ll_diff,df)
        # get LL value for const. prediction
        GEN_DIR_NAME = 'data/experiment_coop_foraging/{}_phase4a_correct_traj_nose_neck_rot_gz5_HD2_remove_state_rep'.format(data) 
        file_trajs = open(GEN_DIR_NAME +'/expert_trajectories.pickle', 'rb')
        all_expert_trajectories = pickle.load(file_trajs)
        N_traj = min(len(all_expert_trajectories), num_trajs)
        all_expert_trajectories = all_expert_trajectories[:N_traj]
        T = sum(len(traj["actions"]) for traj in all_expert_trajectories)
        ll0 = T / 5 * np.log(1 / 9)
        df = 100
        ll_diff = 2 * (ll_collect_inter[0] - ll0)
        p_value0 = chi2.sf(ll_diff, df)
        p_value_collect = [p_value0, p_value1, p_value2, p_value3]
        sig_collect = [1 if p < 0.01 else 0 for p in p_value_collect]
        LL_per_decision = [LL/(T/5) for LL in ll_collect_inter]
        summary_tab.loc[idx, 'LL'] = str(ll_collect_inter)
        summary_tab.loc[idx, 'p_value'] = str(p_value_collect)
        summary_tab.loc[idx, 'sig'] = str(sig_collect)
        summary_tab.loc[idx, 'T'] = T/5
        summary_tab.loc[idx, 'LL_per_decision'] = str(LL_per_decision)
    print(summary_tab)
    summary_tab.to_csv(plot_dir + 'model_comparison_LL_gain_p_value_ctable.csv', index=False)


if args.figure_idx == 1.2:
    print('Plotting figure 1: Model selection, plot on F/L on the same panel')
    data_list = ['YC069_phase4a_correct','YC071_phase4a_correct', 'YC073_phase4a_correct','YC075_phase4a_correct','YC115_phase4a_correct']
    data_label = ['YC069','YC071','YC073','YC075','YC115']
    labels_inter = ['Self','Self+other','Self+distance','Self+distance+HD','Self+distance+other']
    labels_inter = labels_inter[:-1]
    summary_tab = pd.read_csv(plot_dir + 'model_comparison_LL_gain_p_value.csv')

    fig_name = plot_dir + 'model_comparison'
    fig, axs = plt.subplots(1,2,figsize=(3.5,2.5))
    plt.rc('font', family='Myriad Pro')  # Set the font type for the entire figure
    plt.rc('font', size=LEGEND_SIZE)  # Set the font size for the entire figure
    count = 0 
    width = 0.4  # Width of the bars
    for data_idx, data in enumerate(data_list[:2]):
        ax = axs[data_idx]
        for agent in [1,2]:
            ll_collect_inter = summary_tab.loc[count, 'LL'].split('[')[1].split(']')[0].split(',')[:-1]            
            ll_relative = [float(ele)-float(ll_collect_inter[0]) for ele in ll_collect_inter]
            print(ll_relative)
            y = np.arange(len(labels_inter))
            if agent == 1:
                b1 = ax.barh(y - width / 2, ll_relative[::-1], height=width, color=colors_role[1], label='Follower')
            elif agent == 2:
                b2 = ax.barh(y + width / 2, ll_relative[::-1], height=width, color=colors_role[0], label='Leader')
                ax.set_yticks(range(len(labels_inter)))
                ax.set_yticklabels(labels_inter[::-1], rotation=0, ha='right')
                leg = ax.legend([b1,b2],['Follower','Leader'], frameon=False, fontsize=LEGEND_SIZE-3)
                leg.get_texts()[0].set_color(colors_role[1]) 
                leg.get_texts()[1].set_color(colors_role[0])  
            ax.set_xlim([0, max(ax.get_xlim())])
            ax.set_xlabel('LL Gain')
            ax.set_title('Pair {}'.format(data_idx+1), fontsize=SMALL_SIZE)
            ax.spines['top'].set_visible(False)
            ax.spines['right'].set_visible(False)
            ax.set_aspect(np.diff(ax.get_xlim())/np.diff(ax.get_ylim()))
            count += 1
    axs[1].set_yticks(range(len(labels_inter)))
    axs[1].set_yticklabels([])
    plt.tight_layout()
    # fig.text(0.5, 0.04, 'LL Gain', ha='center', va='center')
    fig.savefig(fig_name+'.png', dpi=300, bbox_inches='tight', transparent=True)
    fig.savefig(fig_name+'.pdf', dpi=300, bbox_inches='tight', transparent=True)
    print('Saved at ' + fig_name + '.png')

# Calculate Number of pairs that are significant duing model selection
if args.figure_idx == 1.21:
    print('Plot number of pairs that are significant duing model selection')
    summary_tab1 = pd.read_csv(plot_dir + 'model_comparison_LL_gain_p_value.csv')
    summary_tab2 = pd.read_csv(plot_dir + 'model_comparison_LL_gain_p_value_ctable.csv')
    summary_tab = pd.concat([summary_tab1[['animal', 'role', 'sig']], summary_tab2[['animal', 'role', 'sig']]], axis=0, ignore_index=True)
    # summary_tab = summary_tab1
    summary_tab = summary_tab.dropna()
    summary_tab['sig_self'] = summary_tab['sig'].apply(lambda x: int(x.split('[')[1].split(']')[0].split(',')[0]))
    summary_tab['sig_other'] = summary_tab['sig'].apply(lambda x: int(x.split('[')[1].split(']')[0].split(',')[1]))
    summary_tab['sig_distance'] = summary_tab['sig'].apply(lambda x: int(x.split('[')[1].split(']')[0].split(',')[2]))
    summary_tab['sig_HD'] = summary_tab['sig'].apply(lambda x: int(x.split('[')[1].split(']')[0].split(',')[3]))
    summary_tab_collapsed = summary_tab.groupby(['role']).agg({
        'sig_self': 'sum',
        'sig_other': 'sum',
        'sig_distance': 'sum',
        'sig_HD': 'sum'
    }).reset_index()
    print('Total number of animal pairs: {}'.format(len(summary_tab.role)/2))
    print(summary_tab_collapsed)

# Plot LL gain for imagined pairs
if args.figure_idx == 1.3:
    print('Plotting figure 1.3: Model selection, multiple pairs')
    labels_inter = ['Self','Self+other','Self+distance','Self+distance+HD']
    selected_cols = ['animal', 'agent', 'role', 'LL']
    summary_tab1 = pd.read_csv(plot_dir + 'model_comparison_LL_gain_p_value.csv')
    # summary_tab2 = pd.read_csv(plot_dir + 'model_comparison_LL_gain_p_value_ctable.csv')
    # summary_tab = pd.concat([summary_tab1[selected_cols], summary_tab2[selected_cols]], axis=0, ignore_index=True)
    summary_tab = summary_tab1[selected_cols]
    print(summary_tab)

    count = 0 
    width = 0.4  # Width of the bars
    fig_name = plot_dir + 'model_comparison_paired'
    ll_follower = []
    ll_leader = []
    for idx in range(len(summary_tab)):
        data = summary_tab.loc[idx, 'animal']
        agent = summary_tab.loc[idx, 'agent']
        role = summary_tab.loc[idx, 'role']
        ll_collect_inter = summary_tab.loc[idx,'LL'].split('[')[1].split(']')[0].split(',')
        ll_relative = [float(ele) - float(ll_collect_inter[0]) for ele in ll_collect_inter]
        if role == 'Follower':
            ll_follower.append(ll_relative)
        else:
            ll_leader.append(ll_relative)

    fig_name = plot_dir + 'model_comparison'
    fig, axs = plt.subplots(1, 2, figsize=(3, 1.5))
    plt.rc('font', family='Myriad Pro')  
    plt.rc('font', size=LEGEND_SIZE)
    ax = axs[0]
    ax.barh(np.arange(len(labels_inter)) - width / 2, ll_follower[1][::-1], height=width,
            facecolor='none', edgecolor=colors_role[1], linewidth=LineWidth, label='Follower')
    ax.barh(np.arange(len(labels_inter)) + width / 2, ll_leader[1][::-1], height=width,
            facecolor='none', edgecolor=colors_role[0], linewidth=LineWidth, label='Leader')
    ax.set_yticks(range(len(labels_inter)))
    ax.set_yticklabels(labels_inter[::-1], rotation=0, ha='right')
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.set_aspect(np.diff(ax.get_xlim()) / np.diff(ax.get_ylim()))
    
    ax = axs[1]
    ax.barh(np.arange(len(labels_inter)) - width / 2, np.mean(ll_follower, axis=0)[::-1], height=width,
            facecolor='none', edgecolor=colors_role[1], linewidth=LineWidth, label='Follower')
    ax.barh(np.arange(len(labels_inter)) + width / 2, np.mean(ll_leader, axis=0)[::-1], height=width,
            facecolor='none', edgecolor=colors_role[0], linewidth=LineWidth, label='Leader')
    for i in range(len(labels_inter)):
        ax.scatter(np.array(ll_follower)[:, i], [len(labels_inter)-1-i-width/2] * len(ll_follower), s=MarkerSize, color=colors_role[1])
        ax.scatter(np.array(ll_leader)[:, i], [len(labels_inter)-1-i+width/2] * len(ll_leader), s=MarkerSize, color=colors_role[0])
    ax.set_yticks(range(len(labels_inter)))
    ax.set_yticklabels([])
    ax.set_ylim(axs[0].get_ylim())
    # ax.set_title('All pairs', fontsize=SMALL_SIZE)
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.set_aspect(np.diff(ax.get_xlim()) / np.diff(ax.get_ylim()))
    
    axs[0].set_xlabel('LL gain')
    axs[0].set_ylabel('')
    axs[1].set_xlabel('LL gain')
    for ax in axs:
        for spine in ax.spines.values():
            spine.set_linewidth(LineWidth)
    # plt.tight_layout()
    fig.savefig(fig_name + '.png', dpi=300, bbox_inches='tight', transparent=True)
    fig.savefig(fig_name + '.pdf', dpi=300, bbox_inches='tight', transparent=True)
    print('Saved at ' + fig_name + '.png')

if args.figure_idx == 1.31:
    print('Plotting figure 1.31: Model selection, multiple pairs, LL per decision')
    labels_inter = ['Self','Self+other','Self+distance','Self+distance+HD']
    summary_tab = pd.read_csv(plot_dir + 'model_comparison_LL_gain_p_value.csv')

    count = 0 
    width = 0.4  # Width of the bars
    fig_name = plot_dir + 'model_comparison_paired_per_decision'
    ll_follower = []
    ll_leader = []
    for idx in range(len(summary_tab)):
        data = summary_tab.loc[idx, 'animal']
        agent = summary_tab.loc[idx, 'agent']
        role = summary_tab.loc[idx, 'role']
        ll_collect_inter = summary_tab[(summary_tab.animal == data) & (summary_tab.agent == agent)].LL_per_decision.values[0].split('[')[1].split(']')[0].split(',')
        ll_relative = [float(ele) for ele in ll_collect_inter]
        if role == 'Follower':
            ll_follower.append(ll_relative)
        else:
            ll_leader.append(ll_relative)

    fig, axs = plt.subplots(1, 1, figsize=(3.5, 2.5))
    plt.rc('font', family='Myriad Pro')  
    plt.rc('font', size=LEGEND_SIZE)
    # ax = axs[0]
    # ax.barh(np.arange(len(labels_inter)) - width / 2, ll_follower[0][::-1], height=width,
    #         facecolor='none', edgecolor=colors_role[1], linewidth=1.5, label='Follower')
    # ax.barh(np.arange(len(labels_inter)) + width / 2, ll_leader[0][::-1], height=width,
    #         facecolor='none', edgecolor=colors_role[0], linewidth=1.5, label='Leader')
    # ax.set_yticks(range(len(labels_inter)))
    # ax.set_yticklabels(labels_inter[::-1], rotation=0, ha='right')
    # ax.set_title('Pair 1', fontsize=SMALL_SIZE)
    # ax.spines['top'].set_visible(False)
    # ax.spines['right'].set_visible(False)
    # ax.set_aspect(np.diff(ax.get_xlim()) / np.diff(ax.get_ylim()))
    
    print(np.array(ll_follower))
    ax = axs
    ax.barh(np.arange(len(labels_inter)) - width / 2, np.mean(ll_follower, axis=0)[::-1], height=width,
            facecolor='none', edgecolor=colors_role[1], linewidth=1.5, label='Follower')
    ax.barh(np.arange(len(labels_inter)) + width / 2, np.mean(ll_leader, axis=0)[::-1], height=width,
            facecolor='none', edgecolor=colors_role[0], linewidth=1.5, label='Leader')
    for i in range(len(labels_inter)):
        ax.scatter(np.array(ll_follower)[:, i], [len(labels_inter)-1-i-width/2] * len(ll_follower), s=5, color=colors_role[1])
        ax.scatter(np.array(ll_leader)[:, i], [len(labels_inter)-1-i+width/2] * len(ll_leader), s=5, color=colors_role[0])
    ax.set_yticks(range(len(labels_inter)))
    ax.set_yticklabels([])
    ax.set_title('All pairs', fontsize=SMALL_SIZE)
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.set_aspect(np.diff(ax.get_xlim()) / np.diff(ax.get_ylim()))
    
    ax.set_xlabel('LL (nats/decision)')
    ax.set_ylabel('')
    ax.set_yticks(range(len(labels_inter)))
    ax.set_yticklabels(labels_inter[::-1], rotation=0, ha='right')
    ax.set_xlim([-2.3,-1.0])
    ax.axvline(x=np.log(1/9), color='k', linestyle='--', linewidth=1.)
    plt.tight_layout()
    fig.savefig(fig_name + '.png', dpi=300, bbox_inches='tight', transparent=True)
    fig.savefig(fig_name + '.pdf', dpi=300, bbox_inches='tight', transparent=True)
    print('Saved at ' + fig_name + '.png')


if args.figure_idx == 2:
    print('Plotting fitting maps')
    tag_train = 1
    lr_maps, lr_weights = 0.1, 0.005
    lam1, lam2 = 5.0, 1.0
    gamma, sigma = 0.9, 1.0
    n_maps_individual, n_maps_interaction = 1, 1
    num_trajs, seed, max_iters = 1000, 1, 20
    tag = tags_train[tag_train]
    tag += '_inter_circular_dist'
    tag += '_init_occu'
    REC_DIR_NAME = 'recovered_parameters/coop_foraging/experiment_coop_foraging/{}_traj_nose_neck_rot_gz5_HD2_remove_rep/fit_{}/'.format(args.data, tag)
    
    fig, axs = plt.subplots(2,2,figsize=(6,5))
    for agent in [1,2]:
        rec_dir_name = REC_DIR_NAME + 'maps_{}_{}_lr_{}_{}_lam_{}_{}_gamma{}_sigma{}_early_stop/agent_{}/'.format(
                    n_maps_individual, n_maps_interaction, lr_maps, lr_weights, lam1, lam2, gamma, sigma, agent)
        rec_weights = np.load(rec_dir_name + "weights_trajs_" + str(num_trajs) +"_seed_" + str(seed) + "_iters_" + str(max_iters) +".npy")[-1]
        if agent == 1:
            rec_ind_maps = np.load(rec_dir_name + "ind1_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
        else:
            rec_ind_maps = np.load(rec_dir_name + "ind2_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
        rec_inter_maps = np.load(rec_dir_name + "inter_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
        
        map_weight = rec_weights[0,0] if agent == 1 else rec_weights[1,0]
        c_max = np.max(np.abs(rec_ind_maps[0,:])*map_weight)
        ax = axs[agent-1,0]
        im = ax.imshow(map_weight*np.reshape(rec_ind_maps[0,:],(10, 10),order='F'),vmin=-c_max, vmax=c_max)
        c_bar = plt.colorbar(im,ax=ax,fraction=0.046, pad=0.04, ticks=[-c_max,0,c_max])
        c_bar.set_ticks([-c_max, 0, c_max])
        c_bar.set_ticklabels(['{:.2f}'.format(-c_max), '0', '{:.2f}'.format(c_max)])
        ax.set_title('M{}'.format(agent))
        ax.set_axis_off()
        ax = axs[agent-1,1]
        ax.plot(rec_inter_maps[0,:]*rec_weights[2,0])
        # ax.set_ylim([-c_max, c_max])
        ax.set_title('$\phi$')
        ax.set_xlabel('Circular Distance')

    plt.tight_layout()
    fig.savefig(plot_dir + '{}_maps.png'.format(args.data), dpi=300, bbox_inches='tight', transparent=True)
    print('Saved at ' + plot_dir + '{}_maps.png'.format(args.data))


if args.figure_idx == 2.1:
    print('Plot maps for different conditions')
    animal = 'YC071'
    conditions = ['correct','wrong','phase4d_correct']
    condition_labels = ['Phase4a','Wrong','Phase4d']
    lr_maps, lr_weights = 0.01, 0.005
    lam1, lam2 = 5.0, 1.0
    gamma, sigma = 0.9, 1.0
    n_maps_individual, n_maps_interaction = 1, 1
    num_trajs, seed, max_iters = 1000, 1, 20
    tag = 'independent_control'
    tag += '_inter_circular_dist'
    tag += '_init_occu'

    fig, axs = plt.subplots(2,2*len(conditions),figsize=(7,5))
    for cond_idx, cond in enumerate(conditions):
        REC_DIR_NAME = 'recovered_parameters/coop_foraging/experiment_coop_foraging/{}_{}_traj_neck_rot_gz5_remove_rep/fit_{}/'.format(animal, cond, tag)
        for agent in [1,2]:
            rec_dir_name = REC_DIR_NAME + 'maps_{}_{}_lr_{}_{}_lam_{}_{}_gamma{}_sigma{}_early_stop/agent_{}/'.format(
                        n_maps_individual, n_maps_interaction, lr_maps, lr_weights, lam1, lam2, gamma, sigma, agent)
            rec_weights = np.load(rec_dir_name + "weights_trajs_" + str(num_trajs) +"_seed_" + str(seed) + "_iters_" + str(max_iters) +".npy")[-1]
            if agent == 1:
                rec_ind_maps = np.load(rec_dir_name + "ind1_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
                map_weight = rec_weights[0,0]
                col = colors_role[1]
            else:
                rec_ind_maps = np.load(rec_dir_name + "ind2_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
                map_weight = rec_weights[1,0]
                col = colors_role[0]
            rec_inter_maps = np.load(rec_dir_name + "inter_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
            c_max = np.max(np.abs(rec_ind_maps[0,:])*map_weight)
            mat = map_weight*np.reshape(rec_ind_maps[0,:],(10, 10),order='F') / c_max
            
            ax = axs[2-agent,cond_idx*2]
            im = ax.imshow(mat,vmin=-1, vmax=1,cmap=customColormap)
            # c_bar = plt.colorbar(im, ax=ax, fraction=0.046, pad=0.04, ticks=[-c_max, 0, c_max], location='left')
            # c_bar.set_ticks([-1, 0, 1])
            # c_bar.outline.set_visible(False)  # Remove the frame around the colorbar
            ax.set_xticks([0,9])
            ax.set_xticklabels([-25,25])
            ax.set_yticks([0,9])
            ax.set_yticklabels([-25,25])
            # ax.set_axis_off()
            ax.invert_yaxis()
            ax = axs[2-agent,cond_idx*2+1]
            ax.plot(-rec_inter_maps[0,:]*rec_weights[2,0] / c_max, color=col)
            ax.axhline(0, color='k', linestyle='--', linewidth=1)
            ax.set_ylim([-1, 1])
            ax.set_xticks(range(0, 10, 4))
            ax.set_xticklabels(range(0, 10, 4))
            ax.spines['top'].set_visible(False)
            ax.spines['right'].set_visible(False)
            ax.set_aspect(np.diff(ax.get_xlim())/np.diff(ax.get_ylim()))

    plt.tight_layout()
    fig.savefig(plot_dir + 'Maps_conditions.png'.format(animal), dpi=300, bbox_inches='tight', transparent=True)
    fig.savefig(plot_dir + 'Maps_conditions.pdf'.format(animal), dpi=300, bbox_inches='tight', transparent=True)
    print('Saved at ' + plot_dir + 'Maps_conditions.png'.format(animal))

# Plot maps for mismatch conditions
if args.figure_idx == 2.11:
    # condition = 'phase4d_correct'
    # animals = ['YC071','YC073','YC075']
    condition = 'wrong'
    animals = ['YC070','YC072','YC074']
    lr_maps, lr_weights = 0.1, 0.005
    lam1, lam2 = 5.0, 1.0
    gamma, sigma = 0.9, 1.0
    n_maps_individual, n_maps_interaction = 1, 1
    num_trajs, seed, max_iters = 1000, 1, 20
    tag = 'independent_control'
    tag += '_inter_circular_dist'
    tag += '_init_occu'    
    inter_map_follower = []
    inter_map_leader = []
    map_follower = []
    map_leader = []
    summary_tab = pd.DataFrame({'animal': [ele for ele in animals for _ in range(2)],
                                 'agent': [1, 2] * len(animals),
                                 'role': ['Follower', 'Leader'] * len(animals)})
    for idx in summary_tab.index:
        animal = summary_tab.loc[idx, 'animal']
        agent = summary_tab.loc[idx, 'agent']
        role = summary_tab.loc[idx, 'role']
        REC_DIR_NAME = 'recovered_parameters/coop_foraging/experiment_coop_foraging/{}_{}_traj_neck_rot_gz5_remove_rep/fit_{}/'.format(animal, condition, tag)
        rec_dir_name = REC_DIR_NAME + 'maps_{}_{}_lr_{}_{}_lam_{}_{}_gamma{}_sigma{}_early_stop/agent_{}/'.format(
                    n_maps_individual, n_maps_interaction, lr_maps, lr_weights, lam1, lam2, gamma, sigma, agent)
        rec_weights = np.load(rec_dir_name + "weights_trajs_" + str(num_trajs) +"_seed_" + str(seed) + "_iters_" + str(max_iters) +".npy")[-1]
        rec_inter_maps = np.load(rec_dir_name + "inter_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
        if agent == 1:
            rec_ind_maps = np.load(rec_dir_name + "ind1_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
            map_weight = rec_weights[0,0]
            c_max = np.max(np.abs(rec_ind_maps[0,:])*map_weight)
        else:
            rec_ind_maps = np.load(rec_dir_name + "ind2_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
            map_weight = rec_weights[1,0]
            c_max = np.max(np.abs(rec_ind_maps[0,:])*map_weight)
        if role == 'Follower':
            map_follower.append(rec_ind_maps[0,:]*map_weight / c_max)
            inter_map_follower.append(rec_inter_maps[0,:]*rec_weights[2,0] / c_max)
        else:
            map_leader.append(rec_ind_maps[0,:]*map_weight / c_max)
            inter_map_leader.append(rec_inter_maps[0,:]*rec_weights[2,0] / c_max)

    example_map1 = []
    example_map2 = []
    REC_DIR_NAME = 'recovered_parameters/coop_foraging/experiment_coop_foraging/' \
    'YC073_{}_traj_neck_rot_gz5_remove_rep/fit_independent_control_inter_circular_dist_init_occu/' \
    'maps_1_1_lr_0.1_0.005_lam_5.0_1.0_gamma0.9_sigma1.0_early_stop/'.format(condition)
    rec_dir_name = REC_DIR_NAME + 'agent_1/'
    rec_weights = np.load(rec_dir_name + "weights_trajs_1000_seed_1_iters_20.npy")[-1]
    rec_ind_maps = np.load(rec_dir_name + "ind1_maps_trajs_1000_seed_1_iters_20.npy")[-1]
    map_weight = rec_weights[0,0]
    c_max = np.max(np.abs(rec_ind_maps[0,:])*map_weight)
    example_map1 = rec_ind_maps[0,:]*map_weight / c_max
    rec_dir_name = REC_DIR_NAME + 'agent_2/'
    rec_weights = np.load(rec_dir_name + "weights_trajs_1000_seed_1_iters_20.npy")[-1]
    rec_ind_maps = np.load(rec_dir_name + "ind2_maps_trajs_1000_seed_1_iters_20.npy")[-1]
    map_weight = rec_weights[1,0]
    c_max = np.max(np.abs(rec_ind_maps[0,:])*map_weight)
    example_map2 = rec_ind_maps[0,:]*map_weight / c_max

    t_stat, p_value = ttest_ind(np.array(inter_map_follower)[:,1], np.array(inter_map_leader)[:,1])
    print(f"t-test results: p-value = {p_value:.2e}")

    fig, axs = plt.subplots(2,3,figsize=(4,2.5))
    plt.rc('font', family='Myriad Pro')  
    plt.rc('font', size=LEGEND_SIZE)
    for role_idx in [0,1]:  
        if role_idx == 0: # leader
            mat = example_map2.reshape((10, 10), order='F')
            maps = map_leader
            inter_map = inter_map_leader
        else: # follower
            mat = example_map1.reshape((10, 10), order='F')
            maps = map_follower
            inter_map = inter_map_follower
        ax = axs[role_idx,0]
        im = ax.imshow(mat,vmin=-1, vmax=1,cmap=customColormap)
        ax.set_xticks([0,9])
        ax.set_xticklabels([-25,25])
        ax.set_yticks([0,9])
        ax.set_yticklabels([-25,25])
        ax.invert_yaxis()
        ax = axs[role_idx,1]
        # 84: east
        # 48: north
        # 44: middle
        middle = np.array(maps)[:,44]
        east = np.array(maps)[:,84]
        north = np.array(maps)[:,48]
        other_loc = np.delete(np.arange(100), [44, 48, 84])
        others = np.array(maps)[:,other_loc].mean(axis=1)
        t_stat_middle, p_value_middle = ttest_rel(middle, others)
        t_stat_east, p_value_east = ttest_rel(east, others)
        t_stat_north, p_value_north = ttest_rel(north, others)
        print(f"Middle vs Others: p-value = {p_value_middle:.2e}")
        print(f"East vs Others: p-value = {p_value_east:.2e}")
        print(f"North vs Others: p-value = {p_value_north:.2e}")
        ax = axs[role_idx,1]
        ax.scatter([0]*len(middle), middle, s=5, color=colors_role[role_idx])
        ax.scatter([1]*len(east), east, s=5, color=colors_role[role_idx])
        ax.scatter([2]*len(north), north, s=5, color=colors_role[role_idx])
        ax.scatter([3]*len(others), others, s=5, color=colors_role[role_idx])
        ax.bar([0,1,2,3], [np.mean(middle), np.mean(east), np.mean(north), np.mean(others)], color=colors_role[role_idx], 
               facecolor='none', edgecolor=colors_role[role_idx], linewidth=1.5, width=0.4)
        ax.set_xticks([0,1,2,3])
        ax.set_xticks([])
        ax.set_yticks([0,1])
        ax.set_yticklabels([0,1])
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.set_aspect(np.diff(ax.get_xlim())/np.diff(ax.get_ylim()))

        ax = axs[role_idx,2]
        ax.plot(np.array(inter_map).T, color=colors_role[role_idx], linewidth=1, alpha=0.8)
        ax.axhline(0, color='k', linestyle='--', linewidth=0.5)
        ax.set_ylim([-1, 1.5])
        ax.set_yticks([0,1])
        ax.set_yticklabels([0,1])
        ax.set_xticks(range(0, 10, 4))
        ax.set_xticklabels(range(0, 10, 4))
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.set_aspect(np.diff(ax.get_xlim())/np.diff(ax.get_ylim()))
    
    axs[1,2].set_xlabel('Dijkstra distance (bin)')
    axs[1,2].set_ylabel('V(distance)')
    axs[1,1].set_xticks([0,1,2,3])
    axs[1,1].set_xticklabels(['Middle','East','North','Others'], rotation=30, ha='right')
    axs[1,1].set_ylabel('V(self pos)')
    axs[1,0].set_xlabel('X (cm)')
    axs[1,0].set_ylabel('Y (cm)')
    for ax in axs.flatten():
        for spine in ax.spines.values():
            spine.set_linewidth(LineWidth)
    for ax in axs[1, :]:
        box = ax.get_position()
        ax.set_position([box.x0, box.y0 - 0.05, box.width, box.height])
    for ax in axs[:, 1]:
        box = ax.get_position()
        ax.set_position([box.x0 + 0.05, box.y0, box.width, box.height])
    for ax in axs[:, 2]:
        box = ax.get_position()
        ax.set_position([box.x0 + 0.1, box.y0, box.width, box.height])
    
    figname = plot_dir + '{}_across_animals'.format(condition)
    fig.savefig(figname+'.png', dpi=300, bbox_inches='tight', transparent=True)
    fig.savefig(figname+'.pdf', dpi=300, bbox_inches='tight', transparent=True)
    print('Saved at ' + figname + '.png')


if args.figure_idx == 2.2:
    print('Plot map for HD fitting')
    tag_train = 1
    agent = 1
    lr_maps, lr_weights = 0.1, 0.005
    lam1, lam2 = 5.0, 1.0
    gamma, sigma = 0.9, 1.0
    n_maps_individual, n_maps_interaction = 1, 1
    num_trajs, seed, max_iters = 1000, 1, 20
    tag = tags_train[tag_train]
    tag += '_inter_circular_dist'
    tag += '_init_occu'
    REC_DIR_NAME = 'recovered_parameters/coop_foraging/experiment_coop_foraging/YC069_phase4a_correct_traj_nose_neck_rot_gz5_HD2_remove_state_rep/fit_HD_{}/'.format(tag)

    fig, axs = plt.subplots(1,2,figsize=(3.5,2.5))
    rec_dir_name = REC_DIR_NAME + 'maps_{}_{}_lr_{}_{}_lam_{}_{}_gamma{}_sigma{}_early_stop/agent_{}/'.format(
                n_maps_individual, n_maps_interaction, lr_maps, lr_weights, lam1, lam2, gamma, sigma, agent)
    rec_weights = np.load(rec_dir_name + "weights_trajs_" + str(num_trajs) +"_seed_" + str(seed) + "_iters_" + str(max_iters) +".npy")[-1]
    rec_ind_maps = np.load(rec_dir_name + "ind1_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
    rec_inter_maps = np.load(rec_dir_name + "inter_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
    map_weight = rec_weights[0,0]
    c_max = np.max(np.abs(rec_ind_maps[0,:])*map_weight)
    ax = axs[0]
    im = ax.imshow(map_weight*np.reshape(rec_ind_maps[0,:],(10, 10),order='F'),vmin=-c_max, vmax=c_max,cmap=customColormap)
    c_bar = plt.colorbar(im,ax=ax,fraction=0.046, pad=0.04, ticks=[-c_max,0,c_max])
    c_bar.set_ticks([-c_max, 0, c_max])
    c_bar.set_ticklabels(['{:.2f}'.format(-c_max), '0', '{:.2f}'.format(c_max)])
    if agent == 1:
        ax.set_title('Follower location')
    else:
        ax.set_title('Leader location')
    ax.invert_yaxis()
    ax.set_axis_off()
    ax = axs[1]
    ax.plot(-rec_inter_maps[0,:,0]*rec_weights[2,0], label='Front', color=colors_role[1])
    ax.plot(-rec_inter_maps[0,:,1]*rec_weights[2,0], label='Back', color=colors_role[1], linestyle='--')
    ax.legend(frameon=False,fontsize=LEGEND_SIZE)
    ax.set_xticks(range(0, 10, 2))
    ax.set_xticklabels(range(0, 10, 2))
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.set_aspect(np.diff(ax.get_xlim())/np.diff(ax.get_ylim()))
    ax.set_title('Distance')

    plt.tight_layout()
    fig.savefig(plot_dir + '{}_HD_maps.png'.format(args.data), dpi=300, bbox_inches='tight', transparent=True)
    fig.savefig(plot_dir + '{}_HD_maps.pdf'.format(args.data), dpi=300, bbox_inches='tight', transparent=True)
    print('Saved at ' + plot_dir + '{}_HD_maps.png'.format(args.data))


# Plot maps across multiple animals
if args.figure_idx == 3:
    print('Figure 3: Plotting maps across multiple animals')
    condition = 'phase4a_correct'
    lr_maps, lr_weights = 0.1, 0.005
    lam1, lam2 = 5.0, 1.0
    gamma, sigma = 0.9, 1.0
    n_maps_individual, n_maps_interaction = 1, 1
    num_trajs, seed, max_iters = 1000, 1, 20
    tag = 'independent_control'
    tag += '_inter_circular_dist'
    tag += '_init_occu'    
    inter_map_follower = []
    inter_map_leader = []
    map_follower = []
    map_leader = []
    summary_tab = pd.read_csv(plot_dir + 'model_comparison_LL_gain_p_value.csv')
    for idx in summary_tab.index:
        animal = summary_tab.loc[idx, 'animal'].split('_')[0]
        agent = summary_tab.loc[idx, 'agent']
        role = summary_tab.loc[idx, 'role']
        REC_DIR_NAME = 'recovered_parameters/coop_foraging/experiment_coop_foraging/{}_{}_traj_nose_neck_rot_gz5_HD2_remove_state_rep/fit_{}/'.format(animal, condition, tag)
        rec_dir_name = REC_DIR_NAME + 'maps_{}_{}_lr_{}_{}_lam_{}_{}_gamma{}_sigma{}_early_stop/agent_{}/'.format(
                    n_maps_individual, n_maps_interaction, lr_maps, lr_weights, lam1, lam2, gamma, sigma, agent)
        if os.path.exists(rec_dir_name+'weights_trajs_1000_seed_1_iters_20.npy'):
            num_trajs = 1000
        elif os.path.exists(rec_dir_name+'weights_trajs_2000_seed_1_iters_20.npy'):
            num_trajs = 2000
        rec_weights = np.load(rec_dir_name + "weights_trajs_" + str(num_trajs) +"_seed_" + str(seed) + "_iters_" + str(max_iters) +".npy")[-1]
        rec_inter_maps = np.load(rec_dir_name + "inter_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
        if agent == 1:
            rec_ind_maps = np.load(rec_dir_name + "ind1_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
            map_weight = rec_weights[0,0]
            c_max = np.max(np.abs(rec_ind_maps[0,:])*map_weight)
        else:
            rec_ind_maps = np.load(rec_dir_name + "ind2_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
            map_weight = rec_weights[1,0]
            c_max = np.max(np.abs(rec_ind_maps[0,:])*map_weight)
        if role == 'Follower':
            map_follower.append(rec_ind_maps[0,:]*map_weight / c_max)
            inter_map_follower.append(rec_inter_maps[0,:]*rec_weights[2,0] / c_max)
        else:
            map_leader.append(rec_ind_maps[0,:]*map_weight / c_max)
            inter_map_leader.append(rec_inter_maps[0,:]*rec_weights[2,0] / c_max)

    example_map1 = []
    example_map2 = []
    REC_DIR_NAME = 'recovered_parameters/coop_foraging/experiment_coop_foraging/YC069YC070_phase4a_correct_traj_nose_neck_rot_gz5_HD2_remove_state_rep/fit_independent_control_inter_circular_dist_init_occu/maps_1_1_lr_0.1_0.005_lam_5.0_1.0_gamma0.9_sigma1.0_early_stop/'
    rec_dir_name = REC_DIR_NAME + 'agent_1/'
    rec_weights = np.load(rec_dir_name + "weights_trajs_2000_seed_1_iters_20.npy")[-1]
    rec_ind_maps = np.load(rec_dir_name + "ind1_maps_trajs_2000_seed_1_iters_20.npy")[-1]
    map_weight = rec_weights[0,0]
    c_max = np.max(np.abs(rec_ind_maps[0,:])*map_weight)
    example_map1 = rec_ind_maps[0,:]*map_weight / c_max
    rec_dir_name = REC_DIR_NAME + 'agent_2/'
    rec_weights = np.load(rec_dir_name + "weights_trajs_2000_seed_1_iters_20.npy")[-1]
    rec_ind_maps = np.load(rec_dir_name + "ind2_maps_trajs_2000_seed_1_iters_20.npy")[-1]
    map_weight = rec_weights[1,0]
    c_max = np.max(np.abs(rec_ind_maps[0,:])*map_weight)
    example_map2 = rec_ind_maps[0,:]*map_weight / c_max

    t_stat, p_value = ttest_ind(np.array(inter_map_follower)[:,1], np.array(inter_map_leader)[:,1])
    print(f"t-test results: p-value = {p_value:.2e}")

    fig, axs = plt.subplots(2,3,figsize=(4,2.5))
    plt.rc('font', family='Myriad Pro')  
    plt.rc('font', size=LEGEND_SIZE)
    for role_idx in [0,1]:
        if role_idx == 0: # leader
            mat = example_map2.reshape((10, 10), order='F')
            maps = map_leader
            inter_map = inter_map_leader
        else: # follower
            mat = example_map1.reshape((10, 10), order='F')
            maps = map_follower
            inter_map = inter_map_follower
        ax = axs[role_idx,0]
        im = ax.imshow(mat,vmin=-1, vmax=1,cmap=customColormap)
        ax.set_xticks([0,9])
        ax.set_xticklabels([-25,25])
        ax.set_yticks([0,9])
        ax.set_yticklabels([-25,25])
        ax.invert_yaxis()
        ax = axs[role_idx,1]
        # 84: east
        # 48: north
        # 44: middle
        middle = np.array(maps)[:,44]
        east = np.array(maps)[:,84]
        north = np.array(maps)[:,48]
        other_loc = np.delete(np.arange(100), [44, 48, 84])
        others = np.array(maps)[:,other_loc].mean(axis=1)
        t_stat_middle, p_value_middle = ttest_rel(middle, others)
        t_stat_east, p_value_east = ttest_rel(east, others)
        t_stat_north, p_value_north = ttest_rel(north, others)
        print(f"Middle vs Others: p-value = {p_value_middle:.2e}")
        print(f"East vs Others: p-value = {p_value_east:.2e}")
        print(f"North vs Others: p-value = {p_value_north:.2e}")
        ax = axs[role_idx,1]
        ax.scatter([0]*len(middle), middle, s=5, color=colors_role[role_idx])
        ax.scatter([1]*len(east), east, s=5, color=colors_role[role_idx])
        ax.scatter([2]*len(north), north, s=5, color=colors_role[role_idx])
        ax.scatter([3]*len(others), others, s=5, color=colors_role[role_idx])
        ax.bar([0,1,2,3], [np.mean(middle), np.mean(east), np.mean(north), np.mean(others)], color=colors_role[role_idx], 
               facecolor='none', edgecolor=colors_role[role_idx], linewidth=1.5, width=0.4)
        ax.set_xticks([0,1,2,3])
        ax.set_xticklabels([])
        ax.set_yticks([0,1])
        ax.set_yticklabels([0,1])
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.set_aspect(np.diff(ax.get_xlim())/np.diff(ax.get_ylim()))

        ax = axs[role_idx,2]
        ax.plot(np.array(inter_map).T, color=colors_role[role_idx], linewidth=1, alpha=0.8)
        ax.axhline(0, color='k', linestyle='--', linewidth=0.5)
        ax.set_ylim([-1, 1.5])
        ax.set_yticks([0,1])
        ax.set_yticklabels([0,1])
        ax.set_xticks(range(0, 10, 4))
        ax.set_xticklabels(range(0, 10, 4))
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.set_aspect(np.diff(ax.get_xlim())/np.diff(ax.get_ylim()))

    axs[1,2].set_xlabel('Dijkstra distance (bin)')
    axs[1,2].set_ylabel('V(distance)')
    axs[1,1].set_xticks([0,1,2,3])
    axs[1,1].set_xticklabels(['Middle','East','North','Others'], rotation=30, ha='right')
    axs[1,1].set_ylabel('V(self pos)')
    axs[1,0].set_xlabel('X (cm)')
    axs[1,0].set_ylabel('Y (cm)')
    for ax in axs.flatten():
        for spine in ax.spines.values():
            spine.set_linewidth(LineWidth)
    for ax in axs[1, :]:
        box = ax.get_position()
        ax.set_position([box.x0, box.y0 - 0.05, box.width, box.height])
    for ax in axs[:, 1]:
        box = ax.get_position()
        ax.set_position([box.x0 + 0.05, box.y0, box.width, box.height])
    for ax in axs[:, 2]:
        box = ax.get_position()
        ax.set_position([box.x0 + 0.1, box.y0, box.width, box.height])

    fig.savefig(plot_dir + 'maps_across_animals.png', dpi=300, bbox_inches='tight', transparent=True)
    fig.savefig(plot_dir + 'maps_across_animals.pdf', dpi=300, bbox_inches='tight', transparent=True)
    print('Saved at ' + plot_dir + 'maps_across_animals.png')

#  Plot map for HD fitting: multiple pairs
if args.figure_idx == 3.1:
    print('Plot map for HD fitting: multiple pairs')
    tag_train = 1
    agent = 1
    lr_maps, lr_weights = 0.1, 0.005
    lam1, lam2 = 5.0, 1.0
    gamma, sigma = 0.9, 1.0
    n_maps_individual, n_maps_interaction = 1, 1
    num_trajs, seed, max_iters = 1000, 1, 20
    tag = tags_train[tag_train]
    tag += '_inter_circular_dist'
    tag += '_init_occu'
    
    data_list = ['YC069YC070','YC071YC072','YC073YC074','YC075YC076','YC115YC116','YC091','YC111']
    agent = 1
    inter_map_hd1 = []
    inter_map_hd2 = []
    for data in data_list:
        REC_DIR_NAME = 'recovered_parameters/coop_foraging/experiment_coop_foraging/{}_phase4a_correct_traj_nose_neck_rot_gz5_HD2_remove_state_rep/fit_HD_{}/'.format(data, tag)
        rec_dir_name = REC_DIR_NAME + 'maps_{}_{}_lr_{}_{}_lam_{}_{}_gamma{}_sigma{}_early_stop/agent_{}/'.format(
                    n_maps_individual, n_maps_interaction, lr_maps, lr_weights, lam1, lam2, gamma, sigma, agent)
        if os.path.exists(rec_dir_name+'weights_trajs_1000_seed_1_iters_20.npy'):
            num_trajs = 1000
        elif os.path.exists(rec_dir_name+'weights_trajs_2000_seed_1_iters_20.npy'):
            num_trajs = 2000
        rec_weights = np.load(rec_dir_name + "weights_trajs_" + str(num_trajs) +"_seed_" + str(seed) + "_iters_" + str(max_iters) +".npy")[-1]
        rec_inter_maps = np.load(rec_dir_name + "inter_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
        rec_ind_maps = np.load(rec_dir_name + "ind1_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
        map_weight = rec_weights[0,0]
        c_max = np.max(np.abs(rec_ind_maps[0,:])*map_weight)
        inter_map_hd1.append(rec_inter_maps[0,:,0]*rec_weights[2,0] / c_max)
        inter_map_hd2.append(rec_inter_maps[0,:,1]*rec_weights[2,0] / c_max)

    t_stat, p_value = ttest_rel(np.array(inter_map_hd1)[:,1], np.array(inter_map_hd2)[:,1])
    print(f"Paired t-test results: t-statistic = {t_stat:.3f}, p-value = {p_value:.3e}")
    fig, axs = plt.subplots(1,2,figsize=(3,2))
    plt.rc('font', family='Myriad Pro')  
    plt.rc('font', size=LEGEND_SIZE)
    for hd in range(2):
        ax = axs[hd]
        inter_map = inter_map_hd1 if hd == 0 else inter_map_hd2
        ax.plot(np.array(inter_map).T, color=colors_role[1], linewidth=LineWidth,alpha=0.8)
        ax.axhline(0, color='k', linestyle='--', linewidth=LineWidth)
        ax.set_ylim([-1.3, 1.6])
        ax.set_yticks([-1,0,1])
        ax.set_yticklabels([-1,0,1])
        ax.set_xticks(range(0, 10, 4))
        ax.set_xticklabels(range(0, 10, 4))
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.set_aspect(np.diff(ax.get_xlim())/np.diff(ax.get_ylim()))
    axs[0].set_title('Front')
    axs[1].set_title('Back')
    axs[0].text(2, 1.2, r'$p$={:.2e}'.format(p_value), fontsize=SMALL_SIZE)

    axs[0].set_xlabel('Dijkstra distance (bin)')
    axs[0].set_ylabel('V(distance)')
    for ax in axs.flatten():
        for spine in ax.spines.values():
            spine.set_linewidth(LineWidth)
    fig.savefig(plot_dir + 'HD_maps_multiple.png', dpi=300, bbox_inches='tight', transparent=True)
    fig.savefig(plot_dir + 'HD_maps_multiple.pdf', dpi=300, bbox_inches='tight', transparent=True)
    print('Saved at ' + plot_dir + 'HD_maps_multiple.png')

# LL gain v.s. decoding accuracy
if args.figure_idx == 4:
    print('LL gain v.s. decoding accuracy')
    labels_inter = ['Self','Self+other','Self+distance','Self+distance+HD']
    tags = ['independent_control_self_map_only','independent_control_ind_maps_only',
                  'independent_control_inter_circular_dist','HD_independent_control_inter_circular_dist']
    lr_maps, lr_weights = 0.1, 0.005
    lam1, lam2 = 5.0, 1.0
    gamma, sigma = 0.9, 1.0
    n_maps_individual, n_maps_interaction = 1, 1
    num_trajs, max_iters = 1000, 20
    seed = 1
    animal_list = ['YC069','YC070','YC071','YC072','YC073','YC074','YC075','YC076','YC115','YC116',
                   'YC091','YC111']
    LL_gain = pd.DataFrame({'animal':animal_list,
                            'agent': [1,2,1,2,1,2,1,2,1,2,1,1],
                            'dist_gain': [None]*len(animal_list),
                            'HD_gain': [None]*len(animal_list)})
    for data_idx, data in enumerate(animal_list):
        agent = LL_gain.loc[data_idx, 'agent']
        ll_collect_inter = []
        for i, tag in enumerate(tags):
            REC_DIR_NAME = 'recovered_parameters/coop_foraging/experiment_coop_foraging/{}_phase4a_correct_traj_nose_neck_rot_gz5_HD2_remove_state_rep/fit_{}_init_occu/'.format(data, tag)
            rec_dir_name = REC_DIR_NAME + 'maps_{}_{}_lr_{}_{}_lam_{}_{}_gamma{}_sigma{}_early_stop/agent_{}/'.format(
                n_maps_individual, n_maps_interaction, lr_maps, lr_weights, lam1, lam2, gamma, sigma, agent)
            if os.path.exists(rec_dir_name+'weights_trajs_1000_seed_1_iters_20.npy'):
                num_trajs = 1000
            elif os.path.exists(rec_dir_name+'weights_trajs_2000_seed_1_iters_20.npy'):
                num_trajs = 2000
            tmp = rec_dir_name + "validation_lls_trajs_{}_seed_{}_iters_{}.npy".format(num_trajs, seed, max_iters)
            vali_ll = np.load(tmp)[-1]
            ll_collect_inter.append(vali_ll)
        LL_gain.loc[data_idx, 'dist_gain'] = ll_collect_inter[2] - ll_collect_inter[0]
        LL_gain.loc[data_idx, 'HD_gain'] = ll_collect_inter[3] - ll_collect_inter[2]
        data_idx += 1
    
    neural_accuracy = pd.read_csv('recovered_parameters/coop_foraging/neural_value/decoding_table_animals.csv')
    neural_sel = neural_accuracy[neural_accuracy['animal'].isin(LL_gain['animal'])]
    combined = pd.merge(LL_gain, neural_sel[['animal','role','p_corr_dist','p_corr_angle']], on='animal')
    df_follower = combined[combined.role == 'follower']
    df_leader = combined[combined.role == 'leader']
    combined['dist_gain'] = combined['dist_gain'].astype(np.float64)
    combined['HD_gain'] = combined['HD_gain'].astype(np.float64)

    fig, axs = plt.subplots(1,2,figsize=(3,2))
    plt.rc('font', family='Myriad Pro')  # Set the font type for the entire figure
    plt.rc('font', size=LEGEND_SIZE)  # Set the font size for the entire figure
    ax = axs[0]
    p1 = ax.scatter(df_follower.p_corr_dist, df_follower.dist_gain, color=colors_role[1], label='Follower', edgecolor='black', linewidth=LineWidth_marker)
    p2 = ax.scatter(df_leader.p_corr_dist, df_leader.dist_gain, color=colors_role[0], label='Leader', edgecolor='black', linewidth=LineWidth_marker)
    ll_thres = chi2.ppf(1 - 0.01, 10) / 2
    ax.hlines([ll_thres, ll_thres], xmin=ax.get_xlim()[0], xmax=ax.get_xlim()[1], color='black', linestyle='dashed', linewidth=LineWidth)
    slope, intercept, r_value, p_value, std_err = linregress(combined.p_corr_dist,
                                                              combined.dist_gain)
    x_vals = np.linspace(combined.p_corr_dist.min(), combined.p_corr_dist.max(), 100)
    y_vals = slope * x_vals + intercept
    ax.plot(x_vals, y_vals, color='black', linestyle='solid', linewidth=1)
    print('$R$={:.2f}'.format(r_value))
    print('pvalue={:.3f}'.format(p_value))
    ax.set_xlabel('Decoding accuracy')
    ax.set_ylabel('LL Gain')
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.set_aspect(np.diff(ax.get_xlim())/np.diff(ax.get_ylim()))


    ax = axs[1]
    p1 = ax.scatter(df_follower.p_corr_angle, df_follower.HD_gain, color=colors_role[1], label='Follower', edgecolor='black', linewidth=LineWidth_marker)
    p2 = ax.scatter(df_leader.p_corr_angle, df_leader.HD_gain, color=colors_role[0], label='Leader', edgecolor='black', linewidth=LineWidth_marker)
    ax.hlines([ll_thres, ll_thres], xmin=ax.get_xlim()[0], xmax=ax.get_xlim()[1], color='black', linestyle='dashed', linewidth=LineWidth)
    slope, intercept, r_value, p_value, std_err = linregress(combined.p_corr_angle,
                                                              combined.HD_gain)
    x_vals = np.linspace(combined.p_corr_angle.min(), combined.p_corr_angle.max(), 100)
    y_vals = slope * x_vals + intercept
    ax.plot(x_vals, y_vals, color='black', linestyle='solid', linewidth=1)
    print('$R$={:.2f}'.format(r_value))
    print('pvalue={:.3f}'.format(p_value))
    ax.set_xlabel('Decoding accuracy')
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.set_aspect(np.diff(ax.get_xlim())/np.diff(ax.get_ylim()))
    for ax in axs.flatten():
        for spine in ax.spines.values():
            spine.set_linewidth(LineWidth)

    fig.savefig(plot_dir + 'LL_gain_neural_prop.png', dpi=300, bbox_inches='tight', transparent=True)
    fig.savefig(plot_dir + 'LL_gain_neural_prop.pdf', dpi=300, bbox_inches='tight', transparent=True)
    print('Saved at ' + plot_dir + 'LL_gain_neural_prop.png')

# Example of p-value calcultion from null distribution    
if args.figure_idx == 5:
    print('Neural activity v.s. Value representation')
    animal_list = ['069','070']
    date_list = ['20240601','20240521']
    fig, axs = plt.subplots(1,2,figsize=(3.5,2.5))
    for idx in range(2):
        data_dir = 'recovered_parameters/coop_foraging/neural_value/YC{}_{}'.format(animal_list[idx], date_list[idx])
        R_obs = np.load(data_dir + '/lr_R2.npy')
        with open(data_dir +'/lr_frame_shuffled_R2.pkl', 'rb') as f:
            R_shuffled = pickle.load(f)
        mu, std = norm.fit(R_shuffled)
        p_value = 1 - norm.cdf(R_obs, loc=mu, scale=std)
        ax = axs[idx]
        h = ax.hist(R_shuffled, bins=30, alpha=0.7, color=colors_role[1-idx], edgecolor='white')
        v = ax.vlines(R_obs, ymin=0, ymax=max(ax.get_ylim()), color=colors_role[1-idx], linestyle='dashed', linewidth=2)
        ax.set_xlabel(r'$R^2$')
        ax.set_ylim([0, max(h[0])*1.2])
        ax.legend([h[2][0], v], ['Null', 'Observed'], frameon=False, fontsize=LEGEND_SIZE-2, ncol=2)
        ax.set_title('P value: {:.1e}'.format(p_value))
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.set_aspect(np.diff(ax.get_xlim())/np.diff(ax.get_ylim()))
    axs[0].set_ylabel('Frequency')
    plt.tight_layout()
    fig.savefig(plot_dir + 'R2_null.png', dpi=300, bbox_inches='tight', transparent=True)
    fig.savefig(plot_dir + 'R2_null.pdf', dpi=300, bbox_inches='tight', transparent=True)
    print('Saved at ' + plot_dir + 'R2_null.png')

# Population neural decoding: -log(pvalue) v.s. R2
if args.figure_idx == 5.1:
    df = pd.read_csv('recovered_parameters/coop_foraging/neural_value/animal_mdl.txt',delimiter=",")
    animal_date_list = {}
    for idx in df.index:
        animal = df.loc[idx, 'animal']
        role = df.loc[idx, 'role']
        date_list = str(df.loc[idx, 'date_list']).split(' ')
        if date_list[0] != 'nan':
            animal_date_list[animal+'_'+role] = date_list
    df_days = pd.DataFrame({'animal': [], 'date_list': []})
    rows = [{'animal': animal, 'date_list': date} for animal, date_list in animal_date_list.items() for date in date_list]
    df_days = pd.concat([df_days, pd.DataFrame(rows)], ignore_index=True)
    df_days[['animal', 'role']] = df_days['animal'].str.split('_', expand=True)
    df_days['R2'] = np.nan
    df_days['p_value'] = np.nan
    for idx in df_days.index:
        animal = df_days.loc[idx, 'animal']
        date = df_days.loc[idx, 'date_list']
        data_dir = 'recovered_parameters/coop_foraging/neural_value/{}_{}'.format(animal,date)
        R_obs = np.load(data_dir + '/lr_R2.npy')
        with open(data_dir +'/lr_frame_shuffled_R2.pkl', 'rb') as f:
            R_shuffled = pickle.load(f)
        mu, std = norm.fit(R_shuffled)
        p_value = 1 - norm.cdf(R_obs, loc=mu, scale=std)
        df_days.loc[idx, 'R2'] = R_obs
        df_days.loc[idx, 'p_value'] = p_value
    
    df_days['p_value_log'] = [-np.log10(p) if p > 0 else 20 for p in df_days['p_value']]
    df_follower = df_days[df_days.role == 'follower']
    df_leader = df_days[df_days.role == 'leader']

    fig = plt.figure(figsize=(2,2))
    plt.rc('font', family='Myriad Pro')  
    plt.rc('font', size=LEGEND_SIZE)

    gs = fig.add_gridspec(2, 1, height_ratios=[1, 4])  # Adjust height ratios
    ax1 = fig.add_subplot(gs[0])
    ax2 = fig.add_subplot(gs[1], sharex=ax1)
    fig.subplots_adjust(hspace=0.05)  # adjust space between Axes
    ax1.scatter(df_follower['R2'], df_follower['p_value_log'], color=colors_role[1], label='Follower', edgecolors='black', linewidth=LineWidth_marker)
    ax1.scatter(df_leader['R2'], df_leader['p_value_log'], color=colors_role[0], label='Leader', edgecolors='black', linewidth=LineWidth_marker)
    s1 = ax2.scatter(df_follower['R2'], df_follower['p_value_log'], color=colors_role[1], label='Follower', edgecolors='black', linewidth=LineWidth_marker)
    s2 = ax2.scatter(df_leader['R2'], df_leader['p_value_log'], color=colors_role[0], label='Leader', edgecolors='black', linewidth=LineWidth_marker)
    ax2.hlines(2, xmin=0, xmax=max(ax2.get_xlim()), color='black', linestyle='dashed', linewidth=LineWidth)

    ax1.set_ylim(19.5, 20.5)  # outliers only
    ax1.set_yticks([20])
    ax1.set_yticklabels([r'$>$16'])
    ax2.set_ylim(0, 17)  # most of the data

    ax1.spines.bottom.set_visible(False)
    ax1.spines.top.set_visible(False)
    ax1.spines.right.set_visible(False)
    ax2.spines.top.set_visible(False)
    ax2.spines.right.set_visible(False)
    ax1.tick_params(axis='x', which='both', bottom=False, top=False, labelbottom=False, labeltop=False)
    ax2.xaxis.tick_bottom()

    ax2.set_xlabel(r'$R^2$ score')
    ax2.set_ylabel('-log(p-value)')
    ax2.legend(handles=[s1, s2], labels=['Follower', 'Leader'], 
              frameon=True, prop={'weight': 'bold'}, loc='upper left',handlelength=0, handletextpad=0)
    legend = ax2.get_legend()
    legend.get_texts()[0].set_color(colors_role[1]) 
    legend.get_texts()[1].set_color(colors_role[0])  
    # ax.set_aspect(np.diff(ax.get_xlim())/np.diff(ax.get_ylim()))
    ax1.set_title('Neural rep. of value')

    d = .5  # proportion of vertical to horizontal extent of the slanted line
    kwargs = dict(marker=[(-1, -d), (1, d)], markersize=12,
                linestyle="none", color='k', mec='k', mew=1, clip_on=False)
    ax1.plot([0, 0], [0, 0], transform=ax1.transAxes, **kwargs)
    ax2.plot([0, 0], [1, 1], transform=ax2.transAxes, **kwargs)
    for ax in [ax1, ax2]:
        for spine in ax.spines.values():
            spine.set_linewidth(LineWidth)
    fig.savefig(plot_dir + 'R2.png', dpi=300, bbox_inches='tight', transparent=True)
    fig.savefig(plot_dir + 'R2.pdf', dpi=300, bbox_inches='tight', transparent=True)
    print('Saved at ' + plot_dir + 'R2.png')

# Trials stats for daily sessions
if args.figure_idx == 5.2:
    df = pd.read_csv('recovered_parameters/coop_foraging/neural_value/animal_mdl.txt',delimiter=",")
    animal_date_list = {}
    for idx in df.index:
        animal = df.loc[idx, 'animal']
        role = df.loc[idx, 'role']
        date_list = str(df.loc[idx, 'date_list']).split(' ')
        if date_list[0] != 'nan':
            animal_date_list[animal+'_'+role] = date_list
    df_days = pd.DataFrame({'animal': [], 'date_list': []})
    rows = [{'animal': animal, 'date_list': date} for animal, date_list in animal_date_list.items() for date in date_list]
    df_days = pd.concat([df_days, pd.DataFrame(rows)], ignore_index=True)
    df_days[['animal', 'role']] = df_days['animal'].str.split('_', expand=True)
    N_list = []
    T_list = []
    Trial_list = []
    for idx in df_days.index:
        animal = df_days.loc[idx, 'animal']
        date = df_days.loc[idx, 'date_list']
        neural_data_path = 'data/experiment_coop_foraging/neural_data/{}_{}_neural_loc.csv'.format(animal, date)
        neural_data = pd.read_csv(neural_data_path, delimiter=',') 
        colname_neuron = [name for name in neural_data.columns if 'Neuron' in name]
        neural_data = neural_data[colname_neuron]
        N, T = neural_data.shape
        tmp = 'YC069YC070' if animal == 'YC069' else animal
        traj_file = 'data/experiment_coop_foraging/{}_{}_traj_neck_rot_gz5_remove_rep/expert_trajectories.pickle'.format(tmp,date)
        with open(traj_file, 'rb') as f:
            all_expert_trajectories = pickle.load(f)
        num_trajs = len(all_expert_trajectories)
        Trial_list.append(num_trajs)
        N_list.append(N)
        T_list.append(T)
    df_days['num_trajs'] = Trial_list
    df_days['N'] = N_list
    df_days['T'] = T_list
    df_days.to_csv(plot_dir + 'neural_data_summary.csv', index=False)
    print('Saved neural data summary to ' + plot_dir + 'neural_data_summary.csv')

# Simulate trajectories and calculate the reward zone chosen probability
if args.figure_idx == 6:
    def simulate_trajectory(gw, policy, traj, agent):
        target1 = (4,8,4,8)
        target2 = (8,4,8,4)
        gw.reset(traj['states4d'][0])
        step = 0
        traj_rec = []
        agent_idx = [0,1] if agent == 1 else [2,3]
        while step < 1000:
            cur_ind = gw.get_current_state()[:2] if agent == 1 else gw.get_current_state()[2:4]
            traj_rec.append(cur_ind)
            # move the selected agent based on policy and the other one based on known information
            s_idx = gw.pos2idx1(gw.get_current_state())
            action_self = np.random.choice(len(policy[s_idx, :]), p=policy[s_idx, :])
            if step < len(traj['actions2d']):
                action_other = traj['actions2d'][step][2-agent]
            else:
                action_other = 4
            action_joint = (action_self, action_other) if agent == 1 else (action_other, action_self)
            gw.step(action_joint)
            current = gw.get_current_state()
            if max([abs(current[i]-target1[i]) for i in agent_idx]) < 1 or max([abs(current[i]-target2[i]) for i in agent_idx]) < 1:
                break
            step += 1
        cur_ind = gw.get_current_state()[:2] if agent == 1 else gw.get_current_state()[2:4]
        traj_rec.append(cur_ind)
        return traj_rec

    tags = ['independent_control_self_map_only','independent_control_ind_maps_only',
            'independent_control_inter_circular_dist']
    tags_idx = [7,8,6]
    lr_maps, lr_weights = 0.1, 0.005
    lam1, lam2 = 5.0, 1.0
    gamma, sigma = 0.9, 1.0
    n_maps_individual, n_maps_interaction = 1, 1
    num_trajs, max_iters = 1000, 20
    seed = 1
    height, width = 10, 10
    correct_list = []
    correct_random_list = []

    df = pd.read_csv('figures_coop_foraging_formal/model_comparison_LL_gain_p_value.csv')
    df['traj_sim_correct'] = [None]*len(df)
    df['traj_sim_correct_random'] = [None]*len(df)
    for data_idx, data in enumerate(df['animal']):
        agent = df.loc[data_idx, 'agent']
        print('Animal: {}, agent: {}'.format(data, agent))
        correct_tags = []
        correct_random_tags = []
        for t_idx, tag in enumerate(tags):
            info = {'inter_tag': tags_idx[t_idx], 'SingleAgent': agent, 'HD': False}
            # evaluate the model derivated policy
            REC_DIR_NAME = 'recovered_parameters/coop_foraging/experiment_coop_foraging/{}_traj_nose_neck_rot_gz5_HD2_remove_state_rep/fit_{}_init_occu/'.format(data, tag)
            rec_dir_name = REC_DIR_NAME + 'maps_{}_{}_lr_{}_{}_lam_{}_{}_gamma{}_sigma{}_early_stop/agent_{}/'.format(
                n_maps_individual, n_maps_interaction, lr_maps, lr_weights, lam1, lam2, gamma, sigma, agent)
            if os.path.exists(rec_dir_name + 'weights_trajs_1000_seed_1_iters_20.npy'):
                num_trajs = 1000
            elif os.path.exists(rec_dir_name + 'weights_trajs_2000_seed_1_iters_20.npy'):
                num_trajs = 2000
            a = np.load(rec_dir_name+'weights_trajs_{}_seed_1_iters_20.npy'.format(num_trajs))[-1]
            diff_map = np.load(rec_dir_name+'inter_maps_trajs_{}_seed_1_iters_20.npy'.format(num_trajs))[-1]
            individual_map1 = np.load(rec_dir_name+'ind1_maps_trajs_{}_seed_1_iters_20.npy'.format(num_trajs))[-1]
            individual_map2 = np.load(rec_dir_name+'ind2_maps_trajs_{}_seed_1_iters_20.npy'.format(num_trajs))[-1]
            GEN_DIR_NAME = 'data/experiment_coop_foraging/{}_traj_nose_neck_rot_gz5_HD2_remove_state_rep'.format(data) 
            file_trajs = open(GEN_DIR_NAME +'/expert_trajectories.pickle', 'rb')
            all_expert_trajectories = pickle.load(file_trajs)
            file = open(GEN_DIR_NAME + '/generative_parameters.pickle', 'rb')
            generative_params = pickle.load(file)
            P_a = generative_params['P_a'] 
            N_traj = min(len(all_expert_trajectories), num_trajs)
            all_expert_trajectories = all_expert_trajectories[:N_traj]
            all_expert_trajectories_single = []
            for traj in all_expert_trajectories:
                traj['actions'] = [a[agent-1] for a in traj['actions2d']]
                all_expert_trajectories_single.append(traj)

            P_a = torch.from_numpy(P_a).float()
            a = torch.from_numpy(a).float()
            goal_maps = create_joint_maps_v2(individual_map1, individual_map2, diff_map, info, width, height)
            goal_maps = torch.from_numpy(goal_maps).float()
            rewards = a.T @ goal_maps
            policy, p1, p2 = policy_vi(P_a, rewards, gamma, 1)
            policy = p1 if agent == 1 else p2
            
            gw = gridworld.GridWorld_9action(height,width,np.zeros((height, width)).astype(int),{}) # self.dirs = {0: 'r', 1: 'l', 2: 'd', 3: 'u', 4: 's', 5: 'ur', 6: 'dr', 7: 'ul', 8: 'dl'}
            # # Example trajectory simulation
            # i = 0
            # traj_rec = simulate_trajectory(gw, policy.detach().numpy(), all_expert_trajectories_single[i], agent)
            # traj_rec = np.array(traj_rec)
            # traj_real = np.array([(a,b) for (a,b,c,d) in all_expert_trajectories_single[i]['states4d']]) if agent == 1 else np.array([(c,d) for (a,b,c,d) in expert_trajectories_single[i]['states4d']])
            # fig, ax = plt.subplots(1,2, figsize=(8,3))
            # plot_gridworld_trajectories(10, 10, {'states2d':traj_real}, fig, ax[0])
            # plot_gridworld_trajectories(10, 10, {'states2d':traj_rec}, fig, ax[1])
            # ax[0].set_title('Real trajectory')
            # ax[1].set_title('Estimated trajectory')
            # fig.suptitle('Traj: {}'.format(i), fontsize=SMALL_SIZE)
            # fig.savefig(plot_dir + 'estimated_trajectory.png', dpi=300, bbox_inches='tight', transparent=True)
            # print('Saved at ' + plot_dir + 'estimated_trajectory.png')

            correct = []
            correct_random = []
            for i in range(len(all_expert_trajectories_single)):
                traj_rec = simulate_trajectory(gw, policy.detach().numpy(), all_expert_trajectories_single[i], agent)
                traj_rec = np.array(traj_rec)
                traj_real = np.array([(a,b) for (a,b,c,d) in all_expert_trajectories_single[i]['states4d']]) if agent == 1 else np.array([(c,d) for (a,b,c,d) in all_expert_trajectories_single[i]['states4d']])
                dist = max(traj_real[-1] - traj_rec[-1])
                correct.append(1 if dist < 1 else 0)
                policy_random = np.ones(policy.shape) / policy.shape[1]
                traj_rec_random = simulate_trajectory(gw, policy_random, all_expert_trajectories_single[i], agent)
                traj_rec_random = np.array(traj_rec_random)
                dist = max(traj_real[-1] - traj_rec_random[-1])
                correct_random.append(1 if dist < 1 else 0)
            correct_tags.append(sum(correct)/len(correct))
            correct_random_tags.append(sum(correct_random)/len(correct_random))
        df.loc[data_idx, 'traj_sim_correct'] = str(correct_tags)
        df.loc[data_idx, 'traj_sim_correct_random'] = str(correct_random_tags)
    
    df.to_csv(plot_dir + 'traj_sim_correct.csv', index=False)

# Plot simulation results
if args.figure_idx == 6.1:
    summary_tab = pd.read_csv(plot_dir + 'traj_sim_correct.csv')
    labels_inter = ['Self','Self+other','Self+distance','Self+distance+HD']
    width = 0.4 
    fig_name = plot_dir + 'traj_sim_correct'
    correct_follower = []
    correct_leader = []
    ll_follower = []
    ll_leader = []
    correct_baseline = []
    for idx in range(len(summary_tab)):
        data = summary_tab.loc[idx, 'animal']
        agent = summary_tab.loc[idx, 'agent']
        role = summary_tab.loc[idx, 'role']
        correct_list = summary_tab[(summary_tab.animal == data) & (summary_tab.agent == agent)].traj_sim_correct.values[0].split('[')[1].split(']')[0].split(',')
        ll_list = summary_tab[(summary_tab.animal == data) & (summary_tab.agent == agent)].LL_per_decision.values[0].split('[')[1].split(']')[0].split(',')
        if role == 'Follower':
            correct_follower.append([float(i) for i in correct_list])
            ll_follower.append([float(i) for i in ll_list])
        else:
            correct_leader.append([float(i) for i in correct_list])
            ll_leader.append([float(i) for i in ll_list])
        correct_tmp = summary_tab[(summary_tab.animal == data) & (summary_tab.agent == agent)].traj_sim_correct_random.values[0].split('[')[1].split(']')[0].split(',')
        correct_baseline += [float(i) for i in correct_tmp]

    print('Testing for leader significance')
    for i in range(len(correct_leader[0])):
        t_stat, p_value = ttest_1samp(np.array(correct_leader)[:, i], np.mean(correct_baseline))
        print(p_value)
    print('Testing for follower significance')
    for i in range(len(correct_follower[0])):
        t_stat, p_value = ttest_1samp(np.array(correct_follower)[:, i], np.mean(correct_baseline))
        print(p_value)

    fig, axs = plt.subplots(1, 2, figsize=(3, 1.5))
    plt.rc('font', family='Myriad Pro')  
    plt.rc('font', size=LEGEND_SIZE)
    ax = axs[0]
    ax.barh(np.arange(len(labels_inter)) - width / 2, np.mean(ll_follower, axis=0)[::-1], height=width,
            facecolor='none', edgecolor=colors_role[1], linewidth=LineWidth, label='Follower')
    ax.barh(np.arange(len(labels_inter)) + width / 2, np.mean(ll_leader, axis=0)[::-1], height=width,
            facecolor='none', edgecolor=colors_role[0], linewidth=LineWidth, label='Leader')
    for i in range(len(labels_inter)):
        ax.scatter(np.array(ll_follower)[:, i], [len(labels_inter)-1-i-width/2] * len(ll_follower), s=MarkerSize, color=colors_role[1])
        ax.scatter(np.array(ll_leader)[:, i], [len(labels_inter)-1-i+width/2] * len(ll_leader), s=MarkerSize, color=colors_role[0])
    ax.axvline(np.log(1/9), color='k', linestyle='--', linewidth=LineWidth)
    ax.set_xlim([-2.4, -1.])
    ax.set_yticks(range(len(labels_inter)))
    ax.set_yticklabels(labels_inter[::-1])
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.set_aspect(np.diff(ax.get_xlim()) / np.diff(ax.get_ylim()))
    ax.set_xlabel('LL per decision')

    ax = axs[1]
    ax.barh(np.array([1,2,3]) - width / 2, np.mean(correct_follower, axis=0)[::-1], height=width,
            facecolor='none', edgecolor=colors_role[1], linewidth=LineWidth, label='Follower')
    ax.barh(np.array([1,2,3]) + width / 2, np.mean(correct_leader, axis=0)[::-1], height=width,
            facecolor='none', edgecolor=colors_role[0], linewidth=LineWidth, label='Leader')
    for i in range(len(labels_inter)-1):
        ax.scatter(np.array(correct_follower)[:, i], [len(labels_inter)-1-i-width/2] * len(correct_follower), s=MarkerSize, color=colors_role[1])
        ax.scatter(np.array(correct_leader)[:, i], [len(labels_inter)-1-i+width/2] * len(correct_leader), s=MarkerSize, color=colors_role[0])
    ax.axvline(np.mean(correct_baseline), color='k', linestyle='--', linewidth=LineWidth)
    ax.set_yticks(range(len(labels_inter)))
    ax.set_yticklabels([])
    ax.set_ylim(axs[0].get_ylim())
    ax.set_xlim([0, 1])
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.set_aspect(np.diff(ax.get_xlim()) / np.diff(ax.get_ylim()))
    ax.set_ylabel('')
    ax.set_xlabel('Correct prediction')
    for ax in axs:
        for spine in ax.spines.values():
            spine.set_linewidth(LineWidth)

    # plt.tight_layout()
    fig.savefig(fig_name + '.png', dpi=300, bbox_inches='tight', transparent=True)
    fig.savefig(fig_name + '.pdf', dpi=300, bbox_inches='tight', transparent=True)
    print('Saved at ' + fig_name + '.png')
