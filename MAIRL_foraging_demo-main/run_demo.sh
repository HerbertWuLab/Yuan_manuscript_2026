for data in YC069
do
    python process_coop_foraging_data.py --HD --remove_state_rep --save_tag _remove_state_rep \
    --name ${data}_phase4a_correct_traj_nose_neck_rot 
    python main_irl_foraging.py --GRID_SIZE 5 --TRAIN_NOW_IND 1 --SingleAgent 1 --HD \
    --TAG_TRAIN 1 --INTERACTION 6 --initialization 1 --early_stop --lr_weights 0.1 \
    --num_trajs 1000 --seed 1 --lam1 5.0 --lam2 1.0 --sigma 1.0 --gamma 0.9 --max_iters 20 \
    --DATA experiment_coop_foraging/${data}_phase4a_correct_traj_nose_neck_rot_gz5_HD2_remove_state_rep
    python main_irl_foraging.py --GRID_SIZE 5 --TRAIN_NOW_IND 1 --SingleAgent 2 --HD \
    --TAG_TRAIN 1 --INTERACTION 6 --initialization 1 --early_stop --lr_weights 0.1 \
    --num_trajs 1000 --seed 1 --lam1 5.0 --lam2 1.0 --sigma 1.0 --gamma 0.9 --max_iters 20 \
    --DATA experiment_coop_foraging/${data}_phase4a_correct_traj_nose_neck_rot_gz5_HD2_remove_state_rep
    for i in 6 7 8
    do
        python main_irl_foraging.py --GRID_SIZE 5 --TRAIN_NOW_IND 1 --SingleAgent 1 \
        --TAG_TRAIN 1 --INTERACTION $i --initialization 1 --early_stop --lr_weights 0.1 \
        --num_trajs 1000 --seed 1 --lam1 5.0 --lam2 1.0 --sigma 1.0 --gamma 0.9 --max_iters 20 \
        --DATA experiment_coop_foraging/${data}_phase4a_correct_traj_nose_neck_rot_gz5_HD2_remove_state_rep
        python main_irl_foraging.py --GRID_SIZE 5 --TRAIN_NOW_IND 1 --SingleAgent 2 \
        --TAG_TRAIN 1 --INTERACTION $i --initialization 1 --early_stop --lr_weights 0.1 \
        --num_trajs 1000 --seed 1 --lam1 5.0 --lam2 1.0 --sigma 1.0 --gamma 0.9 --max_iters 20 \
        --DATA experiment_coop_foraging/${data}_phase4a_correct_traj_nose_neck_rot_gz5_HD2_remove_state_rep
    done
done
