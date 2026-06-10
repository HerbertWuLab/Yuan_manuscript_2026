%% ============================================================
%   Function: count_zone_visits_and_dists
%   Purpose : 计算每个 trial 的访问次数 + 每次访问的最小距离
%              （不包含最后一个 reward zone 的访问）
% ============================================================
function [Num_visitZs, MinDist_eachVisit] = count_zone_visits_and_dists(table_in, rz_center, radius_cm)

    Num_visitZs = nan(height(table_in),1);
    MinDist_eachVisit = cell(height(table_in),1);  % 每个 trial 存一个 cell

    for i = 1:height(table_in)
        cur_m2_trial = table_in.m2_trials{i};
        m2_neck_x = cur_m2_trial.neck_x(cur_m2_trial.in_trial == 1);
        m2_neck_y = cur_m2_trial.neck_y(cur_m2_trial.in_trial == 1);
        pos = [m2_neck_x, m2_neck_y];
        nFrame = size(pos,1);
        if nFrame == 0, continue; end

        % ---- 计算与各 reward zone 的距离 ----
        dist_mat = zeros(nFrame, size(rz_center,1));
        for z = 1:size(rz_center,1)
            dist_mat(:,z) = sqrt((pos(:,1)-rz_center(z,1)).^2 + (pos(:,2)-rz_center(z,2)).^2);
        end

        % 每帧最近的 zone 编号 & 距离
        [min_dist, nearest_zone] = min(dist_mat, [], 2);

        % 是否在任意 zone 内
        in_any_zone = min_dist <= radius_cm;

        % 检测进入事件（从 0 → 1）
        enter_idx = find(diff([0; in_any_zone]) == 1);
        Num_visitZs(i) = numel(enter_idx);

        % ---- 计算每次访问的最小距离 ----
        visit_dists = [];
        for k = 1:numel(enter_idx)
            start_idx = enter_idx(k);
            if start_idx < nFrame
                end_idx = find(~in_any_zone(start_idx:end), 1, 'first');
                if isempty(end_idx)
                    end_idx = nFrame - start_idx + 1;
                end
                visit_frames = start_idx : (start_idx + end_idx - 1);

                % 如果是最后一次访问，且之后就trial结束，则跳过
                if k == numel(enter_idx) && visit_frames(end) >= nFrame - 1
                    continue;
                end

                % 找出访问所属 zone（多数帧属于同一 zone）
                z_mode = mode(nearest_zone(visit_frames));

                % 计算该访问期间的最小距离
                visit_dists(end+1,1) = min(dist_mat(visit_frames, z_mode));
            end
        end

        MinDist_eachVisit{i} = visit_dists;
    end
end
