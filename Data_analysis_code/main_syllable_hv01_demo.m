%% for plotting syllable metrics
% original file in /Users/herbert/Wulab Dropbox/Lab/Yuan/12_Syllable_labels/hand_labeling

%% 1. generate a master table for storing all of neccesory files.
% Define the folder and file paths
fd = '/Users/herbert/Wulab Dropbox/Lab/Yuan/12_Syllable_labels/hand_labeling/sessions_data_paper';
info_file = 'syllable_labeling_info_0320.xlsx';

% Call the combine_sessions function to get syllable_table
syllable_table = combine_sessions(fd, info_file);

% Define the 'cohort' folder path
cohort_folder = fullfile(fd, 'cohort');

% Check if 'cohort' folder exists, if not, create it
if ~exist(cohort_folder, 'dir')
    mkdir(cohort_folder);
end

% Define the file path to save the syllable_table
save_file = fullfile(cohort_folder, 'syllable_table.mat');

% Save the syllable_table as a .mat file using v7.3 format and compression
save(save_file, 'syllable_table', '-v7.3');  % Use '-v7.3' for large data files

disp(['syllable_table saved as: ', save_file]);

%% Herbert's code 
fd = '/Users/herbert/Wulab Dropbox/Lab/Yuan/12_Syllable_labels/hand_labeling/sesssion_data';
cd(fd)
filename = 'cohort/syllable_table.mat';

% Load the syllable table
syllable_table = load(fullfile(fd, filename)).syllable_table;
s = 4;
stable = syllable_table.stable{s};
syllable = syllable_table.syllabel{s};

% clear syllable_table
clear syllable_table
%%
T = syllable;
frameVar = T.Properties.VariableNames{1};           % e.g., 'OriginalFrameNumber'
drop = {frameVar,'IncludedInNewVideo','StitchedFrameNumber','m2_sync'};
% drop m2_sync because it is a duplicate of m1_sync. this prevents the duplication 
% of all the inter-animal metrics from being populated twice. however, in
% the later neck speed plots, only the m1 neck speed is plotted.

syllCols = setdiff(T.Properties.VariableNames, drop);

S = strings(0,1);  SF = [];  EF = [];  DUR = [];
F = T.(frameVar);

for v = syllCols
    x = T.(v{1}) == 1;                               % 1 = present
    d = diff([0; x; 0]);                             % transitions
    sIdx = find(d == 1);                             % bout starts (row index)
    eIdx = find(d == -1) - 1;                        % bout ends   (row index)
    if ~isempty(sIdx)
        S   = [S;   repmat(string(v), numel(sIdx), 1)];
        SF  = [SF;  F(sIdx)];
        EF  = [EF;  F(eIdx)];
        DUR = [DUR; EF(end-numel(sIdx)+1:end) - F(sIdx) + 1]; % frames
    end
end

bouts = table(S, SF, EF, DUR, 'VariableNames', ...
              {'Syllable','StartFrame','EndFrame','DurationFrames'});
bouts = sortrows(bouts, {'Syllable','StartFrame'});

%% calculate syllable metrics
stable = get_features_syllable(stable);

%% find the coordinates of both animals
thetas = [0, pi/2, pi, -pi/2]; 
n_instance = height(bouts);
bouts.trial = nan(n_instance,1);
bouts.zone = nan(n_instance,1);
bouts.m1_pos_rot = cell(n_instance,1);
bouts.m2_pos_rot = cell(n_instance,1);
bouts.inter_dist = cell(n_instance,1);
for n = 1:n_instance
    cur_syll = bouts.Syllable{n};
    id = cur_syll(1:2);
    frame_st = bouts.StartFrame(n);
    frame_en = bouts.EndFrame(n);
    cur_tr = find(frame_st > (stable.led_init - 30),1,'last');
    cur_zone = stable.m1_zone(cur_tr);
    bouts.trial(n) = cur_tr;
    bouts.zone(n) = cur_zone;
    % confirm this trial is correct
    if stable.correct(cur_tr) ~= 1
        disp('syllable in an incorrect trial, skip it\n')
        continue
    end
    m1_trials = stable.m1_trials{cur_tr};
    m2_trials = stable.m2_trials{cur_tr};
    idx_st = find(m1_trials.f_no == frame_st)-10;
    idx_end = find(m1_trials.f_no == frame_en)+5;
    m1_pos = table2array(m1_trials(idx_st:idx_end,{'neck_x','neck_y'}));
    m2_pos = table2array(m2_trials(idx_st:idx_end,{'neck_x','neck_y'}));
    inter_dist = vecnorm(m1_pos - m2_pos,2,2);
    cur_trials = eval([id '_trials']);
    Aspd = cur_trials.([id '_k2n_Aspd'])(idx_st:idx_end);
    dif_k2n_Aabs = m1_trials.dif_k2n_Aabs(idx_st:idx_end);
    AprchRatio = cur_trials.([id '_TwdOther_n_AprchRatio'])(idx_st:idx_end);
    TanRatio = cur_trials.([id '_TwdOther_n_TanRatio'])(idx_st:idx_end);

    theta = thetas(cur_zone);
    R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
    m1_pos_rot = (R * m1_pos')';
    m2_pos_rot = (R * m2_pos')';
    bouts.m1_pos_rot{n} = m1_pos_rot;
    bouts.m2_pos_rot{n} = m2_pos_rot;
    bouts.inter_dist{n} = inter_dist;
    bouts.Aspd{n} = Aspd;
    bouts.dif_k2n_Aabs{n} = dif_k2n_Aabs;
    bouts.AprchRatio{n} = AprchRatio;
    bouts.TanRatio{n} = TanRatio;
end

%% plot trajectory
syllables = unique(bouts.Syllable);
n_syl = length(syllables);
n_rows = floor(sqrt(n_syl));
n_cols = round(n_syl/n_rows);
fig = figure('Position',[300 300 600 600]); 
tiledlayout(n_rows,n_cols,'TileSpacing','tight'); % Create a grid with tight spacing and padding
for i = 1:n_syl
% for i = 4
    cur_syll = syllables{i};
    cur_bouts = bouts(strcmp(bouts.Syllable,cur_syll),:);
    n_instance = height(cur_bouts);
    % subplot(n_rows,n_cols,i)
    nexttile;
    hold on;
    for n = 1:n_instance
        m1_pos_rot = cur_bouts.m1_pos_rot{n};
        m2_pos_rot = cur_bouts.m2_pos_rot{n};
        plot(m1_pos_rot(:,1),m1_pos_rot(:,2),'Color','c',LineWidth=2);
        plot(m2_pos_rot(:,1),m2_pos_rot(:,2),'Color','m',LineWidth=2);
        % cur_trial = cur_bouts.trial(n);
        % cur_zone = cur_bouts.zone(n);
        % title([cur_syll ' trial #' num2str(cur_trial) ' zone ' num2str(cur_zone)])
    end
    xlim([-25 25])
    ylim([-25 25])
    title(cur_syll)
    xlabel('X (cm)')
    ylabel('Y (cm)')
    set(gca,'FontSize',14)
end

%% plot metrics
syllables = unique(bouts.Syllable);
n_syl = length(syllables);
n_rows = floor(sqrt(n_syl));
n_cols = round(n_syl/n_rows);
fig = figure('Position',[300 300 600 400]); 
tiledlayout(n_rows,n_cols,'TileSpacing','tight','Padding','tight'); % Create a 2x2 grid with tight spacing and padding
feature = 'TanRatio';
for i = 1:n_syl
% for i = 4
    cur_syll = syllables{i};
    cur_bouts = bouts(strcmp(bouts.Syllable,cur_syll),:);
    n_instance = height(cur_bouts);
    % subplot(n_rows,n_cols,i)
    nexttile;
    hold on;
    for n = 1:n_instance
        cur_metric = cur_bouts.(feature){n};
        plot(cur_metric,'Color',[0.8 0.8 0.8 0.8],LineWidth=1);
        % cur_trial = cur_bouts.trial(n);
        % cur_zone = cur_bouts.zone(n);
        % title([cur_syll ' trial #' num2str(cur_trial) ' zone ' num2str(cur_zone)])
    end
    % get the mean
    C = cur_bouts.(feature);    % cell array of vectors
    maxN = max(cellfun(@numel, C));
    
    % Pad all vectors to maxN with NaN
    M = nan(maxN, numel(C));
    for i = 1:numel(C)
        n = numel(C{i});
        M(1:n,i) = C{i};
    end
    % Compute position-wise mean ignoring missing
    f_mean = mean(M, 2, 'omitnan');
    plot(f_mean,'k','LineWidth',2)
    title(cur_syll)
    % ylim([0 1500]); % for angular speed    ylabel('Angular speed')
    % ylim([0 200]); ylabel('neck-nose angle dif'); % for angle difference 
    ylim([0 1]); ylabel('Tan Ratio'); % for angle difference 
    xlim([0 40])
    xlabel('Time (frame)')
    set(gca,'FontSize',14)
end        
%% plot metrics
syllables = unique(bouts.Syllable);
n_syl = length(syllables);
n_rows = floor(sqrt(n_syl));
n_cols = round(n_syl/n_rows);
fig = figure('Position',[300 300 600 400]); 
tiledlayout(n_rows,n_cols,'TileSpacing','tight','Padding','tight'); % Create a 2x2 grid with tight spacing and padding
feature = 'inter_dist';
for i = 1:n_syl
% for i = 4
    cur_syll = syllables{i};
    cur_bouts = bouts(strcmp(bouts.Syllable,cur_syll),:);
    n_instance = height(cur_bouts);
    % subplot(n_rows,n_cols,i)
    nexttile;
    hold on;
    for n = 1:n_instance
        cur_metric = cur_bouts.(feature){n};
        plot(cur_metric,'Color',[0.8 0.8 0.8 0.8],LineWidth=1);
        % cur_trial = cur_bouts.trial(n);
        % cur_zone = cur_bouts.zone(n);
        % title([cur_syll ' trial #' num2str(cur_trial) ' zone ' num2str(cur_zone)])
    end
    % get the mean
    C = cur_bouts.(feature);    % cell array of vectors
    maxN = max(cellfun(@numel, C));
    % Pad all vectors to maxN with NaN
    M = nan(maxN, numel(C));
    for i = 1:numel(C)
        n = numel(C{i});
        M(1:n,i) = C{i};
    end
    % Compute position-wise mean ignoring missing
    f_mean = mean(M, 2, 'omitnan');
    plot(f_mean,'k','LineWidth',2)
    title(cur_syll)
    ylim([0 40])
    xlim([0 40])
    xlabel('Time (frame)')
    ylabel('Inter-animal distance (cm)')
    set(gca,'FontSize',14)
end
%% group m1 and m2 and plot metrics
syllables = {'track';'sync';'join';'sharp'};
n_syl = length(syllables);
n_rows = 2; n_cols = 2;
fig = figure('Position',[300 300 600 600]); 
tiledlayout(n_rows,n_cols,'TileSpacing','tight'); 
feature = 'inter_dist';
for i = 1:n_syl
% for i = 4
    cur_syll = syllables{i};
    cur_syll_group = {['m1_' cur_syll];['m2_' cur_syll]};
    cur_bouts = bouts(ismember(bouts.Syllable,cur_syll_group),:);
    n_instance = height(cur_bouts);
    nexttile;
    hold on;
    for n = 1:n_instance
        cur_metric = cur_bouts.(feature){n};
        plot(cur_metric,'Color',[0.8 0.8 0.8 0.8],LineWidth=1);
    end
    C = cur_bouts.(feature);    % cell array of vectors
    maxN = max(cellfun(@numel, C));
    % Pad all vectors to maxN with NaN
    M = nan(maxN, numel(C));
    for tr = 1:numel(C)
        n = numel(C{tr});
        M(1:n,tr) = C{tr};
    end 
    % Compute position-wise mean ignoring missing
    f_mean = mean(M, 2, 'omitnan');
    plot(f_mean,'k','LineWidth',2)
    title(cur_syll)
    ylim([0 40])
    xlim([0 40])
    xlabel('Time (frame)')
    ylabel('Inter-animal distance (cm)')
    set(gca,'FontSize',14)
end

%% combine all sessions 
fd = '/Users/herbert/Wulab Dropbox/Lab/Yuan/12_Syllable_labels/hand_labeling/sessions_data_paper_2nd';
filename = 'cohort/syllable_table.mat';
cd(fd)
% Load the syllable table
syllable_table = load(fullfile(fd, filename)).syllable_table;
n_ses = height(syllable_table);
bouts_cbd = [];
% for s = 1:2
for s = 1:n_ses
    cur_ses = syllable_table.session{s};
    cur_animal = cur_ses(1:10);
    cur_date = cur_ses(12:end);
    fprintf('Processing Session #%d %s\n', s, cur_ses) 
    stable = syllable_table.stable{s};
    syllable = syllable_table.syllabel{s};
    % % calculate syllable metrics
    % stable = get_features_syllable(stable);
    % save([fd '/' cur_ses '/stable_with_features'],"stable");
    % or load syllable metrics;
    stable = load([fd '/' cur_ses '/stable_with_features']).stable;
    bouts = get_syllable_bouts(syllable,stable);
    n_instance = height(bouts);
    bouts.animal = repmat(cur_animal,n_instance,1);
    bouts.date = repmat(cur_date,n_instance,1);
    bouts = bouts(:,[end-1:end 1:end-2]);
    bouts_cbd = [bouts_cbd;bouts];
end
save([fd '/cohort/bout_table'],"bouts_cbd");

%% group m1 and m2 and plot metrics
syllables = {'track';'sync';'join';'sharp'};
n_syl = length(syllables);
n_rows = 1; n_cols = 4;
fig = figure('Position',[300 300 792 230]); 
tiledlayout(n_rows,n_cols,'TileSpacing','tight'); 
% feature = 'inter_dist'; ylims = [0 35]; y_label = 'Distance (cm)'; 
% feature = 'Aspd'; ylims = [0 500]; y_label = 'Angular speed';
feature = 'dif_k2n_Aabs'; ylims = [0 150]; y_label = ['Head angle dif (' char(176) ')'];
% feature = 'TanRatio'; ylims = [0 1]; y_label = 'Proportion lateral movement'; 
% feature = 'nkt_Aspd'; ylims = [0 400]; y_label = 'NKT angle speed'; 
% feature = 'nkt_A'; ylims = [-90 90]; y_label = 'NKT angle'; 
% feature = 'n_Spd'; ylims = [0 50]; y_label = 'Neck speed (cm/s)'; 
% feature = 'n_Acc'; ylims = [-2000 2000]; y_label = 'Neck Acceleration'; 

for i = 1:n_syl
% for i = 4
    cur_syll = syllables{i};
    cur_syll_group = {['m1_' cur_syll];['m2_' cur_syll]};
    cur_bouts = bouts_cbd(ismember(bouts_cbd.Syllable,cur_syll_group),:);
    n_instance = height(cur_bouts);
    nexttile;
    hold on;
    C = cur_bouts.(feature);    % cell array of vectors
    % Smooth each cell vector
    w = 5;  % window size, adjust as needed
    for n = 1:n_instance
        C{n} = movmean(C{n}, w);
    end
    % % plot individual traces
    % for n = 1:n_instance
    %     cur_metric = C{n};
    %     plot(cur_metric,'Color',[0.8 0.8 0.8 0.8],LineWidth=1);
    % end
    maxN = max(cellfun(@numel, C));
    % Pad all vectors to maxN with NaN
    M = nan(maxN, numel(C));
    for tr = 1:numel(C)
        n = numel(C{tr});
        M(1:n,tr) = C{tr};
    end 
    % Compute position-wise mean ignoring missing
    f_mean = mean(M, 2, 'omitnan');
    f_std = std(M,0,2,"omitmissing");
    t_end = length(f_mean);
    x = (1:t_end);
    plot(f_mean,'k','LineWidth',2)
    [p,~] = error_shade(x,f_mean',f_std',[0.2 0.2 0.2]);
    title(sprintf([cur_syll ' (N=%d)'],n_instance))
    ylim(ylims);
    if strcmp(cur_syll,'sharp')
        x_end = 50;
    else
        x_end = 40;
    end
    xlim([0 x_end])
    xlabel('Time (frame)')
    ylabel(y_label)
    set(gca,'FontSize',16,'TickDir','out')
end
sgtitle(y_label,'FontSize',18,'FontWeight','bold')
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd '/plots/' hoy '_all_animals_' feature];
set(fig,'PaperOrientation','landscape');
print(fig,figname,'-dpdf');

%% stats
n_timepoints = 40;
data = [];
animal = [];
condition = [];
time = [];
trial = [];
Ntrials = 0;
for i = 1:n_syl
    cur_syll = syllables{i};
    cur_syll_group = {['m1_' cur_syll];['m2_' cur_syll]};
    cur_bouts = bouts_cbd(ismember(bouts_cbd.Syllable,cur_syll_group),:);
    C = cur_bouts.(feature);    % cell array of vectors
    maxN = max(cellfun(@numel, C));
    % Pad all vectors to maxN with NaN
    n_trials = height(cur_bouts);
    cur_data = nan(maxN, n_trials); % n_timepoints x n_trials
    for tr = 1:numel(C)
        n = numel(C{tr});
        cur_data(1:n,tr) = C{tr};
    end 
    cur_data = cur_data(1:n_timepoints,:);
    idx_nan = any(isnan(cur_data), 1);
    cur_data(:,idx_nan) = []; % remove any trial with NaN
    cur_bouts = cur_bouts(~idx_nan,:);
    n_trials = size(cur_data,2); % update n_trials
    data = [data;cur_data(:)];
    animal = [animal;repelem(cellstr(cur_bouts.animal),n_timepoints)];
    time = [time; repmat((1:n_timepoints)', n_trials, 1)];
    condition = [condition;repmat({cur_syll},n_trials*n_timepoints,1)];
    trial = [trial; repelem((Ntrials+1:Ntrials+n_trials)',n_timepoints)];
    Ntrials = Ntrials + n_trials;
end

% Build table
tbl = table(data, time, condition, animal, trial);
% lme = fitlme(tbl, 'data ~ condition * time + (1 | animal)')
lme = fitlme(tbl, 'data ~ condition * time + (time | animal) + (time|animal:trial)')

%% pair-wise comparison
conds = syllables;
pairs = nchoosek(1:4,2);

pvals = zeros(size(pairs,1),1);
labels = strings(size(pairs,1),1);

for k = 1:size(pairs,1)
    c1 = conds{pairs(k,1)};
    c2 = conds{pairs(k,2)};
    
    % Set reference level
    % tbl.condition = reordercats(tbl.condition, {c1,c2, conds{~ismember(conds,{c1,c2})}});
    newOrder = {c1, c2, conds{~ismember(conds,{c1,c2})}};
    tbl.condition = categorical(tbl.condition, newOrder);
    
    % Fit model
    lme = fitlme(tbl, 'data ~ condition*time + (time|animal) + (time|animal:trial)')
    
    % Extract p-value for slope difference
    pvals(k) = lme.Coefficients.pValue(6);
    
    labels(k) = c1 + " vs " + c2;
end

%% group m1 and m2， plot two metrics on the x and y axes
syllables = {'track';'sync';'join';'sharp'};
n_syl = length(syllables);
n_rows = 1; n_cols = 4;
% fig = figure('Position',[300 300 600 600]); 
fig = figure('Position',[300 300 792 230]); 

tiledlayout(n_rows,n_cols,'TileSpacing','tight'); 
feature1 = 'n_Spd'; xlims = [0 70]; x_label = 'Neck speed (cm/s)'; 
% feature2 = 'Aspd'; ylims = [0 1500]; y_label = 'Angular speed';
% feature2 = 'nkt_Aspd'; ylims = [0 1000]; y_label = 'NKT angle speed'; 
% feature2 = 'nkt_A'; ylims = [-90 90]; y_label = 'NKT angle'; 
feature2 = 'inter_dist'; ylims = [0 40]; y_label = 'Inter-animal distance (cm)'; 
% feature = 'dif_k2n_Aabs'; ylims = [0 200]; y_label = 'neck-nose angle dif';
% feature = 'TanRatio'; ylims = [0 1]; y_label = 'Tan Ratio'; 
% feature = 'n_Acc'; ylims = [-2000 2000]; y_label = 'Neck Acceleration'; 

for i = 1:n_syl
% for i = 4
    cur_syll = syllables{i};
    if strcmp(cur_syll,'sharp')
        t_end = 50;
    else
        t_end = 40;
    end

    cur_syll_group = {['m1_' cur_syll];['m2_' cur_syll]};
    cur_bouts = bouts_cbd(ismember(bouts_cbd.Syllable,cur_syll_group),:);
    n_instance = height(cur_bouts);
    nexttile;
    hold on;
    F1 = cur_bouts.(feature1); 
    F2 = cur_bouts.(feature2);
    % Smooth each cell vector
    w = 3;  % window size, adjust as needed
    for n = 1:n_instance
        F1{n} = movmean(F1{n}, w);
        F2{n} = movmean(F2{n}, w);
    end
    % plot individual traces
    for n = 1:99:n_instance % plot 1% of the trials as examples
        cur_F1 = F1{n};
        cur_F2 = F2{n};
        if length(cur_F1) > t_end
            plot(cur_F1(1:t_end),cur_F2(1:t_end),'Color',[0.8 0.8 0.8 0.8],LineWidth=1);
        else
            plot(cur_F1,cur_F2,'Color',[0.8 0.8 0.8 0.8],LineWidth=1);
        end
    end
    maxN = max(cellfun(@numel, F1));
    % Pad all vectors to maxN with NaN
    F1_array = nan(maxN, n_instance);
    F2_array = nan(maxN, n_instance);
    for tr = 1:n_instance
        n = numel(F1{tr});
        F1_array(1:n,tr) = F1{tr};
        F2_array(1:n,tr) = F2{tr};
    end 
    % Compute position-wise mean ignoring missing
    mean_F1 = mean(F1_array, 2, 'omitnan');
    mean_F2 = mean(F2_array, 2, 'omitnan');
    plot(mean_F1(1:t_end),mean_F2(1:t_end),'k','LineWidth',2)
    scatter(mean_F1(1),mean_F2(1),80,'g','filled');
    scatter(mean_F1(t_end),mean_F2(t_end),80,'r','filled')
    title(sprintf([cur_syll ' (N=%d)'],n_instance))
    ylim(ylims);
    xlim(xlims)
    xlabel(x_label)
    ylabel(y_label)
    set(gca,'FontSize',14,'TickDir','out')
end
sgtitle('Inter-animal distance vs speed','FontSize',18,'FontWeight','bold')
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd '/plots/' hoy '_all_animals_' feature1 '_vs_' feature2];
set(fig,'PaperOrientation','landscape');
print(fig,figname,'-dpdf');

%% plot trajectories of all sessions
fd = '/Users/herbert/Wulab Dropbox/Lab/Yuan/12_Syllable_labels/hand_labeling/sessions_data_paper';
filename = 'cohort/syllable_table.mat';

% Load the syllable table
syllable_table = load(fullfile(fd, filename)).syllable_table;
n_ses = height(syllable_table);
%%
colors = [246,141,92;63 182 196]/255;
% for s = 1
for s = 1:n_ses
    cur_ses = syllable_table.session{s};
    cur_animal = cur_ses(1:10);
    cur_date = cur_ses(12:end);
    fprintf('Processing Session #%d %s\n', s, cur_ses) 
    % stable = syllable_table.stable{s};
    syllable = syllable_table.syllabel{s};
    % calculate syllable metrics
    % stable = get_features_syllable(stable);
    % save([fd '/' cur_ses '/stable_with_features'],"stable");
    % or load syllable metrics;
    stable = load([fd '/' cur_ses '/stable_with_features']).stable;
    bouts = get_syllable_bouts(syllable,stable); % choose how to rotate trials here
    bouts = bouts(bouts.trial_type<=4,:); % only use trial type 1-4 for consistency
    % plot trajectory
    syllables = unique(bouts.Syllable);
    n_syl = length(syllables);
    n_rows = floor(sqrt(n_syl));
    n_cols = round(n_syl/n_rows);
    fig = figure('Position',[300 300 792 410]); 
    tiledlayout(n_rows,n_cols,'TileSpacing','tight'); % Create a grid with tight spacing and padding
    for i = 1:n_syl
    % for i = 4
        cur_syll = syllables{i};
        cur_bouts = bouts(strcmp(bouts.Syllable,cur_syll),:);
        n_instance = height(cur_bouts);
        cur_actor = cur_syll(1:2);
        cur_partner = ['m' num2str(3-str2double(cur_actor(2)))];
        % subplot(n_rows,n_cols,i)
        nexttile;
        hold on;
        for n = 1:n_instance
            % % plot based on m1/m2
            % m1_pos_rot = cur_bouts.m1_pos_rot{n};
            % m2_pos_rot = cur_bouts.m2_pos_rot{n};
            % if ~isempty(m1_pos_rot) && ~isempty(m2_pos_rot)
            %     plot(m1_pos_rot(:,1),m1_pos_rot(:,2),'Color',[0 1 1 0.8],LineWidth=1);
            %     plot(m2_pos_rot(:,1),m2_pos_rot(:,2),'Color',[1 0 1 0.8],LineWidth=1);
            % end

            % plot based on actor
            actor_pos_rot = cur_bouts.([cur_actor '_pos_rot']){n};
            partner_pos_rot = cur_bouts.([cur_partner '_pos_rot']){n};
            if ~isempty(actor_pos_rot) && ~isempty(partner_pos_rot)
                plot(actor_pos_rot(:,1),actor_pos_rot(:,2),'Color',[colors(1,:) 0.8],LineWidth=1);
                plot(partner_pos_rot(:,1),partner_pos_rot(:,2),'Color',[colors(2,:) 0.8],LineWidth=1);
            end

            % cur_trial = cur_bouts.trial(n);
            % cur_zone = cur_bouts.zone(n);
            % title([cur_syll ' trial #' num2str(cur_trial) ' zone ' num2str(cur_zone)])
        end

        % % plot mean trajectory
        % maxN = max(cellfun(@numel, cur_bouts.m1_pos_rot));
        % % Pad all vectors to maxN with NaN
        % m1_array = nan(maxN, 2, n_instance);
        % m2_array = nan(maxN, 2, n_instance);
        % for tr = 1:n_instance
        %     n = size(cur_bouts.m1_pos_rot{tr},1);
        %     m1_array(1:n,:,tr) = cur_bouts.m1_pos_rot{tr};
        %     m2_array(1:n,:,tr) = cur_bouts.m2_pos_rot{tr};
        % end 
        % % Compute position-wise mean ignoring missing
        % mean_m1 = mean(m1_array, 3, 'omitmissing');
        % mean_m2 = mean(m2_array, 3, 'omitmissing');
        % plot(mean_m1(:,1),mean_m1(:,2),'Color','c',LineWidth=2);
        % plot(mean_m2(:,1),mean_m2(:,2),'Color','m',LineWidth=2);

        xlim([-25 25])
        ylim([-25 25])
        title(strrep(cur_syll,'_',' '))
        xlabel('X (cm)')
        ylabel('Y (cm)')
        set(gca,'FontSize',14,'Tickdir','out')
    end
    sgtitle([cur_animal ' ' cur_date],'FontSize',18,'FontWeight','bold')
    hoy = char(datetime('now','Format','yyyyMMdd'));
    figname = [fd '/plots/' hoy '_traj_actor_' cur_animal '_' cur_date '_v2'];
    set(fig,'PaperOrientation','landscape');
    print(fig,figname,'-dpdf');
end
