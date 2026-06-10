% ------------------------ Setup instructions ------------------------
% Before running this script:
% 1) Set the MATLAB Current Folder to:
%    Code/Data_analysis_code
%    so that all required functions are on the MATLAB path.
%
% 2) Update the data directory below (fd) to the location of the
%    downloaded folder "Yuan_manuscript_demo" on your local machine.
%    Example:
%    fd = '.../Yuan_manuscript_demo/';
%
% -------------------------------------------------------------------
% fd = '/Users/yuan.cheng/Wulab Dropbox/Yuan/Yuan_manuscript_demo/'

fd = 'E:\Wulab Dropbox\Yuan\Yuan_manuscript_demo\';  % <-- modify this path
%% Correlation between leadership and initiatorship (Figure 1)
% cumulative proportion reaching training criterion
cumulative_curve_demo(fd); % figure 1b

% extract learning phase table
ctable = load([fd '/Data/ctable_light_combined.mat']).ctable;
ltable = extract_ltable_demo(ctable); 

% plot trial-by-trial performance: arrival times, leader, inititor, and outcome
stable = ctable.stable{34}; % example session: #52, YC011YC012, 20230522, phase4a
plt_performance_byTrial_v4(fd,stable); % Fig. 1c


% get the simple props insert
plt_init_prop_oneSession_v2(fd,stable); % Fig. 1c insert 1
plt_lead_prop_oneSession_v2(fd,stable); % Fig. 1c insert 2

% plot leader/initiator metrics on the single animal level
plt_leader_metrics_demo(fd,ltable); % Fig. 1d-f, Sup Fig. 1l-n

prob_leadership_init_condition_v1_demo; % Wrapper for Sup Fig.i,j ********
get_leadership_byAlignment_demo; % Wrapper for Sup Fig. 1k *********

% plot leader/initiator metrics on the btable level
% cohort plot and stats of all pairs. Fig. 1g-j, Sup Fig. 1o-r
plt_leader_metrics_cohort_demo(fd,ltable);

% plot stability of leadership proportion differences
plt_leader_stability_demo(fd,ctable); % fig. 1l

% do leaders initiate more trials? Division of roles
plt_lead_init_prop_demo(fd,ltable); % Fig. 1m, Sup Fig.2c,d

% plot correlation between ranking and leader/initiator props
plt_ranking_corr_demo(fd,ctable); % Fig. 1n

% plot correlation between days to criterion and leader disparity at criterion
plt_corr_d2c_ld_demo(ltable,fd); % Fig. 1k

% tube test result stability. 
plot_win_count_ind_v1; % Wrapper for Sup Fig. 3a,b.
plot_win_count_lead_foll_v1; % Wrapper for Sup Fig. 3c and d. 

% prop of dominant animals becoming leaders or initiators
plot_dominant_demo(fd); % Fig. 1o and Sup Fig. 3t,3u

original_pair = load([fd 'Data/original_pair.mat']).original_pair;
swapped_pair = load([fd 'Data/swapped_pair.mat']).swapped_pair;
plt_leader_swap_demo(fd,original_pair,swapped_pair) % fig. 1p and Sup Fig. 4a,b

% compare days to criterion between original pair and swapped pair
plt_swap_learning(fd); % Fig. 1q and Sup Fig. 4c,d

% same role pairing
note_table = load([fd 'Data/pairing_table.mat']).note_table; % Fig. 1r
fd_plots = [fd '\plots\'];
note_table = getTrueLeaderStats(note_table);
plot_samerole_pairing_demo(note_table, fd, 'all'); % Fig. 1r
plot_samerole_pairing_demo(note_table, fd, 'male'); % Sup Fig. 4f
plot_samerole_pairing_demo(note_table, fd, 'female');% Sup Fig. 4e
plot_whoBecomesNewLeader_demo(fd, note_table);% Sup Fig. 4j and k
summaryData = load(fullfile(fd,'Data/summaryData.mat')).summaryData;
plot_prop_dominant_switch_role_demo(summaryData, fd); % Sup Fig. 4i
plot_newrole_byRank_demo(summaryData, fd); % Sup Fig. 4g and h


%% this part used another ltable. 
ltable = load([fd '/Data/ltable.mat']).ltable;

plot_cpRate_mean(ltable,fd); %Sup Fig2.a right
plot_cpRate_initiate_mean(ltable, fd); % Sup Fig.2b right
plot_cprate_indiv(ltable, fd, 25); % Sup Fig.2a left
plot_cprate_indiv_initiation(ltable, fd, 25); % Sup Fig.2b left

%% Do Phase 2 and Phase 2b metrics predict social roles?（Supplementary Fig.2）
btable = load(fullfile(fd,'Data/Phase2_matrics/phase2_batch_table.mat')).btable;
p2_metrics = {"co_rate","m1_mean_spd","m1_95p_spd","m1_rt_co_med","Trials2Criterion","total_corrects"};
plot_p2_p4(btable, p2_metrics,fd);  % Sup Fig.2 e,f,g

%% social hierarchy related（Supplementary Fig.3）
plot_hierarchy_leadership(fd, '/Data/social_hierarchy/Leadership–Hierarchy Correlation.xlsx');   % Supplementary fig.3 i,n,s
out = plot_dominance_consistency(fd);   % Supplementary fig.3 g
out = compare_sex_stability_reward(fd);   % Supplementary fig.3 f,k,p
[mean_time, sem_time, rank_time, figH] = plotWarmspotByRank(fd); % Supplementary fig. 3l
[mean_rank, sem_rank] = tubeRank_vs_rewardWinrate_v02(fd, [], true); % Supplementary fig. 3q
[ALL, Rtbl, Ptbl, r_pdf, p_pdf] = elo_rankings_and_correlations_cohort(fd); % Supplementary fig. 3 h,m,r

%% Behavior motif analysis. Fig 2b-f
% Load the syllable table
syllable_table = load(fullfile(fd, 'Data/syllable_table.mat')).syllable_table;
syllable_table = get_syllablebatch_info(syllable_table);
syllable_table = get_proportion_syllable(syllable_table);

make_gantt_plot_demo(fd,syllable_table); % Fig. 2b

motif_wrapper; % Wrapper for Sup Fig.6

% plot syllable_proportion by pairs
plot_syllable_proportions_pairs(syllable_table,fd); %fig.2d; Supplementary fig.7f,g

syllable_table=get_disp(syllable_table);
sex_sel = {'female','male','both'};
plot_corro_disp_syllable(syllable_table, fd, sex_sel); % Supplementary fig.7h-s

%% psychometric analysis of leader and follower. Fig. 2h-t

% fit responder choice using glm
fit_rspd_choice_demo(fd,ctable); % Fig. 2k-o. Sup Fig.8 e-n Wrapper

% fit all trials at all times
fit_all_choice_demo(fd,ctable); % Fig. 2q,r. Sup Fig.8 o-r Wrapper
fit_choice_by_trialtype_demo(fd, ctable); %Sup Fig.8st

%% below sections use old ctable

ctable = load([fd '\Data\ctable_light.mat']).ctable;
% fit initiator choice using glm
fit_init_choice_demo(fd,ctable); % Fig. 2f-i and Sup Fig. 8a-d. edit to make all figures


%% mPFC inactivation. Fig. 3
% inactivation in both roles
inact_ses_info_fname = fullfile(fd, 'Data/inact_sessions_info_20250317.xlsx'); 

% To analyze other inactivation conditions, replace this file with the appropriate session info file and rerun this section.
cno_table = extract_cno_table_demo(inact_ses_info_fname,ctable,'both','phase4a',5);
cno_table = get_cno_inact(cno_table);
features = {'cp_rate','lead_dsp','init_dsp','cp_rate_ledBy_sLead',...
    'cp_rate_ledBy_sFoll','lead_rt_mean','foll_rt_mean'};
plt_cno_inact_demo(fd,cno_table,features,'both'); % Fig. 3b-h

% inact_ses_info_fname = fullfile(fd, 'Data/inact_sessions_info_OFC.xlsx');

%========= Sup Fig. 10f& g======================================
ctable = load([fd '\Data\ctable.mat']).ctable;
ctable = recalc_leader_disp(ctable);
inact_ses_info_fname = fullfile(fd, 'Data/inact_sessions_info_20251130.xlsx');
cno_table = extract_cno_table_demo(inact_ses_info_fname,ctable,'both','phase4a',5);
cno_table = get_ctable_features(cno_table);  
cno_table = get_speed_v03(cno_table);        
cno_table = get_cno_inact(cno_table);
    
features = {'mm_rate','ur_rate',...
    'ses_trials','omission_rate','mean_inter_dis',...
    'p_initBy_sInit','p_initBy_sResp'...
    'lead_95p_spd','foll_95p_spd',...
    'lead_mean_spd','foll_mean_spd','lead_im_p','foll_im_p'}; % Sup Fig. 10f&g
subject = 'both';
sex = 'both';
plt_cno_inact_v2(fd,cno_table,features,subject,sex); % include sex

%===========Sup Fig. 10h====================================================
% feature_pair = {'foll_mean_spd_n','cp_rate_n'};
% feature_pair = {'foll_95p_spd_n','cp_rate_n'};
% feature_pair = {'lead_mean_spd_n','cp_rate_n'};
feature_pair = {'lead_95p_spd_n','cp_rate_n'};
subject = 'both';
idx_shift = 0; % corr feature1 on cno day vs feature 2 on cno day
% feature_pair = {'lead_dsp','cp_rate_n'};
% idx_shift = 1; % corr feature1 on before day vs feature 2 on cno day
corr_cno_inact(fd,cno_table,feature_pair,subject,idx_shift);

%=========Sup Fig. 11b==============================    ====
inact_ses_info_fname = fullfile(fd, 'Data/inact_sessions_info_camkII.xlsx');
ctable = load([fd 'Data/ctable_light2_camkII.mat']).ctable;
cno_table = extract_cno_table_demo(inact_ses_info_fname,ctable,'both','phase4a',5);
cno_table = get_cno_inact(cno_table);
features = {'cp_rate','lead_dsp','mm_rate','ur_rate',...
    'lead_dsp', 'init_dsp'};
subject = 'both';
sex = 'both';
plt_cno_inact_camkii_v2(fd,cno_table,features,subject);
 %=========Sup Fig.11d =======================================
 inact_ses_info_fname = fullfile(fd, 'Data/inact_sessions_info_sham.xlsx');
 ctable = load([fd 'Data/ctable_light2_sham.mat']).ctable_light2;
 cno_table = extract_cno_table_demo(inact_ses_info_fname,ctable,'both','phase4a',5);
cno_table = get_cno_inact(cno_table);
features = {'cp_rate','lead_dsp','init_dsp','cp_rate_ledBy_sLead',...
    'cp_rate_ledBy_sFoll'};
% subject = 'both';
% sex = 'both';
plt_cno_inact_demo(fd,cno_table,features,'both');
%=====================================================================
% inactivation in leaders or followers
cno_table = extract_cno_table_demo(inact_ses_info_fname,ctable,{'m1','m2'},'phase4a',5);
cno_table = get_cno_inact(cno_table);
features = {'p_initBy_sInit','p_initBy_sResp','omission_rate'}; % Sup
plt_cno_inact_v2(fd,cno_table,features,'sLead','both'); % supfig11.e
plt_cno_inact_v2(fd,cno_table,features,'sFoll','both'); % supfig11.f
% features = {'cp_rate','lead_dsp','init_dsp'}; % main figure
plt_cno_inact_demo(fd,cno_table,features,'sLead'); % Fig. 3j-l
plt_cno_inact_demo(fd,cno_table,features,'sFoll'); % Fig. 3m-p

% fit cno inactivation with logistic model. inactivation in both, leader, or follower
fit_all_choice_cno_demo(fd,inact_ses_info_fname,ctable); % edit to make Fig. 3i,m,q
% % which_mouse = 'both'; % Fig. 3i
% % which_mouse = 'lead'; % Fig. 3m
% % which_mouse = 'foll'; % Fig. 3q

%% other inactivation results. 
% load ctable of CaMKII-Gi result and rerun last section for generating Sup Fig.11b
inact_ses_info_fname = fullfile(fd, 'Data/inact_sessions_info_camkII.xlsx');
ctable = load([fd 'Data/ctable_light2_camkII.mat']).ctable;

% load ctable of OFC inactivation result and resun last section for
% generating Sup Fig. 10e
inact_ses_info_fname = fullfile(fd, 'inact_sessions_info_OFC.xlsx');
ctable = load([fd 'Data\ctable_light2_OFC.mat']).ctable_light2;

% load ctable of sham inactivation result and resun last section for
% generating Sup Fig. 11d 
inact_ses_info_fname = fullfile(fd, 'inact_sessions_info_sham.xlsx');
ctable = load([fd 'Data/ctable_light2_sham.mat']).ctable_light2;

%% optogenetic inactivation experiment
opto_table = load([fd 'Data/ctable_opto.mat']).opto_table;
plt_opto_inact_demo(fd,opto_table,{'cp_rate','lead_dsp','init_dsp'},'both','inter_trial'); % Fig. 3s-u
plt_opto_inact_demo(fd,opto_table,{'cp_rate'},'both','init_2s'); % Fig. 3w
plt_opto_inact_demo(fd,opto_table,{'cp_rate'},'both','init_1s'); % Fig. 3w
plt_opto_inact_demo(fd,opto_table,{'cp_rate'},'leader','inter_trial'); % Fig. 3x
plt_opto_inact_demo(fd,opto_table,{'cp_rate'},'follower','inter_trial'); % Fig. 3x

% logistic fit
fit_choice_opto_demo(fd, opto_table,'both','inter_trial'); % Fig. 3v

%%  Trajectory replay experiment (Fig.3 & Supplementary fig.12)
ctable = load(fullfile(fd,'Data/trajectory_replay/ctable.mat')).ctable;

% -------- Supplementary Fig. 12f --------
ltable = extract_ltable_op(ctable);
plt_learning_curve_op_all(ltable,fd);  

% -------- Load pooled trajectory table --------
pool_table = load(fullfile(fd,...
    'Data/trajectory_replay/trajectory_pool/stable.mat')).stable;

% -------- Criterion sessions --------
criterion_table = ltable(ltable.at_crit > 0, :);
fprintf('comparision_OP_SF_matrics: %d criterion sessions\n', ...
    height(criterion_table));

% -------- Figure 3z; Supplementary Fig.12f (middle) --------
compare_correct_rate(criterion_table, pool_table, fd);

% -------- Figure 3aa --------
plt_pledBy_mouseVSdot(criterion_table,fd);

% -------- Figure 3ab; 3ac; 3ad --------
comparision_OP_SF_cohort(ltable,fd);

% -------- Supplementary Fig. 12f (right); Supplementary Fig. 12h (right) --------
metrics = {'cp_rate','rt'};
plot_ledBy_dot_vs_mouse(criterion_table, 10, metrics, fd);

% -------- Supplementary Fig.12h (left and middle) --------
plt_dist_rt_Traj_SF(criterion_table,fd);

% -------- Supplementary Fig. 12f (right); Supplementary Fig. 12g --------
metrics = {'cp_rate','p_ledBy_m1','p_ledBy_m2'};
plot_leader_trace_vs_follower_trace(...
    criterion_table, metrics, fd);

%%  mPFC inactivation in trajectory replay task (Fig.3 & Supplementary fig.12)
inact_ses_info_fname = fullfile(fd, ...
    'Data/trajectory_replay/inact_sessions_info_updated_01102026.xlsx');

which_mouse = {'m2'};
which_phase = {'phase4a'}; % phase4a or phase4b
which_dose  = 5;

cno_table = extract_cno_table_op(...
    fd, inact_ses_info_fname, ctable, ...
    which_mouse, which_phase, which_dose);

subject  = 'm2';
features = {'cp_rate','p_ledBy_m1','m2_95p_spd','m2_mean_spd'};

% -------- mPFC inactivation plots --------
plt_cno_inact_op_v2(fd,cno_table,features,subject); % Fig.3ae,af; Sup Fig.12 i

%% choice and leadership representation in the mPFC. Fig. 4
plt_example_choice_neuron_demo(fd); % Fig. 4a

plt_choice_SI_demo(fd); % Fig. 4b

decode_choice_demo(fd); % Fig. 4c

plt_example_leader_neuron_demo(fd); % Fig. 4d-g

plt_SI_over_time_demo(fd); % Fig. 4h-i

plt_zone_choice_demo(fd); % Fig. 4j

plt_port_choice_demo(fd); % Fig. 4k

plt_spd_control_demo(fd); % Sup Fig. 13c

plt_pos_control_demo(fd); % Sup Fig. 13d

plt_reward_mod_demo(fd); % Sup Fig. 13e

plt_leader_SI_demo(fd); % Fig. 4l

decode_leader_demo(fd); % Fig. 4m

%% Social value representation of partner position (Fig. 5)
% This section computes the social value representation of the partner's position.
% It requires LIBLINEAR to be installed and added to the MATLAB path.
% For installation instructions, please refer to the official LIBLINEAR website:
% https://www.csie.ntu.edu.tw/~cjlin/liblinear/

plt_example_position_neuron_demo(fd); % plot example neuron, Fig. 5a-d

% Prop selective across spatial reference frames. Fig. 5e
prop_table = load([fd 'Data/prop_table_phase4a.mat']).prop_table;
params.fd = fd; params.phase = '4a';
plt_prop_spatial_selectivity_med(prop_table,params);


decode_position_demo(fd); % Fig. 5h-k, Sup Fig. 6a,b 

plt_position_tuning_demo(fd); % Fig. 5p,q,s,t

plt_prop_freerun_vs_4a_demo(fd); % Fig. 5r

% (review only) This demo function is provided for code review only.
trial_rf_response_v02_demo; % Fig.5t–y and Sup Fig.15e (didn't see sup fig15e)