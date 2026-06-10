function plotSyllableDistribution(stitched_frames, syllable_status, syllable_names, output_pdf)
    % Add today's date as a prefix to the PDF filename
    current_date = datestr(now, 'yyyymmdd');

    % Extract folder path and original filename
    output_folder = fileparts(output_pdf);
    [~, original_filename, ext] = fileparts(output_pdf);
    % Ensure the output folder exists; create it if necessary
    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end
    
    % Generate full session PDF filename
    full_pdf = fullfile(output_folder, [current_date, '_', original_filename, '_full', ext]);

    % Define custom colors
    lead_colors = [hex2rgb('#531e5c');  % Dark purple
                   hex2rgb('#9970ab');  % Medium purple
                   hex2rgb('#e7d4e8')]; % Light purple

    foll_colors = [hex2rgb('#0f4d2b');  % Dark green
                   hex2rgb('#5aae61');  % Medium green
                   hex2rgb('#d9f0d3')]; % Light green

    sync_color = hex2rgb('#cb7831'); % Orange

    % Define syllable types and their order
    syllable_types = {'sharp', 'track', 'join'};

    % Split and sort syllable names
    split_syllables = cellfun(@(x) split(x, '_'), syllable_names, 'UniformOutput', false);
    roles = cellfun(@(x) x{2}, split_syllables, 'UniformOutput', false);
    types = cellfun(@(x) x{1}, split_syllables, 'UniformOutput', false);
    
    [~, role_order] = ismember(roles, {'Lead', 'Foll'});
    [~, type_order] = ismember(types, syllable_types);
    [~, sorted_idx] = sortrows([role_order(:), type_order(:)]);
    
    syllable_names = syllable_names(sorted_idx);
    syllable_status = syllable_status(:, sorted_idx);

    % Get sync mask: combine all sync status into one column
    sync_indices = contains(syllable_names, 'sync');
    sync_combined = any(syllable_status(:, sync_indices) > 0, 2);

    % Filter non-sync syllables
    non_sync_indices = ~sync_indices;
    syllable_names_nonsync = syllable_names(non_sync_indices);
    syllable_status_nonsync = syllable_status(:, non_sync_indices);

    % Plot function
    function plotSyllables(xlim_range, filename)
        figure; hold on;
        vertical_offset = 0;
        offset_increment = 1;

        % Plot non-sync syllables
        for i = 1:length(syllable_names_nonsync)
            syllable_parts = split(syllable_names_nonsync{i}, '_');
            syllable_type = syllable_parts{1};
            prefix = syllable_parts{2};

            type_index = find(strcmp(syllable_types, syllable_type));
            if isempty(type_index)
                error('Unknown syllable type: %s', syllable_type);
            end

            if strcmp(prefix, 'Lead')
                color = lead_colors(type_index, :);
            else
                color = foll_colors(type_index, :);
            end

            valid_indices = (stitched_frames >= xlim_range(1)) & ...
                            (stitched_frames <= xlim_range(2)) & ...
                            (syllable_status_nonsync(:, i) > 0);
            x = stitched_frames(valid_indices);

            for j = 1:length(x)
                plot([x(j), x(j)], [vertical_offset, vertical_offset + 0.9], ...
                     'Color', color, 'LineWidth', 1.5);
            end

            text(xlim_range(2) + 15, vertical_offset + 0.4, syllable_names_nonsync{i}, ...
                 'Color', 'k', 'VerticalAlignment', 'middle', 'Interpreter', 'none');
            vertical_offset = vertical_offset + offset_increment;
        end

        % Plot combined sync syllable (once)
        valid_indices = (stitched_frames >= xlim_range(1)) & ...
                        (stitched_frames <= xlim_range(2)) & ...
                        sync_combined;
        x = stitched_frames(valid_indices);

        for j = 1:length(x)
            plot([x(j), x(j)], [vertical_offset, vertical_offset + 0.9], ...
                 'Color', sync_color, 'LineWidth', 1.5);
        end

        text(xlim_range(2) + 15, vertical_offset + 0.4, 'sync', ...
             'Color', 'k', 'VerticalAlignment', 'middle', 'Interpreter', 'none');

        % Plot formatting
        title('Syllable Distribution');
        xlim(xlim_range);
        xticks = get(gca, 'XTick');
        set(gca, 'XTickLabel', xticks / 1e3, 'TickDir', 'out');
        xlabel('Stitched Frames (×10³)');
        ax = gca;
        ax.XAxis.Exponent = 0;
        ylim([0, vertical_offset + 1]);
        set(gca, 'YTick', []);
        set(gca, 'YColor', 'none');
        grid off;
        hold off;

        set(gcf, 'Position', [100, 100, 600, 200]);
        set(gcf, 'Renderer', 'painters');
        print(gcf, filename, '-dpdf', '-vector');
        disp(['Saved vector PDF: ', filename]);
        close(gcf);
    end

    % Plot the full session
    plotSyllables([min(stitched_frames), max(stitched_frames)], full_pdf);
end

% Helper function
function rgb = hex2rgb(hex)
    hex = strrep(hex, '#', '');
    rgb = sscanf(hex, '%2x%2x%2x', [1, 3]) / 255;
end
