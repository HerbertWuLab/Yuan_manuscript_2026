function fig = plt_init_prop_oneSession_v2(fd,stable)
%{
plot initiator proportions in one session
horizontal bar
%}

% set params
oc_colors = {'#31a354','#bd0026','#252525'}; % outcome colors
m_colors = [65 182 196; 252 141 89; 150 150 150]/255; % mouse colors

% get data
stable_sel = stable((stable.correct==1|stable.mismatch==1) & ~isnan(stable.initiator),:);
n_trials = height(stable_sel);

m1_lead_prop = mean(stable_sel.initiator==1);
m2_lead_prop = mean(stable_sel.initiator==2);

% source data
source_data = table( ...
    {'m1'; 'm2'}, ...
    [1; 2], ...
    [sum(stable_sel.initiator==1); sum(stable_sel.initiator==2)], ...
    [m1_lead_prop; m2_lead_prop], ...
    repmat(n_trials,2,1), ...
    'VariableNames', ...
    {'Mouse','MouseID','NInitiatedTrials','ProportionInitiated','NTrialsTotal'});

assignin('base','source_data',source_data);

% plot
fig = figure(Position=[200 200 300 200]);
hold on;

b = barh([m1_lead_prop m2_lead_prop],'FaceColor','flat');
b.CData(1,:) = m_colors(1,:);
b.CData(2,:) = m_colors(2,:);

yticks([1 2])
yticklabels({'m1','m2'})
ylabel('Mouse');
xlabel(['Proportion of trials (N=' num2str(n_trials) ')']);
title('Initiates trial');

set(gca,'FontSize',20,'TickDir','out')

hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_initiates_trial_prop_oneSession'];
print(fig,figname,'-dpdf');