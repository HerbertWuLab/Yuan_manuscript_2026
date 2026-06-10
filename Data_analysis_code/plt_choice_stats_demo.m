function plt_choice_stats_demo(rtable, params)
% plot SI histogram for self choice
%
% Outputs to base workspace:
%   source_data
%   stats_table

fd = params.fd; 
hoy = char(datetime('now','Format','yyyyMMdd'));
pcut = params.pcut;
role = params.role;

if strcmp(role,'leader')
    m_colors = {'#c2a5cf','#969696'}; % leader
elseif strcmp(role,'follower')
    m_colors = {'#a6dba0','#969696'}; % follower
end

time_bin = params.time_bin;
bin_str = [time_bin{1} '-' time_bin{2}];

%% ---------- source data ----------
si = rtable.SI_self_choice;
pvals = rtable.p_self_choice;

sig_idx = pvals < pcut;

source_data = table( ...
    (1:length(si))', ...
    si, ...
    pvals, ...
    sig_idx, ...
    'VariableNames', ...
    {'CellIndex','SI_self_choice','PValue','Significant'});

assignin('base','source_data',source_data);

%% ---------- statistics ----------
n_cells = length(si);
n_sig = sum(sig_idx);

mean_si = mean(si,'omitnan');
median_si = median(si,'omitnan');
sd_si = std(si,'omitnan');
sem_si = sd_si / sqrt(sum(~isnan(si)));

mean_sig = mean(si(sig_idx),'omitnan');
median_sig = median(si(sig_idx),'omitnan');

fprintf('\n========================================\n')
fprintf('%s SI for self choice\n', role)
fprintf('========================================\n')

fprintf('N cells = %d\n', n_cells)
fprintf('N significant = %d\n', n_sig)
fprintf('Proportion significant = %.4f\n\n', n_sig/n_cells)

fprintf('All cells:\n')
fprintf('Mean SI = %.4f\n', mean_si)
fprintf('Median SI = %.4f\n', median_si)
fprintf('SD = %.4f\n', sd_si)
fprintf('SEM = %.4f\n\n', sem_si)

fprintf('Significant cells only:\n')
fprintf('Mean SI = %.4f\n', mean_sig)
fprintf('Median SI = %.4f\n', median_sig)

stats_table = table( ...
    {role}, ...
    n_cells, ...
    n_sig, ...
    n_sig/n_cells, ...
    mean_si, ...
    median_si, ...
    sd_si, ...
    sem_si, ...
    mean_sig, ...
    median_sig, ...
    'VariableNames', ...
    {'Role','NCells','NSignificant','PropSignificant', ...
    'MeanSI','MedianSI','SD_SI','SEM_SI', ...
    'MeanSI_Significant','MedianSI_Significant'});

assignin('base','stats_table',stats_table);

%% ---------- histogram ----------
fig = figure('Position',[600 300 400 400]);

edges = 0:0.02:1;

sig_si = si(sig_idx);

counts = histcounts(si,edges)/n_cells;
sig_counts = histcounts(sig_si,edges)/n_cells;

h(1) = histogram( ...
    'BinEdges',edges, ...
    'BinCounts',counts, ...
    'EdgeColor','k', ...
    'LineWidth',0.5, ...
    'FaceColor',m_colors{1}, ...
    'FaceAlpha',0.1);

hold on;

h(2) = histogram( ...
    'BinEdges',edges, ...
    'BinCounts',sig_counts, ...
    'EdgeColor','k', ...
    'LineWidth',0.5, ...
    'FaceColor',m_colors{1}, ...
    'FaceAlpha',1);

xlabel('SI')
ylabel('Proportion')

title([role ' SI for self choice (N=' num2str(n_cells) ' cells)'])

set(gca,'FontSize',24,'TickDir','out');

box off

ylim([0 0.13])

%% ---------- save ----------
figname = [fd '/plots/' hoy 'p_' role '_SI_self_choice_' bin_str];

fd_plot = [fd '/plots'];

if ~exist(fd_plot, 'dir')
    mkdir(fd_plot);
end

print(fig,figname,'-dpdf');

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end