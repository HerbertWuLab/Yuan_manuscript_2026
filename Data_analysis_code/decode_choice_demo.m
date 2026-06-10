function decode_choice_demo(fd)

dc_table = load([fd 'Data/dc_table_choice.mat']).dc_table;

params.fd = '/Users/herbert/Wulab Dropbox/Lab/Yuan/imaging_analysis/';
params.role = 'both';
params.Ninput = 100;
params.alignBy = 'TrialEnd'; % TrialStart, m1Arrival, m2Arrival, TrialEnd
params.whose_choice = 'self';

% trim dc_table
for s = 1:height(dc_table)
    cor_data = dc_table.cor_data{s};
    cor_sim = dc_table.cor_sim{s};

    dc_table.cor_data{s} = cor_data(1:41);
    dc_table.cor_sim{s} = cor_sim(:,1:41);
end

params.t_array_binned = -60:3:60;

%% ===== source data only =====
source_data = table();

for s = 1:height(dc_table)

    cor_data = dc_table.cor_data{s};
    cor_sim = dc_table.cor_sim{s};

    n_time = length(cor_data);
    n_sim = size(cor_sim,1);

    % data decoding curve
    T_data = table( ...
        repmat(s,n_time,1), ...
        repmat({'Data'},n_time,1), ...
        params.t_array_binned(:), ...
        cor_data(:), ...
        nan(n_time,1), ...
        'VariableNames', ...
        {'SessionIndex','Type','Time','DecodingAccuracy','ShuffleIndex'});

    % shuffled/simulated decoding curves
    T_sim = table( ...
        repmat(s,n_sim*n_time,1), ...
        repmat({'Shuffle'},n_sim*n_time,1), ...
        repmat(params.t_array_binned(:),n_sim,1), ...
        cor_sim(:), ...
        repelem((1:n_sim)',n_time), ...
        'VariableNames', ...
        {'SessionIndex','Type','Time','DecodingAccuracy','ShuffleIndex'});

    source_data = [source_data; T_data; T_sim];

end

assignin('base','source_data',source_data);

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')

plt_choice_decoding_v2(dc_table, params)

end