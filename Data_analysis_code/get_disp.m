function syllable_table=get_disp(syllable_table)
% get leader and follower proportions and correct rate when either animal leads

n_ses = height(syllable_table);
% syllable_table.cp_ra_leBy_sLe = nan(n_ses,1); % cooperation rate of trials led by session Leader
% syllable_table.cp_ra_leBy_sFo = nan(n_ses,1); % cooperation rate of trials led by session Follower
% syllable_table.cp_ra_inBy_sIn = nan(n_ses,1); % cooperation rate of trials initiated by session Initiator
% syllable_table.cp_ra_inBy_sRe = nan(n_ses,1); % cooperation rate of trials initiated by session Respondent
% syllable_table.tr_le = nan(n_ses,1); % prop of trials led by the leader is significantly higher than chance
% syllable_table.tr_in = nan(n_ses,1); % prop of trials init by the initiator is significantly higher than chance
chance_level = 0.5; % if m1 and m2 are equally likely to lead
for s = 1:n_ses
    stable = syllable_table.stable{s};
    
    % leaders can be called only in correct or mismatch trials
    sel = stable.correct==1 | stable.mismatch==1; 
    sel_stable = stable(sel,:);

    syllable_table.p_ledBy_m1(s) = mean(sel_stable.leader==1); % prop of trials led by m1
    syllable_table.p_ledBy_m2(s) = mean(sel_stable.leader==2); % prop of trials led by m2
    syllable_table.p_initBy_m1(s) = mean(sel_stable.initiator == 1); % prop of trials initiated by m1
    syllable_table.p_initBy_m2(s) = mean(sel_stable.initiator == 2); % prop of trials initiated by m2  

    % cooperation rate of trials led/init by m1/m2
    syllable_table.cp_rate_ledBy_m1(s) = mean(sel_stable.correct(sel_stable.leader==1));
    syllable_table.cp_rate_ledBy_m2(s) = mean(sel_stable.correct(sel_stable.leader==2));
    syllable_table.cp_rate_initBy_m1(s) = mean(sel_stable.correct(sel_stable.initiator==1));
    syllable_table.cp_rate_initBy_m2(s) = mean(sel_stable.correct(sel_stable.initiator==2));

    % short trials only
    sel_s_stable = sel_stable(sel_stable.dur_f<150,:);
    syllable_table.p_ledBy_m1_s(s) = mean(sel_s_stable.leader==1); % prop of trials led by m1
    syllable_table.p_ledBy_m2_s(s) = mean(sel_s_stable.leader==2); % prop of trials led by m2
    syllable_table.p_initBy_m1_s(s) = mean(sel_s_stable.initiator == 1); % prop of trials initiated by m1
    syllable_table.p_initBy_m2_s(s) = mean(sel_s_stable.initiator == 2); % prop of trials initiated by m2  

    % cooperation rate of trials led/init by m1/m2
    syllable_table.cp_rate_ledBy_m1_s(s) = mean(sel_s_stable.correct(sel_s_stable.leader==1));
    syllable_table.cp_rate_ledBy_m2_s(s) = mean(sel_s_stable.correct(sel_s_stable.leader==2));
    syllable_table.cp_rate_initBy_m1_s(s) = mean(sel_s_stable.correct(sel_s_stable.initiator==1));
    syllable_table.cp_rate_initBy_m2_s(s) = mean(sel_s_stable.correct(sel_s_stable.initiator==2));

    % cooperation rate of trials led by session leader/follower
    if syllable_table.p_ledBy_m1(s) > syllable_table.p_ledBy_m2(s) % m1 leads most trials
        syllable_table.sLead{s} = 'm1';
        syllable_table.sFoll{s} = 'm2';
        syllable_table.cp_rate_ledBy_sLead(s) = syllable_table.cp_rate_ledBy_m1(s);
        syllable_table.cp_rate_ledBy_sFoll(s) = syllable_table.cp_rate_ledBy_m2(s);
        syllable_table.p_ledBy_sLead(s) = syllable_table.p_ledBy_m1(s); % prop of trials led by session leader
        syllable_table.p_ledBy_sFoll(s) = syllable_table.p_ledBy_m2(s); 
        syllable_table.p_initBy_sLead(s) = syllable_table.p_initBy_m1(s);
    elseif syllable_table.p_ledBy_m1(s) < syllable_table.p_ledBy_m2(s) % m2 leads
        syllable_table.sLead{s} = 'm2';
        syllable_table.sFoll{s} = 'm1';
        syllable_table.cp_rate_ledBy_sLead(s) = syllable_table.cp_rate_ledBy_m2(s);
        syllable_table.cp_rate_ledBy_sFoll(s) = syllable_table.cp_rate_ledBy_m1(s);
        syllable_table.p_ledBy_sLead(s) = syllable_table.p_ledBy_m2(s); % prop of trials led by session leader
        syllable_table.p_ledBy_sFoll(s) = syllable_table.p_ledBy_m1(s); 
        syllable_table.p_initBy_sLead(s) = syllable_table.p_initBy_m2(s);
    else % no leader
        syllable_table.sLead{s} = nan;
        syllable_table.sFoll{s} = nan;
        syllable_table.cp_rate_ledBy_sLead(s) = nan;
        syllable_table.cp_rate_ledBy_sFoll(s) = nan;
        syllable_table.p_ledBy_sLead(s) = nan; % prop of trials led by session leader
        syllable_table.p_ledBy_sFoll(s) = nan;
        syllable_table.p_initBy_sLead(s) = nan;
    end

    % cooperation rate of trials init by session initiator/respondent
    if syllable_table.p_initBy_m1(s) > syllable_table.p_initBy_m2(s) % m1 initiator
        syllable_table.sInit{s} = 'm1';
        syllable_table.sResp{s} = 'm2';
        syllable_table.cp_rate_initBy_sInit(s) = syllable_table.cp_rate_initBy_m1(s);
        syllable_table.cp_rate_initBy_sResp(s) = syllable_table.cp_rate_initBy_m2(s);
        syllable_table.p_initBy_sInit(s) = syllable_table.p_initBy_m1(s); % prop of trials init by session initiator
        syllable_table.p_initBy_sResp(s) = syllable_table.p_initBy_m2(s); 
    elseif syllable_table.p_initBy_m1(s) < syllable_table.p_initBy_m2(s) % m2 initiator
        syllable_table.sInit{s} = 'm2';
        syllable_table.sResp{s} = 'm1';
        syllable_table.cp_rate_initBy_sInit(s) = syllable_table.cp_rate_initBy_m2(s);
        syllable_table.cp_rate_initBy_sResp(s) = syllable_table.cp_rate_initBy_m1(s);
        syllable_table.p_initBy_sInit(s) = syllable_table.p_initBy_m2(s); % prop of trials init by session initiator
        syllable_table.p_initBy_sResp(s) = syllable_table.p_initBy_m1(s); 
    else % no leader
        syllable_table.sInit{s} = nan;
        syllable_table.sResp{s} = nan;
        syllable_table.cp_rate_initBy_sInit(s) = nan;
        syllable_table.cp_rate_initBy_sResp(s) = nan;
        syllable_table.p_initBy_sInit(s) = nan;
        syllable_table.p_initBy_sResp(s) = nan;
    end

    % determine if prop of trials led by the session leader is significantly above chance
    n_ledBy_m1 = sum(sel_stable.leader==1); % num of trials led by m1
    n_ledBy_m2 = sum(sel_stable.leader==2); % num of trials led by m2
    syllable_table.n_ledBy_m1(s) = n_ledBy_m1;
    syllable_table.n_ledBy_m2(s) = n_ledBy_m2;
    [~, pci] = binofit(n_ledBy_m1, (n_ledBy_m1+n_ledBy_m2), 0.01); % use alpha = 0.01
    syllable_table.lead_pci{s} = pci; % 99% probability confidence interval
    if chance_level >= pci(1) && chance_level <= pci(2)
        syllable_table.true_lead(s) = 0; % true leader
    else
        syllable_table.true_lead(s) = 1;
    end

    % determine if prop of trials init by the session initiator is significantly above chance
    n_initBy_m1 = sum(sel_stable.initiator==1); % num of trials init by m1
    n_initBy_m2 = sum(sel_stable.initiator==2); % num of trials init by m2
    syllable_table.n_initBy_m1(s) = n_initBy_m1;
    syllable_table.n_initBy_m2(s) = n_initBy_m2;
    [~, pci] = binofit(n_initBy_m1, (n_initBy_m1+n_initBy_m2), 0.01); % use alpha = 0.01
    syllable_table.init_pci{s} = pci;
    if chance_level >= pci(1) && chance_level <= pci(2)
        syllable_table.true_init(s) = 0;
    else
        syllable_table.true_init(s) = 1;
    end
end

% leader disparity, defined as the abs difference in the prop of trials led by each mouse 
syllable_table.lead_dsp = abs(syllable_table.p_ledBy_m1 - syllable_table.p_ledBy_m2);

% same for initiator disparity
syllable_table.init_dsp = abs(syllable_table.p_initBy_m1 - syllable_table.p_initBy_m2);

end
