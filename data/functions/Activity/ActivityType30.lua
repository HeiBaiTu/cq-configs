module("ActivityType30", package.seeall)

--[[
    个人活动，鉴定类活动

    个人数据：ActorData[AtvId]
    {
        lastChangeExtraVipLevel             上一次改变额外鉴定次数的等级
        remainIdentifyTimes,                剩余鉴定次数
        remainExtraIdentifyTimes,           剩余外鉴定次数
        extraIdentifyimes,                  额外鉴定次数
    }

    全局缓存：Cache[fbId]
    {

    }

    全局数据：GlobalData[AtvId]
    {

    }
]]--

--活动类型
local ActivityType = 30

--对应的活动配置
local ActivityConfig = Activity30Config

--鉴定类型
local IdentifyType =
{
    CommonIdentify = 1,        -- 普通鉴定
    ExtraIdentify = 2,         -- 额外鉴定
}


--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------
-- 请求鉴定
function reqAppraisal(atvId, pActor, inPack)
    print("ActivityType30.lua reqAppraisal 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)

    local nIdentifyType = DataPack.readByte(inPack)
    if nil == nIdentifyType or nIdentifyType < IdentifyType.CommonIdentify or nIdentifyType > IdentifyType.ExtraIdentify then
        print("ActivityType30.lua reqAppraisal nil == nIdentifyType or nIdentifyType < IdentifyType.CommonIdentify or nIdentifyType > IdentifyType.ExtraIdentify 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
        return
    end

    if not ActivityConfig or not ActivityConfig[atvId] then
        print("ActivityType30.lua reqAppraisal not ActivityConfig or not ActivityConfig[atvId] 活动Id ："..atvId)
        return
    end

    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    if nIdentifyType == IdentifyType.CommonIdentify then       -- 普通鉴定
        local openDayLimit = 0
        local zsLevelLimit = 0
        local levelLimit   = 0
        -- 每日副本鉴定条件
        if ActivityConfig[atvId].openParam then
            openDayLimit = (ActivityConfig[atvId].openParam.openDay or 0)
            zsLevelLimit = (ActivityConfig[atvId].openParam.zsLevel or 0)
            levelLimit   = (ActivityConfig[atvId].openParam.level or 0)
        end

        -- 开服天数不足
        if openDayLimit > System.getDaysSinceOpenServer() then
            print("ActivityType30.lua reqEnterFuben DaysSinceOpenServer not enough 活动Id ："..atvId.." 开服 "..openDayLimit.." 天可以挑战")
            return
        end

        -- 转生等级不足 或 等级不足
        local nZSLevel = Actor.getIntProperty(pActor, PROP_ACTOR_CIRCLE)
        local nLevel = Actor.getIntProperty(pActor, PROP_CREATURE_LEVEL)
        if zsLevelLimit > nZSLevel or levelLimit > nLevel then
            --print("ActivityType30.lua reqEnterFuben CircleNotEnough 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
            Actor.sendTipmsg(pActor, (ActivityConfig[atvId].tips or " "), tstUI)
            return
        end

        -- 鉴定次数不足
        if actorData.remainIdentifyTimes <= 0 then
            --print("ActivityType30.lua reqAppraisal actorData.remainIdentifyTimes <= 0 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
            Actor.sendTipmsgWithId(pActor, tmNoTimes, tstUI)
            return
        end
    elseif nIdentifyType == IdentifyType.ExtraIdentify then    -- 额外鉴定
        local openDayLimit = 0
        local zsLevelLimit = 0
        local levelLimit   = 0
        -- 每日副本鉴定条件
        if ActivityConfig[atvId].showParam then
            openDayLimit = (ActivityConfig[atvId].showParam.openDay or 0)
            zsLevelLimit = (ActivityConfig[atvId].showParam.zsLevel or 0)
            levelLimit   = (ActivityConfig[atvId].showParam.level or 0)
        end

        -- 开服天数不足
        if openDayLimit > System.getDaysSinceOpenServer() then
            print("ActivityType30.lua reqEnterFuben DaysSinceOpenServer not enough 活动Id ："..atvId.." 开服 "..openDayLimit.." 天可以挑战")
            return
        end

        -- 转生等级不足
        local nZSLevel = Actor.getIntProperty(pActor, PROP_ACTOR_CIRCLE)
        if zsLevelLimit > nZSLevel then
            --print("ActivityType30.lua reqEnterFuben CircleNotEnough 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
            Actor.sendTipmsgWithId(pActor, tmCircleNotEnough, tstUI)
            return
        end
 
        -- 等级不足
        local nLevel = Actor.getIntProperty(pActor, PROP_CREATURE_LEVEL)
        if levelLimit > nLevel then
            --print("ActivityType30.lua reqEnterFuben LevelNotEnough 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
            Actor.sendTipmsgWithId(pActor, tmLevelLowernoenter, tstUI)
            return
        end

        -- 检查消耗
        if ActivityConfig[atvId].VipJiandingPrice then
            if true ~= CommonFunc.Consumes.CheckActorSources(pActor, ActivityConfig[atvId].VipJiandingPrice[actorData.extraIdentifyimes + 1], tstUI) then
                --print("ActivityType30.lua reqAppraisal not CheckActorSources 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
                return
            end
        else
            print("ActivityType30.lua reqAppraisal not ActivityConfig[atvId].VipJiandingPrice 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
        end

        -- 鉴定次数不足
        if actorData.remainExtraIdentifyTimes <= 0 then
            --print("ActivityType30.lua reqAppraisal actorData.remainExtraIdentifyTimes <= 0 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
            Actor.sendTipmsgWithId(pActor, tmNoTimes, tstUI)
            return
        end
    end

    -- 检查背包格子
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor, 16, tmDefNoBagNum, tstUI) then
        print("ActivityType30.lua reqAppraisal CheckBagNotEnough 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
        return
    end

    -- 移除消耗
    if nIdentifyType == IdentifyType.ExtraIdentify then
        if true ~= CommonFunc.Consumes.Remove(pActor, ActivityConfig[atvId].VipJiandingPrice[actorData.extraIdentifyimes + 1], GameLog.Log_Activity12, "Activity12|"..atvId) then
            --print("ActivityType30.lua reqAppraisal Remove Consumes fail 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
            return
        end
    end

    -- 消耗次数
    if nIdentifyType == IdentifyType.CommonIdentify then       -- 普通鉴定
        actorData.remainIdentifyTimes = actorData.remainIdentifyTimes - 1
    elseif nIdentifyType == IdentifyType.ExtraIdentify then    -- 额外鉴定
        actorData.extraIdentifyimes = actorData.extraIdentifyimes + 1
        actorData.remainExtraIdentifyTimes = actorData.remainExtraIdentifyTimes - 1
    end

    -- 发放奖励
    CommonFunc.Awards.Give(pActor, ActivityConfig[atvId].reward, GameLog.Log_Activity30, "Activity30|"..atvId)

    Actor.sendTipmsg(pActor, "鉴定成功", tstUI)

    -- 记录日志
    Actor.SendActivityLog(pActor, atvId,ActivityType, 2)

    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)

    -- 触发活跃事件
    if nIdentifyType == IdentifyType.CommonIdentify then
        Actor.triggerActiveEvent(pActor,nAchieveActivity,1 ,atvId)
        Actor.triggerActiveEvent(pActor, nAchieveCompleteActivity,1 ,atvId)

        Actor.triggerActiveEvent(pActor,nAchieveActivityType,1 ,ActivityType)
    end
end
--------------------------------------------------------------------
-- 活动 回调注册
--------------------------------------------------------------------
-- 加载活动时（启动服务器从数据库返回的）
function OnLoad(atvId, pActor)
    --print("ActivityType30.lua OnLoad 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
end

-- 活动开始
function OnStart(atvId, pActor)
    print("ActivityType30.lua OnStart 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)

    -- 开服第一天开始,初始化新玩家次数
    if 1 > System.getDaysSinceOpenServer() then
        return
    end

    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    if nil == actorData.lastChangeExtraVipLevel then
        actorData.lastChangeExtraVipLevel = 0
    end
    if nil == actorData.remainIdentifyTimes then
        actorData.remainIdentifyTimes = 0
    end

    local ndiffday = 0
    if ActivityConfig and ActivityConfig[atvId] then
        local config = ActivityConfig[atvId]
        local nOpenTime = System.getOpenServerRelToday()
        local nDiffTime = math.max(nOpenTime, (config.SetTime or 0));
        local bNewActor = false
        local nTime = Actor.getStaticCount(pActor, config.counterid)
        if nTime == 0 then
            bNewActor = true
        end

        local nOffDay = 0
        if nTime ~= nDiffTime then
            if bNewActor then
                nTime = System.getToday()
                nOffDay = math.ceil( (math.abs(nTime - nDiffTime)) / (24*3600) ) + 1
            else
                nOffDay = math.ceil( (math.abs(nTime - nDiffTime)) / (24*3600) ) + ndiffday
            end
            Actor.setStaticCount(pActor, config.counterid, nDiffTime)
        end

        if nOffDay ~= 0 then
            ndiffday = nOffDay
        end
    else
        print("ActivityType30.lua OnStart not ActivityConfig or not ActivityConfig[atvId] atvId : "..atvId)
    end
    actorData.remainIdentifyTimes = ndiffday

    if nil == actorData.remainExtraIdentifyTimes then
        local nVipLevel = Actor.GetMaxColorCardLevel(pActor)
        local nExtraIdentify = 0
        if ActivityConfig and ActivityConfig[atvId] and ActivityConfig[atvId].vipBuyCount then
            nExtraIdentify = (ActivityConfig[atvId].vipBuyCount[nVipLevel] or 0)
        end
        actorData.remainExtraIdentifyTimes = nExtraIdentify
        actorData.lastChangeExtraVipLevel = nVipLevel
    end
    if nil == actorData.extraIdentifyimes then
        actorData.extraIdentifyimes = 0
    end
end

-- 活动红点数据
function OnGetRedPoint(atvId, pActor)
    print("ActivityType30.lua OnGetRedPoint 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
    
    -- 开服天数
    local nOpenDays = System.getDaysSinceOpenServer()
    local nZSLevel  = Actor.getIntProperty(pActor, PROP_ACTOR_CIRCLE)
    local nLevel    = Actor.getIntProperty(pActor, PROP_CREATURE_LEVEL)
    
    -- 鉴定限制条件
    local openDayLimit = 0
    local zsLevelLimit = 0
    local levelLimit   = 0
    if ActivityConfig and ActivityConfig[atvId] and ActivityConfig[atvId].openParam then
        openDayLimit     = (ActivityConfig[atvId].openParam.openDay or 0)
        zsLevelLimit   = (ActivityConfig[atvId].openParam.zsLevel or 0)
        levelLimit     = (ActivityConfig[atvId].openParam.level or 0)
    end

    local ret       = 1
    -- 开服天数不足
    if openDayLimit > nOpenDays then
        ret = 0
    end
    -- 转升等级不足
    if zsLevelLimit > nZSLevel then
        ret = 0
    end
    -- 等级不足
    if levelLimit > nLevel then
        ret = 0
    end
    -- 剩余鉴定次数不足
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    if not actorData.remainIdentifyTimes or actorData.remainIdentifyTimes <= 0 then
        ret = 0
    end

    return ret
end

-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    print("ActivityType30.lua OnReqData 玩家 ："..Actor.getName(pActor).." 活动Id ："..atvId)
    
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)

    -- 如果VIP等级发生变化，则增加相应次数
    local nVipLevel = Actor.GetMaxColorCardLevel(pActor)
    if actorData.lastChangeExtraVipLevel ~= nVipLevel then
        local nTimes = 0
        if ActivityConfig and ActivityConfig[atvId] and ActivityConfig[atvId].vipBuyCount then
            nTimes = (ActivityConfig[atvId].vipBuyCount[nVipLevel] or 0) - actorData.extraIdentifyimes
        end

        if nTimes then
            actorData.remainExtraIdentifyTimes = nTimes

            actorData.lastChangeExtraVipLevel = nVipLevel
        else
            print("ActivityType30.lua OnReqData 玩家 ："..Actor.getName(pActor).." nTimes : "..nTimes)
        end
    end

    DataPack.writeWord(outPack, (actorData.remainIdentifyTimes or 0))
    DataPack.writeByte(outPack, (actorData.remainExtraIdentifyTimes or 0))
    DataPack.writeByte(outPack, (actorData.extraIdentifyimes or 0))
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    print("ActivityType30.lua OnOperator 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)

    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cAppraisal then     -- 请求鉴定
        reqAppraisal(atvId, pActor, inPack)
    end
end

-- 活动结束
function OnEnd(atvId, pActor)
    --print("ActivityType30.lua OnEnd 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
end

ActivityDispatcher.Reg(ActivityEvent.OnLoad, ActivityType, OnLoad, "ActivityType30.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType30.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType30.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType30.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType30.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType30.lua")


-- 跨天
function OnNewDayArrive(pActor, ndiffday)
    print("ActivityType30.lua OnNewDayArrive 玩家 ："..Actor.getName(pActor).. " 跨 "..ndiffday.." 天")
    
    local runAtvIdList = Actor.getRunningActivityId(pActor, ActivityType)
    if runAtvIdList then
        -- 增加鉴定的起始开服天数
        for i, atvId in ipairs(runAtvIdList) do

            -- 开服第一天开始；累加鉴定次数:
            if 1 > System.getDaysSinceOpenServer() then
                return
            end

            local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
            if nil == actorData.lastChangeExtraVipLevel then
                actorData.lastChangeExtraVipLevel = 0
            end
            if nil == actorData.remainIdentifyTimes then
                actorData.remainIdentifyTimes = 0
            end
            if nil == actorData.remainExtraIdentifyTimes then
                actorData.remainExtraIdentifyTimes = 0
            end
            if nil == actorData.extraIdentifyimes then
                actorData.extraIdentifyimes = 0
            end
            
            if ActivityConfig and ActivityConfig[atvId] then
                local config = ActivityConfig[atvId]
                local nOpenTime = System.getOpenServerRelToday()
                local nDiffTime = math.max(nOpenTime, (config.SetTime or 0));

                local bNewActor = false
                local nTime = Actor.getStaticCount(pActor, config.counterid)
                if nTime == 0 then
                    bNewActor = true
                end

                local nOffDay = 0
                if nTime ~= nDiffTime then
                    if bNewActor then
                        nTime = System.getToday();
                        nOffDay = math.ceil( (math.abs(nTime - nDiffTime)) / (24*3600) ) + 1
                    else
                        nOffDay = math.ceil( (math.abs(nTime - nDiffTime)) / (24*3600) ) + ndiffday
                    end
                    Actor.setStaticCount(pActor, config.counterid, nDiffTime)
                end

                if nOffDay ~= 0 then
                    ndiffday = nOffDay
                end
            else
                print("ActivityType30.lua OnNewDayArrive not ActivityConfig or not ActivityConfig[atvId] atvId : "..atvId)
            end

            actorData.remainIdentifyTimes = actorData.remainIdentifyTimes + ndiffday

            -- 重置额外鉴定次数
            local nVipLevel = Actor.GetMaxColorCardLevel(pActor)
            local nExtraIdentify = 0
            if ActivityConfig and ActivityConfig[atvId] and ActivityConfig[atvId].vipBuyCount then
                nExtraIdentify = (ActivityConfig[atvId].vipBuyCount[nVipLevel] or 0)
            end
            actorData.remainExtraIdentifyTimes = nExtraIdentify
            actorData.lastChangeExtraVipLevel = nVipLevel
            actorData.extraIdentifyimes = 0

            -- 发送一个活动数据
            Actor.sendActivityData(pActor, atvId)
        end
    end
end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType30.lua")