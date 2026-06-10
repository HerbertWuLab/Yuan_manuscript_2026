function ctable = recalc_leader_disp(ctable)
% normalize p_ledBy by sum
ctable.p_ledBy_sum = ctable.p_ledBy_m1 + ctable.p_ledBy_m2;
ctable.p_ledBy_m1_adj = ctable.p_ledBy_m1./ctable.p_ledBy_sum;
ctable.p_ledBy_m2_adj = ctable.p_ledBy_m2./ctable.p_ledBy_sum;
ctable.lead_dsp = abs(ctable.p_ledBy_m1_adj - ctable.p_ledBy_m2_adj);

% normalize p_initBy by sum
ctable.p_initBy_sum = ctable.p_initBy_m1 + ctable.p_initBy_m2;
ctable.p_initBy_m1_adj = ctable.p_initBy_m1./ctable.p_initBy_sum;
ctable.p_initBy_m2_adj = ctable.p_initBy_m2./ctable.p_initBy_sum;
ctable.init_dsp = abs(ctable.p_initBy_m1_adj - ctable.p_initBy_m2_adj);

% normalize 
p_ledBy_sum = ctable.p_ledBy_sLead + ctable.p_ledBy_sFoll;
ctable.p_ledBy_sLead = ctable.p_ledBy_sLead./p_ledBy_sum;
ctable.p_ledBy_sFoll = ctable.p_ledBy_sFoll./p_ledBy_sum;

p_initBy_sum = ctable.p_initBy_sInit + ctable.p_initBy_sResp;
ctable.p_initBy_sInit = ctable.p_initBy_sInit./p_initBy_sum;
ctable.p_initBy_sResp = ctable.p_initBy_sResp./p_initBy_sum;

%% add binomial test p-value
n_ses = height(ctable);
ctable.pval_lead = nan(n_ses,1);
for n = 1:n_ses
    n_ledBy_m1 = ctable.n_ledBy_m1(n);
    n_ledBy_m2 = ctable.n_ledBy_m2(n);
    n_sum = n_ledBy_m1 + n_ledBy_m2;
    n_small = min(n_ledBy_m1,n_ledBy_m2);
    pval_lead = 2 * binocdf(n_small,n_sum,0.5);
    ctable.pval_lead(n) = pval_lead;
end
