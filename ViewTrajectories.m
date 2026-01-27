% clc;
% clear;
% close all;
% 
% %% 1. 加载匹配结果和原始数据
% fprintf('正在加载匹配结果和原始数据，请稍候...\n');
% if ~isfile('MatchResults.mat')
%     error('未找到匹配结果 MatchResults.mat，请先运行 RunBatchMatching.m');
% end
% load('MatchResults.mat', 'results');

if isempty(results)
    error('匹配结果为空！');
end

num_matches = length(results);
fprintf('加载完成！共有 %d 个匹配结果。\n', num_matches);

% 按需加载原始数据（为了绘图）
if ~exist('UID', 'var')
    load('radar_all.mat', 'UID', 'Lon_radar', 'Lat_radar', 'Time_radar');
end
if ~exist('MMSI', 'var')
    load('AIS_tracks.mat', 'MMSI', 'Lon', 'Lat', 'Time');
end

%% 2. 交互式查看
while true
    fprintf('---------------------------------------------------\n');
    fprintf('请输入要查看的结果编号 (1 - %d)，输入 0 或 q 退出: ', num_matches);
    user_input = input('', 's');
    
    if strcmp(user_input, '0') || strcmpi(user_input, 'q')
        fprintf('退出程序。\n');
        break;
    end
    
    idx = str2double(user_input);
    
    if isnan(idx) || idx < 1 || idx > num_matches
        fprintf('输入无效，请输入有效的数字编号！\n');
        continue;
    end
    
    % 获取选定结果的详细信息
    selected_res = results(idx);
    curr_uid = selected_res.UID;
    curr_mmsi = selected_res.BestMMSI;
    
    fprintf('正在绘制: 索引 %d | UID: %s <--> MMSI: %s (匹配距离: %.2f 米)\n', ...
        idx, curr_uid, curr_mmsi, selected_res.MinDist);
    
    % 3. 提取轨迹数据并绘图
    % 雷达数据
    r_idx = strcmp(UID, curr_uid);
    r_lon = Lon_radar(r_idx);
    r_lat = Lat_radar(r_idx);
    r_time = Time_radar(r_idx);
    [r_time, ord] = sort(r_time);
    r_lon = r_lon(ord);
    r_lat = r_lat(ord);
    
    % AIS数据
    a_idx = strcmp(MMSI, curr_mmsi);
    a_lon = Lon(a_idx);
    a_lat = Lat(a_idx);
    a_time = Time(a_idx);
    [a_time, ord] = sort(a_time);
    a_lon = a_lon(ord);
    a_lat = a_lat(ord);
    
    % 仅截取时间重叠部分稍微扩展一点以便观察
    % 计算两个时间序列的重叠区间
    t_start = max(min(r_time), min(a_time));
    t_end   = min(max(r_time), max(a_time));
    
    if t_end > t_start
        buffer = minutes(0); % 向两侧扩展 0 分钟 (可根据需要调整)
        v_start = t_start - buffer;
        v_end   = t_end + buffer;
        
        % 截取雷达数据
        r_mask = (r_time >= v_start) & (r_time <= v_end);
        r_lon = r_lon(r_mask);
        r_lat = r_lat(r_mask);
        % r_time = r_time(r_mask); % 如后续需要时间也可截取
        
        % 截取 AIS 数据
        a_mask = (a_time >= v_start) & (a_time <= v_end);
        a_lon = a_lon(a_mask);
        a_lat = a_lat(a_mask);
        % a_time = a_time(a_mask);
        
        fprintf('   [显示优化] 已截取时间重叠部分 (扩展 0 分钟): \n');
        fprintf('   显示范围: %s 至 %s\n', string(v_start), string(v_end));
    else
        fprintf('   [提示] 时间无重叠，显示全段数据。\n');
    end
    
    R = 6378137;
    title_str = sprintf('匹配结果 #%d\nUID: %s  |  MMSI: %s', idx, curr_uid, curr_mmsi);
    
    plot_trajectory_function(r_lon, r_lat, a_lon, a_lat, R, title_str);
end
