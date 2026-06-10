function wt_ctable = select_well_trained_sessions_v2(ctable)

uni_pairs = unique(ctable.pair);
n_uni_pairs = length(uni_pairs);
ltable = extract_ltable(ctable);
wt_ctable = [];
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};

    % process the ctable
    btable = ctable(strcmp(cur_pair,ctable.pair),:);
    
    if strcmp(cur_pair,'YC013YC014') % only use sessions before extended phase4b+cno sessions
        btable = btable(str2double(btable.date)<=20230804,:);
    elseif strcmp(cur_pair,'YC015YC016') % only use sessions before extended phase4b+cno sessions
        btable = btable(str2double(btable.date)<=20230831,:);
    elseif strcmp(cur_pair,'YC017YC018') % only use sessions before extended phase4b+cno sessions
        btable = btable(str2double(btable.date)<=20231017,:);    
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
    end
    wt_ctable = [wt_ctable;btable];
end