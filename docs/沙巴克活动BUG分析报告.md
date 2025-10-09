# 沙巴克活动BUG分析报告

## 🎯 问题描述

**BUG现象：** 沙巴克活动存在严重BUG，玩家只要占领沙巴克就能立即领取奖励，而不需要等活动结束。这导致多个行会会长可以重复领取奖励，严重影响游戏平衡。

**预期行为：** 应该只有等活动结束后，最终占领沙巴克的行会才能领取奖励。

## 🔍 问题分析

### 相关文件位置

| 文件类型 | 文件路径 | 作用 |
|---------|---------|------|
| 活动配置 | `data/config/activity/Activities.config` | 沙巴克活动总表配置 |
| 活动配置 | `data/config/activity/Activity10Config.config` | 沙巴克活动详细配置 |
| 活动配置 | `data/config/activity/Activity27Config.config` | 首沙活动配置 |
| 奖励逻辑 | `data/functions/ActorSystems/GuildSystem/guildSystem.lua` | 沙巴克奖励领取核心逻辑 |
| 行会配置 | `data/config/guild/Notice.config` | 行会公告牌奖励配置 |
| 活动脚本 | `data/functions/Activity/ActivityType10.lua` | 沙巴克活动执行脚本 |
| 活动脚本 | `data/functions/Activity/ActivityType27.lua` | 首沙活动执行脚本 |

### 关键配置信息

#### 1. 活动时间配置
```lua
-- Activities.config 中的沙巴克活动配置
[13] = {
    Id = 13,
    ActivityType = 10,
    ActivityName = "沙巴克",
    TimeType = 3,
    TimeDetail = {
        [1]={StartTime="3-20:10",EndTime="3-20:40"},
        [2]={StartTime="6-20:10",EndTime="6-20:40"},
    },
    AfterSrvDay = 3,
    Popup = false,
}
```

#### 2. 奖励配置
```lua
-- Notice.config 中的奖励配置
[4] = {
    position = 4,
    noticereward = {{type=16,id=12,count=1},{type=0,id=1031,count=1},{type=0,id=1032,count=1}},
    ActivityID = 13,
    ActivityID2 = 41,
}
```

### BUG根本原因

**核心问题：** `data/functions/ActorSystems/GuildSystem/guildSystem.lua` 文件中的 `HandleGetSBKAward` 函数存在逻辑错误。

#### 问题代码分析

```lua
-- 第43-46行的错误逻辑
if Actor.isActivityRunning(pActor, (cfg.ActivityID or 0)) or 
   Actor.isActivityRunning(pActor, (cfg.ActivityID2 or 0)) then
    errorcode = 5;  -- 活动进行中，不能领取
    break;
end
```

**问题分析：**
1. **时间检查逻辑错误：** 代码检查活动是否在进行中，如果在进行中就不能领取，但这个逻辑是反的
2. **缺少活动结束判断：** 没有正确判断活动是否已经结束
3. **奖励标志管理混乱：** `setSbkAwardFlag` 在活动开始时被重置，但活动结束时的逻辑不完善

## 🛠️ 解决方案

### 方案1：修改奖励领取逻辑（推荐）

**修改文件：** `data/functions/ActorSystems/GuildSystem/guildSystem.lua`

**修改位置：** 第13-59行的 `HandleGetSBKAward` 函数

**修改内容：**

```lua
function HandleGetSBKAward(pActor, packet)
    if Actor.getEntityType(pActor) ~= enActor then
        return
    end
    local errorcode = 0;
    while(true) 
    do
        local guild = Actor.getGuildPtr(pActor);
        if guild == nil then
            errorcode = 1;
            break;
        end

        local isSbk = Actor.MyGuildIsSbk(pActor);
        if isSbk == 0 then
            errorcode = 2;
            break;
        end

        local nGuildPos = Actor.getGuildPos(pActor);
        local cfg = NoticeConfig[nGuildPos];
        if cfg == nil then
            errorcode = 3;
            break;
        end
        
        -- 修改：检查活动是否已结束
        local activityEnded = true;
        if Actor.isActivityRunning(pActor, (cfg.ActivityID or 0)) or 
           Actor.isActivityRunning(pActor, (cfg.ActivityID2 or 0)) then
            activityEnded = false;
        end
        
        if not activityEnded then
            errorcode = 5;  -- 活动未结束，不能领取
            break;
        end
        
        local nFlag = getSbkData();
        if nFlag then
            errorcode = 4;
            break;
        end
        
        if cfg.noticereward then
            CommonFunc.Awards.Give(pActor, cfg.noticereward, GameLog.Log_SBKaward, "沙巴克领奖")
        end
        setSbkAwardFlag(1);
        break;
    end
    -- 回复使用结果
    local npack = DataPack.allocPacket(pActor, enGuildSystemID, sGuildGetSbkAward)
    if npack then
        DataPack.writeByte(npack, errorcode)
        DataPack.flush(npack)
    end
end
```

### 方案2：修改活动结束逻辑

**修改文件：** 
- `data/functions/Activity/ActivityType10.lua`
- `data/functions/Activity/ActivityType27.lua`

**修改位置：** `OnEnd` 函数

**修改内容：**

```lua
function OnEnd(atvId)
    local Cfg = ActivityConfig
    if Cfg then
        -- ... 现有代码 ...
        
        -- 添加：活动结束时重置奖励标志，允许领取
        setSbkAwardFlag(nil);
    end
    
    SbkState = AtvStatus.End
    ActivityDispatcher.ClearCacheData(atvId);
    print("[GActivity 10] 沙巴克 活动结束了，id："..atvId)
end
```

## 📋 实施步骤

### 1. 备份原文件
```bash
# 备份关键文件
cp data/functions/ActorSystems/GuildSystem/guildSystem.lua data/functions/ActorSystems/GuildSystem/guildSystem.lua.backup
cp data/functions/Activity/ActivityType10.lua data/functions/Activity/ActivityType10.lua.backup
cp data/functions/Activity/ActivityType27.lua data/functions/Activity/ActivityType27.lua.backup
```

### 2. 修改配置文件
按照上述方案修改相应的Lua文件。

### 3. 重新加载配置
```bash
# 重启服务器或重新加载配置
# 具体命令根据服务器环境而定
```

### 4. 验证修改效果
- 测试活动进行中无法领取奖励
- 测试活动结束后可以正常领取奖励
- 测试重复领取被正确阻止

## ⚠️ 注意事项

### 1. 测试建议
- **先在测试服务器验证修改效果**
- 测试各种边界情况
- 验证现有玩家的奖励状态

### 2. 数据一致性
- 修改后需要检查现有玩家的奖励领取状态
- 确保不会影响已经正确领取的玩家

### 3. 时间窗口
- 建议在活动结束后立即进行修改
- 避免影响正在进行的活动

### 4. 回滚准备
- 保留原始文件备份
- 准备快速回滚方案

## 🎯 预期效果

修改完成后，沙巴克活动的奖励领取将按照以下逻辑工作：

1. **活动进行中：** 无法领取奖励，显示"活动未结束"提示
2. **活动结束后：** 只有最终占领沙巴克的行会会长可以领取奖励
3. **重复领取：** 已领取的玩家无法再次领取
4. **权限检查：** 只有行会会长可以领取奖励

## 📞 技术支持

如果在实施过程中遇到问题，请检查：
1. 文件路径是否正确
2. 语法是否有错误
3. 服务器日志中的错误信息
4. 玩家客户端的错误提示

---

**文档创建时间：** 2024年12月
**文档版本：** v1.0
**适用版本：** 当前配置版本
