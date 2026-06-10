function opto_table_sel = plt_opto_inact_demo(fd,opto_table,features,which_mouse,time_window)

%%
n_features = length(features);

switch which_mouse

    case 'both'

        opto_table_sel = opto_table(strcmp(opto_table.inact_feat,time_window) ... 
            & strcmp(opto_table.subject,which_mouse),:);

        uni_pairs = unique(opto_table_sel.pair);
        n_pairs = length(uni_pairs);
        opto_table_updated = [];

        for p = 1:n_pairs

            cur_pair = uni_pairs{p};
            cur_table_pair = opto_table_sel(strcmp(opto_table_sel.pair,cur_pair),:);

            cur_leader = cur_table_pair.sLead_N(strcmp(cur_table_pair.subject,'both'));
            cur_follower = cur_table_pair.sFoll_N(strcmp(cur_table_pair.subject,'both'));

            cur_table_pair.lead_rt_mean_nor = cur_table_pair.([cur_leader{1} '_rt_mean_nor']);
            cur_table_pair.foll_rt_mean_nor = cur_table_pair.([cur_follower{1} '_rt_mean_nor']);

            cur_table_pair.lead_rt_mean_inact = cur_table_pair.([cur_leader{1} '_rt_mean_inact']);
            cur_table_pair.foll_rt_mean_inact = cur_table_pair.([cur_follower{1} '_rt_mean_inact']);

            opto_table_updated = [opto_table_updated; cur_table_pair];

        end

        opto_table_sel = opto_table_updated;

    case 'leader'

        opto_table_sel = [];
        cur_table = opto_table(strcmp(opto_table.inact_feat,time_window),:);

        uni_pairs = unique(cur_table.pair);
        n_pairs = length(uni_pairs);

        for p = 1:n_pairs

            cur_pair = uni_pairs{p};
            cur_table_pair = cur_table(strcmp(cur_table.pair,cur_pair),:);

            cur_leader = cur_table_pair.sLead_N(strcmp(cur_table_pair.subject,'both'));
            cur_table_sel = cur_table_pair(strcmp(cur_table_pair.subject,cur_leader{1}),:);

            opto_table_sel = [opto_table_sel; cur_table_sel];

        end

    case 'follower'

        opto_table_sel = [];
        cur_table = opto_table(strcmp(opto_table.inact_feat,time_window),:);

        uni_pairs = unique(cur_table.pair);
        n_pairs = length(uni_pairs);

        for p = 1:n_pairs

            cur_pair = uni_pairs{p};
            cur_table_pair = cur_table(strcmp(cur_table.pair,cur_pair),:);

            cur_follower = cur_table_pair.sFoll_N(strcmp(cur_table_pair.subject,'both'));
            cur_table_sel = cur_table_pair(strcmp(cur_table_pair.subject,cur_follower{1}),:);

            opto_table_sel = [opto_table_sel; cur_table_sel];

        end

end

%% initialize source data and stats table

source_data = table();
stats_table = table();

color_single = [0.6 0.6 0.6];
color_med = [0.2 0.2 0.2];

for f = 1:n_features

    cur_feature = features{f};    
    feature_label = strrep(cur_feature,'_',' ');

    ctrl = opto_table_sel.([cur_feature '_nor']);
    inact = opto_table_sel.([cur_feature '_inact']);

    temp = [ctrl inact];
    N = size(temp,1);

    %% ===== source data =====

    valid = ~isnan(ctrl) & ~isnan(inact);
    ctrl_valid = ctrl(valid);
    inact_valid = inact(valid);
    diff_valid = inact_valid - ctrl_valid;

    n_valid = length(ctrl_valid);

    T_source = table( ...
        repmat({which_mouse},n_valid,1), ...
        repmat({time_window},n_valid,1), ...
        repmat({cur_feature},n_valid,1), ...
        repmat({feature_label},n_valid,1), ...
        find(valid), ...
        ctrl_valid, ...
        inact_valid, ...
        diff_valid, ...
        'VariableNames', ...
        {'WhichMouse','TimeWindow','Feature','FeatureLabel', ...
        'RowIndex','Control','LED','Difference_LED_minus_Control'});

    source_data = [source_data; T_source];

    %% ===== stats =====

    [p,~,stats] = signrank(ctrl_valid,inact_valid);

    control_median = median(ctrl_valid,'omitnan');
    led_median = median(inact_valid,'omitnan');
    diff_median = median(diff_valid,'omitnan');

    control_mean = mean(ctrl_valid,'omitnan');
    led_mean = mean(inact_valid,'omitnan');
    diff_mean = mean(diff_valid,'omitnan');

    control_sd = std(ctrl_valid,'omitnan');
    led_sd = std(inact_valid,'omitnan');
    diff_sd = std(diff_valid,'omitnan');

    control_sem = control_sd / sqrt(n_valid);
    led_sem = led_sd / sqrt(n_valid);
    diff_sem = diff_sd / sqrt(n_valid);

    if isfield(stats,'signedrank')
        signedrank_stat = stats.signedrank;
    else
        signedrank_stat = NaN;
    end

    if isfield(stats,'zval')
        zval = stats.zval;
    else
        zval = NaN;
    end

    fprintf('\n========================================\n')
    fprintf('mPFC opto %s | %s | %s\n', which_mouse, time_window, feature_label)
    fprintf('========================================\n')
    fprintf('Test: paired Wilcoxon signed-rank test\n')
    fprintf('N = %d\n\n', n_valid)

    fprintf('Control median = %.4f\n', control_median)
    fprintf('LED median = %.4f\n', led_median)
    fprintf('Median difference (LED - Control) = %.4f\n\n', diff_median)

    fprintf('Control mean = %.4f\n', control_mean)
    fprintf('LED mean = %.4f\n', led_mean)
    fprintf('Mean difference (LED - Control) = %.4f\n\n', diff_mean)

    fprintf('Control SD = %.4f\n', control_sd)
    fprintf('LED SD = %.4f\n', led_sd)
    fprintf('Difference SD = %.4f\n', diff_sd)

    fprintf('Control SEM = %.4f\n', control_sem)
    fprintf('LED SEM = %.4f\n', led_sem)
    fprintf('Difference SEM = %.4f\n\n', diff_sem)

    fprintf('Signed-rank statistic = %.4f\n', signedrank_stat)

    if ~isnan(zval)
        fprintf('Z = %.4f\n', zval)
    end

    fprintf('P = %.6g\n', p)

    T_stats = table( ...
        {which_mouse}, ...
        {time_window}, ...
        {cur_feature}, ...
        {feature_label}, ...
        n_valid, ...
        control_median, ...
        led_median, ...
        diff_median, ...
        control_mean, ...
        led_mean, ...
        diff_mean, ...
        control_sd, ...
        led_sd, ...
        diff_sd, ...
        control_sem, ...
        led_sem, ...
        diff_sem, ...
        signedrank_stat, ...
        zval, ...
        p, ...
        'VariableNames', ...
        {'WhichMouse','TimeWindow','Feature','FeatureLabel','N', ...
        'ControlMedian','LEDMedian','MedianDifference_LED_minus_Control', ...
        'ControlMean','LEDMean','MeanDifference_LED_minus_Control', ...
        'ControlSD','LEDSD','DifferenceSD', ...
        'ControlSEM','LEDSEM','DifferenceSEM', ...
        'SignedRankStatistic','Z','PValue'});

    stats_table = [stats_table; T_stats];

    %% ===== plot =====

    fig = figure('Position',[600 300 200 400]);
    hold on;

    y = median(temp,"omitnan");

    plot(temp','LineWidth',1,'Color',color_single, ...
        'Marker','.','MarkerSize',10);

    plot(y','LineWidth',3,'Color',color_med, ...
        'Marker','.','MarkerSize',16); 

    xlim([0.5 2.5])

    if ismember(cur_feature,{'co_rate','cp_rate'})
        ylim([0.65 1])
    elseif ismember(cur_feature,{'lead_rt_mean','foll_rt_mean'})
        ylim([0 42])
    elseif ismember(cur_feature,{'cp_rate_ledBy_sLead','cp_rate_ledBy_sFoll'})
        ylim([0.35 1])
    end

    xticks(1:2);
    xticklabels({'Ctrl','LED'});

    ylabel(feature_label);

    title(['mPFC opto ' which_mouse ...
        ' on ' feature_label ...
        ' (N=' num2str(N) ')']);

    box off

    text(0.38,0.98,sprintf('P=%.2g', p), ...
        'FontSize',28, ...
        'Units','normalized')

    set(gca,'FontSize',24,'TickDir','out');

    hoy = char(datetime('now','Format','yyyyMMdd'));

    figname = [fd 'plots/' hoy ...
        '_bar_mPFC_opto_' ...
        which_mouse '_' feature_label '_' time_window];

    print(fig,figname,'-dpdf');

end

%% send to base workspace

assignin('base','source_data',source_data);
assignin('base','stats_table',stats_table);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end