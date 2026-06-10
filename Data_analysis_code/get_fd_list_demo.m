function fd_list = get_fd_list_demo(fd, phase)

% If the phase argument is not provided, list folders directly under fd
if nargin < 2 || isempty(phase)
    filelist = dir(fd);
else
    % If phase is 'learning' or 'freerun'
    if ismember(phase, {'learning','freerun'})
        % Look inside fd/phase
        filelist = dir([fd phase]);
    else
        % Otherwise look inside fd/phaseX
        filelist = dir([fd 'phase' phase]);
    end
end

% Select directories only
sel_dir = [filelist.isdir];

% Exclude unwanted folders
sel_data_fd = ~ismember({filelist.name}, {'.', '..', '.DS_Store', 'plots', 'registration'});

% Return the filtered folder list
fd_list = filelist(sel_dir & sel_data_fd);

end