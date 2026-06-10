% ===== Base folder =====
fd = 'E:\Wulab Dropbox\Yuan\Yuan_manuscript_demo';

data_folder = fullfile(fd, 'data');
plot_root   = fullfile(fd, 'plots');

%% Plot 1: Individual mouse plots grouped by cage_num

source_data_individual = table();
stats_table_individual = table();

plot_folder = fullfile(plot_root, datestr(now, 'yyyymmdd'), 'ind_plots');  % today's date
if ~exist(plot_folder, 'dir')
    mkdir(plot_folder);
end

% Load the CSV file
phase4_data = readtable(fullfile(data_folder, 'processed_wins_phase4.csv'));
phase4_data.sex = string(phase4_data.sex);
phase4_data.mouse = string(phase4_data.mouse);
unique_cages = unique(phase4_data.cage_num);

day_threshold = 6;  % number of last days to include (last day = 0)

for cage_idx = 1:length(unique_cages)
    cage = unique_cages(cage_idx);

    % Filter data for this cage
    cage_data = phase4_data(phase4_data.cage_num == cage, :);
    sex = unique(cage_data.sex);

    % Apply day threshold: keep rel_date = 0, -1, ..., -(day_threshold-1)
    cage_data = cage_data(cage_data.rel_date >= -(day_threshold-1), :);

    % Skip if no data
    if isempty(cage_data)
        continue
    end

    % Sort so oldest -> newest (e.g., -5 ... 0)
    cage_data = sortrows(cage_data, 'rel_date');

    % Make x axis labels 1..day_threshold (last day becomes day_threshold)
    % Map each rel_date to x using: x = rel_date + day_threshold
    cage_data.x_day = cage_data.rel_date + day_threshold;

    % --- Determine plotting order by rank on the final day (rel_date == 0) ---
    final_day = cage_data(cage_data.rel_date == 0, :);
    
    % If some mice are missing rel_date==0, you can decide what to do; here we skip them
    mouse_rank_tbl = unique(final_day(:, {'mouse','rank'}), 'rows');
    
    % Sort by rank (adjust ascend/descend depending on how rank is defined)
    mouse_rank_tbl = sortrows(mouse_rank_tbl, 'rank', 'ascend');
    mice_in_cage = mouse_rank_tbl.mouse;      % Use this order for plotting

    T_source = table( ...
        repmat(cage,height(cage_data),1), ...
        repmat(string(sex(1)),height(cage_data),1), ...
        string(cage_data.mouse), ...
        cage_data.rel_date, ...
        cage_data.x_day, ...
        cage_data.win_count, ...
        cage_data.rank, ...
        'VariableNames', ...
        {'Cage','Sex','Mouse','RelDate','XDay','WinCount','Rank'});

    source_data_individual = [source_data_individual; T_source];

    for mi = 1:length(mice_in_cage)
        mouse_name = string(mice_in_cage(mi));
        mouse_data = cage_data(cage_data.mouse == mouse_name, :);

        T_stat = table( ...
            cage, ...
            string(sex(1)), ...
            mouse_name, ...
            height(mouse_data), ...
            mean(mouse_data.win_count,'omitnan'), ...
            median(mouse_data.win_count,'omitnan'), ...
            std(mouse_data.win_count,'omitnan'), ...
            min(mouse_data.win_count), ...
            max(mouse_data.win_count), ...
            'VariableNames', ...
            {'Cage','Sex','Mouse','NDays','MeanWinCount','MedianWinCount','SDWinCount','MinWinCount','MaxWinCount'});

        stats_table_individual = [stats_table_individual; T_stat];
    end

    % Extract mice name txt for saving
    mice_list = sort(mice_in_cage);
    txt = sprintf('%s-%s', mice_list{1}, mice_list{end}(3:end));
    
    % Create figure for this cage
    if cage_idx == 1
        fig = figure('Position', [100, 100, 450, 320]);
    else
        fig = figure('Position', [100, 100, 450, 320], 'Visible', 'off');
    end

    hold on;

    % Define colors and markers for up to 4 mice
    lineColor   = 'k';
    markers     = {'o','o','s','s'};
    faceColors  = {'k','w','k','w'};   % white, black, white, black
    edgeColor   = 'k';
    legend_entries = {};

    % Plot each mouse using x_day
    for mouse_idx = 1:length(mice_in_cage)
        mouse_name = mice_in_cage{mouse_idx};

        % Filter data for this specific mouse
        mouse_data = cage_data(strcmp(cage_data.mouse, mouse_name), :);

        if ~isempty(mouse_data)
            x = mouse_data.x_day;
            wins = mouse_data.win_count;

            plot(x, wins, ['-' markers{mouse_idx}], ...
                'Color', lineColor, ...
                'LineWidth', 1.5, ...
                'MarkerSize', 8, ...
                'MarkerEdgeColor', edgeColor, ...
                'MarkerFaceColor', faceColors{mouse_idx});

            legend_entries{end+1} = mouse_name; %#ok<SAGROW>
        end
    end

    % Format plot
    xlabel('Tube Test Days', 'FontSize', 10);
    ylabel('Tube Test Rank', 'FontSize', 10);
    title(sprintf('Win Count Across Days (%s) - %s', sex, txt), ...
        'FontSize', 14, 'FontWeight', 'bold');

    % X axis is always 1..day_threshold (even if some days missing)
    xlim([0.5 day_threshold + 0.5]);
    xticks(1:day_threshold);

    % Y axis formatting (0..3, no decimals + padding)
    yticks(0:3);
    ylim([-0.5 3.5]);

    ax = gca;
    ax.TickDir = 'out';
    ax.FontSize = 10;
    ax.TickLength = [0.01 0.01];   % smaller ticks (major, minor)
    ax.LineWidth = 1.5;    % thickness of the x/y axes
    ax.XColor = 'k';       % x-axis color
    ax.YColor = 'k';       % y-axis color
    ax.YTickLabel = {'4','3','2','1'};  % force labels to replace win_count = 0,1,2,3

    % % Legend outside top-right
    % lgd = legend(legend_entries, 'Location', 'northeastoutside');
    % lgd.Box = 'off';

    hold off;

    outname = fullfile(plot_folder, sprintf('win_count_phase4_%ddays_%s_%s.pdf', ...
        day_threshold, txt, sex));
    
    exportgraphics(fig, outname, 'ContentType', 'vector');
    fprintf('Saved: %s\n', outname);
end

assignin('base','source_data_individual',source_data_individual);
assignin('base','stats_table_individual',stats_table_individual);

fprintf('\n========================================\n')
fprintf('Individual mouse plots grouped by cage_num\n')
fprintf('========================================\n')
fprintf('N source rows = %d\n', height(source_data_individual))
fprintf('N summary rows = %d\n', height(stats_table_individual))
disp(stats_table_individual)

%% Cohort plot: average win_count across ALL cages
% grouped by final_rank_int (1..4) within each cage
% (uses rel_date where last day = 0)

source_data_cohort = table();
stats_table_cohort = table();

plot_folder = fullfile(plot_root, datestr(now, 'yyyymmdd'), 'cohort_plots');  % today's date
if ~exist(plot_folder, 'dir')
    mkdir(plot_folder);
end

day_threshold = 8;   % how many last days to include
sex_mode = 'all';   % change to 'all', 'M' or 'F' when needed

% mask for sex filtering
if strcmpi(sex_mode, 'all')
    sex_mask = true(height(phase4_data),1);
else
    sex_mask = strcmpi(string(phase4_data.sex), sex_mode);
end

% Make sure phase4_data has rel_date and final_rank_int already
if ~ismember('rel_date', phase4_data.Properties.VariableNames)
    error("phase4_data must have rel_date (last day = 0 for each cage) before running this block.");
end
if ~ismember('final_rank_int', phase4_data.Properties.VariableNames)
    error("phase4_data must have final_rank_int (1..4 within each cage) before running this block.");
end

% Keep last N days only & apply sex mask
cohort_data = phase4_data( ...
    sex_mask & phase4_data.rel_date >= -(day_threshold-1) & phase4_data.rel_date <= 0, :);

% Map rel_date -> x_day = 1..day_threshold (so rel_date=-(N-1)->1, rel_date=0->N)
cohort_data.x_day = cohort_data.rel_date + day_threshold;

% Ensure rank is numeric
cohort_data.final_rank_int = double(cohort_data.final_rank_int);

source_data_cohort = table( ...
    cohort_data.cage_num, ...
    string(cohort_data.mouse), ...
    string(cohort_data.sex), ...
    cohort_data.rel_date, ...
    cohort_data.x_day, ...
    cohort_data.final_rank_int, ...
    cohort_data.win_count, ...
    'VariableNames', ...
    {'Cage','Mouse','Sex','RelDate','XDay','FinalRank','WinCount'});

% Aggregate mean + SEM across all cages (and mice) for each (rank, day)
cohort_data.group_key = categorical(string(cohort_data.final_rank_int) + "_" + string(cohort_data.x_day));
[group_ids, group_levels] = findgroups(cohort_data.group_key);

mean_win = splitapply(@(x) mean(x, 'omitnan'), cohort_data.win_count, group_ids);
sem_win  = splitapply(@(x) std(x, 'omitnan') / sqrt(sum(~isnan(x))), cohort_data.win_count, group_ids);
sd_win   = splitapply(@(x) std(x, 'omitnan'), cohort_data.win_count, group_ids);
n_win    = splitapply(@(x) sum(~isnan(x)), cohort_data.win_count, group_ids);

% Parse group_levels back into rank/day
group_levels_str = string(group_levels);
tokens = split(group_levels_str, "_");
rank_vals = str2double(tokens(:,1));
day_vals  = str2double(tokens(:,2));

summary_tbl = table(rank_vals, day_vals, mean_win, sd_win, sem_win, n_win, ...
    'VariableNames', {'final_rank_int','x_day','mean_win','sd_win','sem_win','n'});

stats_table_cohort = summary_tbl;

assignin('base','source_data_cohort',source_data_cohort);
assignin('base','stats_table_cohort',stats_table_cohort);

fprintf('\n========================================\n')
fprintf('Cohort plot: average win_count across all cages\n')
fprintf('========================================\n')
fprintf('sex_mode = %s\n', sex_mode)
fprintf('day_threshold = %d\n', day_threshold)
disp(stats_table_cohort)

%--------------------------------------------------
% Plot
%--------------------------------------------------
figure('Position', [100, 100, 480, 300]); hold on;

% Define colors and markers for up to 4 mice
lineColor   = 'k';
markers     = {'o','o','s','s'};
faceColors  = {'k','w','k','w'};   % white, black, white, black
edgeColor   = 'k';
legend_entries = {};

for r = 1:4 % loop through each rank
    this_rank = summary_tbl(summary_tbl.final_rank_int == r, :);
    if isempty(this_rank)
        continue
    end

    % Make sure days are ordered
    this_rank = sortrows(this_rank, 'x_day');

    % Plot mean line with markers
    plot(this_rank.x_day, this_rank.mean_win, ...
        ['-' markers{r}], ...
        'Color', lineColor, ...
        'LineWidth', 1.5, ...
        'MarkerSize', 8, ...
        'MarkerFaceColor', faceColors{r});

    errorbar(this_rank.x_day, this_rank.mean_win, this_rank.sem_win, ...
        'LineStyle', 'none', 'Color', lineColor, 'LineWidth', 1.5, ...
        'HandleVisibility', 'off');

    legend_entries{end+1} = sprintf('Final rank %d', r); %#ok<SAGROW>
end

xlabel('Day', 'FontSize', 10);
ylabel('Mean Win Count', 'FontSize', 10);
title(sprintf('Cohort Win Count (last %d days of Phase4) - %s', day_threshold, sex_mode), ...
    'FontSize', 14, 'FontWeight', 'bold');

xlim([0.5 day_threshold + 0.5]);
xticks(1:day_threshold);

yticks(0:3);
ylim([-0.5 3.5]);     % gaps top/bottom like your example

ax = gca;
ax.TickDir = 'out';
ax.FontSize = 10;
ax.TickLength = [0.01 0.01];   % smaller ticks (major, minor)
ax.LineWidth = 1.5;    % thickness of the x/y axes
ax.XColor = 'k';       % x-axis color
ax.YColor = 'k';       % y-axis color

lgd = legend(legend_entries, 'Location', 'northeastoutside');
lgd.Box = 'off';

hold off;

outname = fullfile(plot_folder, sprintf('cohort_win_count_by_final_rank_last_%d_days_%s.png', day_threshold, sex_mode));
saveas(gcf, outname);
fprintf('Saved: %s\n', outname);

%% Cohort trajectory plot - per-cage last N days, grouped by prev-day rank
% - Window is last N days PER CAGE (anchored to each cage's last day)
% - Days renumbered to 1..N within each cage window (oldest -> newest)
% - Day 1: groups are defined by integer within-cage rank (1..4) -> means exactly 1..4
% - Days 2..N: for animals in prev-day group r, compute CURRENT-day average rank position (tiedrank)
% - Optional sex filtering (applied to plotted animals; ranks computed within cage/day)

source_data_prevday = table();
stats_table_prevday = table();

plot_folder = fullfile(plot_root, datestr(now, 'yyyymmdd'), 'cohort_plots');  % today's date
if ~exist(plot_folder, 'dir')
    mkdir(plot_folder);
end

day_threshold = 6;      % last N days per cage (anchored to each cage's last day)
sex_mode = 'F';       % 'all', 'M', 'F'

% ---- checks / types
req = {'cage_num','mouse','win_count','rel_date','sex'};
miss = setdiff(req, phase4_data.Properties.VariableNames);
if ~isempty(miss), error("Missing columns: %s", strjoin(miss,", ")); end
phase4_data.mouse = string(phase4_data.mouse);
phase4_data.sex   = string(phase4_data.sex);

% ---- helpers
keepSex = @(sex) strcmpi(sex_mode,'all') | strcmpi(sex,sex_mode);

% ---- build baseline+transitions in one table: (day, prev_rank_group, rank_pos)
rows = table();

for c = unique(phase4_data.cage_num).'
    T = phase4_data(phase4_data.cage_num==c, :);
    days = sort(unique(T.rel_date));
    if numel(days) < day_threshold, continue; end   % Drop the cage that doesn't have enough days for day_threshold
    days = days(end-day_threshold+1:end);                  % last N (oldest->newest)

    % precompute ranks each day
    D = cell(day_threshold,1);                             % each cell: table(mouse,sex,rank_avg,rank_int)
    ok = true;
    for d = 1:day_threshold
        td = T(T.rel_date==days(d), :);
        [~,ia] = unique(td.mouse,'stable'); td = td(ia,:);
        if height(td) < 4, ok=false; break; end
        td = td(1:4,:);

        wins = td.win_count;
        rAvg = tiedrank(-wins);                            % average rank positions (ties fractional)

        % integer rank groups (1..4): sort by win desc then mouse asc
        S = table(string(td.mouse), wins, string(td.sex), rAvg, ...
            'VariableNames', {'mouse','win','sex','rank_avg'});
        S = sortrows(S, {'win','mouse'}, {'descend','ascend'});
        S.rank_int = (1:height(S)).';

        D{d} = S(:, {'mouse','sex','rank_avg','rank_int'});
    end
    if ~ok, continue; end

    % Day 1 baseline: rank_pos = rank_int (exact 1..4)
    d1 = D{1};
    k1 = keepSex(d1.sex);
    if any(k1)
        T_add = table( ...
            repmat(c,sum(k1),1), ...
            d1.mouse(k1), ...
            d1.sex(k1), ...
            ones(sum(k1),1), ...
            d1.rank_int(k1), ...
            d1.rank_int(k1), ...
            'VariableNames', ...
            {'cage_num','mouse','sex','day','prev_rank_group','rank_pos'});
        rows = [rows; T_add];
    end

    % Days 2..N transitions: group by prev-day rank_int, outcome = current-day rank_avg
    for d = 2:day_threshold
        prev = D{d-1}; curr = D{d};
        [cm, ip, ic] = intersect(prev.mouse, curr.mouse, 'stable');
        if numel(cm) < 4, continue; end

        prevG = prev.rank_int(ip);
        currP = curr.rank_avg(ic);                         % current-day average rank position
        currS = curr.sex(ic);
        currM = curr.mouse(ic);

        k = keepSex(currS);
        if any(k)
            T_add = table( ...
                repmat(c,sum(k),1), ...
                currM(k), ...
                currS(k), ...
                repmat(d,sum(k),1), ...
                prevG(k), ...
                currP(k), ...
                'VariableNames', ...
                {'cage_num','mouse','sex','day','prev_rank_group','rank_pos'});
            rows = [rows; T_add];
        end
    end
end

if isempty(rows), error("No data after filtering. Check day_threshold / sex_mode / missing mice."); end

source_data_prevday = rows;

% ---- aggregate mean ± SEM by (prev_rank_group, day)
[g, grpR, grpD] = findgroups(rows.prev_rank_group, rows.day);
mean_rankpos = splitapply(@(x) mean(x,'omitnan'), rows.rank_pos, g);
sem_rankpos  = splitapply(@(x) std(x,'omitnan')/sqrt(sum(isfinite(x))), rows.rank_pos, g);
sd_rankpos   = splitapply(@(x) std(x,'omitnan'), rows.rank_pos, g);
n_obs        = splitapply(@(x) sum(isfinite(x)), rows.rank_pos, g);

summary_tbl = table(grpR, grpD, mean_rankpos, sd_rankpos, sem_rankpos, n_obs, ...
    'VariableNames', {'prev_rank_group','day','mean_rankpos','sd_rankpos','sem_rankpos','n'});

stats_table_prevday = summary_tbl;

assignin('base','source_data_prevday',source_data_prevday);
assignin('base','stats_table_prevday',stats_table_prevday);

fprintf('\n========================================\n')
fprintf('Cohort trajectory plot grouped by prev-day rank\n')
fprintf('========================================\n')
fprintf('sex_mode = %s\n', sex_mode)
fprintf('day_threshold = %d\n', day_threshold)
fprintf('N source rows = %d\n', height(source_data_prevday))
disp(stats_table_prevday)

% -------- plot

% color theme
sexes = {'female'; 'male'};

fill_colors = [239,154,154;   % female fill
               129,212,250] / 255;   % male fill

line_colors = [183, 28, 28;   % female line
                1, 87,155] / 255;    % male line

fig = figure('Position',[100 100 450 320]);  hold on;

markers = {'o','o','s','s'};
faces   = {'w','k','w','k'};  % empty, filled, empty, filled
legend_entries = {};

% ---- choose color scheme based on sex_mode
use_sex_colors = ~strcmpi(sex_mode, 'all');

if use_sex_colors
    if strcmpi(sex_mode, 'female') || strcmpi(sex_mode, 'F')
        ci = 1;
    elseif strcmpi(sex_mode, 'male') || strcmpi(sex_mode, 'M')
        ci = 2;
    else
        error('Unknown sex_mode: %s', sex_mode);
    end

    base_line_color = line_colors(ci, :);
    base_fill_color = fill_colors(ci, :);
else
    base_line_color = 'k';   % unchanged behavior for 'all'
    base_fill_color = [0 0 0];
end

for r = 1:4
    tr = summary_tbl(summary_tbl.prev_rank_group == r, :);
    if isempty(tr), continue; end
    tr = sortrows(tr, 'day');

    % error bars
    errorbar(tr.day, tr.mean_rankpos, tr.sem_rankpos, ...
        'LineStyle','none', ...
        'Color', base_line_color, ...
        'LineWidth',1.5, ...
        'HandleVisibility','off');

    % marker face color logic (rank-based fill stays intact)
    if strcmp(faces{r}, 'k')
        mface = base_fill_color;
    else
        mface = 'w';
    end

    plot(tr.day, tr.mean_rankpos, ['-' markers{r}], ...
        'Color', base_line_color, ...
        'LineWidth',1.5, ...
        'MarkerSize',8, ...
        'MarkerEdgeColor', base_line_color, ...
        'MarkerFaceColor', mface);

    legend_entries{end+1} = sprintf('Prev-day rank %d', r); %#ok<SAGROW>
end

xlim([0.5 day_threshold + 0.5]);
xticks(1:day_threshold);
ylim([0.5 4.5]); yticks(1:4); set(gca,'YDir','reverse');
xlabel('Tube Test Days');
ylabel('Tube Test Rank');
title(sprintf('Rank trajectory by prev-day rank (%d days) - %s', day_threshold, sex_mode));
% legend(legend_entries,'Location','northeastoutside'); box off; grid off; hold off;

ax = gca;
ax.TickDir = 'out';
ax.FontSize = 10;
ax.TickLength = [0.01 0.01];   % smaller ticks (major, minor)
ax.LineWidth = 1.5;    % thickness of the x/y axes
ax.XColor = 'k';       % x-axis color
ax.YColor = 'k';       % y-axis color

outname = fullfile(plot_folder, sprintf('cohort_rankpos_prevday_rank_last_%d_days_%s.pdf', day_threshold, sex_mode));
exportgraphics(fig, outname, 'ContentType', 'vector');

% saveas(gcf, outname);
fprintf('Saved: %s\n', outname);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data_individual\n')
fprintf('stats_table_individual\n')
fprintf('source_data_cohort\n')
fprintf('stats_table_cohort\n')
fprintf('source_data_prevday\n')
fprintf('stats_table_prevday\n')