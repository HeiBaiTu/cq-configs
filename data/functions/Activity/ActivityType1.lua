module("ActivityType1", package.seeall)

--[[
    个人活动，打副本刷怪的活动
    通关才扣取进入消耗及次数；
    次数每天叠加不清空；
    
    个人数据：ActorData[AtvId]
    {
        count,      当前的可进入次数
    }
]]--

--活动类型
ActivityType = 1
--对应的活动配置
ActivityConfig = Activity1Config
if ActivityConfig == nil then
    assert(false)
end

--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------

--请求进入副本
function reqEnterFuben(pActor, atvId, Conf, inPack)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    
    --消耗检查
    local consumes = nil
    if Conf.enterExpends then
        consumes = Conf.enterExpends
        if CommonFunc.Consumes.Check(pActor, consumes) ~= true then
            Actor.sendTipmsgWithId(pActor, tmNeedItemNotEnough, tstUI)
            return
        end
    end

    --次数检查
    if data.count == nil then
        data.count = Conf.count
    else
        if data.count <= 0 then
            --Actor.sendTipmsg(pActor, "次数没了！", tstUI)
            Actor.sendTipmsgWithId(pActor, tmNoTimes, tstUI)--次数不足
            return
        end
    end
    
    --进入副本
    ActivityDispatcher.EnterFuben(atvId, pActor, Conf.fbId)
end

--------------------------------------------------------------------
-- 活动 回调注册
--------------------------------------------------------------------

-- 活动开始
function OnStart(atvId, pActor)
    --初始化活动个人数据
    ActivityDispatcher.ClearActorData(pActor, atvId)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    local multi = 1
    if ActivityConfig[atvId].isFromOpenSrv then
        multi = System.getDaysSinceOpenServer()
    end
    data.count = multi * (ActivityConfig[atvId].count or 1)
end

-- 活动结束
function OnEnd(atvId, pActor)
    ActivityDispatcher.ClearActorData(pActor, atvId)
end

-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    DataPack.writeInt(outPack, (data.count or 0))
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- id对应配置
    local Conf = ActivityConfig[atvId]
    if Conf == nil then
        print("[PActivity 1] "..Actor.getName(pActor).." 活动配置中找不到活动id："..atvId)
    end
    
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cEnterFuben then     -- 请求进入副本
        reqEnterFuben(pActor,atvId,Conf,inPack)
    end
end

--玩家退出活动副本
function OnExitFuben(atvId, pActor, pFuben, pOwner)
    -- 通关后才消耗门票跟次数
    if FubenDispatcher.GetReault(pFuben) == 1 then
        local data = ActivityDispatcher.GetActorData(pActor,atvId)
        local Conf = ActivityConfig[atvId]

        -- 补充退出结算
        OnReqFubenAward(atvId, pFuben, pActor, pActor)

        -- 消耗次数
        data.count = data.count - 1

        -- 消耗门票
        local consumes = Conf.enterExpends
        if consumes then
            CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity1, "刷怪副本类活动|"..atvId)
        end
        
        -- 记录日志
        Actor.SendActivityLog(pActor,atvId,ActivityType,2)

        -- 发送一个活动数据
        Actor.sendActivityData(pActor, atvId)
    end
end

--活动副本结束
function OnFubenFinish(atvId, pFuben, result, pOwner)
    --发送成功失败的旗帜
    if pOwner then
        if result == 1 then
            --完成副本任务
            Actor.ExOnQuestEvent(pOwner, CQuestData.qtFuben, 1);
            Actor.triggerAchieveEvent(pOwner, nAchieveActivity,1 ,atvId);
            Actor.triggerAchieveEvent(pOwner, nAchieveCompleteActivity,1 ,atvId);
        end
        local npack = ActivityDispatcher.AllocResultPack(pOwner, atvId, result)
        if npack then
            DataPack.flush(npack)
        end
    end
end

--活动请求结算
function OnReqFubenAward(atvId, pFuben, pActor, pOwner)
    -- 单人副本活动，所有者必须为自己
    if pOwner == pActor then
        if FubenDispatcher.GetReault(pFuben) == 1 then
            local fbcache = FubenDispatcher.GetCacheData(pFuben)
            if not fbcache.hasGetAward then
                local awards = ActivityConfig[atvId].Persongift
                -- if CommonFunc.Awards.CheckBagGridCount(pActor,awards) ~= true then
                --     return
                -- end
                if CommonFunc.Awards.Give(pActor, awards, GameLog.Log_Activity1, "Activity1|"..atvId, -1 ) == true  then 
                    Actor.sendTipmsg(pActor, "成功领取奖励！", tstGetItem)
                    fbcache.hasGetAward = 1
                end 
            end
        end
    end
end

--活动红点数据
function OnGetRedPoint(atvId, pActor)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    local ret = 0
    if data.count and (data.count > 0) then ret = 1 end
    local limitLv = 0;
    local cfg = ActivityConfig[atvId]
    if cfg and cfg.openParam then
        limitLv =  (cfg.openParam.level or 0)
    end
    local lv = Actor.getIntProperty( pActor, PROP_CREATURE_LEVEL )
    if lv < limitLv then ret = 0 end
    return ret
end

function OnCombineSrv(atvId, ndiffDay, pActor)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    if data.count == nil then
        data.count = 0
    end
    
    data.count = data.count + (2 * ndiffDay)
    
    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)


end 
ActivityDispatcher.Reg(ActivityEvent.OnCombineSrv, ActivityType, OnCombineSrv, "ActivityType1.lua")

ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType1.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType1.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType1.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType1.lua")
ActivityDispatcher.Reg(ActivityEvent.OnExitFuben, ActivityType, OnExitFuben, "ActivityType1.lua")
ActivityDispatcher.Reg(ActivityEvent.OnFubenFinish, ActivityType, OnFubenFinish, "ActivityType1.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqFubenAward, ActivityType, OnReqFubenAward, "ActivityType1.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType1.lua")

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 跨天，次数清零
function OnNewDayArrive(pActor,ndiffday)
    print("[PActivity 1] "..Actor.getName(pActor).." 跨"..ndiffday.."天")
    local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
    if runAtvIdList == nil then 
        return 
    end
    for i,atvId in ipairs(runAtvIdList) do
        print("[PActivity 1] "..Actor.getName(pActor).." 跨天加活动次数,atvId="..atvId)
        local data = ActivityDispatcher.GetActorData(pActor,atvId)
        if data.count == nil then
            data.count = 0
        end
        if ActivityConfig[atvId].IsAdd then
            data.count = data.count + ((ActivityConfig[atvId].count or 1) * ndiffday)
        else
            data.count = (ActivityConfig[atvId].count or 1)
        end

        -- 发送一个活动数据
        Actor.sendActivityData(pActor, atvId)
    end
end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType1.lua")
