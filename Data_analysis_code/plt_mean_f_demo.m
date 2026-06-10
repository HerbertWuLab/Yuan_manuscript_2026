function fig = plt_mean_f_demo(f_array, mask, stable_sel, params)
% plot mean dff and sem in line and shaded region

%% set params
hoy = char(datetime('now','Format','yyyyMMdd'));
fd = params.fd; 
date = params.date;
animal = params.animal;
role = params.role;

sortBy = params.sortBy;
alignBy = params.alignBy;
t_array = params.t_array;

f_array_length = size(f_array,2);
n_cells = size(f_array,3);
val_trial_cutoff = params.val_trial_cutoff; % minimal no. of trials in a group

self_id = params.id;
self_num = str2double(self_id(2));
other_num = 3 - self_num;
m_nums = [self_num other_num];
m_legend = {'self lead','other lead'};
if strcmp(role,'leader')
    zone_colors = {'#c2a5cf';'#9970ab';'#762a83';'#531e5c'}; % leader one shade darker  
    m_color = '#9970ab';
elseif strcmp(role,'follower')
    zone_colors = {'#a6dba0';'#5aae61';'#1b7837';'#0f4d2b'}; % follower one shade darker
    m_color = '#5aae61';
end
zone_names = {'East','South','West','North'};
linestyles = {'-','--'};
facealphas = [0.4, 0.2];

%% apply mask
f_array = f_array.*mask;

%% sort
switch sortBy
    case 'SelfZone'
        stable_sel.group = string(stable_sel.self_zone);
    case 'OtherZone'
        stable_sel.group = string(stable_sel.other_zone);   
    case 'Leader'
        sel_trials = ~isnan(stable_sel.leader); % remove trials when there is a tie
        stable_sel = stable_sel(sel_trials,:);
        f_array = f_array(sel_trials,:,:);
        stable_sel.group = string(stable_sel.leader);   
    case 'SelfZone & Leader'
        sel_trials = ~isnan(stable_sel.leader); % remove trials when there is a tie
        stable_sel = stable_sel(sel_trials,:);
        f_array = f_array(sel_trials,:,:);
        stable_sel.group = strcat(string(stable_sel.self_zone), string(stable_sel.leader));
    case 'SelfZone & Initiator'
        sel_trials = ~isnan(stable_sel.initiator); % remove trials when there is a tie
        stable_sel = stable_sel(sel_trials,:);
        f_array = f_array(sel_trials,:,:);
        stable_sel.group = strcat(string(stable_sel.self_zone), string(stable_sel.initiator));
end
group_names = unique(stable_sel.group);
n_groups = length(group_names);

%% plot mean with standard error
if isfield(params,'cell_list')
    cell_list = params.cell_list;
    cell_list = cell_list(cell_list<200);
else
    cell_list = 1:20;
end
for r = cell_list
    cur_f_array = f_array(:,:,r);

    % get the mean and sem
    means = zeros(n_groups,f_array_length);
    sems = zeros(n_groups,f_array_length);
    counts = zeros(n_groups,f_array_length);

    for g = 1:n_groups 
        cur_group_name = group_names{g};
        idx = strcmp(stable_sel.group,cur_group_name);
        cur_group_f = cur_f_array(idx,:);
        % N of valid trials at every frame
        n_val_trials_atEveryFrame = sum(~isnan(cur_group_f)); 
        % only include the time point when N of valid trials >= threshold
        val_trial_flag_atEveryFrame = n_val_trials_atEveryFrame >= val_trial_cutoff;

        % set frames without enough trials to NaN
        n_val_trials_nan = n_val_trials_atEveryFrame;
        n_val_trials_nan(~val_trial_flag_atEveryFrame) = NaN;
        counts(g,:) = n_val_trials_nan;

        % get means
        cur_mean = mean(cur_group_f,"omitnan");
        cur_mean_plt = cur_mean;
        cur_mean_plt(~val_trial_flag_atEveryFrame) = NaN;
        means(g,:) = cur_mean_plt;

        % get sems
        cur_sem = std(cur_group_f,"omitnan")./sqrt(n_val_trials_nan);
        sems(g,:) = cur_sem;
    end
    % get ylims
    max_y = max(max(means+sems));
    min_y = min(min(means-sems));
    ylims = [min_y-0.05*abs(min_y) max_y*1.05];
    txt_y = min_y + 0.03*(max_y-min_y);
    
    % trim the traces to equal length (removing groups with longer nonnan
    % values)
    val_t_idx = all(~isnan(means), 1);
    t_array_trim = t_array(val_t_idx);
    means_trim = means(:,val_t_idx);
    sems_trim = sems(:,val_t_idx);

    % plot
    fig = figure('Position',[600 300 400 400],'Visible','on'); 
    hold on; 
    if strcmp(sortBy,'SelfZone & Leader') || strcmp(sortBy,'SelfZone & Initiator') 
        for z = 1:4 
            subplot(2,2,z)
            hold on;
            clear p;
            for m = 1:2
                m_num = m_nums(m); % flipped when mouse is m2
                zz = (z-1)*2 + m_num;
                x = t_array_trim;
                y = means_trim(zz,:);
                error = sems_trim(zz,:);
                sel_nonnan = ~isnan(y) & ~isnan(error);
                x = x(sel_nonnan);
                y = y(sel_nonnan);
                error = error(sel_nonnan);
                y_upper = y + error;
                y_lower = y - error;
                p(m) = plot(x, y, 'LineWidth', 2,'Color',zone_colors{z},'LineStyle',linestyles{m}); % Main plot line in blue
                fill([x, fliplr(x)], [y_upper, fliplr(y_lower)],"",'FaceColor',zone_colors{z}, ...
                    'FaceAlpha', facealphas(m), 'EdgeColor', 'none'); % Shaded region
            end
            if z==3
                xlabel(['Frame no. from ' alignBy]);
                ylabel('dff');
            end
            plot([0,0],ylims,'Color','k','LineWidth',1,'LineStyle',':');
            title(zone_names{z})
            set(gca,'FontSize',14,'TickDir','out');
            legend(p, m_legend,'Location','northwest','FontSize',16);
            legend boxoff
            ylim(ylims);
            axis padded
        end
        sgtitle_name = sprintf([animal ' ' date ' ROI #%03d mean sort by ' sortBy], r);
        sgtitle(sgtitle_name,'FontSize',18,'FontWeight','bold');
    elseif strcmp(sortBy,'SelfZone') || strcmp(sortBy,'OtherZone')
        for z = 1:n_groups 
            [p(z),~] = error_shade(t_array_trim,means_trim(z,:),sems_trim(z,:),zone_colors{z});
        end
        % add trial start
        ylims = ylim;
        plot([0 0],ylims,'Color','k','LineWidth',1,'LineStyle',':');
        xlabel(['Frame from ' alignBy]);
        ylabel('dF/F');
        legend(p, zone_names,'Location','northeast','FontSize',16);
        legend boxoff
        caption_mean = sprintf([animal ' ' date ' ROI #%03d mean sortBy ' sortBy], r);
        title(caption_mean);
        set(gca,'FontSize',20,'TickDir','out');
        xticks(-90:30:60)
        xticklabels(-3:2)
        axis padded
    elseif strcmp(sortBy,'Leader')
        for m = 1:2
            m_num = m_nums(m); % flipped when mouse is m2
            x = t_array_trim;
            y = means_trim(m_num,:);
            error = sems_trim(m_num,:);
            sel_nonnan = ~isnan(y) & ~isnan(error);
            x = x(sel_nonnan);
            y = y(sel_nonnan);
            error = error(sel_nonnan);
            y_upper = y + error;
            y_lower = y - error;
            p(m) = plot(x, y, 'LineWidth', 2,'Color',m_color,'LineStyle',linestyles{m}); % Main plot line in blue
            fill([x, fliplr(x)], [y_upper, fliplr(y_lower)],"",'FaceColor',m_color, ...
                'FaceAlpha', facealphas(m), 'EdgeColor', 'none'); % Shaded region
        end
        xlabel(['Frame from ' alignBy]);
        ylabel('dF/F');
        ylims = ylim;
        plot([0 0],ylims,'Color','k','LineWidth',1,'LineStyle','--');
        legend(p, m_legend,'Location','northeast','FontSize',28);
        legend boxoff
        caption_mean = sprintf([animal ' ' date ' ROI #%03d mean sortBy ' sortBy], r);
        title(caption_mean);
        set(gca,'FontSize',31,'TickDir','out');
        xticks(-60:30:90)
        xticklabels(-2:3)
        axis padded
    end
    figname = sprintf([fd '/plots/' hoy 'p_' animal '_' date '_roi#%03d_mean_sortBy_' sortBy '_alignBy_' alignBy], r);
    print(fig,figname,'-dpdf');
end