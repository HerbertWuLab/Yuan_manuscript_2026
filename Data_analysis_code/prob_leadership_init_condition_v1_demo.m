function prob_leadership_init_condition_v1
%% analyze lead/follow probability as a function of distance to reward zones

% fd = '/Users/herbert/Wulab Dropbox/Herbert/Research/Projects/SocialForaging/Behavior/';
% load([fd 'ctable_behavior/ctable_light.mat'])

%% set params
coords_north = [0 22.5];
coords_east = [22.5 0];
uni_pairs = unique(ctable.pair);
n_uni_pairs = length(uni_pairs);
threshold = 1; % threshold for calling a consistent leader in a cohort
mstable = []; % combined master stable to include all pairs

for p = 1:n_uni_pairs
% for p = 3
    cur_pair = uni_pairs{p};

    % process the ctable
    btable = ctable(strcmp(cur_pair,ctable.pair),:);
    
    if strcmp(cur_pair,'YC017YC018') % only use sessions before extended phase4b+cno sessions
        btable = btable(str2double(btable.date)<=20231017,:);
    % elseif strcmp(cur_pair,'YC011YC012') % remove problematic sessions, need to revisit!
    %     btable = btable(str2double(btable.date)<=20230526,:);
    elseif strcmp(cur_pair,'YC013YC014') % only use sessions before extended phase4b+cno sessions
        btable = btable(str2double(btable.date)<=20230804,:);
    elseif strcmp(cur_pair,'YC015YC016') % only use sessions before extended phase4b+cno sessions
        btable = btable(str2double(btable.date)<=20230831,:);
    end

    s_range = btable.cno==0 & btable.cp_rate>=0.8 & strcmpi(btable.phase,'phase4a');
    btable = btable(s_range,:); % well-trained

    if sum(s_range)>0
    n_ses = height(btable);

    % determine which mouse is the consistent leader across sessions
    n_ledBy_m1 = sum(strcmp(btable.sLead,'m1'));
    n_ledBy_m2 = sum(strcmp(btable.sLead,'m2'));
    if n_ledBy_m1 >= n_ses * threshold
        cLead = 1; cFoll = 2;
    elseif n_ledBy_m2 >= n_ses * threshold
        cLead = 2; cFoll = 1;
    else
        fprintf(['No mouse leads more than prop=%.2f of well-trained, phase4a,'...
            ' control sessions in ' cur_pair '. Check data!\n'],threshold)
        continue; % skip the rest of the current iter and go to the next iter
    end

    % % filter the sessions and get early learning phase data
    % btable = extract_ltable(cur_ctable);
    % btable = btable(btable.cp_rate<0.65,:);

    % get phase 4a psych table
    % btable = get_psych_table(btable);
    % btable = get_psych_table_v2(btable); % new other mouse zone calculations

    stable = vertcat(btable.stable{:});

    % apply selection criteria. don't need the distance filter now
    sel_co_mm = stable.correct == 1 | stable.mismatch == 1; % correct or mismatch
    % init_dis_sel = stable.init_dis<dis_threshold; % distance filter
    sel_trial_dur = stable.dur_f < 150; % trial is less than 5s
    sel_trial_type =  stable.trial_type >=1 & stable.trial_type <=4; % only neighboring trial types
    sel_trials1 = sel_co_mm & sel_trial_dur & sel_trial_type; % combine and save
    
    sel_trials2 = ~isnan(stable.m1_choose_n) & ~isnan(stable.m2_choose_n); % when both make valid choices

    stable_sel = stable(sel_trials1 & sel_trials2,:);
    n_trials = height(stable_sel);

    for m = 1:2
        cur_animal = ['m' num2str(m)];
        cur_animal_choose_n = stable_sel.([cur_animal '_choose_n'])==1;

        % angle to chosen zone
        stable_sel.([cur_animal '_angle_chosen_zone']) = nan(n_trials,1);
        stable_sel.([cur_animal '_angle_chosen_zone'])(cur_animal_choose_n) = stable_sel.([cur_animal '_angle_nz_rot'])(cur_animal_choose_n);
        stable_sel.([cur_animal '_angle_chosen_zone'])(~cur_animal_choose_n) = stable_sel.([cur_animal '_angle_ez_rot'])(~cur_animal_choose_n);

        %%% calculate the angles from east and from north
        angle_zero = stable_sel.([cur_animal '_hd_rot']);
        
        % absolute angular distance to east
        angle_east = angle_zero;
        angle_east(angle_east>180) = angle_east(angle_east>180) - 360;
        stable_sel.([cur_animal '_angle_east']) = abs(angle_east); % take the abs
        
        % absolute angular distance to north
        angle_north = angle_zero - 90;
        angle_north(angle_zero>270) = angle_north(angle_zero>270) - 360;
        stable_sel.([cur_animal '_angle_north']) = abs(angle_north); % take the abs
    
        stable_sel.([cur_animal '_angle_dif']) = (stable_sel.([cur_animal '_angle_east']) - ...
            stable_sel.([cur_animal '_angle_north']))/90; % normalize by max=90
        
        stable_sel.([cur_animal '_angle_rz_dif']) = (stable_sel.([cur_animal '_angle_ez_rot']) - ...
            stable_sel.([cur_animal '_angle_nz_rot']))/180; % normalize by max=180

        % calculate the distance to north and east zones
        x_coords = stable_sel.([cur_animal '_x_rot']);
        y_coords = stable_sel.([cur_animal '_y_rot']);
        stable_sel.([cur_animal '_d2east']) = sqrt((x_coords-coords_east(1)).^2 + (y_coords-coords_east(2)).^2);
        stable_sel.([cur_animal '_d2north']) = sqrt((x_coords-coords_north(1)).^2 + (y_coords-coords_north(2)).^2);
        stable_sel.([cur_animal '_dis_dif']) = stable_sel.([cur_animal '_d2east']) - stable_sel.([cur_animal '_d2north']);

        stable_sel.([cur_animal '_d2chosen_zone']) = nan(n_trials,1);
        stable_sel.([cur_animal '_d2chosen_zone'])(cur_animal_choose_n) = stable_sel.([cur_animal '_d2north'])(cur_animal_choose_n);
        stable_sel.([cur_animal '_d2chosen_zone'])(~cur_animal_choose_n) = stable_sel.([cur_animal '_d2east'])(~cur_animal_choose_n);

    end   
    
    leader = ['m' num2str(cLead)];
    stable_sel.lead_angle_east = stable_sel.([leader '_angle_east']);
    stable_sel.lead_angle_north = stable_sel.([leader '_angle_north']);
    stable_sel.lead_angle_dif = stable_sel.([leader '_angle_dif']);
    stable_sel.lead_angle_ez_rot = stable_sel.([leader '_angle_ez_rot']);
    stable_sel.lead_angle_nz_rot = stable_sel.([leader '_angle_nz_rot']);    
    stable_sel.lead_angle_rz_dif = stable_sel.([leader '_angle_rz_dif']);
    stable_sel.lead_d2north = stable_sel.([leader '_d2north']);
    stable_sel.lead_d2east = stable_sel.([leader '_d2east']);
    stable_sel.lead_dis_dif = stable_sel.([leader '_dis_dif']);
    stable_sel.lead_choose_n = stable_sel.([leader '_choose_n']);
    stable_sel.ledBysLead = stable_sel.leader==cLead;
    stable_sel.lead_angle_chosen_zone = stable_sel.([leader '_angle_chosen_zone']);
    stable_sel.lead_d2chosen_zone = stable_sel.([leader '_d2chosen_zone']);

    follower = ['m' num2str(cFoll)];
    stable_sel.foll_angle_east = stable_sel.([follower '_angle_east']);
    stable_sel.foll_angle_north = stable_sel.([follower '_angle_north']);
    stable_sel.foll_angle_dif = stable_sel.([follower '_angle_dif']);
    stable_sel.foll_angle_ez_rot = stable_sel.([follower '_angle_ez_rot']);
    stable_sel.foll_angle_nz_rot = stable_sel.([follower '_angle_nz_rot']); 
    stable_sel.foll_angle_rz_dif = stable_sel.([follower '_angle_rz_dif']);
    stable_sel.foll_d2north = stable_sel.([follower '_d2north']);
    stable_sel.foll_d2east = stable_sel.([follower '_d2east']);
    stable_sel.foll_dis_dif = stable_sel.([follower '_dis_dif']);
    stable_sel.foll_choose_n = stable_sel.([follower '_choose_n']);
    stable_sel.foll_angle_chosen_zone = stable_sel.([follower '_angle_chosen_zone']);
    stable_sel.foll_d2chosen_zone = stable_sel.([follower '_d2chosen_zone']);

    stable_sel.pair = repmat({cur_pair},height(stable_sel),1);
    mstable = [mstable;stable_sel];
    end
end

%% 
% figure; histogram(mstable.lead_d2chosen_zone)
mean(mstable.ledBysLead(mstable.lead_d2chosen_zone<10))
mean(mstable.ledBysLead(mstable.lead_d2chosen_zone>30))

mean(mstable.ledBysLead(mstable.foll_d2chosen_zone<10))
mean(mstable.ledBysLead(mstable.foll_d2chosen_zone>30))

%% probability of leading as a function of distance to reward zones
% clean up mstable
dis_lim = [17 28];
f1 = mstable.lead_d2chosen_zone<dis_lim(1) & mstable.foll_d2chosen_zone<dis_lim(1); 
f2 = mstable.lead_d2chosen_zone<dis_lim(1) & mstable.foll_d2chosen_zone>dis_lim(2); 
f3 = mstable.lead_d2chosen_zone>dis_lim(2) & mstable.foll_d2chosen_zone>dis_lim(2); 
f4 = mstable.lead_d2chosen_zone>dis_lim(2) & mstable.foll_d2chosen_zone<dis_lim(1); 
mstable_sel = mstable(~(f1 | f2 | f3 | f4),:);
% --- Define threshold ranges ---
% range of critera
k1min = 5; k1max = 45;  % full range is 0-55
n_k = k1max-k1min+1;  % controls the granularity of the sampling
kVfront = linspace(k1min,k1max,n_k); % vector of kappa for pref
kVother = kVfront;
dis_range = 5;
[XF,XO] = meshgrid(kVfront,kVother);

x_range = kVfront;   % front activity percentile threshold
y_range = kVother;   % other activity percentile threshold

% --- Initialize heatmap matrix ---
lead_prob = nan(n_k, n_k);
N = nan(n_k,n_k);

% --- Compute leading probability for each percentile pair ---
for iy = 1:n_k
    for ix = 1:n_k
        lead_sel = (mstable_sel.lead_d2chosen_zone > x_range(ix)-dis_range) & (mstable_sel.lead_d2chosen_zone <= x_range(ix)+dis_range);
        foll_sel = (mstable_sel.foll_d2chosen_zone > y_range(iy)-dis_range) & (mstable_sel.foll_d2chosen_zone <= y_range(iy)+dis_range);
        if sum(lead_sel & foll_sel) > 0
            N(iy,ix) = length(mstable_sel.ledBysLead(lead_sel & foll_sel));
            lead_prob(iy, ix) = mean(mstable_sel.ledBysLead(lead_sel & foll_sel));
        end
    end
end
fig = figure('Position',[600 400 500 500]); 
hold on
p = pcolor(XF, XO, lead_prob);
set(p, 'AlphaData', ~isnan(lead_prob))   
ax = gca;
ax.Color = 'k';  
% xticks(0.5:0.1:0.9);
% yticks(0.1:0.1:0.5);
xticks(k1min:5:k1max);
yticks(k2min:5:k2max);
set(gca,'TickDir','out','Box','off','FontSize',20);
% set(gca,'YDir','normal')
clim([0 1])
cm = get_colormap('diverging');
% cm = viridis(100); 
colormap(cm);
colorbar;
% xlabel({'Percentile_{front}'; 'Response front RF < Percentile_{front}'});
% ylabel({'Percentile_{other}'; 'Response other RF > Percentile_{other}'});
xlabel('Leader distance to chosen zone (cm)');
ylabel('Follower distance to chosen zone (cm)');
title('Probability of trials led by leader');
plot([5 45],[5 45],'k:','LineWidth',1)
xlim([5 45])
ylim([5 45])
axis square; 
shading interp; % This interpolates colors across the faces of the cells
hoy = char(datetime('now','Format','yyyyMMdd'));
fd = '/Users/herbert/Wulab Dropbox/Lab/Yuan/imaging_analysis/';
figname = [fd '/plots/' hoy '_prob_leadership_init_distance.pdf'];
% print(fig,figname,'-dpdf');
% print(fig, figname, '-dpng', '-r300');
exportgraphics(fig, figname, 'ContentType', 'vector')

%%

figure('Position',[400 400 400 400]);
% scatter(mstable.lead_d2chosen_zone, mstable.foll_d2chosen_zone,30)
scatter(mstable_sel.lead_d2chosen_zone, mstable_sel.foll_d2chosen_zone,30)
axis equal
xlim([0 55])
ylim([0 55])

%% probability of leading as a function of angle from reward zones

% --- Define threshold ranges ---
% range of critera
k1min = 10; k1max = 170;  % full range is 0-180
n_k = k1max-k1min+1;  % controls the granularity of the sampling
kVfront = linspace(k1min,k1max,n_k); % vector of kappa for pref
kVother = kVfront;
hd_range = 10;
[XF,XO] = meshgrid(kVfront,kVother);

x_range = kVfront;   % front activity percentile threshold
y_range = kVother;   % other activity percentile threshold

% --- Initialize heatmap matrix ---
lead_prob = nan(n_k, n_k);
N = nan(n_k,n_k);

% --- Compute leading probability for each percentile pair ---
for iy = 1:n_k
    for ix = 1:n_k
        lead_sel = (mstable.lead_angle_chosen_zone > x_range(ix)-hd_range) & (mstable.lead_angle_chosen_zone <= x_range(ix)+hd_range);
        foll_sel = (mstable.foll_angle_chosen_zone > y_range(iy)-hd_range) & (mstable.foll_angle_chosen_zone <= y_range(iy)+hd_range);
        if sum(lead_sel & foll_sel) > 0
            N(iy,ix) = length(mstable.ledBysLead(lead_sel & foll_sel));
            lead_prob(iy, ix) = mean(mstable.ledBysLead(lead_sel & foll_sel));
        end
    end
end
%
fig = figure('Position',[600 400 500 500]); 
hold on
% imagesc(x_range/100, y_range/100, lead_prob);
pcolor(XF, XO, lead_prob);
% xticks(0.5:0.1:0.9);
% yticks(0.1:0.1:0.5);
xlim([k1min k1max])
ylim([k1min k1max])
xticks(k1min:20:k1max);
yticks(k1min:20:k1max);
set(gca,'TickDir','out','Box','off','FontSize',20);
% set(gca,'YDir','normal')
clim([0.5 1])
% cm = get_colormap('diverging');
cm = viridis(100); 
colormap(cm);
colorbar;
% xlabel({'Percentile_{front}'; 'Response front RF < Percentile_{front}'});
% ylabel({'Percentile_{other}'; 'Response other RF > Percentile_{other}'});
xlabel(['Leader HD from chosen zone (' char(176) ')']);
ylabel(['Follower HD from chosen zone (' char(176) ')']);
title('Probability of trials led by leader');
% plot([5 45],[5 45],'k:','LineWidth',1)
% xlim([5 45])
% ylim([5 45])
axis square;
shading interp; % This interpolates colors across the faces of the cells
hoy = char(datetime('now','Format','yyyyMMdd'));
fd = '/Users/herbert/Wulab Dropbox/Lab/Yuan/imaging_analysis/';
figname = [fd '/plots/' hoy '_prob_leadership_init_HD.pdf'];
% print(fig,figname,'-dpdf');
exportgraphics(fig, figname, 'ContentType', 'vector')
