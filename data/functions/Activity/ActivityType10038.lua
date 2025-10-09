module("ActivityType10038", package.seeall)


--[[
    全局活动 神秘福袋

    个人数据：ActorData[AtvId]
    {
        awardTime =                    神秘福袋开始计时时间
        onlineTime                     在线时长
        nextAwardIndex =               当前神秘福袋索引
    }

    全局缓存：Cache[AtvId]
    {
        actors = {actorid,...}  记录活动副本中的玩家id
    }

    全局数据：GlobalData[AtvId]
    {
        status,                 活动状态，这个即使服务器重启了，也要保存这个数据
        nextPrintOnlineDataTime  下次打印玩家在线时长的时间戳
    }
]]--

--活动类型
ActivityType = 10038

--对应的活动配置
ActivityConfig = Activity10038Config

--通知玩家在线时间间隔(单位：秒)
PrintOnlineDataInterval = 5 

--活动状态
local AtvStatus =
{
    Run = 1,        --活动中
    End = 2,        --活动结束了
}

--在场景中的玩家
actorsInFuben =
{
    --[atvId] =
    --{
    --  [actorId] = actorId
    --}
}

function ReLoadScript()
    local actvsList = System.getRunningActivityId(ActivityType)
    if actvsList then
        for i,atvId in ipairs(actvsList) do
            actorsInFuben[atvId] = {}
            local cacheData = ActivityDispatcher.GetCacheData(atvId)
            if cacheData and cacheData.actors then
                for i,actorId in Ipairs(cacheData.actors) do
                    local pActor = Actor.getActorById(actorId)
                    if pActor then
                        actorsInFuben[atvId][actorId] = actorId
                    end
                end
            end
        end
    end
end
ReLoadScript()

--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------


--请求领取阶段奖励
function reqGetPhaseAward(pActor, atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    
    if nil == actorData.awardTime then
        actorData.awardTime = System.getCurrMiniTime()
    end
    
    if nil == actorData.nextAwardIndex then
        actorData.nextAwardIndex = 1
    end

    local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    if nil == actorsInFuben[atvId][actorId] then
        print("ActivityType10038 reqGetPhaseAward 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor).." actorId : "..actorId)
        return
    end

    if not ActivityConfig or not ActivityConfig[atvId] or not ActivityConfig[atvId].reward or not ActivityConfig[atvId].reward[actorData.nextAwardIndex] then
        print("ActivityType10038 reqGetPhaseAward not ActivityConfig or not ActivityConfig[atvId] or not ActivityConfig[atvId].reward or not ActivityConfig[atvId].reward[actorData.nextAwardIndex] 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))
        return
    end

    if not ActivityConfig[atvId].reward[actorData.nextAwardIndex].time or not ActivityConfig[atvId].reward[actorData.nextAwardIndex].awards then
        print("ActivityType10038 reqGetPhaseAward not ActivityConfig[atvId].reward[actorData.nextAwardIndex].time or not ActivityConfig[atvId].reward[actorData.nextAwardIndex].awards 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))
        return
    end

    if actorData.onlineTime >= ActivityConfig[atvId].reward[actorData.nextAwardIndex].time then
        local awards = ActivityConfig[atvId].reward[actorData.nextAwardIndex].awards

        if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,1,tmDefNoBagNum,tstUI) then
            print("ActivityType10038 reqGetPhaseAward not BagEnough 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))
            return
        end

        CommonFunc.Awards.Give(pActor, awards, GameLog.Log_Activity10038, "Activity10038onlineAward|"..atvId)
        actorData.nextAwardIndex = actorData.nextAwardIndex + 1
        actorData.onlineTime = 0
        actorData.awardTime = System.getCurrMiniTime()

        -- 发送一个活动数据
        Actor.sendActivityData(pActor, atvId)
    else
        print("ActivityType10038 reqGetPhaseAward 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor).." onlineTime : "..actorData.onlineTime.." time : "..ActivityConfig[atvId].reward[actorData.nextAwardIndex].time)
    end

    print("ActivityType10038 reqGetPhaseAward 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor).." nextAwardIndex : "..actorData.nextAwardIndex)
end

-- 加载活动时（启动服务器从数据库返回的）
function OnLoad(atvId)
    print("ActivityType10038 OnLoad 活动Id ："..atvId)

    ActivityDispatcher.ClearCacheData(atvId)
    ActivityDispatcher.ClearGlobalData(atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)

    cacheData.actors = {}
    actorsInFuben[atvId] = {}
    globalData.status = AtvStatus.Run
    globalData.nextPrintOnlineDataTime = System.getCurrMiniTime() + PrintOnlineDataInterval
end

-- 初始化玩家数据
function OnInit(atvId, pActor)
    --print("ActivityType10038 OnInit 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))
    
    local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    if nil == cacheData.actors then
        cacheData.actors = {}
    end
    cacheData.actors[actorId] = actorId

    if nil == actorsInFuben[atvId] then
        actorsInFuben[atvId] = {}
    end
    
    if actorsInFuben[atvId][actorId] then
        --print("ActivityType10038 OnInit actorsInFuben[atvId][actorId] 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))

        local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
        actorData.awardTime = System.getCurrMiniTime() - (actorData.onlineTime or 0)

        return
    end
    actorsInFuben[atvId][actorId] = actorId    

    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if nil == actorData.awardTime then
        actorData.awardTime = System.getCurrMiniTime()
        actorData.onlineTime = 0
        actorData.nextAwardIndex = 1
    end
end

-- 活动开始
function OnStart(atvId)
    print("ActivityType10038 OnStart 活动Id ："..atvId)

    ActivityDispatcher.ClearCacheData(atvId)
    ActivityDispatcher.ClearGlobalData(atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    if nil == globalData.openTimes then
        globalData.openTimes = System.getCurrMiniTime()
    else
        globalData.openTimes = globalData.openTimes + 1
    end
    cacheData.actors = {}
    actorsInFuben[atvId] = {}
    globalData.status = AtvStatus.Run
    globalData.nextPrintOnlineDataTime = System.getCurrMiniTime() + PrintOnlineDataInterval
end

--初始化活动数据
function OnLoginGame(atvId, pActor)
    --print("ActivityType10038 OnLoginGame 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    if nil == globalData.status or AtvStatus.Run ~= globalData.status then
        --print("ActivityType10038 OnLoginGame not globalData.status or AtvStatus.Run ~= globalData.status 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))
        return
    end

    local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    if nil == cacheData.actors then
        cacheData.actors = {}
    end
    cacheData.actors[actorId] = actorId

    if nil == actorsInFuben[atvId] then
        actorsInFuben[atvId] = {}
    end
    
    if actorsInFuben[atvId][actorId] then
        --print("ActivityType10038 OnInit actorsInFuben[atvId][actorId] 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))

        local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
        actorData.awardTime = System.getCurrMiniTime() - (actorData.onlineTime or 0)

        return
    end
    actorsInFuben[atvId][actorId] = actorId

    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if nil == actorData.awardTime then
        actorData.awardTime = System.getCurrMiniTime()
        actorData.onlineTime = 0
        actorData.nextAwardIndex = 1
    end
end

--获取活动数据
function OnReqData(atvId, pActor, outPack)
    --print("ActivityType10038 OnReqData 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))

    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    DataPack.writeUInt(outPack, (data.onlineTime or 0))
    DataPack.writeByte(outPack, (data.nextAwardIndex or 1))
end

--活动红点数据
function OnGetRedPoint(atvId, pActor)
    --print("ActivityType10038 OnGetRedPoint 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))

    local nRet = 0
    local nLimitLv = 0
    local nLimitZS = 0

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    if not globalData.status or AtvStatus.Run ~= globalData.status then
        --print("ActivityType10038 OnGetRedPoint not globalData.status or AtvStatus.Run ~= globalData.status 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))
        return nRet
    end

    if ActivityConfig and ActivityConfig[atvId] and ActivityConfig[atvId].openParam then
        nLimitLv =  (ActivityConfig[atvId].openParam.level or 0)
        nLimitZS =  (ActivityConfig[atvId].openParam.zsLevel or 0)
    end

    local nLv = Actor.getIntProperty( pActor, PROP_CREATURE_LEVEL )
    local nZSLv = Actor.getIntProperty(pActor, PROP_ACTOR_CIRCLE)
    if nZSLv < nLimitZS then
        --print("ActivityType10038 OnGetRedPoint nZSLv < nLimitZS 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))
        return nRet 
    end
    if nLv < nLimitLv then
        --print("ActivityType10038 OnGetRedPoint nLv < nLimitLv 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))
        return nRet
    end

    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if not ActivityConfig or not ActivityConfig[atvId] or not ActivityConfig[atvId].reward or not ActivityConfig[atvId].reward[actorData.nextAwardIndex] then
        --print("ActivityType10038 OnGetRedPoint not ActivityConfig or not ActivityConfig[atvId] or not ActivityConfig[atvId].reward or not ActivityConfig[atvId].reward[actorData.nextAwardIndex] 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor).."actorData.nextAwardIndex : "..(actorData.nextAwardIndex or 1))
        return nRet
    end

    if not ActivityConfig[atvId].reward[actorData.nextAwardIndex].time or not actorData.onlineTime or actorData.onlineTime < ActivityConfig[atvId].reward[actorData.nextAwardIndex].time then
        --print("ActivityType10038 OnGetRedPoint not ActivityConfig[atvId].reward[actorData.nextAwardIndex].time or not actorData.onlineTime or actorData.onlineTime < ActivityConfig[atvId].reward[actorData.nextAwardIndex].time 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor).."")
        return nRet
    end

    nRet = 1

    return nRet
end

-- 活动帧更新
function OnUpdate(atvId, curTime)
    -- print("ActivityType10038 OnUpdate 活动Id ："..atvId.." curTime : "..curTime)

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    if nil == globalData.status or AtvStatus.Run ~= globalData.status then
        --print("ActivityType10038 OnUpdate not globalData.status or AtvStatus.Run ~= globalData.status 活动Id ："..atvId)
        return
    end

    -- 有玩家时才处理
    if actorsInFuben[atvId] then
        for i,actorid in pairs(actorsInFuben[atvId]) do
            local pActor = Actor.getActorById(actorid)
            if pActor then
                local data = ActivityDispatcher.GetActorData(pActor,atvId)

                if nil == data.awardTime then
                    data.awardTime = System.getCurrMiniTime()
                end

                data.onlineTime = curTime -  data.awardTime
                
                if curTime > globalData.nextPrintOnlineDataTime then
                    globalData.nextPrintOnlineDataTime = globalData.nextPrintOnlineDataTime + PrintOnlineDataInterval
                    --print("ActivityType10038 OnUpdate 玩家 "..Actor.getName(pActor).." data.onlineTime : "..data.onlineTime)
                end
            end
        end
    end
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cGetPhaseAward then --请求获取阶段奖励
        reqGetPhaseAward(pActor, atvId)
    end
end

-- 活动结束
function OnEnd(atvId)
    print("ActivityType10038 OnEnd 活动Id ："..atvId)

    -- 有玩家时才处理
    if actorsInFuben[atvId] then
        for i,actorid in pairs(actorsInFuben[atvId]) do
            local pActor = Actor.getActorById(actorid)
            if pActor then
                ActivityDispatcher.ClearActorData(pActor,atvId)

                -- 发送一个活动数据
                Actor.sendActivityData(pActor, atvId)
            end
        end
    end

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    globalData.status = AtvStatus.End

    ActivityDispatcher.ClearCacheData(atvId)
    ActivityDispatcher.ClearGlobalData(atvId)
    actorsInFuben[atvId] = nil
end

ActivityDispatcher.Reg(ActivityEvent.OnLoad, ActivityType, OnLoad, "ActivityType10038.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType10038.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType10038.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType10038.lua")
ActivityDispatcher.Reg(ActivityEvent.OnLoginGame, ActivityType, OnLoginGame, "ActivityType10038.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType10038.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType10038.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType1.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType10038.lua")

-- 跨天
function OnNewDayArrive(pActor, ndiffday)
    print("ActivityType10038 OnNewDayArrive "..Actor.getName(pActor).." 跨 "..ndiffday.." 天")

    local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
    if nil == runAtvIdList then 
        return 
    end
    for i,atvId in ipairs(runAtvIdList) do
        print("ActivityType10038 OnNewDayArrive "..Actor.getName(pActor).." 跨天重置神秘福袋,atvId = "..atvId)

        ActivityDispatcher.ClearActorData(pActor,atvId)

        -- 发送一个活动数据
        Actor.sendActivityData(pActor, atvId)
    end
end
ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10038.lua")