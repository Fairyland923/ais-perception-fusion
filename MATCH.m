% clc;
% clear;
% close all;
% 
% %% 1. 加载数据
% load('AIS_tracks.mat','MMSI','Lon','Lat','Time');   % AIS 数据
% load('radar_all.mat','UID','Lon_radar','Lat_radar','Time_radar');  % 雷达数据

%% 2. 设定时间和空间窗口
time_window = minutes(3);  % 时间窗口：10分钟内认为是同一时刻
distance_threshold = 1;  % 定义空间距离阈值（米）

%% 3. 统计 UID 和初始化匹配结果
unique_UID = unique(UID);

%% 4. 输入查询的 UID
query_uid = input('请输入要查询的 UID: ', 's');  % 用户输入UID

% 检查用户输入的 UID 是否存在
if ~ismember(query_uid, unique_UID)
    error('输入的 UID 不存在！');
end

%% 5. 查询特定 UID 对应的雷达数据，并开始匹配过程
% 获取当前 UID 对应的雷达数据点
idx_radar = strcmp(UID, query_uid);  % 找到所有该 UID 对应的雷达数据
if sum(idx_radar) == 0
    error('未找到对应的雷达数据！');
end

radar_lon = Lon_radar(idx_radar);    % 雷达经度
radar_lat = Lat_radar(idx_radar);    % 雷达纬度
radar_time = Time_radar(idx_radar);  % 雷达时间
min_time_radar = min(radar_time);
max_time_radar = max(radar_time);

% 设定时间窗口范围（扩展 5 分钟）
start_time_window = min_time_radar - time_window;  % 时间窗口的起始时间
end_time_window = max_time_radar + time_window;   % 时间窗口的结束时间
time_window_idx = (Time >= start_time_window) & (Time <= end_time_window);  % 在时间窗口内的 AIS 数据

% 获取对应时间窗口内的AIS数据
ais_lon = Lon(time_window_idx);  % AIS 经度
ais_lat = Lat(time_window_idx);  % AIS 纬度
ais_mmsi = MMSI(time_window_idx);  % AIS MMSI
ais_time = Time(time_window_idx);  % AIS 时间

%% 6. 开始匹配特定 UID 对应的 MMSI
unique_mmsi = unique(ais_mmsi);  % 找到所有独立的 MMSI
min_point = 0;
for j = 1:length(unique_mmsi)
    
    % 获取当前MMSI对应的AIS数据
    idx_mmsi = strcmp(ais_mmsi, unique_mmsi(j));  % 找到当前MMSI对应的所有AIS数据
    mmsi_lon = ais_lon(idx_mmsi);  % 当前MMSI的AIS经度
    mmsi_lat = ais_lat(idx_mmsi);  % 当前MMSI的AIS纬度
    mmsi_time = ais_time(idx_mmsi);  % 当前MMSI的AIS时间

    % 计算雷达轨迹和当前MMSI的轨迹之间的Haversine距离
    total_distance = 0;  % 累积总距离
    num_matches = 0;     % 匹配点数

    for k = 1:length(radar_lat)
        distance = haversine(radar_lat(k), radar_lon(k), mmsi_lat, mmsi_lon);  % 计算雷达点和所有AIS点的距离
        [min_dist, ~] = min(distance);  % 找到最近的AIS点

        % 如果最小距离小于阈值，认为匹配成功
        if min_dist <= distance_threshold
            total_distance = total_distance + min_dist;  % 累加总距离
            num_matches = num_matches + 1;  % 增加匹配点数
        end
    end

    %% 7. 判断匹配度，基于总距离来判断是否匹配
    if num_matches > min_point && total_distance / num_matches < distance_threshold
        Best_MMSI = unique_mmsi(j);  % 存储当前匹配的MMSI
        min_point = num_matches;
    end
end

%% 8. 输出匹配结果
if ~isempty(Best_MMSI)
    disp(['匹配的 MMSI 为: ', Best_MMSI{1}]);
else
    warning(' 没有找到匹配的MMSI！');
end




%% Haversine 距离函数
function dist = haversine(lat1, lon1, lat2, lon2)
    % 将角度转换为弧度
    lat1 = deg2rad(lat1);
    lon1 = deg2rad(lon1);
    lat2 = deg2rad(lat2);
    lon2 = deg2rad(lon2);
    dlat = lat2 - lat1;  % lat2和lat1的差
    dlon = lon2 - lon1;  % lon2和lon1的差

    % Haversine 距离公式
    a = sin(dlat / 2).^2 + cos(lat1) .* cos(lat2) .* sin(dlon / 2).^2;
    c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    % 计算距离（单位：米）
    dist = 6378137 * c;  % 地球半径（单位：米）
end

