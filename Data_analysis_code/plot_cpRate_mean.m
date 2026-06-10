function plot_cpRate_mean(ltable, fd, minPairs, maxDays)

if nargin < 3 || isempty(minPairs), minPairs = 3; end
if nargin < 4 || isempty(maxDays),  maxDays  = 25; end

leaderColor   = [153 112 171] / 255;   % #9970ab
followerColor = [88 174 95]  / 255;    % #58ae5f

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

YL = nan(maxlen, num_pairs);
YF = nan(maxlen, num_pairs);

for i = 1:num_pairs
    idx = strcmp(pair, pairs{i});
    yL = ltable.cp_rate_ledBy_sLead(idx);
    yF = ltable.cp_rate_ledBy_sFoll(idx);
    YL(1:numel(yL), i) = yL(:);
    YF(1:numel(yF), i) = yF(:);
end

if isfinite(maxDays)
    maxDays = min(maxDays, size(YL,1));
else
    maxDays = size(YL,1);
end
YL = YL(1:maxDays, :);
YF = YF(1:maxDays, :);

nPairs = max(sum(isfinite(YL),2), sum(isfinite(YF),2));
keep = nPairs >= minPairs;
YL = YL(keep, :);
YF = YF(keep, :);

% ===============================
% Figure 1 removed (do not plot)
% ===============================
% mL = mean(YL, 2, 'omitnan');
% sL = std(YL, 0, 2, 'omitnan');
% mF = mean(YF, 2, 'omitnan');
% sF = std(YF, 0, 2, 'omitnan');
% x = 1:numel(mL);
% figure('Color','w','Units','pixels','Position',[100 100 200 300]); hold on;
% [pL, fL] = error_shade(x, mL', sL', leaderColor);   set(fL,'FaceAlpha',0.2);
% [pF, fF] = error_shade(x, mF', sF', followerColor); set(fF,'FaceAlpha',0.2);
% yline(0.8, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5);
% xlabel('Training day');
% ylabel('Cooperation rate');
% title('Cooperation rate across training days');
% legend([pL pF], {'Led by leader','Led by follower'}, 'Location','best');
% ax = gca; ax.TickDir = 'out'; box off;
% ylim([0 1]); yticks(0:0.5:1);
% set(gca,'FontSize',18,'TickDir','out');
% if ~isempty(fd)
%     print(gcf, fullfile(fd, 'cooperation_rate_across_training_days.pdf'), '-dpdf', '-painters');
% end

firstL = nan(num_pairs,1); lastL = nan(num_pairs,1);
firstF = nan(num_pairs,1); lastF = nan(num_pairs,1);

for i = 1:num_pairs
    yLi = YL(:,i);
    yFi = YF(:,i);

    i1L = find(isfinite(yLi), 1, 'first');
    i2L = find(isfinite(yLi), 1, 'last');
    i1F = find(isfinite(yFi), 1, 'first');
    i2F = find(isfinite(yFi), 1, 'last');

    if ~isempty(i1L) && ~isempty(i2L)
        firstL(i) = yLi(i1L);
        lastL(i)  = yLi(i2L);
    end
    if ~isempty(i1F) && ~isempty(i2F)
        firstF(i) = yFi(i1F);
        lastF(i)  = yFi(i2F);
    end
end

okL = isfinite(firstL) & isfinite(lastL);
okF = isfinite(firstF) & isfinite(lastF);

source_data_leader = table( ...
    pairs(okL), ...
    find(okL), ...
    firstL(okL), ...
    lastL(okL), ...
    lastL(okL) - firstL(okL), ...
    repmat({'LeaderLed'},sum(okL),1), ...
    'VariableNames', ...
    {'Pair','PairIndex','Day0','CriterionDay','Difference_CriterionMinusDay0','Condition'});

source_data_follower = table( ...
    pairs(okF), ...
    find(okF), ...
    firstF(okF), ...
    lastF(okF), ...
    lastF(okF) - firstF(okF), ...
    repmat({'FollowerLed'},sum(okF),1), ...
    'VariableNames', ...
    {'Pair','PairIndex','Day0','CriterionDay','Difference_CriterionMinusDay0','Condition'});

source_data = [source_data_leader; source_data_follower];

assignin('base','source_data',source_data);

tempL = [firstL(okL) lastL(okL)];
tempF = [firstF(okF) lastF(okF)];

pL_sr = NaN;
pF_sr = NaN;
signedrank_L = NaN;
signedrank_F = NaN;
z_L = NaN;
z_F = NaN;

if size(tempL,1) >= 3
    [pL_sr,~,statsL] = signrank(tempL(:,1), tempL(:,2));
    if isfield(statsL,'signedrank')
        signedrank_L = statsL.signedrank;
    end
    if isfield(statsL,'zval')
        z_L = statsL.zval;
    end
end

if size(tempF,1) >= 3
    [pF_sr,~,statsF] = signrank(tempF(:,1), tempF(:,2));
    if isfield(statsF,'signedrank')
        signedrank_F = statsF.signedrank;
    end
    if isfield(statsF,'zval')
        z_F = statsF.zval;
    end
end

stats_table = table( ...
    {'LeaderLed';'FollowerLed'}, ...
    {'paired Wilcoxon signed-rank';'paired Wilcoxon signed-rank'}, ...
    [size(tempL,1); size(tempF,1)], ...
    [median(tempL(:,1),'omitnan'); median(tempF(:,1),'omitnan')], ...
    [median(tempL(:,2),'omitnan'); median(tempF(:,2),'omitnan')], ...
    [median(tempL(:,2)-tempL(:,1),'omitnan'); median(tempF(:,2)-tempF(:,1),'omitnan')], ...
    [mean(tempL(:,1),'omitnan'); mean(tempF(:,1),'omitnan')], ...
    [mean(tempL(:,2),'omitnan'); mean(tempF(:,2),'omitnan')], ...
    [mean(tempL(:,2)-tempL(:,1),'omitnan'); mean(tempF(:,2)-tempF(:,1),'omitnan')], ...
    [std(tempL(:,1),'omitnan')/sqrt(size(tempL,1)); std(tempF(:,1),'omitnan')/sqrt(size(tempF,1))], ...
    [std(tempL(:,2),'omitnan')/sqrt(size(tempL,1)); std(tempF(:,2),'omitnan')/sqrt(size(tempF,1))], ...
    [signedrank_L; signedrank_F], ...
    [z_L; z_F], ...
    [pL_sr; pF_sr], ...
    'VariableNames', ...
    {'Condition','Test','N', ...
    'MedianDay0','MedianCriterionDay','MedianDifference_CriterionMinusDay0', ...
    'MeanDay0','MeanCriterionDay','MeanDifference_CriterionMinusDay0', ...
    'SEMDay0','SEMCriterionDay', ...
    'SignedRankStatistic','Z','PValue'});

assignin('base','stats_table',stats_table);

fprintf('\nLeader-led trials\n')
fprintf('Test: paired Wilcoxon signed-rank test\n')
fprintf('N pairs = %d\n', size(tempL,1))
fprintf('Day 0 median = %.4f\n', median(tempL(:,1),'omitnan'))
fprintf('Criterion day median = %.4f\n', median(tempL(:,2),'omitnan'))
fprintf('Median difference = %.4f\n', median(tempL(:,2)-tempL(:,1),'omitnan'))
fprintf('Day 0 mean = %.4f\n', mean(tempL(:,1),'omitnan'))
fprintf('Criterion day mean = %.4f\n', mean(tempL(:,2),'omitnan'))
fprintf('Mean difference = %.4f\n', mean(tempL(:,2)-tempL(:,1),'omitnan'))
fprintf('Signed-rank statistic = %.4f\n', signedrank_L)
if ~isnan(z_L)
    fprintf('Z = %.4f\n', z_L)
end
fprintf('P = %.6g\n', pL_sr)

fprintf('\nFollower-led trials\n')
fprintf('Test: paired Wilcoxon signed-rank test\n')
fprintf('N pairs = %d\n', size(tempF,1))
fprintf('Day 0 median = %.4f\n', median(tempF(:,1),'omitnan'))
fprintf('Criterion day median = %.4f\n', median(tempF(:,2),'omitnan'))
fprintf('Median difference = %.4f\n', median(tempF(:,2)-tempF(:,1),'omitnan'))
fprintf('Day 0 mean = %.4f\n', mean(tempF(:,1),'omitnan'))
fprintf('Criterion day mean = %.4f\n', mean(tempF(:,2),'omitnan'))
fprintf('Mean difference = %.4f\n', mean(tempF(:,2)-tempF(:,1),'omitnan'))
fprintf('Signed-rank statistic = %.4f\n', signedrank_F)
if ~isnan(z_F)
    fprintf('Z = %.4f\n', z_F)
end
fprintf('P = %.6g\n', pF_sr)

figure('Position',[600 300 200 300]); hold on;
color_single = [0.6 0.6 0.6];
color_med    = [0.2 0.2 0.2];

plot(tempL','LineWidth',1,'Color',color_single,...
     'Marker','.','MarkerSize',10);

yMedL = median(tempL,'omitnan');
plot(yMedL','LineWidth',3,'Color',color_med,...
     'Marker','.','MarkerSize',16);

xlim([0.5 2.5]);
xticks([1 2]);
xticklabels({'Day 0','Criterion day'});

ylabel('Cooperation rate (leader-led trials)');
ylim([0 1]); yticks(0:0.5:1);
box off;

if size(tempL,1) >= 3
    text(0.38,0.98,sprintf('P=%.4g',pL_sr),...
         'Units','normalized','FontSize',20);
end

set(gca,'FontSize',18,'TickDir','out');

if ~isempty(fd)
    print(gcf, fullfile(fd, 'leader_day0_vs_criterion.pdf'), '-dpdf','-painters');
end

figure('Position',[600 300 200 300]); hold on;

plot(tempF','LineWidth',1,'Color',color_single,...
     'Marker','.','MarkerSize',10);

yMedF = median(tempF,'omitnan');
plot(yMedF','LineWidth',3,'Color',color_med,...
     'Marker','.','MarkerSize',16);

xlim([0.5 2.5]);
xticks([1 2]);
xticklabels({'Day 0','Criterion day'});

ylabel('Cooperation rate (follower-led trials)');
ylim([0 1]); yticks(0:0.5:1);
box off;

if size(tempF,1) >= 3
    text(0.38,0.98,sprintf('P=%.4g',pF_sr),...
         'Units','normalized','FontSize',20);
end

set(gca,'FontSize',18,'TickDir','out');

if ~isempty(fd)
    print(gcf, fullfile(fd, 'follower_day0_vs_criterion.pdf'), '-dpdf','-painters');
end

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end