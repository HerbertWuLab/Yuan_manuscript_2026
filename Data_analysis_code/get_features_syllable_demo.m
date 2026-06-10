function stable = get_features_syllable(stable)
post_bf = 30;
n_trials = height(stable);
for trial=1:n_trials
% for trial = 1   
    for a = 1:2
    % a = 1;
        % disp(['Processing Mouse #' num2str(a) ' Trial #' num2str(trial)]) 
        avar = ['m' num2str(a)]; % m1 or m2
        avar_other = ['m' num2str(3-a)]; % m1 or m2
        trials = stable.([avar '_trials']);
        trials_other = stable.([avar_other '_trials']);  

        cur_trial = trials{trial};
        cur_trial_other = trials_other{trial};
        if isempty(cur_trial) || isempty(cur_trial_other)
            continue
        end
        n_frames = height(cur_trial); % = pre-buffer + trial frames + post-buffer
        % calculate every frame, 
        % but the last few frames will be incorrect due to the use of diff multiple times
        for i = 1:(n_frames-post_bf+20) % add a 15-frame buffer

                        %%%%%%%%%%%% WITHIN ANIMAL CALCULATIONS %%%%%%%%%%%%
            % nkt at current frame
            t1 = [cur_trial.torso_x(i), cur_trial.torso_y(i)];
            k1 = [cur_trial.neck_x(i), cur_trial.neck_y(i)]; % k is necK!
            n1 = [cur_trial.nose_x(i), cur_trial.nose_y(i)]; % n is nose
            
            % nkt at next frame
            t2 = [cur_trial.torso_x(i+1), cur_trial.torso_y(i+1)];
            k2 = [cur_trial.neck_x(i+1), cur_trial.neck_y(i+1)];
            n2 = [cur_trial.nose_x(i+1), cur_trial.nose_y(i+1)];

            % nose-neck-torso angles %
            % k2t_1 = t1 - k1; % neck to torso
            t2k_f1 = k1 - t1; % torso to neck
            k2n_f1 = n1 - k1; % neck to nose

            % signed angle, look left is positive
            nkt_angle1 = get_angle_v01(t2k_f1,k2n_f1); 

            % k2t_2 = t2 - k2; % neck to torso
            t2k_f2 = k2 - t2; % torso to neck
            k2n_f2 = n2 - k2; % neck to nose
            nkt_angle2 = get_angle_v01(t2k_f2,k2n_f2); 

            cur_trial.([avar '_nkt_A'])(i) = nkt_angle1; % current angle
            cur_trial.([avar '_nkt_Adelta'])(i) = nkt_angle2 - nkt_angle1;
            cur_trial.([avar '_nkt_Aspeed'])(i) = abs((nkt_angle2 - nkt_angle1) * 30);  

            % speed of each node
            cur_trial.([avar '_n_Spd'])(i) = 30*norm(n2 - n1);
            cur_trial.([avar '_k_Spd'])(i) = 30*norm(k2 - k1);
            cur_trial.([avar '_t_Spd'])(i) = 30*norm(t2 - t1);

            %%% neck to nose calculations %%%
            % get the neck to nose forward and lateral movements
            % forward movement is the velocity componenet in neck>nose direction
            % lateral movement is the perpendicular componenet
            [k2n_x,k2n_y] = get_movement_proj_v01(k1,n1,n1,n2);
            cur_trial.([avar '_k2n_FwdMov'])(i) = k2n_x;
            cur_trial.([avar '_k2n_FwdSpd'])(i) = abs(k2n_x * 30);
            cur_trial.([avar '_k2n_LatMov'])(i) = k2n_y;
            cur_trial.([avar '_k2n_LatSpd'])(i) = abs(k2n_y * 30);

            % get the neck to nose angle relative to horizon
            angle1=atan2d(k2n_f1(2),k2n_f1(1)); 
            angle2=atan2d(k2n_f2(2),k2n_f2(1));

            % get the current k2n angle in [0, 360)
            if angle1 < 0
                angle1_360  = angle1 + 360;
                cur_trial.([avar '_k2n_A'])(i) = angle1_360;
            else
                cur_trial.([avar '_k2n_A'])(i) = angle1;
            end
            
            % handle 180 degree crossing for neck to nose angle change
            theta = angle_diff(angle1,angle2,180);            
            cur_trial.([avar '_k2n_Adelta'])(i) = theta; % rotational angle
            cur_trial.([avar '_k2n_Aspd'])(i) = abs(theta * 30); % rotational speed

            %%% torso to neck calculations %%%
            % get the torso to neck forward and lateral movements
            [t2k_x,t2k_y] = get_movement_proj_v01(t1,k1,k1,k2);
            cur_trial.([avar '_t2k_FwdMov'])(i) = t2k_x;
            cur_trial.([avar '_t2k_FwdSpd'])(i) = abs(t2k_x * 30);
            cur_trial.([avar '_t2k_LatMov'])(i) = t2k_y;
            cur_trial.([avar '_t2k_LatSpd'])(i) = abs(t2k_y * 30);

             % get the torso to neck angle relative to horizon
            t2k_f1 = k1 - t1; 
            t2k_f2 = k2 - t2;

            angle1=atan2d(t2k_f1(2),t2k_f1(1)); 
            angle2=atan2d(t2k_f2(2),t2k_f2(1));

            % get the current angle in [0, 360)
            if angle1 < 0
                angle1_360  = angle1 + 360;
                cur_trial.([avar '_t2k_A'])(i) = angle1_360; % current torso to neck angle
            else
                cur_trial.([avar '_t2k_A'])(i) = angle1; % current torso to neck angle
            end

            % handle 180 degree crossing for neck to nose angle change
            theta = angle_diff(angle1,angle2,180);
            cur_trial.([avar '_t2k_Adelta'])(i) = theta; % torso to neck rotational angle
            cur_trial.([avar '_t2k_Aspd'])(i) = abs(theta * 30); % torso to neck rotational speed

            %%% pairwise distance between NKT %%%
            cur_trial.([avar '_kn_Dis'])(i) = norm(n1 - k1);
            cur_trial.([avar '_tk_Dis'])(i) = norm(k1 - t1);
            cur_trial.([avar '_tn_Dis'])(i) = norm(n1 - t1);

            %%%%%%%%%%%% BETWEEN ANIMAL CALCULATIONS %%%%%%%%%%%%
            n1_other = [cur_trial_other.nose_x(i), cur_trial_other.nose_y(i)];
            k1_other = [cur_trial_other.neck_x(i), cur_trial_other.neck_y(i)];
            t1_other = [cur_trial_other.torso_x(i), cur_trial_other.torso_y(i)];
            t2k_other_f1 = k1_other - t1_other;
            k2n_other_f1 = n1_other - k1_other;  

            % k2n and t2k angle difference between the two animals
            if a==1 % only need to calculate once
                cur_trial.dif_k2n_Aabs(i) = abs(get_angle_v01(k2n_other_f1,k2n_f1));
                cur_trial.dif_t2k_Aabs(i) = abs(get_angle_v01(t2k_other_f1,t2k_f1));
            end

            % distance from other's NKT to self's necK
            cur_trial.([avar '_k_ToOthers_n_Dis'])(i) = norm(n1_other - k1);
            cur_trial.([avar '_k_ToOthers_k_Dis'])(i) = norm(k1_other - k1);
            cur_trial.([avar '_k_ToOthers_t_Dis'])(i) = norm(t1_other - k1);

            % pairwise distance
            cur_trial.([avar '_n_ToOthers_n_Dis'])(i) = norm(n1_other - n1);
            cur_trial.([avar '_t_ToOthers_t_Dis'])(i) = norm(t1_other - t1);

            % bearing of other in self's reference frame
            t2other_f1 = k1_other - t1; % self torso to other's neck
            tmp_angle = get_angle_v01(t2k_f1,t2other_f1); % + if on the left
            cur_trial.([avar '_OtherBrg_tk_A'])(i) = tmp_angle;
            cur_trial.([avar '_OtherBrg_tk_Aabs'])(i) = abs(tmp_angle); 

            k2other_f1 = k1_other - k1; % self neck to other's neck
            tmp_angle = get_angle_v01(k2n_f1,k2other_f1); % + if on the left
            cur_trial.([avar '_OtherBrg_kn_A'])(i) = tmp_angle;
            cur_trial.([avar '_OtherBrg_kn_Aabs'])(i) = abs(tmp_angle);

            % other mouse within field of view
            cur_trial.([avar '_Other_inLeftMono'])(i) = tmp_angle>=20 & tmp_angle<=160;  
            cur_trial.([avar '_Other_inRightMono'])(i) = tmp_angle>=-160 & tmp_angle<=-20;  
            cur_trial.([avar '_Other_inBinoc'])(i) = tmp_angle>=-20 & tmp_angle<=20; 
            cur_trial.([avar '_Other_inSight'])(i) = abs(tmp_angle)<=160;    

            % approach and tangent of nose, neck and torso
            nodes = {'n','k','t'};
            for node = 1:3
                cnd = nodes{node};
                d1 = eval([cnd num2str(1)]);
                d2 = eval([cnd num2str(1) '_other']);
                m1 = d1;
                m2 = eval([cnd num2str(2)]);
                % approach is the velocity componenet on the m1>m2 direction
                % tangent is the componenet perpendicular to approach
                [approach,tangent] = get_movement_proj_v01(d1,d2,m1,m2);
                move_distance = norm([approach,tangent]);
                cur_trial.([avar '_TwdOther_' cnd '_AprchMov'])(i) = approach;
                cur_trial.([avar '_TwdOther_' cnd '_TanMov'])(i) = tangent;
                cur_trial.([avar '_TwdOther_' cnd '_AprchSpd'])(i) = abs(approach * 30);
                cur_trial.([avar '_TwdOther_' cnd '_TanSpd'])(i) = abs(tangent * 30);   
                cur_trial.([avar '_TwdOther_' cnd '_AprchRatio'])(i) = abs(approach/move_distance);
                cur_trial.([avar '_TwdOther_' cnd '_TanRatio'])(i) = abs(tangent/move_distance);
            end

        end % end frames loop

        %%% ACCELERATIONS /  SPEEDS  this is done after filling the current trial table
        % forward and lateral movement of self
        cur_trial.([avar '_t2k_FwdAcc']) = [30*diff(30*cur_trial.([avar '_t2k_FwdMov'])); 0];
        cur_trial.([avar '_t2k_LatAcc']) = [30*diff(30*cur_trial.([avar '_t2k_LatMov'])); 0];
        cur_trial.([avar '_k2n_FwdAcc']) = [30*diff(30*cur_trial.([avar '_k2n_FwdMov'])); 0];
        cur_trial.([avar '_k2n_LatAcc']) = [30*diff(30*cur_trial.([avar '_k2n_LatMov'])); 0];
        cur_trial.([avar '_k2n_Aacc']) = [30*diff(30*cur_trial.([avar '_k2n_Adelta'])); 0];
        cur_trial.([avar '_t2k_Aacc']) = [30*diff(30*cur_trial.([avar '_t2k_Adelta'])); 0];
        
        % movement, speed and acceleration towards other
        cur_trial.([avar '_k_ToOthers_n_Mov']) = [diff(cur_trial.([avar '_k_ToOthers_n_Dis'])); 0];
        cur_trial.([avar '_k_ToOthers_n_Spd']) = 30*abs(cur_trial.([avar '_k_ToOthers_n_Mov']));
        cur_trial.([avar '_k_ToOthers_n_Acc']) = [30*diff(30*cur_trial.([avar '_k_ToOthers_n_Mov'])); 0];

        cur_trial.([avar '_k_ToOthers_k_Mov']) = [diff(cur_trial.([avar '_k_ToOthers_k_Dis'])); 0];
        cur_trial.([avar '_k_ToOthers_k_Spd']) = 30*abs(cur_trial.([avar '_k_ToOthers_k_Mov']));
        cur_trial.([avar '_k_ToOthers_k_Acc']) = [30*diff(30*cur_trial.([avar '_k_ToOthers_k_Mov'])); 0];

        cur_trial.([avar '_k_ToOthers_t_Mov']) = [diff(cur_trial.([avar '_k_ToOthers_t_Dis'])); 0];
        cur_trial.([avar '_k_ToOthers_t_Spd']) = 30*abs(cur_trial.([avar '_k_ToOthers_t_Mov']));
        cur_trial.([avar '_k_ToOthers_t_Acc']) = [30*diff(30*cur_trial.([avar '_k_ToOthers_t_Mov'])); 0];

        cur_trial.([avar '_n_ToOthers_n_Mov']) = [diff(cur_trial.([avar '_n_ToOthers_n_Dis'])); 0];
        cur_trial.([avar '_n_ToOthers_n_Spd']) = 30*abs(cur_trial.([avar '_n_ToOthers_n_Mov']));
        cur_trial.([avar '_n_ToOthers_n_Acc']) = [30*diff(30*cur_trial.([avar '_n_ToOthers_n_Mov'])); 0];

        cur_trial.([avar '_t_ToOthers_t_Mov']) = [diff(cur_trial.([avar '_t_ToOthers_t_Dis'])); 0];
        cur_trial.([avar '_t_ToOthers_t_Spd']) = 30*abs(cur_trial.([avar '_t_ToOthers_t_Mov']));
        cur_trial.([avar '_t_ToOthers_t_Acc']) = [30*diff(30*cur_trial.([avar '_t_ToOthers_t_Mov'])); 0];

        % angular delta and speed for other's bearing
        cur_trial.([avar '_OtherBrg_tk_Adelta']) = [diff(cur_trial.([avar '_OtherBrg_tk_A'])); 0];
        cur_trial.([avar '_OtherBrg_tk_Aspd']) = abs(30*cur_trial.([avar '_OtherBrg_tk_Adelta']));
        cur_trial.([avar '_OtherBrg_kn_Adelta']) = [diff(cur_trial.([avar '_OtherBrg_kn_A'])); 0];
        cur_trial.([avar '_OtherBrg_kn_Aspd']) = abs(30*cur_trial.([avar '_OtherBrg_kn_Adelta']));
        
        % approach and tangent movement towards other's nose, neck or torso
        nodes = {'n','k','t'};
        for node = 1:3
            cnd = nodes{node};
            cur_trial.([avar '_TwdOther_' cnd '_AprchAcc']) = [30*diff(30*cur_trial.([avar '_TwdOther_' cnd '_AprchMov'])); 0];
            cur_trial.([avar '_TwdOther_' cnd '_TanAcc']) = [30*diff(30*cur_trial.([avar '_TwdOther_' cnd '_TanMov'])); 0];
        end
        cur_trial.([avar '_n_Acc']) = [30*diff(30*cur_trial.([avar '_n_Spd'])); 0];
        cur_trial.([avar '_k_Acc']) = [30*diff(30*cur_trial.([avar '_k_Spd'])); 0];
        cur_trial.([avar '_t_Acc']) = [30*diff(30*cur_trial.([avar '_t_Spd'])); 0];

        stable.([avar '_trials']){trial} = cur_trial;
    end
end

