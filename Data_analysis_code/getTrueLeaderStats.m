function note_table = getTrueLeaderStats(note_table)
%GETTRUELEADERSTATS
% Compute true leader statistics for each row in note_table.
% 
% For each pair:
%   - Select stable sessions based on role_type
%   - Aggregate stable trials
%   - Compute leader proportions
%   - Perform two-sided binomial test (p = 0.5)
%   - Write results back into note_table

for p = 1:height(note_table)

    ptable_all = note_table.ptable{p};

    % ---------------- Base selection ----------------
    s_range = ptable_all.cno == 0 & ...
              ptable_all.cp_rate >= 0.8 & ...
              strcmpi(ptable_all.phase, 'phase4a');

    idx = find(s_range);
    ptable = table();   % 防止沿用上一轮

    rt = string(note_table.role_type{p});

    % ============================================================
    %                   SELECT STABLE SEGMENT
    % ============================================================

    if rt == "original_pair"

        % ---- old logic ----
        ptable = ptable_all(s_range, :);

        if strcmp(note_table.pair{p}, 'TY001TY003')
            if height(ptable) >= 3
                ptable = ptable(2:3, :);
            else
                ptable = table();
            end
        end

        if height(ptable) == 0
            disp(['[orig: ptable empty] pair = ', note_table.pair{p}])
            continue
        end

    elseif rt == "LL_pairing" || rt == "FF_pairing"

        % ---- new logic: first consecutive segment >=3, take 3rd ----
        if numel(idx) < 3
            disp(['[swap: Total true <3] pair = ', note_table.pair{p}])
            continue
        end

        breaks = [true; diff(idx) ~= 1];
        group_id = cumsum(breaks);

        found = false;

        for g = unique(group_id)'   % 按连续段顺序
            g_idx = idx(group_id == g);
            if numel(g_idx) >= 3
                ptable = ptable_all(g_idx(3), :);  % 只取一行
                found = true;
                break
            end
        end

        if ~found
            disp(['[swap: No consecutive >=3] pair = ', note_table.pair{p}])
            continue
        end

    else
        disp(['[Unknown role_type] pair = ', note_table.pair{p}, ...
              ' role_type = ', char(rt)])
        continue
    end

    % ============================================================
    %                   AGGREGATE STABLE TRIALS
    % ============================================================

    stable = table();

    for s = 1:length(ptable.stable)
        sel_stable = ptable.stable{s};
        stable = [stable; sel_stable];
    end

    if height(stable) == 0
        continue
    end

    % ============================================================
    %                   TRUE LEADER STATISTICS
    % ============================================================

    n1 = sum(stable.leader == 1);
    n2 = sum(stable.leader == 2);
    total = n1 + n2;

    if total == 0
        continue
    end

    p_ledBy_m1 = n1 / total;
    p_ledBy_m2 = n2 / total;

    p_ledBy_sLead = max(p_ledBy_m1, p_ledBy_m2);
    p_ledBy_sFoll = min(p_ledBy_m1, p_ledBy_m2);

    % two-sided binomial test against 0.5
    P_val = 2 * binocdf(min(n1, n2), total, 0.5);
    P_val = min(P_val, 1);

    % ============================================================
    %                   WRITE BACK
    % ============================================================

    note_table.P_val(p)         = P_val;
    note_table.total_trials(p)  = total;
    note_table.p_ledBy_m1(p)    = p_ledBy_m1;
    note_table.p_ledBy_m2(p)    = p_ledBy_m2;
    note_table.p_ledBy_sLead(p) = p_ledBy_sLead;
    note_table.p_ledBy_sFoll(p) = p_ledBy_sFoll;

end

end
