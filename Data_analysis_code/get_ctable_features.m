function ctable = get_ctable_features(ctable)
% get extra ctable features
n_ses = height(ctable);
ctable.omission_rate = nan(n_ses,1);
ctable.ses_trials = nan(n_ses,1);
for s = 1:n_ses
    cur_stable = ctable.stable{s};
    ctable.omission_rate(s) = mean(cur_stable.miss);
    ctable.ses_trials(s) = height(cur_stable);
end