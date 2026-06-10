function plt_cno_inact_op_v2(fd,cno_table,features,subject)
% plot cooperation rate of pairs comparing control and cno
%
% Outputs to base workspace:
%   source_data
%   stats_table

color_single = [0.6 0.6 0.6];
color_med = [0.2 0.2 0.2];
color_cno = [192 58 48]/255;

n_features = length(features);
uni_phase = unique(cno_table.phase);

if length(uni_phase)~=1
    disp('Warning! cno table should include only one phase but has the following:')
    disp(uni_phase)
end

%% initialize output tables
source_data = table();
stats_table = table();

%% ======================= PHASE 4A =======================
if length(uni_phase)==1 && strcmpi(uni_phase{1},'phase4a')

    sel = cno_table.cno==1 & strcmpi(cno_table.subject,subject); 
    idx = find(sel);

    for f = 1:n_features

        cur_feature = features{f}; 
        disp(cur_feature)

        if contains(cur_feature,'m1')

            before = cno_table.(cur_feature)(idx-1);
            cno = cno_table.(cur_feature)(idx);

            feature_label = strrep(cur_feature,'_',' ');
            feature_label = strrep(feature_label,'m1','dot');

        else

            before = cno_table.(cur_feature)(idx-1);
            cno = cno_table.(cur_feature)(idx);

            feature_label = strrep(cur_feature,'_',' ');

        end

        %% label replacements
        feature_label = strrep(feature_label,'p ledBy m1','p ledBy dot');
        feature_label = strrep(feature_label,'m2 95p spd','mice 95p spd');
        feature_label = strrep(feature_label,'m2 mean spd','mice mean spd');

        temp = [before cno];
        N = size(temp,1);

        %% ===== source data =====
        valid = ~isnan(before) & ~isnan(cno);

        before_valid = before(valid);
        cno_valid = cno(valid);

        diff_valid = cno_valid - before_valid;

        T_source = table( ...
            repmat({'phase4a'},sum(valid),1), ...
            repmat({subject},sum(valid),1), ...
            repmat({cur_feature},sum(valid),1), ...
            repmat({feature_label},sum(valid),1), ...
            find(valid), ...
            before_valid, ...
            cno_valid, ...
            diff_valid, ...
            'VariableNames', ...
            {'Phase','Subject','Feature','FeatureLabel', ...
            'Index','Control','CNO','Difference_CNO_minus_Control'});

        source_data = [source_data; T_source];

        %% ===== statistics =====
        [p,~,stats] = signrank(before_valid,cno_valid);

        median_before = median(before_valid,'omitnan');
        median_cno = median(cno_valid,'omitnan');
        median_diff = median(diff_valid,'omitnan');

        mean_before = mean(before_valid,'omitnan');
        mean_cno = mean(cno_valid,'omitnan');
        mean_diff = mean(diff_valid,'omitnan');

        sd_before = std(before_valid,'omitnan');
        sd_cno = std(cno_valid,'omitnan');
        sd_diff = std(diff_valid,'omitnan');

        sem_before = sd_before / sqrt(sum(valid));
        sem_cno = sd_cno / sqrt(sum(valid));
        sem_diff = sd_diff / sqrt(sum(valid));

        signedrank_stat = NaN;
        zval = NaN;

        if isfield(stats,'signedrank')
            signedrank_stat = stats.signedrank;
        end

        if isfield(stats,'zval')
            zval = stats.zval;
        end

        fprintf('\n========================================\n')
        fprintf('%s | %s\n', subject, feature_label)
        fprintf('========================================\n')
        fprintf('Test: paired Wilcoxon signed-rank test\n')
        fprintf('N = %d\n\n', sum(valid))

        fprintf('Control median = %.4f\n', median_before)
        fprintf('CNO median = %.4f\n', median_cno)
        fprintf('Median difference = %.4f\n\n', median_diff)

        fprintf('Control mean = %.4f\n', mean_before)
        fprintf('CNO mean = %.4f\n', mean_cno)
        fprintf('Mean difference = %.4f\n\n', mean_diff)

        fprintf('Control SD = %.4f\n', sd_before)
        fprintf('CNO SD = %.4f\n', sd_cno)
        fprintf('Difference SD = %.4f\n\n', sd_diff)

        fprintf('Control SEM = %.4f\n', sem_before)
        fprintf('CNO SEM = %.4f\n', sem_cno)
        fprintf('Difference SEM = %.4f\n\n', sem_diff)

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
            sum(valid), ...
            median_before, ...
            median_cno, ...
            median_diff, ...
            mean_before, ...
            mean_cno, ...
            mean_diff, ...
            sd_before, ...
            sd_cno, ...
            sd_diff, ...
            sem_before, ...
            sem_cno, ...
            sem_diff, ...
            signedrank_stat, ...
            zval, ...
            p, ...
            'VariableNames', ...
            {'Phase','Subject','Feature','FeatureLabel','N', ...
            'ControlMedian','CNOMedian','MedianDifference', ...
            'ControlMean','CNOMean','MeanDifference', ...
            'ControlSD','CNOSD','DifferenceSD', ...
            'ControlSEM','CNOSEM','DifferenceSEM', ...
            'SignedRankStatistic','Z','PValue'});

        stats_table = [stats_table; T_stats];

        %% ===== plot =====
        fig = figure('Position',[600 300 250 400]);
        hold on;

        y = median(temp,"omitnan");

        plot(temp','LineWidth',1,'Color',color_single,...
            'Marker','.','MarkerSize',10);

        plot(y','LineWidth',3,'Color',color_med,...
            'Marker','.','MarkerSize',16); 

        xlim([0.5 2.5])

        if ismember(cur_feature,{'co_rate','cp_rate'})
            ylim([0.65 1])
        elseif ismember(cur_feature,{'p_ledBy_m1'})
            ylim([0.4 1])
        elseif ismember(cur_feature,{'m2_95p_spd'})
            ylim([20 42])
        elseif ismember(cur_feature,{'m2_mean_spd','m2_med_spd'})
            ylim([8 18])
        elseif ismember(cur_feature,{'cp_rate_ledBy_sFoll'})
            ylim([0 0.8])
        end

        xticks(1:2);
        xticklabels({'ctrl','cno'});

        ylabel(feature_label);

        box off

        text(0.38,0.98,sprintf('P=%.6g', p),...
            'FontSize',28,'Units','normalized')

        set(gca,'FontSize',32,'TickDir','out');

        hoy = char(datetime('now','Format','yyyyMMdd'));

        figname = [fd '/plots/' hoy ...
            '_bar_mPFC_inact_' subject '_' feature_label];

        print(fig,figname,'-dpdf');

    end

%% ======================= PHASE 4B =======================
elseif length(uni_phase)==1 && strcmpi(uni_phase{1},'phase4b')

    uni_r_ratio = unique(cno_table.r_ratio);
    n_r_ratio = length(uni_r_ratio);

    for f = 1:n_features

        cur_feature = features{f}; 
        disp(['plotting ' cur_feature]);

        x_labels = cell(n_r_ratio,1);

        fig = figure('Position',[600 300 600 400]);
        hold on;

        for r = 1:n_r_ratio

            cur_r_ratio = uni_r_ratio{r};

            cur_cno_table = cno_table(strcmpi(cno_table.r_ratio,cur_r_ratio),:);

            sel = cur_cno_table.cno==1 & ...
                strcmpi(cur_cno_table.subject_inact,subject);

            idx = find(sel);        

            if contains(cur_feature,'m1')

                m1_before = cur_cno_table.(cur_feature)(idx-1);
                m1_cno = cur_cno_table.(cur_feature)(idx);

                m2_feature = strrep(cur_feature,'m1','m2');

                m2_before = cur_cno_table.(m2_feature)(idx-1);
                m2_cno = cur_cno_table.(m2_feature)(idx);

                before = [m1_before;m2_before];
                cno = [m1_cno;m2_cno];

                feature_label = strrep(cur_feature,'_',' ');
                feature_label = strrep(feature_label,'m1 ','');

            else

                before = cur_cno_table.(cur_feature)(idx-1);
                cno = cur_cno_table.(cur_feature)(idx);

                feature_label = strrep(cur_feature,'_',' ');

            end

            %% label replacements
            feature_label = strrep(feature_label,'p ledBy m1','p ledBy dot');
            feature_label = strrep(feature_label,'m2 95p spd','mice 95p spd');
            feature_label = strrep(feature_label,'m2 mean spd','mice mean spd');

            temp = [before cno];
            N = size(temp,1);

            %% ===== source data =====
            valid = ~isnan(before) & ~isnan(cno);

            before_valid = before(valid);
            cno_valid = cno(valid);

            diff_valid = cno_valid - before_valid;

            T_source = table( ...
                repmat({'phase4b'},sum(valid),1), ...
                repmat({subject},sum(valid),1), ...
                repmat({cur_r_ratio},sum(valid),1), ...
                repmat({cur_feature},sum(valid),1), ...
                repmat({feature_label},sum(valid),1), ...
                find(valid), ...
                before_valid, ...
                cno_valid, ...
                diff_valid, ...
                'VariableNames', ...
                {'Phase','Subject','RewardRatio','Feature','FeatureLabel', ...
                'Index','Control','CNO','Difference_CNO_minus_Control'});

            source_data = [source_data; T_source];

            %% ===== statistics =====
            [p,~,stats] = signrank(before_valid,cno_valid);

            signedrank_stat = NaN;
            zval = NaN;

            if isfield(stats,'signedrank')
                signedrank_stat = stats.signedrank;
            end

            if isfield(stats,'zval')
                zval = stats.zval;
            end

            fprintf('\n========================================\n')
            fprintf('%s | %s | reward ratio %s\n', ...
                subject, feature_label, cur_r_ratio)
            fprintf('========================================\n')
            fprintf('Test: paired Wilcoxon signed-rank test\n')
            fprintf('N = %d\n', sum(valid))
            fprintf('Signed-rank statistic = %.4f\n', signedrank_stat)

            if ~isnan(zval)
                fprintf('Z = %.4f\n', zval)
            end

            fprintf('P = %.6g\n', p)

            T_stats = table( ...
                {'phase4b'}, ...
                {subject}, ...
                {cur_r_ratio}, ...
                {cur_feature}, ...
                {feature_label}, ...
                sum(valid), ...
                signedrank_stat, ...
                zval, ...
                p, ...
                'VariableNames', ...
                {'Phase','Subject','RewardRatio','Feature', ...
                'FeatureLabel','N','SignedRankStatistic','Z','PValue'});

            stats_table = [stats_table; T_stats];

            %% ===== plot =====
            x = [1 2] + (r-1)*2;

            plot(x, temp','LineWidth',1,'Color',[0.7,0.7,0.7],...
                'Marker','.','MarkerSize',10);

            bar(x, mean(temp,"omitnan"),0.6,...
                'FaceColor','none','LineWidth',1);

            errorbar(x, mean(temp,"omitnan"),[],...
                std(temp,"omitnan")/sqrt(size(temp,1)),...
                'Color','k','LineWidth',1);

            x_labels{r} = [cur_r_ratio ' (N=' num2str(N) ')'];

            text((0.55+(r-1)*2)/(n_r_ratio*2),0.99,...
                sprintf('P=%.2g', p),...
                'FontSize',16,'Units','normalized');

        end

        xlim([0.5 n_r_ratio*2+0.5]);

        xticks(1.5:2:(r*2+0.5));
        xticklabels(x_labels);

        ylabel(feature_label);

        title(['mPFC inact ' subject ...
            ' on ' feature_label ' in phase4b']);

        box off

        set(gca,'FontSize',20,'TickDir','out');

        hoy = char(datetime('now','Format','yyyyMMdd'));

        figname = [fd '/plots/bar_mPFC_inact_' ...
            subject '_' feature_label '_p' hoy];

        print(fig,figname,'-dpdf');

    end
end

%% ===== send to workspace =====
assignin('base','source_data',source_data);
assignin('base','stats_table',stats_table);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end