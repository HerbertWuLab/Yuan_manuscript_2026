function syllable_table = get_syllablebatch_info(syllable_table)
    % This function processes syllable data in the given table and computes
    % the start times, end times, and counts for each syllable.
    %
    % Input:
    %   - syllable_table: The syllable table to process (already loaded outside the function).
    %
    % Output:
    %   - syllable_table: The processed syllable table with added count and duration information.
    
    % Define the column names for counts
    count_column_names = {'m1_sharp', 'm2_sharp', 'm1_track', 'm2_track', 'sync', 'm1_join', 'm2_join'};

    % Loop over each session in the syllable table
    for s = 1:height(syllable_table)
        cur_syll = syllable_table.syllabel{s};  % Current syllable table for the session
        
        % Define the columns to process
        cols = [4:8, 10:11];
        num_cols = length(cols);
        
        % Initialize arrays to store start, end times, and counts
        T_start = cell(1, num_cols);
        T_end = cell(1, num_cols);
        counts = zeros(1, num_cols);
        
        % Loop over each column in 'cur_syll'
        for i = 1:num_cols
            data = cur_syll{:, cols(i)};  % Extract the column data from the current syllable table

            % Ensure the data is a numeric vector (you may need to cast if it's not already)
            data = double(data);  % Convert to double if necessary

            % Get the start, end, and counts for the current syllable
            [T_start{i}, T_end{i}, counts(i)] = get_syllable_info(data);  % Store results for each column

            % Use the correct column name from 'count_column_names' for field assignment
            field_name = count_column_names{i};

            % Store the counts in the field 'n_<field_name>'
            syllable_table.(['n_' field_name])(s) = counts(i);  

            % Calculate and store the duration in the field 'dur_<field_name>'
            if isempty(T_start{i}) || isempty(T_end{i})
                % If either T_start or T_end is empty, set the duration to NaN
                syllable_table.(['dur_' field_name]){s} = NaN;  
            else
                % Otherwise, calculate the duration
                syllable_table.(['dur_' field_name]){s} = T_end{i} - T_start{i};  
            end
        end
    end
end
