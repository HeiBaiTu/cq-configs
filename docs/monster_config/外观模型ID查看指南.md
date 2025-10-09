# 外观模型ID查看指南

## 概述

外观模型ID（modelid）是游戏中用于标识3D模型外观的ID，它决定了怪物、NPC、召唤物等在游戏中的视觉表现。本文档详细说明如何查看和选择合适的外观模型ID。

## 外观模型ID的存储位置

### 1. 后端配置文件

#### Monster.config (怪物配置)
**文件位置**: `data/config/monster/Monster.config`
**用途**: 服务器端怪物和召唤物的基础配置

```lua
[1] = {
    entityid = 1,
    name = "鸡",
    modelid = 30001,  -- 外观模型ID
    -- ... 其他配置
},
```

#### npc.config (NPC配置)
**文件位置**: `data/config/npc/npc.config`
**用途**: 服务器端NPC的基础配置

### 2. 前端配置文件

#### Monster.json (怪物外观)
**文件位置**: `split_configs/Monster.json`
**用途**: 客户端显示怪物和召唤物的外观

```json
"1": {
    "name": "鸡",
    "entityid": 1,
    "modelid": 30001,  // 外观模型ID
    "propid": 1,
    "entityType": 1,
    "scale": 100,
    "circle": 0
}
```

#### Npc.json (NPC外观)
**文件位置**: `split_configs/Npc.json`
**用途**: 客户端显示NPC的外观

#### Scenes.json (场景对象外观)
**文件位置**: `split_configs/Scenes.json`
**用途**: 客户端显示场景中静态对象的外观

## 如何查看现有的外观模型ID

### 1. 查看怪物模型ID

#### 方法1: 查看Monster.config文件
```bash
# 查看所有怪物的模型ID
grep "modelid" data/config/monster/Monster.config

# 查看特定范围的模型ID
grep "modelid.*=.*30[0-9][0-9][0-9]" data/config/monster/Monster.config
```

#### 方法2: 查看Monster.json文件
```bash
# 查看前端配置中的模型ID
grep "modelid" split_configs/Monster.json

# 查看特定范围的模型ID
grep "modelid.*30[0-9][0-9][0-9]" split_configs/Monster.json
```

### 2. 查看NPC模型ID

```bash
# 查看NPC的模型ID
grep "modelid" split_configs/Npc.json
```

### 3. 查看场景对象模型ID

```bash
# 查看场景对象的模型ID
grep "modelid" split_configs/Scenes.json
```

## 外观模型ID分类

### 1. 怪物模型ID范围

| ModelID范围 | 说明 | 示例 |
|-------------|------|------|
| 30001-30050 | 基础怪物模型 | 30001(鸡), 30002(鹿), 30003(羊) |
| 30051-30100 | 中级怪物模型 | 30051(野猪), 30052(狼) |
| 30101-30150 | 高级怪物模型 | 30150(神兽), 30151(超级圣兽) |
| 30151-30200 | 特殊怪物模型 | 30152(梦境神兽), 30153(龙) |
| 30201-30300 | Boss怪物模型 | 30201(祖玛教主), 30202(沃玛教主) |
| 30301-30400 | 世界Boss模型 | 30301(赤月恶魔), 30302(触龙神) |

### 2. NPC模型ID范围

| ModelID范围 | 说明 | 示例 |
|-------------|------|------|
| 40001-40050 | 基础NPC模型 | 40001(村长), 40002(商人) |
| 40051-40100 | 高级NPC模型 | 40051(铁匠), 40052(药师) |
| 40101-40200 | 特殊NPC模型 | 40101(传送员), 40102(仓库管理员) |

### 3. 玩家模型ID范围

| ModelID范围 | 说明 | 示例 |
|-------------|------|------|
| 50001-50050 | 战士模型 | 50001(男战士), 50002(女战士) |
| 50051-50100 | 法师模型 | 50051(男法师), 50052(女法师) |
| 50101-50150 | 道士模型 | 50101(男道士), 50102(女道士) |

## 常用的外观模型ID

### 1. 基础怪物模型

| ModelID | 怪物名称 | 说明 |
|---------|----------|------|
| 30001 | 鸡 | 新手怪物 |
| 30002 | 鹿 | 新手怪物 |
| 30003 | 羊 | 新手怪物 |
| 30004 | 野猪 | 中级怪物 |
| 30005 | 狼 | 中级怪物 |
| 30006 | 熊 | 中级怪物 |
| 30007 | 虎 | 高级怪物 |
| 30008 | 豹 | 高级怪物 |
| 30009 | 狮 | 高级怪物 |
| 30010 | 象 | 高级怪物 |

### 2. 神兽模型

| ModelID | 神兽名称 | 说明 |
|---------|----------|------|
| 30150 | 普通神兽 | 基础神兽外观 |
| 30151 | 超级圣兽 | 炫酷神兽外观 |
| 30152 | 梦境神兽 | 特殊神兽外观 |
| 30153 | 龙 | 龙类外观 |

### 3. Boss模型

| ModelID | Boss名称 | 说明 |
|---------|----------|------|
| 30201 | 祖玛教主 | 祖玛教主外观 |
| 30202 | 沃玛教主 | 沃玛教主外观 |
| 30203 | 赤月恶魔 | 赤月恶魔外观 |
| 30204 | 触龙神 | 触龙神外观 |

## 如何选择合适的模型ID

### 1. 根据怪物类型选择

#### 普通怪物 (monsterType=1)
```lua
-- 推荐使用基础模型ID
modelid = 30001,  -- 鸡
modelid = 30002,  -- 鹿
modelid = 30003,  -- 羊
```

#### 精英怪物 (monsterType=2)
```lua
-- 推荐使用中级模型ID
modelid = 30051,  -- 野猪
modelid = 30052,  -- 狼
modelid = 30053,  -- 熊
```

#### 头目怪物 (monsterType=3)
```lua
-- 推荐使用高级模型ID
modelid = 30101,  -- 虎
modelid = 30102,  -- 豹
modelid = 30103,  -- 狮
```

#### Boss怪物 (monsterType=4)
```lua
-- 推荐使用Boss模型ID
modelid = 30201,  -- 祖玛教主
modelid = 30202,  -- 沃玛教主
modelid = 30203,  -- 赤月恶魔
```

### 2. 根据怪物等级选择

| 等级范围 | 推荐ModelID范围 | 说明 |
|----------|-----------------|------|
| 1-20 | 30001-30020 | 基础怪物模型 |
| 21-40 | 30021-30040 | 中级怪物模型 |
| 41-60 | 30041-30060 | 高级怪物模型 |
| 61-80 | 30061-30080 | 精英怪物模型 |
| 81+ | 30081+ | Boss怪物模型 |

### 3. 根据怪物外观特点选择

#### 动物类怪物
```lua
modelid = 30001,  -- 鸡
modelid = 30002,  -- 鹿
modelid = 30003,  -- 羊
modelid = 30004,  -- 野猪
modelid = 30005,  -- 狼
```

#### 猛兽类怪物
```lua
modelid = 30007,  -- 虎
modelid = 30008,  -- 豹
modelid = 30009,  -- 狮
modelid = 30010,  -- 象
```

#### 神兽类怪物
```lua
modelid = 30150,  -- 普通神兽
modelid = 30151,  -- 超级圣兽
modelid = 30152,  -- 梦境神兽
modelid = 30153,  -- 龙
```

## 查看模型ID的实用命令

### 1. 查看所有模型ID
```bash
# 查看所有怪物的模型ID
grep "modelid" data/config/monster/Monster.config | head -20

# 查看所有NPC的模型ID
grep "modelid" split_configs/Npc.json | head -20
```

### 2. 按范围查看模型ID
```bash
# 查看30001-30050范围的模型ID
grep "modelid.*=.*30[0-4][0-9][0-9]" data/config/monster/Monster.config

# 查看30150-30200范围的模型ID
grep "modelid.*=.*30[1-2][0-9][0-9]" data/config/monster/Monster.config
```

### 3. 查看特定怪物的模型ID
```bash
# 查看名为"鸡"的怪物模型ID
grep -A 5 -B 5 "name.*鸡" data/config/monster/Monster.config

# 查看名为"神兽"的怪物模型ID
grep -A 5 -B 5 "name.*神兽" data/config/monster/Monster.config
```

### 4. 统计模型ID使用情况
```bash
# 统计模型ID使用频率
grep "modelid" data/config/monster/Monster.config | cut -d'=' -f2 | cut -d',' -f1 | sort | uniq -c | sort -nr
```

## 模型ID选择建议

### 1. 新怪物模型ID选择

#### 确定ID范围
- 基础怪物: 30001-30050
- 中级怪物: 30051-30100
- 高级怪物: 30101-30150
- 特殊怪物: 30151-30200
- Boss怪物: 30201-30300

#### 避免冲突
```bash
# 检查ID是否已被使用
grep "modelid.*=.*32000" data/config/monster/Monster.config
grep "modelid.*32000" split_configs/Monster.json
```

### 2. 模型ID命名规范

#### 按类型命名
- 动物类: 30001-30020
- 猛兽类: 30021-30040
- 神兽类: 30150-30170
- Boss类: 30201-30250

#### 按等级命名
- 1-20级: 30001-30020
- 21-40级: 30021-30040
- 41-60级: 30041-30060
- 61-80级: 30061-30080
- 81+级: 30081+

## 注意事项

### 1. 前后端同步
- 前后端配置中的modelid必须保持一致
- 前端修改后需要清除浏览器缓存
- 后端修改后需要重启服务器

### 2. 模型资源
- ModelID必须对应实际存在的3D模型资源
- 如果使用不存在的ModelID，可能导致显示异常
- 建议先测试确认ModelID的有效性

### 3. 性能考虑
- 复杂的3D模型可能影响客户端性能
- 建议选择适合的模型复杂度
- 考虑不同设备的兼容性

### 4. 测试验证
- 修改后需要在游戏中测试外观效果
- 确认模型显示正常，没有贴图错误
- 验证动画效果是否正常

## 总结

外观模型ID的查看和选择需要：

1. **查看现有模型ID**: 通过grep命令查看配置文件中的模型ID
2. **了解模型ID分类**: 根据ID范围了解模型类型
3. **选择合适的模型ID**: 根据怪物类型、等级、外观特点选择
4. **避免ID冲突**: 确保选择的ID没有被使用
5. **测试验证**: 在游戏中测试模型显示效果

常用的查看命令：
```bash
# 查看所有模型ID
grep "modelid" data/config/monster/Monster.config

# 查看特定范围
grep "modelid.*=.*30[0-9][0-9][0-9]" data/config/monster/Monster.config

# 检查ID冲突
grep "modelid.*32000" data/config/monster/Monster.config
```

通过合理选择模型ID，可以为新怪物提供合适的外观表现，提升游戏体验。
