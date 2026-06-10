function corr_cno_inact(fd,cno_table,feature_pair,subject,idx_shift)
% plot correlation between parameters across pairs
%
% Outputs to base workspace:
%   source_data
%   stats_table

uni_phase = unique(cno_table.phase);

source_data = table();
stats_table = table();

if length(uni_phase)==1 && strcmpi(uni_phase{1},'phase4a')

    sel_cno = cno_table.cno==1 & strcmpi(cno_table.subject_inact,subject);
    idx_cno = find(sel_cno);

    feature_x = feature_pair{1};
    feature_y = feature_pair{2};

    x = cno_table.(feature_x)(idx_cno-idx_shift);
    y = cno_table.(feature_y)(idx_cno);

    valid = ~isnan(x) & ~isnan(y);

    x_valid = x(valid);
    y_valid = y(valid);

    idx_cno_valid = idx_cno(valid);

    source_data = table( ...
        repmat({'phase4a'},sum(valid),1), ...
        repmat({subject},sum(valid),1), ...
        repmat({feature_x},sum(valid),1), ...
        repmat({feature_y},sum(valid),1), ...
        repmat(idx_shift,sum(valid),1), ...
        idx_cno_valid(:), ...
        x_valid(:), ...
        y_valid(:), ...
        'VariableNames', ...
        {'Phase','Subject','FeatureX','FeatureY','IndexShift', ...
        'CNOIndex','X','Y'});

    assignin('base','source_data',source_data);

    [r,p] = corr(x_valid,y_valid);

    mdl = fitlm(x_valid,y_valid);

    slope = mdl.Coefficients.Estimate(2);
    intercept = mdl.Coefficients.Estimate(1);
    slope_se = mdl.Coefficients.SE(2);
    slope_t = mdl.Coefficients.tStat(2);
    slope_p = mdl.Coefficients.pValue(2);
    r_squared = mdl.Rsquared.Ordinary;

    stats_table = table( ...
        {'phase4a'}, ...
        {subject}, ...
        {feature_x}, ...
        {feature_y}, ...
        idx_shift, ...
        length(x_valid), ...
        r, ...
        p, ...
        intercept, ...
        slope, ...
        slope_se, ...
        slope_t, ...
        slope_p, ...
        r_squared, ...
        'VariableNames', ...
        {'Phase','Subject','FeatureX','FeatureY','IndexShift','N', ...
        'PearsonR','PearsonP', ...
        'Intercept','Slope','SlopeSE','SlopeTStat','SlopePValue','RSquared'});

    assignin('base','stats_table',stats_table);
    assignin('base','linear_model',mdl);

    fprintf('\n========================================\n')
    fprintf('CNO inactivation correlation | %s\n', subject)
    fprintf('========================================\n')
    fprintf('Phase = phase4a\n')
    fprintf('X = %s\n', feature_x)
    fprintf('Y = %s\n', feature_y)
    fprintf('idx_shift = %d\n', idx_shift)
    fprintf('N = %d\n', length(x_valid))
    fprintf('Pearson correlation: R = %.4f, P = %.6g\n', r, p)
    fprintf('Linear regression: Y ~ X\n')
    fprintf('Intercept = %.6f\n', intercept)
    fprintf('Slope = %.6f\n', slope)
    fprintf('Slope SE = %.6f\n', slope_se)
    fprintf('Slope t = %.6f\n', slope_t)
    fprintf('Slope P = %.6g\n', slope_p)
    fprintf('R^2 = %.6f\n', r_squared)

    fig = figure('Position',[600 300 400 400]);
    hold on;

    % scatter(x,y,60,'k','filled')
    fill_color = [0.9,0.9,0.9];

    scatter(x_valid,y_valid,100, ...
        'MarkerFaceColor',fill_color, ...
        'MarkerEdgeColor','k', ...
        'LineWidth',0.1);

    % linear fit
    yCalc = linear_fit(x_valid, y_valid);

    % plot(x,yCalc,'Color',[0.2 0.2 0.2],'LineStyle','-', 'LineWidth',1);

    text(0.1,0.8,sprintf('R=%.2f P=%.2g', r, p), ...
        'FontSize',28, ...
        'Units','normalized');

    % ylim([0.5 1.03]);

    feature_x_label = feature_x;
    feature_y_label = feature_y;

    feature_x_label = strrep(feature_x_label,'_n',' normalized');
    feature_y_label = strrep(feature_y_label,'_n',' normalized');

    feature_x_label = strrep(feature_x_label,'_',' ');
    feature_y_label = strrep(feature_y_label,'_',' ');

    if idx_shift == 0
        xlabel([feature_x_label ' cno day'])
    elseif idx_shift == 1
        xlabel([feature_x_label ' before day'])
    end

    ylabel([feature_y_label ' cno day'])

    axis padded

    title(['Corr of changes in task features cno inact in ' subject])

    box off

    set(gca,'FontSize',32,'TickDir','out')

    hoy = char(datetime('now','Format','yyyyMMdd'));

    figname = [fd 'plots/' hoy '_scat_cno_inact_' subject '_' feature_x '_vs_' feature_y];

    print(fig,figname,'-dpdf');

    fprintf('\nSaved to base workspace:\n')
    fprintf('source_data\n')
    fprintf('stats_table\n')
    fprintf('linear_model\n')

elseif length(uni_phase)==1 && strcmpi(uni_phase{1},'phase4b')

    disp('to be coded')

end

end