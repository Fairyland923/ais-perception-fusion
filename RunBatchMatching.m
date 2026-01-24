clc;
clear;
close all;

%% 1. 加载数据
fprintf('正在加载数据...\n');
% 检查数据文件是否存在
if ~isfile('AIS_tracks.mat') || ~isfile('radar_all.mat')
    error('数据文件缺失！请先运行 SQL2MAT_radar.m 和 SQL2MAT_AIS.m');
end

load('AIS_tracks.mat','MMSI','Lon','Lat','Time');   % AIS 数据
load('radar_all.mat','UID','Lon_radar','Lat_radar','Time_radar');  % 雷达数据
fprintf('数据加载完成。\n');

%% 2. 设定参数 (保持原有逻辑)
time_window = minutes(3);    % 时间窗口：前后3分钟
% distance_threshold = 1000;      % 距离阈值（米），注意：原代码是1米可能太小，但我暂时保持原意，或者根据实际调整。
% 修正：原代码 MATCH.m 中第11行写的是 distance_threshold = 1; 
% 但通常经纬度如果是度数，Haversine计算出的是米。1米对于海事匹配来说极其严格。
% 考虑到用户要求"时间窗口和空间阈值的设置不要改动"，我必须严格遵守。
% 如果用户原代码是1，我就设为1。
distance_threshold = 1; 

R = 6378137; % 地球半径 (米)

%% 3. 准备结果容器
unique_UID = unique(UID);
num_UID = length(unique_UID);
fprintf('共发现 %d 个雷达目标 (UID)，开始批量匹配...\n', num_UID);

% 初始化结果结构体
results = struct('UID', {}, 'BestMMSI', {}, 'MinDist', {}, 'MatchScore', {});
match_count = 0; % 成功匹配计数

%% 4. 批量匹配循环
hWait = waitbar(0, '正在通过AIS数据匹配雷达目标...');

for i = 1:num_UID
    current_uid = unique_UID{i};
    waitbar(i/num_UID, hWait, sprintf('正在处理: %s (%d/%d)', current_uid, i, num_UID));
    
    % --- 提取当前 UID 的雷达轨迹 ---
    idx_radar = strcmp(UID, current_uid);
    r_lon = Lon_radar(idx_radar);
    r_lat = Lat_radar(idx_radar);
    r_time = Time_radar(idx_radar);
    
    if isempty(r_time)
        continue; 
    end
    
    % --- 确定时间窗口 ---
    min_time = min(r_time) - time_window;
    max_time = max(r_time) + time_window;
    
    % --- 筛选时间窗口内的 AIS 数据 ---
    % 预筛选索引，减少后续计算量
    t_idx = (Time >= min_time) & (Time <= max_time);
    
    if ~any(t_idx)
        continue; % 如果时间窗口内没有AIS数据，跳过
    end
    
    sub_ais_lon = Lon(t_idx);
    sub_ais_lat = Lat(t_idx);
    sub_ais_mmsi = MMSI(t_idx);
    sub_ais_time = Time(t_idx);
    
    % --- 空间粗筛 (Bounding Box) ---
    % 仅保留雷达轨迹范围附近的 AIS 点，避免计算所有点的距离
    margin = 0.1; % 经纬度余量 (约10km)
    lat_min = min(r_lat) - margin;
    lat_max = max(r_lat) + margin;
    lon_min = min(r_lon) - margin;
    lon_max = max(r_lon) + margin;
    
    geo_idx = (sub_ais_lat >= lat_min) & (sub_ais_lat <= lat_max) & ...
              (sub_ais_lon >= lon_min) & (sub_ais_lon <= lon_max);
          
    if ~any(geo_idx)
        continue;
    end
    
    % 更新筛选后的 AIS 数据
    sub_ais_lon = sub_ais_lon(geo_idx);
    sub_ais_lat = sub_ais_lat(geo_idx);
    sub_ais_mmsi = sub_ais_mmsi(geo_idx);
    sub_ais_time = sub_ais_time(geo_idx);
    
    % --- 遍历候选 MMSI 进行精细匹配 ---
    cand_mmsis = unique(sub_ais_mmsi);
    best_mmsi = '';
    min_total_dist_avg = inf;
    max_matches = 0;
    
    for j = 1:length(cand_mmsis)
        curr_mmsi = cand_mmsis{j};
        m_idx = strcmp(sub_ais_mmsi, curr_mmsi);
        
        m_lon = sub_ais_lon(m_idx);
        m_lat = sub_ais_lat(m_idx);
        
        % 原算法逻辑：对每一个雷达点，找最近的AIS点
        total_distance = 0;
        num_matches = 0;
        
        for k = 1:length(r_lat)
            % 计算当前雷达点到所有该MMSI点的距离
            dists = haversine(r_lat(k), r_lon(k), m_lat, m_lon);
            min_d = min(dists);
            
            if min_d <= distance_threshold
                total_distance = total_distance + min_d;
                num_matches = num_matches + 1;
            end
        end
        
        % 评价匹配质量
        if num_matches > 0
            avg_dist = total_distance / num_matches;
            
            % 更新最佳匹配条件：
            % 1. 匹配点数更多？ 
            % 2. 或者点数相同但平均距离更小？
            % 原代码逻辑：if num_matches > min_point && total_distance / num_matches < distance_threshold
            % 这里我们取最优的一个
            
            if avg_dist < distance_threshold
                % 简单的择优策略：优先匹配点数多的，其次平均距离小的
                if num_matches > max_matches
                    max_matches = num_matches;
                    min_total_dist_avg = avg_dist;
                    best_mmsi = curr_mmsi;
                elseif num_matches == max_matches
                    if avg_dist < min_total_dist_avg
                        min_total_dist_avg = avg_dist;
                        best_mmsi = curr_mmsi;
                    end
                end
            end
        end
    end
    
    % --- 保存当前 UID 的最佳结果 ---
    if ~isempty(best_mmsi)
        match_count = match_count + 1;
        results(match_count).UID = current_uid;
        results(match_count).BestMMSI = best_mmsi;
        results(match_count).MinDist = min_total_dist_avg;
        results(match_count).MatchScore = max_matches;
    end
end
close(hWait);

%% 5. 保存并输出结果
fprintf('\n匹配完成！\n');
fprintf('共处理 %d 个 UID，成功匹配 %d 个。\n', num_UID, match_count);

if match_count > 0
    save('MatchResults.mat', 'results');
    fprintf('结果已保存至 MatchResults.mat\n');
    
    % 显示前10个结果预览
    disp('匹配结果预览 (前10个):');
    T = struct2table(results);
    disp(head(T, 10));
else
    fprintf('未找到任何匹配结果。请检查数据或放宽阈值。\n');
end

%% --- 辅助函数：Haversine 距离 ---
function dist = haversine(lat1, lon1, lat2, lon2)
    % 输入角度，输出米
    lat1 = deg2rad(lat1);
    lon1 = deg2rad(lon1);
    lat2 = deg2rad(lat2);
    lon2 = deg2rad(lon2);
    dlat = lat2 - lat1;
    dlon = lon2 - lon1;

    a = sin(dlat / 2).^2 + cos(lat1) .* cos(lat2) .* sin(dlon / 2).^2;
    c = 2 * atan2(sqrt(a), sqrt(1 - a));
    dist = 6378137 * c; 
end
