function [spatial_coherence, avg_neighbor_rate] = calc_spatial_coherence(firing_rate)
%%
    % Calculates spatial coherence using imfilter for efficiency
    % Input:
    %   firing_rate: n x n matrix of firing rates, may contain NaNs
    % Output:
    %   spatial_coherence: correlation between firing rate and local average
    
    % Define the convolution kernel for 8-neighborhood averaging
    kernel = [1 1 1; 1 0 1; 1 1 1];

    % Create a binary mask to identify NaNs
    nan_mask = isnan(firing_rate);

    % Replace NaNs temporarily with 0s for convolution calculation
    firing_rate(nan_mask) = 0;

    % Compute the sum of neighboring firing rates
    sum_neighbors = imfilter(firing_rate, kernel);

    % Compute the count of valid (non-NaN) neighbors
    count_neighbors = imfilter(double(~nan_mask), kernel);

    % Compute the local average firing rate, avoiding division by zero
    avg_neighbor_rate = sum_neighbors ./ count_neighbors;
    
    % Restore NaNs in the original positions
    avg_neighbor_rate(nan_mask) = NaN;

    % Extract valid values (non-NaN) for correlation calculation
    valid_idx = ~nan_mask & ~isnan(avg_neighbor_rate);

    if sum(valid_idx(:)) > 1
        spatial_coherence = corr(firing_rate(valid_idx), avg_neighbor_rate(valid_idx), 'rows', 'complete');
    else
        spatial_coherence = NaN; % Not enough data for correlation
    end

