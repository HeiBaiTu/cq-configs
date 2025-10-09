import json
import os
from collections import OrderedDict

def merge_json_files(input_dir="split_configs", output_file="config_new.json"):
    """
    将拆分后的JSON文件重新合并成一个大的配置文件
    
    Args:
        input_dir: 输入的拆分文件目录
        output_file: 输出的合并文件路径
    """
    
    # 检查输入目录是否存在
    if not os.path.exists(input_dir):
        print(f"错误: 找不到目录 {input_dir}")
        print("请确保 split_configs 文件夹存在")
        return False
    
    print(f"正在读取目录: {input_dir}")
    
    # 获取所有JSON文件
    json_files = [f for f in os.listdir(input_dir) if f.endswith('.json')]
    
    if not json_files:
        print(f"错误: 在 {input_dir} 目录中没有找到JSON文件")
        return False
    
    print(f"发现 {len(json_files)} 个JSON文件")
    
    # 创建合并后的数据字典
    merged_data = OrderedDict()
    
    # 按文件名排序，确保合并顺序一致
    json_files.sort()
    
    # 遍历每个JSON文件
    for filename in json_files:
        filepath = os.path.join(input_dir, filename)
        
        # 从文件名提取配置项名称（去掉.json后缀）
        config_name = filename[:-5]  # 去掉.json后缀
        
        print(f"正在处理: {filename} -> {config_name}")
        
        try:
            # 读取JSON文件
            with open(filepath, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # 添加到合并数据中
            merged_data[config_name] = data
            
            print(f"  -> 已加载: {config_name}")
            
        except json.JSONDecodeError as e:
            print(f"  -> 错误: {filename} 不是有效的JSON文件 - {e}")
            continue
        except Exception as e:
            print(f"  -> 错误: 读取 {filename} 时出错 - {e}")
            continue
    
    if not merged_data:
        print("错误: 没有成功加载任何JSON文件")
        return False
    
    print(f"\n正在写入合并文件: {output_file}")
    
    try:
        # 写入合并后的JSON文件
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(merged_data, f, ensure_ascii=False, indent=2)
        
        print(f"合并完成！文件已保存到: {output_file}")
        print(f"共合并了 {len(merged_data)} 个配置项")
        
        # 显示文件大小信息
        file_size = os.path.getsize(output_file)
        if file_size > 1024 * 1024:  # 大于1MB
            size_str = f"{file_size / (1024 * 1024):.2f} MB"
        else:
            size_str = f"{file_size / 1024:.2f} KB"
        
        print(f"文件大小: {size_str}")
        
        return True
        
    except Exception as e:
        print(f"错误: 写入文件时出错 - {e}")
        return False

def compare_with_original(original_file="config.json", new_file="config_new.json"):
    """
    比较原始文件和新合并文件的配置项数量
    
    Args:
        original_file: 原始配置文件
        new_file: 新合并的配置文件
    """
    
    print("\n" + "=" * 50)
    print("文件对比")
    print("=" * 50)
    
    # 检查原始文件
    if os.path.exists(original_file):
        try:
            with open(original_file, 'r', encoding='utf-8') as f:
                original_data = json.load(f)
            print(f"原始文件 {original_file}: {len(original_data)} 个配置项")
        except Exception as e:
            print(f"无法读取原始文件: {e}")
    else:
        print(f"原始文件 {original_file} 不存在")
    
    # 检查新文件
    if os.path.exists(new_file):
        try:
            with open(new_file, 'r', encoding='utf-8') as f:
                new_data = json.load(f)
            print(f"新文件 {new_file}: {len(new_data)} 个配置项")
        except Exception as e:
            print(f"无法读取新文件: {e}")
    else:
        print(f"新文件 {new_file} 不存在")

if __name__ == "__main__":
    # 使用示例
    input_folder = "split_configs"  # 拆分文件目录
    output_file = "config_new.json"  # 输出文件名
    
    print("=" * 50)
    print("JSON配置文件合并工具")
    print("=" * 50)
    
    # 执行合并
    success = merge_json_files(input_folder, output_file)
    
    if success:
        # 与原始文件对比
        compare_with_original()
        
        print("\n" + "=" * 50)
        print("合并完成！")
        print("=" * 50)
    else:
        print("\n" + "=" * 50)
        print("合并失败！")
        print("=" * 50)
