function htable = extract_htable(ctable)
% Extract hierachy table for analyzing social hierachy
% Find the first well-trained session (phase 4a) with available hierachy data

%%
uni_pairs = unique(ctable.pair);
n_uni_pairs = length(uni_pairs);
htable = [];
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    % note that the session needs to be in phase 4a
    sel = strcmp(cur_pair,ctable.pair) & ctable.cp_rate>=0.795 & ctable.cno==0 & strcmp(ctable.phase,'phase4a');
    cur_ctable = ctable(sel,:);

    % find the first well-trained session with existing hierachy data
    idx = find(~cellfun(@isempty,cur_ctable.rank),1,'first');
    if ~isempty(idx)
        cur_htable = cur_ctable(idx,:);
        htable = [htable;cur_htable];
    else
        disp(['No rank info found in any well-trained sessions for ' cur_pair])
        continue;
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

