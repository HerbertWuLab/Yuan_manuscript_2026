function ltable = extract_ltable_demo(ctable)
% extract learning phase data table
%%
uni_pairs = unique(ctable.pair);
n_uni_pairs = length(uni_pairs);
ltable = [];
% for p = 2
for p = 1:n_uni_pairs
    cur_pair = uni_pairs{p};
    cur_ctable = ctable(strcmp(cur_pair,ctable.pair),:);
    cp_rate_d1 = cur_ctable.cp_rate(1)*100;
    if cp_rate_d1 >= 70 % check if the performance is too good on Day 1
        fprintf([cur_pair ' is at %.1f percent correct on its 1st day. '...
            'Please confirm that the data table does not include the training phase\n'],cp_rate_d1);
    else    
        % find the days when the pair reaches criterion:
        % >=80% for 3 consectutive days
        % people round the coop rate when determining if mice reach criterion 
        % so 0.795 is used because it rounds to 0.80... 
        % akward consequence when people take shortcut..

        cp_rate = cur_ctable.cp_rate;
        cp_rate_logic = cp_rate >=0.795;
        % cp_rate_logic = cp_rate >=0.8;

        cp_rate_logic_movsum = movsum(cp_rate_logic,[2 0]); % trailing sum
        day_crit = find(cp_rate_logic_movsum==3,1,'first');

        if ~isempty(day_crit)
            cur_ltable = cur_ctable(1:day_crit,:);
            cur_ltable.days = (1:day_crit)';
            cur_ltable.at_crit = zeros(height(cur_ltable),1);
            cur_ltable.at_crit(end-2:end) = 1;
            ltable = [ltable;cur_ltable];
        else
            disp([cur_pair ' does not contain data above criterion and is removed.'])
        end
    end
end
ltable = movevars(ltable,"at_crit",'After',"phase");
ltable = movevars(ltable,"days",'After',"phase");
fprintf('remove %d sessions with cno inactivation\n',sum(ltable.cno))
ltable = ltable(ltable.cno==0,:);
% ltable.n_trials = cellfun(@height, ltable.stable);
% fprintf('remove %d sessions with <80 trials\n',sum(ltable.n_trials<80))
% ltable = ltable(ltable.n_trials>=80,:);
