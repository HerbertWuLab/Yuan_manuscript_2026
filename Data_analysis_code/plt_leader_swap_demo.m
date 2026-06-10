function plt_leader_swap_demo(fd,original_pair,swapped_pair)
% persistence of roles after partner swapping
%
% Outputs to base workspace:
%   source_data_leader_swap
%   stats_table_leader_swap

source_data_leader_swap = table();
stats_table_leader_swap = table();

n_pairs = height(original_pair);

%% normalize
for p = 1:n_pairs
    ptable = original_pair.ptable{p};
    ledBy_sum = ptable.p_ledBy_m1 + ptable.p_ledBy_m2;
    ptable.p_ledBy_m1 = ptable.p_ledBy_m1./ledBy_sum;
    ptable.p_ledBy_m2 = ptable.p_ledBy_m2./ledBy_sum;
    original_pair.ptable{p} = ptable;
end

for p = 1:n_pairs
    ptable = swapped_pair.ptable{p};
    ledBy_sum = ptable.p_ledBy_m1 + ptable.p_ledBy_m2;
    ptable.p_ledBy_m1 = ptable.p_ledBy_m1./ledBy_sum;
    ptable.p_ledBy_m2 = ptable.p_ledBy_m2./ledBy_sum;
    swapped_pair.ptable{p} = ptable;
end

%% =========================================================
%% MAIN LOOP
%% =========================================================

for p = 1:n_pairs

    cur_pair = original_pair.original{p};
    ptable = original_pair.ptable{p};

    ledBy_sum = ptable.p_ledBy_m1 + ptable.p_ledBy_m2;

    ptable.p_ledBy_m1 = ptable.p_ledBy_m1./ledBy_sum;
    ptable.p_ledBy_m2 = ptable.p_ledBy_m2./ledBy_sum;

    ptable = ptable(ptable.cp_rate >= 0.8, :);

    if height(ptable) >= 3
        ptable_crit = ptable(1:3,:);
    else
        ptable_crit = ptable;
        disp([cur_pair ' does not have three sessions over criterion'])
    end

    if numel(unique(ptable_crit.sLead))==1

        lead_id = ptable_crit.sLead{1};
        lead_name = ptable_crit.(lead_id){1};

        original_pair.Lead{p} = lead_name;

        original_pair.p_ledBy_sLead(p) = ptable_crit.p_ledBy_sLead(end);

        original_pair.p_ledBy_sFoll(p) = ptable_crit.p_ledBy_sFoll(end);

    else

        fprintf('Use all well-trained session for original pair %s #%d!\n',cur_pair,p)

        ptable = ptable(~ismissing(string(ptable.sLead)),:);

        [uniqueStrings, ~, idx] = unique(ptable.sLead);

        counts = accumarray(idx, 1);

        [maxCount, maxIdx] = max(counts);

        totalCount = height(ptable);

        percentage = maxCount / totalCount;

        if percentage > 0.8

            lead_id = uniqueStrings{maxIdx};

            lead_name = ptable.(lead_id){1};

            original_pair.Lead{p} = lead_name;

            idx_end = find(strcmp(ptable.sLead,lead_id));

            original_pair.p_ledBy_sLead(p) = ptable.p_ledBy_sLead(idx_end(end));

            original_pair.p_ledBy_sFoll(p) = ptable.p_ledBy_sFoll(idx_end(end));

        else

            fprintf('No stable leader in original pair %s #%d!\n',cur_pair,p)

            original_pair.p_ledBy_sLead(p) = NaN;
            original_pair.p_ledBy_sFoll(p) = NaN;

            original_pair.Lead{p} = NaN;

        end
    end

    if isnan(original_pair.Lead{p})

        original_pair.p_ledBy_sLead_swap(p) = NaN;
        original_pair.p_ledBy_sFoll_swap(p) = NaN;

    else

        idx_lead = find(contains(swapped_pair.swapped, original_pair.Lead(p)));

        ptable_swap = swapped_pair.ptable{idx_lead};

        ptable_swap = ptable_swap(ptable_swap.cp_rate >= 0.8, :);

        if height(ptable_swap) >= 3
            ptable_swap_crit = ptable_swap(1:3,:);
        else
            ptable_swap_crit = ptable_swap;
        end

        if all(~ismissing(string(ptable_swap_crit.sLead))) && ...
                numel(unique(ptable_swap_crit.sLead)) == 1

            if strcmp(ptable_swap_crit.m1{1},lead_name)
                swap_id = 'm1';
                swap_foll_id = 'm2';
            else
                swap_id = 'm2';
                swap_foll_id = 'm1';
            end

            original_pair.p_ledBy_sLead_swap(p) = ...
                ptable_swap_crit.(['p_ledBy_' swap_id])(end);

            original_pair.p_ledBy_sFoll_swap(p) = ...
                ptable_swap_crit.(['p_ledBy_' swap_foll_id])(end);

        else

            fprintf('Use all well-trained sessions for swapped pair %s #%d!\n',cur_pair,p)

            ptable_swap = ptable_swap(~ismissing(string(ptable_swap.sLead)),:);

            [uniqueStrings, ~, idx] = unique(ptable_swap.sLead);

            counts = accumarray(idx, 1);

            [maxCount, maxIdx] = max(counts);

            totalCount = height(ptable_swap);

            percentage = maxCount / totalCount;

            if strcmp(ptable_swap.m1{1},lead_name)
                swap_id = 'm1';
                swap_foll_id = 'm2';
            else
                swap_id = 'm2';
                swap_foll_id = 'm1';
            end

            idx_end = find(strcmp(ptable_swap.sLead,swap_id));

            original_pair.p_ledBy_sLead_swap(p) = ...
                ptable_swap.p_ledBy_sLead(idx_end(end));

            original_pair.p_ledBy_sFoll_swap(p) = ...
                ptable_swap.p_ledBy_sFoll(idx_end(end));

            if percentage < 0.8
                fprintf('No stable leader in swapped pair %s #%d!\n',cur_pair,p)
            end
        end
    end
end

%% remove unreliable pair
idx = strcmp(original_pair.original,'RL011RL012');

original_pair.p_ledBy_sLead(idx) = NaN;
original_pair.p_ledBy_sFoll(idx) = NaN;

%% =========================================================
%% ADD SEX
%% =========================================================

original_pair.sex = repmat({'female'},16,1);

male_idx = ismember(original_pair.original, ...
    {'RL015RL016';'RL017RL014';'RL023RL024'; ...
     'RL025RL026';'MK029MK030';'MK031MK032'});

original_pair.sex(male_idx) = {'male'};

original_pair = movevars(original_pair,'sex','After','original');

%% =========================================================
%% SOURCE DATA
%% =========================================================

source_data_leader_swap = table( ...
    original_pair.original, ...
    original_pair.sex, ...
    original_pair.Lead, ...
    original_pair.p_ledBy_sLead, ...
    original_pair.p_ledBy_sLead_swap, ...
    original_pair.p_ledBy_sFoll, ...
    original_pair.p_ledBy_sFoll_swap, ...
    'VariableNames', ...
    {'Pair','Sex','StableLeader', ...
    'LeaderProp_Original','LeaderProp_Swapped', ...
    'FollowerProp_Original','FollowerProp_Swapped'});

assignin('base','source_data_leader_swap',source_data_leader_swap);

%% =========================================================
%% OVERALL FIGURE
%% =========================================================

fill_color = [0.9,0.9,0.9];
m_colors = {'#c2a5cf','#a6dba0','#969696'};

axis_range = [0 1];

fig = figure(Position=[600 600 400 400]);

hold on;

x = original_pair.p_ledBy_sLead;
y = original_pair.p_ledBy_sLead_swap;

sel = ~isnan(x);

x = x(sel);
y = y(sel);

s(1) = scatter(x,y,100, ...
    'MarkerFaceColor',m_colors{1}, ...
    'MarkerEdgeColor','k', ...
    'LineWidth',0.1);

x = original_pair.p_ledBy_sFoll;
y = original_pair.p_ledBy_sFoll_swap;

sel = ~isnan(x);

x = x(sel);
y = y(sel);

n_pairs_all = length(x);

s(2) = scatter(x,y,100, ...
    'MarkerFaceColor',m_colors{2}, ...
    'MarkerEdgeColor','k', ...
    'LineWidth',0.1);

xline(0.5,'k:','LineWidth',2)
yline(0.5,'k:','LineWidth',2)

legend(s,{'Leader','Follower'},'Location','northwest')
legend box off

xlabel('Props led in original pair')
ylabel('Props led in swapped pair')

title(['Persistence of roles (N=' num2str(length(x)) ' pairs)'])

box off

set(gca,'FontSize',24,'TickDir','out')

axis equal

xlim(axis_range);
ylim(axis_range);

x_ticks = xticks;
yticks(x_ticks);

hoy = char(datetime('now','Format','yyyyMMdd'));

plot_dir = fullfile(fd,'plots');

if ~exist(plot_dir,'dir')
    mkdir(plot_dir);
end

figname = fullfile(plot_dir,[hoy '_persit_roles']);

print(fig,figname,'-dpdf');

%% =========================================================
%% OVERALL BINOMIAL
%% =========================================================

n_success = 11;
n_total = 14;

p_all = binocdf(n_success,n_total,0.5,'upper');

fprintf('\n========================================\n')
fprintf('Persistence of roles — overall\n')
fprintf('========================================\n')
fprintf('Success = %d / %d\n', n_success, n_total)
fprintf('Binomial test p = %.6g\n', p_all)

T_all = table( ...
    {'all'}, ...
    n_success, ...
    n_total, ...
    n_success/n_total, ...
    p_all, ...
    'VariableNames', ...
    {'Sex','NSuccess','NTotal','PropPersistence','BinomialP'});

stats_table_leader_swap = [stats_table_leader_swap; T_all];

%% =========================================================
%% SPLIT BY SEX
%% =========================================================

sexes = {'female';'male'};

for i = 1:2

    cur_sex = sexes{i};

    original_pair_sex = original_pair(strcmp(original_pair.sex,cur_sex),:);

    axis_range = [0 1];

    fig = figure(Position=[600 600 400 400]);

    hold on;

    x = original_pair_sex.p_ledBy_sLead;
    y = original_pair_sex.p_ledBy_sLead_swap;

    sel = ~isnan(x);

    x = x(sel);
    y = y(sel);

    s(1) = scatter(x,y,100, ...
        'MarkerFaceColor',m_colors{1}, ...
        'MarkerEdgeColor','k', ...
        'LineWidth',0.1);

    x = original_pair_sex.p_ledBy_sFoll;
    y = original_pair_sex.p_ledBy_sFoll_swap;

    sel = ~isnan(x);

    x = x(sel);
    y = y(sel);

    n_pairs = length(x);

    s(2) = scatter(x,y,100, ...
        'MarkerFaceColor',m_colors{2}, ...
        'MarkerEdgeColor','k', ...
        'LineWidth',0.1);

    xline(0.5,'k:','LineWidth',2)
    yline(0.5,'k:','LineWidth',2)

    legend(s,{'Leader','Follower'},'Location','northwest')
    legend box off

    xlabel('Props led in original pair')
    ylabel('Props led in swapped pair')

    title(['Persistence of roles (N=' num2str(n_pairs) ' ' cur_sex ' pairs)'])

    box off

    set(gca,'FontSize',24,'TickDir','out')

    axis equal

    xlim(axis_range);
    ylim(axis_range);

    x_ticks = xticks;
    yticks(x_ticks);

    figname = fullfile(plot_dir,[hoy '_persit_roles_' cur_sex]);

    print(fig,figname,'-dpdf');

    if strcmp(cur_sex,'female')

        n_success = 7;
        n_total = 9;

        p_cur = binocdf(n_success,n_total,0.5,'upper');

    else

        n_success = 3;
        n_total = 5;

        p_cur = binocdf(n_success,n_total,0.5,'upper');

    end

    fprintf('\n========================================\n')
    fprintf('Persistence of roles — %s\n', cur_sex)
    fprintf('========================================\n')
    fprintf('Success = %d / %d\n', n_success, n_total)
    fprintf('Binomial test p = %.6g\n', p_cur)

    T_cur = table( ...
        {cur_sex}, ...
        n_success, ...
        n_total, ...
        n_success/n_total, ...
        p_cur, ...
        'VariableNames', ...
        {'Sex','NSuccess','NTotal','PropPersistence','BinomialP'});

    stats_table_leader_swap = [stats_table_leader_swap; T_cur];

end

assignin('base','stats_table_leader_swap',stats_table_leader_swap);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data_leader_swap\n')
fprintf('stats_table_leader_swap\n')

end