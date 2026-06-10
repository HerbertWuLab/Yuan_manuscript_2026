function [p,z] = ztest(x1,n1,x2,n2)
% Inputs
% x1 = 50;  % number of successes in group 1
% n1 = 200; % sample size for group 1
% 
% x2 = 30;  % number of successes in group 2
% n2 = 200; % sample size for group 2

% Proportions
p1 = x1 / n1;
p2 = x2 / n2;

% Pooled proportion
p_pool = (x1 + x2) / (n1 + n2);

% Standard error
SE = sqrt(p_pool * (1 - p_pool) * (1/n1 + 1/n2));

% z statistic
z = (p1 - p2) / SE;

% Two-tailed p-value
p = 2 * (1 - normcdf(abs(z)));

% Output
fprintf('Z = %.4f\n', z);
fprintf('p-value = %.4f\n', p);
