function decode_position_demo(fd)
% load data
mrtable = load([fd 'Data/mrtable_4a_other_ego_both_outside_arrival_zone_svc_decoding.mat']).mrtable;

%% decoding svc by animal, each sample is a frame
params.pcut = 0.05;
uni_animals = unique(mrtable.animal);
params.which_pos = 'other_ego';
params.which_frames = 'both_outside_arrival_zone';
params.n_epoch = 5; 
params.n_bins_angle = 15; 
params.min_dist = 0;
params.max_dist = 35;  
params.spatial_binsize = 5;
params.n_bins_dist = (params.max_dist - params.min_dist)/params.spatial_binsize;
params.fd = fd;
params.Ninput = 300;
params.n_rs = 10;
for a = [1 4] % Fig. 5h
    animal = uni_animals{a};
    sel_animal = strcmp(mrtable.animal,animal);
    params.role = get_role_demo(animal); 
    mrtable_sel_animal = mrtable(sel_animal,:);
    params.which2plot = animal;
    params.animal = animal;
    decode_dist_multi_ses_v2(mrtable_sel_animal,params);    
end
for a = [1 6] % Fig. 5j
    animal = uni_animals{a};
    sel_animal = strcmp(mrtable.animal,animal);
    params.role = get_role_demo(animal); 
    mrtable_sel_animal = mrtable(sel_animal,:);
    params.which2plot = animal;
    params.animal = animal;
    decode_angle_multi_ses_v2(mrtable_sel_animal,params);
end
%% summary figure
tbl_animals = load([fd 'Data/decoding_table_animals_N=300.mat']).tbl_animals;

%% bar plot distance decoding performance. Fig.5i, Sup Fig. 15a

params.fd = '/Users/herbert/Wulab Dropbox/Lab/Yuan/imaging_analysis/';

chance_perf_dist = 1/7; % only use 0-35 cm range

x = tbl_animals.p_corr_dist(strcmp(tbl_animals.role,'leader'));
y = tbl_animals.p_corr_dist(strcmp(tbl_animals.role,'follower'));

xlabels = {'Leader','Follower'};
ylabels = 'Prop correct';
caption = 'Partner d decoding accuracy';

% ===== source data =====
source_data = table();

T_lead = table( ...
    repmat({'Leader'},length(x),1), ...
    (1:length(x))', ...
    x, ...
    repmat(chance_perf_dist,length(x),1), ...
    'VariableNames', ...
    {'Role','AnimalIndex','PropCorrect','ChanceLevel'});

T_foll = table( ...
    repmat({'Follower'},length(y),1), ...
    (1:length(y))', ...
    y, ...
    repmat(chance_perf_dist,length(y),1), ...
    'VariableNames', ...
    {'Role','AnimalIndex','PropCorrect','ChanceLevel'});

source_data = [source_data; T_lead; T_foll];

assignin('base','source_data',source_data);

% ===== statistics =====
[p,h,stats] = ranksum(x,y);

ranksum_stat = NaN;
zval = NaN;

if isfield(stats,'ranksum')
    ranksum_stat = stats.ranksum;
end

if isfield(stats,'zval')
    zval = stats.zval;
end

fprintf('\n========================================\n')
fprintf('Partner distance decoding accuracy\n')
fprintf('========================================\n')
fprintf('Test: Wilcoxon rank-sum test, Leader vs Follower\n')
fprintf('N Leader = %d\n', sum(~isnan(x)))
fprintf('N Follower = %d\n', sum(~isnan(y)))
fprintf('Leader median = %.4f\n', median(x,'omitnan'))
fprintf('Follower median = %.4f\n', median(y,'omitnan'))
fprintf('Leader mean = %.4f\n', mean(x,'omitnan'))
fprintf('Follower mean = %.4f\n', mean(y,'omitnan'))
fprintf('Chance level = %.4f\n', chance_perf_dist)
fprintf('Ranksum statistic = %.4f\n', ranksum_stat)

if ~isnan(zval)
    fprintf('Z = %.4f\n', zval)
end

fprintf('P = %.6g\n', p)

stats_table = table( ...
    {'Leader_vs_Follower'}, ...
    {'ranksum'}, ...
    sum(~isnan(x)), ...
    sum(~isnan(y)), ...
    median(x,'omitnan'), ...
    median(y,'omitnan'), ...
    mean(x,'omitnan'), ...
    mean(y,'omitnan'), ...
    chance_perf_dist, ...
    ranksum_stat, ...
    zval, ...
    p, ...
    'VariableNames', ...
    {'Comparison','Test','NLeader','NFollower', ...
    'MedianLeader','MedianFollower', ...
    'MeanLeader','MeanFollower', ...
    'ChanceLevel','RankSumStatistic','Z','PValue'});

assignin('base','stats_table',stats_table);

% ===== plot =====
fig = figure('Position',[600 300 200 400]);
hold on;

bar(1,median(x,"omitnan"),0.6, ...
    'EdgeColor','#c2a5cf', ...
    'FaceColor','none', ...
    'LineWidth',1);

bar(2,mean(y,"omitnan"),0.6, ...
    'EdgeColor','#a6dba0', ...
    'FaceColor','none', ...
    'LineWidth',1);

scatter(1*ones(size(x)),x,100, ...
    'MarkerFaceColor','#c2a5cf', ...
    'MarkerEdgeColor','k', ...
    'LineWidth',0.1);

scatter(2*ones(size(y)),y,100, ...
    'MarkerFaceColor','#a6dba0', ...
    'MarkerEdgeColor','k', ...
    'LineWidth',0.1);

box off

title(caption)

text(0.38,0.98,sprintf('P=%.2g', p), ...
    'FontSize',28, ...
    'Units','normalized')

yline(chance_perf_dist,'k--','LineWidth',1)

set(gca,'FontSize',32,'TickDir','out');

xlim([0.5 2.5])
ylim([0 0.35])

xticks([1 2]);
xticklabels(xlabels);

ylabel(ylabels);

hoy = char(datetime('now','Format','yyyyMMdd'));

figname = [params.fd 'plots/' hoy 'p_dist_decoding'];

print(fig,figname,'-dpdf');

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

%% bar plot angle decoding performance, Fig. 5k, Sup. Fig. 6b
params.fd = '/Users/herbert/Wulab Dropbox/Lab/Yuan/imaging_analysis/';

chance_perf_angle = 0.2;

x = tbl_animals.p_corr_angle(strcmp(tbl_animals.role,'leader'));
y = tbl_animals.p_corr_angle(strcmp(tbl_animals.role,'follower'));

xlabels = {'Leader';'Follower'};
ylabels = 'Prop correct';
caption = 'Partner \theta decoding accuracy';

source_data = table();

T_lead = table( ...
    repmat({'Leader'},length(x),1), ...
    (1:length(x))', ...
    x, ...
    repmat(chance_perf_angle,length(x),1), ...
    'VariableNames', ...
    {'Role','AnimalIndex','PropCorrect','ChanceLevel'});

T_foll = table( ...
    repmat({'Follower'},length(y),1), ...
    (1:length(y))', ...
    y, ...
    repmat(chance_perf_angle,length(y),1), ...
    'VariableNames', ...
    {'Role','AnimalIndex','PropCorrect','ChanceLevel'});

source_data = [source_data; T_lead; T_foll];

assignin('base','source_data',source_data);

[p,h,stats] = ranksum(x,y);

ranksum_stat = NaN;
zval = NaN;

if isfield(stats,'ranksum')
    ranksum_stat = stats.ranksum;
end

if isfield(stats,'zval')
    zval = stats.zval;
end

fprintf('\n========================================\n')
fprintf('Partner angle decoding accuracy\n')
fprintf('========================================\n')
fprintf('Test: Wilcoxon rank-sum test, Leader vs Follower\n')
fprintf('N Leader = %d\n', sum(~isnan(x)))
fprintf('N Follower = %d\n', sum(~isnan(y)))
fprintf('Leader median = %.4f\n', median(x,'omitnan'))
fprintf('Follower median = %.4f\n', median(y,'omitnan'))
fprintf('Leader mean = %.4f\n', mean(x,'omitnan'))
fprintf('Follower mean = %.4f\n', mean(y,'omitnan'))
fprintf('Chance level = %.4f\n', chance_perf_angle)
fprintf('Ranksum statistic = %.4f\n', ranksum_stat)

if ~isnan(zval)
    fprintf('Z = %.4f\n', zval)
end

fprintf('P = %.6g\n', p)

stats_table = table( ...
    {'Leader_vs_Follower'}, ...
    {'ranksum'}, ...
    sum(~isnan(x)), ...
    sum(~isnan(y)), ...
    median(x,'omitnan'), ...
    median(y,'omitnan'), ...
    mean(x,'omitnan'), ...
    mean(y,'omitnan'), ...
    chance_perf_angle, ...
    ranksum_stat, ...
    zval, ...
    p, ...
    'VariableNames', ...
    {'Comparison','Test','NLeader','NFollower', ...
    'MedianLeader','MedianFollower', ...
    'MeanLeader','MeanFollower', ...
    'ChanceLevel','RankSumStatistic','Z','PValue'});

assignin('base','stats_table',stats_table);

data = [x y];
N = size(data,1);

fig = figure('Position',[600 300 200 400]);
hold on;

bar(1,median(x,"omitnan"),0.6, ...
    'EdgeColor','#c2a5cf', ...
    'FaceColor','none', ...
    'LineWidth',1);

bar(2,mean(y,"omitnan"),0.6, ...
    'EdgeColor','#a6dba0', ...
    'FaceColor','none', ...
    'LineWidth',1);

fill_color = [0.9,0.9,0.9];

scatter(1*ones(size(x)),x,100, ...
    'MarkerFaceColor','#c2a5cf', ...
    'MarkerEdgeColor','k', ...
    'LineWidth',0.1);

scatter(2*ones(size(y)),y,100, ...
    'MarkerFaceColor','#a6dba0', ...
    'MarkerEdgeColor','k', ...
    'LineWidth',0.1);

title(caption)

text(0.38,0.98,sprintf('P=%.2g', p), ...
    'FontSize',28, ...
    'Units','normalized')

yline(chance_perf_angle,'k--','LineWidth',1)

xlim([0.5 2.5])
ylim([0 0.5])

set(gca,'FontSize',32,'TickDir','out');

box off

xticks([1 2]);
xticklabels(xlabels)

ylabel(ylabels);

hoy = char(datetime('now','Format','yyyyMMdd'));

figname = [params.fd 'plots/' hoy 'p_angle_decoding'];

print(fig,figname,'-dpdf');

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

%% compare data to shuffled response. Sup. Fig. 6a,b
% edit to make all plots

% caption = 'Partner angle - leader';
% x = tbl_animals.p_corr_angle(strcmp(tbl_animals.role,'leader'));
% y = tbl_animals.p_corr_angle_shuf(strcmp(tbl_animals.role,'leader'));

% caption = 'Partner angle - follower';
% x = tbl_animals.p_corr_angle(strcmp(tbl_animals.role,'follower'));
% y = tbl_animals.p_corr_angle_shuf(strcmp(tbl_animals.role,'follower'));

% caption = 'Partner distance - leader';
% x = tbl_animals.p_corr_dist(strcmp(tbl_animals.role,'leader'));
% y = tbl_animals.p_corr_dist_shuf(strcmp(tbl_animals.role,'leader'));

caption = 'Partner distance - follower';
x = tbl_animals.p_corr_dist(strcmp(tbl_animals.role,'follower'));
y = tbl_animals.p_corr_dist_shuf(strcmp(tbl_animals.role,'follower'));

% YC091 and YC111 are not in a pair, in an older version of the script,
% they were excluded

xlabels = {'Data';'Shuffled'};
ylabels = 'Prop correct';

source_data = table( ...
    (1:length(x))', ...
    x, ...
    y, ...
    y - x, ...
    'VariableNames', ...
    {'AnimalIndex','Data','Shuffled','Difference_ShuffledMinusData'});

assignin('base','source_data',source_data);

data = [x y];
N = size(data,1);

[p,h,stats] = signrank(data(:,1),data(:,2),'tail','right');

signedrank_stat = NaN;
zval = NaN;

if isfield(stats,'signedrank')
    signedrank_stat = stats.signedrank;
end

if isfield(stats,'zval')
    zval = stats.zval;
end

fprintf('\n========================================\n')
fprintf('%s\n', caption)
fprintf('========================================\n')
fprintf('Test: paired Wilcoxon signed-rank test\n')
fprintf('Tail: right\n')
fprintf('N = %d\n', N)
fprintf('Data median = %.4f\n', median(x,'omitnan'))
fprintf('Shuffled median = %.4f\n', median(y,'omitnan'))
fprintf('Data mean = %.4f\n', mean(x,'omitnan'))
fprintf('Shuffled mean = %.4f\n', mean(y,'omitnan'))
fprintf('Mean difference (Data - Shuffled) = %.4f\n', mean(x-y,'omitnan'))
fprintf('Signed-rank statistic = %.4f\n', signedrank_stat)

if ~isnan(zval)
    fprintf('Z = %.4f\n', zval)
end

fprintf('P = %.6g\n', p)

stats_table = table( ...
    {caption}, ...
    {'paired signrank right-tailed'}, ...
    N, ...
    median(x,'omitnan'), ...
    median(y,'omitnan'), ...
    mean(x,'omitnan'), ...
    mean(y,'omitnan'), ...
    mean(x-y,'omitnan'), ...
    signedrank_stat, ...
    zval, ...
    p, ...
    'VariableNames', ...
    {'Comparison','Test','N', ...
    'MedianData','MedianShuffled', ...
    'MeanData','MeanShuffled','MeanDifference_DataMinusShuffled', ...
    'SignedRankStatistic','Z','PValue'});

assignin('base','stats_table',stats_table);

fig = figure('Position',[600 300 200 400]);
hold on;

plot([1 2],data', ...
    'LineWidth',1, ...
    'Color','k', ...
    'Marker','.', ...
    'MarkerSize',10);

title(caption)

text(0.38,0.98,sprintf('P=%.2g', p), ...
    'FontSize',28, ...
    'Units','normalized')

xlim([0.5 2.5])
ylim([0 0.52])
% ylim([0 0.33])

set(gca,'FontSize',32,'TickDir','out');

box off

xticks([1 2]);
xticklabels(xlabels)

ylabel(ylabels);

hoy = char(datetime('now','Format','yyyyMMdd'));

figname = [fd 'plots/' hoy 'p_data_vs_shuf_' caption];

print(fig,figname,'-dpdf');

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')