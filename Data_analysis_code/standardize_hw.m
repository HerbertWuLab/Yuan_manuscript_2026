function output = standardize_hw(input)
% scale 1d data in the 0-1 range
max_input = max(input);
min_input = min(input);
output = (input-min_input)/(max_input-min_input);
