function [fig,p_corr_angle,p_corr_angle_shuf] = decode_angle_multi_ses_v2(mrtable,params)
% decode angle and distance using svc neural responses
% use combined spk matrix from get_svc_decoding_matrix_v1
% every frame is a sample
% every neuron is a feature with neurons from multiple sessions combined
% v1: randsample sample with a simple partition
% v2: partition by segmenting each session into nFold parts and train on
% nFold-1 segment and test on the remaining part

%% get params
fd = params.fd; 
animal = params.animal;
role = params.role;
hoy = char(datetime('now','Format','yyyyMMdd'));
which2plot = params.which2plot;
which_frames = params.which_frames;
colors = get_colormap(role);

spk_angle = vertcat(mrtable.spk_angle{:})'; % transpose to n_frames x n_neurons
spk_angle_shuf = vertcat(mrtable.spk_angle_shuf{:})'; % transpose to n_frames x n_neurons

labels_angle = mrtable.labels_angle{1};
n_frames_angle = mrtable.n_frames_angle{1};

n_sel_frames = length(labels_angle);

n_bins_angle = params.n_bins_angle; 
max_dist = params.max_dist;
spatial_binsize = params.spatial_binsize;
n_bins_dist = max_dist/spatial_binsize;
params.n_bins_dist = n_bins_dist; 

n_cells = height(mrtable);
Ninput = params.Ninput; % choose how many neurons are used for decoding
fprintf('Decoding partner angle for %s\n', animal);
if Ninput == 0
    Ninput = n_cells;
    fprintf('Use all %d of %d input neurons\n',Ninput, n_cells);
elseif Ninput <= n_cells
    % fprintf('Session #%d has %d units\n',i,N);        
    fprintf('Use %d of %d input neurons\n',Ninput, n_cells);
elseif Ninput > n_cells
    % fprintf('Session #%d has %d units, skipped\n',i,N);        
    fprintf('Ninput %d is more than %d available cells!\n',Ninput, n_cells);
end 

% decode data
n_fold = 5;
n_rs = params.n_rs;
p_corr_angle_folds = nan(n_fold,n_rs);
p_corr_angle_folds_shuf = nan(n_fold,n_rs);

prob_estimates = [];
prob_estimates_shuf = [];
for fi = 1:n_fold
% for fi = 1
    idx_test = [];
    for b = 1:n_bins_angle
        n_frames_curBin = n_frames_angle(b);
        idx_test_curBin = zeros(n_frames_curBin,1);
        idx_test_curBin(round((fi-1)/n_fold*n_frames_curBin)+1:round(fi/n_fold*n_frames_curBin))=1;
        idx_test = [idx_test;idx_test_curBin];
    end
    idx_test = find(idx_test);
    idx_train = setdiff((1:n_sel_frames)',idx_test);
    % data
    spk_train0 = spk_angle(idx_train,:);
    labels_train = labels_angle(idx_train);
    spk_test0 = spk_angle(idx_test,:);
    labels_test = labels_angle(idx_test);

    for n = 1:n_rs
        if Ninput < n_cells
            cellinds = randsample(n_cells,Ninput);
            spk_train = spk_train0(:,cellinds);
            spk_test = spk_test0(:,cellinds);
            N_used = Ninput;
        else
            spk_train = spk_train0;
            spk_test = spk_test0;
            N_used = n_cells;
        end

        model_logi = train(labels_train,sparse(spk_train),'-q -s 0');
        [pred_test, ~, prob_estimate_curFold] = predict(labels_test,sparse(spk_test),model_logi,'-q -b 1');  
        prob_estimates_curMean = nan(n_bins_angle,n_bins_angle);
        for b = 1:n_bins_angle
            prob_estimates_curMean(b,:) = mean(prob_estimate_curFold(labels_test==b,:));
        end
        prob_estimates = cat(3,prob_estimates,prob_estimates_curMean);
        labels_neighbor = [labels_test-1 labels_test labels_test+1];
        labels_neighbor(labels_neighbor==0) = n_bins_angle;
        labels_neighbor(labels_neighbor==n_bins_angle+1) = 1;
        corr = any(pred_test==labels_neighbor,2);
        % temp = [predtest_logi labels_neighbor corr];
        p_corr_angle_folds(fi,n) = mean(corr);
    end

    % shuffle
    spk_train0 = spk_angle_shuf(idx_train,:);
    labels_train = labels_angle(idx_train);
    spk_test0 = spk_angle_shuf(idx_test,:);
    labels_test = labels_angle(idx_test);
    for n = 1:n_rs
        if Ninput < n_cells
            cellinds = randsample(n_cells,Ninput);
            spk_train = spk_train0(:,cellinds);
            spk_test = spk_test0(:,cellinds);
        else
            spk_train = spk_train0;
            spk_test = spk_test0;
        end
    
        model_logi_shuf = train(labels_train,sparse(spk_train),'-q -s 0');
        [pred_test, ~, prob_estimate_curFold] = predict(labels_test,sparse(spk_test),model_logi_shuf,'-q -b 1');  
        prob_estimates_curMean = nan(n_bins_angle,n_bins_angle);
        for b = 1:n_bins_angle
            prob_estimates_curMean(b,:) = mean(prob_estimate_curFold(labels_test==b,:));
        end
        prob_estimates_shuf = cat(3,prob_estimates_shuf,prob_estimates_curMean);
        corr = any(pred_test==labels_neighbor,2);
        % temp = [predtest_logi labels_neighbor corr];
        p_corr_angle_folds_shuf(fi,n) = mean(corr);
    end
end

p_corr_angle = mean(p_corr_angle_folds(:));
prob_estimate_mean = mean(prob_estimates,3);

source_data = table();

row = 1;
for obs_bin = 1:n_bins_angle
    for pred_bin = 1:n_bins_angle
        source_data.ObservedBin(row,1) = obs_bin;
        source_data.PredictedBin(row,1) = pred_bin;
        source_data.ObservedAngleDeg(row,1) = ...
            -180 + (obs_bin-1)*360/(n_bins_angle-1);
        source_data.PredictedAngleDeg(row,1) = ...
            -180 + (pred_bin-1)*360/(n_bins_angle-1);
        source_data.DecodingProbability(row,1) = ...
            prob_estimate_mean(obs_bin,pred_bin);
        row = row + 1;
    end
end

summary_data = table();
summary_data.Animal = string(animal);
summary_data.Role = string(role);
summary_data.Which2Plot = string(which2plot);
summary_data.WhichFrames = string(which_frames);
summary_data.NCells = n_cells;
summary_data.NUsed = N_used;
summary_data.NFold = n_fold;
summary_data.NRandomSubsamples = n_rs;
summary_data.DecodingAccuracy = p_corr_angle;

assignin('base','source_data',source_data);
assignin('base','summary_data',summary_data);

fig = figure('Position',[300 300 400 400]);
colormap(colors);
imagesc(prob_estimate_mean);
colorbar;
% clims = clim; 
clims = [0 0.15];
clim([0 clims(2)])
box off
axis equal
xlim([0.5 n_bins_angle+0.5])
xticks([0.5 (n_bins_angle+1)/2 n_bins_angle+0.5])
xticklabels([-180 0 180])
ylim([0.5 n_bins_angle+0.5])
yticks([0.5 (n_bins_angle+1)/2 n_bins_angle+0.5])
yticklabels([-180 0 180])
xlabel(['Predicted head-other angle(' char(176) ')']);
ylabel(['Observed head-other angle(' char(176) ')']);
caption = [which2plot ' ' which_frames ' (N=' num2str(N_used) ')'];
caption = strrep(caption,'_',' ');
title(caption);
set(gca,'FontSize',20,'TickDir','out')
figname = [fd '/plots/' hoy 'p_angle_confusion_matrix_' which2plot '_' which_frames '_N=' num2str(N_used)];
set(fig,'PaperUnits','normalized','PaperPosition', [0 0 1 1]);
print(fig,figname,'-dpdf');

p_corr_angle_shuf = mean(p_corr_angle_folds_shuf(:));
prob_estimate_mean_shuf = mean(prob_estimates_shuf,3);

source_data_shuf = table();

row = 1;
for obs_bin = 1:n_bins_angle
    for pred_bin = 1:n_bins_angle
        source_data_shuf.ObservedBin(row,1) = obs_bin;
        source_data_shuf.PredictedBin(row,1) = pred_bin;
        source_data_shuf.ObservedAngleDeg(row,1) = ...
            -180 + (obs_bin-1)*360/(n_bins_angle-1);
        source_data_shuf.PredictedAngleDeg(row,1) = ...
            -180 + (pred_bin-1)*360/(n_bins_angle-1);
        source_data_shuf.DecodingProbability(row,1) = ...
            prob_estimate_mean_shuf(obs_bin,pred_bin);
        row = row + 1;
    end
end

summary_data_shuf = table();
summary_data_shuf.Animal = string(animal);
summary_data_shuf.Role = string(role);
summary_data_shuf.Which2Plot = string(which2plot);
summary_data_shuf.WhichFrames = string(which_frames);
summary_data_shuf.NCells = n_cells;
summary_data_shuf.NUsed = N_used;
summary_data_shuf.NFold = n_fold;
summary_data_shuf.NRandomSubsamples = n_rs;
summary_data_shuf.DecodingAccuracy = p_corr_angle_shuf;

assignin('base','source_data_shuf',source_data_shuf);
assignin('base','summary_data_shuf',summary_data_shuf);

fig = figure('Position',[700 300 400 400]);
colormap(colors);
imagesc(prob_estimate_mean_shuf);
colorbar
clim([0 clims(2)])
box off
axis equal
xlim([0.5 n_bins_angle+0.5])
xticks([0.5 (n_bins_angle+1)/2 n_bins_angle+0.5])
xticklabels([-180 0 180])
ylim([0.5 n_bins_angle+0.5])
yticks([0.5 (n_bins_angle+1)/2 n_bins_angle+0.5])
yticklabels([-180 0 180])
xlabel(['Predicted head-other angle(' char(176) ')']);
ylabel(['Shuffled head-other angle(' char(176) ')']);
caption = [which2plot ' ' which_frames ' (N=' num2str(N_used) ')'];
caption = strrep(caption,'_',' ');
title(caption);
set(gca,'FontSize',20,'TickDir','out')
figname = [fd '/plots/' hoy 'p_angle_confusion_matrix_' which2plot '_' which_frames '_N=' num2str(N_used) '_shuf'];
set(fig,'PaperUnits','normalized','PaperPosition', [0 0 1 1]);
print(fig,figname,'-dpdf');

end