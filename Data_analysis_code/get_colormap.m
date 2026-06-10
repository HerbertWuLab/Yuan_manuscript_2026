function customColormap = get_colormap(role)
% generate custom color map by interpolating pre-defined points

% if strcmp(role,'leader')
%     % zone_colors = {'#e7d4e8';'#c2a5cf';'#9970ab';'#762a83'}; % leader
%     % zone_colors = {'#c2a5cf';'#9970ab';'#762a83';'#421749'}; % leader one shade darker
%     zone_colors = {'#c2a5cf';'#9970ab';'#762a83';'#531e5c'}; % leader one shade darker  
%     m_color = '#9970ab';
% elseif strcmp(role,'follower')
%     % zone_colors = {'#d9f0d3';'#a6dba0';'#5aae61';'#1b7837'}; % follower
%     zone_colors = {'#a6dba0';'#5aae61';'#1b7837';'#0f4d2b'}; % follower one shade darker
%     m_color = '#5aae61';
% end

switch role
    case 'leader' % '#e7d4e8';'#c2a5cf';'#9970ab';'#762a83';'#531e5c';'#311237'
        colors = [
            231, 212, 232;
            194, 165, 207; % #c2a5cf
            153, 112, 171;
            118, 42, 131;
            83, 30, 92;
        	49	18	55
            ] / 255;
    case 'follower' % '#d9f0d3';'#a6dba0';'#5aae61';'#1b7837';'#0f4d2b';'#092e19'
        colors = [
            217	240	211;
            166, 219, 160;
            90, 174, 97;
            27, 120, 55;
            15, 77, 43;
            9, 46, 25
            ]/255;
    case 'diverging'
        colors = [
            103,0,31
            178,24,43
            214,96,77
            244,165,130
            253,219,199
            247,247,247
            209,229,240
            146,197,222
            67,147,195
            33,102,172
            5,48,97]/255;
end

% Number of colors in the custom colormap
nColors = 100;

% Interpolate colors to create a 100-color colormap
customColormap = interp1(linspace(0, 1, size(colors, 1)), colors, linspace(0, 1, nColors));

% % Create an example plot
% figure;
% % [X, Y] = meshgrid(1:100, 1:100);
% Z = peaks(100); % Generate sample data for plotting
% imagesc(Z); % Display data as a color image
% colormap(customColormap); % Apply the custom colormap
% colorbar; % Show color scale
% title('Example Plot Using Custom 100-Color Colormap');