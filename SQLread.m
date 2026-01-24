filename = 'C:\Users\fairyland\Desktop\感知+AIS轨迹融合\感知数据\mq_radar_record_20260110.sql';

fid = fopen(filename, 'r');

for i = 1:1000
    tline = fgetl(fid);
    if ~ischar(tline)
        break;
    end
    disp(tline)
end

fclose(fid);
