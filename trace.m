%% 主程序：查询UID和MMSI
% 加载数据（AIS和雷达数据）
% load('AIS_tracks.mat','MMSI','Lon','Lat','Time');
% load('radar_all.mat','UID','Lon_radar','Lat_radar','Time_radar');

% 1. 统计 UID 和 MMSI
unique_UID = unique(UID);
unique_MMSI = unique(MMSI);
fprintf('共有 %d 个 UID\n', numel(unique_UID));
fprintf('共有 %d 条船舶（MMSI）\n', numel(unique_MMSI));

% 2. 输入查询的 UID 和 MMSI
query_uid = input('请输入要查询的 UID: ', 's');  % 用户输入UID
query_mmsi = input('请输入要查询的 MMSI: ', 's');  % 用户输入MMSI

% 检查用户输入的 UID 和 MMSI 是否存在
if ~ismember(query_uid, unique_UID)
    error('输入的 UID 不存在！');
end

if ~ismember(query_mmsi, unique_MMSI)
    error('输入的 MMSI 不存在！');
end

% 3. 地球半径（米）
R = 6378137;

%% 查询 UID 和 MMSI 对应的数据
% 查询 UID 数据
idx_radar = strcmp(UID, query_uid);
lon_radar = Lon_radar(idx_radar);
lat_radar = Lat_radar(idx_radar);
time_radar = Time_radar(idx_radar);

% 按时间排序
[time_radar, ord_radar] = sort(time_radar);
lon_radar = lon_radar(ord_radar);
lat_radar = lat_radar(ord_radar);

% 查询 MMSI 数据
idx_ais = strcmp(MMSI, query_mmsi);
lon_ais = Lon(idx_ais);
lat_ais = Lat(idx_ais);
time_ais = Time(idx_ais);

% 按时间排序
[time_ais, ord_ais] = sort(time_ais);
lon_ais = lon_ais(ord_ais);
lat_ais = lat_ais(ord_ais);

% 绘制两个轨迹
plot_trajectory(lon_radar, lat_radar, lon_ais, lat_ais, R, ['Trajectory of UID ', query_uid, ' and MMSI ', query_mmsi]);

%% 公共部分：绘制轨迹
function plot_trajectory(lon1, lat1, lon2, lat2, R, title_text)
    % 经纬度 → 局部平面坐标
    lon0 = deg2rad(lon1(1));  % 选择第一个轨迹的第一个点作为参考点
    lat0 = deg2rad(lat1(1));  % 选择第一个轨迹的第一个点作为参考点

    % 转换为局部平面坐标（ENU）
    x1 = R * cos(lat0) .* (deg2rad(lon1) - lon0);
    y1 = R * (deg2rad(lat1) - lat0);
    x2 = R * cos(lat0) .* (deg2rad(lon2) - lon0);
    y2 = R * (deg2rad(lat2) - lat0);

    % 绘制轨迹
    figure;
    plot(x1, y1, '-', 'DisplayName', 'UID Trajectory', 'LineWidth', 2);
    hold on;
    plot(x2, y2, '-', 'DisplayName', 'MMSI Trajectory');
    axis equal;
    grid on;
    xlabel('East (m)');
    ylabel('North (m)');
    title(title_text);
    legend;
end
