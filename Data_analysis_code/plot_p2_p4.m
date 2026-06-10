function plot_p2_p4(btable, p2_metrics, fd, alpha)

if nargin < 4 || isempty(alpha); alpha = 0.05; end
if nargin < 3 || isempty(fd); error("Please provide fd so I can save PDFs."); end

p2_metrics = string(p2_metrics);
fd = char(fd);

req = ["pairID","sex","P_led_phase4","P_init_phase4"];
for r = req
    if ~ismember(r, string(btable.Properties.VariableNames))
        error("btable must contain column '%s'.", r);
    end
end

plots_root = fullfile(fd, 'plots');
if ~exist(plots_root, 'dir'); mkdir(plots_root); end

fill_colors = [239,154,154;129,212,250]/255;
edge_colors = [183,28,28;1,87,155]/255;

clr_female_fill = fill_colors(1,:);
clr_male_fill   = fill_colors(2,:);
clr_female_edge = edge_colors(1,:);
clr_male_edge   = edge_colors(2,:);

PT_SIZE = 45;
JITTER  = 0.08;
BAR_W   = 0.60;
BAR_LW  = 1.8;
ERR_LW  = 1.2;
FIG_POS = [600 300 200 400];

pairID_raw = btable.pairID;
if iscategorical(pairID_raw) || isstring(pairID_raw)
    pairID = double(categorical(pairID_raw));
else
    pairID = double(pairID_raw);
end

sex = lower(strtrim(string(btable.sex)));

is_leader_all    = double(btable.P_led_phase4)  > 0.5;
is_initiator_all = double(btable.P_init_phase4) > 0.5;

fprintf('\n========== plot_p2_p4 ==========\n');
fprintf('Plots saved to: %s\n', plots_root);
fprintf('Statistics:\n');
fprintf('1. Sex comparison: female vs male, ranksum\n');
fprintf('2. Role comparison: all sex pooled, paired signrank\n');

source_data = table();
source_data_paired = table();

stats_table = table( ...
    strings(0,1), strings(0,1), strings(0,1), strings(0,1), ...
    nan(0,1), nan(0,1), nan(0,1), nan(0,1), nan(0,1), strings(0,1), ...
    'VariableNames', ...
    {'Metric','Test','Comparison','Group', ...
    'N','MedianA','MedianB','Statistic','PValue','Note'} );

for k = 1:numel(p2_metrics)

    metric = p2_metrics(k);

    if ~ismember(metric, string(btable.Properties.VariableNames))
        warning("Metric '%s' not found, skipped.", metric);
        continue;
    end

    y = double(btable.(metric));
    safe_metric = regexprep(char(metric), '[^\w\-]', '_');

    fprintf('\n========================================\n')
    fprintf('Metric: %s\n', metric)
    fprintf('========================================\n')

    y_f = y(sex == "female");
    y_f = y_f(~isnan(y_f));

    y_m = y(sex == "male");
    y_m = y_m(~isnan(y_m));

    T_sex_source = table( ...
        repmat(metric,length(y),1), ...
        sex(:), ...
        y(:), ...
        repmat("SexComparison",length(y),1), ...
        'VariableNames', ...
        {'Metric','Sex','Value','AnalysisType'});

    source_data = [source_data; T_sex_source];

    p_sex = NaN;
    stat_sex = NaN;
    note_sex = "";

    if numel(y_m) >= 3 && numel(y_f) >= 3
        [p_sex,~,statsSex] = ranksum(y_m, y_f);
        if isfield(statsSex,'ranksum')
            stat_sex = statsSex.ranksum;
        end
    else
        note_sex = "n<3 in one sex; ranksum skipped";
    end

    T_sex = table( ...
        metric, ...
        "ranksum", ...
        "male vs female", ...
        "all", ...
        numel(y_m)+numel(y_f), ...
        median(y_m,"omitnan"), ...
        median(y_f,"omitnan"), ...
        stat_sex, ...
        p_sex, ...
        note_sex, ...
        'VariableNames', ...
        stats_table.Properties.VariableNames);

    stats_table = [stats_table; T_sex];

    fprintf('\nSex comparison\n')
    fprintf('Test: Wilcoxon rank-sum test\n')
    fprintf('N male = %d\n', numel(y_m))
    fprintf('N female = %d\n', numel(y_f))
    fprintf('Median male = %.4f\n', median(y_m,"omitnan"))
    fprintf('Median female = %.4f\n', median(y_f,"omitnan"))
    fprintf('RankSum statistic = %.4f\n', stat_sex)
    fprintf('P = %.6g\n', p_sex)

    if ~(isempty(y_f) && isempty(y_m))

        m_f   = mean(y_f, 'omitnan');
        m_m   = mean(y_m, 'omitnan');
        sem_f = std(y_f, 'omitnan') / sqrt(max(1, sum(~isnan(y_f))));
        sem_m = std(y_m, 'omitnan') / sqrt(max(1, sum(~isnan(y_m))));

        fig = figure('Position', FIG_POS, 'Color','w');
        ax = axes('Parent', fig); 
        hold(ax,'on');

        bar(ax, 1, m_f, BAR_W, ...
            'FaceColor','none', ...
            'EdgeColor','k', ...
            'LineWidth', BAR_LW, ...
            'HandleVisibility','off');

        bar(ax, 2, m_m, BAR_W, ...
            'FaceColor','none', ...
            'EdgeColor','k', ...
            'LineWidth', BAR_LW, ...
            'HandleVisibility','off');

        errorbar(ax, [1 2], [m_f m_m], [sem_f sem_m], ...
            'k.', ...
            'LineWidth', ERR_LW, ...
            'HandleVisibility','off');

        for i = 1:numel(y_f)
            scatter(ax, 1 + (rand-0.5)*2*JITTER, y_f(i), PT_SIZE, ...
                'MarkerFaceColor', clr_female_fill, ...
                'MarkerEdgeColor', clr_female_edge, ...
                'LineWidth', 0.8, ...
                'HandleVisibility','off');
        end

        for i = 1:numel(y_m)
            scatter(ax, 2 + (rand-0.5)*2*JITTER, y_m(i), PT_SIZE, ...
                'MarkerFaceColor', clr_male_fill, ...
                'MarkerEdgeColor', clr_male_edge, ...
                'LineWidth', 0.8, ...
                'HandleVisibility','off');
        end

        xlim(ax,[0.5 2.5]);
        xticks(ax,[1 2]);
        xticklabels(ax,{'Female','Male'});

        ylabel(ax, metric, 'Interpreter','none');
        title(ax, metric, 'Interpreter','none');

        box(ax,'off');
        set(ax,'FontSize',12,'TickDir','out');

        if ~isnan(p_sex)
            text(ax, 0.38, 0.98, sprintf('P=%.2g', p_sex), ...
                'Units','normalized', ...
                'FontSize', 18);
        else
            text(ax, 0.38, 0.98, 'P=NA', ...
                'Units','normalized', ...
                'FontSize', 18);
        end

        h_f = plot(ax, nan, nan, 'o', ...
            'MarkerFaceColor', clr_female_fill, ...
            'MarkerEdgeColor', clr_female_edge, ...
            'LineWidth',0.8, ...
            'MarkerSize',7);

        h_m = plot(ax, nan, nan, 'o', ...
            'MarkerFaceColor', clr_male_fill, ...
            'MarkerEdgeColor', clr_male_edge, ...
            'LineWidth',0.8, ...
            'MarkerSize',7);

        legend(ax, [h_f h_m], {'female','male'}, ...
            'Location','best', ...
            'Box','off');

        pdf_path = fullfile(plots_root, sprintf('sex_compare_%s.pdf', safe_metric));
        exportgraphics(fig, pdf_path, 'ContentType','vector');
        fprintf('Saved: %s\n', pdf_path);
        close(fig);
    end

    [yLeader, yFollower, sexLeader] = get_paired_values(pairID, y, sex, is_leader_all);

    pL = NaN;
    statL = NaN;
    noteL = "";

    if numel(yLeader) >= 3
        [pL,~,statsL] = signrank(yLeader, yFollower);
        if isfield(statsL,'signedrank')
            statL = statsL.signedrank;
        end
    else
        noteL = "pairs<3; signrank skipped";
    end

    T_lead = table( ...
        metric, ...
        "signrank", ...
        "Leader vs Follower", ...
        "all", ...
        numel(yLeader), ...
        median(yLeader,"omitnan"), ...
        median(yFollower,"omitnan"), ...
        statL, ...
        pL, ...
        noteL, ...
        'VariableNames', ...
        stats_table.Properties.VariableNames);

    stats_table = [stats_table; T_lead];

    fprintf('\nLeader vs Follower\n')
    fprintf('Test: paired Wilcoxon signed-rank test\n')
    fprintf('N pairs = %d\n', numel(yLeader))
    fprintf('Median Leader = %.4f\n', median(yLeader,"omitnan"))
    fprintf('Median Follower = %.4f\n', median(yFollower,"omitnan"))
    fprintf('Signed-rank statistic = %.4f\n', statL)
    fprintf('P = %.6g\n', pL)

    T_lead_source = table( ...
        repmat(metric,numel(yLeader),1), ...
        repmat("all",numel(yLeader),1), ...
        yLeader(:), ...
        yFollower(:), ...
        yFollower(:)-yLeader(:), ...
        repmat("LeaderVsFollower",numel(yLeader),1), ...
        'VariableNames', ...
        {'Metric','Group','ValueA','ValueB','Difference_BminusA','AnalysisType'});

    source_data_paired = [source_data_paired; T_lead_source];

    [yInitiator, yResponder, sexInitiator] = get_paired_values(pairID, y, sex, is_initiator_all);

    pI = NaN;
    statI = NaN;
    noteI = "";

    if numel(yInitiator) >= 3
        [pI,~,statsI] = signrank(yInitiator, yResponder);
        if isfield(statsI,'signedrank')
            statI = statsI.signedrank;
        end
    else
        noteI = "pairs<3; signrank skipped";
    end

    T_init = table( ...
        metric, ...
        "signrank", ...
        "Initiator vs Responder", ...
        "all", ...
        numel(yInitiator), ...
        median(yInitiator,"omitnan"), ...
        median(yResponder,"omitnan"), ...
        statI, ...
        pI, ...
        noteI, ...
        'VariableNames', ...
        stats_table.Properties.VariableNames);

    stats_table = [stats_table; T_init];

    fprintf('\nInitiator vs Responder\n')
    fprintf('Test: paired Wilcoxon signed-rank test\n')
    fprintf('N pairs = %d\n', numel(yInitiator))
    fprintf('Median Initiator = %.4f\n', median(yInitiator,"omitnan"))
    fprintf('Median Responder = %.4f\n', median(yResponder,"omitnan"))
    fprintf('Signed-rank statistic = %.4f\n', statI)
    fprintf('P = %.6g\n', pI)

    T_init_source = table( ...
        repmat(metric,numel(yInitiator),1), ...
        repmat("all",numel(yInitiator),1), ...
        yInitiator(:), ...
        yResponder(:), ...
        yResponder(:)-yInitiator(:), ...
        repmat("InitiatorVsResponder",numel(yInitiator),1), ...
        'VariableNames', ...
        {'Metric','Group','ValueA','ValueB','Difference_BminusA','AnalysisType'});

    source_data_paired = [source_data_paired; T_init_source];

    fig = figure('Position', FIG_POS, 'Color','w');
    ax = axes('Parent', fig); 
    hold(ax,'on');

    plot_two_group_paired(ax, yLeader, yFollower, sexLeader, ...
        clr_female_fill, clr_male_fill, ...
        clr_female_edge, clr_male_edge, ...
        {'Leader','Follower'}, metric, ...
        'Leadership', PT_SIZE);

    pdf_path2 = fullfile(plots_root, sprintf('p2_by_p4_leadership_%s_allsex.pdf', safe_metric));
    exportgraphics(fig, pdf_path2, 'ContentType','vector');
    close(fig);

    fig = figure('Position', FIG_POS, 'Color','w');
    ax = axes('Parent', fig); 
    hold(ax,'on');

    plot_two_group_paired(ax, yInitiator, yResponder, sexInitiator, ...
        clr_female_fill, clr_male_fill, ...
        clr_female_edge, clr_male_edge, ...
        {'Initiator','Responder'}, metric, ...
        'Initiatorship', PT_SIZE);

    pdf_path2 = fullfile(plots_root, sprintf('p2_by_p4_initiatorship_%s_allsex.pdf', safe_metric));
    exportgraphics(fig, pdf_path2, 'ContentType','vector');
    close(fig);

end

assignin('base','source_data',source_data);
assignin('base','source_data_paired',source_data_paired);
assignin('base','stats_table',stats_table);

out_xlsx = fullfile(fd, 'simple_stats_ranktests.xlsx');

sexSheet  = stats_table(stats_table.Test == "ranksum", :);
leadSheet = stats_table(stats_table.Test == "signrank" & stats_table.Comparison == "Leader vs Follower", :);
initSheet = stats_table(stats_table.Test == "signrank" & stats_table.Comparison == "Initiator vs Responder", :);

try
    if exist(out_xlsx, 'file')
        delete(out_xlsx);
    end

    writetable(stats_table, out_xlsx, 'Sheet', 'All');
    writetable(sexSheet, out_xlsx, 'Sheet', 'Sex_ranksum');
    writetable(leadSheet, out_xlsx, 'Sheet', 'Leadership_signrank');
    writetable(initSheet, out_xlsx, 'Sheet', 'Initiatorship_signrank');

    fprintf('\n[Export] Rank-test stats saved to: %s\n', out_xlsx);

catch ME
    warning("Failed to export stats to Excel: %s", ME.message);
end

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('source_data_paired\n')
fprintf('stats_table\n')

end

function [yA, yB, sexA] = get_paired_values(pairID, y, sex, isRoleA)

pairs = unique(pairID(~isnan(pairID)));

yA = [];
yB = [];
sexA = strings(0,1);

for i = 1:numel(pairs)

    pid = pairs(i);
    idx = pairID == pid;

    if sum(idx) ~= 2
        continue;
    end

    idxA = idx & isRoleA;

    if sum(idxA) ~= 1
        continue;
    end

    idxB = idx & ~isRoleA;

    ya = y(idxA);
    yb = y(idxB);

    if any(isnan([ya yb]))
        continue;
    end

    yA(end+1,1)   = ya;
    yB(end+1,1)   = yb;
    sexA(end+1,1) = sex(idxA);

end

end

function plot_two_group_paired(ax, yA, yB, sexA, ...
    female_fill, male_fill, female_edge, male_edge, ...
    xlabels, yLabel, ttl, PT_SIZE)

if isempty(yA) || isempty(yB)

    title(ax, sprintf('%s (no paired data)', ttl), 'Interpreter','none');
    axis(ax, 'off');

    return;
end

temp = [yA(:) yB(:)];
x = [1 2];

hold(ax,'on');

for i = 1:size(temp,1)

    if ~isempty(sexA) && sexA(i) == "female"
        c_line = female_fill;
        c_fill = female_fill;
        c_edge = female_edge;
    else
        c_line = male_fill;
        c_fill = male_fill;
        c_edge = male_edge;
    end

    plot(ax, x, temp(i,:), ...
        'LineWidth', 1.2, ...
        'Color', c_line);

    scatter(ax, 1, temp(i,1), PT_SIZE, ...
        'MarkerFaceColor', c_fill, ...
        'MarkerEdgeColor', c_edge, ...
        'LineWidth', 0.8);

    scatter(ax, 2, temp(i,2), PT_SIZE, ...
        'MarkerFaceColor', c_fill, ...
        'MarkerEdgeColor', c_edge, ...
        'LineWidth', 0.8);
end

y_med = median(temp, 'omitnan');

plot(ax, x, y_med, ...
    'LineWidth', 3, ...
    'Color', [0.2 0.2 0.2], ...
    'Marker','.', ...
    'MarkerSize', 16);

xlim(ax, [0.5 2.5]);

xticks(ax, [1 2]);
xticklabels(ax, xlabels);

ylabel(ax, yLabel, 'Interpreter','none');
title(ax, ttl, 'Interpreter','none');

box(ax, 'off');

set(ax, 'FontSize', 20, 'TickDir','out');

p = NaN;

if size(temp,1) >= 3
    p = signrank(temp(:,1), temp(:,2));
end

text(ax, 0.38, 0.98, sprintf('P=%.2g', p), ...
    'Units','normalized', ...
    'FontSize', 18);

end