# ModelID 数据位置分析

## 概述
ModelID是游戏中用于标识3D模型外观的ID，它决定了召唤物、怪物、NPC等在游戏中的视觉表现。

## ModelID 数据存储位置

### 1. 前端配置 (客户端显示)

#### 1.1 Monster.json (召唤物/怪物外观)
**文件位置**: `split_configs/Monster.json`
**用途**: 客户端显示召唤物和怪物的外观

```json
"129": {
    "name": "神兽Lv1",
    "entityid": 129,
    "modelid": 30150,        // 外观模型ID
    "propid": 115,           // 属性ID
    "entityType": 4,         // 实体类型(4=召唤物)
    "scale": 115,            // 缩放比例
    "circle": 0
}
```

#### 1.2 Npc.json (NPC外观)
**文件位置**: `split_configs/Npc.json`
**用途**: 客户端显示NPC的外观

#### 1.3 Scenes.json (场景对象外观)
**文件位置**: `split_configs/Scenes.json`
**用途**: 客户端显示场景中静态对象的外观

### 2. 后端配置 (服务器逻辑)

#### 2.1 Monster.config (怪物配置)
**文件位置**: `data/config/monster/Monster.config`
**用途**: 服务器端怪物和召唤物的基础配置

```lua
[129] = {
    entityid = 129,
    entityType = 4,
    monsterType = 1,
    name = "神兽Lv1",
    level = 35,
    circle = 0,
    aiConfigId = 5,
    propid = 115,
    flagid = 9,
    exp = 0,
    attackLevel = 120,
    attackInterval = 500,
    skills = {
        {id=52,level=1,event=0,autoCD=false},
    },
    modelid = 30150,         -- 外观模型ID
    attackMusicRate = 100,
    dieMusicRate = 100,
    targetMusicTate = 100,
    damageMusicRate = 100,
}
```

#### 2.2 npc.config (NPC配置)
**文件位置**: `data/config/npc/npc.config`
**用途**: 服务器端NPC的基础配置

## 召唤神兽 ModelID 对应关系

### 神兽系列 ModelID

| 召唤物名称 | EntityID | ModelID | 说明 |
|------------|----------|---------|------|
| 神兽Lv1    | 129      | 30150   | 普通神兽外观 |
| 神兽Lv2    | 134      | 30150   | 普通神兽外观 |
| 神兽Lv3    | 135      | 30150   | 普通神兽外观 |
| 神兽Lv4    | 136      | 30150   | 普通神兽外观 |
| 圣兽Lv5    | 137      | 30150   | 普通神兽外观 |
| 圣兽Lv6    | 138      | 30150   | 普通神兽外观 |
| 圣兽Lv7    | 139      | 30150   | 普通神兽外观 |
| 圣兽Lv8    | 140      | 30150   | 普通神兽外观 |
| 圣兽Lv9    | 141      | 30150   | 普通神兽外观 |
| 超级圣兽   | 130      | 30151   | 超级圣兽外观 |

### ModelID 说明

- **30150**: 普通神兽/圣兽外观模型
- **30151**: 超级圣兽外观模型 (更炫酷的外观)

## ModelID 数据流向

### 1. 服务器端流程
```
SkillRanges.config (召唤逻辑)
    ↓
Monster.config (获取modelid)
    ↓
服务器创建召唤物实体
```

### 2. 客户端流程
```
Monster.json (获取modelid)
    ↓
客户端渲染系统
    ↓
显示3D模型
```

## 如何修改召唤物外观

### 1. 修改单个召唤物外观

#### 前端配置修改
**文件**: `split_configs/Monster.json`
```json
"129": {
    "modelid": 30151,  // 从30150改为30151，使用超级圣兽外观
    // ... 其他属性保持不变
}
```

#### 后端配置修改
**文件**: `data/config/monster/Monster.config`
```lua
[129] = {
    modelid = 30151,  -- 从30150改为30151
    -- ... 其他属性保持不变
}
```

### 2. 批量修改召唤物外观

#### 修改所有神兽使用超级圣兽外观
```json
// 前端配置
"129": {"modelid": 30151},  // 神兽Lv1
"134": {"modelid": 30151},  // 神兽Lv2
"135": {"modelid": 30151},  // 神兽Lv3
"136": {"modelid": 30151},  // 神兽Lv4
"137": {"modelid": 30151},  // 圣兽Lv5
"138": {"modelid": 30151},  // 圣兽Lv6
"139": {"modelid": 30151},  // 圣兽Lv7
"140": {"modelid": 30151},  // 圣兽Lv8
"141": {"modelid": 30151},  // 圣兽Lv9
```

```lua
-- 后端配置
[129] = {modelid = 30151},  -- 神兽Lv1
[134] = {modelid = 30151},  -- 神兽Lv2
[135] = {modelid = 30151},  -- 神兽Lv3
[136] = {modelid = 30151},  -- 神兽Lv4
[137] = {modelid = 30151},  -- 圣兽Lv5
[138] = {modelid = 30151},  -- 圣兽Lv6
[139] = {modelid = 30151},  -- 圣兽Lv7
[140] = {modelid = 30151},  -- 圣兽Lv8
[141] = {modelid = 30151},  -- 圣兽Lv9
```

## 可用的 ModelID 范围

### 常见 ModelID 类型

| ModelID范围 | 说明 | 示例 |
|-------------|------|------|
| 30001-30100 | 基础怪物模型 | 30001(鸡), 30002(鹿) |
| 30101-30200 | 高级怪物模型 | 30150(神兽), 30151(超级圣兽) |
| 30201-30300 | 特殊怪物模型 | 30208(梦境神兽) |
| 40001-40100 | NPC模型 | 40001(村长), 40002(商人) |
| 50001-50100 | 玩家模型 | 50001(战士), 50002(法师) |

### 查找更多 ModelID

可以通过以下方式查找更多可用的ModelID：

1. **查看Monster.config文件**：
   ```bash
   grep "modelid" data/config/monster/Monster.config
   ```

2. **查看Monster.json文件**：
   ```bash
   grep "modelid" split_configs/Monster.json
   ```

3. **查看Npc.json文件**：
   ```bash
   grep "modelid" split_configs/Npc.json
   ```

## 注意事项

### 1. 同步性要求
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

ModelID数据主要存储在：
1. **前端**: `split_configs/Monster.json` (客户端显示)
2. **后端**: `data/config/monster/Monster.config` (服务器逻辑)

修改召唤物外观需要同时修改前后端配置中的modelid值，确保数据同步。常用的神兽ModelID包括30150(普通神兽)和30151(超级圣兽)。
