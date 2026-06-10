%% Group average - Leader vs Follower (using rel_days_for, rel_days_rev, and rel_days_criterion)
%% Load data

fd = 'E:\Wulab Dropbox\Yuan\Yuan_manuscript_demo';

data_folder = fullfile(fd, 'data');
plot_root   = fullfile(fd, 'plots');

load(fullfile(data_folder, 'combined_ptables_withTT_onlyTTdays.mat'));
T = filtered_data;

T.date_num = cellfun(@str2double, T.date);

T = T(contains(T.ori_swap, 'original'), :);

MIN_PAIRS_THRESHOLD = 10;

plot_folder = fullfile(plot_root, datestr(now, 'yyyymmdd'), 'lead_foll');
if ~exist(plot_folder, 'dir')
    mkdir(plot_folder);
end

diary(fullfile(plot_folder, 'Group_average_Leader_vs_Follower.txt'));
diary on;

fprintf('========================================\n');
fprintf('Code executed on: %s\n', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
fprintf('========================================\n\n');

%% Step 1: Determine leader/follower for each pair based on last 3 days

unique_pairs = unique(T.pair);
pair_leadership = containers.Map();

inconsistent_pairs = 0;
tied_pairs = 0;

for p = 1:length(unique_pairs)
    pair_name = unique_pairs{p};
    pair_data = T(strcmp(T.pair, pair_name), :);
    
    last_3_data = pair_data(max(1, end-2):end, :);
    
    m1_leader_count = sum(strcmp(last_3_data.sLead, 'm1'));
    m2_leader_count = sum(strcmp(last_3_data.sLead, 'm2'));
    
    if m1_leader_count > 0 && m2_leader_count > 0
        inconsistent_pairs = inconsistent_pairs + 1;
        fprintf('Pair %s: m1 led %d days, m2 led %d days in last 3 days\n', ...
            pair_name, m1_leader_count, m2_leader_count);
    end
    
    if m1_leader_count > m2_leader_count
        pair_leadership(pair_name) = 'm1';
    elseif m2_leader_count > m1_leader_count
        pair_leadership(pair_name) = 'm2';
    else
        tied_pairs = tied_pairs + 1;
        fprintf('Pair %s: TIED - skipping\n', pair_name);
        continue;
    end
end

fprintf('\n=== Leadership Summary ===\n');
fprintf('Total pairs: %d\n', length(unique_pairs));
fprintf('Inconsistent: %d\n', inconsistent_pairs);
fprintf('Tied (skipped): %d\n', tied_pairs);
fprintf('Processed: %d\n', pair_leadership.Count);
fprintf('Threshold: %d pairs\n', MIN_PAIRS_THRESHOLD);

%% Step 1.5: Calculate criterion day for each pair using FILTERED data

fprintf('\n=== Calculating Criterion Days (using FILTERED data) ===\n');

criterion_day_map = containers.Map();
pairs_no_criterion = {};
pairs_2day_criterion = {};

unique_pairs_filtered = unique(T.pair);

for p = 1:length(unique_pairs_filtered)
    pair_name = unique_pairs_filtered{p};
    
    if ~isKey(pair_leadership, pair_name)
        fprintf('Pair %s: SKIPPED (tied leadership)\n', pair_name);
        continue;
    end
    
    pair_data = T(strcmp(T.pair, pair_name), :);
    
    [~, sort_idx] = sort(pair_data.date_num);
    pair_data = pair_data(sort_idx, :);
    
    cp_rates = pair_data.cp_rate;
    n_days = length(cp_rates);
    
    criterion_idx = NaN;
    used_3day = false;
    
    if n_days >= 3
        for i = 1:(n_days-2)
            if ~isnan(cp_rates(i)) && ~isnan(cp_rates(i+1)) && ~isnan(cp_rates(i+2))
                if cp_rates(i) >= 0.8 && cp_rates(i+1) >= 0.8 && cp_rates(i+2) >= 0.8
                    criterion_idx = i + 2;
                    used_3day = true;
                    break;
                end
            end
        end
    end
    
    if isnan(criterion_idx) && n_days >= 2
        for i = 1:(n_days-1)
            if ~isnan(cp_rates(i)) && ~isnan(cp_rates(i+1))
                if cp_rates(i) >= 0.8 && cp_rates(i+1) >= 0.8
                    criterion_idx = i + 1;
                    pairs_2day_criterion{end+1} = pair_name;
                    break;
                end
            end
        end
    end
    
    if isnan(criterion_idx)
        pairs_no_criterion{end+1} = pair_name;
        fprintf('Pair %s: NO CRITERION REACHED\n', pair_name);
        fprintf('  cp_rate values: ');
        for j = 1:length(cp_rates)
            fprintf('%.2f ', cp_rates(j));
        end
        fprintf('\n');
    else
        criterion_day_map(pair_name) = criterion_idx;
        if used_3day
            fprintf('Pair %s: Criterion at index %d using 3-day criterion (cp_rate = %.2f)\n', ...
                pair_name, criterion_idx, cp_rates(criterion_idx));
        else
            fprintf('Pair %s: Criterion at index %d using 2-day criterion (cp_rate = %.2f)\n', ...
                pair_name, criterion_idx, cp_rates(criterion_idx));
        end
    end
end

fprintf('\nPairs without criterion: %d\n', length(pairs_no_criterion));
fprintf('Pairs using 2-day criterion: %d\n', length(pairs_2day_criterion));

if ~isempty(pairs_2day_criterion)
    fprintf('  Pairs: ');
    for i = 1:length(pairs_2day_criterion)
        fprintf('%s ', pairs_2day_criterion{i});
    end
    fprintf('\n');
end

fprintf('Pairs with criterion: %d\n', criterion_day_map.Count);

%% Step 2: Calculate Leader vs Follower win_count on the criterion day

fprintf('\n=== Leader vs Follower win_count on CRITERION DAY ===\n');

pairs_with_criterion = keys(criterion_day_map);

leader_win_all = nan(numel(pairs_with_criterion),1);
follower_win_all = nan(numel(pairs_with_criterion),1);

valid_pairs = false(numel(pairs_with_criterion),1);
pair_sex = strings(numel(pairs_with_criterion),1);  
pair_id = strings(numel(pairs_with_criterion),1);
crit_date = strings(numel(pairs_with_criterion),1);
leader_side_all = strings(numel(pairs_with_criterion),1);

for k = 1:numel(pairs_with_criterion)
    pair_name = pairs_with_criterion{k};

    if ~isKey(pair_leadership, pair_name)
        continue
    end

    pair_data = T(strcmp(T.pair, pair_name), :);

    [~, sort_idx] = sort(pair_data.date_num);
    pair_data = pair_data(sort_idx, :);

    criterion_idx = criterion_day_map(pair_name);

    if isnan(criterion_idx) || criterion_idx < 1 || criterion_idx > height(pair_data)
        continue
    end

    row = pair_data(criterion_idx, :);

    pair_id(k) = string(pair_name);
    crit_date(k) = string(row.date);

    row_sex = upper(strtrim(string(row.sex)));

    if row_sex == ""
        continue
    end

    leader_side = pair_leadership(pair_name);

    w1 = row.win_count_m1;
    w2 = row.win_count_m2;

    if ~isfinite(w1) || ~isfinite(w2)
        continue
    end

    if strcmp(leader_side, 'm1')
        leader_win_all(k)   = w1;
        follower_win_all(k) = w2;
    else
        leader_win_all(k)   = w2;
        follower_win_all(k) = w1;
    end

    pair_sex(k) = row_sex;  
    leader_side_all(k) = string(leader_side);
    valid_pairs(k) = true;
    pair_id(k) = string(pair_name);
end

pair_id          = pair_id(valid_pairs);
crit_date        = crit_date(valid_pairs);
leader_win_all   = leader_win_all(valid_pairs);
follower_win_all = follower_win_all(valid_pairs);
pair_sex         = pair_sex(valid_pairs);
leader_side_all  = leader_side_all(valid_pairs);

fprintf('Pairs with criterion (map): %d\n', criterion_day_map.Count);
fprintf('Pairs plotted (valid wins): %d\n', numel(leader_win_all));

if numel(leader_win_all) < MIN_PAIRS_THRESHOLD
    fprintf('WARNING: Only %d pairs available (< %d threshold). Plot will still be made.\n', ...
        numel(leader_win_all), MIN_PAIRS_THRESHOLD);
end

mean_leader   = mean(leader_win_all,   'omitnan');
mean_follower = mean(follower_win_all, 'omitnan');

sem_leader    = std(leader_win_all,   'omitnan') / sqrt(sum(isfinite(leader_win_all)));
sem_follower  = std(follower_win_all, 'omitnan') / sqrt(sum(isfinite(follower_win_all)));

fprintf('Leader mean±SEM:   %.3f ± %.3f\n', mean_leader, sem_leader);
fprintf('Follower mean±SEM: %.3f ± %.3f\n', mean_follower, sem_follower);

summary_tbl = table(pair_id, pair_sex, crit_date, leader_side_all, leader_win_all, follower_win_all, ...
    'VariableNames', {'pair', 'sex', 'criterion_day', 'leader_side', 'leader_win', 'follower_win'});

summary_tbl = sortrows(summary_tbl, {'leader_win','follower_win'}, {'ascend','ascend'});

disp(summary_tbl)

summary_tbl(summary_tbl.sex == "M", :)

%% ---------------- Matrix visualization: Leader (x) vs Follower (y) on criterion day

sex_mode = 'all';

if strcmpi(sex_mode,'all')
    keep = true(size(pair_sex));
else
    keep = pair_sex == upper(string(sex_mode));
end

leader_win   = leader_win_all(keep);
follower_win = follower_win_all(keep);
pair_id_plot = pair_id(keep);
crit_date_plot = crit_date(keep);
pair_sex_plot = pair_sex(keep);
leader_side_plot = leader_side_all(keep);

edges = -0.5:1:3.5;

count_mat = histcounts2(leader_win, follower_win, edges, edges);

disp_mat = count_mat';

source_data_leader_vs_follower = table( ...
    pair_id_plot(:), ...
    pair_sex_plot(:), ...
    crit_date_plot(:), ...
    leader_side_plot(:), ...
    leader_win(:), ...
    follower_win(:), ...
    follower_win(:) - leader_win(:), ...
    'VariableNames', ...
    {'Pair','Sex','CriterionDay','LeaderSide','LeaderWin','FollowerWin','Difference_FollowerMinusLeader'});

source_data_matrix_counts = table();

for lx = 0:3
    for fy = 0:3
        T_cell = table( ...
            string(sex_mode), ...
            lx, ...
            fy, ...
            disp_mat(fy+1,lx+1), ...
            'VariableNames', ...
            {'SexMode','LeaderWin','FollowerWin','Count'});
        source_data_matrix_counts = [source_data_matrix_counts; T_cell];
    end
end

assignin('base','source_data_leader_vs_follower',source_data_leader_vs_follower);
assignin('base','source_data_matrix_counts',source_data_matrix_counts);

fprintf('\n========================================\n')
fprintf('Source data: Leader vs Follower criterion-day win count\n')
fprintf('========================================\n')
fprintf('sex_mode = %s\n', sex_mode)
fprintf('N pairs = %d\n', height(source_data_leader_vs_follower))
disp(source_data_leader_vs_follower)

figure('Position',[200 200 450 320]);

line_colors = [239,154,154;
    129, 212, 250]/255;

imagesc(0:3, 0:3, disp_mat);

for d = 0:3
    rectangle('Position',[d-0.5, d-0.5, 1, 1], ...
        'FaceColor','k', 'EdgeColor','k');
end

hold on;

for x = -0.5:1:3.5
    line([x x], [-0.5 3.5], 'Color','k', 'LineWidth',0.1);
end

for y = -0.5:1:3.5
    line([-0.5 3.5], [y y], 'Color','k', 'LineWidth',0.1);
end

hold off;

axis image;

set(gca,'YDir','normal', ...
        'TickDir','out', ...
        'Box','off');     

n = 256;

if strcmpi(sex_mode,'F')
    base = line_colors(1,:);
elseif strcmpi(sex_mode,'M')
    base = line_colors(2,:);
else
    base = [67 67 67] / 255;
end

cmap = [linspace(1, base(1), n)', ...
        linspace(1, base(2), n)', ...
        linspace(1, base(3), n)'];

colormap(cmap);

maxCount = max(disp_mat(:));
if maxCount == 0
    maxCount = 1;
end

clim([0 maxCount]);

cb = colorbar;
cb.Label.String = 'Number of Pairs';
cb.Ticks = 0:maxCount;

xlabel('Leader win count (criterion day)','FontSize',10);
ylabel('Follower win count (criterion day)','FontSize',10);

title(sprintf('Leader vs Follower Win Count (criterion day) - %s', sex_mode), ...
    'FontSize',12,'FontWeight','bold');

xticks(0:3); 
yticks(0:3);

xlim([-0.5 3.5]); 
ylim([-0.5 3.5]);

ax = gca;
ax.TickDir = 'out';
ax.FontSize = 10;
ax.TickLength = [0.01 0.01];
ax.LineWidth = 1;
ax.XColor = 'k';
ax.YColor = 'k';

cl = ax.CLim;
mid_val = mean(cl);

for x = 0:3
    for y = 0:3

        if x == y
            continue
        end

        val = disp_mat(y+1, x+1);

        if val >= mid_val
            txt_color = 'k';
        else
            txt_color = 'k';
        end

        text(x, y, sprintf('%d', val), ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'FontWeight','normal', ...
            'FontSize', 10, ...
            'Color', txt_color);
    end
end

outname = fullfile(plot_folder, sprintf('leader_vs_follower_matrix_%s.pdf', sex_mode));
exportgraphics(gcf, outname, 'ContentType', 'vector');
fprintf('Saved: %s\n', outname);

%% -------- Stats: Wilcoxon signed-rank test

[p_signrank,h_signrank,stats_signrank] = signrank(leader_win, follower_win);

signedrank_stat = NaN;
z_signrank = NaN;

if isfield(stats_signrank,'signedrank')
    signedrank_stat = stats_signrank.signedrank;
end

if isfield(stats_signrank,'zval')
    z_signrank = stats_signrank.zval;
end

fid = fopen(fullfile(plot_folder, sprintf('leader_vs_follower_wilcoxon_%s.txt', sex_mode)), 'w');

fprintf(fid, '\nWilcoxon signed-rank test (Leader vs Follower, paired):\n');
fprintf(fid, '  signed rank = %.1f\n', signedrank_stat);
if ~isnan(z_signrank)
    fprintf(fid, '  z = %.3f\n', z_signrank);
end
fprintf(fid, '  p = %.4f\n', p_signrank);

if h_signrank == 0
    fprintf(fid, '  Result: NOT significant (fail to reject H0)\n');
else
    fprintf(fid, '  Result: SIGNIFICANT difference\n');
end

fclose(fid);

%% -------- Stats: Wilcoxon rank-sum test

[p_ranksum,h_ranksum,stats_ranksum] = ranksum(leader_win, follower_win);

ranksum_stat = NaN;
z_ranksum = NaN;

if isfield(stats_ranksum,'ranksum')
    ranksum_stat = stats_ranksum.ranksum;
end

if isfield(stats_ranksum,'zval')
    z_ranksum = stats_ranksum.zval;
end

fid = fopen(fullfile(plot_folder, sprintf('leader_vs_follower_ranksum_%s.txt', sex_mode)), 'w');

fprintf(fid, '\nWilcoxon rank-sum test (Leader vs Follower, non-paired):\n');
fprintf(fid, '  rank sum = %.1f\n', ranksum_stat);
if ~isnan(z_ranksum)
    fprintf(fid, '  z = %.3f\n', z_ranksum);
end
fprintf(fid, '  p = %.4f\n', p_ranksum);

if h_ranksum == 0
    fprintf(fid, '  Result: NOT significant (fail to reject H0)\n');
else
    fprintf(fid, '  Result: SIGNIFICANT difference\n');
end

fclose(fid);

%% -------- Save stats table and print to command window

diff_win = follower_win - leader_win;

stats_table_leader_vs_follower = table( ...
    string(sex_mode), ...
    numel(leader_win), ...
    mean(leader_win,'omitnan'), ...
    mean(follower_win,'omitnan'), ...
    mean(diff_win,'omitnan'), ...
    median(leader_win,'omitnan'), ...
    median(follower_win,'omitnan'), ...
    median(diff_win,'omitnan'), ...
    std(leader_win,'omitnan'), ...
    std(follower_win,'omitnan'), ...
    std(diff_win,'omitnan'), ...
    std(leader_win,'omitnan')/sqrt(numel(leader_win)), ...
    std(follower_win,'omitnan')/sqrt(numel(follower_win)), ...
    std(diff_win,'omitnan')/sqrt(numel(diff_win)), ...
    signedrank_stat, ...
    z_signrank, ...
    p_signrank, ...
    ranksum_stat, ...
    z_ranksum, ...
    p_ranksum, ...
    'VariableNames', ...
    {'SexMode','N', ...
    'MeanLeaderWin','MeanFollowerWin','MeanDifference_FollowerMinusLeader', ...
    'MedianLeaderWin','MedianFollowerWin','MedianDifference_FollowerMinusLeader', ...
    'SDLeaderWin','SDFollowerWin','SDDifference', ...
    'SEMLeaderWin','SEMFollowerWin','SEMDifference', ...
    'SignedRankStatistic','SignedRankZ','SignedRankPValue', ...
    'RankSumStatistic','RankSumZ','RankSumPValue'});

assignin('base','stats_table_leader_vs_follower',stats_table_leader_vs_follower);

fprintf('\n========================================\n')
fprintf('Leader vs follower win count statistics\n')
fprintf('========================================\n')
fprintf('sex_mode = %s\n', sex_mode)
fprintf('N pairs = %d\n', numel(leader_win))
fprintf('Leader mean = %.4f, SEM = %.4f\n', ...
    mean(leader_win,'omitnan'), std(leader_win,'omitnan')/sqrt(numel(leader_win)))
fprintf('Follower mean = %.4f, SEM = %.4f\n', ...
    mean(follower_win,'omitnan'), std(follower_win,'omitnan')/sqrt(numel(follower_win)))
fprintf('Leader median = %.4f\n', median(leader_win,'omitnan'))
fprintf('Follower median = %.4f\n', median(follower_win,'omitnan'))
fprintf('Median difference follower - leader = %.4f\n', median(diff_win,'omitnan'))

fprintf('\nWilcoxon signed-rank test, paired:\n')
fprintf('Signed rank = %.4f\n', signedrank_stat)
if ~isnan(z_signrank)
    fprintf('Z = %.4f\n', z_signrank)
end
fprintf('P = %.6g\n', p_signrank)

fprintf('\nWilcoxon rank-sum test, non-paired:\n')
fprintf('Rank sum = %.4f\n', ranksum_stat)
if ~isnan(z_ranksum)
    fprintf('Z = %.4f\n', z_ranksum)
end
fprintf('P = %.6g\n', p_ranksum)

fprintf('\nSaved to base workspace:\n')
fprintf('source_data_leader_vs_follower\n')
fprintf('source_data_matrix_counts\n')
fprintf('stats_table_leader_vs_follower\n')

disp(stats_table_leader_vs_follower)

diary off;