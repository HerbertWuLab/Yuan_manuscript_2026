function plt_learning_curve_op_all(ltable, fd)
% plt_learning_curve_op_all
% Plot combined mean learning curve, mean ± SEM.
% Days with n < 2 pairs are omitted.
%
% Outputs to base workspace:
%   source_data
%   stats_table

plot_dir = fullfile(fd, 'plots');

if ~exist(plot_dir, 'dir')
    mkdir(plot_dir);
end

req_vars = {'pair','days','cp_rate'};

for i = 1:numel(req_vars)
    if ~ismember(req_vars{i}, ltable.Properties.VariableNames)
        error('ltable missing required variable: %s', req_vars{i});
    end
end

cp = ltable.cp_rate;

if nanmedian(cp) > 1
    warning('cp_rate median > 1; values look like percent. Please convert to [0,1] before calling.');
end

pairs = unique(ltable.pair);
nPairs = numel(pairs);
maxDay = max(ltable.days);

Y = nan(nPairs, maxDay);

source_data = table();

for i = 1:nPairs

    pr = pairs{i};
    idx = strcmp(ltable.pair, pr);

    d = ltable.days(idx);
    y = ltable.cp_rate(idx);

    [ud,~,g] = unique(d);
    y_mean = accumarray(g, y, [], @mean);

    Y(i, ud) = y_mean;

    T_source = table( ...
        repmat({pr},numel(ud),1), ...
        ud(:), ...
        y_mean(:), ...
        'VariableNames', ...
        {'Pair','Day','CpRate'});

    source_data = [source_data; T_source];

end

assignin('base','source_data',source_data);

x = 1:maxDay;

mu  = mean(Y, 1, 'omitnan');
n   = sum(~isnan(Y), 1);
sd  = std(Y, 0, 1, 'omitnan');
sem = sd ./ sqrt(max(n,1));

validDay = (n >= 2) & ~isnan(mu);

stats_table = table( ...
    x(:), ...
    n(:), ...
    mu(:), ...
    sd(:), ...
    sem(:), ...
    validDay(:), ...
    'VariableNames', ...
    {'Day','N','MeanCpRate','SD','SEM','IncludedInPlot'});

assignin('base','stats_table',stats_table);

fprintf('\n========================================\n')
fprintf('OP learning curve all mice\n')
fprintf('========================================\n')
fprintf('N pairs total = %d\n', nPairs)
fprintf('Max day = %d\n', maxDay)
fprintf('Days included in plot: %s\n', mat2str(x(validDay)))
fprintf('\nDay-level summary:\n')
disp(stats_table)

fig = figure('Color','w'); 
hold on;

plot(x(validDay), mu(validDay), '-', ...
    'Color', [0 0 0], ...
    'LineWidth', 3.5);

for k = find(validDay)
    if ~isnan(sem(k))
        line([x(k) x(k)], [mu(k)-sem(k) mu(k)+sem(k)], ...
            'Color', [0 0 0], ...
            'LineWidth', 1.4);
    end
end

xlabel('Day');
ylabel('cp\_rate');

xlim([1 maxDay]);
ylim([0 1]);

yticks(0:0.25:1);

box off;

set(gca,'TickDir','out','LineWidth',1.2);

title('OP learning curve (all mice mean \pm SEM)');

print(fig, fullfile(plot_dir, 'op_learning_curve_all_mean_sem.pdf'), ...
    '-dpdf', '-painters');

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end