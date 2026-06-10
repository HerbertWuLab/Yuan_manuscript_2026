function plot_whoBecomesNewLeader(fd, note_table)
% which mouse will become the new leader. (reviewer's question)
%
% Outputs to base workspace:
%   source_data_whoBecomesNewLeader
%   stats_table_whoBecomesNewLeader

if nargin < 1 || isempty(fd)
    fd = pwd;
end

fd = char(fd);

if ~isempty(fd) && (fd(end) == filesep || fd(end) == '/' || fd(end) == '\')
    fd = fd(1:end-1);
end

[~, last_folder] = fileparts(fd);

if strcmpi(last_folder,'plots')
    plot_dir = fd;
else
    plot_dir = fullfile(fd,'plots');
end

if ~exist(plot_dir,'dir')
    mkdir(plot_dir);
end

source_data_whoBecomesNewLeader = table();
stats_table_whoBecomesNewLeader = table();

%% ===== build single_table =====

single_table = table( ...
    strings(0,1), ...
    nan(0,1), ...
    strings(0,1), ...
    nan(0,1), ...
    'VariableNames', {'mouse','p_ledBy','role_type','pairid'} );

for p = 1:height(note_table)

    cur_ptable = note_table.ptable{p};

    note_table.m1{p} = cur_ptable.m1{1};
    note_table.m2{p} = cur_ptable.m2{1};

    single_table.mouse{2*p-1} = cur_ptable.m1{1};
    single_table.mouse{2*p}   = cur_ptable.m2{1};

    single_table.p_ledBy(2*p-1,1) = note_table.p_ledBy_m1(p);
    single_table.p_ledBy(2*p,1)   = note_table.p_ledBy_m2(p);

    single_table.role_type{2*p-1} = note_table.role_type{p};
    single_table.role_type{2*p}   = note_table.role_type{p};

    single_table.pairid(2*p-1,1)  = p;
    single_table.pairid(2*p,1)    = p;

end

features = {'LL_pairing','FF_pairing'};

T = single_table;

if iscell(T.mouse)
    T.mouse = string(T.mouse);
end

if iscell(T.role_type)
    T.role_type = string(T.role_type);
end

T.p_ledBy = double(T.p_ledBy);

original_table = T(T.role_type=="original_pair", {'mouse','p_ledBy'});

original_table.Properties.VariableNames{'p_ledBy'} = 'origPled';

%% =========================================================
%% MAIN LOOP
%% =========================================================

for f = 1:numel(features)

    cur_feature = string(features{f});

    swap_table = T(T.role_type==cur_feature, {'mouse','p_ledBy'});

    if mod(height(swap_table),2)~=0
        error("%s 的行数不是偶数，无法两行一对", cur_feature);
    end

    leader_pled = [];
    foll_pled   = [];

    leader_mouse = strings(0,1);
    follower_mouse = strings(0,1);

    for p = 1:2:height(swap_table)

        m1 = swap_table.mouse(p);
        s1 = swap_table.p_ledBy(p);

        m2 = swap_table.mouse(p+1);
        s2 = swap_table.p_ledBy(p+1);

        idx1 = (original_table.mouse == m1);
        idx2 = (original_table.mouse == m2);

        if ~any(idx1) || ~any(idx2)
            continue;
        end

        o1 = original_table.origPled(idx1);
        o2 = original_table.origPled(idx2);

        if s1 > 0.5 && s2 < 0.5

            leader_pled(end+1,1) = o1;
            foll_pled(end+1,1)   = o2;

            leader_mouse(end+1,1) = m1;
            follower_mouse(end+1,1) = m2;

        elseif s2 > 0.5 && s1 < 0.5

            leader_pled(end+1,1) = o2;
            foll_pled(end+1,1)   = o1;

            leader_mouse(end+1,1) = m2;
            follower_mouse(end+1,1) = m1;

        else

            continue;

        end
    end

    %% =====================================================
    %% SOURCE DATA
    %% =====================================================

    T_source = table( ...
        repmat(cur_feature,numel(leader_pled),1), ...
        leader_mouse, ...
        follower_mouse, ...
        leader_pled, ...
        foll_pled, ...
        leader_pled - foll_pled, ...
        'VariableNames', ...
        {'Feature','NewLeaderMouse','NewFollowerMouse', ...
        'OriginalPled_NewLeader', ...
        'OriginalPled_NewFollower', ...
        'Delta'} );

    source_data_whoBecomesNewLeader = ...
        [source_data_whoBecomesNewLeader; T_source];

    %% =====================================================
    %% PLOT
    %% =====================================================

    fig = figure('Color','w','Position',[600 300 260 420]);

    hold on;

    ok = ~isnan(leader_pled) & ~isnan(foll_pled);

    n_ok = sum(ok);

    for i = 1:numel(leader_pled)

        plot([1 2], [leader_pled(i) foll_pled(i)], '-', ...
            'Color',[0.6 0.6 0.6], ...
            'LineWidth',1);

    end

    scatter(ones(size(leader_pled)), leader_pled, 4, 'filled', ...
        'MarkerFaceColor',[0.6 0.6 0.6], ...
        'MarkerEdgeColor','none');

    scatter(2*ones(size(foll_pled)), foll_pled, 4, 'filled', ...
        'MarkerFaceColor',[0.6 0.6 0.6], ...
        'MarkerEdgeColor','none');

    if n_ok >= 1

        medL = median(leader_pled(ok), 'omitnan');
        medF = median(foll_pled(ok),   'omitnan');

        col_med = [0.2 0.2 0.2];

        plot([1 2], [medL medF], '-', ...
            'Color', col_med, ...
            'LineWidth',2);

        scatter(1, medL, 8, 'filled', ...
            'MarkerFaceColor', col_med, ...
            'MarkerEdgeColor','none');

        scatter(2, medF, 8, 'filled', ...
            'MarkerFaceColor', col_med, ...
            'MarkerEdgeColor','none');
    end

    %% =====================================================
    %% STATS
    %% =====================================================

    if n_ok >= 2

        [pval,hval,stats_signrank] = signrank(leader_pled(ok),foll_pled(ok));

        signedrank_stat = NaN;
        zval = NaN;

        if isfield(stats_signrank,'signedrank')
            signedrank_stat = stats_signrank.signedrank;
        end

        if isfield(stats_signrank,'zval')
            zval = stats_signrank.zval;
        end

        ymax = max([leader_pled(ok); foll_pled(ok)]);

        yline_top = ymax + 0.05;

        plot([1 2], [yline_top yline_top], 'k', 'LineWidth',1);

        text(1.5, yline_top + 0.02, ...
            sprintf('p = %.3g (n=%d)', pval, n_ok), ...
            'HorizontalAlignment','center');

    else

        pval = NaN;
        hval = NaN;
        signedrank_stat = NaN;
        zval = NaN;

        text(0.05,0.95,sprintf('n=%d (no stats)', n_ok), ...
            'Units','normalized','FontSize',18);

    end

    %% =====================================================
    %% FIGURE STYLE
    %% =====================================================

    xlim([0.5 2.5]);

    xticks([1 2]);

    xticklabels({'new leader','new follower'});

    if cur_feature == "LL_pairing"

        ylim([0.5 1.05]);

        yticks(0.5:0.25:1.0);

    elseif cur_feature == "FF_pairing"

        ylim([0 0.55]);

        yticks(0:0.25:0.5);

    end

    ylabel('Original pair p\_ledBy');

    title(sprintf('%s: original p\\_ledBy (leader vs follower in swap pair) | n=%d', ...
        cur_feature, n_ok));

    grid off;

    set(gca,'FontSize',28,'TickDir','out');

    box off;

    %% =====================================================
    %% SAVE FIGURE
    %% =====================================================

    outFile = fullfile(plot_dir, ...
        sprintf('whoBecomesNewLeader_%s.pdf', cur_feature));

    set(fig,'PaperPositionMode','auto');

    print(fig, outFile, '-dpdf', '-vector');

    %% =====================================================
    %% STATS TABLE
    %% =====================================================

    T_stats = table( ...
        {char(cur_feature)}, ...
        n_ok, ...
        mean(leader_pled,'omitnan'), ...
        median(leader_pled,'omitnan'), ...
        mean(foll_pled,'omitnan'), ...
        median(foll_pled,'omitnan'), ...
        signedrank_stat, ...
        zval, ...
        pval, ...
        hval, ...
        'VariableNames', ...
        {'Feature','N', ...
        'LeaderMean','LeaderMedian', ...
        'FollowerMean','FollowerMedian', ...
        'SignedRankStatistic','Z','PValue','RejectH'});

    stats_table_whoBecomesNewLeader = ...
        [stats_table_whoBecomesNewLeader; T_stats];

    %% =====================================================
    %% COMMAND WINDOW
    %% =====================================================

    fprintf('\n========================================\n')
    fprintf('whoBecomesNewLeader | %s\n', char(cur_feature))
    fprintf('========================================\n')

    fprintf('N = %d\n', n_ok)

    fprintf('Leader:\n')
    fprintf('Mean = %.4f\n', mean(leader_pled,'omitnan'))
    fprintf('Median = %.4f\n\n', median(leader_pled,'omitnan'))

    fprintf('Follower:\n')
    fprintf('Mean = %.4f\n', mean(foll_pled,'omitnan'))
    fprintf('Median = %.4f\n\n', median(foll_pled,'omitnan'))

    fprintf('Signrank test\n')
    fprintf('Statistic = %.4f\n', signedrank_stat)

    if ~isnan(zval)
        fprintf('Z = %.4f\n', zval)
    end

    fprintf('P = %.6g\n', pval)
    fprintf('Reject H = %d\n', hval)

    fprintf('Saved figure: %s\n', outFile)

end

%% =========================================================
%% SAVE TO WORKSPACE
%% =========================================================

assignin('base', ...
    'source_data_whoBecomesNewLeader', ...
    source_data_whoBecomesNewLeader);

assignin('base', ...
    'stats_table_whoBecomesNewLeader', ...
    stats_table_whoBecomesNewLeader);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data_whoBecomesNewLeader\n')
fprintf('stats_table_whoBecomesNewLeader\n')

end