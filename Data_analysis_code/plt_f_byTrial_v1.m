function fig = plt_f_byTrial_v1(f_array, mask, stable_sel, params)
% plot dff trial by trial

%% get params
fd = params.fd; 
date = params.date;
animal = params.animal;
role = params.role;
sortBy = params.sortBy;
alignBy = params.alignBy;
event_times = params.event_times;
time_idx = params.time_idx;
align_idx = params.align_idx;
t_range = params.t_range;
mask_opt = params.mask_opt;
n_cells = size(f_array,3);
self_id = params.id;
m_num = str2double(self_id(2));
other_id = ['m' num2str(3-m_num)];
m_identities = {'self','other'};
if m_num==1
    sort_order = 'ascend';
    m_sort = [1 2];
elseif m_num==2
    sort_order = 'descend';
    m_sort = [2 1];
end

%% set params
hoy = char(datetime('now','Format','yyyyMMdd'));
outcome_colors = [166,217,106; % correct
                253,174,97; % mismatch
                215,25,28]/255; % unreward
% time_colors = [255 255 255; % trial start
%     65,182,196; % m1 arrival
%     247,104,161; % m2 arrival
%     255,255,191; % trial end
%     ]/255; 
if m_num==1 & strcmp(role,'leader') || m_num==2 & strcmp(role,'follower')
    time_colors = [255 255 255; % trial start
                    194, 165, 207; % m1 arrival
                    166, 219, 160; % m2 arrival
                    255,255,191; % trial end
                    ]/255;   
else
    time_colors = [255 255 255; % trial start
                    166, 219, 160; % m1 arrival
                    194, 165, 207; % m2 arrival
                    255,255,191; % trial end
                    ]/255;   
end
% tt_colors = {'#7a0177','#f768a1','#006837','#78c679',...
%     '#253494','#41b6c4','#993404','#fe9929'};
tt_colors = [122,1,119;
    247,104,161;
    153,52,4;
    254,153,41
    0,104,55;
    120,198,121;
    37,52,148;
    65,182,196]/255;
txt_xpos = -5;
txt_xpos2 = 6;
outcome_pos = 8;
xlim_pos = 10;
params.tt_colors = tt_colors;
zones = {'E','S','W','N'};
if strcmp(role,'leader')
    colors_zone = {'#e7d4e8';'#c2a5cf';'#9970ab';'#762a83'}; % leader
    colors_bar = {'#9970ab','#f7f7f7'}; 
    colors_txt = {'#f7f7f7';'#9970ab'};
elseif strcmp(role,'follower')
    colors_zone = {'#d9f0d3';'#a6dba0';'#5aae61';'#1b7837'}; % follower
    colors_bar = {'#5aae61','#f7f7f7'}; 
    colors_txt = {'#f7f7f7';'#5aae61'};
end

%% apply mask if necessary
if strcmp(mask_opt,'on')
    f_array = f_array.*mask;
end

%% sort trials
switch sortBy
    case 'SelfZone'
        stable_sel.self_rt = stable_sel.([self_id '_last_arr']) - stable_sel.led_init;
        [stable_sorted,idx_sort] = sortrows(stable_sel,{'self_zone','dur_f'},{'ascend','ascend'});
        % stable_sorted.group = string(stable_sorted.self_zone);
        stable_sorted.sortBy = stable_sorted.self_zone;
    case 'OtherZone'
        [stable_sorted,idx_sort] = sortrows(stable_sel,{'other_zone','dur_f'},{'ascend','ascend'});
        % stable_sorted.group = string(stable_sorted.other_zone); 
        stable_sorted.sortBy = stable_sorted.other_zone;
    case 'Leader' % sort by arrival time
        stable_sel.arr_dif = stable_sel.([self_id '_last_arr']) - stable_sel.([other_id '_last_arr']);
        sel_trials = ~isnan(stable_sel.leader); % remove trials when there is a tie
        stable_sel = stable_sel(sel_trials,:);
        f_array = f_array(sel_trials,:,:);
        event_times = event_times(sel_trials,:);
        [stable_sorted,idx_sort] = sortrows(stable_sel,{'leader','arr_dif'},{sort_order,'ascend'});
        stable_sorted.sortBy = stable_sorted.leader;
    % case 'Leader & ArrivalTime'
    %     stable_sel.arr_dif = stable_sel.([self_id '_last_arr']) - stable_sel.([other_id '_last_arr']);
    %     sel_trials = ~isnan(stable_sel.leader); % remove trials when there is a tie
    %     stable_sel = stable_sel(sel_trials,:);
    %     f_array = f_array(sel_trials,:,:);
    %     event_times = event_times(sel_trials,:);
    %     [stable_sorted,idx_sort] = sortrows(stable_sel,{'leader','arr_dif'},{sort_order,'ascend'});
    %     stable_sorted.sortBy = stable_sorted.leader;
    case 'SelfZone & Leader'
        sel_trials = ~isnan(stable_sel.leader); % remove trials when there is a tie
        stable_sel = stable_sel(sel_trials,:);
        f_array = f_array(sel_trials,:,:);
        event_times = event_times(sel_trials,:);
        [stable_sorted,idx_sort] = sortrows(stable_sel,{'self_zone','leader','dur_f'},{'ascend',sort_order,'ascend'});
        stable_sorted.sortBy = stable_sorted.leader;
        stable_sorted.group = strcat(string(stable_sorted.self_zone), string(stable_sorted.leader));
    case 'SelfZone & Initiator'
        sel_trials = ~isnan(stable_sel.initiator); % remove trials when there is a tie
        stable_sel = stable_sel(sel_trials,:);
        f_array = f_array(sel_trials,:,:);
        event_times = event_times(sel_trials,:);
        [stable_sorted,idx_sort] = sortrows(stable_sel,{'self_zone','initiator','dur_f'},{'ascend',sort_order,'ascend'});
        stable_sorted.sortBy = stable_sorted.initiator;
        % stable_sorted.group = strcat(string(stable_sorted.self_zone), string(stable_sorted.initiator));
    case 'SelfRT & SelfWait'
        stable_sel.self_rt = stable_sel.([self_id '_last_arr']) - stable_sel.led_init;
        stable_sel.self_wait = stable_sel.led_end - stable_sel.([self_id '_last_arr']);
        sel_trials = ~isnan(stable_sel.([self_id '_last_arr'])) & stable_sel.self_rt < 90 ...
            & stable_sel.self_wait < 60 & stable_sel.self_rt > 0; 
        stable_sel = stable_sel(sel_trials,:);
        f_array = f_array(sel_trials,:,:);
        event_times = event_times(sel_trials,:);
        [stable_sorted,idx_sort] = sortrows(stable_sel,{'self_rt','self_wait'},{sort_order,'ascend'});
end
f_array_sorted = f_array(idx_sort,:,:);
event_times = event_times(idx_sort,:);
n_sel_trials = height(stable_sorted);

%% plot trial-by-trial f
if isfield(params,'cell_list')
    cell_list = params.cell_list;
    cell_list = cell_list(cell_list<200);
else
    cell_list = 1:50;
    % cell_list = 28;
    % cell_list = 1:n_cells;
end
for r = cell_list
    cur_f_array = f_array_sorted(:,:,r);
    % plot individual f traces
    fig = figure('Position',[600 300 400 400],'Visible','on'); 
    hold on;
    y = [1 n_sel_trials];
    h = imagesc(t_range, y, cur_f_array);
    set(h, 'AlphaData', ~isnan(cur_f_array));
    set(gca,'YDir','normal')
    colormap(fig,"copper")
    cb = colorbar;
    cb.TickDirection = 'out';
    ylabel(cb,'dF/F')
    xlabel(['Time from ' alignBy ' (s)']);
    ylabel('Trial no. (sorted)');

    % add dashed line for alignment event
    plot([0,0],[0 n_sel_trials+1],'Color',time_colors(align_idx,:),...
        'LineStyle','-','LineWidth',2);

    if strcmp(alignBy,'SelfArrival') || strcmp(alignBy,'OtherArrival') 
        t_plot = 1; % only plot trial start
    elseif strcmp(alignBy,'TrialEnd')
        t_plot = 1;
    else
        t_plot = 1:3; % plot trialstart, other's arrival and trialend
    end
    if strcmp(sortBy,'SelfRT & SelfWait')
        t_plot = [1 3];
    elseif strcmp(sortBy,'Leader')
        t_plot = 2;
    end

    % % add arrival times, trial end and trial outcome
    for i = 1:n_sel_trials
        % hold on;
        for t = t_plot
            plot([event_times(i,t) event_times(i,t)],[i-0.5,i+0.5],'Color',time_colors(time_idx(t),:),'LineWidth',2);
        end
        % plot([t2(i) t2(i)],[i-0.5,i+0.5],'Color',time_colors(time_idx(2),:),'LineWidth',2);
        % plot([t3(i) t3(i)],[i-0.5,i+0.5],'Color',time_colors(time_idx(3),:),'LineWidth',2);

        % add trial number for reference
        % text(200,i,num2str(stable_sorted.m2_port(i)),'FontSize',8,'Color','w');
        % text(t_range(2)-30,i,num2str(stable_sorted.trial_no2(i)),'FontSize',6,'Color','c');
        
        % trial outcome
        % outcome_idx = [stable_sorted.correct(i) stable_sorted.mismatch(i) stable_sorted.unreward(i)]'==1;
        % outcome_color = outcome_colors(outcome_idx,:);
        % scatter(outcome_pos+t_range(1),i,50,outcome_color,"filled");
    end

    % add text indicating sortBy
    if strcmp(sortBy,'SelfZone & Leader') || strcmp(sortBy,'SelfZone & Initiator')
        n_trials = 0;
        for z = 1:4
            cur_sum_zone = sum(stable_sorted.self_zone==z);
            plot([txt_xpos+t_range(1),txt_xpos+t_range(1)],[n_trials+0.5,n_trials+cur_sum_zone+0.5],...
                'Color',colors_zone{z},'linewidth',14);
            txt = text(txt_xpos+t_range(1),cur_sum_zone/2+n_trials,zones{z},...
                'Color','k','FontSize',14, HorizontalAlignment='center');
            set(txt,'Rotation',90);
            colors_bar = [0.8 0.8 0.8;0.2 0.2 0.2];
            colors_txt = [0.2 0.2 0.2;0.8 0.8 0.8];
            for a = 1:2
                cur_sum_sortBy = sum(stable_sorted.self_zone==z & stable_sorted.sortBy==m_sort(a));
                plot([txt_xpos2+t_range(1),txt_xpos2+t_range(1)],[n_trials+0.5,n_trials+cur_sum_sortBy+0.5],...
                    'Color',colors_bar(a,:),'linewidth',14);  
                txt = text(txt_xpos2+t_range(1),cur_sum_sortBy/2+n_trials,m_identities{a},...
                    'Color',colors_txt(a,:),'FontSize',14, HorizontalAlignment='center'); 
                set(txt,'Rotation',90);
                n_trials = n_trials + cur_sum_sortBy;
            end
        end
        % group_names = unique(stable_sorted.group);
        % n_groups = length(group_names);
    elseif strcmp(sortBy,'SelfZone') || strcmp(sortBy,'OtherZone')
        n_trials = 0;
        for z = 1:4
            cur_sum_sortBy = sum(stable_sorted.sortBy==z);
            plot([txt_xpos+t_range(1),txt_xpos+t_range(1)],[n_trials+0.5,n_trials+cur_sum_sortBy+0.5],...
                'Color',colors_zone{z},'linewidth',14);
            txt = text(txt_xpos+t_range(1),cur_sum_sortBy/2+n_trials,zones{z},...
                'Color','k','FontSize',14, HorizontalAlignment='center');
            set(txt,'Rotation',90);
            n_trials = n_trials + cur_sum_sortBy;
        end
    elseif strcmp(sortBy,'Leader')
        n_trials = 0;
        for a = 1:2
            cur_sum_sortBy = sum(stable_sorted.sortBy==m_sort(a));
            plot([txt_xpos+t_range(1),txt_xpos+t_range(1)],[n_trials+0.5,n_trials+cur_sum_sortBy+0.5],...
                'Color',colors_bar{a},'linewidth',14);  
            txt = text(txt_xpos+t_range(1),cur_sum_sortBy/2+n_trials,m_identities{a},...
                'Color',colors_txt{a},'FontSize',14, HorizontalAlignment='center'); 
            set(txt,'Rotation',90);
            n_trials = n_trials + cur_sum_sortBy;
        end
    elseif strcmp(sortBy, 'SelfRT & SelfWait')
        t_range = [-75 70];
    end
    
    %     for g = 1:n_groups 
    %         m1_group_name = group_names{g};
    %         cur_sum = sum(strcmp(stable_sorted.group,m1_group_name));
    %         plot([txt_xpos+t_range(1),txt_xpos+t_range(1)],[cum_sum+0.5,cum_sum+cur_sum+0.5],...
    %             'Color',tt_colors(g,:),'linewidth',14);
    %         % cur_txt = [sortBy_name(1) m1_group_name(1) '-' sortBy_name(2) m1_group_name(2)];
    %         cur_txt = [zones{g}(1) '-m' m1_group_name(2)];
    %         txt = text(txt_xpos+t_range(1),cur_sum/2+cum_sum,cur_txt,...
    %             'Color','w','FontSize',14, HorizontalAlignment='center');
    %         if mod(g,2)==0
    %             txt_xpos2 = 5;
    %         plot([txt_xpos2+t_range(1),txt_xpos2+t_range(1)],[cum_sum+0.5,cum_sum+cur_sum+0.5],...
    %             'Color',tt_colors(g,:),'linewidth',14);
    % 
    % group_names = unique(stable_sorted.group);
    % n_groups = length(group_names);
    % cum_sum = 0;
    % for g = 1:n_groups 
    %     m1_group_name = group_names{g};
    %     cur_sum = sum(strcmp(stable_sorted.group,m1_group_name));
    %     if strcmp(sortBy,'RewardZone & Leader') || strcmp(sortBy,'RewardZone & Initiator')
    %         plot([txt_xpos+t_range(1),txt_xpos+t_range(1)],[cum_sum+0.5,cum_sum+cur_sum+0.5],...
    %             'Color',tt_colors(g,:),'linewidth',14);
    %         % cur_txt = [sortBy_name(1) m1_group_name(1) '-' sortBy_name(2) m1_group_name(2)];
    %         cur_txt = [zones{g}(1) '-m' m1_group_name(2)];
    %         txt = text(txt_xpos+t_range(1),cur_sum/2+cum_sum,cur_txt,...
    %             'Color','w','FontSize',14, HorizontalAlignment='center');
    %         if mod(g,2)==0
    %             txt_xpos2 = 5;
    %         plot([txt_xpos2+t_range(1),txt_xpos2+t_range(1)],[cum_sum+0.5,cum_sum+cur_sum+0.5],...
    %             'Color',tt_colors(g,:),'linewidth',14);
    %     elseif strcmp(sortBy,'SelfZone') || strcmp(sortBy,'OtherZone')
    %         plot([txt_xpos+t_range(1),txt_xpos+t_range(1)],[cum_sum+0.5,cum_sum+cur_sum+0.5],...
    %             'Color',zone_colors{g},'linewidth',14);
    %         txt = text(txt_xpos+t_range(1),cur_sum/2+cum_sum,zones{g},...
    %             'Color','k','FontSize',14, HorizontalAlignment='center');
    %     end
    %     set(txt,'Rotation',90);
    %     cum_sum = cum_sum + cur_sum;
    %     end

    % adjust lim and save
    % xlim([-25 n_frames_trial])
    caption = sprintf([animal ' ' date ' ROI #%03d sortBy ' sortBy], r);
    title(caption);
    set(gca,'FontSize',28,'TickDir','out');
    xlim([t_range(1)-xlim_pos t_range(2)])
    % xlim([t_range(1)-xlim_pos 70])
    xticks(-120:30:150)
    xticklabels(-4:5)
    ylim([0 n_sel_trials+1])
    sortbyname = strrep(sortBy, ' ', '_');
    fd_plot = [fd '/plots'];
    if ~exist(fd_plot, 'dir')
        mkdir(fd_plot); % if the folder does not exist, create it
    end
    figname = sprintf([fd '/plots/' hoy 'p_' animal '_' date '_roi#%03d_hmap_sortBy_' sortbyname '_alignBy_' alignBy], r);
    % set(fig,'PaperUnits','normalized','PaperPosition', [0 0 1 1]);
    print(fig,figname,'-dpdf');
    % close(fig);
end
