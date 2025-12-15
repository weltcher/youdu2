#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
清理 init.sql 文件，只保留 users 表的 COPY 数据
"""

import re

def clean_init_sql(input_file, output_file):
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 标记是否在 COPY 块中
    lines = content.split('\n')
    result_lines = []
    in_copy_block = False
    in_users_copy = False
    skip_until_backslash = False
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # 检测 COPY 语句开始
        if line.startswith('COPY public.'):
            in_copy_block = True
            # 检查是否是 users 表
            if 'COPY public.users' in line:
                in_users_copy = True
                result_lines.append(line)
            else:
                in_users_copy = False
                # 替换为注释
                table_name = re.search(r'COPY public\.(\w+)', line)
                if table_name:
                    result_lines.append(f'-- Data for table {table_name.group(1)} removed')
                skip_until_backslash = True
        # 检测 COPY 块结束
        elif line.strip() == '\\.' and in_copy_block:
            if in_users_copy:
                result_lines.append(line)
            in_copy_block = False
            in_users_copy = False
            skip_until_backslash = False
        # 处理 COPY 块中的数据
        elif in_copy_block:
            if in_users_copy:
                result_lines.append(line)
            # 否则跳过（不添加到结果中）
        # 处理其他行
        else:
            if not skip_until_backslash:
                result_lines.append(line)
        
        i += 1
    
    # 写入输出文件
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(result_lines))
    
    print(f'✓ 已清理 init.sql 文件')
    print(f'  输入文件: {input_file}')
    print(f'  输出文件: {output_file}')
    print(f'  只保留了 users 表的数据')

if __name__ == '__main__':
    input_file = 'server/db/init.sql'
    output_file = 'server/db/init.sql'
    clean_init_sql(input_file, output_file)
