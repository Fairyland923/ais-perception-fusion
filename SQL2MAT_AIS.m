clc;
clear;
close all;

%% ========= 文件路径 =========
filename = 'C:\Users\fairyland\Desktop\感知+AIS轨迹融合\感知数据\request_log_20260110.sql';
fid = fopen(filename,'r');

%% 
Nalloc = 3e6;
cnt = 0;

MMSI = cell(Nalloc,1);
Lon  = zeros(Nalloc,1);
Lat  = zeros(Nalloc,1);
TimeS = cell(Nalloc,1);

while ~feof(fid)
    line = fgetl(fid);
    if ~startsWith(line,'INSERT INTO')
        continue;
    end
    tokens = regexp(line, 'VALUES\s*\(([^;]+)\)', 'tokens');

    if isempty(tokens)
        continue;
    end
    
    for k = 1:numel(tokens)
        row = tokens{k}{1};
        c = strsplit(row, ',');

        mmsi_str = cleanStr(c{10});
        lon_str  = cleanStr(c{13});
        lat_str  = cleanStr(c{14});
        tim_str  = cleanStr(c{20});
    
        lon = str2double(lon_str);
        lat = str2double(lat_str);
    
        if isnan(lon) || isnan(lat)
            continue;
        end
        if lon < -180 || lon > 180 || lat < -90 || lat > 90
            continue;
        end
    
        cnt = cnt + 1;
        MMSI{cnt} = mmsi_str;
        Lon(cnt)  = lon;
        Lat(cnt)  = lat;
        TimeS{cnt} = tim_str;
    end

end
fclose(fid);
MMSI = MMSI(1:cnt);
Lon  = Lon(1:cnt);
Lat  = Lat(1:cnt);
TimeS = TimeS(1:cnt);
Time = datetime(TimeS,'InputFormat','yyyy-MM-dd HH:mm:ss');
clear TimeS
fprintf('总有效轨迹点数：%d\n',cnt);
save('AIS_tracks.mat','MMSI','Lon','Lat','Time','-v7.3');
disp('轨迹数据提取完成，已保存 ship_tracks.mat');

%% ========= 清洗函数 =========
function s = cleanStr(x)
    s = strtrim(x);
    s = erase(s,'''');
    s = erase(s,';');
end
