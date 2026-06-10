function fit_rspd_choice_v3(fd,ctable)
% plot the heatmap of responder's choice as a function of location
% responder can be anywhere in the arena, the initiator is at the init port
% by design, this analysis excludes phaseb2 data because there is no responder

ctable = load([fd 'Data\ctable_light_combined.mat']).ctable;

%% make master stable
uni_pairs = unique(ctable.pair);
n_uni_pairs = length(uni_pairs);
threshold = 0.6; % threshold for calling a consistent leader in a cohort
mstable = [];
ltable = extract_ltable(ctable);

for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    % process the ctable
    btable = ctable(strcmp(cur_pair,ctable.pair),:);
    if strcmp(cur_pair,'YC017YC018') % only use sessions before extended phase4b+cno sessions
        btable = btable(str2double(btable.date)<=20231017,:);
    elseif strcmp(cur_pair,'YC013YC014') % only use sessions before extended phase4b+cno sessions
        btable = btable(str2double(btable.date)<=20230804,:);
    elseif strcmp(cur_pair,'YC015YC016') % only use sessions before extended phase4b+cno sessions
        btable = btable(str2double(btable.date)<=20230831,:);
    end
    cur_ltable = ltable(strcmp(cur_pair, ltable.pair), :);
  
    % get criterion day 1
    if isempty(cur_ltable.true_lead) % the pair is not in ltable
        continue
    else
        crit_day1 = cur_ltable.date(end-2);
        sel_date = str2double(btable.date) >= str2double(crit_day1);
    
        s_range = btable.cno==0 & btable.cp_rate>=0.795 & strcmpi(btable.phase,'phase4a')...
            & (btable.p_ledBy_m1+btable.p_ledBy_m2)>=0.8 & sel_date;
        btable = btable(s_range,:); % well-trained
        n_ses = height(btable);
    end
    btable = get_other_choose_n(btable);

    % get phase 4a psych table
    btable = get_psych_table_v3(btable); % new other mouse zone calculations

    % determine which mouse is the consistent leader across sessions
    n_ledBy_m1 = sum(strcmp(btable.sLead,'m1'));
    n_ledBy_m2 = sum(strcmp(btable.sLead,'m2'));
    if n_ledBy_m1 >= n_ses * threshold
        pLead = 1; pFoll = 2;
    elseif n_ledBy_m2 >= n_ses * threshold
        pLead = 2; pFoll = 1;
    else
        fprintf(['Leading %d vs %d in %d sessions, less than prop=%.2f of well-trained, phase4a,'...
            ' control sessions in ' cur_pair '. Check data!\n'],n_ledBy_m1,n_ledBy_m2,n_ses,threshold)
        continue; % skip the rest of the current iter and go to the next iter
    end
    animals = {btable{1,'m1'};btable{1,'m2'}}; % get the animal names

    for m = 1:2
        % which animal to analyze
        cur_animal = animals{m};
        cur_pair = btable.pair{1};
        sel_btable = btable;
        
        %%% combine the phase4 stables
        stable_cat = vertcat(sel_btable.stable{:});
        stable_cat.sex = repmat(sel_btable.sex(1),height(stable_cat),1);

        % apply the saved (same as in plt_psych_curve) and new selection criterion
        sel2 = stable_cat.initiator == 3-m; % only when the other mouse is the initiator
        % sel3 = ~isnan(stable_cat.other_choose_n); % when other makes a valid choice
        sel3 = ~isnan(stable_cat.m1_choose_n) & ~isnan(stable_cat.m2_choose_n); % when both make valid choices
        sel = stable_cat.sel==1 & sel2 & sel3;
        stable_cat = stable_cat(sel,:);
        
        stable_cat.animal = repmat({cur_animal},height(stable_cat),1);
        stable_cat.pair = repmat({cur_pair},height(stable_cat),1);
        if m==pLead
            stable_cat.subject = repmat({'pLead'},height(stable_cat),1);
        else
            stable_cat.subject = repmat({'pFoll'},height(stable_cat),1);
        end
        mstable = [mstable;stable_cat];
    end
end

%% plot leader or follower's choices as responder
% cur_role = 'pLead'; role = 'leader';
cur_role = 'pFoll'; role = 'follower';
sel_role = strcmp(mstable.subject,cur_role);
mstable_sel_role = mstable(sel_role,:);

init_heading = {'east','south','west','north'};
% init_heading = {'north','east'};
n_init_hds = length(init_heading);
n_all_trials = nan(n_init_hds,1);

source_data = table();

choice_maps = cell(n_init_hds,1);
for hd = 1:n_init_hds
    % init_hd = 'north';
    init_hd = init_heading{hd};
    switch init_hd % select only trials meet the hd condition of the init
        case 'east'
            sel_hd = (mstable_sel_role.init_hd_rot>=0 & mstable_sel_role.init_hd_rot<30) | ...
                (mstable_sel_role.init_hd_rot>=330 & mstable_sel_role.init_hd_rot<360); % init face east
            u = 1; v = 0; % for drawing init heading
        case 'south'
            sel_hd = (mstable_sel_role.init_hd_rot>=240 & mstable_sel_role.init_hd_rot<300); % init face north
            u = 0; v = -1; % for drawing init heading
        case 'west'
            sel_hd = (mstable_sel_role.init_hd_rot>=150 & mstable_sel_role.init_hd_rot<210); % init face north
            u = -1; v = 0; % for drawing init heading
        case 'north'
            sel_hd = (mstable_sel_role.init_hd_rot>=60 & mstable_sel_role.init_hd_rot<120); % init face north
            u = 0; v = 1; % for drawing init heading
    end
    mstable_sel_hd = mstable_sel_role(sel_hd,:);
    
    xedges = -24:8:24;
    yedges = -24:8:24;
    min_trials = 3;
    n_bins = length(xedges)-1;
    n_trials = height(mstable_sel_hd);
    n_all_trials(hd) = n_trials;
    [N,~,~,binX,binY] = histcounts2(mstable_sel_hd.other_x_rot,mstable_sel_hd.other_y_rot,xedges,yedges);
    choice_map = nan(n_bins,n_bins);
    prop_frames = nan(n_bins,n_bins);
    for i = 1:n_bins
        for j = 1:n_bins
            bin_idx = binX==i & binY==j;
            n_cur_trials = sum(bin_idx);
            if n_cur_trials>=min_trials % at least min_trials in this bin
                choice_map(j,i) = mean(mstable_sel_hd.other_choose_n(bin_idx));
                prop_frames(j,i) = n_cur_trials/n_trials;
            end
            % CRITICAL! column index is i on the x axis, row index is j on the y axis
        end
    end

    for i = 1:n_bins
        for j = 1:n_bins
            bin_idx = binX==i & binY==j;
            n_cur_trials = sum(bin_idx);

            tmp = table();
            tmp.Role = string(role);
            tmp.Subject = string(cur_role);
            tmp.InitHeading = string(init_hd);
            tmp.InitHeadingIndex = hd;
            tmp.XBinIndex = i;
            tmp.YBinIndex = j;
            tmp.XBinLeft = xedges(i);
            tmp.XBinRight = xedges(i+1);
            tmp.YBinBottom = yedges(j);
            tmp.YBinTop = yedges(j+1);
            tmp.XBinCenter = mean(xedges(i:i+1));
            tmp.YBinCenter = mean(yedges(j:j+1));
            tmp.NTrialsInBin = n_cur_trials;
            tmp.NTrialsTotalForHeading = n_trials;
            tmp.MinTrials = min_trials;
            tmp.PropChoosingNorth = choice_map(j,i);
            tmp.PropFrames = prop_frames(j,i);

            source_data = [source_data; tmp];
        end
    end

    choice_maps{hd} = choice_map;
    fig = figure('Position',[200 200 300 300]); hold on
    h = imagesc(choice_map);
    set(gca,'YDir','normal')
    set(h, 'AlphaData', ~isnan(choice_map))       
    % for i = 1:n_bins
    %     for j = 1:n_bins
    %         text(j, i, sprintf('%.2f',choice_map(i, j)), 'Color', 'black', 'FontSize', 20, 'HorizontalAlignment', 'center');
    %     end
    % end
    hold on;
    quiver(3.5, 3.5, u, v, 'off', 'LineWidth', 4, 'MaxHeadSize', 3,'Color','k');

    % colormap(parula)
    colors = get_colormap(role);
    colormap(colors);
    clim([0 1])
    cb = colorbar;
    cb.TickDirection = 'out';
    ylabel(cb,'Prop choosing north','FontSize',20)

    axis equal
    xlim([0.5 n_bins+0.5]); 
    % xticks(0.5:n_bins+0.5)
    xticks([0.5 n_bins/2+0.5 n_bins+0.5])
    % xticklabels(xedges)
    xticklabels([-24 0 24])
    xlabel('X (cm)');
    ylim([0.5 n_bins+0.5]); 
    % yticks(0.5:n_bins+0.5)
    yticks([0.5 n_bins/2+0.5 n_bins+0.5])
    % yticklabels(xedges)
    yticklabels([-24 0 24])
    ylabel('Y (cm)');
    title(sprintf('Prop %s choosing north when init face %s',cur_role,init_hd))
    set(gca,'FontSize',20)
    hoy = char(datetime('now','Format','yyyyMMdd'));
    figname = [fd 'plots/' hoy '_responder_choice_' cur_role '_init_face_' init_hd];
    % set(fig,'PaperOrientation','landscape','PaperUnits','normalized','PaperPosition', [0 0 1 1]);
    print(fig,figname,'-dpdf');

end

assignin('base','source_data',source_data);
%% heatmap difference between north and east
fig = figure('Position',[200 200 500 500]); 
hold on

choice_map_dif = choice_maps{4} - choice_maps{1}; % north minus east

source_data_dif = table();

for i = 1:n_bins
    for j = 1:n_bins
        tmp = table();

        tmp.Role = string(role);
        tmp.Subject = string(cur_role);
        tmp.Comparison = "north_minus_east";
        tmp.XBinIndex = i;
        tmp.YBinIndex = j;
        tmp.XBinLeft = xedges(i);
        tmp.XBinRight = xedges(i+1);
        tmp.YBinBottom = yedges(j);
        tmp.YBinTop = yedges(j+1);
        tmp.XBinCenter = mean(xedges(i:i+1));
        tmp.YBinCenter = mean(yedges(j:j+1));
        tmp.PropChoosingNorth_NorthInit = choice_maps{4}(j,i);
        tmp.PropChoosingNorth_EastInit = choice_maps{1}(j,i);
        tmp.DiffPropChoosingNorth = choice_map_dif(j,i);

        source_data_dif = [source_data_dif; tmp];
    end
end

assignin('base','source_data_dif',source_data_dif);

h = imagesc(choice_map_dif);
set(gca,'YDir','normal')
set(h, 'AlphaData', ~isnan(choice_map_dif))       
clim([-0.5 0.5])

colors = get_colormap('diverging');
colors = flipud(colors);
colormap(colors)

cb = colorbar;
cb.TickDirection = 'out';
ylabel(cb,'Diff in prop choosing north','FontSize',20)

axis equal
xlim([0.5 n_bins+0.5]); 
% xticks(0.5:n_bins+0.5)
xticks([0.5 n_bins/2+0.5 n_bins+0.5])
% xticklabels(xedges)
xticklabels([-24 0 24])
xlabel('X (cm)');

ylim([0.5 n_bins+0.5]); 
% yticks(0.5:n_bins+0.5)
yticks([0.5 n_bins/2+0.5 n_bins+0.5])
% yticklabels(xedges)
yticklabels([-24 0 24])
ylabel('Y (cm)');

title(sprintf('Choice difference of %s when init face north vs. east',cur_role))

set(gca,'FontSize',20)

hoy = char(datetime('now','Format','yyyyMMdd'));

figname = [fd 'plots/' hoy '_hmap_dif_responder_choice_' cur_role '_init_face_north_vs_east'];

% set(fig,'PaperOrientation','landscape','PaperUnits','normalized','PaperPosition', [0 0 1 1]);

print(fig,figname,'-dpdf');
%% scatter plot difference between north and east
m_colors = {'#c2a5cf','#a6dba0','#969696'}; % leader vs follower 
if strcmp(cur_role,'pLead')
    cur_color = '#c2a5cf';
elseif strcmp(cur_role,'pFoll')
    cur_color = '#a6dba0';
end
fig = figure('Position',[200 200 300 300]);
hold on;
plot([0 1],[0 1],'k--','LineWidth',2)
scatter(choice_maps{1}(:),choice_maps{4}(:),300,'MarkerFaceColor',cur_color,...
    'MarkerEdgeColor','k','LineWidth',0.1)
% xlabel(sprintf('Pnorth of %s when init face east',cur_role))
% ylabel(sprintf('Pnorth of %s when init face north',cur_role))
xlabel('Face E');
ylabel('Face N')
title('P(north)')
[h,p] = ttest(choice_maps{1}(:),choice_maps{4}(:));
text(0.05,0.95,sprintf('P=%.2g', p),'Units','Normalized','FontSize',20)
set(gca,'FontSize',20,'TickDir','out')
axis equal
xlim([0 1])
ylim([0 1])
figname = [fd 'plots/' hoy '_scat_responder_choice_' cur_role '_init_face_north_vs_east'];
print(fig,figname,'-dpdf');

%% fitting choice as a function of distance difference between north and east
[x_coords,y_coords] = meshgrid(-20:8:20, -20:8:20);
coords_north = [0, 24];
coords_east = [24, 0];
d2north = sqrt((x_coords-coords_north(1)).^2 + (y_coords-coords_north(2)).^2);
d2east = sqrt((x_coords-coords_east(1)).^2 + (y_coords-coords_east(2)).^2);
d_dif = d2east - d2north;
fig = figure('Position',[1200 200 300 300]);
hold on
hdls = [];
init_heading = {'east','south','west','north'};
n_init_hds = length(init_heading);
Rs = nan(n_init_hds,1);
Ps = nan(n_init_hds,1);
if strcmp(cur_role,'pLead')
    m_colors = {'#e7d4e8';'#c2a5cf';'#9970ab';'#762a83'}; % leader
elseif strcmp(cur_role,'pFoll')
    m_colors = {'#d9f0d3';'#a6dba0';'#5aae61';'#1b7837'}; % follower
end
for ii = 1:n_init_hds
    hdls(ii) = scatter(d_dif(:),choice_maps{ii}(:),50,"MarkerFaceColor",m_colors{ii},...
        'MarkerFaceAlpha',0.5,'MarkerEdgeColor','k','LineWidth',0.1);
    [Rs(ii),Ps(ii)] = corr(d_dif(:),choice_maps{ii}(:),'Rows','complete');
    % linear fit
    x = d_dif(:);
    y = choice_maps{ii}(:);
    sel = ~isnan(y);
    x_sel = x(sel);
    y_sel = y(sel);
    yCalc = linear_fit(x_sel, y_sel);
    pl(ii) = plot(x_sel,yCalc,'Color',m_colors{ii},'LineStyle','-', 'LineWidth',2);
end
ylim([0 1.1])
xlim([-32 32])
% lgds = cellfun(@(x) ['Initiator face ' x], init_heading, 'UniformOutput', false);
% legend(pl,init_heading,'Location','southeast outside')
legend(pl,init_heading,'Location','southeast')
legend box off
xlabel('Dis to east - Dis to north (cm)')
ylabel('Prop choosing north')
title(['Initiator heading impacts choice of responder as ' cur_role])
set(gca,'FontSize',20,'TickDir','out')
figname = [fd 'plots/' hoy '_corr_responder_choice_vs_location_' cur_role];
print(fig,figname,'-dpdf');

%% fit repeated measure model and stats
tbl = table(d_dif(:),choice_maps{1}(:),choice_maps{2}(:),choice_maps{3}(:),choice_maps{4}(:),...
    'VariableNames',['d_dif',init_heading]);
% HDs = table([1 2 3 4]','VariableNames',{'Direction'});
Direction = [1 2 3 4]';
rm = fitrm(tbl,'east-north~1','WithinDesign',Direction);
ranovatbl = ranova(rm)
multcompare(rm,'Time')

%% split by sex
sexes = {'female';'male'};

source_data = table();
source_data_dif = table();
source_data_scatter = table();
source_data_corr = table();

for se = 1

    cur_sex = sexes{se};

    mstable_sex = mstable(strcmp(mstable.sex,cur_sex),:);

    % cur_role = 'pLead'; role = 'leader';
    cur_role = 'pFoll'; role = 'follower';

    sel_role = strcmp(mstable_sex.subject,cur_role);

    mstable_sel_role = mstable_sex(sel_role,:);

    init_heading = {'east','south','west','north'};
    % init_heading = {'north','east'};

    n_init_hds = length(init_heading);

    n_all_trials = nan(n_init_hds,1);

    choice_maps = cell(n_init_hds,1);

    for hd = 1:n_init_hds

        % init_hd = 'north';
        init_hd = init_heading{hd};

        switch init_hd % select only trials meet the hd condition of the init

            case 'east'
                sel_hd = (mstable_sel_role.init_hd_rot>=0 & mstable_sel_role.init_hd_rot<30) | ...
                    (mstable_sel_role.init_hd_rot>=330 & mstable_sel_role.init_hd_rot<360); % init face east
                u = 1; v = 0; % for drawing init heading

            case 'south'
                sel_hd = (mstable_sel_role.init_hd_rot>=240 & mstable_sel_role.init_hd_rot<300); % init face north
                u = 0; v = -1; % for drawing init heading

            case 'west'
                sel_hd = (mstable_sel_role.init_hd_rot>=150 & mstable_sel_role.init_hd_rot<210); % init face north
                u = -1; v = 0; % for drawing init heading

            case 'north'
                sel_hd = (mstable_sel_role.init_hd_rot>=60 & mstable_sel_role.init_hd_rot<120); % init face north
                u = 0; v = 1; % for drawing init heading
        end

        mstable_sel_hd = mstable_sel_role(sel_hd,:);

        xedges = -24:8:24;
        yedges = -24:8:24;

        min_trials = 3;

        n_bins = length(xedges)-1;

        n_trials = height(mstable_sel_hd);

        n_all_trials(hd) = n_trials;

        [N,~,~,binX,binY] = histcounts2( ...
            mstable_sel_hd.other_x_rot,...
            mstable_sel_hd.other_y_rot,...
            xedges,yedges);

        choice_map = nan(n_bins,n_bins);

        prop_frames = nan(n_bins,n_bins);

        for i = 1:n_bins
            for j = 1:n_bins

                bin_idx = binX==i & binY==j;

                n_cur_trials = sum(bin_idx);

                if n_cur_trials>=min_trials % at least min_trials in this bin

                    choice_map(j,i) = mean(mstable_sel_hd.other_choose_n(bin_idx));

                    prop_frames(j,i) = n_cur_trials/n_trials;

                end

                % CRITICAL! column index is i on the x axis, row index is j on the y axis

                tmp = table();

                tmp.Sex = string(cur_sex);
                tmp.Role = string(role);
                tmp.Subject = string(cur_role);

                tmp.InitHeading = string(init_hd);
                tmp.InitHeadingIndex = hd;

                tmp.XBinIndex = i;
                tmp.YBinIndex = j;

                tmp.XBinLeft = xedges(i);
                tmp.XBinRight = xedges(i+1);

                tmp.YBinBottom = yedges(j);
                tmp.YBinTop = yedges(j+1);

                tmp.XBinCenter = mean(xedges(i:i+1));
                tmp.YBinCenter = mean(yedges(j:j+1));

                tmp.NTrialsInBin = n_cur_trials;
                tmp.NTrialsTotalForHeading = n_trials;

                tmp.PropChoosingNorth = choice_map(j,i);

                tmp.PropFrames = prop_frames(j,i);

                source_data = [source_data; tmp];

            end
        end

        choice_maps{hd} = choice_map;

        fig = figure('Position',[200 200 300 300]);

        hold on

        h = imagesc(choice_map);

        set(gca,'YDir','normal')

        set(h, 'AlphaData', ~isnan(choice_map))

        hold on;

        quiver(3.5, 3.5, u, v, 'off', ...
            'LineWidth', 4, ...
            'MaxHeadSize', 3,...
            'Color','k');

        % colormap(parula)
        colors = get_colormap(role);

        colormap(colors);

        clim([0 1])

        cb = colorbar;

        cb.TickDirection = 'out';

        ylabel(cb,'Prop choosing north','FontSize',20)

        axis equal

        xlim([0.5 n_bins+0.5]);

        xticks([0.5 n_bins/2+0.5 n_bins+0.5])

        xticklabels([-24 0 24])

        xlabel('X (cm)');

        ylim([0.5 n_bins+0.5]);

        yticks([0.5 n_bins/2+0.5 n_bins+0.5])

        yticklabels([-24 0 24])

        ylabel('Y (cm)');

        title(sprintf('Prop %s choosing north when init face %s',cur_role,init_hd))

        set(gca,'FontSize',20)

        hoy = char(datetime('now','Format','yyyyMMdd'));

        figname = [fd 'plots/' hoy '_responder_choice_' ...
            cur_role '_init_face_' init_hd '_' cur_sex];

        print(fig,figname,'-dpdf');

    end

    %%% heatmap difference between north and east

    fig = figure('Position',[200 200 500 500]);

    hold on

    choice_map_dif = choice_maps{4} - choice_maps{1}; % north minus east

    for i = 1:n_bins
        for j = 1:n_bins

            tmp = table();

            tmp.Sex = string(cur_sex);
            tmp.Role = string(role);
            tmp.Subject = string(cur_role);

            tmp.Comparison = "north_minus_east";

            tmp.XBinIndex = i;
            tmp.YBinIndex = j;

            tmp.XBinLeft = xedges(i);
            tmp.XBinRight = xedges(i+1);

            tmp.YBinBottom = yedges(j);
            tmp.YBinTop = yedges(j+1);

            tmp.XBinCenter = mean(xedges(i:i+1));
            tmp.YBinCenter = mean(yedges(j:j+1));

            tmp.PropChoosingNorth_NorthInit = choice_maps{4}(j,i);
            tmp.PropChoosingNorth_EastInit = choice_maps{1}(j,i);

            tmp.DiffPropChoosingNorth = choice_map_dif(j,i);

            source_data_dif = [source_data_dif; tmp];

        end
    end

    h = imagesc(choice_map_dif);

    set(gca,'YDir','normal')

    set(h, 'AlphaData', ~isnan(choice_map_dif))

    clim([-0.5 0.5])

    colors = get_colormap('diverging');

    colors = flipud(colors);

    colormap(colors)

    cb = colorbar;

    cb.TickDirection = 'out';

    ylabel(cb,'Diff in prop choosing north','FontSize',20)

    axis equal

    xlim([0.5 n_bins+0.5]);

    xticks([0.5 n_bins/2+0.5 n_bins+0.5])

    xticklabels([-24 0 24])

    xlabel('X (cm)');

    ylim([0.5 n_bins+0.5]);

    yticks([0.5 n_bins/2+0.5 n_bins+0.5])

    yticklabels([-24 0 24])

    ylabel('Y (cm)');

    title(sprintf('Choice difference of %s when init face north vs. east',cur_role))

    set(gca,'FontSize',20)

    hoy = char(datetime('now','Format','yyyyMMdd'));

    figname = [fd 'plots/' hoy '_hmap_dif_responder_choice_' ...
        cur_role '_init_face_north_vs_east_' cur_sex];

    print(fig,figname,'-dpdf');

    %%% scatter plot difference between north and east

    m_colors = {'#c2a5cf','#a6dba0','#969696'}; % leader vs follower 

    if strcmp(cur_role,'pLead')
        cur_color = '#c2a5cf';
    elseif strcmp(cur_role,'pFoll')
        cur_color = '#a6dba0';
    end

    fig = figure('Position',[200 200 300 300]);

    hold on;

    plot([0 1],[0 1],'k--','LineWidth',2)

    scatter(choice_maps{1}(:),choice_maps{4}(:),300,...
        'MarkerFaceColor',cur_color,...
        'MarkerEdgeColor','k',...
        'LineWidth',0.1)

    tmp_scatter = table();

    tmp_scatter.Sex = repmat(string(cur_sex),numel(choice_maps{1}),1);
    tmp_scatter.Role = repmat(string(role),numel(choice_maps{1}),1);
    tmp_scatter.Subject = repmat(string(cur_role),numel(choice_maps{1}),1);

    tmp_scatter.PropChoosingNorth_EastInit = choice_maps{1}(:);
    tmp_scatter.PropChoosingNorth_NorthInit = choice_maps{4}(:);

    source_data_scatter = [source_data_scatter; tmp_scatter];

    xlabel('Face E');

    ylabel('Face N')

    title('P(north)')

    [h,p] = ttest(choice_maps{1}(:),choice_maps{4}(:));

    text(0.05,0.95,sprintf('P=%.2g', p),...
        'Units','Normalized',...
        'FontSize',20)

    set(gca,'FontSize',20,'TickDir','out')

    axis equal

    xlim([0 1])

    ylim([0 1])

    figname = [fd 'plots/' hoy '_scat_responder_choice_' ...
        cur_role '_init_face_north_vs_east_' cur_sex];

    print(fig,figname,'-dpdf');

    %%% fitting choice as a function of distance difference between north and east

    [x_coords,y_coords] = meshgrid(-20:8:20, -20:8:20);

    coords_north = [0, 24];
    coords_east = [24, 0];

    d2north = sqrt((x_coords-coords_north(1)).^2 + ...
        (y_coords-coords_north(2)).^2);

    d2east = sqrt((x_coords-coords_east(1)).^2 + ...
        (y_coords-coords_east(2)).^2);

    d_dif = d2east - d2north;

    fig = figure('Position',[1200 200 300 300]);

    hold on

    hdls = [];

    init_heading = {'east','south','west','north'};

    n_init_hds = length(init_heading);

    Rs = nan(n_init_hds,1);
    Ps = nan(n_init_hds,1);

    if strcmp(cur_role,'pLead')
        m_colors = {'#e7d4e8';'#c2a5cf';'#9970ab';'#762a83'}; % leader
    elseif strcmp(cur_role,'pFoll')
        m_colors = {'#d9f0d3';'#a6dba0';'#5aae61';'#1b7837'}; % follower
    end

    for ii = 1:n_init_hds

        hdls(ii) = scatter(d_dif(:),choice_maps{ii}(:),50,...
            "MarkerFaceColor",m_colors{ii},...
            'MarkerFaceAlpha',0.5,...
            'MarkerEdgeColor','k',...
            'LineWidth',0.1);

        [Rs(ii),Ps(ii)] = corr(d_dif(:),choice_maps{ii}(:),...
            'Rows','complete');

        tmp_corr = table();

        tmp_corr.Sex = repmat(string(cur_sex),numel(d_dif),1);
        tmp_corr.Role = repmat(string(role),numel(d_dif),1);
        tmp_corr.Subject = repmat(string(cur_role),numel(d_dif),1);

        tmp_corr.InitHeading = repmat(string(init_heading{ii}),numel(d_dif),1);

        tmp_corr.DistanceEastMinusNorth = d_dif(:);

        tmp_corr.PropChoosingNorth = choice_maps{ii}(:);

        source_data_corr = [source_data_corr; tmp_corr];

        % linear fit
        x = d_dif(:);

        y = choice_maps{ii}(:);

        sel = ~isnan(y);

        x_sel = x(sel);

        y_sel = y(sel);

        yCalc = linear_fit(x_sel, y_sel);

        pl(ii) = plot(x_sel,yCalc,...
            'Color',m_colors{ii},...
            'LineStyle','-', ...
            'LineWidth',2);

    end

    ylim([0 1.1])

    xlim([-32 32])

    legend(pl,init_heading,'Location','southeast')

    legend box off

    xlabel('Dis to east - Dis to north (cm)')

    ylabel('Prop choosing north')

    title(['Initiator heading impacts choice of responder as ' cur_role])

    set(gca,'FontSize',20,'TickDir','out')

    figname = [fd 'plots/' hoy '_corr_responder_choice_vs_location_' ...
        cur_role '_' cur_sex];

    print(fig,figname,'-dpdf');

    %%% fit repeated measure model and stats

    tbl = table( ...
        d_dif(:),...
        choice_maps{1}(:),...
        choice_maps{2}(:),...
        choice_maps{3}(:),...
        choice_maps{4}(:),...
        'VariableNames',['d_dif',init_heading]);

    % HDs = table([1 2 3 4]','VariableNames',{'Direction'});

    Direction = [1 2 3 4]';

    rm = fitrm(tbl,'east-north~1','WithinDesign',Direction);

    ranovatbl = ranova(rm)

    multcompare(rm,'Time')

end

assignin('base','source_data',source_data);
assignin('base','source_data_dif',source_data_dif);
assignin('base','source_data_scatter',source_data_scatter);
assignin('base','source_data_corr',source_data_corr);