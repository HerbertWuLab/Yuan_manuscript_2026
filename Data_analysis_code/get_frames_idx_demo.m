function [frames_idxn, stable_sel] = get_frames_idx_demo(which_frames,stable_sel,ftable,params)
self_id = params.id;
st = stable_sel.led_init;
en = stable_sel.led_end;
self_arr = stable_sel.([self_id '_last_arr']);
% self_dpt = stable_sel.([self_id '_depart']);

n_trials = height(stable_sel);
n_frames = height(ftable);
frames = [];
pre_st = 60; post_st = 30; % time points for before and after init
pre_en = 60; post_en = 60; % time points for before and after end
stable_sel.windows = cell(n_trials,1);

% rename ftable variable
if ~strcmp('m1_min_d2_rz',ftable.Properties.VariableNames)
    ftable = renamevars(ftable,"m1_min_dis_rzc","m1_min_d2_rz");
end
if ~strcmp('m2_min_d2_rz',ftable.Properties.VariableNames)
    ftable = renamevars(ftable,"m2_min_dis_rzc","m2_min_d2_rz");
end

switch which_frames
    case "self_outside_arrival_zone"
        frames = find(ftable.([self_id '_min_d2_rz'])>10)';
    case "both_outside_arrival_zone"
        frames = find(ftable.m1_min_d2_rz>10 & ftable.m2_min_d2_rz>10)';
end
frames_idxn = frames';