function ltable = extract_ltable_op(ctable)
% extract_ltable_op
% Extract learning-phase data table for OP task using plateau criterion.
%
% Criterion (fixed):
%   - Sliding window: 3 days
%   - Stability: max(window) - min(window) <= 0.06
%   - Dynamic level: mean(window) >= max(0.60, prctile(cp_rate,90) - 0.10)
%
% Learning table includes sessions from day 1 up to day_crit (inclusive).
% at_crit coding (more informative than 0/1):
%   - 0 : not in criterion window
%   - 1 : criterion window day 1 (earliest of the 3)
%   - 2 : criterion window day 2
%   - 3 : criterion window day 3 (criterion day, i.e., day_crit)
%
% Post filter:
%   - remove sessions with cno==1
%
% Command window feedback:
%   - prints per-pair status + lists pairs that did NOT learn / too short

%% fixed parameters
win = 3;
max_delta = 0.06;   % within-window fluctuation (absolute proportion)
drop = 0.10;        % within 10% of peak
floor_abs = 0.60;   % absolute minimum performance level

%% init
uni_pairs = unique(ctable.pair);
ltable = [];

not_learned = {};
too_short = {};

fprintf('=== extract_ltable_op ===\n');
fprintf('Criterion: win=%d | range<=%.2f | mean>=max(%.2f, p90-%.2f)\n', ...
    win, max_delta, floor_abs, drop);

%% per-pair processing
for p = 1:numel(uni_pairs)
    cur_pair = uni_pairs{p};
    cur_ctable = ctable(strcmp(cur_pair, ctable.pair), :);

    if isempty(cur_ctable) || height(cur_ctable) < win
        fprintf('[%s] < %d sessions -> cannot evaluate criterion\n', cur_pair, win);
        too_short{end+1} = cur_pair; %#ok<AGROW>
        continue
    end

    % Day 1 warning (sanity check only; does NOT exclude)
    cp_rate_d1 = cur_ctable.cp_rate(1) * 100;
    if cp_rate_d1 >= 70
        fprintf('[%s] WARNING: %.1f%% correct on Day 1 (check training-phase contamination)\n', ...
            cur_pair, cp_rate_d1);
    end

    cp_rate = cur_ctable.cp_rate;

    % robust peak (90th percentile) and dynamic level threshold
    peak = prctile(cp_rate, 90);
    level_th = max(floor_abs, peak - drop);

    % find first day where trailing 3-day window is stable + high enough
    day_crit = [];
    crit_w_mean = NaN;
    crit_w_range = NaN;

    for t = win:numel(cp_rate)
        w = cp_rate(t-win+1:t);
        if any(isnan(w))
            continue
        end

        w_range = max(w) - min(w);
        w_mean  = mean(w);

        if (w_range <= max_delta) && (w_mean >= level_th)
            day_crit = t;
            crit_w_mean = w_mean;
            crit_w_range = w_range;
            break
        end
    end

    if isempty(day_crit)
        fprintf('[%s] NOT learned: no 3-day plateau (peak_p90=%.3f, level_th=%.3f)\n', ...
            cur_pair, peak, level_th);
        not_learned{end+1} = cur_pair; %#ok<AGROW>
        continue
    end

    fprintf('[%s] learned: day_crit=%d | peak_p90=%.3f | level_th=%.3f | window_mean=%.3f | window_range=%.3f\n', ...
        cur_pair, day_crit, peak, level_th, crit_w_mean, crit_w_range);

    % build learning table (day 1 .. day_crit)
    cur_ltable = cur_ctable(1:day_crit, :);
    cur_ltable.days = (1:day_crit)';

    % at_crit: 0 outside criterion window; 1/2/3 inside (3 is criterion day)
    cur_ltable.at_crit = zeros(height(cur_ltable), 1);
    cur_ltable.at_crit(end-win+1:end) = (1:win)';

    ltable = [ltable; cur_ltable];
end

%% summary (command window)
fprintf('=== Summary ===\n');
fprintf('Total pairs: %d\n', numel(uni_pairs));
fprintf('Learned pairs: %d\n', numel(uni_pairs) - numel(not_learned) - numel(too_short));
fprintf('Not learned pairs: %d\n', numel(not_learned));
fprintf('Too-short pairs (<%d sessions): %d\n', win, numel(too_short));

if ~isempty(not_learned)
    fprintf('Not learned list:\n');
    for i = 1:numel(not_learned)
        fprintf('  - %s\n', not_learned{i});
    end
end

if ~isempty(too_short)
    fprintf('Too-short list:\n');
    for i = 1:numel(too_short)
        fprintf('  - %s\n', too_short{i});
    end
end

%% formatting + post-filter (only cno)
if isempty(ltable)
    warning('extract_ltable_op: ltable is empty after criterion detection.');
    return
end

ltable = movevars(ltable, "at_crit", 'After', "phase");
ltable = movevars(ltable, "days", 'After', "phase");

fprintf('remove %d sessions with cno inactivation\n', sum(ltable.cno))
ltable = ltable(ltable.cno==0, :);

end
