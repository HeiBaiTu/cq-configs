module("ActivityType17", package.seeall)

--[[
    全局活动
    兑换活动

    个人数据：ActorData[AtvId]
    {
        ActorDaily {} //每日限次
        Limits {} //总现在
    }

    全局缓存：Cache[AtvId]
    {   
        
    }

    全局数据：GlobalData[AtvId]
    {
        GlobalDaily {} //每日限次
    }
]]--

--活动类型
ActivityType = 10017
--对应的活动配置
ActivityConfig = Activity10017Config
if ActivityConfig == nil then
    assert(false)
end

--兑换
function reqExChange(pActor, atvId , idx)
    local AtvCfg = ActivityConfig[atvId]
    if AtvCfg and AtvCfg[idx] then
        -- print("111idx..."..idx)
        local Cfg = AtvCfg[idx]
        local nOpenDay = System.getDaysSinceOpenServer();
        local actorData = ActivityDispatcher.GetActorData(pActor, atvId)

        if actorData.ActorDaily == nil then
            actorData.ActorDaily = {}
        end
        if actorData.Limits == nil then
            actorData.Limits = {}
        end
        if Cfg.table then
            if CommonFunc.Consumes.CheckActorSources(pActor, Cfg.table ,tstUI) ~= true then
                return
            end
        end
        -- print("222idx..."..idx)
        local usetimes = getUseTimes(pActor, atvId, Cfg);
        if Cfg.times and usetimes >= Cfg.times then
            Actor.sendTipmsgWithParams(pActor, tmActivity10017LimitTimes,tstUI);
            return
        end
        -- print("333idx..."..idx)
        if Cfg.mergelimit then
            if Actor.checkCommonLimit(pActor,(Cfg.mergelimit.level or 0), (Cfg.mergelimit.zsLevel or 0),
            (Cfg.mergelimit.vip or 0), (Cfg.mergelimit.office or 0)) == false then
                Actor.sendTipmsgWithParams(pActor, tmActivity10017Limit,tstUI);
                return;
            end
            if (Cfg.mergelimit.openday or 0) > nOpenDay then
                Actor.sendTipmsgWithParams(pActor, tmActivity10017Limit,tstUI);
                return;
            end

        end
        -- print("4444idx..."..idx)
        if CommonFunc.Awards.CheckBagIsEnough(pActor,Cfg.bagtype,tmActivity10017LimitBags,tstUI) ~= true then
            return
        end
        --扣除消耗
        if Cfg.table then
            if CommonFunc.Consumes.Remove(pActor, Cfg.table, GameLog.Log_Activity10017, "兑换活动|"..atvId) ~= true then
                return
            end
        end
       
        if Cfg.times then
            if Cfg.timesclear then
                actorData.ActorDaily[Cfg.subid] = (actorData.ActorDaily[Cfg.subid] or 0) + 1;
            else
                actorData.Limits[Cfg.subid] = (actorData.Limits[Cfg.subid] or 0) + 1;
            end
        end
        
        CommonFunc.Awards.Give(pActor, Cfg.compose, GameLog.Log_Activity10017)
        Actor.sendTipmsgWithParams(pActor, tmActivity10017OperateSuccess,tstUI);
        -- 记录日志
        Actor.SendActivityLog(pActor,atvId,ActivityType,2)
        if Cfg.tips then
            local name = Actor.getName(pActor);
            local str = string.format(Cfg.tips,name)
            System.broadcastTipmsgLimitLev(str, tstKillDrop)
        end
    end 
    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
end 

function getUseTimes(pActor,atvId, Cfg)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    local usetimes = 0;
    if Cfg.times then
        if Cfg.timesclear then
            usetimes = actorData.ActorDaily[Cfg.subid] or 0;
        else
            usetimes = actorData.Limits[Cfg.subid] or 0;
        end
    end
    return usetimes;
end



--------------------------我是分界线----------------------------

-- 初始化玩家数据
function OnInit(atvId, pActor) 
    print("[GActivity 17]  兑换活动"..Actor.getName(pActor).." 初始化 id："..atvId)
    ActivityDispatcher.ClearActorData(pActor, atvId)                      
end

--活动开始
function OnStart(atvId)
    print("[GActivity 17]兑换活动id："..atvId.."开始了!")
    ActivityDispatcher.ClearGlobalData(atvId);
end


-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cReqExchange then --捐献
        local idx = DataPack.readByte(inPack)
        reqExChange(pActor, atvId , idx)
    end
end


-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    local Cfg = ActivityConfig[atvId]
    if Cfg == nil then 
        return;
    end
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    
    local actorId = Actor.getIntProperty(pActor, PROP_ENTITY_ID )
    local donateValue = 0;
    if actorData.ActorDaily == nil then
        actorData.ActorDaily = {};
    end
    if actorData.Limits == nil then
        actorData.Limits = {}
    end
    if outPack then  
        DataPack.writeInt(outPack, (#Cfg or 0))
        for _, cfg in ipairs(Cfg) do
            local lefttimes = -1;
            local usetimes = getUseTimes(pActor, atvId, cfg);
            lefttimes = cfg.times - (usetimes or 0)
            DataPack.writeByte(outPack, (cfg.subid or 0))
            DataPack.writeInt(outPack, (lefttimes or 0))
        end
    end
end


-- 活动结束
function OnEnd(atvId)
    ActivityDispatcher.ClearGlobalData(atvId)
end

ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType10017.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType10017.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType10017.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType10017.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType10017.lua")

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 跨天，次数清零
function OnNewDayArrive(pActor,ndiffday)
    print("[PActivity 17] "..Actor.getName(pActor).." 跨"..ndiffday.."天")
    local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
    if runAtvIdList == nil then 
        return 
    end
    for i,atvId in ipairs(runAtvIdList) do
        -- 发送一个活动数据
        local data = ActivityDispatcher.GetActorData(pActor,atvId)
        if data == nil then
            data = {}
        end
        data.ActorDaily = {}
        Actor.sendActivityData(pActor, atvId)
    end
end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10017.lua")