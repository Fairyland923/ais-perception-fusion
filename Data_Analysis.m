%% Data_Analysis.m - 分析雷达与AIS的数据特性
clc; clear; close all;

% 1. 加载数据
fprintf('正在加载数据...\n');
load('AIS_tracks.mat', 'MMSI', 'Time', 'Lat', 'Lon');
load('radar_all.mat', 'UID', 'Time_radar', 'Lat_radar', 'Lon_radar');

%% === 分析 1: 采样时间间隔 (Sampling Interval) ===
% 我们需要知道两个点之间通常隔多久

% 计算雷达的时间间隔 (取前1000个UID做样本以节省时间)
u_UID = unique(UID);
radar_dt = [];
sample_size = min(1000, length(u_UID));

for i = 1:sample_size
    idx = strcmp(UID, u_UID{i});
    t = sort(Time_radar(idx));
    if length(t) > 1
        dt = seconds(diff(t)); % 计算差分，转为秒
        radar_dt = [radar_dt; dt]; 
    end
end

% 计算AIS的时间间隔 (取前1000个MMSI做样本)
u_MMSI = unique(MMSI);
ais_dt = [];
sample_size_ais = min(1000, length(u_MMSI));

for i = 1:sample_size_ais
    idx = strcmp(MMSI, u_MMSI{i});
    t = sort(Time(idx));
    if length(t) > 1
        dt = seconds(diff(t));
        ais_dt = [ais_dt; dt];
    end
end

% 绘图
figure('Name', '采样间隔分布');
subplot(2,1,1);
histogram(radar_dt(radar_dt < 60), 50); % 只看60秒内的分布
title('雷达采样间隔分布 (\Delta t)'); xlabel('秒'); ylabel('频次');
subtitle(['中位数: ' num2str(median(radar_dt)) 's']);

subplot(2,1,2);
histogram(ais_dt(ais_dt < 600), 50); % 只看10分钟内的分布
title('AIS采样间隔分布 (\Delta t)'); xlabel('秒'); ylabel('频次');
subtitle(['中位数: ' num2str(median(ais_dt)) 's']);

%% === 分析 2: 轨迹点数密度 (Points per Track) ===
% 这决定了“最小匹配点数”应该设为 5 还是 50

radar_counts = zeros(sample_size, 1);
for i = 1:sample_size
    radar_counts(i) = sum(strcmp(UID, u_UID{i}));
end

ais_counts = zeros(sample_size_ais, 1);
for i = 1:sample_size_ais
    ais_counts(i) = sum(strcmp(MMSI, u_MMSI{i}));
end

figure('Name', '轨迹包含点数分布');
subplot(2,1,1);
histogram(radar_counts, 30);
title('每条雷达轨迹的点数'); xlabel('点数');
subtitle(['平均点数: ' num2str(mean(radar_counts))]);

subplot(2,1,2);
histogram(ais_counts, 30);
title('每条AIS轨迹的点数'); xlabel('点数');
subtitle(['平均点数: ' num2str(mean(ais_counts))]);

%% === 分析 3: 输出建议 ===
fprintf('========== 数据特性统计报告 ==========\n');
fprintf('1. 雷达数据频率: 约 %.1f 秒/点\n', median(radar_dt));
fprintf('2. AIS 数据频率: 约 %.1f 秒/点\n', median(ais_dt));
ratio = median(ais_dt) / median(radar_dt);
fprintf('   -> AIS比雷达稀疏约 %.1f 倍。\n', ratio);
fprintf('3. 雷达轨迹平均长度: %.1f 个点\n', mean(radar_counts));
fprintf('4. AIS 轨迹平均长度: %.1f 个点\n', mean(ais_counts));
fprintf('======================================\n');