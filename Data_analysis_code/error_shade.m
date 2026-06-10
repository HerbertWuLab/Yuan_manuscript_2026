function [p,f] = error_shade(x,y,error,color)
% Define upper and lower bounds for shading
sel_nonnan = ~isnan(y) & ~isnan(error);
x = x(sel_nonnan);
y = y(sel_nonnan);
error = error(sel_nonnan);

y_upper = y + error;
y_lower = y - error;

% Plot the main data line
% figure;
p = plot(x, y, 'LineWidth', 2,'Color',color); % Main plot line in blue
hold on;

% Create a patch for shaded error region
f = fill([x, fliplr(x)], [y_upper, fliplr(y_lower)],"",'FaceColor',color, ...
    'FaceAlpha', 0.2, 'EdgeColor', 'none'); % Shaded region in blue with transparency

% % Customize plot
% xlabel('X-axis');
% ylabel('Y-axis');
% title('Plot with Shaded Error Region');
% legend('Data', 'Error Region');
% hold off;
%%
% h1 = errorbarShade(x,y,error,"",...
%     0.3,{'FaceColor','#a6dba0','LineWidth',2,'LineStyle','-'});