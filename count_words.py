#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import re

def count_chars(text):
    """从文本中提取中文和英文字符数"""
    # 提取中文字符
    chinese = re.findall(r'[\u4e00-\u9fff]', text)
    # 英文和数字
    english = re.findall(r'[a-zA-Z0-9]', text)
    return len(chinese), len(english)

def process_tex_file(filepath):
    """处理单个tex文件"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 移除注释行
    lines = content.split('\n')
    filtered_lines = []
    for line in lines:
        # 移除%后的注释
        idx = line.find('%')
        if idx >= 0:
            line = line[:idx]
        filtered_lines.append(line)
    
    content = '\n'.join(filtered_lines)
    
    # 移除LaTeX环境
    content = re.sub(r'\\begin\{[^}]*\}.*?\\end\{[^}]*\}', '', content, flags=re.DOTALL)
    
    # 移除LaTeX命令
    content = re.sub(r'\\[a-zA-Z]+\{[^}]*\}', '', content)
    content = re.sub(r'\\[a-zA-Z]+\[[^\]]*\]\{[^}]*\}', '', content)
    content = re.sub(r'\\[a-zA-Z]+', '', content)
    
    # 移除数学公式
    content = re.sub(r'\$\$.*?\$\$', '', content, flags=re.DOTALL)
    content = re.sub(r'\$.*?\$', '', content, flags=re.DOTALL)
    content = re.sub(r'\\\[.*?\\\]', '', content, flags=re.DOTALL)
    
    # 移除括号
    content = re.sub(r'[{}[\]]', '', content)
    
    return count_chars(content)

# 统计main.tex
try:
    total_chinese = 0
    total_english = 0
    
    print("开始统计字数...\n")
    
    # main.tex
    ch, en = process_tex_file('main.tex')
    total_chinese += ch
    total_english += en
    print(f"main.tex: 中文 {ch}字，英文/数字 {en}个")
    
    # data 文件夹下的所有tex文件
    import os
    import glob
    
    tex_files = []
    for root, dirs, files in os.walk('data'):
        for file in files:
            if file.endswith('.tex'):
                filepath = os.path.join(root, file)
                tex_files.append(filepath)
    
    tex_files.sort()
    
    if tex_files:
        print("\ninclude 文件统计:")
        for filepath in tex_files:
            try:
                ch, en = process_tex_file(filepath)
                if ch + en > 0:
                    total_chinese += ch
                    total_english += en
                    print(f"  {filepath}: 中文 {ch}字，英文/数字 {en}个")
            except Exception as e:
                print(f"  {filepath}: 处理失败 - {e}")
    
    print("\n" + "="*60)
    print(f"总计字数:")
    print(f"  中文字数（含标题、摘要等）: {total_chinese}")
    print(f"  英文字母和数字: {total_english}")
    print(f"  总计: {total_chinese + total_english}")
    print("="*60)
    print("\n注：")
    print("- 中文按每个汉字计数")
    print("- 英文字母和数字每个计数一次")
    print("- 不包括LaTeX命令、公式等标记")
    
except Exception as e:
    print(f"统计出错: {e}")
    import traceback
    traceback.print_exc()
