function plt_leadership_decoding_v2(dc_table, params)
% plot cohort-level leadership decoding result
% plot auROC instead of correct rate
%
% Output to base workspace:
%   source_data

alignBy = params.alignBy;
t_array_binned = params.t_array_binned;
Ninput = params.Ninput;
fd = params.fd;
role = params.role;
n_bins = length(t_array_binned);

% filter dc_table using number of neurons
dc_table = dc_table(dc_table.n_cells>=Ninput,:);

source_data = table();

%% leader/follower separately
if strcmp(role,'leader') || strcmp(role,'follower')

    if strcmp(role,'leader')
        m_colors = {'#c2a5cf','#969696'};
    elseif strcmp(role,'follower')
        m_colors = {'#a6dba0','#969696'};
    end

    sel_role = strcmp(dc_table.role,{role});
    dc_table_sel = dc_table(sel_role,:);
    n_ses = height(dc_table_sel);

    auc_data_cohort = nan(n_ses,n_bins);
    auc_sim_cohort = nan(n_ses,n_bins);

    for s = 1:n_ses
        auc_data_cohort(s,:) = dc_table_sel.auc_data{s};
        auc_sim_cohort(s,:) = mean(dc_table_sel.auc_sim{s});

        T_data = table( ...
            repmat({role},n_bins,1), ...
            repmat({'Data'},n_bins,1), ...
            repmat(s,n_bins,1), ...
            t_array_binned(:), ...
            auc_data_cohort(s,:)', ...
            'VariableNames', ...
            {'Role','Type','SessionIndex','TimeBin','AUC'});

        T_shuffle = table( ...
            repmat({role},n_bins,1), ...
            repmat({'Shuffled'},n_bins,1), ...
            repmat(s,n_bins,1), ...
            t_array_binned(:), ...
            auc_sim_cohort(s,:)', ...
            'VariableNames', ...
            {'Role','Type','SessionIndex','TimeBin','AUC'});

        source_data = [source_data; T_data; T_shuffle];
    end

    fig = figure('Position',[200 200 600 600]);
    hold on;

    data1_mean = mean(auc_data_cohort,1);
    auc_data_se = std(auc_data_cohort,[],1)/sqrt(n_ses);
    [h1,f1] = error_shade(t_array_binned,data1_mean,auc_data_se,m_colors{1});

    auc_sim_mean = mean(auc_sim_cohort,1);
    auc_sim_se = std(auc_sim_cohort,[],1)/sqrt(n_ses);
    [h2,f2] = error_shade(t_array_binned,auc_sim_mean,auc_sim_se,m_colors{2});

    xline(0,'LineStyle',':','LineWidth',1);
    ylim([0.1 0.75])
    axis padded
    xlabel(['Frame no. from ' alignBy])
    ylabel('auROC')

    legend([h1 h2], ...
        {['Data (' num2str(n_ses) ' sessions)'], ...
        ['Shuffled (' num2str(n_ses) ' sessions)']}, ...
        'Location','northeast');

    legend boxoff

elseif strcmp(role,'both_per_animal')

    m_colors = {'#c2a5cf','#a6dba0','#969696'};
    fig = figure('Position',[200 200 400 400]);
    hold on;

    %% leader
    sel_leader = strcmp(dc_table.role,'leader');
    dc_table_leader = dc_table(sel_leader,:);

    uni_animals_leader = unique(dc_table_leader.animal);
    n_uni_animals_leader = length(uni_animals_leader);
    auc_data_leader = nan(n_uni_animals_leader,n_bins);

    for a = 1:n_uni_animals_leader
        cur_animal = uni_animals_leader{a};
        sel_animal = strcmp(dc_table_leader.animal,cur_animal);
        dc_table_leader_sel = dc_table_leader(sel_animal,:);

        auc_data_leader(a,:) = mean(vertcat(dc_table_leader_sel.auc_data{:}));

        T = table( ...
            repmat({'leader'},n_bins,1), ...
            repmat({'Data'},n_bins,1), ...
            repmat({cur_animal},n_bins,1), ...
            t_array_binned(:), ...
            auc_data_leader(a,:)', ...
            'VariableNames', ...
            {'Role','Type','Animal','TimeBin','AUC'});

        source_data = [source_data; T];
    end

    data1 = auc_data_leader;
    data1_mean = mean(data1,1);
    data1_se = std(data1,[],1)/sqrt(n_uni_animals_leader);
    [h1,f1] = error_shade(t_array_binned,data1_mean,data1_se,m_colors{1});

    %% follower
    sel_follower = strcmp(dc_table.role,'follower');
    dc_table_follower = dc_table(sel_follower,:);

    uni_animals_follower = unique(dc_table_follower.animal);
    n_uni_animals_follower = length(uni_animals_follower);
    auc_data_follower = nan(n_uni_animals_follower,n_bins);

    for a = 1:n_uni_animals_follower
        cur_animal = uni_animals_follower{a};
        sel_animal = strcmp(dc_table_follower.animal,cur_animal);
        dc_table_follower_sel = dc_table_follower(sel_animal,:);

        auc_data_follower(a,:) = mean(vertcat(dc_table_follower_sel.auc_data{:}));

        T = table( ...
            repmat({'follower'},n_bins,1), ...
            repmat({'Data'},n_bins,1), ...
            repmat({cur_animal},n_bins,1), ...
            t_array_binned(:), ...
            auc_data_follower(a,:)', ...
            'VariableNames', ...
            {'Role','Type','Animal','TimeBin','AUC'});

        source_data = [source_data; T];
    end

    data2 = auc_data_follower;
    data2_mean = mean(data2,1);
    data2_se = std(data2,[],1)/sqrt(n_uni_animals_follower);
    [h2,f2] = error_shade(t_array_binned,data2_mean,data2_se,m_colors{2});

    %% shuffled
    uni_animals = unique(dc_table.animal);
    n_uni_animals = length(uni_animals);
    auc_sim = nan(n_uni_animals,n_bins);

    for a = 1:n_uni_animals
        cur_animal = uni_animals{a};
        sel_animal = strcmp(dc_table.animal,cur_animal);
        dc_table_sel = dc_table(sel_animal,:);

        auc_sim(a,:) = mean(vertcat(dc_table_sel.auc_sim{:}));

        T = table( ...
            repmat({'both'},n_bins,1), ...
            repmat({'Shuffled'},n_bins,1), ...
            repmat({cur_animal},n_bins,1), ...
            t_array_binned(:), ...
            auc_sim(a,:)', ...
            'VariableNames', ...
            {'Role','Type','Animal','TimeBin','AUC'});

        source_data = [source_data; T];
    end

    data3 = auc_sim;
    data3_mean = mean(data3,1);
    data3_se = std(data3,[],1)/sqrt(n_uni_animals);
    [h3,f3] = error_shade(t_array_binned,data3_mean,data3_se,m_colors{3});

    xline(0,'LineStyle','--','LineWidth',1);
    ylim([0.1 0.75])
    axis padded
    xlabel(['Frame no. from ' alignBy])
    ylabel('auROC')

    label_leader = sprintf('Leader (%d mice)',n_uni_animals_leader);
    label_follower = sprintf('Follower (%d mice)',n_uni_animals_follower);
    label_shuffle = sprintf('Shuffled (%d mice)',n_uni_animals);

    legend([h1 h2 h3], ...
        {label_leader,label_follower,label_shuffle}, ...
        'Location','northwest');

    legend boxoff
end

caption = ['Decoding leader identity in ' role ...
    ' (N=' num2str(Ninput) ' cells/session)'];
caption = strrep(caption,'_',' ');

title(caption)
set(gca,'FontSize',28,'TickDir','out');

hoy = char(datetime('now','Format','yyyyMMdd'));

dc_figname = [fd '/plots/' hoy ...
    'p_decoding_leadership_' role ...
    '_N=' num2str(Ninput) ...
    '_auROC_alignBy' alignBy '_' role];

print(fig,dc_figname,'-dpdf');

assignin('base','source_data',source_data);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')

end