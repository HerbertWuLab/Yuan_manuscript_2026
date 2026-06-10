load(fullfile(fd,'Data/bout_table.mat'));
syllables = {'track';'sync';'join';'sharp'};
n_syl = length(syllables);
n_rows = 1; n_cols = 4;
fig = figure('Position',[300 300 792 230]); 
tiledlayout(n_rows,n_cols,'TileSpacing','tight'); 
% feature = 'inter_dist'; ylims = [0 35]; y_label = 'Distance (cm)'; 
% feature = 'Aspd'; ylims = [0 500]; y_label = 'Angular speed';
% feature = 'dif_k2n_Aabs'; ylims = [0 150]; y_label = ['Head angle dif (' char(176) ')'];
% feature = 'TanRatio'; ylims = [0 1]; y_label = 'Proportion lateral movement'; 
feature = 'nkt_Aspd'; ylims = [0 400]; y_label = 'NKT angle speed'; 
% feature = 'nkt_A'; ylims = [-90 90]; y_label = 'NKT angle'; 
% feature = 'n_Spd'; ylims = [0 50]; y_label = 'Neck speed (cm/s)'; 
% feature = 'n_Acc'; ylims = [-2000 2000]; y_label = 'Neck Acceleration'; 

source_data = table();

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

    tmp = table();
    tmp.Syllable = repmat(string(cur_syll), t_end, 1);
    tmp.Feature = repmat(string(feature), t_end, 1);
    tmp.TimeFrame = x';
    tmp.Mean = f_mean;
    tmp.Std = f_std;
    tmp.NInstances = repmat(n_instance, t_end, 1);
    source_data = [source_data; tmp];

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

assignin('base','source_data',source_data);

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
% Sup Fig.6g
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

source_data = table();

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

    tmp = table();
    tmp.Syllable = repmat(string(cur_syll), t_end, 1);
    tmp.FeatureX = repmat(string(feature1), t_end, 1);
    tmp.FeatureY = repmat(string(feature2), t_end, 1);
    tmp.TimeFrame = (1:t_end)';
    tmp.MeanX = mean_F1(1:t_end);
    tmp.MeanY = mean_F2(1:t_end);
    tmp.NInstances = repmat(n_instance, t_end, 1);
    source_data = [source_data; tmp];

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

assignin('base','source_data',source_data);

sgtitle('Inter-animal distance vs speed','FontSize',18,'FontWeight','bold')
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd '/plots/' hoy '_all_animals_' feature1 '_vs_' feature2];
set(fig,'PaperOrientation','landscape');
print(fig,figname,'-dpdf');