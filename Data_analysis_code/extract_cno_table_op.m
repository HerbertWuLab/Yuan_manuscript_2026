function cno_table = extract_cno_table_op(fd, inact_ses_info_fname, ctable, which_mouse, which_phase, which_dose)
% extract_cno_table
% Extract CNO sessions (before + CNO + optional after) from ctable using an info table.
%
% Key behavior change:
%   - If after-day session is NOT found, still keep BEFORE + CNO only (no error, no skip).
%   - Do NOT assume sessions are contiguous rows in ctable; use explicit indices.

%% load inactivation session information
info_table = readtable(inact_ses_info_fname);

%% select sessions
remove_animals = {};  % keep your original setting
sel = ismember(info_table.animal_inactivated, which_mouse) & ...
      ismember(info_table.phase, which_phase) & ...
      ~ismember(info_table.pair, remove_animals);

sel_info_table = info_table(sel, :);
info_table_sorted = sortrows(sel_info_table, 'pair');

%% extract CNO sessions from ctable
n_ses = height(info_table_sorted);
cno_table = [];

for s = 1:n_ses
    cur_pair = info_table_sorted.pair{s};

    % ----- BEFORE -----
    cur_before_date = string(info_table_sorted.before_date(s));
    idx_before = find(strcmpi(cur_pair, ctable.pair) & strcmpi(cur_before_date, ctable.date), 1, 'first');

    % ----- CNO -----
    cur_cno_date = string(info_table_sorted.CNO_date(s));
    idx_cno = find(strcmpi(cur_pair, ctable.pair) & strcmpi(cur_cno_date, ctable.date), 1, 'first');

    % ----- AFTER (optional) -----
    cur_after_date = string(info_table_sorted.after_date(s));
    idx_after = find(strcmpi(cur_pair, ctable.pair) & strcmpi(cur_after_date, ctable.date), 1, 'first');

    % ----- sanity checks -----
    if isempty(idx_before)
        fprintf('%s on %s (before day) not found in the ctable.\n', cur_pair, cur_before_date);
        continue
    end

    if isempty(idx_cno)
        fprintf('%s on %s (cno day) not found in the ctable.\n', cur_pair, cur_cno_date);
        continue
    end

    % ----- dose check (use CNO day) -----
    if ctable.dose(idx_cno) ~= which_dose
        fprintf('%s on %s does not meet dose criterion and is removed. Looking for %.1fmg/kg but found %.1fmg/kg\n', ...
            cur_pair, cur_cno_date, which_dose, ctable.dose(idx_cno));
        continue
    end

    % ----- build output rows explicitly (robust) -----
    idx_keep = [idx_before; idx_cno];

    if isempty(idx_after)
        fprintf('%s on %s (after day) not found in the ctable. Using before+cno only.\n', ...
            cur_pair, cur_after_date);
    else
        idx_keep = [idx_keep; idx_after];
    end

    % keep chronological-like order (at least stable)
    idx_keep = sort(idx_keep);

    cur_table = ctable(idx_keep, :);
    cno_table = [cno_table; cur_table];
end

end
