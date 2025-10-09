module("ActivityType10009", package.seeall)

--[[
    全局活动
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
    }

    全局缓存：Cache[AtvId]
    {   
        
    }

    全局数据：GlobalData[AtvId]
    {
    }
]]--

--活动类型
ActivityType = 10009
--对应的活动配置
ActivityConfig = Activity10009Config
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
        local decstr = "达标类活动";
        if ActivitiesConf[atvId] and ActivitiesConf[atvId].ActivityName then
            decstr = ActivitiesConf[atvId].ActivityName
        end
        -- print("decstr.."..decstr);
        --CommonFunc.GiveCommonAward(pActor, Cfg.GiftTable, GameLog.Log_Activity10009,  "达标类活动 | " .. atvId)
        CommonFunc.Awards.Give(pActor, Cfg.GiftTable, GameLog.Log_Activity10009,  decstr)
    end

    -- actorData.nFlag = System.setIntBit(actorData.nFlag, indexId, 1) --将indexId位置置为1
    -- print("indexId..."..indexId)
    SetBitData(atvId, pActor, indexId);
    Actor.sendTipmsgWithId(pActor, tmMailGetItemSuccess, tstUI)
    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
    if Cfg.tips then
        local name = Actor.getName(pActor);
        local str = string.format(Cfg.tips,name)
        System.broadcastTipmsgLimitLev(str, tstKillDrop)
    end
    -- 记录日志
    Actor.SendActivityLog(pActor,atvId,ActivityType,2)
    Actor.SendJoinActivityLog(pActor,atvId,indexId);--领奖
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
-- 初始化玩家数据
function OnInit(atvId, pActor)
    print("[GActivity 10006]  达标类活动"..Actor.getName(pActor).." 初始化 id："..atvId)
    ActivityDispatcher.ClearActorData(pActor, atvId)                
end

--活动开始
function OnStart(atvId, pActor)
    print("[activitytype 10009] 达标类活动---onstart  atvId:"..atvId)
    -- ActivityDispatcher.ClearActorData(pActor, atvId)
    
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
    -- print("[PActivity10009 达标类活动 id:.."..atvId.."请求数据]")

    if outPack == nil then
        return
    end

    local Cfg = ActivityConfig[atvId]
    local len = 0;

    if Cfg then
        len = #Cfg;
    end

    --长度
    -- print("len.."..(len or 0));
    DataPack.writeInt(outPack, (len or 0))  
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
            -- local res = System.getIntBit((actorData.nFlag or 0), cfg.level)

            if res == 1 then res = 2; end
            if res == 0 and value >= cfg.value then res = 1; end
            DataPack.writeByte(outPack, res)
            DataPack.writeInt(outPack, cfg.level)
            DataPack.writeInt(outPack, value) 
            -- print("cfg.level.."..(cfg.level or 0));
        end
    end
end

-- 活动结束
function OnEnd(atvId, pActor)
    print("[PActivity 10009] 活动id.."..atvId.."..结束")
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
                -- local res = System.getIntBit((actorData.nFlag or 0), cfg.level) --对应位为1表示该奖励可领取
                if res == 0 then  ret = 1  break end;
            end 
        end
    end 
    return ret
end

function nextActivityClear(pActor,atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    local atvendTime = System.getActivityEndMiniSecond(atvId);
    if actorData == nil then
        actorData = {}
    end
    if actorData.endtime ==nil then 
        actorData.endtime = 0 ; 
    end 
    
    --跨月了，数据清空
    if actorData.endtime ~= atvendTime then 
        ActivityDispatcher.ClearActorData(pActor,atvId)
        local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
        if actorData == nil then
            actorData = {}
        end
        print("nextActivityClear endtime.."..(actorData.endtime or 0).."..atvendTime.."..(atvendTime or 0))
        actorData.endtime = atvendTime;
    end 
end 

function OnLoginGame(atvId,pActor)
    -- nextActivityClear(pActor, atvId)
end 

function UpdateData(atvId, pActor, nType, nSubType,nValue)
    local Cfg = getTypeCfg(atvId, nType,nSubType);
    if Cfg == nil then
        return 
    end

    -- print("OnUpdateActivity.."..atvId.."..nType.."..nType..".nSubType.."..nSubType.."..nValue.."..nValue)
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
    -- local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
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

ActivityDispatcher.Reg(ActivityEvent.OnLoginGame, ActivityType, OnLoginGame, "ActivityType10009.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType10009.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType10009.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType10009.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType10009.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType10009.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType10009.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdateActivity, ActivityType, OnUpdateActivity, "ActivityType10009.lua")