clc;
clear;
close all;

%% ========= 文件路径设置 =========
filename = 'C:\Users\fairyland\Desktop\感知+AIS轨迹融合\感知数据\request_log_20260110.sql';
fid = fopen(filename,'r');

%% ========= 初始化变量 =========
Nalloc = 3e6;  % 预分配内存大小
cnt = 0;       % 计数器

MMSI  = cell(Nalloc,1);   % 存储AIS MMSI
Lon   = zeros(Nalloc,1);  % 存储AIS经度
Lat   = zeros(Nalloc,1);  % 存储AIS纬度
TimeS = cell(Nalloc,1);   % 存储AIS时间字符串

%% ========= 读取并解析数据 =========
while ~feof(fid)
    line = fgetl(fid);
    % 仅处理以 'INSERT INTO' 开头的行
    if ~startsWith(line,'INSERT INTO')
        continue;
    end
    
    % 使用正则表达式提取 VALUES 后面的内容
    tokens = regexp(line, 'VALUES\s*\(([^;]+)\)', 'tokens');

    if isempty(tokens)
        continue;
    end
    
    for k = 1:numel(tokens)
        row = tokens{k}{1};
        c = strsplit(row, ',');

        % 提取字段（10:MMSI, 13:经度, 14:纬度, 20:时间）
        mmsi_str = cleanStr(c{10});
        lon_str  = cleanStr(c{13});
        lat_str  = cleanStr(c{14});
        tim_str  = cleanStr(c{20});
    
        lon = str2double(lon_str);
        lat = str2double(lat_str);
    
        % 数据有效性检查：跳过无效坐标
        if isnan(lon) || isnan(lat)
            continue;
        end
        if lon < -180 || lon > 180 || lat < -90 || lat > 90
            continue;
        end
    
        cnt = cnt + 1;
        MMSI{cnt}  = mmsi_str;
        Lon(cnt)   = lon;
        Lat(cnt)   = lat;
        TimeS{cnt} = tim_str;
    end
end
fclose(fid);

%% ========= 数据截断与转换 =========
MMSI  = MMSI(1:cnt);
Lon   = Lon(1:cnt);
Lat   = Lat(1:cnt);
TimeS = TimeS(1:cnt);
% 将时间字符串转换为 datetime 对象
Time  = datetime(TimeS,'InputFormat','yyyy-MM-dd HH:mm:ss');
clear TimeS % 清除不再需要的临时变量

%% ========= 保存结果 =========
fprintf('总有效轨迹点数：%d\n', cnt);
save('AIS_tracks.mat','MMSI','Lon','Lat','Time','-v7.3');
disp('AIS数据提取完成并已保存至 AIS_tracks.mat');

%% ========= 辅助函数：清洗字符串 =========
function s = cleanStr(x)
    s = strtrim(x);          % 去除首尾空格
    s = erase(s,'''');       % 去除单引号
    s = erase(s,';');        % 去除分号
end
