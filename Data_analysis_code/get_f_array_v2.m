function [f_array, mask, params] = get_f_array_v2(finput, stable_sel, params)
% align fluorescence based on alignBy and make f_array
% f_array in n_sel_trials x f_array_length x n_cells
% finput should be nFrames x n_cells or nFrames x n_pos, etc
% v2: for plotting leader-selective neurons

%% get params
alignBy = params.alignBy;
n_element = size(finput,2);

self_id = params.id; % m1 or m2
self_id_num = str2double(self_id(2));
other_id = ['m' num2str(3-self_id_num)];
if strcmp(alignBy,'SelfArrival')
    alignBy = [self_id 'Arrival']; 
elseif strcmp(alignBy,'OtherArrival')
    alignBy = [other_id 'Arrival']; 
end

%% get the f_array
n_trials_sel = height(stable_sel);
dur_f = stable_sel.dur_f;
led_init = stable_sel.led_init;
m1_arr = stable_sel.m1_last_arr;
m2_arr = stable_sel.m2_last_arr;
led_end = stable_sel.led_end;
% pre_st = 90;
% post_en = 90;
pre_st = 30;
post_en = 70;

switch alignBy
    case 'TrialStart' 
        max_trial_len = max(dur_f);
        startIdx = led_init - pre_st;
        endIdx = led_init + max_trial_len + post_en;
        t_range = [-pre_st max_trial_len+post_en];
        t1 = m1_arr - led_init; % m1_arr in the time axis (align is at 0)
        t2 = m2_arr - led_init;
        t3 = dur_f;
        time_idx = [2 3 4]; % color idx for t1/t2/t3
        align_idx = 1; % color idx for alignment event
        array_startIdx = ones(n_trials_sel,1);
        % array_endIdx = pre_st + dur_f + post_en+1;
    case 'm1Arrival'
        max_pre_align = max(m1_arr-led_init);
        max_post_align = max(led_end-m1_arr);
        startIdx = m1_arr - max_pre_align - pre_st;
        endIdx = m1_arr + max_post_align + post_en;
        t_range = [-max_pre_align-pre_st max_post_align + post_en];
        t1 = led_init-m1_arr;
        t2 = m2_arr-m1_arr;
        t3 = led_end-m1_arr;
        time_idx = [1 3 4];  
        align_idx = 2;
        array_startIdx = max_pre_align-(m1_arr-led_init)+1;
        % array_endIdx = array_startIdx+pre_st+dur_f+post_en;
    case 'm2Arrival'
        max_pre_align = max(m2_arr-led_init);
        max_post_align = max(led_end-m2_arr);
        startIdx = m2_arr - max_pre_align - pre_st;
        endIdx = m2_arr + max_post_align + post_en;
        t_range = [-max_pre_align-pre_st max_post_align+post_en];
        t1 = led_init-m2_arr;
        t2 = m1_arr-m2_arr;
        t3 = led_end-m2_arr;
        time_idx = [1 2 4];  
        align_idx = 3;
        array_startIdx = max_pre_align-(m2_arr-led_init)+1;
    case 'TrialEnd'
        max_trial_len = max(dur_f);
        startIdx = led_end - max_trial_len - pre_st;
        endIdx = led_end + post_en;
        t_range = [-max_trial_len-pre_st post_en];
        t1 = -dur_f;
        t2 = m1_arr - led_end;
        t3 = m2_arr - led_end;
        time_idx = [1 2 3];  
        align_idx = 4;
        array_startIdx = max_trial_len - dur_f +1;
end
array_endIdx = array_startIdx+pre_st+dur_f+post_en;
t_array = (t_range(1):t_range(2));
f_array_length = t_range(2) - t_range(1) + 1;

% get f_array
n_sel_trials = height(stable_sel);
f_array = nan(n_sel_trials,f_array_length,n_element);
for n = 1:n_element
    cur_finput = finput(:,n);
    for i = 1:n_sel_trials
        if ~isnan(startIdx(i)) % some arrival times are NaNs, skip them
            f_array(i,:,n) = cur_finput(startIdx(i):endIdx(i)); 
        end
    end
end

% make the mask, which is for removing the frames outside a trial
mask = nan(n_sel_trials,f_array_length);
for i = 1:n_sel_trials
    if ~isnan(array_startIdx(i)) % some arrival times are NaNs, skip them
        mask(i,array_startIdx(i):array_endIdx(i)) = 1;
    end
end

event_times = [t1 t2 t3];
params.event_times = event_times;
params.time_idx = time_idx;
params.align_idx = align_idx;
params.t_range = t_range;
params.t_array = t_array;
params.startIdx = startIdx;
params.endIdx = endIdx;
params.f_array_length = f_array_length;
