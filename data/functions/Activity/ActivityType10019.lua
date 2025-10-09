module("ActivityType10019", package.seeall)

--[[
    个人活动
    达标类

    个人数据：ActorData[AtvId]
    {
        int nFlag // 标志
        int nValue //进度
        int endtime
        nNewFlag[]
        {
            nNewFlag
        }
        firstTips
        {}
        dealclear --标志
        gettimes --已经领取的数量
    }

    全局缓存：Cache[AtvId]
    {   
        
    }

    全局数据：GlobalData[AtvId]
    {
    }
]]--

--活动类型
ActivityType = 10019
--对应的活动配置
ActivityConfig = Activity10019Config
if ActivityConfig == nil then
    assert(false)
end


--玩家请求领取奖励
function reqGetAward(pActor, atvId , indexId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData == nil then
        return
    end
    local Cfg = getIndexCfg(atvId, indexId);
    if Cfg == nil then
        return 
    end
    
    local data = actorData[Cfg.subtype]
    if data == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:条件未达成|", tstUI)
        return
    end
    --提示已领取无法多次领取
    local res = GetBitData(atvId, pActor,indexId);
    -- if System.getIntBit((actorData.nFlag or 0),indexId)  == 1  then 
    if res == 1 then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:您已领取该奖励|", tstUI)
        return 
    end 
    
    if (data.nValue == nil) or (data.nValue < Cfg.value) then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:条件未达成|", tstUI)
        return 
    end
    --检查格子够不够
    if CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmGiftNoBagNum,tstUI) ~= true then
        return
    end
    if Cfg.GiftTable then
        local decstr = "个人达标类活动";
        if ActivitiesConf[atvId] and ActivitiesConf[atvId].ActivityName then
            decstr = ActivitiesConf[atvId].ActivityName
        end
        CommonFunc.Awards.Give(pActor, Cfg.GiftTable, GameLog.Log_Activity10019,  decstr)
    end
    actorData.gettimes = (actorData.gettimes or 0) +1
    SetBitData(atvId, pActor, indexId);
    Actor.sendTipmsgWithId(pActor, tmMailGetItemSuccess, tstUI)
    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
    if Cfg.tips then
        local name = Actor.getName(pActor);
        local str = string.format(Cfg.tips,name)
        System.broadcastTipmsgLimitLev(str, tstKillDrop)
    end
    Actor.SendJoinActivityLog(pActor,atvId,indexId);--领奖
    -- 记录日志
    Actor.SendActivityLog(pActor,atvId,ActivityType,2)
    actorData.dealclear = 1;
    print("atvId : ".." name : "..Actor.getName(pActor).." gettimes.."..actorData.gettimes)
end

--
function getIndexCfg(atvId, indexId)
    if ActivityConfig then
        local Cfg = ActivityConfig[atvId];
        if Cfg then
            for _, cfg in pairs(Cfg) do
                if cfg.level == indexId then
                    return cfg;
                end
            end
        end
    end
    return nil;
end


function getTypeCfg(atvId, nType, nSubType)
    if ActivityConfig then
        local Cfg = ActivityConfig[atvId];
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

--活动开始
function OnStart(atvId, pActor)
    print("[pActivitytype10019活动]---onstart  atvId:"..atvId)
end


-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cReqGetAchieveAward then --请求领取基金奖励
        local indexId = DataPack.readInt(inPack)
        reqGetAward(pActor, atvId , indexId)
    end
end


function GetBitData(atvId, pActor, level)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData == nil then
        actorData = {}
    end 
    local nFlag = 0;
    if level < 32 then
        nFlag = System.getIntBit((actorData.nFlag or 0), level)
    else
        if actorData.nNewFlag == nil then
            actorData.nNewFlag = {}
        end
        if actorData.nNewFlag[level] == nil then
            actorData.nNewFlag[level] = 0
        end

        nFlag =actorData.nNewFlag[level] or 0;
    end
    return nFlag;
end

function SetBitData(atvId, pActor, level)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData == nil then
        actorData = {}
    end  
    if level < 32 then
        actorData.nFlag = System.setIntBit(actorData.nFlag, level, 1) --将indexId位置置为1
    else
        if actorData.nNewFlag == nil then
            actorData.nNewFlag = {}
        end
        if actorData.nNewFlag[level] == nil then
            actorData.nNewFlag[level] = 0
        end
        actorData.nNewFlag[level] = 1;
    end
end

-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    if outPack == nil then
        return
    end
    DealClearAtvData(pActor, atvId);
    local Cfg = ActivityConfig[atvId]
    local len = 0;

    if Cfg then
        len = #Cfg;
    end

    --长度
    -- print("len.."..(len or 0));
    DataPack.writeInt(outPack, (len or 0))  
    local getNum = 0;
    if Cfg then
        local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
        if actorData == nil then
            actorData = {}
        end  
        for _, cfg in pairs(Cfg) do
            local value = 0;
            local data = actorData[cfg.subtype]
            if data then
                value = data.nValue or 0
            end
            local res =GetBitData(atvId, pActor, cfg.level);
            if res == 1 then getNum = getNum + 1 end
            if res == 1 then res = 2; end
            if res == 0 and value >= cfg.value then res = 1; end
            DataPack.writeByte(outPack, res)
            DataPack.writeInt(outPack, cfg.level)
            DataPack.writeInt(outPack, value) 
        end
        if (actorData.gettimes or 0) < getNum then
            print("[pActivity10019] OnReqData() 活动id.."..atvId.." name : "..Actor.getName(pActor).." (actorData.gettimes or 0) : "..(actorData.gettimes or 0).."getNum : "..getNum)
            actorData.gettimes = getNum
        end
    end
end
--处理清空逻辑
function DealClearAtvData(pActor, atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData == nil then
        actorData = {}
    end
    local Cfg = ActivityConfig[atvId]
    local getNum = 0;
    if Cfg then
        for _, cfg in pairs(Cfg) do
            local res = GetBitData(atvId, pActor, cfg.level);
            if res == 1 then getNum = getNum + 1 end
        end
    end

    if (actorData.gettimes or 0) < getNum then
        print("[pActivity10019] DealClearAtvData() 活动id.."..atvId.." name : "..Actor.getName(pActor).." (actorData.gettimes or 0) : "..(actorData.gettimes or 0).."getNum : "..getNum)
        actorData.gettimes = getNum
    end
    if (actorData.dealclear == nil and PActivitiesConf[atvId] and PActivitiesConf[atvId].isReset) and (actorData.gettimes and actorData.gettimes >= #Cfg) then
        print(Actor.getName(pActor).."..ClearActorData.."..atvId.."..gettimes.."..(actorData.gettimes or 0).."..#Cfg.."..(#Cfg or 0))
        ActivityDispatcher.ClearActorData(pActor, atvId);
    end
end

-- 活动结束
function OnEnd(atvId, pActor)
    print("[pActivity10019] 活动id.."..atvId.."..结束")
    ActivityDispatcher.ClearGlobalData(atvId)
end

--活动红点
function OnGetRedPoint(atvId, pActor)
    local ret = 0
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    local Cfg = ActivityConfig[atvId]
    if Cfg == nil then
        return 
    end
    if actorData == nil then
        actorData = {}
    end

    for _, cfg in pairs(Cfg) do
        local data = actorData[cfg.subtype]
        if data and data.nValue then
            if data.nValue >= cfg.value then
                local res =GetBitData(atvId, pActor, cfg.level);
                if res == 0 then  ret = 1  break end;
            end 
        end
    end 
    return ret
end

function UpdateData(atvId, pActor, nType, nSubType,nValue)
    local Cfg = getTypeCfg(atvId, nType,nSubType);
    if Cfg == nil then
        return 
    end
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)

    if actorData == nil then
        actorData = {}
    end
    if actorData[nSubType] == nil then
        actorData[nSubType] = {};
    end
    if actorData[nSubType].nValue == nil then
        actorData[nSubType].nValue = 0;
    end
    if Cfg.ValueType == 1 then
        actorData[nSubType].nValue = actorData[nSubType].nValue + nValue;
    else
        if actorData[nSubType].nValue < nValue then
            actorData[nSubType].nValue = nValue;
        end
    end
    if Cfg.firsttips then
        local res = GetBitData(atvId, pActor, Cfg.level); 
        if actorData.firstTips == nil then
            actorData.firstTips = {}
        end
        if (actorData[nSubType].nValue >= Cfg.value) and (res == 0) then
            if actorData.firstTips[Cfg.level] == nil then
                local dropType = 1;
                if nType == nAchieveDropItem then
                    dropType = 2;
                end
                local msg = "";
                msg = msg..dropType.."\\"..Cfg.firsttips
                -- print("msg.."..msg)
                Actor.sendTipmsg(pActor,msg, tstFirstKillDrop);
                actorData.firstTips[Cfg.level] = 1;
            end
        end
    end
end
---更新活动数据
function OnUpdateActivity(atvId, pActor, nType, nSubType, nValue)
    if nAchieveEquipment == nType then
        local Cfg = ActivityConfig[atvId];
        if Cfg then
            for _, cfg in pairs(Cfg) do
                if cfg.type == nType and cfg.subtype <= nSubType then
                    UpdateData(atvId, pActor, nType, cfg.subtype, nValue);
                end
            end
        end
    else
        UpdateData(atvId, pActor, nType, nSubType,nValue);
    end
    
    Actor.sendActivityData(pActor, atvId)
end

ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType10019.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType10019.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType10019.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType10019.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType10019.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdateActivity, ActivityType, OnUpdateActivity, "ActivityType10019.lua")



-- 跨天，次数清零
function OnNewDayArrive(pActor,ndiffday)
    print("[PActivity 10019] "..Actor.getName(pActor).." 跨"..ndiffday.."天")
    local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
    if runAtvIdList == nil then return end
    for i,atvId in ipairs(runAtvIdList) do
        local data = ActivityDispatcher.GetActorData(pActor,atvId)
        local Cfg = ActivityConfig[atvId];
        if (PActivitiesConf[atvId] and PActivitiesConf[atvId].isReset) and (data.gettimes and data.gettimes >= #Cfg) then
            print(Actor.getName(pActor).."..ClearActorData.."..atvId.."..gettimes.."..(data.gettimes or 0).."..#Cfg.."..(#Cfg or 0))
            ActivityDispatcher.ClearActorData(pActor, atvId);
        end
        -- 发送一个活动数据
        Actor.sendActivityData(pActor, atvId)
    end
end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10019.lua")