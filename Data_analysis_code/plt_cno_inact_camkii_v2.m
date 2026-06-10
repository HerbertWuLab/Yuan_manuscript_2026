function plt_cno_inact_camkii_v2(fd,cno_table,features,subject)
% plot cooperation rate of pairs comparing control and cno

% fresh cno injection, but YC011YC012 was injected 3-4months after reaching criterion
% sel_pairs = {'YC021YC022','YC023YC024','YC027YC028'}; % fresh cno in freshly trained pairs
% sel_pairs = {'YC011YC012','YC017YC018','YC021YC022','YC023YC024','YC025YC026','YC027YC028'}; % first 5mg/kg cno injection 

color_single = [0.6 0.6 0.6];
color_med = [0.2 0.2 0.2];
color_cno = [192 58 48]/255;
n_features = length(features);
uni_phase = unique(cno_table.phase);

source_data = table();
stats_table = table();

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

            before = [m1_before;m2_before];
            cno = [m1_cno;m2_cno];

            feature_label = strrep(cur_feature,'_',' ');
            feature_label = strrep(feature_label,'m1 ','');

        else

            if strcmp(cur_feature,'lead_dsp')

                if all(cno_table.true_lead(idx-1) == 1)
                    before = cno_table.(cur_feature)(idx-1);
                    ctrl_source = repmat({'before'},length(before),1);

                elseif all(cno_table.true_lead(idx+1) == 1)
                    before = cno_table.(cur_feature)(idx+1);
                    ctrl_source = repmat({'after'},length(before),1);

                else 
                    disp('look into the leader disparity');
                    before = cno_table.(cur_feature)(idx-1);
                    ctrl_source = repmat({'before_uncertain'},length(before),1);
                end

            else

                before = cno_table.(cur_feature)(idx-1);
                ctrl_source = repmat({'before'},length(before),1);

            end                

            cno = cno_table.(cur_feature)(idx);
            feature_label = strrep(cur_feature,'_',' ');

        end

        temp = [before cno];
        N = size(temp,1);

        valid = ~isnan(before) & ~isnan(cno);
        before_valid = before(valid);
        cno_valid = cno(valid);
        diff_valid = cno_valid - before_valid;

        if ~exist('ctrl_source','var') || length(ctrl_source) ~= length(before)
            ctrl_source = repmat({'before'},length(before),1);
        end
        ctrl_source_valid = ctrl_source(valid);

        T_source = table( ...
            repmat({'phase4a'},sum(valid),1), ...
            repmat({subject},sum(valid),1), ...
            repmat({cur_feature},sum(valid),1), ...
            repmat({feature_label},sum(valid),1), ...
            find(valid), ...
            ctrl_source_valid, ...
            before_valid, ...
            cno_valid, ...
            diff_valid, ...
            'VariableNames', ...
            {'Phase','Subject','Feature','FeatureLabel','Index', ...
            'ControlSource','Control','CNO','Difference_CNO_minus_Control'});

        source_data = [source_data; T_source];

        [p,~,stats] = signrank(before_valid,cno_valid);

        signedrank_stat = NaN;
        zval = NaN;

        if isfield(stats,'signedrank')
            signedrank_stat = stats.signedrank;
        end

        if isfield(stats,'zval')
            zval = stats.zval;
        end

        control_median = median(before_valid,'omitnan');
        cno_median = median(cno_valid,'omitnan');
        diff_median = median(diff_valid,'omitnan');

        control_mean = mean(before_valid,'omitnan');
        cno_mean = mean(cno_valid,'omitnan');
        diff_mean = mean(diff_valid,'omitnan');

        control_sd = std(before_valid,'omitnan');
        cno_sd = std(cno_valid,'omitnan');
        diff_sd = std(diff_valid,'omitnan');

        control_sem = control_sd / sqrt(sum(valid));
        cno_sem = cno_sd / sqrt(sum(valid));
        diff_sem = diff_sd / sqrt(sum(valid));

        fprintf('\n========================================\n')
        fprintf('CaMKII CNO inactivation | %s | %s\n', subject, feature_label)
        fprintf('========================================\n')
        fprintf('Test: paired Wilcoxon signed-rank test\n')
        fprintf('N = %d\n', sum(valid))
        fprintf('Control median = %.4f\n', control_median)
        fprintf('CNO median = %.4f\n', cno_median)
        fprintf('Median difference CNO - control = %.4f\n', diff_median)
        fprintf('Control mean = %.4f, SEM = %.4f\n', control_mean, control_sem)
        fprintf('CNO mean = %.4f, SEM = %.4f\n', cno_mean, cno_sem)
        fprintf('Mean difference CNO - control = %.4f, SEM = %.4f\n', diff_mean, diff_sem)
        fprintf('Signed-rank statistic = %.4f\n', signedrank_stat)
        if ~isnan(zval)
            fprintf('Z = %.4f\n', zval)
        end
        fprintf('P = %.6g\n', p)

        T_stats = table( ...
            {'phase4a'}, ...
            {subject}, ...
            {cur_feature}, ...
            {feature_label}, ...
            {'paired Wilcoxon signed-rank'}, ...
            sum(valid), ...
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
            {'Phase','Subject','Feature','FeatureLabel','Test','N', ...
            'ControlMedian','CNOMedian','MedianDifference_CNO_minus_Control', ...
            'ControlMean','CNOMean','MeanDifference_CNO_minus_Control', ...
            'ControlSD','CNOSD','DifferenceSD', ...
            'ControlSEM','CNOSEM','DifferenceSEM', ...
            'SignedRankStatistic','Z','PValue'});

        stats_table = [stats_table; T_stats];

        fig = figure('Position',[600 300 200 400]);
        hold on;

        y = median(temp,"omitnan");

        % b = bar(x,y,0.6,'FaceColor','none','LineWidth',1);
        % b.EdgeColor = 'flat';
        % b.CData(1,:) = color_single;
        % b.CData(2,:) = [192 58 48]/255;

        plot(temp','LineWidth',1,'Color',color_single,...
            'Marker','.','MarkerSize',10);

        plot(y','LineWidth',3,'Color',color_med,...
            'Marker','.','MarkerSize',16); 

        % errorbar(1,median(before),median(before)-quantile(before, 0.25),quantile(before, 0.75)-median(before),'Color','k','LineWidth',2);
        % errorbar(2,median(cno),median(cno)-quantile(cno, 0.25),quantile(cno, 0.75)-median(cno),'Color',color_cno,'LineWidth',2);
        % errorbar(x,mean(temp,"omitnan"),[],std(temp,"omitnan")/sqrt(size(temp,1)),'Color','k','LineWidth',2);

        xlim([0.5 2.5])

        if ismember(cur_feature,{'co_rate','cp_rate'})
            ylim([0.65 1])
        elseif ismember(cur_feature,{'lead_rt_mean','foll_rt_mean'})
            ylim([0 42])
        elseif ismember(cur_feature,{'cp_rate_ledBy_sFoll'})
            ylim([0.5 1.001])
        elseif ismember(cur_feature,{'lead_im_p'})
            ylim([0 0.36])
        elseif ismember(cur_feature,{'foll_im_p'})
            ylim([0 0.2])
        elseif ismember(cur_feature,{'mean_inter_dis'})
            ylim([10 22])
        end

        xticks(1:2);
        xticklabels({'ctrl','cno'});

        ylabel(feature_label);

        % title(['chemo ' subject ' on ' feature_label ' (N=' num2str(N) ')']);
        title([subject ' ' feature_label]);

        box off

        text(0.38,0.98,sprintf('P=%.2g', p), ...
            'FontSize',28, ...
            'Units','normalized')

        set(gca,'FontSize',32,'TickDir','out');

        hoy = char(datetime('now','Format','yyyyMMdd'));

        figname = [fd 'plots/' hoy ...
            '_bar_mPFC_camkii_inact_' subject '_' feature_label];

        print(fig,figname,'-dpdf');

        clear ctrl_source

    end

elseif length(uni_phase)==1 && strcmpi(uni_phase{1},'phase4b')

    disp('Phase4b was not performed during camkII-Gi inactivation!')

end

assignin('base','source_data',source_data);
assignin('base','stats_table',stats_table);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end