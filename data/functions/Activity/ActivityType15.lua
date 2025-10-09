module("ActivityType15", package.seeall)

--[[
    任务

    个人数据：ActorData[AtvId]
    {
        quest[type]//进度  
        {
        }
        isred[index] 红点数据
        int nFalg //
        limit[itemtype]
        {

        }
    }

    全局缓存：Cache[AtvId]
    {   
        
    }

    全局数据：GlobalData[AtvId]
    {
        int nNumber --期数
        int endTime;
        int nStartTime
    }
]]--

--活动类型
ActivityType = 15
--对应的活动配置
ActivityConfig = Activity15Config
ActivitySetConfig = ActivitysetConfig
if ActivityConfig == nil then
    assert(false)
end

EXP = 10000;

--玩家请求领取奖励
function reqGetAward(pActor, atvId , indexId)
    print("atvId.."..atvId.."..indexId.."..indexId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId);
    if globalData == nil then
        globalData = {}
    end
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData == nil then
        return
    end
    
    local AtvCfg = ActivityConfig[atvId];
    if AtvCfg == nil then
        return 
    end
    
    local Cfg = AtvCfg[(globalData.nNumber or 1)]
    if Cfg then
        Cfg =  AtvCfg[(globalData.nNumber or 1)][indexId]
    end
    
    if Cfg == nil then
        return
    end
   
    local ntype = Cfg.type * EXP + Cfg.subtype
    if actorData.quest[ntype] == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:条件未达成|", tstUI)
        return
    end
    --提示已领取无法多次领取
    if System.getIntBit((actorData.nFlag or 0),indexId)  == 1  then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:您已领取该奖励|", tstUI)
        return 
    end 
    
    if (actorData.quest[ntype] < Cfg.value) then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:条件未达成|", tstUI)
        return 
    end
    local SetCfg = ActivitySetConfig[atvId]
    if SetCfg == nil then
        return 
    end
    local setCfg = SetCfg[(globalData.nNumber or 1)];
    if setCfg == nil then
        return 
    end
    
    --检查格子够不够
    if setCfg.VIPbagremain and setCfg.VIPtips then
        if CommonFunc.Awards.CheckBagIsEnough(pActor,setCfg.VIPbagremain,setCfg.VIPtips,tstUI) ~= true then
            return
        end
    end
            
    if actorData.limit == nil then
        actorData.limit = {}
    end
    local gift1 = getAwardCfg(Cfg)
    if gift1 then
        CommonFunc.GiveCommonAward(pActor, gift1, GameLog.Log_Activity15,  "战令任务|"..atvId)
    end

    local gift2 = getLimitAwardCfg(Cfg, actorData.limit)

    if gift2 and #gift2 > 0 then
        CommonFunc.GiveCommonAward(pActor, gift2, GameLog.Log_Activity15,  "战令任务|"..atvId)

        for i, data in pairs(gift2) do
            actorData.limit[i] =  (actorData.limit[i] or 0) + data.count;
        end
    end

    actorData.nFlag = System.setIntBit(actorData.nFlag, indexId, 1) --将indexId位置置为1
     -- 记录日志
     Actor.SendActivityLog(pActor,atvId,ActivityType,2)

    UpdateActivity(pActor, atvId)
    Actor.sendTipmsgWithId(pActor, tmMailGetItemSuccess, tstUI)
    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
end

function getAwardCfg(Cfg)
    if Cfg.GiftTable then
        if Cfg.UpperLimit then
            local award1 = {}
            for i, cfg in pairs(Cfg.GiftTable) do
                if Cfg.UpperLimit[i] == nil then
                    table.insert(award1, cfg)
                end
            end
            return award1;
        else
            return Cfg.GiftTable
        end
    end
    return nil
end


function getLimitAwardCfg(Cfg, nLimitData)
    if Cfg.GiftTable then
        local award1 = {}
        for i, cfg in pairs(Cfg.GiftTable) do
            if Cfg.UpperLimit and Cfg.UpperLimit[i] then
                local nLeftCount = Cfg.UpperLimit[i]
                if nLimitData and nLimitData[i] then
                    nLeftCount = nLeftCount - nLimitData[i]
                end

                if nLeftCount > cfg.count then
                    nLeftCount = cfg.count;
                end

                if nLeftCount > 0 then
                    local award2 = {} 
                    award2.type = cfg.type
                    award2.id = cfg.id
                    award2.count = nLeftCount
                    award1[i] = award2
                end
            end
        end
        return award1;
    end
    return nil
end


function UpdateActivity(pActor, atvId)
    if ActivitiesConf[atvId] then
        if ActivitiesConf[atvId].activityid then
            for _, id in pairs(ActivitiesConf[atvId].activityid) do
                -- local atvType = 0
                -- if (ActivitiesConf[id] and ActivitiesConf[id].ActivityType) then
                --     atvType = ActivitiesConf[id].ActivityType
                -- end
                Actor.sendActivityData(pActor, id)
                -- ActivityDispatcher.OnEvent(OnUpdateActivity, atvType,id,pActor);
            end
        end
    end
end

--玩家消耗道具 完成任务
function deleteItemToComplete(pActor, atvId , indexId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId);
    if globalData == nil then
        globalData = {}
    end
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData == nil then
        return
    end
    local AtvCfg = ActivityConfig[atvId];
    if AtvCfg == nil then
        return 
    end

    local Cfg = AtvCfg[(globalData.nNumber or 1)]
    if Cfg then
        Cfg =  AtvCfg[(globalData.nNumber or 1)][indexId]
    end

    if Cfg == nil then
        return
    end
    
    if Cfg.data == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:当前任务无需贡献|", tstUI)
        return 
    end
    local ntype = Cfg.type * EXP + Cfg.subtype

    --提示已领取无法多次领取
    if System.getIntBit((actorData.nFlag or 0),indexId)  == 1  then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:当前任务已领取|", tstUI)
        return 
    end 
    if CommonFunc.Consumes.CheckActorSources(pActor,  Cfg.data, tstUI) ~= true then
        -- Actor.sendTipmsgWithId(pActor, tmNeedItemNotEnough, tstUI)
        return
    end

    CommonFunc.Consumes.Remove(pActor, Cfg.data, GameLog.Log_Activity15, "完成任务|"..atvId)
    actorData.quest[ntype] = (actorData.quest[ntype] or 0) + Cfg.value;

    -- 记录日志
    Actor.SendActivityLog(pActor,atvId,ActivityType,2)

    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
end


function getTypeCfg(atvId, nType, nSubType, nNumber)
    local AtvCfg = ActivityConfig[atvId]
    if AtvCfg then
        local Cfg = AtvCfg[nNumber];
        if Cfg then
            for _, cfg in pairs(Cfg) do
                if cfg.type == nType and cfg.subtype == nSubType then
                    return cfg;
                end
            end
        end
    end
    return nil;
end
--------------------------我是分界线----------------------------
-- 初始化玩家数据
function OnInit(atvId, pActor)
    print("[GActivity 15]  任务活动"..Actor.getName(pActor).." 初始化 id："..atvId)
    ActivityDispatcher.ClearActorData(pActor, atvId)                
end

--活动开始
function OnStart(atvId, pActor)
    print("[activitytype 15] 任务活动---onstart  atvId:"..atvId)

    ActivityDispatcher.ClearGlobalData(atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId);
    if globalData == nil then
        globalData = {}
    end
    if globalData.openTimes == nil then
        local currentId = System.getCurrMiniTime();
        globalData.openTimes = currentId
    end
    --初始化
    local openDay = System.getDaysSinceOpenServer();
    local SetCfg = ActivitySetConfig[atvId];
    if SetCfg == nil then
        return 
    end

    for _, cfg in pairs(SetCfg) do
        if openDay >= cfg.openday then
            globalData.nNumber = cfg.number;
        end
    end

    globalData.nStartTime = System.getCurrMiniTime();
    
end


-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cGetQuestAward then --请求奖励奖励
        local indexId = DataPack.readByte(inPack)
        reqGetAward(pActor, atvId , indexId)
    elseif operaCode == ActivityOperate.cDeleteItem then --提交道具
        local indexId = DataPack.readByte(inPack)
        deleteItemToComplete(pActor, atvId ,indexId)
    end
end


-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    -- print("[activitytype 15 任务活动 id:.."..atvId.."请求数据]")

    if outPack == nil then
        return
    end
    local globalData = ActivityDispatcher.GetGlobalData(atvId);
    if globalData == nil then
        globalData = {}
    end
    local AtvCfg = ActivityConfig[atvId]

    if AtvCfg == nil then
        return
    end
    local Cfg = AtvCfg[(globalData.nNumber or 1)]
    local len = 0;

    if Cfg then
        len = #Cfg;
    end
    DealNewDay(pActor, atvId, System.getCurrMiniTime())
    --长度
    DataPack.writeByte(outPack, (globalData.nNumber or 1))  
    DataPack.writeByte(outPack, (len or 0))
    if Cfg then

        
        local endtime = System.getActivityEndMiniSecond(atvId);
        if globalData.endTime then
            if globalData.endTime ~= endtime then
                ActivityDispatcher.ClearActorData(pActor, atvId)
            end
        end

        local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
        if actorData == nil then
            actorData = {}
        end

        if globalData.endTime == nil then
            globalData.endTime = endtime;
        end

        if actorData.quest == nil then
            actorData.quest = {};
        end

        -- DataPack.writeInt(outPack, (actorData.nValue or 0))  
        for _, cfg in pairs(Cfg) do
            DataPack.writeByte(outPack, cfg.taskID)
            local value = cfg.type * EXP + cfg.subtype;
            -- print("actorData.quest[value].."..(actorData.quest[value] or 0))
            DataPack.writeInt(outPack, (actorData.quest[value] or 0))  
            local res = System.getIntBit((actorData.nFlag or 0), cfg.taskID)

            if res == 1 then res = 2; end
            if res == 0 and (actorData.quest[value] and actorData.quest[value] >= cfg.value) then res = 1; end
            DataPack.writeByte(outPack, res)
        end
    end
end


-- 活动结束
function OnEnd(atvId, pActor)
    print("[PActivity 15] 活动id.."..atvId.."..结束")
    -- ActivityDispatcher.ClearActorData(pActor, atvId)
end

--活动红点
function OnGetRedPoint(atvId, pActor)
    local ret = 0
    local AtvCfg = ActivityConfig[atvId]
    if AtvCfg == nil then
        return
    end
    local globalData = ActivityDispatcher.GetGlobalData(atvId);
    if globalData == nil then
        globalData = {}
    end
    local Cfg = AtvCfg[(globalData.nNumber or 1)]
    if Cfg == nil then
        return
    end
    DealNewDay(pActor, atvId, System.getCurrMiniTime())
    local len = 0;
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    if actorData == nil then
        actorData = {}
    end

    if actorData.quest == nil then
        actorData.quest = {}
    end

    for _, cfg in pairs(Cfg) do
        local ntype = cfg.type * EXP + cfg.subtype
        if actorData.quest[ntype] then
            if actorData.quest[ntype] >= cfg.value then
                local res = System.getIntBit((actorData.nFlag or 0), cfg.taskID) --对应位为1表示该奖励可领取
                if res == 0 then  ret = 1  break end;
            end 
        end
    end 
    return ret
end

---更新活动数据
function OnUpdateActivity(atvId, pActor, nType, nSubType, nValue)
    local globalData = ActivityDispatcher.GetGlobalData(atvId);
    if globalData == nil then
        globalData = {}
    end
    if nType == 17 and nSubType == 35 then
        nSubType = 11
    end
    -- print("atvId.."..atvId.."..nType.."..nType.."..nSubType.."..nSubType.."..num.."..(globalData.nNumber or 1))
   local Cfg = getTypeCfg(atvId, nType, nSubType, (globalData.nNumber or 1));
    if Cfg == nil then
        return 
    end
    DealNewDay(pActor, atvId, System.getCurrMiniTime())

    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)

    if actorData == nil then
        actorData = {}
    end
    if actorData.quest == nil then
        actorData.quest = {};
    end
    -- print("[PActivity 15] 活动id.."..atvId.."..结束")
    local ntype = nType * EXP + nSubType;

    if Cfg.ValueType == 1 then
        actorData.quest[ntype] = (actorData.quest[ntype] or 0) + nValue
    else
        actorData.quest[ntype] = nValue;
    end

    local ret = 0
    local AtvCfg = ActivityConfig[atvId]
    if AtvCfg == nil then
        return
    end
    local globalData = ActivityDispatcher.GetGlobalData(atvId);
    if globalData == nil then
        globalData = {}
    end
    local Cfg = AtvCfg[(globalData.nNumber or 1)]
    if Cfg == nil then
        return
    end

    if actorData.isred == nil then
        actorData.isred = {}
    end

    for _, cfg in pairs(Cfg) do
        if cfg.type == nType and cfg.subtype == nSubType then

            if actorData.quest[ntype] >= cfg.value and actorData.isred[cfg.taskID] == nil then
                actorData.isred[cfg.taskID] = 1
                local res = System.getIntBit((actorData.nFlag or 0), cfg.taskID) --对应位为1表示该奖励可领取
                if res == 0 then
                    Actor.sendActivityData(pActor, atvId)
                end
            end 
        end
           
    end 
end

function DealNewDay(pActor, atvId, curTime)
    if (ActivitiesConf[atvId] and ActivitiesConf[atvId].Resettask) then
        local actorData = ActivityDispatcher.GetActorData(pActor, atvId);
        if actorData == nil then
            return
        end

        if System.isSameDay( (actorData.nStartTime or 0), curTime) == true then
            return
        end
        ActivityDispatcher.ClearActorData(pActor, atvId)
        actorData.nStartTime = curTime;
    end
end
function OnUpdate(atvId, curTime)
    local globalData = ActivityDispatcher.GetGlobalData(atvId);
    if globalData == nil then
        return
    end

    if System.isSameDay( (globalData.nStartTime or 0), curTime) == true then
        return
    end
    System.sendAllActorOneActivityData(atvId);
    globalData.nStartTime = curTime
end

ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType15.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType15.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType15.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType15.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType15.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType15.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdateActivity, ActivityType, OnUpdateActivity, "ActivityType15.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType15.lua")



-- -- 跨天，次数清零
-- function OnNewDayArrive(pActor)
--     local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
--     if runAtvIdList == nil then
--         return
--     end
--     for i,atvId in ipairs(runAtvIdList) do
--         if (ActivitiesConf[atvId] and ActivitiesConf[atvId].Resettask) then
--             ActivityDispatcher.ClearActorData(pActor, atvId)
--         end
--     end
-- end

-- ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType15.lua")