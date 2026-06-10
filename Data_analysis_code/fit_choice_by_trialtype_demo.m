function [beta_by_tt, pairs_by_tt] = fit_choice_by_trialtype_demo(fd, ctable)
% Compute beta coefficients (GLM) per trial type (1-4) per role (lead/foll).
% Returns:
%   beta_by_tt  - 4x1 cell, each entry: n_pairs x 2 x 4
%                 dim2: role (1=lead, 2=foll predicting choice)
%                 dim3: coeff (lead_angle_rz_dif, lead_dis_dif, foll_angle_rz_dif, foll_dis_dif)
%   pairs_by_tt - 4x1 cell, each entry: n_pairs x 1 cell of pair names

ctable = load([fd 'Data\ctable_light_combined.mat']).ctable;

beta_by_tt  = cell(4,1);
pairs_by_tt = cell(4,1);

%% compute beta coefficients for each trial type
for tt = 1:4

    coords_north  = [0 22.5];
    coords_east   = [22.5 0];
    uni_pairs     = unique(ctable.pair);
    n_uni_pairs   = length(uni_pairs);
    threshold     = 0.6;
    dis_threshold = 10;
    mst           = [];
    ltable        = extract_ltable(ctable);

    for p = 1:n_uni_pairs
        cur_pair = uni_pairs{p};
        btable   = ctable(strcmp(cur_pair, ctable.pair), :);

        if strcmp(cur_pair,'YC013YC014')
            btable = btable(str2double(btable.date) <= 20230804, :);
        elseif strcmp(cur_pair,'YC015YC016')
            btable = btable(str2double(btable.date) <= 20230831, :);
        elseif strcmp(cur_pair,'YC017YC018')
            btable = btable(str2double(btable.date) <= 20231017, :);
        end

        cur_ltable = ltable(strcmp(cur_pair, ltable.pair), :);
        if isempty(cur_ltable.true_lead)
            continue
        end

        crit_day1 = cur_ltable.date(end-2);
        sel_date  = str2double(btable.date) >= str2double(crit_day1);
        s_range   = btable.cno==0 & btable.cp_rate>=0.795 & strcmpi(btable.phase,'phase4a') ...
                    & (btable.p_ledBy_m1+btable.p_ledBy_m2)>=0.8 & sel_date;
        btable    = btable(s_range, :);
        n_ses     = height(btable);

        n_ledBy_m1 = sum(strcmp(btable.sLead,'m1'));
        n_ledBy_m2 = sum(strcmp(btable.sLead,'m2'));
        if n_ledBy_m1 >= n_ses * threshold
            cLead = 1; cFoll = 2;
        elseif n_ledBy_m2 >= n_ses * threshold
            cLead = 2; cFoll = 1;
        else
            fprintf(['Leading %d vs %d in %d sessions, less than prop=%.2f of well-trained, phase4a,' ...
                ' control sessions in ' cur_pair '. Check data!\n'], n_ledBy_m1, n_ledBy_m2, n_ses, threshold)
            continue
        end

        stable = vertcat(btable.stable{:});

        sel_co_mm      = stable.correct==1 | stable.mismatch==1;
        init_dis_sel   = stable.init_dis < dis_threshold;
        sel_trial_dur  = stable.dur_f < 150;
        sel_trial_type = stable.trial_type == tt;
        sel_trials2    = ~isnan(stable.m1_choose_n) & ~isnan(stable.m2_choose_n);
        sel_trials3    = ~isnan(stable.initiator);
        stable_sel     = stable(sel_co_mm & sel_trial_dur & sel_trial_type & init_dis_sel & sel_trials2 & sel_trials3, :);

        for m = 1:2
            cur_animal = ['m' num2str(m)];
            stable_sel.([cur_animal '_angle_rz_dif']) = ...
                (stable_sel.([cur_animal '_angle_ez_rot']) - stable_sel.([cur_animal '_angle_nz_rot'])) / 180;
            x = stable_sel.([cur_animal '_x_rot']);
            y = stable_sel.([cur_animal '_y_rot']);
            d2east  = sqrt((x - coords_east(1)).^2  + (y - coords_east(2)).^2);
            d2north = sqrt((x - coords_north(1)).^2 + (y - coords_north(2)).^2);
            stable_sel.([cur_animal '_dis_dif']) = d2east - d2north;
        end

        leader   = ['m' num2str(cLead)];
        follower = ['m' num2str(cFoll)];
        stable_sel.lead_angle_rz_dif = stable_sel.([leader   '_angle_rz_dif']);
        stable_sel.lead_dis_dif      = stable_sel.([leader   '_dis_dif']);
        stable_sel.lead_choose_n     = stable_sel.([leader   '_choose_n']);
        stable_sel.foll_angle_rz_dif = stable_sel.([follower '_angle_rz_dif']);
        stable_sel.foll_dis_dif      = stable_sel.([follower '_dis_dif']);
        stable_sel.foll_choose_n     = stable_sel.([follower '_choose_n']);
        stable_sel.pair              = repmat({cur_pair}, height(stable_sel), 1);

        mst = [mst; stable_sel];
    end

    if isempty(mst)
        fprintf('No trials for trial_type=%d, skipping.\n', tt);
        continue
    end

    mst.lead_angle_rz_dif = standardize_hw(mst.lead_angle_rz_dif);
    mst.lead_dis_dif      = standardize_hw(mst.lead_dis_dif);
    mst.foll_angle_rz_dif = standardize_hw(mst.foll_angle_rz_dif);
    mst.foll_dis_dif      = standardize_hw(mst.foll_dis_dif);

    % get coefficients of every animal
    uni_pairs     = unique(mst.pair);
    n_uni_pairs   = length(uni_pairs);
    roles         = {'lead','foll'};
    beta_estimate = nan(n_uni_pairs, 2, 4);
    n_trials_pair = nan(n_uni_pairs, 1);

    for r = 1:2
        cur_role      = roles{r};
        which_choose_n = [cur_role '_choose_n'];
        modelspec     = [which_choose_n ' ~ lead_angle_rz_dif + lead_dis_dif + foll_angle_rz_dif + foll_dis_dif'];
        for p = 1:n_uni_pairs
            cur_pair      = uni_pairs{p};
            cur_mst_pair  = mst(strcmp(cur_pair, mst.pair), :);
            n_trials_pair(p) = height(cur_mst_pair);
            try
                mdl = fitglm(cur_mst_pair, modelspec, Distribution="Binomial");
                beta_estimate(p, r, :) = mdl.Coefficients.Estimate(2:5);
            catch ME
                fprintf('fitglm failed: %s role=%s tt=%d: %s\n', cur_pair, cur_role, tt, ME.message);
            end
        end
    end

    beta_by_tt{tt}  = beta_estimate;
    pairs_by_tt{tt} = uni_pairs;

end

%% plot each coefficient across trial types (8 figures: 2 roles x 4 coefficients)
all_pairs_tt = unique(vertcat(pairs_by_tt{:}));
n_all_pairs  = length(all_pairs_tt);
roles        = {'lead','foll'};
role_labels  = {'Predicting leader choice','Predicting follower choice'};
coeff_labels = {'Lead \Delta\theta','Lead \Deltad','Foll \Delta\theta','Foll \Deltad'};
coeff_tags   = {'lead_hd','lead_pos','foll_hd','foll_pos'};
hoy          = char(datetime('now','Format','yyyyMMdd'));

source_data = table();

for r = 1:2
    for c = 1:4
        data = nan(n_all_pairs, 4);
        for tt = 1:4
            cur_pairs = pairs_by_tt{tt};
            cur_beta  = beta_by_tt{tt};
            for pi = 1:n_all_pairs
                idx = find(strcmp(all_pairs_tt{pi}, cur_pairs));
                if ~isempty(idx)
                    data(pi, tt) = cur_beta(idx, r, c);
                end
            end
        end

        tmp = table();
        tmp.Pair = strings(n_all_pairs*4,1);
        tmp.Role = strings(n_all_pairs*4,1);
        tmp.Coefficient = strings(n_all_pairs*4,1);
        tmp.TrialType = nan(n_all_pairs*4,1);
        tmp.BetaEstimate = nan(n_all_pairs*4,1);

        row = 1;
        for pi = 1:n_all_pairs
            for tt = 1:4
                tmp.Pair(row) = string(all_pairs_tt{pi});
                tmp.Role(row) = string(roles{r});
                tmp.Coefficient(row) = string(coeff_tags{c});
                tmp.TrialType(row) = tt;
                tmp.BetaEstimate(row) = data(pi, tt);
                row = row + 1;
            end
        end

        source_data = [source_data; tmp];

        fig = figure('Position',[200 200 300 300]);
        hold on;
        for pi = 1:n_all_pairs
            plot(1:4, data(pi,:), '-o', 'LineWidth',1, 'Color',0.65*[1 1 1], ...
                'MarkerSize',5, 'MarkerFaceColor',0.65*[1 1 1]);
        end
        mean_data = nanmean(data, 1);
        sem_data  = nanstd(data, 0, 1) ./ sqrt(sum(~isnan(data), 1));
        errorbar(1:4, mean_data, sem_data, 'k-o', 'LineWidth',2, ...
            'MarkerSize',7, 'MarkerFaceColor','k');

        xlim([0.5 4.5])
        xticks(1:4)
        xticklabels({'tt1','tt2','tt3','tt4'})
        xlabel('Trial type')
        ylabel('Beta estimate')
        title([role_labels{r} newline coeff_labels{c}], 'FontSize',14)
        box off
        ax = gca;
        set(ax, 'FontSize',14, 'TickDir','out');

        figname = [fd 'plots/' hoy '_coeff_by_trialtype_' roles{r} '_' coeff_tags{c}];
        print(fig, figname, '-dpdf');
    end
end

assignin('base','source_data',source_data);

%% statistics: repeated measures ANOVA for trial type effect on each coefficient
% Within-subject factor: trial type (4 levels), subject: pair.
% Reports F, p, eta-squared (effect size), and BF01 (Bayes Factor for H0).
% BF01 > 3: moderate evidence for no effect; > 10: strong evidence.
fprintf('\n=== Trial type effect on beta coefficients (repeated measures ANOVA) ===\n');
fprintf('%-28s  df_num  df_den     F       p      eta2    BF01\n', 'Role_Coeff');

for r = 1:2
    for c = 1:4
        % assemble n_pairs x 4 data matrix
        data = nan(n_all_pairs, 4);
        for tt = 1:4
            cur_pairs = pairs_by_tt{tt};
            cur_beta  = beta_by_tt{tt};
            for pi = 1:n_all_pairs
                idx = find(strcmp(all_pairs_tt{pi}, cur_pairs));
                if ~isempty(idx)
                    data(pi, tt) = cur_beta(idx, r, c);
                end
            end
        end

        % keep only pairs with complete data across all 4 trial types
        data_cc = data(all(~isnan(data), 2), :);
        n_sub   = size(data_cc, 1);
        if n_sub < 3
            fprintf('%-28s  skipped (n=%d complete pairs)\n', [roles{r} '_' coeff_tags{c}], n_sub);
            continue
        end

        % repeated measures ANOVA
        T  = array2table(data_cc, 'VariableNames', {'tt1','tt2','tt3','tt4'});
        rm = fitrm(T, 'tt1-tt4 ~ 1', 'WithinDesign', (1:4)');
        ra = ranova(rm);
        F_val  = ra.F(1);
        df_num = ra.DF(1);
        df_den = ra.DF(2);
        p_val  = ra.pValue(1);

        % eta-squared (proportion of variance explained by trial type)
        eta2 = ra.SumSq(1) / (ra.SumSq(1) + ra.SumSq(2));

        % BF01 approximation (Masson 2011): converts F to Bayes Factor for H0
        BF01 = exp(-0.5 * n_sub * log(1 + F_val * df_num / (df_den)) + ...
                    0.5 * df_num * log(1 + F_val * df_num / (df_den)));

        fprintf('%-28s    %2d      %3d     %6.3f  %6.4f  %6.4f  %6.2f\n', ...
            [roles{r} '_' coeff_tags{c}], df_num, df_den, F_val, p_val, eta2, BF01);
    end
end
end