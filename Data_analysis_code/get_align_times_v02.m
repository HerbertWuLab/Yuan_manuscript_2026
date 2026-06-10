function btable = get_align_times_v02(btable)
% calculate the alignment between neck-nose vector to the reward zone. 
% the idea is that the leader will orient toward the reward zone
% before the follower does
% v02: extend the neck > nose vector and check if it intersects with the
% reward zone line segment. see the video example for a very intutive demo
pre_bf = 30; % add buffer frames before init frame
post_bf = 30; % add buffer frames after end frame

% because sleap tracking is still not accurate. use arrival zone radius
% as the distance threshold: if a mouse is in the arrival zone, mouse is 
% considered aligned to the reward zone line segment, 
% even if the mouse is looking elsewhere
az_rds = 4; % in cm / 4cm default

% reward zone line segment half width in cm
rzl_hw = 6;  % 6cm default

n_ses = height(btable);
for s = 1:n_ses
% for s = 5
    landmks = btable.landmks{s};
    rzc = pix2cm_landmks([landmks.mt;landmks.mr;landmks.mb;landmks.ml],landmks); % reward zone centers    
    rzl_range = [rzc(1,1)-rzl_hw rzc(1,2) rzc(1,1)+rzl_hw rzc(1,2);
                  rzc(2,1) rzc(2,2)-rzl_hw rzc(2,1) rzc(2,2)+rzl_hw; 
                  rzc(3,1)-rzl_hw rzc(3,2) rzc(3,1)+rzl_hw rzc(3,2);
                  rzc(4,1) rzc(4,2)-rzl_hw rzc(4,1) rzc(4,2)+rzl_hw];  
    stable = btable.stable{s};
    n_trials = height(stable);
    stable.m1_align_f = nan(n_trials,1); % time of alignment
    stable.m2_align_f = nan(n_trials,1);
    stable.leader_align = nan(n_trials,1);
    for i = 1:n_trials
        m1_zone = stable.m1_zone(i);
        m2_zone = stable.m2_zone(i);
        cur_init_frame = stable.led_init(i);
        cur_end_frame = stable.led_end(i);
        flag = 0;    
        if stable.correct(i) == 1 % if match, m1_zone shoul equal to m2_zone
            if isnan(m1_zone) || isnan(m2_zone)
                fprintf('WARNING: Trial #%d is match, but m1 or m2 is not at the arrival zones!\n',i);
                disp('Double check this trial. This is most likely due to bad SLEAP data')
                flag = 1;
            elseif m1_zone ~= m2_zone
                fprintf('WARNING: Trial #%d is match, but m1 and m2 are at different zones!\n',i);
                disp('Double check this trial. This is most likely due to bad SLEAP data')
                flag = 1;
            end
        elseif stable.mismatch(i) == 1 % if mismatch, m1_port be different from m2_port
            if isnan(m1_zone) || isnan(m2_zone)
                fprintf('WARNING: Trial #%d is mismatch, but m1 or m2 is not at arrival zones!\n',i);
                disp('Double check this trial. This is most likely due to bad SLEAP data')
                flag = 1;
            elseif m1_zone == m2_zone
                fprintf('WARNING: Trial #%d is mismatch, but m1 and m2 are at the same zone!\n',i);
                disp('Double check this trial. This is most likely due to bad SLEAP data')
                flag = 1;
            end
        end
        % Find the alignment times and call leader2 
        if (flag==0) && (stable.correct(i) == 1 || stable.mismatch(i) == 1) % if correct or mismatch and no error in previous step
            for m=1:2
                mstr = ['m' num2str(m)];
                cur_zone = eval([mstr '_zone']);
                cur_rzc = rzc(cur_zone,:); % get reward zone center of m1
                cur_rz_range = rzl_range(cur_zone,:); % get reward zone line range of m1
                endpoints2 = [cur_rz_range(1:2);cur_rz_range(3:4)]; % re-arrange
                % cur_k_coords = [stable.([mstr '_trials']){i}.neck_x(pre_bf+1:end-post_bf), stable.([mstr '_trials']){i}.neck_y(pre_bf+1:end-post_bf)];
                % cur_n_coords = [stable.([mstr '_trials']){i}.nose_x(pre_bf+1:end-post_bf), stable.([mstr '_trials']){i}.nose_y(pre_bf+1:end-post_bf)];
                cur_k_coords = [stable.([mstr '_trials']){i}.neck_x, stable.([mstr '_trials']){i}.neck_y];
                cur_n_coords = [stable.([mstr '_trials']){i}.nose_x, stable.([mstr '_trials']){i}.nose_y];
                n_frames = size(cur_k_coords,1);
                cur_rz_proj = nan(n_frames,2);
                for f = 1:n_frames  
                    endpoints1 = [cur_n_coords(f,:);cur_k_coords(f,:)];
                    intersectionPoint = findIntersection(endpoints1, endpoints2);
                    if ~isempty(intersectionPoint)
                        cur_rz_proj(f,:) = intersectionPoint;
                    end
                end
                % HD becomes inaccurate when the mouse is too close to the
                % reward zone. only use HD when the mouse is at least some
                % distance away.
                cur_k2rzc_dis = vecnorm(cur_k_coords-cur_rzc,2,2);
                % save the distance and HD
                n_all_frames = length(stable.([mstr '_trials']){i}.nose_x);
                % stable.([mstr '_trials']){i}.k2rzc_dis = nan(n_all_frames,1);
                stable.([mstr '_trials']){i}.k2rzc_dis = cur_k2rzc_dis;
                % stable.([mstr '_trials']){i}.rz_proj = nan(n_all_frames,2);
                stable.([mstr '_trials']){i}.rz_proj = cur_rz_proj;
                cur_k2rzc_dis_intrial = cur_k2rzc_dis(pre_bf+1:end-post_bf);
                cur_rz_proj_intrial = cur_rz_proj(pre_bf+1:end-post_bf,:);

                % when mouse is in the arrival zone, which is smaller than
                % reward zone
                dis_filter = cur_k2rzc_dis_intrial < az_rds; 
                % replace zeros when there are less than 4 consecutive zeros, 
                % to handle sporadic frames of the neck outside reward zone due to SLEAP inaccuracies
                dis_filter = replaceZeros(dis_filter, 4); 
                % only check the proj when mouse is outside the reward zone
                lastEnterRewardZoneStart = find(diff([dis_filter; 0]) == 1, 1, 'last');
                cur_rz_proj_filtered = cur_rz_proj_intrial(:,1);
                cur_rz_proj_filtered(lastEnterRewardZoneStart:end) = [];
                n_frames_filtered = length(cur_rz_proj_filtered);
                cur_rz_proj_flip = flip(cur_rz_proj_filtered);
                idx = find(isnan(cur_rz_proj_flip),1,'first');
                if ~isempty(idx) 
                    if idx == 1 % no intersection until the last frame before entering reward zone
                        output = cur_init_frame + n_frames_filtered; % assume it is aligned because the mouse is very close
                    else % aligned at some point and maintain the alignment until trial end
                        cur_last_align_frame = n_frames_filtered - idx + 1;
                        output = cur_init_frame + cur_last_align_frame;
                    end
                else % always aligned
                    output = cur_init_frame;
                end
                stable.([mstr '_align_f'])(i) = output;
                stable.([mstr '_align_rt'])(i) = output - stable.led_init(i);
            end

            % call leader using alignment times
            if stable.m1_align_f(i)<stable.m2_align_f(i)
                stable.leader_align(i) = 1; % leader aligns earlier
            elseif stable.m1_align_f(i)>stable.m2_align_f(i)
                stable.leader_align(i) = 2; 
            else
                stable.leader_align(i) = NaN; % no leader can be called
            end
        end
    end % end trials loop
    btable.stable{s} = stable;
    % leaders can be called only in correct or mismatch trials
    sel = (stable.correct==1 | stable.mismatch==1) & ~isnan(stable.leader) & ~isnan(stable.leader_align); 
    sel_stable = stable(sel,:);
    btable.p_align_m1(s) = mean(sel_stable.leader_align==1); % prop trials in which m1 aligned first to rz
    btable.p_align_m2(s) = mean(sel_stable.leader_align==2); % prop trials in which m2 aligned first to rz
    % correct rate of trials when m1/m2 aligns with reward zone first
    btable.cp_rate_align_m1(s) = mean(sel_stable.correct(sel_stable.leader_align==1));
    btable.cp_rate_align_m2(s) = mean(sel_stable.correct(sel_stable.leader_align==2));
    % recaculate leader proportion after taking out NaNs
    btable.p_ledBy_m1(s) = mean(sel_stable.leader==1); % prop of trials led by m1
    btable.p_ledBy_m2(s) = mean(sel_stable.leader==2); % prop of trials led by m2
    
end % end sessions loop
btable.align_disparity = abs(btable.p_align_m1 - btable.p_align_m2);