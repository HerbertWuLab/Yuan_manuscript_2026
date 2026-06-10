# two agent collaborative exploration version
# incorporate head direction and remove weight optimization (Y.C. Feb 2025)

import os, argparse
import numpy as np
import pickle
from src.optimize_weights import getMAP_weights
from itertools import permutations
import matplotlib.pyplot as plt
from src.compute_conf_interval import compute_inv_hessian_maps, compute_conf_interval_maps
from src.irl_for_gridworld import fit_irl_gridworld
from src.irl_for_gridworld_ind import fit_irl_gridworld_ind
import time



if __name__=='__main__':

    parser = argparse.ArgumentParser(description='enter environment specifics')
    parser.add_argument('--TRAIN_NOW', type=int, default=0, help='whether to train now')
    parser.add_argument('--TRAIN_NOW_IND', type=int, default=0, help='whether to train independent control now')
    parser.add_argument('--HD',action='store_true', help='whether to use HD')
    parser.add_argument('--DATA', type=str, help='data directory containing trajectories and generative parameters')
    parser.add_argument('--TAG_TRAIN', type=int, default=0, help='which interaction type used to infer')
    parser.add_argument('--GRID_SIZE', type=int, default=4, help='grid size (cm), the whole arena is 50cm x 50cm')
    parser.add_argument('--num_trajs', type=int, default=200, help='number of trajectories to use')
    parser.add_argument('--SingleAgent', type=int, default=0, help='which agent to plot')
    parser.add_argument('--seed', type=int, default=1, help='seed for initialization')
    parser.add_argument('--INTERACTION_TAG', type=int, default=5, help='which interaction function to use (default: 5)')
    parser.add_argument('--initialization', type=int, default=0, help='which initialization to use (default: 0)')
    parser.add_argument('--lam1', type=float, default=10, help='Regularization on individual maps')
    parser.add_argument('--lam2',type=float, default=2, help='Regularization on the interaction map')
    parser.add_argument('--lr_maps', type=float, default=0.005, help='learning rate for maps')
    parser.add_argument('--lr_weights', type=float, default=0.01, help='learning rate for weights')
    parser.add_argument('--max_iters', type=int, default=20, help='max iters to run SGD for optimization of goal maps and weights durng each outer loop of dirl')
    parser.add_argument('--n_maps_individual', type=int, default=1, help='number of individual maps')
    parser.add_argument('--early_stop', action='store_true', help='whether to use early stopping')
    parser.add_argument('--sigma', type=float, default=0, help='sigma for weight coefficient (default to use 0.01)')
    parser.add_argument('--gamma', type=float, default=0.9, help='discount factor')

    args = parser.parse_args()

    TRAIN_NOW = args.TRAIN_NOW 
    TRAIN_NOW_IND = args.TRAIN_NOW_IND
    TAG_TRAIN = args.TAG_TRAIN
    INTERACTION_TAG = args.INTERACTION_TAG
    INITIALIZATION_TAG = args.initialization

    tags_train = ['centralized', 'independent_control', 'independent_control_w_uniform_prediction',
                   '', '', 'selfish',
                   'independent_control_ego_uniform', 'independent_control_ego_ToM1']
    tag_train = tags_train[TAG_TRAIN]
    tags_inter = ['','_inter_circular_dist','_self_map_only','_ind_maps_only','_inter_circular_dist_only']
    # 5: two self maps + absolute circular distance
    # 6: self map + absolute circular distance, neglect the other agent's map
    # 7: neglect the other agent's map and the interaction map
    # 8: neglect the interaction map
    # 9: only using the interaction map
    tag_inter = tags_inter[INTERACTION_TAG-5]
    tags_init = ['','_init_occu']
    tag_init = tags_init[INITIALIZATION_TAG]

    print('tag_train:', tag_train)
    print('tag_inter:', tag_inter)

    GEN_DIR_NAME = 'data/' + args.DATA
    REC_DIR_NAME = 'recovered_parameters/coop_foraging/' + args.DATA
    model_name = '/fit_HD_'+tags_train[TAG_TRAIN] if args.HD else '/fit_'+tags_train[TAG_TRAIN]
    REC_DIR_NAME += model_name
    REC_DIR_NAME += tag_inter
    REC_DIR_NAME += tag_init

    grid_H, grid_W = int(45/args.GRID_SIZE)+1, int(45/args.GRID_SIZE)+1 # grid size

    num_trajs = args.num_trajs # number of simulated trajectories to use
    max_iters = args.max_iters # max iters to run SGD for optimization of goal maps and weights durng each outer loop of dirl
    n_maps_individual = args.n_maps_individual # individual maps per agent
    n_maps_interaction = 1 # interaction maps to use
    lr_maps = args.lr_maps # lr of goal maps
    lr_weights = args.lr_weights # lr of weights
    seed = args.seed # initialization seed
    gamma = args.gamma # discount factor
    lam1 = args.lam1 # l2 reg on individual maps
    lam2 = args.lam2 # l2 reg on interactions maps

    info = {'Neval':0}
    info['inter_tag'] = INTERACTION_TAG
    info['init_tag'] = INITIALIZATION_TAG
    info['HD'] = args.HD
    info['SingleAgent'] = args.SingleAgent
    info['early_stop'] = args.early_stop
    info['sigma'] = args.sigma
    info['gamma'] = gamma
    info['lam1'] = lam1
    info['lam2'] = lam2
    info['seed'] = seed

    rec_dir_name = REC_DIR_NAME + "/maps_{}_{}_lr_{}_{}_lam_{}_{}".format(n_maps_individual, n_maps_interaction, lr_weights, lr_maps, lam1, lam2)
    rec_dir_name += '_gamma' + str(gamma)
    if info['sigma']:
        rec_dir_name += '_sigma' + str(info['sigma'])
    if info['early_stop']:
        rec_dir_name = rec_dir_name + '_early_stop'
    if info['SingleAgent']:
        rec_dir_name = rec_dir_name + '/agent_' + str(args.SingleAgent) + '/'
        print('Saved at ', rec_dir_name)
    
    if not rec_dir_name.endswith('/'):
        rec_dir_name += '/'
        
    if not os.path.exists(rec_dir_name):
        os.makedirs(rec_dir_name)

    with open(os.path.join(rec_dir_name, 'info.txt'), 'w') as f:
        for key, value in info.items():
            f.write(f"{key}: {value}\n")

    if TRAIN_NOW:
        start_time = time.time()
        # HD or lr_weights not incorporated
        fit_irl_gridworld(num_trajs, lr_weights, lr_maps, max_iters, gamma, n_maps_individual, n_maps_interaction,
                          seed, GEN_DIR_NAME, rec_dir_name, lam1, lam2, TAG_TRAIN, info)
        elapsed_time = time.time() - start_time
        log_file = os.path.join(rec_dir_name, 'training_log.txt')
        elapsed_time_minutes = elapsed_time / 60
        with open(log_file, 'w') as f:
            f.write(f"Elapsed Time: {elapsed_time_minutes:.2f} minutes\n")
            f.close()
    
    if TRAIN_NOW_IND:
        start_time = time.time()
        fit_irl_gridworld_ind(num_trajs, lr_weights, lr_maps, max_iters, gamma, n_maps_individual, n_maps_interaction,
                            seed, GEN_DIR_NAME, rec_dir_name, lam1, lam2, TAG_TRAIN, info)
        elapsed_time = time.time() - start_time
        log_file = os.path.join(rec_dir_name, 'training_log.txt')
        elapsed_time_minutes = elapsed_time / 60
        with open(log_file, 'w') as f:
            f.write(f"Elapsed Time: {elapsed_time_minutes:.2f} minutes\n")
            f.close()
    
    rec_weights = np.load(rec_dir_name + "weights_trajs_" + str(num_trajs) +"_seed_" + str(seed) + "_iters_" + str(max_iters) +".npy")[-1]
    rec_ind1_maps = np.load(rec_dir_name + "ind1_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
    rec_ind2_maps = np.load(rec_dir_name + "ind2_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
    rec_inter_maps = np.load(rec_dir_name + "inter_maps_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")[-1]
    test_ll = np.load(rec_dir_name + "validation_lls_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")
    train_ll = np.load(rec_dir_name + "training_lls_trajs_" + str(num_trajs) + "_seed_" + str(seed) + "_iters_" + str(max_iters) + ".npy")


    # inv_hess_individual_map1, inv_hess_individual_map2, inv_hess_inter_maps = compute_inv_hessian_maps(seed, P_a, expert_trajectories, hyperparams, rec_weights, 
                                    # rec_ind1_maps, rec_ind2_maps, rec_inter_maps, tag_train, lam1, lam2, gamma=0.9)
    # std_inter_maps = compute_conf_interval_maps(inv_hess_inter_maps)

    # ---------------------------------------------------------
    # Begin Plotting
    # ---------------------------------------------------------
    save_dir = rec_dir_name 
    print('Save at:', save_dir)

    LEGEND_SIZE = 10
    SMALL_SIZE = 15
    BIGGER_SIZE = 20

    plt.rc('font', size=LEGEND_SIZE)          # controls default text sizes
    plt.rc('axes', titlesize=LEGEND_SIZE)     # fontsize of the axes title
    plt.rc('axes', labelsize=LEGEND_SIZE)    # fontsize of the x and y labels
    plt.rc('xtick', labelsize=LEGEND_SIZE)    # fontsize of the tick labels
    plt.rc('ytick', labelsize=LEGEND_SIZE)    # fontsize of the tick labels
    plt.rc('legend', fontsize=LEGEND_SIZE)    # legend fontsize
    colors = ['steelblue', '#D85427', 'tab:green', 'k']

    # Plot the maps and list the weight
    fig, axs = plt.subplots(1+n_maps_individual, 2, figsize=(8,5))
    ax = axs[0,0]
    ax.plot(rec_inter_maps[0,:])
    if args.HD:
        ax.legend([str(i) for i in range(rec_inter_maps.shape[2])])
    ax.set_xlabel('Circular distance')
    ax.set_ylabel('Value')
    ax.set_title('{:.2f}'.format(rec_weights[2,0]))

    for i in range(n_maps_individual):
        ax = axs[i+1,0]
        im = ax.imshow(np.reshape(rec_ind1_maps[i,:],(grid_H, grid_W), order='F'))
        plt.colorbar(im, ax=ax)
        ax.set_title('Rec. agent 1: {:.2f}'.format(rec_weights[0,0]), fontsize=8)
        ax = axs[i+1,1]
        im = ax.imshow(np.reshape(rec_ind2_maps[i,:],(grid_H, grid_W),order='F'))
        plt.colorbar(im, ax=ax)
        ax.set_title('Rec. agent 2: {:.2f}'.format(rec_weights[1,0]), fontsize=8)
    
    plt.tight_layout()
    fig.savefig(save_dir + 'maps.png')
    # fig.savefig(save_dir + 'maps.pdf')

    # load in loss function and plot
    losses_all_maps = np.load(save_dir + 'losses_maps_trajs_{}_seed_{}_iters_{}.npy'.format(num_trajs, seed, max_iters))
    losses_weights = np.load(save_dir + 'losses_weights_trajs_{}_seed_{}_iters_{}.npy'.format(num_trajs, seed, max_iters))

    fig, axs = plt.subplots(2,1,figsize=(4.4, 4.4))
    axs[0].plot(losses_weights)
    axs[0].set_title('Loss for weight')
    axs[1].plot(losses_all_maps)
    axs[1].set_title('Loss for maps')
    plt.tight_layout()
    fig.savefig(save_dir + 'losses.pdf')

    # load in test set ll and plot
    fig, axs = plt.subplots(1,2, figsize=(5,2.2))
    axs[0].plot(np.array(train_ll))
    axs[0].set_xlabel('Iteration (outer loop)')
    axs[0].set_ylabel('Train ll')
    axs[0].set_title('Final: {:.2f}'.format(train_ll[-1]))
    axs[1].plot(np.array(test_ll))
    axs[1].set_xlabel('Iteration (outer loop)')
    axs[1].set_ylabel('Test ll')
    axs[1].set_title('Final: {:.2f}'.format(test_ll[-1]))
    plt.tight_layout()
    fig.savefig(save_dir + 'test_ll.pdf')


