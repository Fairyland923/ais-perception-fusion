clc;
clear;
close all;

%% ========= 文件路径设置 =========
filename = 'C:\Users\fairyland\Desktop\感知+AIS轨迹融合\感知数据\mq_radar_record_20260110.sql';
fid = fopen(filename,'r');

%% ========= 初始化变量 =========
Nalloc = 3e6;  % 预分配内存大小
cnt = 0;       % 计数器

UID         = cell(Nalloc,1);   % 存储雷达UID
Lon_radar   = zeros(Nalloc,1);  % 存储雷达经度
Lat_radar   = zeros(Nalloc,1);  % 存储雷达纬度
TimeS_radar = cell(Nalloc,1);   % 存储雷达时间字符串

%% ========= 读取并解析数据 =========
while ~feof(fid)
    line = fgetl(fid);
    % 仅处理以 'INSERT INTO' 开头的行
    if ~startsWith(line,'INSERT INTO')
        continue;
    end
    
    % 查找数据段的起始和结束位置
    p1 = strfind(line,'(');
    p2 = strfind(line,')');

    % 遍历每一行中的所有记录
    for k = 1:numel(p1)
        cnt = cnt + 1;
        row = line(p1(k)+1 : p2(k)-1);
        c = strsplit(row,',');

        % 提取字段（2:UID, 3:经度, 4:纬度, 7:时间）
        uid_str = cleanStr(c{2});
        lon_str = cleanStr(c{3});
        lat_str = cleanStr(c{4});
        tim_str = cleanStr(c{7});

        UID{cnt}         = uid_str;
        Lon_radar(cnt)   = str2double(lon_str);
        Lat_radar(cnt)   = str2double(lat_str);
        TimeS_radar{cnt} = tim_str;
    end
end
fclose(fid);

%% ========= 数据截断与转换 =========
UID         = UID(1:cnt);
Lon_radar   = Lon_radar(1:cnt);
Lat_radar   = Lat_radar(1:cnt);
TimeS_radar = TimeS_radar(1:cnt);
% 将时间字符串转换为 datetime 对象
Time_radar  = datetime(TimeS_radar,'InputFormat','yyyy-MM-dd HH:mm:ss');
clear TimeS_radar % 清除不再需要的临时变量

%% ========= 保存结果 =========
fprintf('总记录数：%d\n', cnt);
save('radar_all.mat','UID','Lon_radar','Lat_radar','Time_radar','-v7.3');
disp('雷达数据提取完成并已保存至 radar_all.mat');

%% ========= 辅助函数：清洗字符串 =========
function s = cleanStr(x)
    s = strtrim(x);          % 去除首尾空格
    s = erase(s,'''');       % 去除单引号
    s = erase(s,')');        % 去除右括号
    s = erase(s,';');        % 去除分号
end
