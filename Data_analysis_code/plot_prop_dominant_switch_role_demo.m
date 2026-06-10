function plot_prop_dominant_switch_role(summaryData, fd)
% plot_prop_dominant_switch_role
%
% Outputs to base workspace:
%   source_data_dominant_switch_role
%   stats_table_dominant_switch_role

T = summaryData;

sexes = {'female','male'};
sex_colors = [239,154,154; 129,212,250]/255;
grey_color = [0.6 0.6 0.6];
bar_width = 0.6;

if nargin < 2 || isempty(fd)
    fd = pwd;
end

fd = char(fd);
fd = regexprep(fd, '[\\/]+$', '');

[~, last_folder] = fileparts(fd);
if strcmpi(last_folder,'plots')
    plot_dir = fd;
else
    plot_dir = fullfile(fd,'plots');
end

if ~exist(plot_dir,'dir')
    mkdir(plot_dir);
end

reqVars = ["feature","role_type","rank","m1","m2","p_ledBy_m1","p_ledBy_m2","sex"];

assert(all(ismember(reqVars, string(T.Properties.VariableNames))), ...
    'summaryData missing required columns');

isOriginal = (T.feature=="original_pair") & (T.role_type=="original_pair");
isSwapped  = (T.feature=="swapped_pairing");
hasDate = ismember("date", T.Properties.VariableNames);

roleTypes = ["LL_pairing","FF_pairing"];
sexGroups = ["female","male","all animals"];

total_by_role   = zeros(1,2);
changed_by_role = zeros(1,2);
total_by_sex    = zeros(1,3);
changed_by_sex  = zeros(1,3);

switched_role = cell(1,2);
switched_sex = cell(1,3);

for i = 1:2
    switched_role{i} = string.empty;
end

for i = 1:3
    switched_sex{i} = string.empty;
end

source_data_dominant_switch_role = table();

idxSwapped = find(isSwapped);

for ii = 1:numel(idxSwapped)

    i = idxSwapped(ii);

    if ismissing(T.rank(i))
        continue;
    end

    if T.rank(i)=="m1"

        domID = T.m1(i);
        p_swap = T.p_ledBy_m1(i);

    elseif T.rank(i)=="m2"

        domID = T.m2(i);
        p_swap = T.p_ledBy_m2(i);

    else

        continue

    end

    jCand = find(isOriginal & (T.m1==domID | T.m2==domID));

    if isempty(jCand)
        continue;
    end

    j = jCand(1);

    if numel(jCand)>1 && hasDate
        [~,o] = sort(T.date(jCand));
        j = jCand(o(1));
    end

    if T.m1(j)==domID
        p_orig = T.p_ledBy_m1(j);
    else
        p_orig = T.p_ledBy_m2(j);
    end

    switched = (p_orig>0.5) ~= (p_swap>0.5);

    cur_role_type = string(T.role_type(i));
    cur_sex = lower(string(T.sex(i)));

    T_source = table( ...
        domID, ...
        cur_sex, ...
        cur_role_type, ...
        string(T.feature(i)), ...
        string(T.rank(i)), ...
        p_orig, ...
        p_swap, ...
        switched, ...
        double(switched), ...
        'VariableNames', ...
        {'DominantMouse','Sex','RoleType','Feature','Rank', ...
        'OriginalPled','SwappedPled','SwitchedLogical','SwitchedNumeric'});

    source_data_dominant_switch_role = [source_data_dominant_switch_role; T_source];

    rIdx = find(roleTypes==cur_role_type,1);

    if ~isempty(rIdx)

        total_by_role(rIdx) = total_by_role(rIdx) + 1;

        if switched
            changed_by_role(rIdx) = changed_by_role(rIdx) + 1;
            switched_role{rIdx}(end+1) = domID;
        end
    end

    if cur_sex=="female"
        sIdx = 1;
    elseif cur_sex=="male"
        sIdx = 2;
    else
        sIdx = [];
    end

    if ~isempty(sIdx)

        total_by_sex(sIdx) = total_by_sex(sIdx) + 1;

        if switched
            changed_by_sex(sIdx) = changed_by_sex(sIdx) + 1;
            switched_sex{sIdx}(end+1) = domID;
        end
    end

    total_by_sex(3) = total_by_sex(3) + 1;

    if switched
        changed_by_sex(3) = changed_by_sex(3) + 1;
        switched_sex{3}(end+1) = domID;
    end
end

stats_table_dominant_switch_role = table();

labels_all = ["all animals","female","male","LL_pairing","FF_pairing"];

total_comb   = [total_by_sex(3),   total_by_sex(1),   total_by_sex(2),   total_by_role(1),   total_by_role(2)];
changed_comb = [changed_by_sex(3), changed_by_sex(1), changed_by_sex(2), changed_by_role(1), changed_by_role(2)];

for i = 1:numel(labels_all)

    n_total = total_comb(i);
    n_changed = changed_comb(i);

    if n_total > 0
        prop_changed = n_changed / n_total;
        p_binom = binocdf(n_changed,n_total,0.5,'upper');
    else
        prop_changed = NaN;
        p_binom = NaN;
    end

    T_stat = table( ...
        labels_all(i), ...
        n_total, ...
        n_changed, ...
        prop_changed, ...
        p_binom, ...
        'VariableNames', ...
        {'Group','NTotal','NChanged','PropChanged','BinomialP_UpperTail'});

    stats_table_dominant_switch_role = [stats_table_dominant_switch_role; T_stat];

end

assignin('base','source_data_dominant_switch_role',source_data_dominant_switch_role);
assignin('base','stats_table_dominant_switch_role',stats_table_dominant_switch_role);

fprintf("\n=== Switched dominant mice ===\n");

for k = 1:2
    fprintf("\n%s: %d / %d\n", roleTypes(k), changed_by_role(k), total_by_role(k));
    disp(unique(switched_role{k}))
end

for k = 1:3
    fprintf("\n%s: %d / %d\n", sexGroups(k), changed_by_sex(k), total_by_sex(k));
    disp(unique(switched_sex{k}))
end

fprintf('\nDominant switch role statistics\n')
fprintf('========================================\n')
disp(stats_table_dominant_switch_role)

fig = figure('Color','w'); 
hold on

xlabels = ["all animals","female","male","LL_pairing","FF_pairing"];
x = 1:numel(xlabels);

bar(x, total_comb, bar_width, ...
    'FaceColor','none', ...
    'EdgeColor','k', ...
    'LineWidth',1.3);

changed_colors = repmat(grey_color, numel(x), 1);
changed_colors(2,:) = sex_colors(1,:);
changed_colors(3,:) = sex_colors(2,:);

for i = 1:numel(x)
    bar(x(i), changed_comb(i), bar_width, ...
        'FaceColor', changed_colors(i,:), ...
        'EdgeColor','k', ...
        'LineWidth',1.3);
end

xticks(x); 
xticklabels(xlabels);

set(gca,'TickLabelInterpreter','none');

ylabel('Number of dominant mice','Interpreter','none');
title('Dominant role switching counts','Interpreter','none');

set(gca,'TickDir','out');

ylim([0 max(total_comb)+2]);

box off

outFile = fullfile(plot_dir,'dominant_switch_counts_combined.pdf');

print(fig, outFile, '-dpdf','-vector');

fprintf('\nSaved figure: %s\n', outFile)
fprintf('Saved to base workspace:\n')
fprintf('source_data_dominant_switch_role\n')
fprintf('stats_table_dominant_switch_role\n')

end