function cno_table = extract_cno_table_demo(inact_ses_info_fname,ctable,which_mouse,which_phase,which_dose)
%%
% extract cno (and before and after) sessions
info_table = readtable(inact_ses_info_fname);

% select the inactivation of both animals in phase 4a
remove_animals = {};
sel = ismember(info_table.animal_inactivated, which_mouse) & ...
        ismember(info_table.phase, which_phase) & ...
        ~ismember(info_table.pair, remove_animals);
sel_info_table = info_table(sel,:);
info_table_sorted = sortrows(sel_info_table,'pair');

% extract these cno sessions from ctable
n_ses = height(info_table_sorted);
cno_table = [];
for s = 1:n_ses
    cur_pair = info_table_sorted.pair{s};
    cur_before_date = string(info_table_sorted.before_date(s));
    idx_array = strcmpi(cur_pair,ctable.pair) & strcmpi(cur_before_date,ctable.date); 
    idx_before = find(idx_array);
    cur_cno_date = string(info_table_sorted.CNO_date(s));
    idx_array = strcmpi(cur_pair,ctable.pair) & strcmpi(cur_cno_date,ctable.date); 
    idx_cno = find(idx_array); 
    cur_after_date = string(info_table_sorted.after_date(s));
    idx_array = strcmpi(cur_pair,ctable.pair) & strcmpi(cur_after_date,ctable.date); 
    idx_after = find(idx_array); 
    if isempty(idx_before)
        fprintf('%s on %s (before day) not found in the ctable.\n',cur_pair,cur_before_date)
        continue;
    elseif isempty(idx_cno)
        fprintf('%s on %s (cno day) not found in the ctable.\n',cur_pair,cur_cno_date)
        continue;
    else
        if isempty(idx_after)
            idx_range = 1;
            fprintf('%s on %s (after day) not found in the ctable.\n',cur_pair,cur_after_date)
        else
            idx_range = 2;
        end
        if ctable.dose(idx_cno) == which_dose
            cur_table = ctable(idx_before:idx_before+idx_range,:);
            cno_table = [cno_table;cur_table];
        else
            fprintf('%s on %s with %.1fmg/kg is removed. Looking for %.1fmg/kg\n',...
                cur_pair, cur_cno_date, ctable.dose(idx_before+1),which_dose)
        end
    end
end
