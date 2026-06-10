function [rtable,params] = get_spatial_selectivity_demo(stable_sel,ftable,spk,params)
% determine the spatial selectivity by comparing the spatial information
% content of the data and shuffled
% apply a threshold of number of frames when calculating spatial information
% content and first/second halves correlation
% calculate the position of receptive size of social vector cells
% add spatial coherence criterion

%% get params
fd = params.fd; 
date = params.date;
animal = params.animal;
n_frames = height(ftable);
min_frames = 15; % minimal number of data points in a spatial bin
n_cells = size(spk,1);
roi_range = params.roi_range;
self_id = params.id;
m = str2double(self_id(2));
other_id = ['m' num2str(3-m)];
role = params.role;
hoy = char(datetime('now','Format','yyyyMMdd'));
max_dist = params.max_dist;
spatial_binsize = params.spatial_binsize;

fprintf('processing %s on %s for %s\n',animal, date, params.which_pos)

% select frames based on timing of the task
% remove trials when there is no self arrival time
sel_trials = ~isnan(stable_sel.([self_id '_last_arr'])); 
stable_sel = stable_sel(sel_trials,:);

which_frames = params.which_frames;
frames_idxn = get_frames_idx_demo(which_frames,stable_sel,ftable,params);
n_frames_sel = length(frames_idxn);

% get the calcium data
spk_sel = spk(:,frames_idxn);

% get positions
which_pos = params.which_pos;
switch which_pos
    case 'self'
        pos = ftable.([self_id '_neck']);
    case 'other'
        pos = ftable.([other_id '_neck']);
    case 'other_allo' % other pos relative to self in allocentric reference frame
        pos = ftable.([other_id '_neck_allo']);
    case 'other_ego' % other pos relative to self in egocentric reference frame
        pos = ftable.([other_id '_neck_ego']);
    case 'other_bearing' % other bearing relative to self
        pos = ftable.([other_id '_brg_by_' self_id])/180*pi;
end

x_sel = pos(frames_idxn,1);
y_sel = pos(frames_idxn,2);

%% 
params.sel_frames = which_frames;
edges = -max_dist:spatial_binsize:max_dist;
n_bins = length(edges)-1;
params.n_bins = n_bins;
n_frames0 = length(x_sel);
[N,~,~,binX,binY] = histcounts2(x_sel,y_sel,edges,edges);
N_linear = N(:);
n_frames_N_linear = sum(N_linear);
N_linear_sel = N_linear(N_linear>=min_frames);
n_frames_N_sel = sum(N_linear_sel(:));
fprintf('%d total frames, %d in bins, %d passed min frames\n',n_frames0,n_frames_N_linear,n_frames_N_sel)

%% get spatial information content for every cell
rtable = table;
rtable.animal = repmat({animal},n_cells,1);
rtable.date = repmat({date},n_cells,1);
rtable.id = repmat({self_id},n_cells,1);
rtable.role = repmat({params.role},n_cells,1);
rtable.cell = (1:n_cells)';

rtable.info = nan(n_cells,1);
rtable.p_info = nan(n_cells,1);
rtable.corr_halves = nan(n_cells,1);
rtable.p_corr = nan(n_cells,1);
rtable.mean_sp = nan(n_cells,1); % mean spike probability in the selected window
rtable.med_sp = nan(n_cells,1); % median spike probability in the selected window
rtable.mean_sp_ses = nan(n_cells,1); % mean spike probability in the full session
rtable.med_sp_ses = nan(n_cells,1); % median spike probability in the full session
c = turbo(100);
n_rs = 100;

% split the frames in two halves for checking reliability
n_1st_half = round(n_frames_sel/2);
idx_1st = 1:n_1st_half;
idx_2nd = (n_1st_half+1):n_frames_sel;
for r = roi_range
    if mod(r, 100) == 0
        fprintf('Processing roi %d of %d\n',r,n_cells);
    end
    cur_spk = spk_sel(r,:);
    rtable.mean_sp_ses(r) = mean(spk(r,:),"omitmissing");
    rtable.med_sp_ses(r) = median(spk(r,:),"omitmissing");
    % get mean overall
    spk_map = nan(n_bins,n_bins);
    spk_map_1st = nan(n_bins,n_bins);
    spk_map_2nd = nan(n_bins,n_bins);
    prop_frames = nan(n_bins,n_bins);
    finput_remaining = [];
    for i = 1:n_bins
        for j = 1:n_bins
            bin_idx = binX==i & binY==j;
            if sum(bin_idx)>=min_frames % at least min_frames in this bin
                % get mean 
                spk_cur_cell = cur_spk(bin_idx);
                cur_mean = mean(spk_cur_cell,"omitnan");
                spk_map(j,i) = cur_mean;
                prop_frames(j,i) = sum(bin_idx)/n_frames_N_sel;
                finput_remaining = [finput_remaining spk_cur_cell];
            end
            % CRITICAL! 
            % column index is i on the x axis
            % row index is j on the y axis

            % get the first and second halves mean_finput
            bin_idx_1st = bin_idx(idx_1st);
            if sum(bin_idx_1st)>=min_frames
                cur_spk_1st = cur_spk(idx_1st);
                cur_finput_bin_1st = cur_spk_1st(bin_idx_1st);
                spk_map_1st(j,i) = mean(cur_finput_bin_1st,"omitnan");
            end
            bin_idx_2nd = bin_idx(idx_2nd);
            if sum(bin_idx_2nd)>=min_frames
                cur_spk_2nd = cur_spk(idx_2nd);
                cur_finput_bin_2nd = cur_spk_2nd(bin_idx_2nd);
                spk_map_2nd(j,i) = mean(cur_finput_bin_2nd,"omitnan");
            end
        end
    end
    mean_all = mean(finput_remaining,"omitnan");
    rtable.mean_sp(r) = mean_all; 
    rtable.med_sp(r) = median(finput_remaining,"omitnan");
    
    % get spatial info
    info_data = prop_frames.*(spk_map/mean_all).*log2(spk_map/mean_all);
    I_data = sum(info_data(:),"omitnan");
    rtable.info(r) = I_data;
    
    % check reliability index
    rho_data = corr(spk_map_1st(:),spk_map_2nd(:),'Type','Spearman','Rows','complete');
    rtable.corr_halves(r) = rho_data;
    
    % get spatial coherence
    [coh_data,avg_neighbor_rate] = calc_spatial_coherence(spk_map);
    rtable.coh(r) = coh_data;

    % generate random shuffle by shifting the array circularly
    I_shuffle = nan(n_rs,1);
    Rho_shuffle = nan(n_rs,1);
    coh_shuffle = nan(n_rs,1);
    for n = 1:n_rs
        k = randi([300 n_frames_sel-300]); % shift by a random N larger than 300 frames
        f_shuffle = circshift(cur_spk,k);
        spk_map_shuffle = nan(n_bins,n_bins);
        map_shuffle_1st = nan(n_bins,n_bins);
        map_shuffle_2nd = nan(n_bins,n_bins);
        finput_shuffle_remaining = [];
        for i = 1:n_bins
            for j = 1:n_bins
                bin_idx = binX==i & binY==j;
                % compute SIC for shuffled data
                if sum(bin_idx)>=min_frames % at least min_frames in this bin
                    spk_cur_cell = f_shuffle(bin_idx);
                    cur_mean = mean(spk_cur_cell,"omitnan");
                    spk_map_shuffle(j,i) = cur_mean;
                    finput_shuffle_remaining = [finput_shuffle_remaining spk_cur_cell];
                end
                % compute first/second halves correlation for shuffled data
                bin_idx_1st = bin_idx(idx_1st);
                if sum(bin_idx_1st)>=min_frames
                    f_shuffle_1st = f_shuffle(idx_1st);
                    cur_shuffle_1st = f_shuffle_1st(bin_idx_1st);
                    map_shuffle_1st(j,i) = mean(cur_shuffle_1st,"omitnan");
                end
                bin_idx_2nd = bin_idx(idx_2nd);
                if sum(bin_idx_2nd)>=min_frames  
                    f_shuffle_2nd = f_shuffle(idx_2nd);
                    cur_shuffle_2nd = f_shuffle_2nd(bin_idx_2nd);
                    map_shuffle_2nd(j,i) = mean(cur_shuffle_2nd,"omitnan");
                end
            end
        end
        mean_shuffle_all = mean(finput_shuffle_remaining,"omitnan");
        info_shuffle = prop_frames.*(spk_map_shuffle/mean_shuffle_all).*log2(spk_map_shuffle/mean_shuffle_all);
        I_shuffle(n) = sum(info_shuffle(:),"omitnan");
        Rho_shuffle(n) = corr(map_shuffle_1st(:),map_shuffle_2nd(:),...
            'Type','Spearman','Rows','complete');
        coh_shuffle(n) = calc_spatial_coherence(spk_map_shuffle);
    end
    p_info = mean(I_shuffle>=I_data);
    rtable.p_info(r) = p_info;
    p_corr = mean(Rho_shuffle>=rho_data);
    rtable.p_corr(r) = p_corr;
    rtable.p_coh(r) = mean(coh_shuffle>=coh_data);

    % scatter plots
    colors = get_colormap(role);
    n_colors = height(colors);
    fig = figure('Position',[600 300 600 600],'Visible','on'); 
    hold on;
    max_f = max(cur_spk);
    min_f = min(cur_spk);
    dff_tier = floor((cur_spk-min_f)/(max_f-min_f)*(n_colors-1))+1;
    colormap(colors);
    for ii = 1:n_colors
        idx = dff_tier==ii;
        plot(x_sel(idx),y_sel(idx),'.','MarkerSize',6,'Color',colors(ii,:));
    end 
    hold on; 
    axis equal
    xlim([-max_dist max_dist]); ylim([-max_dist max_dist]);
    xticks([-max_dist 0 max_dist]); 
    yticks([-max_dist 0 max_dist]);
    xlabel('X (cm)')
    ylabel('Y (cm)');
    cb = colorbar;
    cb.TickDirection = 'out';
    cb.Ticks = [0 1];
    cb.TickLabels = round(linspace(min_f,max_f,6),1);
    cb.TickLabels = round([min_f max_f],3);
    cb.TickLabels = [0 1];
    ylabel(cb,'Spikes/s','FontSize',20)
    title_name = sprintf([animal ' ' date ' ROI #%03d FR %s ' which_pos], r, which_frames);
    title_name = strrep(title_name,'_',' ');
    title(title_name);
    set(gca,'FontSize',28,'TickDir','out');
    figname = sprintf([fd '/plots/' hoy 'p_' animal '_' date '_roi#%03d_FR_scat_%s_' which_pos], r, which_frames);
    set(fig,'PaperOrientation','landscape','PaperUnits','normalized','PaperPosition', [0 0 1 1]);
    print(fig,figname,'-dpdf');

    %{ 
    % trajectory plot begins
    fig = figure('Position',[600 200 600 600],'Visible','on'); 
    hold on;
    % x_plot = x_sel(1:2:end);
    % y_plot = y_sel(1:2:end);
    % spk_plot = cur_spk(1:2:end);
    dis_threshold = 10; % in cm, because max_speed = 90cm/s, 1 frame is 0.033s
    segments = break_segments(x_sel, y_sel, dis_threshold);
    n_segment = length(segments);
    for tr = 1:n_segment
        win_cur = segments{tr};
        % win_cur = windows{tr};
        % win_cur = win_cur(1:2:end);
        % x_plot = pos(win_cur,1);
        % y_plot = pos(win_cur,2);
        if ~isscalar(win_cur) % do not plot single frames
            x_plot = x_sel(win_cur);
            y_plot = y_sel(win_cur);
            spk_plot = spk_sel(r,win_cur);
            len_traj = length(x_plot);
            lineColor = spk_plot;
            colors = get_colormap(role);
            colormap(colors);
            surface([x_plot';x_plot'], [y_plot';y_plot'],...
                [zeros(1,len_traj);zeros(1,len_traj)], [lineColor;lineColor],...
                'FaceColor', 'none','EdgeColor', 'interp',...
                'LineWidth', 1, 'EdgeAlpha', 0.2);  
        end
    end
    % cb = colorbar;
    % cb.TickDirection = 'out';
    % clim([0 0.9])
    % cb.Ticks = [0 0.9];
    % quiver(0, 0, 7.5, 0, 'off', 'LineWidth', 4, 'MaxHeadSize', 3,'Color','k');
    axis equal
    xlim([-max_dist max_dist]); ylim([-max_dist max_dist]);
    % xticks(-max_dist:spatial_binsize*2:max_dist); 
    % yticks(-max_dist:spatial_binsize*2:max_dist);
    xticks([-max_dist 0 max_dist]); 
    yticks([-max_dist 0 max_dist]);
    xticklabels([])
    yticklabels([])
    % xlabel('X (cm)')
    % ylabel('Y (cm)');
    title_name = sprintf([animal ' ' date ' ROI #%03d FR %s ' which_pos], r, which_frames);
    title_name = strrep(title_name,'_',' ');
    % title(title_name);
    set(gca,'FontSize',16,'TickDir','out');
    figname = sprintf([fd '/plots/example_cells/' hoy 'p_' animal '_' date '_roi#%03d_FR_surf_%s_' which_pos], r, which_frames);
    set(fig,'PaperOrientation','landscape','PaperUnits','normalized','PaperPosition', [0 0 1 1]);
    % print(fig,figname,'-dpdf'); 
    print(fig, figname, '-dpng', '-r300');  % High-res PNG
    % trajectory plot ends
    %}         
end
