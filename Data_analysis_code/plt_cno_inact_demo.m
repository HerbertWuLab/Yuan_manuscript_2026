function plt_cno_inact_demo(fd,cno_table,features,subject)
% plot behavioral metrics of cno and control
% source data and stats are assigned to base workspace

color_single = [0.6 0.6 0.6];
color_med = [0.2 0.2 0.2];
color_cno = [192 58 48]/255;

n_features = length(features);
uni_phase = unique(cno_table.phase);

source_data_all = table();
stats_all = table();

if length(uni_phase)~=1
    disp('Warning! cno table should include only one phase but has the following:')
    disp(uni_phase)
end

if length(uni_phase)==1 && strcmpi(uni_phase{1},'phase4a')

    sel = cno_table.cno==1 & strcmpi(cno_table.subject_inact,subject); 
    idx = find(sel);

    for f = 1:n_features

        cur_feature = features{f}; 
        disp(cur_feature)

        if contains(cur_feature,'m1')

            m1_before = cno_table.(cur_feature)(idx-1);
            m1_cno = cno_table.(cur_feature)(idx);

            m2_feature = strrep(cur_feature,'m1','m2');

            m2_before = cno_table.(m2_feature)(idx-1);
            m2_cno = cno_table.(m2_feature)(idx);

            before = [m1_before; m2_before];
            cno = [m1_cno; m2_cno];

            feature_label = strrep(cur_feature,'_',' ');
            feature_label = strrep(feature_label,'m1 ','');

        else

            before = cno_table.(cur_feature)(idx-1);
            cno = cno_table.(cur_feature)(idx);

            feature_label = strrep(cur_feature,'_',' ');

        end

        temp = [before cno];
        N = size(temp,1);

        %% ===== source data =====

        source_data = table( ...
            repmat({subject},N,1), ...
            repmat({cur_feature},N,1), ...
            repmat({feature_label},N,1), ...
            (1:N)', ...
            before, ...
            cno, ...
            cno - before, ...
            'VariableNames', ...
            {'SubjectInact','Feature','FeatureLabel','PairIndex', ...
            'Control','CNO','Difference_CNO_minus_Control'});

        source_data_all = [source_data_all; source_data];

        var_name = ['source_data_' matlab.lang.makeValidName(cur_feature)];
        assignin('base',var_name,source_data);

        %% ===== statistics =====

        valid = ~isnan(before) & ~isnan(cno);
        before_valid = before(valid);
        cno_valid = cno(valid);
        diff_valid = cno_valid - before_valid;

        [p,~,stats] = signrank(before_valid,cno_valid);

        n_valid = length(before_valid);

        control_median = median(before_valid,'omitnan');
        cno_median = median(cno_valid,'omitnan');
        diff_median = median(diff_valid,'omitnan');

        control_mean = mean(before_valid,'omitnan');
        cno_mean = mean(cno_valid,'omitnan');
        diff_mean = mean(diff_valid,'omitnan');

        control_sd = std(before_valid,'omitnan');
        cno_sd = std(cno_valid,'omitnan');
        diff_sd = std(diff_valid,'omitnan');

        control_sem = control_sd / sqrt(n_valid);
        cno_sem = cno_sd / sqrt(n_valid);
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
        fprintf('%s | %s\n', subject, feature_label)
        fprintf('========================================\n')
        fprintf('Test: paired Wilcoxon signed-rank test\n')
        fprintf('N = %d\n\n', n_valid)

        fprintf('Control median = %.4f\n', control_median)
        fprintf('CNO median = %.4f\n', cno_median)
        fprintf('Median difference (CNO - Control) = %.4f\n\n', diff_median)

        fprintf('Control mean = %.4f\n', control_mean)
        fprintf('CNO mean = %.4f\n', cno_mean)
        fprintf('Mean difference (CNO - Control) = %.4f\n\n', diff_mean)

        fprintf('Control SD = %.4f\n', control_sd)
        fprintf('CNO SD = %.4f\n', cno_sd)
        fprintf('Difference SD = %.4f\n', diff_sd)

        fprintf('Control SEM = %.4f\n', control_sem)
        fprintf('CNO SEM = %.4f\n', cno_sem)
        fprintf('Difference SEM = %.4f\n\n', diff_sem)

        fprintf('Signed-rank statistic = %.4f\n', signedrank_stat)

        if ~isnan(zval)
            fprintf('Z = %.4f\n', zval)
        end

        fprintf('P = %.6g\n', p)

        T_stats = table( ...
            {subject}, ...
            {cur_feature}, ...
            {feature_label}, ...
            n_valid, ...
            control_median, ...
            cno_median, ...
            diff_median, ...
            control_mean, ...
            cno_mean, ...
            diff_mean, ...
            control_sd, ...
            cno_sd, ...
            diff_sd, ...
            control_sem, ...
            cno_sem, ...
            diff_sem, ...
            signedrank_stat, ...
            zval, ...
            p, ...
            'VariableNames', ...
            {'SubjectInact','Feature','FeatureLabel','N', ...
            'ControlMedian','CNOMedian','MedianDifference_CNO_minus_Control', ...
            'ControlMean','CNOMean','MeanDifference_CNO_minus_Control', ...
            'ControlSD','CNOSD','DifferenceSD', ...
            'ControlSEM','CNOSEM','DifferenceSEM', ...
            'SignedRankStatistic','Z','PValue'});

        stats_all = [stats_all; T_stats];

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
        elseif ismember(cur_feature,{'cp_rate_ledBy_sFoll'})
            ylim([0.5 1.001])
        end

        xticks(1:2);
        xticklabels({'ctrl','cno'});
        ylabel(feature_label);

        title(['chemo ' subject ' on ' feature_label ' (N=' num2str(N) ')']);

        box off

        text(0.38,0.98,sprintf('P=%.2g', p), ...
            'FontSize',28,'Units','normalized')

        set(gca,'FontSize',24,'TickDir','out');

        hoy = char(datetime('now','Format','yyyyMMdd'));

        figname = [fd 'plots/' hoy '_bar_mPFC_inact_' subject '_' feature_label];

        print(fig,figname,'-dpdf');

    end
end

assignin('base','source_data_cno_inact_all',source_data_all);
assignin('base','stats_cno_inact_all',stats_all);

disp('Saved source data to base workspace:')
disp('source_data_cno_inact_all')
disp('stats_cno_inact_all')
disp('also saved each feature as source_data_<feature>')

end