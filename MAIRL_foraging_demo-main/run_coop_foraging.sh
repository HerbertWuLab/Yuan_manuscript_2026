# ------------------------------------------------
# Compare models of correct trials
# ------------------------------------------------
# @tesla, screen -r run
# for data in YC069 YC071 YC073 YC075 YC115 YC091 YC111
# for data in YC009YC010 YC011YC012 YC013YC014 YC015YC016 YC017YC018 YC021YC022 YC023YC024 YC025YC026 \
# YC027YC028 YC041YC042 YC043YC044 YC045YC046 YC047YC048 YC057YC058 YC103YC104 YC105YC106 YC127YC128
for data in YC070 YC072 YC074 YC076 YC116
# for data in YC069YC070 YC071YC072 YC073YC074 YC075YC076 YC115YC116
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



# -----------------------------------------------
# Recover maps for mismatch trials
# -----------------------------------------------
# for data in YC071 YC072 YC073 YC074 YC075 YC076
for data in YC071
do
    python process_coop_foraging_data.py --remove_rep --save_tag _remove_rep \
    --name ${data}_phase4d_correct_traj_neck_rot 
    python main_irl_foraging.py --GRID_SIZE 5 --TRAIN_NOW_IND 1 --SingleAgent 1 \
    --TAG_TRAIN 1 --INTERACTION 6 --initialization 1 --early_stop --lr_weights 0.1 \
    --num_trajs 1000 --seed 1 --lam1 5.0 --lam2 1.0 --sigma 1.0 --gamma 0.9 --max_iters 20 \
    --DATA experiment_coop_foraging/${data}_phase4d_correct_traj_neck_rot_gz5_remove_rep
    python main_irl_foraging.py --GRID_SIZE 5 --TRAIN_NOW_IND 1 --SingleAgent 2 \
    --TAG_TRAIN 1 --INTERACTION 6 --initialization 1 --early_stop --lr_weights 0.1 \
    --num_trajs 1000 --seed 1 --lam1 5.0 --lam2 1.0 --sigma 1.0 --gamma 0.9 --max_iters 20 \
    --DATA experiment_coop_foraging/${data}_phase4d_correct_traj_neck_rot_gz5_remove_rep
done

# -----------------------------------------------
# Recover maps for wrong trials
# -----------------------------------------------
# @ tesla, screen -r run2
for data in YC069YC070 YC070 YC071 YC072 YC073 YC074
do
    python process_coop_foraging_data.py --remove_rep --save_tag _remove_rep \
    --name ${data}_wrong_traj_neck_rot 
    python main_irl_foraging.py --GRID_SIZE 5 --TRAIN_NOW_IND 1 --SingleAgent 1 \
    --TAG_TRAIN 1 --INTERACTION 6 --initialization 1 --early_stop --lr_weights 0.1 \
    --num_trajs 1000 --seed 1 --lam1 5.0 --lam2 1.0 --sigma 1.0 --gamma 0.9 --max_iters 20 \
    --DATA experiment_coop_foraging/${data}_wrong_traj_neck_rot_gz5_remove_rep
    python main_irl_foraging.py --GRID_SIZE 5 --TRAIN_NOW_IND 1 --SingleAgent 2 \
    --TAG_TRAIN 1 --INTERACTION 6 --initialization 1 --early_stop --lr_weights 0.1 \
    --num_trajs 1000 --seed 1 --lam1 5.0 --lam2 1.0 --sigma 1.0 --gamma 0.9 --max_iters 20 \
    --DATA experiment_coop_foraging/${data}_wrong_traj_neck_rot_gz5_remove_rep
done



# ----------------------------------------------
# To process neural activity on a daily basis
# ----------------------------------------------
# YC069
for date in 20240601 20240602 20240604 20240605 20240606 20240607 20240609 20240610
do
    python process_coop_foraging_data.py --remove_rep --save_tag _remove_rep \
    --name YC069YC070_${date}_traj_neck_rot 
    python main_irl_foraging.py --GRID_SIZE 5 --TRAIN_NOW_IND 1 --SingleAgent 1 \
    --TAG_TRAIN 1 --INTERACTION 6 --initialization 1 --early_stop --lr_weights 0.1 \
    --num_trajs 1000 --seed 1 --lam1 5.0 --lam2 1.0 --sigma 1.0 --gamma 0.9 --max_iters 20 \
    --DATA experiment_coop_foraging/YC069YC070_${date}_traj_neck_rot_gz5_remove_rep
    python analyze_neural_value.py --pca --lr --shuffle_frame --date ${date} --animal YC069
done
# YC070
for date in 20240521 20240522 20240523 20240524 20240525 20240526 20240527 20240528 20240529 20240530 20240531
do
    python process_coop_foraging_data.py --remove_rep --save_tag _remove_rep \
    --name YC070_${date}_traj_neck_rot 
    python main_irl_foraging.py --GRID_SIZE 5 --TRAIN_NOW_IND 1 --SingleAgent 2 \
    --TAG_TRAIN 1 --INTERACTION 6 --initialization 1 --early_stop --lr_weights 0.1 \
    --num_trajs 1000 --seed 1 --lam1 5.0 --lam2 1.0 --sigma 1.0 --gamma 0.9 --max_iters 20 \
    --DATA experiment_coop_foraging/YC070_${date}_traj_neck_rot_gz5_remove_rep
    python analyze_neural_value.py --pca --lr --shuffle_frame --date ${date} --animal YC070
done
# YC071
for date in 20240809 20240807 20240805 20240803 20240802 20240729 20240727
do
    python process_coop_foraging_data.py --remove_rep --save_tag _remove_rep \
    --name YC071_${date}_traj_neck_rot 
    python main_irl_foraging.py --GRID_SIZE 5 --TRAIN_NOW_IND 1 --SingleAgent 1 \
    --TAG_TRAIN 1 --INTERACTION 6 --initialization 1 --early_stop --lr_weights 0.1 \
    --num_trajs 1000 --seed 1 --lam1 5.0 --lam2 1.0 --sigma 1.0 --gamma 0.9 --max_iters 20 \
    --DATA experiment_coop_foraging/YC071_${date}_traj_neck_rot_gz5_remove_rep
    python analyze_neural_value.py --pca --lr --shuffle_frame --date ${date} --animal YC071
done
# YC072
for date in 20240728 20240731 20240804 20240806 20240808
do
    python process_coop_foraging_data.py --remove_rep --save_tag _remove_rep \
    --name YC072_${date}_traj_neck_rot 
    python main_irl_foraging.py --GRID_SIZE 5 --TRAIN_NOW_IND 1 --SingleAgent 2 \
    --TAG_TRAIN 1 --INTERACTION 6 --initialization 1 --early_stop --lr_weights 0.1 \
    --num_trajs 1000 --seed 1 --lam1 5.0 --lam2 1.0 --sigma 1.0 --gamma 0.9 --max_iters 20 \
    --DATA experiment_coop_foraging/YC072_${date}_traj_neck_rot_gz5_remove_rep
    python analyze_neural_value.py --pca --lr --shuffle_frame --date ${date} --animal YC072
done
# YC073
for date in 20240727 20240729 20240801 20240802 20240803 20240805 20240807
do
    python process_coop_foraging_data.py --remove_rep --save_tag _remove_rep \
    --name YC073_${date}_traj_neck_rot 
    python main_irl_foraging.py --GRID_SIZE 5 --TRAIN_NOW_IND 1 --SingleAgent 1 \
    --TAG_TRAIN 1 --INTERACTION 6 --initialization 1 --early_stop --lr_weights 0.1 \
    --num_trajs 1000 --seed 1 --lam1 5.0 --lam2 1.0 --sigma 1.0 --gamma 0.9 --max_iters 20 \
    --DATA experiment_coop_foraging/YC073_${date}_traj_neck_rot_gz5_remove_rep
    python analyze_neural_value.py --pca --lr --shuffle_frame --date ${date} --animal YC073
done
# YC074
for date in 20240808 20240804 20240806 20240731 20240728
do
    python process_coop_foraging_data.py --remove_rep --save_tag _remove_rep \
    --name YC074_${date}_traj_neck_rot 
    python main_irl_foraging.py --GRID_SIZE 5 --TRAIN_NOW_IND 1 --SingleAgent 2 \
    --TAG_TRAIN 1 --INTERACTION 6 --initialization 1 --early_stop --lr_weights 0.1 \
    --num_trajs 1000 --seed 1 --lam1 5.0 --lam2 1.0 --sigma 1.0 --gamma 0.9 --max_iters 20 \
    --DATA experiment_coop_foraging/YC074_${date}_traj_neck_rot_gz5_remove_rep
    python analyze_neural_value.py --pca --lr --shuffle_frame --date ${date} --animal YC074
done

