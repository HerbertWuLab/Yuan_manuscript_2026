function stable = get_syllables(stable, syllable_status, syllable_names, coords_full)
% get_syllables: Updates the stable table with syllable frames and corresponding coords.
% Each syllable frame will store a table with the frame number and coordinates of all mice.
%
% Parameters:
%   stable            - Table containing trial information with columns 'bf_SF' and 'bf_EF'
%   syllable_status   - 2D array, each row represents a frame, each column represents syllable status (0 or 1)
%   syllable_names    - Cell array containing syllable names
%   coords_full       - 4D array, dimensions: [frame_num, node_num, dim, mouse_num]
% 
% Updates the 'stable' table with syllable frames and coords for each trial, and returns the updated stable table.

% Initialize new column in stable table for syllable information
stable.syllable_info = cell(height(stable), 1);  % Combined column for syllable frames and coords
stable.syllable_names = cell(height(stable), 1);  % Column for syllable names
coords = coords_full;

% Loop through each trial
for trialIdx = 1:height(stable)
    % Get the start and end frames for the current trial
    startFrame = stable.bf_SF(trialIdx);
    endFrame = stable.bf_EF(trialIdx);

    % Initialize storage for syllable frames and coords during the trial
    syllableNames = {};
    syllableInfo = {};

    % Loop through the frames within the trial's frame range
    for frameIdx = startFrame:endFrame
        if frameIdx > 1 && frameIdx <= size(syllable_status, 1)
            % Check for syllable start (0 to 1 transition in syllable_status)
            for syllableIdx = 1:size(syllable_status, 2)
                if syllable_status(frameIdx, syllableIdx) == 1 && syllable_status(frameIdx-1, syllableIdx) == 0
                    % Store syllable name for the detected syllable
                    syllableNames{end+1} = syllable_names{syllableIdx};  % Store syllable name

                    % Collect frames for this syllable where syllable_status == 1
                    syllableFrames = find(syllable_status(startFrame:endFrame, syllableIdx) == 1) + startFrame - 1;

                    % Extract coords for the syllable frames
                    coordsForSyllable = squeeze(coords(syllableFrames, :, :, :));  % Extract coords for all mice

                    % Create a table for the syllable with frame numbers and coordinates for all frames
                    syllableTable = table(syllableFrames, coordsForSyllable(:, 1), coordsForSyllable(:, 2), ...
                                          coordsForSyllable(:, 3), coordsForSyllable(:, 4), ...
                                          coordsForSyllable(:, 5), coordsForSyllable(:, 6), ...
                                          'VariableNames', {'frame_number', 'nose_x', 'nose_y', 'neck_x', 'neck_y', 'torso_x', 'torso_y'});

                    syllableInfo{end+1} = syllableTable;  % Store the table in syllableInfo
                end
            end
        end
    end

    % If no syllables were detected, set the entry to 'none' and empty arrays/cells
    if isempty(syllableNames)
        stable.syllable_names{trialIdx} = 'none';
        stable.syllable_info{trialIdx} = 'none';
    else
        % Update the stable table for the current trial with detected syllables
        stable.syllable_names{trialIdx} = syllableNames;
        stable.syllable_info{trialIdx} = syllableInfo;
    end
end

% Merge 'm1_sync' and 'm2_sync' into 'sync' in syllable_names
for trialIdx = 1:height(stable)
    syllableNames = stable.syllable_names{trialIdx};
    if iscell(syllableNames) && numel(syllableNames) == 2 && all(ismember({'m1_sync', 'm2_sync'}, syllableNames))
        stable.syllable_names{trialIdx} = {'sync'};  % Merge m1_sync and m2_sync into sync
    end
end

% Clean up syllable_names to ensure only the first entry is kept if it contains multiple cells
for i = 1:height(stable)
    if iscell(stable.syllable_names{i}) && numel(stable.syllable_names{i}) > 1
        % Extract the first value if it is a 1x2 cell
        stable.syllable_names{i} = stable.syllable_names{i}{1};
    end
end

% Return the updated stable table
end
