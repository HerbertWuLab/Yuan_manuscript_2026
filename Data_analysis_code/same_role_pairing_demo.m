function fig = same_role_pairing_demo(fd,note_table)
for p = 1:height(note_table)
    ptable = note_table.ptable{p};
    s_range = ptable.cno == 0 & ptable.cp_rate >= 0.8 & strcmpi(ptable.phase, 'phase4a');
    ptable = ptable(s_range, :); % well-trained
    if strcmp(note_table.pair{p}, 'TY001TY003')
        if height(ptable) >= 3
            ptable = ptable(2:3, :);  
        else
            ptable = [];  
        end
    end
    n_ses=length(ptable.stable);
    stable=table();
    for s=1:n_ses
        sel_stable=ptable.stable{s};
        stable=[stable;sel_stable];
    end
    p_ledBy_m1=sum(stable.leader==1)/(sum(stable.leader==1)+sum(stable.leader==2));
    p_ledBy_m2=sum(stable.leader==2)/(sum(stable.leader==1)+sum(stable.leader==2));
    if p_ledBy_m1>p_ledBy_m2
        p_ledBy_sLead=p_ledBy_m1;
        p_ledBy_sFoll=p_ledBy_m2;
    else
        p_ledBy_sLead=p_ledBy_m2;
        p_ledBy_sFoll=p_ledBy_m1;
    end
    total_trials=sum(stable.leader==1)+sum(stable.leader==2);
    %statistics
    n1 = sum(stable.leader == 1);
    n2 = sum(stable.leader == 2);
    total = n1 + n2;
    P_val = 2 * binocdf(min(n1, n2), total, 0.5);
    P_val = min(P_val, 1);
    note_table.P_val(p) = P_val;
    note_table.total_trials(p)=total_trials;
    note_table.p_ledBy_m1(p) = p_ledBy_m1;
    note_table.p_ledBy_m2(p) = p_ledBy_m2;
    note_table.p_ledBy_sLead(p) = p_ledBy_sLead;
    note_table.p_ledBy_sFoll(p) = p_ledBy_sFoll;
end
%% plotting
groups = {
    'T2321T2322', 'T2322T2323', 'T2323T2324', 'T2321T2324';
    'TY001TY002', 'TY003TY004', 'TY001TY003', 'TY002TY004';
    'YC159YC160', 'YC161YC162', 'YC159YC162', 'YC161YC160'
};
n_group = size(groups, 1);
fig = figure('Position', [100 100 400 400]);
ax = axes('Position', [0.15 0.15 0.7 0.7]); 
hold on;
axis([0 1 0 1]);
grid off;
box on;
xlabel('p\_ledBy\_m1');
ylabel('p\_ledBy\_m2');
set(gca, 'TickDir', 'out', 'XTick', 0:0.5:1, 'YTick', 0:0.5:1);
colors = {[153, 112, 171]/255, [90, 174, 97]/255}; 
plot([0 1], [1 0], '--r', 'LineWidth', 1.5); 
plot([0.5 0.5], [0 1], ':k', 'LineWidth', 1); 
plot([0 1], [0.5 0.5], ':k', 'LineWidth', 1); 
for g = 1:n_group
    current_pairs = groups(g, :);
    s_range = false(height(note_table), 1);
    
    for i = 1:length(current_pairs)
        s_range = s_range | contains(note_table.pair, current_pairs{i});
    end
    data = note_table(s_range, :);
    original_Lead = data(strcmp(data.role_type, 'original_pair'), :).p_ledBy_sLead;
    original_Foll = data(strcmp(data.role_type, 'original_pair'), :).p_ledBy_sFoll;
    p_LL = [data(strcmp(data.role_type, 'LL_pairing'), :).p_ledBy_sLead; data(strcmp(data.role_type, 'LL_pairing'), :).p_ledBy_sFoll];
    p_FF = [data(strcmp(data.role_type, 'FF_pairing'), :).p_ledBy_sLead; data(strcmp(data.role_type, 'FF_pairing'), :).p_ledBy_sFoll];
    start_points = [original_Lead(1), original_Lead(2); original_Foll(1), original_Foll(2)];
    end_points = [p_LL(1), p_LL(2); p_FF(1), p_FF(2)];
    data2norm = @(x, y) [...
        (x - ax.XLim(1)) / (ax.XLim(2) - ax.XLim(1)) * ax.Position(3) + ax.Position(1), ...
        (y - ax.YLim(1)) / (ax.YLim(2) - ax.YLim(1)) * ax.Position(4) + ax.Position(2) ...
    ];
    for i = 1:2
        start_norm = data2norm(start_points(i,1), start_points(i,2));
        end_norm = data2norm(end_points(i,1), end_points(i,2));
        
        annotation('arrow', [start_norm(1), end_norm(1)], [start_norm(2), end_norm(2)], ...
            'Color', colors{i}, 'LineWidth', 2, 'HeadWidth', 10, 'HeadLength', 10);
        
        plot(start_points(i,1), start_points(i,2), 'o', 'Color', colors{i}, ...
            'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'w');
    end
end
h_arrow(1) = plot(nan, nan, '-', 'Color', colors{1}, 'LineWidth', 2, 'DisplayName', 'swapped Leader');
h_arrow(2) = plot(nan, nan, '-', 'Color', colors{2}, 'LineWidth', 2, 'DisplayName', 'swapped Follower');
h_circle(1) = plot(nan, nan, 'o', 'Color', colors{1},'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'w', 'DisplayName', 'original Leader');
h_circle(2) = plot(nan, nan, 'o', 'Color', colors{2},'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'w', 'DisplayName', 'original Follower');
legend([h_arrow, h_circle], 'Location', 'best');
hoy = char(datetime('now','Format','yyyyMMdd'));
figname = [fd 'plots/' hoy '_LLFF_pairing'];
print(fig,figname,'-dpdf');