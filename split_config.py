import json
import os
from collections import OrderedDict

def split_json_file(input_file, output_dir="split_configs"):
    """
    将大的JSON配置文件拆分成多个小文件
    
    Args:
        input_file: 输入的JSON文件路径
        output_dir: 输出目录
    """
    
    # 创建输出目录
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"已创建输出目录: {output_dir}")
    
    print(f"正在读取文件: {input_file}")
    
    # 读取JSON文件
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"发现 {len(data)} 个顶级配置项")
    
    # 遍历每个顶级键
    for key, value in data.items():
        # 创建文件名
        filename = f"{key}.json"
        filepath = os.path.join(output_dir, filename)
        
        print(f"正在处理: {key} -> {filename}")
        
        # 递归排序函数，处理嵌套字典
        def sort_dict_recursively(obj):
            if isinstance(obj, dict):
                # 改进的排序函数，处理字符串和数字混合的情况
                def sort_key(k):
                    try:
                        # 尝试转换为数字
                        return (0, int(k))  # 数字键优先级高，返回 (0, 数字)
                    except (ValueError, TypeError):
                        # 如果转换失败，按字符串排序
                        return (1, str(k))  # 字符串键优先级低，返回 (1, 字符串)
                
                # 按从小到大排序
                sorted_items = sorted(obj.items(), key=lambda x: sort_key(x[0]))
                sorted_dict = OrderedDict()
                
                # 递归处理每个值
                for k, v in sorted_items:
                    sorted_dict[k] = sort_dict_recursively(v)
                
                return sorted_dict
            elif isinstance(obj, list):
                # 如果是列表，递归处理列表中的每个元素
                return [sort_dict_recursively(item) for item in obj]
            else:
                # 基本类型直接返回
                return obj
        
        # 对值进行递归排序
        sorted_value = sort_dict_recursively(value)
        
        # 写入文件
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(sorted_value, f, ensure_ascii=False, indent=2)
        
        print(f"  -> 已保存到: {filepath}")
    
    print(f"\n拆分完成！所有文件已保存到: {output_dir}")
    print(f"共生成 {len(data)} 个配置文件")

if __name__ == "__main__":
    # 使用示例
    input_file = "config.json"  # 你的配置文件路径
    output_folder = "split_configs"  # 输出文件夹名称
    
    print("=" * 50)
    print("JSON配置文件拆分工具")
    print("=" * 50)
    
    # 检查输入文件是否存在
    if not os.path.exists(input_file):
        print(f"错误: 找不到文件 {input_file}")
        print("请确保 config.json 文件在当前目录下")
        exit(1)
    
    # 执行拆分
    split_json_file(input_file, output_folder)
    
    print("\n" + "=" * 50)
    print("拆分完成！")
    print("=" * 50)
