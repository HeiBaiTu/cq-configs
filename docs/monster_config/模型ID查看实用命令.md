# 模型ID查看实用命令

## 概述

本文档提供查看外观模型ID的实用命令，帮助快速找到合适的模型ID。

## 基础查看命令

### 1. 查看所有怪物模型ID

```bash
# 查看Monster.config中的所有模型ID
grep "modelid" data/config/monster/Monster.config

# 查看Monster.json中的所有模型ID
grep "modelid" split_configs/Monster.json
```

### 2. 按范围查看模型ID

```bash
# 查看30001-30050范围的模型ID
grep "modelid.*=.*30[0-4][0-9][0-9]" data/config/monster/Monster.config

# 查看30150-30200范围的模型ID
grep "modelid.*=.*30[1-2][0-9][0-9]" data/config/monster/Monster.config

# 查看30201-30300范围的模型ID
grep "modelid.*=.*30[2-3][0-9][0-9]" data/config/monster/Monster.config
```

### 3. 查看特定怪物的模型ID

```bash
# 查看名为"鸡"的怪物模型ID
grep -A 3 -B 3 "name.*鸡" data/config/monster/Monster.config

# 查看名为"神兽"的怪物模型ID
grep -A 3 -B 3 "name.*神兽" data/config/monster/Monster.config

# 查看名为"Boss"的怪物模型ID
grep -A 3 -B 3 "name.*Boss" data/config/monster/Monster.config
```

## 高级查看命令

### 1. 统计模型ID使用频率

```bash
# 统计模型ID使用频率（按使用次数排序）
grep "modelid" data/config/monster/Monster.config | \
cut -d'=' -f2 | cut -d',' -f1 | sort | uniq -c | sort -nr

# 统计前端配置中的模型ID使用频率
grep "modelid" split_configs/Monster.json | \
cut -d':' -f3 | cut -d',' -f1 | sort | uniq -c | sort -nr
```

### 2. 查找未使用的模型ID

```bash
# 查找30001-30050范围内未使用的模型ID
for i in {30001..30050}; do
    if ! grep -q "modelid.*$i" data/config/monster/Monster.config; then
        echo "未使用的模型ID: $i"
    fi
done

# 查找30151-30200范围内未使用的模型ID
for i in {30151..30200}; do
    if ! grep -q "modelid.*$i" data/config/monster/Monster.config; then
        echo "未使用的模型ID: $i"
    fi
done
```

### 3. 检查模型ID冲突

```bash
# 检查特定模型ID是否已被使用
check_modelid() {
    local modelid=$1
    echo "检查模型ID: $modelid"
    
    if grep -q "modelid.*$modelid" data/config/monster/Monster.config; then
        echo "后端配置中已使用: $modelid"
        grep "modelid.*$modelid" data/config/monster/Monster.config
    else
        echo "后端配置中未使用: $modelid"
    fi
    
    if grep -q "modelid.*$modelid" split_configs/Monster.json; then
        echo "前端配置中已使用: $modelid"
        grep "modelid.*$modelid" split_configs/Monster.json
    else
        echo "前端配置中未使用: $modelid"
    fi
}

# 使用示例
check_modelid 32000
```

## 分类查看命令

### 1. 按怪物类型查看

```bash
# 查看普通怪物(monsterType=1)的模型ID
grep -A 10 "monsterType = 1" data/config/monster/Monster.config | grep "modelid"

# 查看Boss怪物(monsterType=4)的模型ID
grep -A 10 "monsterType = 4" data/config/monster/Monster.config | grep "modelid"

# 查看召唤物(entityType=4)的模型ID
grep -A 10 "entityType = 4" data/config/monster/Monster.config | grep "modelid"
```

### 2. 按等级范围查看

```bash
# 查看1-20级怪物的模型ID
grep -A 10 "level = [1-9]\|level = 1[0-9]\|level = 20" data/config/monster/Monster.config | grep "modelid"

# 查看21-40级怪物的模型ID
grep -A 10 "level = 2[1-9]\|level = 3[0-9]\|level = 40" data/config/monster/Monster.config | grep "modelid"

# 查看81+级怪物的模型ID
grep -A 10 "level = 8[1-9]\|level = 9[0-9]\|level = [1-9][0-9][0-9]" data/config/monster/Monster.config | grep "modelid"
```

### 3. 按模型ID范围查看

```bash
# 查看基础怪物模型(30001-30050)
grep "modelid.*=.*30[0-4][0-9][0-9]" data/config/monster/Monster.config

# 查看神兽模型(30150-30170)
grep "modelid.*=.*301[5-7][0-9]" data/config/monster/Monster.config

# 查看Boss模型(30201-30250)
grep "modelid.*=.*302[0-4][0-9]" data/config/monster/Monster.config
```

## 实用脚本

### 1. 模型ID查找脚本

```bash
#!/bin/bash
# 模型ID查找脚本

# 函数：查找模型ID
find_modelid() {
    local modelid=$1
    echo "=== 查找模型ID: $modelid ==="
    
    # 在后端配置中查找
    echo "后端配置 (Monster.config):"
    if grep -q "modelid.*$modelid" data/config/monster/Monster.config; then
        grep -B 5 -A 5 "modelid.*$modelid" data/config/monster/Monster.config
    else
        echo "未找到"
    fi
    
    # 在前端配置中查找
    echo -e "\n前端配置 (Monster.json):"
    if grep -q "modelid.*$modelid" split_configs/Monster.json; then
        grep -B 5 -A 5 "modelid.*$modelid" split_configs/Monster.json
    else
        echo "未找到"
    fi
}

# 使用示例
find_modelid 32000
```

### 2. 模型ID统计脚本

```bash
#!/bin/bash
# 模型ID统计脚本

echo "=== 模型ID使用统计 ==="
echo "后端配置统计:"
grep "modelid" data/config/monster/Monster.config | \
cut -d'=' -f2 | cut -d',' -f1 | sort | uniq -c | sort -nr | head -20

echo -e "\n前端配置统计:"
grep "modelid" split_configs/Monster.json | \
cut -d':' -f3 | cut -d',' -f1 | sort | uniq -c | sort -nr | head -20

echo -e "\n=== 按范围统计 ==="
echo "30001-30050 (基础怪物):"
grep "modelid.*=.*30[0-4][0-9][0-9]" data/config/monster/Monster.config | wc -l

echo "30051-30100 (中级怪物):"
grep "modelid.*=.*30[0-1][0-9][0-9]" data/config/monster/Monster.config | wc -l

echo "30101-30150 (高级怪物):"
grep "modelid.*=.*301[0-4][0-9]" data/config/monster/Monster.config | wc -l

echo "30151-30200 (特殊怪物):"
grep "modelid.*=.*301[5-9][0-9]\|modelid.*=.*30200" data/config/monster/Monster.config | wc -l

echo "30201-30300 (Boss怪物):"
grep "modelid.*=.*302[0-9][0-9]\|modelid.*=.*30300" data/config/monster/Monster.config | wc -l
```

### 3. 模型ID冲突检查脚本

```bash
#!/bin/bash
# 模型ID冲突检查脚本

check_conflict() {
    local modelid=$1
    echo "检查模型ID: $modelid"
    
    # 检查后端配置
    if grep -q "modelid.*$modelid" data/config/monster/Monster.config; then
        echo "❌ 后端配置中已使用: $modelid"
        grep "modelid.*$modelid" data/config/monster/Monster.config
    else
        echo "✅ 后端配置中未使用: $modelid"
    fi
    
    # 检查前端配置
    if grep -q "modelid.*$modelid" split_configs/Monster.json; then
        echo "❌ 前端配置中已使用: $modelid"
        grep "modelid.*$modelid" split_configs/Monster.json
    else
        echo "✅ 前端配置中未使用: $modelid"
    fi
    
    # 检查NPC配置
    if grep -q "modelid.*$modelid" split_configs/Npc.json; then
        echo "❌ NPC配置中已使用: $modelid"
        grep "modelid.*$modelid" split_configs/Npc.json
    else
        echo "✅ NPC配置中未使用: $modelid"
    fi
}

# 使用示例
check_conflict 32000
```

## 快速查找命令

### 1. 查找可用模型ID

```bash
# 查找30001-30050范围内可用的模型ID
for i in {30001..30050}; do
    if ! grep -q "modelid.*$i" data/config/monster/Monster.config && \
       ! grep -q "modelid.*$i" split_configs/Monster.json; then
        echo "可用模型ID: $i"
    fi
done
```

### 2. 查找相似模型ID

```bash
# 查找包含"30"的模型ID
grep "modelid.*30" data/config/monster/Monster.config

# 查找包含"301"的模型ID
grep "modelid.*301" data/config/monster/Monster.config

# 查找包含"302"的模型ID
grep "modelid.*302" data/config/monster/Monster.config
```

### 3. 查找特定怪物的模型ID

```bash
# 查找所有"兽"类怪物的模型ID
grep -B 5 -A 5 "name.*兽" data/config/monster/Monster.config | grep "modelid"

# 查找所有"龙"类怪物的模型ID
grep -B 5 -A 5 "name.*龙" data/config/monster/Monster.config | grep "modelid"

# 查找所有"神"类怪物的模型ID
grep -B 5 -A 5 "name.*神" data/config/monster/Monster.config | grep "modelid"
```

## 总结

通过这些实用命令，可以快速：

1. **查看现有模型ID**: 了解已使用的模型ID
2. **查找可用模型ID**: 找到未使用的模型ID
3. **检查模型ID冲突**: 避免重复使用
4. **统计模型ID使用**: 了解使用情况
5. **按分类查看**: 根据需求查找特定类型的模型ID

常用命令：
```bash
# 查看所有模型ID
grep "modelid" data/config/monster/Monster.config

# 检查特定模型ID
grep "modelid.*32000" data/config/monster/Monster.config

# 统计使用频率
grep "modelid" data/config/monster/Monster.config | cut -d'=' -f2 | cut -d',' -f1 | sort | uniq -c | sort -nr
```
