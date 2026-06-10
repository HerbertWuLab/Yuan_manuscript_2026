function [T_start, T_end, counts] = get_syllable_info(data)
% Input: data - a column vector representing the syllable time series, with values 0 or 1.
% Output: T_start - start times of syllables
%         T_end - end times of syllables
%         counts - number of syllables

if all(data == 0) % Check if the entire data is zeros
    T_start = [];
    T_end = [];
    counts = 0;
    return;
end

starts = find(diff([0; data]) == 1); % Find positions where 0 changes to 1 (syllable start)
ends = find(diff([data; 0]) == -1);  % Find positions where 1 changes to 0 (syllable end)

counts = length(starts);
T_start = starts;
T_end = ends;
end
