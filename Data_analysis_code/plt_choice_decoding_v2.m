function plt_choice_decoding_v2(dc_table, params)
% plot cohort-level choice decoding result
% mean across sessions
%
% Output to base workspace:
%   source_data

alignBy = params.alignBy;
t_array_binned = params.t_array_binned;
Ninput = params.Ninput;
fd = params.fd;
role = params.role;
n_bins = length(t_array_binned);
whose_choice = params.whose_choice;

% filter dc_table using number of neurons
dc_table = dc_table(dc_table.n_cells>=Ninput,:);

source_data = table();

%% plot leader and follower separately
if strcmp(role,'leader') || strcmp(role,'follower')

    if strcmp(role,'leader')
        m_colors = {'#c2a5cf','#969696'};
    elseif strcmp(role,'follower')
        m_colors = {'#a6dba0','#969696'};
    end

    sel_role = strcmp(dc_table.role,{role});
    dc_table_sel = dc_table(sel_role,:);

    uni_animals = unique(dc_table_sel.animal);
    n_uni_animals = length(uni_animals);

    cor_data_cohort = nan(n_uni_animals,n_bins);
    cor_sim_cohort = nan(n_uni_animals,n_bins);

    for a = 1:n_uni_animals

        cur_animal = uni_animals{a};
        sel_animal = strcmp(dc_table_sel.animal,cur_animal);
        dc_table_animal = dc_table_sel(sel_animal,:);

        cor_data_cohort(a,:) = mean(vertcat(dc_table_animal.cor_data{:}));
        cor_sim_cohort(a,:) = mean(vertcat(dc_table_animal.cor_sim{:}));

        T_data = table( ...
            repmat({cur_animal},n_bins,1), ...
            repmat({role},n_bins,1), ...
            repmat({'Data'},n_bins,1), ...
            t_array_binned(:), ...
            cor_data_cohort(a,:)', ...
            'VariableNames', ...
            {'Animal','Role','Type','TimeBin','CorrectRate'});

        T_shuffle = table( ...
            repmat({cur_animal},n_bins,1), ...
            repmat({role},n_bins,1), ...
            repmat({'Shuffled'},n_bins,1), ...
            t_array_binned(:), ...
            cor_sim_cohort(a,:)', ...
            'VariableNames', ...
            {'Animal','Role','Type','TimeBin','CorrectRate'});

        source_data = [source_data; T_data; T_shuffle];

    end

    fig = figure('Position',[200 200 600 600]);
    hold on;

    cor_data_mean = mean(cor_data_cohort,1);
    cor_data_se = std(cor_data_cohort,[],1)/sqrt(n_uni_animals);
    [h1,f1] = error_shade(t_array_binned,cor_data_mean,cor_data_se,m_colors{1});

    cor_sim_mean = mean(cor_sim_cohort,1);
    cor_sim_se = std(cor_sim_cohort,[],1)/sqrt(n_uni_animals);
    [h2,f2] = error_shade(t_array_binned,cor_sim_mean,cor_sim_se,m_colors{2});

    xline(0,'LineStyle',':','LineWidth',1);
    ylim([0.1 0.75])
    axis padded
    xlabel(['Frame no. from ' alignBy])
    ylabel('Correct rate')
    legend([h1 h2],{'Data','Shuffled'},'Location','northeast');
    legend boxoff

elseif strcmp(role,'both')

    m_colors = {'#c2a5cf','#a6dba0','#969696'};

    fig = figure('Position',[200 200 600 600]);
    hold on;

    %% get leader
    sel_leader = strcmp(dc_table.role,'leader');
    dc_table_leader = dc_table(sel_leader,:);

    uni_animals_leader = unique(dc_table_leader.animal);
    n_uni_animals_leader = length(uni_animals_leader);

    cor_data_leader = nan(n_uni_animals_leader,n_bins);

    for a = 1:n_uni_animals_leader

        cur_animal = uni_animals_leader{a};
        sel_animal = strcmp(dc_table_leader.animal,cur_animal);
        dc_table_leader_sel = dc_table_leader(sel_animal,:);

        cor_data_leader(a,:) = mean(vertcat(dc_table_leader_sel.cor_data{:}));

        T = table( ...
            repmat({cur_animal},n_bins,1), ...
            repmat({'leader'},n_bins,1), ...
            repmat({'Data'},n_bins,1), ...
            t_array_binned(:), ...
            cor_data_leader(a,:)', ...
            'VariableNames', ...
            {'Animal','Role','Type','TimeBin','CorrectRate'});

        source_data = [source_data; T];

    end

    data1 = cor_data_leader;
    data1_mean = mean(data1,1);
    data1_se = std(data1,[],1)/sqrt(n_uni_animals_leader);
    [h1,f1] = error_shade(t_array_binned,data1_mean,data1_se,m_colors{1});

    %% get follower
    sel_follower = strcmp(dc_table.role,'follower');
    dc_table_follower = dc_table(sel_follower,:);

    uni_animals_follower = unique(dc_table_follower.animal);
    n_uni_animals_follower = length(uni_animals_follower);

    cor_data_follower = nan(n_uni_animals_follower,n_bins);

    for a = 1:n_uni_animals_follower

        cur_animal = uni_animals_follower{a};
        sel_animal = strcmp(dc_table_follower.animal,cur_animal);
        dc_table_follower_sel = dc_table_follower(sel_animal,:);

        cor_data_follower(a,:) = mean(vertcat(dc_table_follower_sel.cor_data{:}));

        T = table( ...
            repmat({cur_animal},n_bins,1), ...
            repmat({'follower'},n_bins,1), ...
            repmat({'Data'},n_bins,1), ...
            t_array_binned(:), ...
            cor_data_follower(a,:)', ...
            'VariableNames', ...
            {'Animal','Role','Type','TimeBin','CorrectRate'});

        source_data = [source_data; T];

    end

    data2 = cor_data_follower;
    data2_mean = mean(data2,1);
    data2_se = std(data2,[],1)/sqrt(n_uni_animals_follower);
    [h2,f2] = error_shade(t_array_binned,data2_mean,data2_se,m_colors{2});

    %% get shuffled data of both
    uni_animals = unique(dc_table.animal);
    n_uni_animals = length(uni_animals);

    cor_sim = nan(n_uni_animals,n_bins);

    for a = 1:n_uni_animals

        cur_animal = uni_animals{a};
        sel_animal = strcmp(dc_table.animal,cur_animal);
        dc_table_sel = dc_table(sel_animal,:);

        cor_sim(a,:) = mean(vertcat(dc_table_sel.cor_sim{:}));

        T = table( ...
            repmat({cur_animal},n_bins,1), ...
            repmat({'both'},n_bins,1), ...
            repmat({'Shuffled'},n_bins,1), ...
            t_array_binned(:), ...
            cor_sim(a,:)', ...
            'VariableNames', ...
            {'Animal','Role','Type','TimeBin','CorrectRate'});

        source_data = [source_data; T];

    end

    data3 = cor_sim;
    data3_mean = mean(data3,1);
    data3_se = std(data3,[],1)/sqrt(n_uni_animals);
    [h3,f3] = error_shade(t_array_binned,data3_mean,data3_se,m_colors{3});

    xline(0,'LineStyle','--','LineWidth',1);
    ylim([0.1 0.75])
    xticks(-60:30:60)
    xticklabels(-2:2)
    axis padded
    xlabel(['Frame from ' alignBy])
    ylabel('Correct rate')

    label_leader = sprintf('Leader (%d animals)',n_uni_animals_leader);
    label_follower = sprintf('Follower (%d animals)',n_uni_animals_follower);
    label_shuffle = sprintf('Shuffled (%d animals)',n_uni_animals);

    legend([h1 h2 h3], ...
        {label_leader,label_follower,label_shuffle}, ...
        'Location','northwest');

    legend boxoff

end

set(gca,'FontSize',36,'TickDir','out');

title(['Decoding ' whose_choice ' choice in ' role ...
    ' (N=' num2str(Ninput) ' cells/session)'])

hoy = char(datetime('now','Format','yyyyMMdd'));

dc_figname = [fd '/plots/' hoy 'p_decoding_' ...
    whose_choice '_choice_' role '_N=' num2str(Ninput)];

print(fig,dc_figname,'-dpdf');

assignin('base','source_data',source_data);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')

end