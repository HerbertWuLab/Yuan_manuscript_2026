function syllable_names = check_syllable_name(stable, syllable_names)
    % Check which leader is more frequent in the stable data
    if mean(stable.leader == 1) > mean(stable.leader == 2)
        leader = 'm1';
        follower = 'm2';
    else
        leader = 'm2';
        follower = 'm1';
    end

    % Iterate through each syllable name
    for i = 1:length(syllable_names)
        syllable_name = syllable_names{i}; % Extract the current syllable name
        sel_name = syllable_name(4:end); % Extract the part of the name after the first 3 characters

        % Check if the syllable name contains the leader or follower
        if contains(syllable_name, leader)
            syllable_name = [sel_name, '_', 'Lead']; % Append leader prefix
        else
            syllable_name = [sel_name, '_', 'Foll']; % Append follower prefix
        end

        syllable_names{i} = syllable_name; % Update the syllable name in the list
    end
end