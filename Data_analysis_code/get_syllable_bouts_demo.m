function bouts = get_syllable_bouts(syllable,stable)
%% get all the syllable bouts from a session

%% get the bouts
T = syllable;
% T is your table
frameVar = T.Properties.VariableNames{1};           % e.g., 'OriginalFrameNumber'
drop = {frameVar,'IncludedInNewVideo','StitchedFrameNumber','m2_sync'};
syllCols = setdiff(T.Properties.VariableNames, drop);

S = strings(0,1);  SF = [];  EF = [];  DUR = [];
F = T.(frameVar);

for v = syllCols
    x = T.(v{1}) == 1;                               % 1 = present
    d = diff([0; x; 0]);                             % transitions
    sIdx = find(d == 1);                             % bout starts (row index)
    eIdx = find(d == -1) - 1;                        % bout ends   (row index)
    if ~isempty(sIdx)
        S   = [S;   repmat(string(v), numel(sIdx), 1)];
        SF  = [SF;  F(sIdx)];
        EF  = [EF;  F(eIdx)];
        DUR = [DUR; EF(end-numel(sIdx)+1:end) - F(sIdx) + 1]; % frames
    end
end

bouts = table(S, SF, EF, DUR, 'VariableNames', ...
              {'Syllable','StartFrame','EndFrame','DurationFrames'});
bouts = sortrows(bouts, {'Syllable','StartFrame'});

%% find the coordinates of both animals
% counter-clockwise rotate angles for trial type = 1-6
thetas = [0, pi/2, pi, -pi/2, 0, pi/2]; 
% which zone is in the north after rotation for trial type = 1-6
nzone_rot = [1, 2, 3, 4, 1, 2];

n_instance = height(bouts);
bouts.trial = nan(n_instance,1);
bouts.zone = nan(n_instance,1);
bouts.m1_pos_rot = cell(n_instance,1);
bouts.m2_pos_rot = cell(n_instance,1);
bouts.inter_dist = cell(n_instance,1);
for n = 1:n_instance
    cur_syll = bouts.Syllable{n};
    id = cur_syll(1:2);
    frame_st = bouts.StartFrame(n);
    frame_en = bouts.EndFrame(n);
    cur_tr = find(frame_st > (stable.led_init - 30),1,'last');
    cur_zone = stable.m1_zone(cur_tr);
    cur_trialtype = stable.trial_type(cur_tr);
    bouts.trial(n) = cur_tr;
    bouts.zone(n) = cur_zone;
    % confirm this trial is correct
    if stable.correct(cur_tr) ~= 1
        fprintf('syllable in incorrect trial #%d, skip it\n',cur_tr)
        continue
    end
    m1_trials = stable.m1_trials{cur_tr};
    m2_trials = stable.m2_trials{cur_tr};
    idx_st = find(m1_trials.f_no == frame_st)-15;
    idx_end = find(m1_trials.f_no == frame_en)+15;
    if idx_st <= 0
        fprintf('start frame procedes trial buffer in trial #%d, skip it\n',cur_tr)
        continue
    elseif idx_end > m1_trials.f_no(end)
        fprintf('end frame exceeds trial buffer in trial #%d, skip it\n',cur_tr)
        continue
    end
    m1_pos = table2array(m1_trials(idx_st:idx_end,{'neck_x','neck_y'}));
    m2_pos = table2array(m2_trials(idx_st:idx_end,{'neck_x','neck_y'}));
    inter_dist = vecnorm(m1_pos - m2_pos,2,2);
    cur_trials = eval([id '_trials']);
    Aspd = cur_trials.([id '_k2n_Aspd'])(idx_st:idx_end);
    dif_k2n_Aabs = m1_trials.dif_k2n_Aabs(idx_st:idx_end);
    AprchRatio = cur_trials.([id '_TwdOther_n_AprchRatio'])(idx_st:idx_end);
    TanRatio = cur_trials.([id '_TwdOther_n_TanRatio'])(idx_st:idx_end);
    nkt_Aspd = cur_trials.([id '_nkt_Aspeed'])(idx_st:idx_end);
    nkt_A = cur_trials.([id '_nkt_A'])(idx_st:idx_end);
    n_Spd = cur_trials.([id '_n_Spd'])(idx_st:idx_end);
    n_Acc = cur_trials.([id '_n_Acc'])(idx_st:idx_end);

    % % coords rotation - 1st approach
    % first rotate trial types to north/east configuration. then determine
    % whether animals choose the rotated north or rotated east. if rotated
    % east, flip the x/y coords so that the other lit zone is always on the
    % east. however, the left/right port chosen by a mouse is flipped. this
    % works best for sharp.
    theta = thetas(cur_trialtype);
    R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
    m1_pos_rot = (R * m1_pos')';
    m2_pos_rot = (R * m2_pos')';
    % mirror x/y coords so that animals go to the rotated north zone
    cur_north = nzone_rot(cur_trialtype);
    if cur_zone ~= cur_north
        m1_pos_rot = fliplr(m1_pos_rot);
        m2_pos_rot = fliplr(m2_pos_rot);
    end

    % % coords rotation - 2nd approach
    % % rotate based on the chosen reward zone of the focal animal. this
    % % preserves the left/right port choice of the animals, but the other
    % % lit zone can be in the east or west. works best for sync.
    % theta = thetas(cur_zone);
    % R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
    % m1_pos_rot = (R * m1_pos')';
    % m2_pos_rot = (R * m2_pos')';

    bouts.trial_type(n) = cur_trialtype;
    bouts.m1_pos_rot{n} = m1_pos_rot;
    bouts.m2_pos_rot{n} = m2_pos_rot;
    bouts.inter_dist{n} = inter_dist;
    bouts.Aspd{n} = Aspd;
    bouts.dif_k2n_Aabs{n} = dif_k2n_Aabs;
    bouts.AprchRatio{n} = AprchRatio;
    bouts.TanRatio{n} = TanRatio;
    bouts.nkt_Aspd{n} = nkt_Aspd;
    bouts.nkt_A{n} = nkt_A;
    bouts.n_Spd{n} = n_Spd;
    bouts.n_Acc{n} = n_Acc;
end