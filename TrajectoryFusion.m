% TrajectoryFusion.m
% 混合轨迹融合脚本：处理匹配后的雷达与AIS数据
% 功能包含：统一时间轴、轨迹插值与采样、加权融合，以及可视化。

% clc;
% clear;
% close all;
% 
% %% 1. 加载数据
% fprintf('=== 初始化：正在加载数据 ===\n');
% if ~isfile('AIS_tracks.mat') || ~isfile('radar_all.mat') || ~isfile('MatchResults.mat')
%     error('数据文件缺失！请先运行相关解析及匹配（TestMatch.m）脚本确保数据正确生成。');
% end
% 
% load('AIS_tracks.mat', 'MMSI', 'Lon', 'Lat', 'Time');     % AIS数据
% load('radar_all.mat', 'UID', 'Lon_radar', 'Lat_radar', 'Time_radar');    % 雷达数据
% load('MatchResults.mat', 'results');                      % 匹配结果数据

fprintf('数据加载完成。共有 %d 对匹配轨迹待融合。\n', length(results));

%% 2. 融合参数设置
resample_dt = seconds(1); % 统一的固定采样频率（例如1秒一帧）

% ================= [融合算法参数] =================
% 这里我们使用简单的加权平均法融合轨迹坐标（可以扩展为卡尔曼滤波等高级算法）
% 考虑到AIS的全球低频高置信度和雷达的局部高频特点：
weight_radar = 0.5;
weight_ais = 0.5;
% =================================================

% ================= [可视化参数] =================
% 为了避免过多轨迹导致图表混乱，可以设置为只画部分指定的轨迹
num_plot = 10; % 设为正整数则随机选择绘制，设为0或大于总数则画全部
plot_indices = []; % 也可以直接在这里手动指定索引，如 [1, 5, 20]
% =================================================

% 预分配一个结构体保存融合后的结果
fused_trajectories = struct('UID', {}, 'MMSI', {}, 'Time', {}, ...
    'Fused_Lon', {}, 'Fused_Lat', {}, ...
    'Radar_Lon', {}, 'Radar_Lat', {}, ...
    'AIS_Lon', {}, 'AIS_Lat', {});

%% 3. 提取匹配轨迹并进行插值融合

% 生成需要画图的索引
if isempty(plot_indices)
    if num_plot > 0 && num_plot < length(results)
        plot_indices = randperm(length(results), num_plot); % 随机选择 num_plot 个
    else
        plot_indices = 1:length(results); % 画出所有轨迹
    end
end

% 每对轨迹单独作图，这里只保留绘图索引计数
color_idx = 1;

hWait = waitbar(0, '正在进行轨迹同步与融合...');

for i = 1:length(results)
    uidStr = results(i).UID;
    mmsiStr = results(i).BestMMSI;
    
    waitbar(i/length(results), hWait, sprintf('正在融合第 %d/%d 对：UID %s 與 MMSI %s', i, length(results), uidStr, mmsiStr));
    
    % --- 提取当前匹配对的雷达数据 ---
    idx_radar = strcmp(UID, uidStr);
    r_lon = Lon_radar(idx_radar);
    r_lat = Lat_radar(idx_radar);
    r_time = Time_radar(idx_radar);
    
    % --- 提取当前匹配对的AIS数据 ---
    idx_ais = strcmp(MMSI, mmsiStr);
    a_lon = Lon(idx_ais);
    a_lat = Lat(idx_ais);
    a_time = Time(idx_ais);
    
    % --- 清洗数据：去除重复的时间点，以防插值(interp1)报错 ---
    [r_time, unique_idx_r] = unique(r_time);
    r_lon = r_lon(unique_idx_r);
    r_lat = r_lat(unique_idx_r);
    
    [a_time, unique_idx_a] = unique(a_time);
    a_lon = a_lon(unique_idx_a);
    a_lat = a_lat(unique_idx_a);
    
    % 需要至少2个点才能进行插值
    if length(r_time) < 2 || length(a_time) < 2
        fprintf('  > 警告: UID: %s 或 MMSI: %s 数据点不足，跳过融合。\n', uidStr, mmsiStr);
        continue;
    end
    
    % --- 确定时间重叠区间 (求交集) ---
    start_time = max(min(r_time), min(a_time));
    end_time = min(max(r_time), max(a_time));
    
    if start_time >= end_time
        fprintf('  > 警告: UID: %s 与 MMSI: %s 无重合时间段，跳过。\n', uidStr, mmsiStr);
        continue;
    end
    
    % --- 步骤 1: 建立全局固定的采样频率 (统一时间轴) ---
    sync_time = (start_time:resample_dt:end_time)';
    
    if isempty(sync_time)
        continue;
    end
    
    % --- 步骤 2: 插值与采样 ---
    % 将两个数据源的时间对齐到同一时刻 (sync_time)
    % pchip (保形三次矩阵插值): 防止出现平滑样条带来的过冲现象，较适合真实物体的运动轨迹
    
    % 为了兼容某些旧版本MATLAB，显式转换为 datenum 进行插值 (数值型支持度更好)
    num_sync = datenum(sync_time);
    num_r_time = datenum(r_time);
    num_a_time = datenum(a_time);
    
    r_lon_interp = interp1(num_r_time, r_lon, num_sync, 'pchip');
    r_lat_interp = interp1(num_r_time, r_lat, num_sync, 'pchip');
    
    a_lon_interp = interp1(num_a_time, a_lon, num_sync, 'pchip');
    a_lat_interp = interp1(num_a_time, a_lat, num_sync, 'pchip');
    
    % --- 步骤 3: 轨迹融合 ---
    % 当前使用加权平均算法（可扩展为复杂的基于各自协方差矩阵的卡尔曼融合）
    fused_lon = weight_radar * r_lon_interp + weight_ais * a_lon_interp;
    fused_lat = weight_radar * r_lat_interp + weight_ais * a_lat_interp;
    
    % --- 保存当前的融合结果 ---
    fused_trajectories(end+1).UID = uidStr;
    fused_trajectories(end).MMSI = mmsiStr;
    fused_trajectories(end).Time = sync_time;
    fused_trajectories(end).Fused_Lon = fused_lon;
    fused_trajectories(end).Fused_Lat = fused_lat;
    fused_trajectories(end).Radar_Lon = r_lon_interp;
    fused_trajectories(end).Radar_Lat = r_lat_interp;
    fused_trajectories(end).AIS_Lon = a_lon_interp;
    fused_trajectories(end).AIS_Lat = a_lat_interp;
    
    % --- 步骤 4: 可视化 ---
    if ismember(i, plot_indices)
        figure('Name', sprintf('轨迹融合可视化 - UID: %s', uidStr), ...
               'Color', 'w', 'Position', [100+color_idx*20, 100+color_idx*20, 800, 600]);
        hold on; grid on;
        xlabel('经度 (Longitude)');
        ylabel('纬度 (Latitude)');
        title(sprintf('轨迹融合展示 (UID: %s | MMSI: %s)', uidStr, mmsiStr), 'Interpreter', 'none');
        
        % 仅提取重合时间段内的部分进行显示
        idx_r_overlap = (r_time >= start_time) & (r_time <= end_time);
        idx_a_overlap = (a_time >= start_time) & (a_time <= end_time);
        
        plot_r_lon = r_lon(idx_r_overlap);
        plot_r_lat = r_lat(idx_r_overlap);
        plot_a_lon = a_lon(idx_a_overlap);
        plot_a_lat = a_lat(idx_a_overlap);
        
        % 为了区分，雷达原始轨迹用蓝色，AIS用绿色，融合后用醒目的橙红加粗
        c_radar = [0, 0.4470, 0.7410];
        c_ais   = [0.4660, 0.6740, 0.1880];
        c_fused = [0.8500, 0.3250, 0.0980];
        
        % 去掉丑陋的空心圆和方块，改用更干净的小圆点配合虚线/点划线表示采样点频率和走势
        hR = plot(plot_r_lon, plot_r_lat, '--', 'Color', c_radar, 'LineWidth', 1, 'Marker', '.', 'MarkerSize', 8);
        hA = plot(plot_a_lon, plot_a_lat, '-.', 'Color', c_ais, 'LineWidth', 1, 'Marker', '.', 'MarkerSize', 8); 
        
        % 绘制融合后的结果
        hF = plot(fused_lon, fused_lat, '-', 'Color', c_fused, 'LineWidth', 1.5);
        
        % 标志本段融合轨迹的起点和终点
        hStart = plot(fused_lon(1), fused_lat(1), '^', 'Color', 'g', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
        hEnd = plot(fused_lon(end), fused_lat(end), 'v', 'Color', 'r', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
        
        legend([hR, hA, hF, hStart, hEnd], ...
               {'原始雷达轨迹(重叠段)', '原始AIS轨迹(重叠段)', '时空对齐后融合轨迹', '起点', '终点'}, ...
               'Location', 'best');
               
        color_idx = color_idx + 1;
    end
end
close(hWait);

fprintf('\n=== 融合完成 ===\n');
fprintf('共计成功处理并融合 %d 条匹配轨迹。\n', length(fused_trajectories));

%% 4. 保存融合结果
save('FusedTrajectories.mat', 'fused_trajectories');
fprintf('融合后的轨迹数据（结构体）已保存至 FusedTrajectories.mat\n');

% 根据需要，也可以将轨迹点合并成表(table)输出
% 可视化图表也可以被保存
% saveas(gcf, 'FusionVisualization.png');
