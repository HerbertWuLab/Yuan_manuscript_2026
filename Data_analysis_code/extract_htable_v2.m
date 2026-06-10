function htable = extract_htable_v2(ctable)
% extract hierachy table for analyzing social hierachy
% v2: find the first well-trained session (phase 4a) with available hierachy data

%% recaculate
ctable = recalc_leader_disp(ctable); % get adjusted leader/initiator props
ltable = extract_ltable(ctable); 

uni_pairs = unique(ctable.pair);
n_uni_pairs = length(uni_pairs);
htable = [];
% for p = 2
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    cur_ltable = ltable(strcmp(ltable.pair,cur_pair),:);
    if ~isempty(cur_ltable) && cur_ltable.true_lead(end) && cur_ltable.true_init(end)
        if ~isempty(cur_ltable.rank{end})
            cur_htable = cur_ltable(end,{'pair';'sex';'date';'phase';'cno';...
                'dose';'rank';'sLead';'sInit';'p_ledBy_sLead';'p_ledBy_sFoll';'p_initBy_sInit';'p_initBy_sResp';'true_lead';'true_init'}); % take criterion day 3 if it has ranking
            htable = [htable;cur_htable];
            disp([cur_pair ': ranking found on criterion day 3'])
        else % find a later well-trained date
            crit_day3 = cur_ltable.date(end);
            cur_ctable = ctable(strcmp(ctable.pair,cur_pair),:);
            sel_date = str2double(cur_ctable.date) > str2double(crit_day3);
    
            % sel = sel_date & cur_ctable.cp_rate>=0.795 & cur_ctable.cno==0 & strcmp(cur_ctable.phase,'phase4a');
            sel = sel_date & cur_ctable.cp_rate>=0.795 & cur_ctable.cno==0; % can use a phase4b session
            cur_ctable = cur_ctable(sel,:);
    
            % find the first well-trained session with existing hierachy data
            idx = find(~cellfun(@isempty,cur_ctable.rank),1,'first');
            if ~isempty(idx)
                cur_htable = cur_ctable(idx,{'pair';'sex';'date';'phase';'cno';...
                    'dose';'rank';'sLead';'sInit';'p_ledBy_sLead';'p_ledBy_sFoll';'p_initBy_sInit';'p_initBy_sResp';'true_lead';'true_init'});
                htable = [htable;cur_htable];
                disp([cur_pair ': No ranking on criterion day 3, but found in later well-trained sessions'])
            else
                disp([cur_pair ': No ranking found in any well-trained sessions'])
                continue;
            end
        end
    end
end
%% calculate prop trials led or init by dominant or subodinate
htable.p_ledBy_dom = nan(height(htable),1);
htable.p_ledBy_sub = nan(height(htable),1);
htable.p_initBy_dom = nan(height(htable),1);
htable.p_initBy_sub = nan(height(htable),1);

% when the dominant is leader
idx_congru = strcmpi(htable.rank,htable.sLead); 
htable.p_ledBy_dom(idx_congru) = htable.p_ledBy_sLead(idx_congru);
htable.p_ledBy_sub(idx_congru) = htable.p_ledBy_sFoll(idx_congru);

% when dominant is not leader
htable.p_ledBy_dom(~idx_congru) = htable.p_ledBy_sFoll(~idx_congru);
htable.p_ledBy_sub(~idx_congru) = htable.p_ledBy_sLead(~idx_congru);

% same for initiator
idx_congru = strcmpi(htable.rank,htable.sInit); 
htable.p_initBy_dom(idx_congru) = htable.p_initBy_sInit(idx_congru);
htable.p_initBy_sub(idx_congru) = htable.p_initBy_sResp(idx_congru);

htable.p_initBy_dom(~idx_congru) = htable.p_initBy_sResp(~idx_congru);
htable.p_initBy_sub(~idx_congru) = htable.p_initBy_sInit(~idx_congru);

% scripts for validation
% temp = htable(:,{'pair','rank','p_ledBy_m1','p_ledBy_m2','p_ledBy_sLead','p_ledBy_sFoll','p_ledBy_dom','p_ledBy_sub','sLead','sFoll','sInit','sResp'});
% temp = htable(:,{'pair','rank','p_initBy_m1','p_initBy_m2','p_initBy_sInit','p_initBy_sResp','p_initBy_dom','p_initBy_sub','sLead','sFoll','sInit','sResp'});

