function plot_cprate_indiv_initiation(ltable, fd, maxDays)
% Plot individual-pair initiation curves (long table).
% Lines only (no markers).
% Colors:
%   responder (cp_rate_initBy_sResp): cyan
%   initiator (cp_rate_initBy_sInit): magenta

if nargin < 3 || isempty(maxDays), maxDays = 25; end

respColor = [128,205,193] / 255;   % #dd8452
initColor = [223,194,125] / 255;   % #4c72b0
 pair = ltable.pair;
if iscategorical(pair), pair = cellstr(pair); end
if isstring(pair), pair = cellstr(pair); end

pairs = unique(pair, 'stable');
num_pairs = numel(pairs);

figure('Position',[600 300 200 400]); hold on;

for i = 1:num_pairs
    idx = strcmp(pair, pairs{i});

    yInit = ltable.cp_rate_initBy_sInit(idx); yInit = yInit(:);
    yResp = ltable.cp_rate_initBy_sResp(idx); yResp = yResp(:);

    n = min([numel(yInit), numel(yResp), maxDays]);
    if n < 1, continue; end

    x = 1:n;

    plot(x, yResp(1:n), 'LineWidth', 1, 'Color', respColor);
    plot(x, yInit(1:n), 'LineWidth', 1, 'Color', initColor);
end

yline(0.8, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5);

xlim([0.5 maxDays+0.5]);
xlabel('Training day');
ylabel('Cooperation rate');
title('Cooperation rate across training days (individual pairs)');

hR = plot(nan, nan, '-', 'LineWidth', 2, 'Color', respColor);
hI = plot(nan, nan, '-', 'LineWidth', 2, 'Color', initColor);
legend([hI hR], {'Initiated by initiator','Initiated by responder'}, 'Location','best');

ylim([0 1]);
yticks(0:0.5:1);

set(gca,'FontSize',18,'TickDir','out');
box off;

if ~isempty(fd)
    filename = fullfile(fd, 'initiation_cooperation_rate_individual_pairs.pdf');
    print(gcf, filename, '-dpdf', '-painters');
end

end