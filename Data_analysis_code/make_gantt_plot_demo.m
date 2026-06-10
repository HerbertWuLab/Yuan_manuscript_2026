function make_gantt_plot_demo(fd,syllable_table)
% m1_sync is same with m2_sync

for s = [1 9]

    % Extract relevant fields from the table
    stable = syllable_table.stable{s};
    coords_full = syllable_table.SLEAP_coords{s};
    syllable_status = table2array(syllable_table.syllabel{s}(:, 4:11));
    syllable_names = {'m1_sharp', 'm2_sharp', 'm1_track', 'm2_track', ...
                      'm1_sync', 'm2_sync', 'm1_join', 'm2_join'};

    % Annotate trials with syllables
    stable = get_syllables(stable, syllable_status, syllable_names, coords_full);

    % Compute stitched frame index based on trial intervals
    total_frames = size(syllable_status, 1);
    stitched_frames = zeros(total_frames, 1);
    stitched_number = 1;

    for i = 1:height(stable)
        led_init = stable.bf_SF(i);
        led_end = stable.led_end(i);

        if led_init > 0 && led_end <= total_frames
            stitched_frames(led_init:led_end) = stitched_number:(stitched_number + led_end - led_init);
            stitched_number = stitched_frames(led_end) + 1;
        else
            warning('Frame indices out of range for trial %d', i);
        end
    end

    % Create output folder
    session_name = syllable_table.session{s};

    plot_folder = fullfile(fd, 'plots');
    if ~exist(plot_folder, 'dir')
        mkdir(plot_folder);
    end

    % Check syllable names used in plot
    syllable_names = check_syllable_name(stable, syllable_names);

    % source data
    source_data = table();

    for syi = 1:numel(syllable_names)

        cur_status = syllable_status(:,syi) == 1;
        valid_idx = stitched_frames > 0;

        cur_status = cur_status & valid_idx;

        d = diff([false; cur_status; false]);
        start_idx = find(d == 1);
        end_idx = find(d == -1) - 1;

        n_ep = numel(start_idx);

        if n_ep > 0
            tmp = table();

            tmp.Session = repmat(string(session_name), n_ep, 1);
            tmp.SessionIndex = repmat(s, n_ep, 1);
            tmp.Syllable = repmat(string(syllable_names{syi}), n_ep, 1);
            tmp.SyllableIndex = repmat(syi, n_ep, 1);

            tmp.StartFrameOriginal = start_idx;
            tmp.EndFrameOriginal = end_idx;

            tmp.StartFrameStitched = stitched_frames(start_idx);
            tmp.EndFrameStitched = stitched_frames(end_idx);

            tmp.DurationFrames = tmp.EndFrameOriginal - tmp.StartFrameOriginal + 1;

            source_data = [source_data; tmp];
        end
    end

    assignin('base','source_data',source_data);

    % Generate and save syllable distribution plot
    output_pdf = fullfile(plot_folder, append(session_name, '_syllable_distribution.pdf'));
    plotSyllableDistribution(stitched_frames, syllable_status, syllable_names, output_pdf);

end