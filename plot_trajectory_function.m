function plot_trajectory_function(lon1, lat1, lon2, lat2, R, title_text)
    % plot_trajectory_function 绘制雷达和AIS的对比轨迹
    %
    % 输入参数:
    %   lon1, lat1 - 雷达轨迹的经纬度 (单位: 度)
    %   lon2, lat2 - AIS轨迹的经纬度 (单位: 度)
    %   R          - 地球半径 (单位: 米)
    %   title_text - 图形标题

    %% 坐标转换：经纬度 -> 局部平面坐标 (ENU近似)
    % 选择第一个雷达点作为参考原点 (0,0)
    lon0 = deg2rad(lon1(1)); 
    lat0 = deg2rad(lat1(1)); 

    % 转换雷达轨迹
    % x = R * cos(lat0) * (lon - lon0)
    % y = R * (lat - lat0)
    x1 = R * cos(lat0) .* (deg2rad(lon1) - lon0);
    y1 = R * (deg2rad(lat1) - lat0);
    
    % 转换AIS轨迹 (使用相同的参考点)
    x2 = R * cos(lat0) .* (deg2rad(lon2) - lon0);
    y2 = R * (deg2rad(lat2) - lat0);

    %% 绘制轨迹
    figure;
    % 绘制雷达轨迹 (蓝色实线)
    % plot(x1, y1, 'b.-', 'DisplayName', '雷达轨迹', 'LineWidth', 1.5, 'MarkerSize', 8);
    plot(x1, y1, '-', 'DisplayName', '雷达轨迹', 'LineWidth', 2);
    hold on;
    % 绘制AIS轨迹 (红色虚线)
    % plot(x2, y2, 'r.--', 'DisplayName', 'AIS轨迹', 'LineWidth', 1.5, 'MarkerSize', 8);
    plot(x2, y2, '-', 'DisplayName', 'AIS轨迹');
    
    % % 标注起点和终点
    % plot(x1(1), y1(1), 'bs', 'MarkerFaceColor', 'b', 'DisplayName', '雷达起点');
    % plot(x2(1), y2(1), 'rs', 'MarkerFaceColor', 'r', 'DisplayName', 'AIS起点');

    axis equal;
    grid on;
    xlabel('东向距离 (米)');
    ylabel('北向距离 (米)');
    title(title_text, 'Interpreter', 'none'); % none 防止下划线被解释为下标
    legend('show', 'Location', 'best');
    
    hold off;
end
