function btable = get_speed_v03(btable)
% calculate speed metrics
% tic;
n_ses = height(btable);
for s = 1:n_ses
    % btable.date{s}
    stable = btable.stable{s};
    n_trials = height(stable);
    k_spd = cell(3,1); % k for neck speed
    k_spd_short = cell(3,1); % for trials < 150 frames
    inter_dist = [];
    for i = 1:n_trials
        for m = 1:2
            avar = ['m' num2str(m)]; % m1 or m2
            neck_x_dif = [diff(stable.([avar '_trials']){i}.neck_x); NaN];
            neck_y_dif = [diff(stable.([avar '_trials']){i}.neck_y); NaN];
            in_trial_sel = stable.([avar '_trials']){i}.in_trial==1;
            f_no = stable.([avar '_trials']){i}.f_no;
            cur_k_spd = 30*vecnorm([neck_x_dif neck_y_dif],2,2);
            stable.([avar '_trials']){i}.n_spd = cur_k_spd;
            k_spd{m} = [k_spd{m};cur_k_spd(in_trial_sel)];
            if m==1 % get the frame no.
                k_spd{3} = [k_spd{3};f_no(in_trial_sel)];
            end
            if stable.dur_f(i) < 150 % only collect trials less than 150 frames
                k_spd_short{m} = [k_spd_short{m};cur_k_spd(in_trial_sel)];
                if m==1 % get the frame no.
                    k_spd_short{3} = [k_spd_short{3};f_no(in_trial_sel)];
                end
            end
        end
        % get inter-animal distance
        m1_pos = stable.m1_trials{i};
        m2_pos = stable.m2_trials{i};
        in_trial_sel = stable.m1_trials{i}.in_trial==1;
        cur_dist = vecnorm([m1_pos.neck_x-m2_pos.neck_x m1_pos.neck_y-m2_pos.neck_y],2,2);
        inter_dist = [inter_dist;cur_dist(in_trial_sel)];
    end
    btable.m1_k_spd{s} = k_spd{1};
    btable.m2_k_spd{s} = k_spd{2};
    btable.f_no{s} = k_spd{3};
    btable.m1_k_spd_s{s} = k_spd_short{1}; % neck speed in short trials
    btable.m2_k_spd_s{s} = k_spd_short{2};
    btable.f_no_s{s} = k_spd_short{3};
    btable.stable{s} = stable;
    % % temp = vertcat(stable.m1_trials{:});
    % % btable.f_no{s} = temp.f_no;
    % % btable.m1_n_spd{s} = temp.n_spd;
    % % temp = vertcat(stable.m2_trials{:});
    % % btable.m2_n_spd{s} = temp.n_spd;
    btable.m1_d_trl(s) = sum(btable.m1_k_spd{s},"omitnan")/3000; % in meter
    btable.m2_d_trl(s) = sum(btable.m2_k_spd{s},"omitnan")/3000;
    btable.m1_med_spd(s) = median(btable.m1_k_spd{s},"omitnan");
    btable.m2_med_spd(s) = median(btable.m2_k_spd{s},"omitnan");
    btable.m1_mean_spd(s) = mean(btable.m1_k_spd{s},"omitnan");
    btable.m2_mean_spd(s) = mean(btable.m2_k_spd{s},"omitnan");
    btable.m1_95p_spd(s) = prctile(btable.m1_k_spd{s},95);
    btable.m2_95p_spd(s) = prctile(btable.m2_k_spd{s},95);
    btable.m1_im_p(s) = mean(btable.m1_k_spd{s}<2,"omitnan");
    btable.m2_im_p(s) = mean(btable.m2_k_spd{s}<2,"omitnan");
    % only short trials
    btable.m1_d_trl_s(s) = sum(btable.m1_k_spd_s{s},"omitnan")/3000;
    btable.m2_d_trl_s(s) = sum(btable.m2_k_spd_s{s},"omitnan")/3000;
    btable.m1_med_spd_s(s) = median(btable.m1_k_spd_s{s},"omitnan");
    btable.m2_med_spd_s(s) = median(btable.m2_k_spd_s{s},"omitnan");
    btable.m1_mean_spd_s(s) = mean(btable.m1_k_spd_s{s},"omitnan");
    btable.m2_mean_spd_s(s) = mean(btable.m2_k_spd_s{s},"omitnan");
    btable.m1_95p_spd_s(s) = prctile(btable.m1_k_spd_s{s},95);
    btable.m2_95p_spd_s(s) = prctile(btable.m2_k_spd_s{s},95);
    btable.m1_im_p_s(s) = mean(btable.m1_k_spd_s{s}<2,"omitnan");
    btable.m2_im_p_s(s) = mean(btable.m2_k_spd_s{s}<2,"omitnan");
    % mean and median inter-animal distance
    btable.med_inter_dis(s) = median(inter_dist,"omitmissing");
    btable.mean_inter_dis(s) = mean(inter_dist,"omitmissing");
end
% elapsedTime = toc;
% disp(['Elapsed Time: ' num2str(elapsedTime) ' seconds']);

% get immobile proportions of the control sessions (speed < 2cm/s)
ctrl_m1_immob_props = btable.m1_im_p(btable.cno==0);
mean_ctrl_m1_immob_props = mean(ctrl_m1_immob_props);
std_ctrl_m1_immob_props = std(ctrl_m1_immob_props);
ctrl_m2_immob_props = btable.m2_im_p(btable.cno==0);
mean_ctrl_m2_immob_props = mean(ctrl_m2_immob_props);
std_ctrl_m2_immob_props = std(ctrl_m2_immob_props);
for s = 1:n_ses
    btable.m1_im_z(s) = (btable.m1_im_p(s)-mean_ctrl_m1_immob_props)/std_ctrl_m1_immob_props;
    btable.m2_im_z(s) = (btable.m2_im_p(s)-mean_ctrl_m2_immob_props)/std_ctrl_m2_immob_props;
    btable.m1_im_h(s) = abs(btable.m1_im_z(s)) > 2.58; % 99% confidence interval
    btable.m2_im_h(s) = abs(btable.m2_im_z(s)) > 2.58; % 99% confidence interval
end

% %% manually verify the maximum possible speed
% m1_max_spd = nan(n_ses,2);
% m2_max_spd = nan(n_ses,2);
% for s = 1:n_ses
%     [m1_max_spd(s,2),idx] = max(btable.m1_n_spd{s});
%     m1_max_spd(s,1) = btable.f_no{s}(idx);
%     [m2_max_spd(s,2),idx] = max(btable.m2_n_spd{s});
%     m2_max_spd(s,1) = btable.f_no{s}(idx);
% end
% s = 17;
% cur_ses = btable.m2_n_spd{s};
% [~,sort_idx] = sort(cur_ses,'descend');
% sorted_cur_ses = [btable.f_no{s}(sort_idx) btable.m2_n_spd{s}(sort_idx)];

%%% Check max neck speed %%%
% M1
% Session   frame	n_spd				real？
% 12		57563	79.7251840565653	real
% 13		51911	89.5417500505579	artifact
% 17		33977	84.2957001844973	real
% 19		44421	<91.4359479670459>	real
% 21		34917	90.8425698944663	real
% 43		58779	94.1304399283459	artifact
% 
% M2
% Session   frame	n_spd				real?
% 31		87390	99.8484544069235	artifact
% 41 		40659	95.6209270149046	artifact
% 34		66378	93.2479045547427	artifact
% 34		15543	80.2694402664340	real
% 17		9563	83.7974639714166	artifact
% 13		20884	<82.0791727382706>	real
%%%