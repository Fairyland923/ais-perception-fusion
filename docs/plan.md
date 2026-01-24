# 实施计划 - AIS与雷达数据匹配改进

## 目标描述
当前工作流需要手动输入进行每一次船只匹配和可视化，效率低下。代码也存在可读性问题，且缺乏注释。
目标是：
1.  **自动化匹配**：创建一个批量处理流程，自动将**所有**雷达UID与AIS MMSI进行匹配，无需用户干预。
2.  **保存结果**：将匹配结果存储在结构化文件（`MatchResults.mat`）中，以便快速访问。
3.  **统一可视化**：创建一个查看器，读取保存的结果，允许用户选择一个UID立即查看其轨迹，无需重新输入MMSI。
4.  **重构代码**：改进注释和向量化，以提高性能和可读性。

## 用户审查要求
> [!NOTE]
> - **输入方式**：用户将通过**索引（1-N）**选择UID，而不是输入完整的UID字符串。
> - **语言**：所有注释将使用**中文**。
> - **阈值**：时间窗口和空间阈值将保持**不变**。

## 提议的变更

### 数据匹配
#### [新] [RunBatchMatching.m](file:///C:/Users/fairyland/Desktop/ais-perception-fusion/RunBatchMatching.m)
- **目的**：匹配过程的主要入口点。
- **逻辑**：
    1.  加载 `radar_all.mat` 和 `AIS_tracks.mat`。
    2.  从雷达数据中提取所有唯一的UID。
    3.  遍历每个UID：
        -   提取雷达轨迹。
        -   按时间和位置（边界框）过滤AIS数据。
        -   计算与候选MMSI的距离。
        -   基于距离阈值选择最佳匹配（**保持现有阈值逻辑**）。
    4.  将结果存储在结构体数组中（UID, BestMMSI, MinDistance, MatchScore）。
    5.  保存到 `MatchResults.mat`。
    6.  打印匹配摘要表。

### 可视化
#### [新] [ViewTrajectories.m](file:///C:/Users/fairyland/Desktop/ais-perception-fusion/ViewTrajectories.m)
- **目的**：用于查看结果的交互式工具。
- **逻辑**：
    1.  加载 `MatchResults.mat`。
    2.  显示匹配的UID总数（例如，“共有 50 个匹配结果”）。
    3.  **提示用户输入索引（1-N）**。
    4.  检索对应索引的UID和MMSI。
    5.  调用绘图函数。

### 视觉辅助
#### [新] [plot_trajectory_function.m](file:///C:/Users/fairyland/Desktop/ais-perception-fusion/plot_trajectory_function.m)
- **目的**：可重用的绘图函数。
- **逻辑**：从 `trace.m` 中提取。确保所有注释均为**中文**。

### 清理
#### [修改] [SQL2MAT_radar.m](file:///C:/Users/fairyland/Desktop/ais-perception-fusion/SQL2MAT_radar.m)
- 添加解释输入/输出的**中文**注释。
- 标准化变量名以提高可读性。

#### [修改] [SQL2MAT_AIS.m](file:///C:/Users/fairyland/Desktop/ais-perception-fusion/SQL2MAT_AIS.m)
- **标准化**代码结构以匹配 `SQL2MAT_radar.m`。
- 添加**中文**注释。
- 更新变量名以与雷达脚本保持一致。

## 验证计划

### 自动化测试
- 无（从代理自动化MATLAB环境较为困难，且无特定测试框架）。

### 手动验证
1.  **运行处理**：
    -   执行 `RunBatchMatching`。
    -   验证 `MatchResults.mat` 是否已创建。
    -   检查命令窗口输出，确认匹配了多少个UID的摘要。
2.  **运行可视化**：
    -   执行 `ViewTrajectories`。
    -   输入一个已匹配的UID对应的索引（例如，从摘要中获取）。
    -   验证是否弹出图形窗口，显示雷达和AIS轨迹已对齐。
    -   验证标题是否显示正确的UID和MMSI。
