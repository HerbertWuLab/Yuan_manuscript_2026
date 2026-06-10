function plot_cpRate_initiate_mean(ltable, fd, minPairs, maxDays)

if nargin < 3 || isempty(minPairs), minPairs = 3; end
if nargin < 4 || isempty(maxDays),  maxDays  = 25; end

initColor = [62 182 196] / 255;   % #3eb6c4
respColor = [246 142 93] / 255;   % #f68e5d

pair = ltable.pair;
if iscategorical(pair), pair = cellstr(pair); end
if isstring(pair), pair = cellstr(pair); end

pairs = unique(pair, 'stable');
num_pairs = numel(pairs);

lens = zeros(num_pairs,1);
for i = 1:num_pairs
    lens(i) = sum(strcmp(pair, pairs{i}));
end
maxlen = max(lens);

YI = nan(maxlen, num_pairs);
YR = nan(maxlen, num_pairs);

for i = 1:num_pairs
    idx = strcmp(pair, pairs{i});
    yI = ltable.cp_rate_initBy_sInit(idx);
    yR = ltable.cp_rate_initBy_sResp(idx);
    YI(1:numel(yI), i) = yI(:);
    YR(1:numel(yR), i) = yR(:);
end

if isfinite(maxDays)
    maxDays = min(maxDays, size(YI,1));
else
    maxDays = size(YI,1);
end

YI = YI(1:maxDays, :);
YR = YR(1:maxDays, :);

nPairs = max(sum(isfinite(YI),2), sum(isfinite(YR),2));
keep = nPairs >= minPairs;

YI = YI(keep, :);
YR = YR(keep, :);

% ==========================================
% Figure 1 removed (mean ± SD across days)
% ==========================================
% mI = mean(YI, 2, 'omitnan');
% sI = std(YI, 0, 2, 'omitnan');
% mR = mean(YR, 2, 'omitnan');
% sR = std(YR, 0, 2, 'omitnan');
% x = 1:numel(mI);
%
% figure('Color','w','Units','pixels','Position',[100 100 200 400]); hold on;
% [pI, fI] = error_shade(x, mI', sI', initColor); set(fI,'FaceAlpha',0.2);
% [pR, fR] = error_shade(x, mR', sR', respColor); set(fR,'FaceAlpha',0.2);
% yline(0.8, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5);
% xlabel('Training day');
% ylabel('Cooperation rate');
% title('Cooperation rate across training days');
% legend([pI pR], {'Initiated by initiator','Initiated by responder'}, 'Location','best');
% ax = gca; ax.TickDir = 'out'; box off;
% ylim([0 1]); yticks(0:0.5:1);
% set(gca,'FontSize',18,'TickDir','out');
% if ~isempty(fd)
%     print(gcf, fullfile(fd, 'initiate_cooperation_rate_across_training_days.pdf'), '-dpdf', '-painters');
% end

firstI = nan(num_pairs,1); lastI = nan(num_pairs,1);
firstR = nan(num_pairs,1); lastR = nan(num_pairs,1);

for i = 1:num_pairs
    yIi = YI(:,i);
    yRi = YR(:,i);

    i1I = find(isfinite(yIi), 1, 'first');
    i2I = find(isfinite(yIi), 1, 'last');
    i1R = find(isfinite(yRi), 1, 'first');
    i2R = find(isfinite(yRi), 1, 'last');

    if ~isempty(i1I) && ~isempty(i2I)
        firstI(i) = yIi(i1I);
        lastI(i)  = yIi(i2I);
    end

    if ~isempty(i1R) && ~isempty(i2R)
        firstR(i) = yRi(i1R);
        lastR(i)  = yRi(i2R);
    end
end

okI = isfinite(firstI) & isfinite(lastI);
okR = isfinite(firstR) & isfinite(lastR);

source_data_initiator = table( ...
    pairs(okI), ...
    find(okI), ...
    firstI(okI), ...
    lastI(okI), ...
    lastI(okI) - firstI(okI), ...
    repmat({'InitiatorInitiated'},sum(okI),1), ...
    'VariableNames', ...
    {'Pair','PairIndex','Day0','CriterionDay', ...
    'Difference_CriterionMinusDay0','Condition'});

source_data_responder = table( ...
    pairs(okR), ...
    find(okR), ...
    firstR(okR), ...
    lastR(okR), ...
    lastR(okR) - firstR(okR), ...
    repmat({'ResponderInitiated'},sum(okR),1), ...
    'VariableNames', ...
    {'Pair','PairIndex','Day0','CriterionDay', ...
    'Difference_CriterionMinusDay0','Condition'});

source_data = [source_data_initiator; source_data_responder];

assignin('base','source_data',source_data);

tempI = [firstI(okI) lastI(okI)];
tempR = [firstR(okR) lastR(okR)];

pI_sr = NaN;
pR_sr = NaN;
signedrank_I = NaN;
signedrank_R = NaN;
z_I = NaN;
z_R = NaN;

if size(tempI,1) >= 3
    [pI_sr,~,statsI] = signrank(tempI(:,1), tempI(:,2));
    if isfield(statsI,'signedrank')
        signedrank_I = statsI.signedrank;
    end
    if isfield(statsI,'zval')
        z_I = statsI.zval;
    end
end

if size(tempR,1) >= 3
    [pR_sr,~,statsR] = signrank(tempR(:,1), tempR(:,2));
    if isfield(statsR,'signedrank')
        signedrank_R = statsR.signedrank;
    end
    if isfield(statsR,'zval')
        z_R = statsR.zval;
    end
end

stats_table = table( ...
    {'InitiatorInitiated';'ResponderInitiated'}, ...
    {'paired Wilcoxon signed-rank';'paired Wilcoxon signed-rank'}, ...
    [size(tempI,1); size(tempR,1)], ...
    [median(tempI(:,1),'omitnan'); median(tempR(:,1),'omitnan')], ...
    [median(tempI(:,2),'omitnan'); median(tempR(:,2),'omitnan')], ...
    [median(tempI(:,2)-tempI(:,1),'omitnan'); median(tempR(:,2)-tempR(:,1),'omitnan')], ...
    [mean(tempI(:,1),'omitnan'); mean(tempR(:,1),'omitnan')], ...
    [mean(tempI(:,2),'omitnan'); mean(tempR(:,2),'omitnan')], ...
    [mean(tempI(:,2)-tempI(:,1),'omitnan'); mean(tempR(:,2)-tempR(:,1),'omitnan')], ...
    [std(tempI(:,1),'omitnan')/sqrt(size(tempI,1)); std(tempR(:,1),'omitnan')/sqrt(size(tempR,1))], ...
    [std(tempI(:,2),'omitnan')/sqrt(size(tempI,1)); std(tempR(:,2),'omitnan')/sqrt(size(tempR,1))], ...
    [signedrank_I; signedrank_R], ...
    [z_I; z_R], ...
    [pI_sr; pR_sr], ...
    'VariableNames', ...
    {'Condition','Test','N', ...
    'MedianDay0','MedianCriterionDay','MedianDifference_CriterionMinusDay0', ...
    'MeanDay0','MeanCriterionDay','MeanDifference_CriterionMinusDay0', ...
    'SEMDay0','SEMCriterionDay', ...
    'SignedRankStatistic','Z','PValue'});

assignin('base','stats_table',stats_table);

fprintf('\nInitiator-initiated trials\n')
fprintf('Test: paired Wilcoxon signed-rank test\n')
fprintf('N pairs = %d\n', size(tempI,1))
fprintf('Day 0 median = %.4f\n', median(tempI(:,1),'omitnan'))
fprintf('Criterion day median = %.4f\n', median(tempI(:,2),'omitnan'))
fprintf('Median difference = %.4f\n', median(tempI(:,2)-tempI(:,1),'omitnan'))
fprintf('Day 0 mean = %.4f\n', mean(tempI(:,1),'omitnan'))
fprintf('Criterion day mean = %.4f\n', mean(tempI(:,2),'omitnan'))
fprintf('Mean difference = %.4f\n', mean(tempI(:,2)-tempI(:,1),'omitnan'))
fprintf('Signed-rank statistic = %.4f\n', signedrank_I)
if ~isnan(z_I)
    fprintf('Z = %.4f\n', z_I)
end
fprintf('P = %.6g\n', pI_sr)

fprintf('\nResponder-initiated trials\n')
fprintf('Test: paired Wilcoxon signed-rank test\n')
fprintf('N pairs = %d\n', size(tempR,1))
fprintf('Day 0 median = %.4f\n', median(tempR(:,1),'omitnan'))
fprintf('Criterion day median = %.4f\n', median(tempR(:,2),'omitnan'))
fprintf('Median difference = %.4f\n', median(tempR(:,2)-tempR(:,1),'omitnan'))
fprintf('Day 0 mean = %.4f\n', mean(tempR(:,1),'omitnan'))
fprintf('Criterion day mean = %.4f\n', mean(tempR(:,2),'omitnan'))
fprintf('Mean difference = %.4f\n', mean(tempR(:,2)-tempR(:,1),'omitnan'))
fprintf('Signed-rank statistic = %.4f\n', signedrank_R)
if ~isnan(z_R)
    fprintf('Z = %.4f\n', z_R)
end
fprintf('P = %.6g\n', pR_sr)

color_single = [0.6 0.6 0.6];
color_med    = [0.2 0.2 0.2];

figure('Position',[600 300 200 300]); 
hold on;

tempI = [firstI(okI) lastI(okI)];

plot(tempI','LineWidth',1,'Color',color_single,...
     'Marker','.','MarkerSize',10);

yMedI = median(tempI,'omitnan');

plot(yMedI','LineWidth',3,'Color',color_med,...
     'Marker','.','MarkerSize',16);

xlim([0.5 2.5]);
xticks([1 2]);
xticklabels({'Day 0','Criterion day'});

ylabel('Cooperation rate (initiator-initiated trials)');
ylim([0 1]); 
yticks(0:0.5:1);

box off;

if size(tempI,1) >= 3
    text(0.38,0.98,sprintf('P=%.4g',pI_sr),...
         'Units','normalized','FontSize',20);
end

set(gca,'FontSize',18,'TickDir','out');

if ~isempty(fd)
    print(gcf, fullfile(fd, 'initiator_day0_vs_criterion.pdf'), '-dpdf','-painters');
end

figure('Position',[600 300 200 300]); 
hold on;

tempR = [firstR(okR) lastR(okR)];

plot(tempR','LineWidth',1,'Color',color_single,...
     'Marker','.','MarkerSize',10);

yMedR = median(tempR,'omitnan');

plot(yMedR','LineWidth',3,'Color',color_med,...
     'Marker','.','MarkerSize',16);

xlim([0.5 2.5]);
xticks([1 2]);
xticklabels({'Day 0','Criterion day'});

ylabel('Cooperation rate (responder-initiated trials)');
ylim([0 1]); 
yticks(0:0.5:1);

box off;

if size(tempR,1) >= 3
    text(0.38,0.98,sprintf('P=%.4g',pR_sr),...
         'Units','normalized','FontSize',20);
end

set(gca,'FontSize',18,'TickDir','out');

if ~isempty(fd)
    print(gcf, fullfile(fd, 'responder_day0_vs_criterion.pdf'), '-dpdf','-painters');
end

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end