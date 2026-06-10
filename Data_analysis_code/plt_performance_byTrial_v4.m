% plot trial-by-trial session performance 
% trial on x axis, frame on y 
function fig = plt_performance_byTrial_v4(fd,stable)
%%
% set params
xoffset = 1; % for log scale plot
line_width = 5;
marker_size = 10;
oc_colors = {'#1a9850','#d73027','#252525'}; % outcome colors
m_colors = {'#41b6c4','#fc8d59','#969696'}; % mouse colors

% get data
% stable = ctable.stable{52}; % session 52 'YC011YC012' '20230522' 'phase4a'
stable_sel = stable((stable.correct==1|stable.mismatch==1) & ~isnan(stable.initiator),:);
n_trials = height(stable_sel);

% plot
fig = figure(Position=[1200 400 790 300]);
hold on;
% plot the trials into 4 blocks
tr_cumu = 0;
for cur_init = 1:2
    for cur_lead = 1:2
        stable_curBlock = stable_sel(stable_sel.initiator==cur_init & stable_sel.leader==cur_lead,:);
        if cur_lead == 1
            stable_sorted = sortrows(stable_curBlock,{'m1_rt','dif_rt'},{'ascend','ascend'});
        else
            stable_sorted = sortrows(stable_curBlock,{'m2_rt','dif_rt'},{'ascend','ascend'});
        end
        m1_rt = stable_sorted.m1_rt + 0.03; 
        m2_rt = stable_sorted.m2_rt + 0.03;
        % for plotting
        n_trials_curBlock = height(stable_curBlock);
        for tr_idx = 1:n_trials_curBlock
            tr_pos = tr_idx + tr_cumu;
            h_arr1 = plot(tr_pos, m1_rt(tr_idx)+xoffset,'.','Color', m_colors{1},'MarkerSize',marker_size);
            h_arr2 = plot(tr_pos, m2_rt(tr_idx)+xoffset,'.','Color', m_colors{2},'MarkerSize',marker_size);

            oc_pos = 750;
            if stable_curBlock.correct(tr_idx) == 1
                h_oc1 = line([tr_pos-0.45 tr_pos+0.45],[oc_pos oc_pos],'Color',oc_colors{1},'LineWidth',line_width);
            elseif stable_curBlock.mismatch(tr_idx) == 1
                h_oc2 = line([tr_pos-0.45 tr_pos+0.45],[oc_pos oc_pos],'Color',oc_colors{2},'LineWidth',line_width);
            else
                h_oc3 = line([tr_pos-0.45 tr_pos+0.45],[oc_pos oc_pos],'Color',oc_colors{3},'LineWidth',line_width);
            end
        
            % init
            x = [tr_pos-0.45 tr_pos tr_pos+0.45]; % X-coordinates
            y = [0.75 0.98 0.75]; % Y-coordinates (equilateral triangle)
            if cur_init == 1
                h_init1 = fill(x, y, 'k', 'EdgeColor', 'none');
                h_init1.FaceColor = m_colors{1};
            elseif cur_init == 2
                h_init2 = fill(x, y, 'k', 'EdgeColor', 'none');
                h_init2.FaceColor = m_colors{2};
            end
        end
        xline(tr_cumu+0.5,'k','LineWidth',1)
        tr_cumu = tr_cumu + n_trials_curBlock;
    end
end
xlim([0, tr_cumu + 1]); % Adjust for flipped axes
ylim([0.7 800])
yscale log
ylabel('Arrival time (frames)');
xlabel('Trial number');
title('Trial-by-trial performance');
hs = [h_init1 h_init2 h_arr1 h_arr2 h_oc1 h_oc2];
legend_names = {'m1 initiates','m2 initiates','m1 arrives','m2 arrives',...
    'correct','mismatch'};
legend(hs, legend_names,'Location','east')
legend box off
yticks([1 10 100])
yticklabels([1 10 100])
set(gca,'FontSize',16,'TickDir','out')
hoy = char(datetime('now','Format','yyyyMMdd'));
% fd = '/Users/herbert/Wulab Dropbox/Herbert/Research/Projects/SocialForaging/Behavior/';
figname = [fd 'plots/' hoy '_arrival_times'];
set(fig,'PaperOrientation','landscape');
% source data for current figure
% source data for current figure
source_data = table();

tr_cumu = 0;

for cur_init = 1:2
    for cur_lead = 1:2

        stable_curBlock = stable_sel( ...
            stable_sel.initiator==cur_init & ...
            stable_sel.leader==cur_lead,:);

        if cur_lead == 1
            stable_sorted = sortrows(stable_curBlock,...
                {'m1_rt','dif_rt'},...
                {'ascend','ascend'});
        else
            stable_sorted = sortrows(stable_curBlock,...
                {'m2_rt','dif_rt'},...
                {'ascend','ascend'});
        end

        n_trials_curBlock = height(stable_sorted);

        tmp = table();

        tmp.trial_plot = (1:n_trials_curBlock)' + tr_cumu;

        tmp.block = repmat( ...
            string(sprintf('init%d_leader%d',cur_init,cur_lead)), ...
            n_trials_curBlock,1);

        tmp.initiator = stable_sorted.initiator;
        tmp.leader = stable_sorted.leader;

        tmp.m1_arrival_frame = stable_sorted.m1_rt + 0.03;
        tmp.m2_arrival_frame = stable_sorted.m2_rt + 0.03;

        tmp.correct = stable_sorted.correct;
        tmp.mismatch = stable_sorted.mismatch;

        source_data = [source_data; tmp];

        tr_cumu = tr_cumu + n_trials_curBlock;
    end
end

assignin('base','source_data',source_data);
print(fig,figname,'-dpdf');
