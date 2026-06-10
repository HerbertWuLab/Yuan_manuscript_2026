function [fig_angle,fig_dist] = plt_svc_tuning_demo(mrtable,params)

fd = params.fd; 
role = params.role;
hoy = char(datetime('now','Format','yyyyMMdd'));

colors = get_colormap(role);

which2plot = params.which2plot; 
which_frames = params.which_frames;

n_bins_angle = params.n_bins_angle;
n_bins_dist = params.n_bins_dist;

max_dist = params.max_dist;
min_dist = params.min_dist;

pcut = params.pcut;
phase = params.phase;

switch role
    case 'leader'
        m_color = {'#c2a5cf';'#9970ab';'#311237'};
    case 'follower'
        m_color = {'#a6dba0';'#5aae61';'#092e19'};
end

sel_cells = mrtable.p_info<params.pcut & ...
            mrtable.p_corr<params.pcut & ...
            mrtable.p_coh<params.pcut;

mrtable_sel = mrtable(sel_cells,:);

source_data = table();
stats_table_binomial = table();
stats_table_ks = table();

fig_angle = figure('Position',[200 700 600 600]); 
pos1 = [0.1 0.35 0.8 0.5];
subplot('Position',pos1)

mrtable_sel_angle = mrtable_sel(mrtable_sel.p_angle<pcut,:);
spk_bin_angle = mrtable_sel_angle.spk_bin_angle;
spk_bin_angle_norm = spk_bin_angle ./ max(spk_bin_angle,[],2);

[~,idx_peak_angle] = max(spk_bin_angle_norm,[],2);
[~,idx_sort] = sort(idx_peak_angle);
spk_bin_angle_norm_sort = spk_bin_angle_norm(idx_sort,:);

imagesc(spk_bin_angle_norm_sort)

disp(['number of angle-tuned neurons is ' num2str(size(spk_bin_angle_norm_sort,1))])

colormap(colors)

cb = colorbar;
cb.TickDirection = 'out';
ylabel(cb,'Normalized FR')

box off
xticks([0.5 (n_bins_angle+1)/2 n_bins_angle+0.5])
xticklabels([])
ylabel('Cell no.');

caption = ['Angle tuning of social vector cells ' which2plot];
caption = strrep(caption,'_',' ');
title(caption);

set(gca,'FontSize',40,'TickDir','out')

pos2 = [0.1 0.15 0.72 0.15];
subplot('Position',pos2)

histogram(idx_peak_angle,0.5:n_bins_angle+0.5, ...
    'FaceColor',m_color{3}, ...
    'EdgeColor','none', ...
    'Normalization','probability')

hold on;

if strcmp(phase,'4a')

    yline(1/n_bins_angle,'k--','LineWidth',2)
    ylim([0 0.14])

elseif strcmp(phase,'4d')

    mrtable4a = load([fd 'Data/mrtable_4a_other_ego_both_outside_arrival_zone_svc_tuning.mat']).mrtable;

    sel_animals = ismember(mrtable4a.animal, ...
        {'YC069','YC070','YC071','YC072','YC073','YC074', ...
         'YC075','YC076','YC091','YC111','YC115','YC116'});

    sel_role = strcmp(mrtable4a.role,role);

    sel_cells4a = mrtable4a.p_info<params.pcut & ...
                  mrtable4a.p_corr<params.pcut & ...
                  mrtable4a.p_coh<params.pcut;

    mrtable4a_sel = mrtable4a(sel_animals & sel_role & sel_cells4a,:);

    mrtable4a_sel_angle = mrtable4a_sel(mrtable4a_sel.p_angle<pcut,:);

    spk_bin_angle4a = mrtable4a_sel_angle.spk_bin_angle;
    spk_bin_angle4a_norm = spk_bin_angle4a ./ max(spk_bin_angle4a,[],2);

    [~,idx_peak_angle4a] = max(spk_bin_angle4a_norm,[],2);

    counts4a = histcounts(idx_peak_angle4a,0.5:n_bins_angle+0.5);
    counts4a_prop = counts4a/sum(counts4a);

    binCenters = 1:n_bins_angle;

    b = bar(binCenters,-counts4a_prop, ...
        'FaceColor',m_color{1}, ...
        'EdgeColor','none');

    b.BarWidth = 1;

    yline(-1/n_bins_angle,'k--','LineWidth',2)

    [~,p_ks_angle,ks_stat_angle] = kstest2(idx_peak_angle4a,idx_peak_angle);

    fprintf('\n========================================\n')
    fprintf('Angle tuning KS test | %s | phase4a vs %s\n', role, phase)
    fprintf('KS statistic = %.4f\n', ks_stat_angle)
    fprintf('P = %.6g\n', p_ks_angle)

    T_ks_angle = table( ...
        {'Angle'}, ...
        {role}, ...
        {phase}, ...
        {'phase4a_vs_current'}, ...
        length(idx_peak_angle4a), ...
        length(idx_peak_angle), ...
        ks_stat_angle, ...
        p_ks_angle, ...
        'VariableNames', ...
        {'Measure','Role','Phase','Comparison', ...
        'NPhase4a','NCurrent','KSStatistic','PValue'});

    stats_table_ks = [stats_table_ks; T_ks_angle];

end

counts_angle = histcounts(idx_peak_angle,0.5:n_bins_angle+0.5);
n_angle = sum(counts_angle);
p0_angle = 1/n_bins_angle;

fprintf('\n========================================\n')
fprintf('Angle tuning binomial tests | %s | %s\n', role, phase)
fprintf('========================================\n')
fprintf('Null probability per bin = %.6f\n', p0_angle)
fprintf('N angle-tuned cells = %d\n', n_angle)

for bin_i = 1:n_bins_angle

    k = counts_angle(bin_i);

    p_right = 1 - binocdf(k-1,n_angle,p0_angle);
    p_left = binocdf(k,n_angle,p0_angle);
    p_two = min(1,2*min(p_left,p_right));

    fprintf('Angle bin %d: count = %d/%d, prop = %.4f, binomial p = %.6g\n', ...
        bin_i,k,n_angle,k/n_angle,p_two)

    T_binom = table( ...
        {'Angle'}, ...
        {role}, ...
        {phase}, ...
        bin_i, ...
        k, ...
        n_angle, ...
        k/n_angle, ...
        p0_angle, ...
        p_two, ...
        'VariableNames', ...
        {'Measure','Role','Phase','Bin','Count', ...
        'NCells','ObservedProp','NullProp','PValue'});

    stats_table_binomial = [stats_table_binomial; T_binom];

end

for c = 1:size(spk_bin_angle_norm_sort,1)

    T = table( ...
        repmat({'Angle'},n_bins_angle,1), ...
        repmat({role},n_bins_angle,1), ...
        repmat({phase},n_bins_angle,1), ...
        repmat(c,n_bins_angle,1), ...
        (1:n_bins_angle)', ...
        spk_bin_angle_norm_sort(c,:)', ...
        'VariableNames', ...
        {'Measure','Role','Phase','CellIndex','Bin','NormalizedFR'});

    source_data = [source_data; T];

end

box off
xlim([0.5 n_bins_angle+0.5])
xticks([0.5 (n_bins_angle+1)/2 n_bins_angle+0.5])
xticklabels([-180 0 180])
xlabel(['Head-other angle(' char(176) ')']);
ylabel('Prop')
set(gca,'FontSize',40,'TickDir','out')

figname = [fd '/plots/' hoy 'p_angle_tuning_' which2plot '_' which_frames];
print(fig_angle,figname,'-dpdf');

mrtable_sel_dist = mrtable_sel(mrtable_sel.p_info_dist<pcut,:);

fig_dist = figure('Position',[800 700 600 600]); 
pos1 = [0.1 0.35 0.8 0.5];
subplot('Position',pos1)

spk_bin_dist = mrtable_sel_dist.spk_bin_dist;
spk_bin_dist_norm = spk_bin_dist ./ max(spk_bin_dist,[],2);

[~,idx_peak_dist] = max(spk_bin_dist_norm,[],2);

sel_bins = idx_peak_dist<=n_bins_dist;

idx_peak_dist = idx_peak_dist(sel_bins);
spk_bin_dist_norm = spk_bin_dist_norm(sel_bins,1:n_bins_dist);

[~,idx_sort] = sort(idx_peak_dist);

spk_bin_dist_norm_sort = spk_bin_dist_norm(idx_sort,:);

imagesc(spk_bin_dist_norm_sort)

disp(['number of distance-tuned neurons is ' num2str(size(spk_bin_dist_norm_sort,1))])

colormap(colors)

cb = colorbar;
cb.TickDirection = 'out';
ylabel(cb,'Normalized FR')

box off
xticks([0.5 n_bins_dist+0.5])
xticklabels([])
ylabel('Cell no.');

caption = ['Distance tuning of social vector cells ' which2plot];
caption = strrep(caption,'_',' ');
title(caption);

set(gca,'FontSize',40,'TickDir','out')

pos2 = [0.1 0.15 0.72 0.15];
subplot('Position',pos2)
hold on;

histogram(idx_peak_dist,0.5:n_bins_dist+0.5, ...
    'FaceColor',m_color{3}, ...
    'EdgeColor','none', ...
    'Normalization','probability')

if strcmp(phase,'4a')

    ylim([0 0.32])
    yline(1/n_bins_dist,'k--','LineWidth',2)

elseif strcmp(phase,'4d')

    mrtable4a_sel_dist = mrtable4a_sel(mrtable4a_sel.p_info_dist<pcut,:);

    spk_bin_dist4a = mrtable4a_sel_dist.spk_bin_dist;
    spk_bin_dist4a_norm = spk_bin_dist4a ./ max(spk_bin_dist4a,[],2);

    [~,idx_peak_dist4a] = max(spk_bin_dist4a_norm,[],2);

    idx_peak_dist4a = idx_peak_dist4a(idx_peak_dist4a<=n_bins_dist);

    counts4a = histcounts(idx_peak_dist4a,0.5:n_bins_dist+0.5);
    counts4a_prop = counts4a/sum(counts4a);

    binCenters = 1:n_bins_dist;

    b = bar(binCenters,-counts4a_prop, ...
        'FaceColor',m_color{1}, ...
        'EdgeColor','none');

    b.BarWidth = 1;

    yline(-1/n_bins_dist,'k--','LineWidth',2)

    [~,p_ks_dist,ks_stat_dist] = kstest2(idx_peak_dist4a,idx_peak_dist);

    fprintf('\n========================================\n')
    fprintf('Distance tuning KS test | %s | phase4a vs %s\n', role, phase)
    fprintf('KS statistic = %.4f\n', ks_stat_dist)
    fprintf('P = %.6g\n', p_ks_dist)

    T_ks_dist = table( ...
        {'Distance'}, ...
        {role}, ...
        {phase}, ...
        {'phase4a_vs_current'}, ...
        length(idx_peak_dist4a), ...
        length(idx_peak_dist), ...
        ks_stat_dist, ...
        p_ks_dist, ...
        'VariableNames', ...
        {'Measure','Role','Phase','Comparison', ...
        'NPhase4a','NCurrent','KSStatistic','PValue'});

    stats_table_ks = [stats_table_ks; T_ks_dist];

end

counts_dist = histcounts(idx_peak_dist,0.5:n_bins_dist+0.5);
n_dist = sum(counts_dist);
p0_dist = 1/n_bins_dist;

fprintf('\n========================================\n')
fprintf('Distance tuning binomial tests | %s | %s\n', role, phase)
fprintf('========================================\n')
fprintf('Null probability per bin = %.6f\n', p0_dist)
fprintf('N distance-tuned cells = %d\n', n_dist)

for bin_i = 1:n_bins_dist

    k = counts_dist(bin_i);

    p_right = 1 - binocdf(k-1,n_dist,p0_dist);
    p_left = binocdf(k,n_dist,p0_dist);
    p_two = min(1,2*min(p_left,p_right));

    fprintf('Distance bin %d: count = %d/%d, prop = %.4f, binomial p = %.6g\n', ...
        bin_i,k,n_dist,k/n_dist,p_two)

    T_binom = table( ...
        {'Distance'}, ...
        {role}, ...
        {phase}, ...
        bin_i, ...
        k, ...
        n_dist, ...
        k/n_dist, ...
        p0_dist, ...
        p_two, ...
        'VariableNames', ...
        {'Measure','Role','Phase','Bin','Count', ...
        'NCells','ObservedProp','NullProp','PValue'});

    stats_table_binomial = [stats_table_binomial; T_binom];

end

for c = 1:size(spk_bin_dist_norm_sort,1)

    T = table( ...
        repmat({'Distance'},n_bins_dist,1), ...
        repmat({role},n_bins_dist,1), ...
        repmat({phase},n_bins_dist,1), ...
        repmat(c,n_bins_dist,1), ...
        (1:n_bins_dist)', ...
        spk_bin_dist_norm_sort(c,:)', ...
        'VariableNames', ...
        {'Measure','Role','Phase','CellIndex','Bin','NormalizedFR'});

    source_data = [source_data; T];

end

box off
xlim([0.5 n_bins_dist+0.5])
xticks([0.5 n_bins_dist+0.5])
xticklabels([min_dist max_dist])
xlabel('Distance from self (cm)');
ylabel('Prop')
set(gca,'FontSize',40,'TickDir','out')

figname = [fd '/plots/' hoy 'p_dist_tuning_' which2plot '_' which_frames];
print(fig_dist,figname,'-dpdf');

source_name = ['source_data_' role '_' phase];
stats_binom_name = ['stats_table_binomial_' role '_' phase];
stats_ks_name = ['stats_table_ks_' role '_' phase];

assignin('base',source_name,source_data);
assignin('base',stats_binom_name,stats_table_binomial);
assignin('base',stats_ks_name,stats_table_ks);

fprintf('\nSaved to base workspace:\n')
fprintf('%s\n', source_name)
fprintf('%s\n', stats_binom_name)
fprintf('%s\n', stats_ks_name)

end