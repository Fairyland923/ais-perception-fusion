"""
sql2csv_radar.py
读取 SQL 导出文件中的雷达记录，提取 UID、经度、纬度、时间 四列，保存为 CSV 文件。
参考 SQL2MAT_radar.m 的解析逻辑。
"""

import re
import csv
import os
import time

# ========= 文件路径设置 =========
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT_FILE = os.path.join(SCRIPT_DIR, 'dataset', 'mq_radar_record_20260110.sql')
OUTPUT_FILE = os.path.join(SCRIPT_DIR, 'dataset', 'radar_data_20260110.csv')


def clean_str(s):
    """清洗字符串：去除首尾空格、单引号、右括号、分号"""
    s = s.strip()
    s = s.replace("'", "")
    s = s.replace(")", "")
    s = s.replace(";", "")
    return s


def parse_sql_to_csv(input_path, output_path):
    """
    逐行读取 SQL 文件，解析 INSERT INTO 语句中的记录，
    提取 UID(mq_id)、经度(longitude)、纬度(latitude)、时间(mq_time)，
    写入 CSV 文件。
    """
    # 用于匹配每条记录中括号内的内容
    record_pattern = re.compile(r"\(([^)]+)\)")

    cnt = 0
    start_time = time.time()

    with open(input_path, 'r', encoding='utf-8') as fin, \
         open(output_path, 'w', encoding='utf-8-sig', newline='') as fout:

        writer = csv.writer(fout)
        # 写入表头
        writer.writerow(['UID', 'Longitude', 'Latitude', 'Time'])

        for line in fin:
            # 仅处理以 INSERT INTO 开头的行
            if not line.startswith('INSERT INTO'):
                continue

            # 提取该行所有括号内的记录
            matches = record_pattern.findall(line)
            for match in matches:
                # 按逗号分割字段
                fields = match.split(',')

                # 提取字段（与 MATLAB 脚本一致）
                #   fields[0] -> id
                #   fields[1] -> mq_id (UID)
                #   fields[2] -> longitude (经度)
                #   fields[3] -> latitude  (纬度)
                #   fields[4] -> height
                #   fields[5] -> speed
                #   fields[6] -> mq_time   (时间)
                uid = clean_str(fields[1])
                lon = clean_str(fields[2])
                lat = clean_str(fields[3])
                mq_time = clean_str(fields[6])

                writer.writerow([uid, lon, lat, mq_time])
                cnt += 1

                # 每 50 万条打印一次进度
                if cnt % 500000 == 0:
                    elapsed = time.time() - start_time
                    print(f'  已处理 {cnt} 条记录，耗时 {elapsed:.1f}s')

    elapsed = time.time() - start_time
    print(f'\n完成！总记录数：{cnt}，耗时 {elapsed:.1f}s')
    print(f'CSV 文件已保存至：{output_path}')


if __name__ == '__main__':
    print(f'输入文件：{INPUT_FILE}')
    print(f'输出文件：{OUTPUT_FILE}')
    print('开始解析...\n')
    parse_sql_to_csv(INPUT_FILE, OUTPUT_FILE)
