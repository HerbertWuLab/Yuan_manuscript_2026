function [T_long,rtable] = get_bytrial_response(stable_sel,ftable,rtable,spk,params)

binCenters = [-32.5000  -27.5000  -22.5000  -17.5000  -12.5000   -7.5000 ...
    -2.5000    2.5000    7.5000   12.5000   17.5000   22.5000   27.5000   32.5000];
self_id = params.id;
m = str2double(self_id(2));
other_id = ['m' num2str(3-m)];
pos = ftable.([other_id '_neck_ego']);

P.Plot = true;
P.MaxPlotTrials = 0;

which_frames = params.which_frames;
[frames_idxn, stable_sel] = get_frames_idx(which_frames,stable_sel,ftable,params);

stable_sel = stable_sel(~isnan(stable_sel.([self_id '_last_arr'])),:);

% Basic sizes
n_trials = height(stable_sel);
n_cells  = size(spk,1);

% select neurons based on RF
% rf_filter = 'front_prox';
% rf_filter = 'other';
% rf_filter = params.rf_filter;
% switch rf_filter
%     case 'front_prox'
%         sel_neuron = rtable.dist <= 10 & (rtable.angle > -90 & rtable.angle <90);
%     case 'other'
%         sel_neuron = ~(rtable.dist <= 10 & (rtable.angle > -90 & rtable.angle <90));
% end
sig = cellfun(@(m)~isempty(m), rtable.rf);
used_neurons = find(sig);

n_used = numel(used_neurons);

% Prepare bin edges from centers
binCenters = binCenters(:)';           % row vector
if numel(binCenters) < 2
    error('binCenters must have at least 2 values.');
end
d = median(diff(binCenters));
edges = [binCenters(1)-d/2, binCenters(1:end-1)+d/2, binCenters(end)+d/2];
n_bins = numel(binCenters);

% Map positions to bin indices once for all frames
x = pos(:,1);
y = pos(:,2);
[~, ~, binX] = histcounts(x, edges);
[~, ~, binY] = histcounts(y, edges);
valid_bins = binX>0 & binX<=n_bins & binY>0 & binY<=n_bins;

% Output matrix
resp_mat = nan(n_used, n_trials);

% Iterate neurons
for ui = 1:n_used
% for ui = 3
    n = used_neurons(ui);
    mask = rtable.rf{n};
    if ~isequal(size(mask), [n_bins, n_bins])
        error('rtable.mask{%d} size %s does not match n_bins %d.', n, mat2str(size(mask)), n_bins);
    end

    if mean(mask(:)) > 0.5 % If RF occupies more than half of the field, skip
        resp_mat(ui,:) = NaN;
        continue
    end

    % Iterate trials
    n_plotted = 0;
    for t = 1:n_trials
    % for t = 1:3
        frames = stable_sel.windows{t};             % vector of frame indices for this trial
        frames = frames(:);
        valid_t = frames(valid_bins(frames));       % keep only frames that map to in-range bins

        if isempty(valid_t)
            % no valid bin mapping for this trial
            resp_mat(ui, t) = NaN;
            if P.Plot && n_plotted < P.MaxPlotTrials
                plot_trial_debug(t, [], [], [], [], [], [], [], [], ...
                    'No valid bin mapping for this trial.');
                n_plotted = n_plotted + 1;
            end
            continue
        end

        bx = binX(valid_t);
        by = binY(valid_t);

        % in-RF frames = frames whose (row, col) is true in mask
        lin = sub2ind(size(mask), by, bx);  % note: row = y -> index 1, col = x -> index 2
        inRF = mask(lin);

        frames_inRF = valid_t(inRF);
        
        if isempty(frames_inRF) % if traj does not cross RF
            resp_mat(ui, t) = NaN;
        else
            % mean response during RF occupancy
            resp_mat(ui, t) = mean(spk(n, frames_inRF), 'omitnan');
        end

        % Visualization for this trial
        if P.Plot && n_plotted < P.MaxPlotTrials
            % Build a simple image for RF mask and overlay trajectory
            x_traj = x(frames); y_traj = y(frames);
            x_in   = x(frames_inRF); y_in = y(frames_inRF);
    
            % Trial time series for the neuron
            tr_resp = spk(n, frames);
    
            % Boolean vector of in-RF along trial frames (length = numel(frames))
            inRF_trial = false(size(frames));
            if ~isempty(frames_inRF)
                inRF_trial(ismember(frames, frames_inRF)) = true;
            end
    
            % Find peak location of mask for a reference marker (optional)
            % This just finds the centroid of RF mask (unweighted)
            [yy, xx] = find(mask);
            cx = mean(binCenters(xx), 'omitnan');
            cy = mean(binCenters(yy), 'omitnan');
    
            plot_trial_debug(t, binCenters, mask, x_traj, y_traj, x_in, y_in, tr_resp, inRF_trial, ...
                sprintf('Neuron %d (row %d), trial %d — mean in-RF = %s', n, ui, t, num2str(resp_mat(ui,t))), ...
                [cx, cy]);
    
            n_plotted = n_plotted + 1;
        end
    end
end

%% get the per neuron ranking

% Inputs:
%   resp_mat  % [n_used_neurons x n_trials]
% Output:
%   pct       % same size, percentile ranks 0..100 (NaN where resp_mat is NaN)

[n_cells_used, n_trials] = size(resp_mat);
pct = nan(size(resp_mat));

for i = 1:n_cells_used
    r = resp_mat(i, :);
    valid = ~isnan(r);

    if any(valid)
        rv = r(valid);

        % Average ranks for ties
        % tiedrank returns ranks starting at 1
        rk = tiedrank(rv);

        if numel(rv) == 1
            % Only one valid trial
            pct(i, valid) = 100;
        else
            % Scale ranks to 0..100
            pct(i, valid) = 100 * (rk - 1) / (numel(rv) - 1);
        end
    end
end

% build table for comparing lead/follow and match/mismatch

% --- Build per-trial table ---
T = table((1:n_trials)', 'VariableNames', {'trial'});

% Add one column per neuron percentile
for i = 1:n_cells_used
    varname = sprintf('pct_n%03d', used_neurons(i));   % label by original neuron index
    T.(varname) = pct(i, :)';
end

% --- Role column: leader or follower for the recorded mouse ---
% stable_sel.leader is 1 or 2. Compare to mouse_id (1 or 2).
T.lead = stable_sel.leader == m;
T.follow = stable_sel.leader == 3-m;

% --- Outcome columns from stable_sel ---
% Assumes stable_sel.correct and stable_sel.mismatch are logical or 0/1.
T.correct  = stable_sel.correct;
T.mismatch = stable_sel.mismatch;

% --- Identify neuron columns
neuron_vars = startsWith(T.Properties.VariableNames, 'pct_');
neuron_names = T.Properties.VariableNames(neuron_vars);

% --- Stack into long format
n_neurons = numel(neuron_names);

all_resp   = [];
all_lead   = [];
all_follow = [];
all_correct = [];
all_mismatch = [];
all_dist = [];
all_angle = [];

for i = 1:n_neurons
    this_resp = T.(neuron_names{i});   % [n_trials x 1]
    all_resp   = [all_resp; this_resp];
    all_lead   = [all_lead; T.lead];       % repeat role per trial
    all_follow   = [all_follow; T.follow];  
    all_correct = [all_correct; T.correct]; % repeat correct per trial
    all_mismatch = [all_mismatch; T.mismatch]; % repeat mismatch per trial

    % get the RF information
    n = used_neurons(i);
    dist = rtable.dist(n);
    all_dist = [all_dist; dist*ones(n_trials,1)];

    angle = rtable.angle(n);
    all_angle = [all_angle; angle*ones(n_trials,1)];
end

% --- Build new table
T_long = table(all_resp, all_lead, all_follow, all_correct, all_mismatch,all_dist,all_angle,...
               'VariableNames', {'response','lead','follow','correct','mismatch','dist','angle'});

% Inspect
head(T_long)

%% --- Compute per-neuron ratios and append to rtable ---

n_neurons = numel(used_neurons);
LF_ratio = nan(n_neurons,1);
CM_ratio = nan(n_neurons,1);

for i = 1:n_neurons
    n = used_neurons(i);

    % pull this neuron's responses across trials
    varname = sprintf('pct_n%03d', n);
    resp = T.(varname);

    % --- Lead vs Follow ---
    r_lead   = mean(resp(T.lead==1), 'omitnan');
    r_follow = mean(resp(T.follow==1), 'omitnan');
    LF_ratio(i) = r_lead / r_follow;

    % --- Correct vs Mismatch ---
    r_correct  = mean(resp(T.correct==1), 'omitnan');
    r_mismatch = mean(resp(T.mismatch==1), 'omitnan');
    CM_ratio(i) = r_correct / r_mismatch;
end

% Append to rtable (matching used_neurons rows only)
rtable.LF_ratio = nan(height(rtable),1);
rtable.CM_ratio = nan(height(rtable),1);

rtable.LF_ratio(used_neurons) = LF_ratio;
rtable.CM_ratio(used_neurons) = CM_ratio;


%
%% --- Calcium traces for one neuron across all trials, split into n columns ---
m_colors = [194, 165, 207; 90, 174, 97] / 255;
if strcmp(params.role,'leader')
    cur_color = m_colors(1,:);
elseif strcmp(params.role,'follower')
        cur_color = m_colors(2,:);
end

cell_to_plot = used_neurons(1);  % <-- choose neuron index
mask = rtable.rf{cell_to_plot};

% normalization over entire session
cell_full_resp = spk(cell_to_plot, :);
min_r = min(cell_full_resp, [], 'omitnan');
max_r = max(cell_full_resp, [], 'omitnan');

% time window (frames relative to arrival)
win = -60:0;

% number of columns and trials per column
n_cols = 12;
n_trials = height(stable_sel);
trials_per_col = ceil(n_trials / n_cols);

spacing = 1.1;  % vertical shift per trial

fig = figure('Color','w','Position',[100 100 792 600]);
tiledlayout(1, n_cols, 'TileSpacing','compact','Padding','compact');

for col = 1:n_cols
    trial_idx_start = (col-1)*trials_per_col + 1;
    trial_idx_end   = min(col*trials_per_col, n_trials);
    trials_to_plot  = trial_idx_start:trial_idx_end;

    nexttile; hold on;

    for i = 1:numel(trials_to_plot)
        t = trials_to_plot(i);
        arr_time = stable_sel.([self_id '_last_arr'])(t);
        frames = arr_time + win;
        valid = frames > 0 & frames <= size(spk,2);
        frames = frames(valid);
        t_rel = win(valid);

        % calcium trace normalized to session min/max
        tr = spk(cell_to_plot, frames);
        tr = (tr - min_r) / (max_r - min_r + eps);

        % partner position for these frames
        bx = binX(frames);
        by = binY(frames);
        valid_xy = bx > 0 & by > 0 & bx <= n_bins & by <= n_bins;
        bx = bx(valid_xy);
        by = by(valid_xy);
        t_rel = t_rel(valid_xy);
        tr = tr(valid_xy);

        lin = sub2ind(size(mask), by, bx);
        inRF = mask(lin);

        % vertical shift for stacking
        % yshift = (i-1) * spacing;
        yshift = i * spacing;

        % plot full trace in black
        plot(t_rel/30, tr + yshift, 'k', 'LineWidth', 1);

        % overlay red segments where partner is in RF
        if any(inRF)
            idx = find(inRF);
            brk = [0; find(diff(idx) > 1); numel(idx)];
            for b = 1:numel(brk)-1
                seg = idx(brk(b)+1:brk(b+1));
                plot(t_rel(seg)/30, tr(seg) + yshift, 'Color',cur_color, 'LineWidth', 1);
            end
        end
    end

    % aesthetics
    % xline(0,'--','Color',[0.6 0.6 0.6]);  % arrival reference
    % xlabel('Time from arrival (s)');
    if col == 1
        ylabel('Trial (stacked vertically)');
        xlabel('Time from arrival (s)')
    else
        set(gca,'YTickLabel',[]);
        xlabel([])
    end
    set(gca,'TickDir','out')
    set(gca,'FontSize',20)
    title(sprintf('#%d–%d', trial_idx_start, trial_idx_end));
    ylim([0, numel(trials_to_plot)*spacing+1]);
    xticks([-2 -1 0])
    % set(gca,'YDir','normal');
    % axis tight;
end
fd = params.fd;
sgtitle(sprintf('Neuron %d: Calcium traces across trials (green = partner in RF)', cell_to_plot),'FontSize',20);
hoy = char(datetime('now','Format','yyyyMMdd'));
set(fig,'PaperOrientation','landscape');
figname = [fd '/plots/' hoy '_single_trial_ca_traces_RF'];
print(fig,figname,'-dpdf');

%}

