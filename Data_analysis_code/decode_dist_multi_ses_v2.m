function [fig,p_corr_dist,p_corr_dist_shuf] = decode_dist_multi_ses_v2(mrtable,params)
% decode distance using svc neural responses
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

spk_dist = vertcat(mrtable.spk_dist{:})'; % transpose to n_frames x n_neurons
spk_dist_shuf = vertcat(mrtable.spk_dist_shuf{:})'; % transpose to n_frames x n_neurons

labels_dist = mrtable.labels_dist{1};
n_frames_dist = mrtable.n_frames_dist{1};

n_sel_frames = length(labels_dist);

n_bins_dist = params.n_bins_dist; 
max_dist = params.max_dist;
min_dist = params.min_dist;

n_cells = height(mrtable);
Ninput = params.Ninput; % choose how many neurons are used for decoding
fprintf('Decoding partner dist for %s\n', animal);
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
Nfold = 5;
n_rs = params.n_rs;
p_corr_dist_folds = nan(Nfold,n_rs);
p_corr_dist_folds_shuf = nan(Nfold,n_rs);

prob_estimates = [];
prob_estimates_shuf = [];
for fi = 1:Nfold
% for fi = 1
    idx_test = [];
    for b = 1:n_bins_dist
        n_frames_curBin = n_frames_dist(b);
        idx_test_curBin = zeros(n_frames_curBin,1);
        idx_test_curBin(round((fi-1)/Nfold*n_frames_curBin)+1:round(fi/Nfold*n_frames_curBin))=1;
        idx_test = [idx_test;idx_test_curBin];
    end
    idx_test = find(idx_test);
    idx_train = setdiff((1:n_sel_frames)',idx_test);
    % data
    spk_train0 = spk_dist(idx_train,:);
    labels_train = labels_dist(idx_train);
    spk_test0 = spk_dist(idx_test,:);
    labels_test = labels_dist(idx_test);

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
        prob_estimates_curMean = nan(n_bins_dist,n_bins_dist);
        for b = 1:n_bins_dist
            prob_estimates_curMean(b,:) = mean(prob_estimate_curFold(labels_test==b,:));
        end
        prob_estimates = cat(3,prob_estimates,prob_estimates_curMean);
        labels_neighbor = [labels_test-1 labels_test labels_test+1];
        % labels_neighbor(labels_neighbor==0) = n_bins_dist;
        % labels_neighbor(labels_neighbor==n_bins_dist+1) = 1;
        % corr = mean(any(pred_test==labels_neighbor,2));
        corr = mean(pred_test==labels_test);
        p_corr_dist_folds(fi,n) = corr;
    end

    % shuffle
    spk_train0 = spk_dist_shuf(idx_train,:);
    labels_train = labels_dist(idx_train);
    spk_test0 = spk_dist_shuf(idx_test,:);
    labels_test = labels_dist(idx_test);

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
        prob_estimates_curMean = nan(n_bins_dist,n_bins_dist);
        for b = 1:n_bins_dist
            prob_estimates_curMean(b,:) = mean(prob_estimate_curFold(labels_test==b,:));
        end
        prob_estimates_shuf = cat(3,prob_estimates_shuf,prob_estimates_curMean);
        % corr = mean(any(pred_test==labels_neighbor,2));
        corr = mean(pred_test==labels_test);
        p_corr_dist_folds_shuf(fi,n) = corr;
    end
end
p_corr_dist = mean(p_corr_dist_folds(:));
prob_estimate_mean = mean(prob_estimates,3);

source_data = table();

row = 1;
for obs_bin = 1:n_bins_dist
    for pred_bin = 1:n_bins_dist
        source_data.ObservedBin(row,1) = obs_bin;
        source_data.PredictedBin(row,1) = pred_bin;
        source_data.ObservedDistanceCm(row,1) = ...
            min_dist + (obs_bin-1)*(max_dist-min_dist)/(n_bins_dist-1);
        source_data.PredictedDistanceCm(row,1) = ...
            min_dist + (pred_bin-1)*(max_dist-min_dist)/(n_bins_dist-1);
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
summary_data.NFold = Nfold;
summary_data.NRandomSubsamples = n_rs;
summary_data.DecodingAccuracy = p_corr_dist;

assignin('base','source_data',source_data);
assignin('base','summary_data',summary_data);

fig = figure('Position',[300 300 400 400]);
colormap(colors);
imagesc(prob_estimate_mean);
colorbar;
% clims = clim;
clims = [0 0.3];
clim([0 clims(2)])
box off
axis equal
xlim([0.5 n_bins_dist+0.5])
xticks([0.5 n_bins_dist+0.5])
xticklabels([min_dist max_dist])
ylim([0.5 n_bins_dist+0.5])
yticks([0.5 n_bins_dist+0.5])
yticklabels([min_dist max_dist])
xlabel('Predicted partner distance (cm)');
ylabel('Observed partner distance (cm)');
caption = [which2plot ' ' which_frames ' (N=' num2str(N_used) ')'];
caption = strrep(caption,'_',' ');
title(caption);
set(gca,'FontSize',20,'TickDir','out')
figname = [fd '/plots/' hoy 'p_dist_confusion_matrix_' which2plot '_' which_frames '_N=' num2str(N_used)];
set(fig,'PaperUnits','normalized','PaperPosition', [0 0 1 1]);
print(fig,figname,'-dpdf');

p_corr_dist_shuf = mean(p_corr_dist_folds_shuf(:));
prob_estimate_mean_shuf = mean(prob_estimates_shuf,3);

source_data_shuf = table();

row = 1;
for obs_bin = 1:n_bins_dist
    for pred_bin = 1:n_bins_dist
        source_data_shuf.ObservedBin(row,1) = obs_bin;
        source_data_shuf.PredictedBin(row,1) = pred_bin;
        source_data_shuf.ObservedDistanceCm(row,1) = ...
            min_dist + (obs_bin-1)*(max_dist-min_dist)/(n_bins_dist-1);
        source_data_shuf.PredictedDistanceCm(row,1) = ...
            min_dist + (pred_bin-1)*(max_dist-min_dist)/(n_bins_dist-1);
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
summary_data_shuf.NFold = Nfold;
summary_data_shuf.NRandomSubsamples = n_rs;
summary_data_shuf.DecodingAccuracy = p_corr_dist_shuf;

assignin('base','source_data_shuf',source_data_shuf);
assignin('base','summary_data_shuf',summary_data_shuf);

fig = figure('Position',[700 300 400 400]);
colormap(colors);
imagesc(prob_estimate_mean_shuf);
colorbar
clim([0 clims(2)])
box off
axis equal
xlim([0.5 n_bins_dist+0.5])
xticks([0.5 n_bins_dist+0.5])
xticklabels([min_dist max_dist])
ylim([0.5 n_bins_dist+0.5])
yticks([0.5 n_bins_dist+0.5])
yticklabels([min_dist max_dist])
xlabel('Predicted partner distance (cm)');
ylabel('Shuffled partner distance (cm)');
caption = [which2plot ' ' which_frames ' (N=' num2str(N_used) ')'];
caption = strrep(caption,'_',' ');
title(caption);
set(gca,'FontSize',20,'TickDir','out')
figname = [fd '/plots/' hoy 'p_dist_confusion_matrix_' which2plot '_' which_frames '_N=' num2str(N_used) '_shuf'];
set(fig,'PaperUnits','normalized','PaperPosition', [0 0 1 1]);
print(fig,figname,'-dpdf');

end