function fig = plot_pos_time_cohort_demo(pos_table,params)
% plot position/trajectory of animals on the cohort level
% every line is the median of a session
%
% Outputs to base workspace:
%   source_data
%   stats_table

fd = params.fd; 
role = params.role;

hoy = char(datetime('now','Format','yyyyMMdd'));

clear p

fig = figure('Position',[300 300 400 400]);
hold on

switch role
    case 'both'
        pos_table_sel = pos_table;
        m_colors = [0.5490 0.3176 0.0392; 0.5 0.5 0.5];

    case 'leader'
        pos_table_sel = pos_table(strcmp(pos_table.role,'leader'),:);
        m_colors = [0.6000 0.4392 0.6706; 0.5 0.5 0.5];

    case 'follower'
        pos_table_sel = pos_table(strcmp(pos_table.role,'follower'),:);
        m_colors = [0.3529 0.6824 0.3804; 0.5 0.5 0.5]; 
end

uni_animals = unique(pos_table_sel.animal);
n_animals = length(uni_animals);

table_animal = table;
table_animal.animal = uni_animals;
table_animal.self_lead = cell(n_animals,1);
table_animal.other_lead = cell(n_animals,1);

source_data = table();

for a = 1:n_animals

    cur_animal = uni_animals{a};

    pos_table_animal = pos_table_sel(strcmp(pos_table_sel.animal,cur_animal),:);

    self_lead = mean(cat(3,pos_table_animal.self_lead{:}),3);
    other_lead = mean(cat(3,pos_table_animal.other_lead{:}),3);  

    table_animal.self_lead{a} = self_lead;
    table_animal.other_lead{a} = other_lead;

    n_time = size(self_lead,1);

    T_self = table( ...
        repmat({role},n_time,1), ...
        repmat({cur_animal},n_time,1), ...
        repmat({'self_lead'},n_time,1), ...
        (1:n_time)', ...
        self_lead(:,1), ...
        self_lead(:,2), ...
        'VariableNames', ...
        {'Role','Animal','Condition','Frame','X','Y'});

    T_other = table( ...
        repmat({role},n_time,1), ...
        repmat({cur_animal},n_time,1), ...
        repmat({'other_lead'},n_time,1), ...
        (1:n_time)', ...
        other_lead(:,1), ...
        other_lead(:,2), ...
        'VariableNames', ...
        {'Role','Animal','Condition','Frame','X','Y'});

    source_data = [source_data; T_self; T_other];

    p(1) = plot(self_lead(:,1),self_lead(:,2), ...
        'Color',[m_colors(1,:) 0.5], ...
        'LineWidth',2);

    p(2) = plot(other_lead(:,1),other_lead(:,2), ...
        'Color',[m_colors(2,:) 0.5], ...
        'LineWidth',2);

end

self_lead_cohort = cat(3,table_animal.self_lead{:});
other_lead_cohort = cat(3,table_animal.other_lead{:});

mean_self_x = squeeze(mean(self_lead_cohort(:,1,:),3,'omitnan'));
mean_self_y = squeeze(mean(self_lead_cohort(:,2,:),3,'omitnan'));
mean_other_x = squeeze(mean(other_lead_cohort(:,1,:),3,'omitnan'));
mean_other_y = squeeze(mean(other_lead_cohort(:,2,:),3,'omitnan'));

stats_table = table( ...
    {role}, ...
    n_animals, ...
    mean(mean_self_x,'omitnan'), ...
    mean(mean_self_y,'omitnan'), ...
    mean(mean_other_x,'omitnan'), ...
    mean(mean_other_y,'omitnan'), ...
    'VariableNames', ...
    {'Role','NAnimals', ...
    'MeanSelfLeadX','MeanSelfLeadY', ...
    'MeanOtherLeadX','MeanOtherLeadY'});

assignin('base','source_data',source_data);
assignin('base','stats_table',stats_table);

fprintf('\n========================================\n')
fprintf('Arrival trajectory | %s\n', role)
fprintf('========================================\n')
fprintf('N animals = %d\n', n_animals)
fprintf('Source data contains animal-level trajectory points.\n')
fprintf('No inferential statistical test is performed in this function.\n')
disp(stats_table)

% plot(0,22.5,'Marker','+','MarkerSize',30,'Color','k','MarkerEdgeColor','k')

% self_lead_avg = mean(self_lead_cohort,3);
% other_lead_avg = mean(other_lead_cohort,3);
% p(1) = plot(self_lead_avg(:,1),self_lead_avg(:,2),'Color',[m_colors(1,:) 1],'LineWidth',3);
% p(2) = plot(other_lead_avg(:,1),other_lead_avg(:,2),'Color',[m_colors(2,:) 1],'LineWidth',3);
% scatter(0,22.5,100,'k','filled'); % center of north reward zone

m_legend = {'self lead','other lead'};

legend(p, m_legend,'Location','southeast','FontSize',28);
legend boxoff

caption = ['Arrival trajectory ' role ' (N=' num2str(n_animals) ' animals)'];
title(caption);

xlabel('X (cm)')
ylabel('Y (cm)')

% axis padded
axis equal

xlim([-5 5])
ylim([13 23])
yticks([10:5:20])

set(gca,'FontSize',28,'TickDir','out');

figname = [fd '/plots/' hoy 'p_arrival_trajectory_' role];

% set(fig,'PaperUnits','normalized','PaperPosition', [0 0 1 1]);

print(fig,figname,'-dpdf');

fprintf('\nSaved to base workspace:\n')
fprintf('source_data\n')
fprintf('stats_table\n')

end