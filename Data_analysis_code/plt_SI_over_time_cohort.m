function [fig,source_data,stats_table] = plt_SI_over_time_cohort(mrtable,params)
% plot population SI over time of cohorts

%% set parameters
fd = params.fd; 
alignBy = params.alignBy;
t_array_sel = params.t_array_sel;
n_frames = length(t_array_sel);
pcut = params.pcut;
hoy = char(datetime('now','Format','yyyyMMdd'));
role = params.role;
selective_only = params.selective_only;

switch role
    case 'both'
        mrtable_sel_role = mrtable;
    case 'leader'
        mrtable_sel_role = mrtable(strcmp(mrtable.role,'leader'),:);
    case 'follower'
        mrtable_sel_role = mrtable(strcmp(mrtable.role,'follower'),:);
end

if selective_only
    mrtable_sel_role = mrtable_sel_role(mrtable_sel_role.p_leader<pcut,:);
end

si_array = vertcat(mrtable_sel_role.si_array{:});
n_cells = height(mrtable_sel_role);

%% sort SI
[max_si_array,idx_peak] = max(abs(si_array),[],2);
idx_peak_array = sub2ind(size(si_array),(1:n_cells)',idx_peak);
max_si_array_abs = si_array(idx_peak_array);

si_array_plus = si_array(max_si_array_abs>0,:);
idx_peak_plus = idx_peak(max_si_array_abs>0);
[~,idx_sort_plus] = sort(idx_peak_plus);
si_array_plus_sorted = si_array_plus(idx_sort_plus,:);
n_cells_plus = size(si_array_plus_sorted,1);

si_array_minus = si_array(max_si_array_abs<0,:);
idx_peak_minus = idx_peak(max_si_array_abs<0);
[~,idx_sort_minus] = sort(idx_peak_minus);
si_array_minus_sorted = si_array_minus(idx_sort_minus,:);

si_array_sorted = [si_array_plus_sorted; si_array_minus_sorted];

%% ===== source data =====
source_data = table();

for c = 1:n_cells

    if c <= n_cells_plus
        peak_sign = {'positive'};
    else
        peak_sign = {'negative'};
    end

    T = table( ...
        repmat({role},n_frames,1), ...
        repmat(c,n_frames,1), ...
        repmat(peak_sign,n_frames,1), ...
        t_array_sel(:), ...
        (1:n_frames)', ...
        si_array_sorted(c,:)', ...
        'VariableNames', ...
        {'Role','SortedCellIndex','PeakSign','Time','FrameIndex','SI'});

    source_data = [source_data; T];

end

%% ===== stats table =====
mean_si = mean(si_array_sorted,1,'omitnan');
median_si = median(si_array_sorted,1,'omitnan');
sd_si = std(si_array_sorted,[],1,'omitnan');
sem_si = sd_si ./ sqrt(sum(~isnan(si_array_sorted),1));

stats_table = table( ...
    repmat({role},n_frames,1), ...
    t_array_sel(:), ...
    (1:n_frames)', ...
    mean_si(:), ...
    median_si(:), ...
    sd_si(:), ...
    sem_si(:), ...
    repmat(n_cells,n_frames,1), ...
    repmat(n_cells_plus,n_frames,1), ...
    repmat(n_cells-n_cells_plus,n_frames,1), ...
    'VariableNames', ...
    {'Role','Time','FrameIndex','MeanSI','MedianSI','SD_SI','SEM_SI', ...
    'NCells','NPositivePeak','NNegativePeak'});

fprintf('\n========================================\n')
fprintf('SI over time | %s\n', role)
fprintf('========================================\n')
fprintf('N cells = %d\n', n_cells)
fprintf('N positive peak cells = %d\n', n_cells_plus)
fprintf('N negative peak cells = %d\n', n_cells-n_cells_plus)
fprintf('Mean SI across all cells and time = %.4f\n', mean(si_array_sorted(:),'omitnan'))
fprintf('Median SI across all cells and time = %.4f\n', median(si_array_sorted(:),'omitnan'))
fprintf('\n========================================\n')
fprintf('SI over time | %s\n', role)
fprintf('========================================\n')

fprintf('N cells = %d\n', n_cells)
fprintf('N positive peak cells = %d\n', n_cells_plus)
fprintf('N negative peak cells = %d\n\n', n_cells-n_cells_plus)

fprintf('Global mean SI = %.4f\n', mean(si_array_sorted(:),'omitnan'))
fprintf('Global median SI = %.4f\n', median(si_array_sorted(:),'omitnan'))
fprintf('Global SD SI = %.4f\n', std(si_array_sorted(:),'omitnan'))

fprintf('\nPeak frame distribution:\n')
fprintf('Mean peak frame = %.2f\n', mean(idx_peak))
fprintf('Median peak frame = %.2f\n', median(idx_peak))

fprintf('\n')

%% plot SI
fig = figure('Position',[600 300 400 400],'Visible','on'); 

xrange = [1 n_frames];
yrange = [1 n_cells];

h = imagesc(xrange, yrange, si_array_sorted);

clim([-1 1])
colors = get_colormap('diverging');
colors = flipud(colors);
colormap(colors)

cb = colorbar;
cb.TickDirection = 'out';
cb.Ticks = [-1 0 1];
ylabel(cb,'Selectivity Index','FontSize',30)

set(gca,'YDir','normal','FontSize',30,'TickDir','out')

xticks(1:30:n_frames)
xticklabels(-2:3)

xlabel(['Frame from ' alignBy]);
ylabel('Cells (sorted)');

yticks(0:500:n_cells)

yline(n_cells_plus+0.5,'k','LineWidth',1.5)

box off

title(sprintf('Leadership selectivity %s',role))

figname = [fd '/plots/' hoy ...
    'p_leader_SI_over_time_alignBy_' alignBy '_' role ...
    '_sel_only=' num2str(selective_only)];

print(fig,figname,'-dpdf');

end