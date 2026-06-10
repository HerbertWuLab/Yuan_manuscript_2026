%% get leadership by alignment
% compare leadership as defined by alignment
% need full ctable to calculate alignment times
%% well-trained animals
fd = 'E:\Wulab Dropbox\Lab\Yuan\ctable\ctable_20251201\';
% fd = '/Users/herbert/Wulab Dropbox/Lab/Yuan/ctable/ctable_20251201/';
ctable1 = load([fd 'behavior_ctable/ctable_with_sex.mat']).ctable;
ctable1 = select_well_trained_sessions_v2(ctable1); % only use well-trained sessions
% ctable1 = extract_ltable(ctable1); % use learning sessions
ctable1 = get_align_times_v02(ctable1);
ctable_light1 = mk_light_ctable2(ctable1);
clear ctable1
pairs_ctable1 = unique(ctable_light1.pair);

%
ctable2 = load([fd 'diff_role_pairing/ctable_with_sex.mat']).ctable;
ctable2 = select_well_trained_sessions_v2(ctable2); % only use well-trained sessions
% ctable2 = extract_ltable(ctable2);
ctable2 = get_align_times_v02(ctable2);
ctable_light2 = mk_light_ctable2(ctable2);
clear ctable2
% remove YC103-106
ctable_light2(ismember(ctable_light2.pair,pairs_ctable1),:) = [];

ctable3 = load([fd 'same_role_pairing/ctable_with_sex.mat']).ctable;
ctable3 = select_well_trained_sessions_v2(ctable3); % only use well-trained sessions
% ctable3 = extract_ltable(ctable3);
ctable3 = get_align_times_v02(ctable3);
ctable_light3 = mk_light_ctable2(ctable3);
clear ctable3
% remove YC191-YC198
ctable_light3(ismember(ctable_light3.pair,pairs_ctable1),:) = [];

ctable = [ctable_light1;ctable_light2;ctable_light3];


%%

fig = plt_align_times_v4(fd,ctable);

%% sketch for comparing leader disparity and alignment disparity

fig = figure('Position',[600 300 400 400]);
hold on;

if exist('wt_ctable','var') && ...
        ismember('lead_dsp',wt_ctable.Properties.VariableNames) && ...
        ismember('align_disparity',wt_ctable.Properties.VariableNames)

    plot_ctable = wt_ctable;

elseif ismember('lead_dsp',ctable.Properties.VariableNames) && ...
        ismember('align_disparity',ctable.Properties.VariableNames)

    plot_ctable = ctable;

else

    error('Cannot find lead_dsp and align_disparity in wt_ctable or ctable.')

end

X = plot_ctable.lead_dsp;
Y = plot_ctable.align_disparity;

source_data = table();
source_data.LeadershipDisparity = X;
source_data.AlignmentDisparity = Y;

if ismember('pair', plot_ctable.Properties.VariableNames)
    source_data.Pair = plot_ctable.pair;
end

if ismember('session', plot_ctable.Properties.VariableNames)
    source_data.Session = plot_ctable.session;
end

assignin('base','source_data',source_data);

scatter(X,Y,100,'MarkerFaceColor','none','MarkerEdgeColor','k','LineWidth',0.1);

% linear fit
yCalc = linear_fit(X,Y);

p_all = plot(X,yCalc,'Color','k', 'LineWidth',1);

axis equal
xlim([0 1])
ylim([0 1])