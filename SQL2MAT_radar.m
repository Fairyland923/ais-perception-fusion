clc;
clear;
close all;

%% ========= 文件路径 =========
filename = 'C:\Users\fairyland\Desktop\感知+AIS轨迹融合\感知数据\mq_radar_record_20260110.sql';
fid = fopen(filename,'r');

%%
Nalloc = 3e6;        
cnt = 0;

UID   = cell(Nalloc,1);
Lon_radar   = zeros(Nalloc,1);
Lat_radar   = zeros(Nalloc,1);
TimeS_radar = cell(Nalloc,1);   

while ~feof(fid)
    line = fgetl(fid);
    if ~startsWith(line,'INSERT INTO')
        continue;
    end
    p1 = strfind(line,'(');
    p2 = strfind(line,')');

    for k = 1:numel(p1)
        cnt = cnt + 1;
        row = line(p1(k)+1 : p2(k)-1);
        c = strsplit(row,',');

        uid_str = cleanStr(c{2});
        lon_str = cleanStr(c{3});
        lat_str = cleanStr(c{4});
        tim_str = cleanStr(c{7});

        UID{cnt}   = uid_str;
        Lon_radar(cnt)   = str2double(lon_str);
        Lat_radar(cnt)   = str2double(lat_str);
        TimeS_radar{cnt} = tim_str;
    end
end
fclose(fid);

UID   = UID(1:cnt);
Lon_radar   = Lon_radar(1:cnt);
Lat_radar   = Lat_radar(1:cnt);
TimeS_radar = TimeS_radar(1:cnt);
Time_radar = datetime(TimeS_radar,'InputFormat','yyyy-MM-dd HH:mm:ss');
clear TimeS_radar


fprintf('总记录数：%d\n',cnt);
save('radar_all.mat','UID','Lon_radar','Lat_radar','Time_radar','-v7.3');
disp('数据提取完成并已保存 radar_all.mat');

%% ========= 局部函数 =========
function s = cleanStr(x)
    s = strtrim(x);
    s = erase(s,'''');
    s = erase(s,')');
    s = erase(s,';');
end


