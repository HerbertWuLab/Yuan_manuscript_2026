function cno_table = get_cno_inact(cno_table)
% calculate 
n_ses = height(cno_table);
cno_table.r_ratio = cell(n_ses,1);
large_rewards = [10,6,5];
small_rewards = [4,3,2,1];
for s = 1:n_ses
    cur_pair = cno_table.pair{s};
    cur_date = cno_table.date{s};
    if cno_table.p_ledBy_m1(s) > cno_table.p_ledBy_m2(s)
        cno_table.lead_mean_spd(s) = cno_table.m1_mean_spd(s);
        cno_table.foll_mean_spd(s) = cno_table.m2_mean_spd(s);
        cno_table.lead_med_spd(s) = cno_table.m1_med_spd(s);
        cno_table.foll_med_spd(s) = cno_table.m2_med_spd(s);
        cno_table.lead_95p_spd(s) = cno_table.m1_95p_spd(s);
        cno_table.foll_95p_spd(s) = cno_table.m2_95p_spd(s);
        cno_table.lead_rt_mean(s) = cno_table.m1_rt_mean(s);
        cno_table.foll_rt_mean(s) = cno_table.m2_rt_mean(s);
        cno_table.lead_rt_med(s) = cno_table.m1_rt_med(s);
        cno_table.foll_rt_med(s) = cno_table.m2_rt_med(s);
        cno_table.lead_rt_co_mean(s) = cno_table.m1_rt_co_mean(s);
        cno_table.foll_rt_co_mean(s) = cno_table.m2_rt_co_mean(s);
        cno_table.lead_rt_mm_mean(s) = cno_table.m1_rt_mm_mean(s);
        cno_table.foll_rt_mm_mean(s) = cno_table.m2_rt_mm_mean(s);
        cno_table.lead_im_p(s) = cno_table.m1_im_p(s);
        cno_table.foll_im_p(s) = cno_table.m2_im_p(s);
    elseif cno_table.p_ledBy_m1(s) < cno_table.p_ledBy_m2(s)
        cno_table.lead_mean_spd(s) = cno_table.m2_mean_spd(s);
        cno_table.foll_mean_spd(s) = cno_table.m1_mean_spd(s);
        cno_table.lead_med_spd(s) = cno_table.m2_med_spd(s);
        cno_table.foll_med_spd(s) = cno_table.m1_med_spd(s);
        cno_table.lead_95p_spd(s) = cno_table.m2_95p_spd(s);
        cno_table.foll_95p_spd(s) = cno_table.m1_95p_spd(s);
        cno_table.lead_rt_mean(s) = cno_table.m2_rt_mean(s);
        cno_table.foll_rt_mean(s) = cno_table.m1_rt_mean(s);
        cno_table.lead_rt_med(s) = cno_table.m2_rt_med(s);
        cno_table.foll_rt_med(s) = cno_table.m1_rt_med(s);
        cno_table.lead_rt_co_mean(s) = cno_table.m2_rt_co_mean(s);
        cno_table.foll_rt_co_mean(s) = cno_table.m1_rt_co_mean(s);
        cno_table.lead_rt_mm_mean(s) = cno_table.m2_rt_mm_mean(s);
        cno_table.foll_rt_mm_mean(s) = cno_table.m1_rt_mm_mean(s);
        cno_table.lead_im_p(s) = cno_table.m2_im_p(s);
        cno_table.foll_im_p(s) = cno_table.m1_im_p(s);
    else % no leader
        cno_table.lead_mean_spd(s) = NaN;
        cno_table.foll_mean_spd(s) = NaN;
        cno_table.lead_med_spd(s) = NaN;
        cno_table.foll_med_spd(s) = NaN;
        cno_table.lead_95p_spd(s) = NaN;
        cno_table.foll_95p_spd(s) = NaN;
        cno_table.lead_rt_mean(s) = NaN;
        cno_table.foll_rt_mean(s) = NaN;
        cno_table.lead_rt_med(s) = NaN;
        cno_table.foll_rt_med(s) = NaN;
        cno_table.lead_rt_co_mean(s) = NaN;
        cno_table.foll_rt_co_mean(s) = NaN;
        cno_table.lead_rt_mm_mean(s) = NaN;
        cno_table.foll_rt_mm_mean(s) = NaN;
        cno_table.lead_im_p(s) = NaN;
        cno_table.foll_im_p(s) = NaN;
    end
    
    % determine whether sLeader or sFollower is inactivated
    if strcmpi(cno_table.sLead{s},cno_table.subject{s})
        cno_table.subject_inact{s} = 'sLead';
    elseif strcmpi(cno_table.sFoll{s},cno_table.subject{s})
        cno_table.subject_inact{s} = 'sFoll';
    elseif strcmpi('both',cno_table.subject{s})
        cno_table.subject_inact{s} = 'both';
    end

    % hard code the TY003T2814 pair because the leader/follower was unstable
    if strcmp(cur_pair,'TY003T2814') && strcmp(cur_date,'20240721')
        cno_table.subject_inact{s} = 'sLead';
    elseif strcmp(cur_pair,'TY003T2814') && strcmp(cur_date,'20240719')
        cno_table.subject_inact{s} = 'sFoll';
    end

    % normalize these features below by "before" session values
    fea_names = {'co_rate','cp_rate','lead_dsp','init_dsp',...
        'm1_mean_spd','m2_mean_spd','m1_95p_spd','m2_95p_spd',...
        'lead_mean_spd','foll_mean_spd','lead_95p_spd','foll_95p_spd'};
    if cno_table.cno(s) == 1 % if it is a cno session
        for j = 1:length(fea_names)
            cur_fea = fea_names{j};
            cur_fea_norm = [cur_fea '_n'];
            cno_table.(cur_fea_norm)(s-1) = 1;
            cno_table.(cur_fea_norm)(s) = cno_table.(cur_fea)(s)/cno_table.(cur_fea)(s-1);
            % cno_table.(cur_fea_norm)(s+1) = cno_table.(cur_fea)(s+1)/cno_table.(cur_fea)(s-1);
            cur_fea_delta = [cur_fea '_d'];
            cno_table.(cur_fea_delta)(s-1) = 0;
            cno_table.(cur_fea_delta)(s) = cno_table.(cur_fea)(s) - cno_table.(cur_fea)(s-1);
            % cno_table.(cur_fea_delta)(s+1) = cno_table.(cur_fea)(s+1) - cno_table.(cur_fea)(s-1);
        end
    end

    % group the reward ratio for phase 4b data
    if strcmpi(cno_table.phase{s},'phase4b') && cno_table.small_r(s)~=0
        if cno_table.large_r(s)==10 && cno_table.small_r(s)==1
            cno_table.r_ratio{s} = 'b1';
        elseif (cno_table.large_r(s)==10 && cno_table.small_r(s)==2) || ...
            (cno_table.large_r(s)==5 && cno_table.small_r(s)==1) || ...
            (cno_table.large_r(s)==6 && cno_table.small_r(s)==1)
            cno_table.r_ratio{s} = 'b2';
        elseif (cno_table.large_r(s)==10 && cno_table.small_r(s)==3)
            cno_table.r_ratio{s} = 'b3';  
        elseif (cno_table.large_r(s)==10 && cno_table.small_r(s)==4) || ...
            (cno_table.large_r(s)==5 && cno_table.small_r(s)==2) || ...
            (cno_table.large_r(s)==6 && cno_table.small_r(s)==2)
            cno_table.r_ratio{s} = 'b4';  
        else
            disp([cur_pair ' ' cur_date ': reward ratio not expected. check your data!'])
        end
    elseif (strcmpi(cno_table.phase{s},'phase4b') && cno_table.small_r(s)==0) || ...
            (strcmpi(cno_table.phase{s},'phase4a') && cno_table.small_r(s)~=0)
        disp([cur_pair ' ' cur_date ': discrepancy in phase and small reward amount. check your data!'])   
    end
end

