% clc;
% clear;

%% 加载匹配结果并打印信息
resultFile = 'MatchResults.mat';

if ~isfile(resultFile)
    fprintf('错误：未找到文件 %s。请先运行 RunBatchMatching.m 生成结果。\n', resultFile);
    return;
end

fprintf('正在加载匹配结果...\n');
load(resultFile, 'results');

if ~exist('results', 'var') || isempty(results)
    fprintf('匹配结果为空。\n');
    return;
end

num_matches = length(results);
fprintf('共加载 %d 条匹配结果：\n', num_matches);
fprintf('----------------------------------------------------------------------\n');
fprintf('%-6s %-20s %-15s %-12s %-10s\n', '索引', '雷达目标(UID)', 'AIS(MMSI)', '平均距离(m)', '匹配点数');
fprintf('----------------------------------------------------------------------\n');

for i = 1:num_matches
    r = results(i);
    
    % 确保转换为字符串以便输出
    uid = string(r.UID);
    mmsi = string(r.BestMMSI);
    dist = r.MinDist;
    score = r.MatchScore;
    
    fprintf('%-6d %-20s %-15s %-12.2f %-10d\n', i, uid, mmsi, dist, score);
end
fprintf('----------------------------------------------------------------------\n');
