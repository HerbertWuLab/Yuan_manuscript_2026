function syllable_table = get_proportion_syllable(syllable_table)
   
    count_column_names = {'m1_sharp', 'm2_sharp', 'm1_track', 'm2_track', 'sync', 'm1_join', 'm2_join'};
   % Initialize cell arrays to store the names
    num_name = cell(1, length(count_column_names));
    dur_name = cell(1, length(count_column_names));

    for i = 1:length(count_column_names)
        % Create field names by prepending 'n_' for counts and 'dur_' for durations
        num_name{i} = ['n_' count_column_names{i}];
        dur_name{i} = ['dur_' count_column_names{i}];
    end

    % Loop over each session in the syllable table
    for s = 1:height(syllable_table)
        % Initialize arrays to store the counts and durations for the current session
        values = zeros(1, length(num_name));  % Initialize an array to store the counts for this row
        durations = zeros(1, length(dur_name));  % Initialize an array to store the durations for this row
        leader=syllable_table.leader{s};
        
        for i = 1:length(num_name)
            % Access the count value for the current field
            current_count = syllable_table.(num_name{i})(s);  
            % Access the duration value for the current field (stored as a cell array)
            current_duration = syllable_table.(dur_name{i})(s);  

            % Sum the count directly (assuming it's numeric)
            values(i) = sum(current_count, 'omitnan');  % Ignore NaN values

            % Ensure duration is extracted from the cell and summed properly
            if iscell(current_duration) && ~isempty(current_duration{1})
                durations(i) = sum(current_duration{1}, 'omitnan');  % Ignore NaNs
            else
                durations(i) = 0;  % Assign 0 if empty or not a cell
            end
        end
        
        % Calculate the total sum of counts and durations, ignoring NaN values
        total_count_sum = sum(values, 'omitnan');
        total_duration_sum = sum(durations, 'omitnan');
        
        % Store the summed duration in the field 'sum_<field_name>'
        for i = 1:length(dur_name)
            syllable_table.(['sum_' dur_name{i}])(s) = durations(i);
        end
        
        % Avoid division by zero for proportions
        if total_count_sum > 0
            count_proportions = values / total_count_sum;  % Calculate proportions for counts
        else
            count_proportions = zeros(1, length(num_name));  % Set to zero if no counts
        end
        
        if total_duration_sum > 0
            duration_proportions = durations / total_duration_sum;  % Calculate proportions for durations
        else
            duration_proportions = zeros(1, length(dur_name));  % Set to zero if no durations
        end
        
        % Store the proportions for counts in new fields
        for i = 1:length(num_name)
            syllable_table.(['proportion_' num_name{i}])(s) = count_proportions(i);
            if strcmp(num_name{i}, 'n_sync')
                continue;
            end

            if contains(num_name{i}, leader)
                syllable_table.(['proportion_n_' num_name{i}(6:end) '_Lead'])(s) = syllable_table.(['proportion_' num_name{i}])(s);
            else
                syllable_table.(['proportion_n_' num_name{i}(6:end) '_Foll'])(s) = syllable_table.(['proportion_' num_name{i}])(s);
            end
        end
        
        % Store the proportions for durations in new fields
        for i = 1:length(dur_name)
            syllable_table.(['proportion_' dur_name{i}])(s) = duration_proportions(i);
            if strcmp(dur_name{i}, 'dur_sync')
                continue;
            end

            if contains(dur_name{i}, leader)
                syllable_table.(['proportion_dur_' dur_name{i}(8:end) '_Lead'])(s) = syllable_table.(['proportion_' dur_name{i}])(s);
            else
                syllable_table.(['proportion_dur_' dur_name{i}(8:end) '_Foll'])(s) = syllable_table.(['proportion_' dur_name{i}])(s);
            end
        end
    end
end
