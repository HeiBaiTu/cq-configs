module("ActivityType29", package.seeall)

--[[
    个人活动————每日Boss
    
    个人数据：ActorData[AtvId]
    {
        lastChangeExtraVipLevel     上一次改变额外扫荡次数的等级
        remainTimes,                剩余挑战(扫荡)次数
        extraSaoDangRemainTimes,    剩余外扫荡次数
        extraSaoDangTimes,          额外扫荡次数
    }
]]--

-- 活动类型
ActivityType = 29

-- 对应的活动配置
ActivityConfig = Activity29Config


--扫荡类型
local SaoDangType =
{
    CommonSaoDang = 1,        -- 普通扫荡
    ExtraSaoDang = 2,         -- 额外扫荡
}


--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------
-- 请求进入副本
function reqEnterFuben(atvId, pActor)
    print("ActivityType29.lua reqEnterFuben 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)

    if not ActivityConfig or not ActivityConfig[atvId] then
        print("ActivityType29.lua reqEnterFuben not ActivityConfig or not ActivityConfig[atvId] 活动Id ："..atvId)
        return
    end

    local openDayLimit = 0
    local zsLevelLimit = 0
    local levelLimit   = 0
    -- 每日Boss挑战条件
    if ActivityConfig[atvId].openParam then
        openDayLimit = (ActivityConfig[atvId].openParam.openDay or 0)
        zsLevelLimit = (ActivityConfig[atvId].openParam.zsLevel or 0)
        levelLimit   = (ActivityConfig[atvId].openParam.level or 0)
    end

    -- 开服天数不足
    if openDayLimit > System.getDaysSinceOpenServer() then
        print("ActivityType29.lua reqEnterFuben DaysSinceOpenServer not enough 活动Id ："..atvId.." 开服 "..openDayLimit.." 天可以挑战")
        return
    end

    -- 转生等级不足 或 等级不足
    local nZSLevel = Actor.getIntProperty(pActor, PROP_ACTOR_CIRCLE)
    local nLevel = Actor.getIntProperty(pActor, PROP_CREATURE_LEVEL)
    if zsLevelLimit > nZSLevel or levelLimit > nLevel then
        --print("ActivityType29.lua reqEnterFuben CircleNotEnough 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
        Actor.sendTipmsg(pActor, (ActivityConfig[atvId].tips or " "), tstUI)
        return
    end

    -- 挑战次数不足
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    if actorData.remainTimes <= 0 then
        --print("ActivityType29.lua reqEnterFuben actorData.remainTimes <= 0 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
        Actor.sendTipmsgWithId(pActor, tmNoTimes, tstUI)
        return
    end

    -- 记录日志
    Actor.SendActivityLog(pActor,atvId,ActivityType,1)

    if nil == ActivityDispatcher.EnterFuben(atvId, pActor, (ActivityConfig[atvId].fbId or 0)) then 
        print("ActivityType29.lua reqEnterFuben EnterFuben failure 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
        return
    end 
end

-- 请求扫荡
function reqSaoDang(atvId, pActor, inPack)
    print("ActivityType29.lua reqSaoDang 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)

    local nSaoDangType = DataPack.readByte(inPack)
    if nil == nSaoDangType or nSaoDangType < SaoDangType.CommonSaoDang or nSaoDangType > SaoDangType.ExtraSaoDang then
        print("ActivityType29.lua reqSaoDang nil == nSaoDangType or nSaoDangType < SaoDangType.CommonSaoDang or nSaoDangType > SaoDangType.ExtraSaoDang 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
        return
    end

    if not ActivityConfig or not ActivityConfig[atvId] then
        print("ActivityType29.lua reqSaoDang not ActivityConfig or not ActivityConfig[atvId] 活动Id ："..atvId)
        return
    end

    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    if nSaoDangType == SaoDangType.CommonSaoDang then       -- 普通扫荡
        local openDayLimit = 0
        local zsLevelLimit = 0
        local levelLimit   = 0
        -- 每日Boss挑战条件
        if ActivityConfig[atvId].openParam then
            openDayLimit = (ActivityConfig[atvId].openParam.openDay or 0)
            zsLevelLimit = (ActivityConfig[atvId].openParam.zsLevel or 0)
            levelLimit   = (ActivityConfig[atvId].openParam.level or 0)
        end

        -- 开服天数不足
        if openDayLimit > System.getDaysSinceOpenServer() then
            print("ActivityType29.lua reqEnterFuben DaysSinceOpenServer not enough 活动Id ："..atvId.." 开服 "..openDayLimit.." 天可以挑战")
            return
        end

        -- 转生等级不足 或 等级不足
        local nZSLevel = Actor.getIntProperty(pActor, PROP_ACTOR_CIRCLE)
        local nLevel = Actor.getIntProperty(pActor, PROP_CREATURE_LEVEL)
        if zsLevelLimit > nZSLevel or levelLimit > nLevel then
            --print("ActivityType29.lua reqEnterFuben CircleNotEnough 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
            Actor.sendTipmsg(pActor, (ActivityConfig[atvId].tips or " "), tstUI)
            return
        end

        local vipLevelLimit = 0
        if ActivityConfig[atvId].SaoRequire then
            vipLevelLimit = (ActivityConfig[atvId].SaoRequire.vip or 0)
        end
        -- 特权等级不足
        local nVipLevel = Actor.GetMaxColorCardLevel(pActor)
        if vipLevelLimit > nVipLevel then
            --print("ActivityType29.lua reqSaoDang vipNotEnough 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
            Actor.sendTipmsgWithId(pActor, tmComPoseVipLimit, tstUI)
            return
        end

        -- 扫荡次数不足
        if actorData.remainTimes <= 0 then
            --print("ActivityType29.lua reqSaoDang actorData.remainTimes <= 0 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
            Actor.sendTipmsgWithId(pActor, tmNoTimes, tstUI)
            return
        end
    elseif nSaoDangType == SaoDangType.ExtraSaoDang then    -- 额外扫荡
        local openDayLimit = 0
        local zsLevelLimit = 0
        local levelLimit   = 0
        -- 每日Boss挑战条件
        if ActivityConfig[atvId].showParam then
            openDayLimit = (ActivityConfig[atvId].showParam.openDay or 0)
            zsLevelLimit = (ActivityConfig[atvId].showParam.zsLevel or 0)
            levelLimit   = (ActivityConfig[atvId].showParam.level or 0)
        end

        -- 开服天数不足
        if openDayLimit > System.getDaysSinceOpenServer() then
            print("ActivityType29.lua reqEnterFuben DaysSinceOpenServer not enough 活动Id ："..atvId.." 开服 "..openDayLimit.." 天可以挑战")
            return
        end

        -- 转生等级不足
        local nZSLevel = Actor.getIntProperty(pActor, PROP_ACTOR_CIRCLE)
        if zsLevelLimit > nZSLevel then
            --print("ActivityType2.lua reqEnterFuben CircleNotEnough 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
            Actor.sendTipmsgWithId(pActor, tmCircleNotEnough, tstUI)
            return
        end
 
        -- 等级不足
        local nLevel = Actor.getIntProperty(pActor, PROP_CREATURE_LEVEL)
        if levelLimit > nLevel then
            --print("ActivityType2.lua reqEnterFuben LevelNotEnough 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
            Actor.sendTipmsgWithId(pActor, tmLevelLowernoenter, tstUI)
            return
        end

        -- 检查消耗
        if ActivityConfig[atvId].VipSaodangPrice then
            if true ~= CommonFunc.Consumes.CheckActorSources(pActor, ActivityConfig[atvId].VipSaodangPrice[actorData.extraSaoDangTimes + 1], tstUI) then
                --print("ActivityType29.lua reqSaoDang not CheckActorSources 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
                Actor.sendTipmsgWithId(pActor, tmYBNotEnough, tstUI)
                return
            end
        end

        -- 扫荡次数不足
        if actorData.extraSaoDangRemainTimes <= 0 then
            --print("ActivityType29.lua reqSaoDang actorData.extraSaoDangRemainTimes <= 0 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
            Actor.sendTipmsgWithId(pActor, tmNoTimes, tstUI)
            return
        end
    end

    -- 检查背包格子
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor, 16, tmDefNoBagNum, tstUI) then
        print("ActivityType29.lua reqSaoDang CheckBagNotEnough 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
        return
    end

    -- 移除消耗
    if nSaoDangType == SaoDangType.ExtraSaoDang then
        if true ~= CommonFunc.Consumes.Remove(pActor, ActivityConfig[atvId].VipSaodangPrice[actorData.extraSaoDangTimes + 1], GameLog.Log_Activity29, "Activity29|"..atvId) then
            print("ActivityType29.lua reqSaoDang Remove Consumes fail 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
            return
        end
    end

    -- 消耗次数
    if nSaoDangType == SaoDangType.CommonSaoDang then       -- 普通扫荡
        actorData.remainTimes = actorData.remainTimes - 1
    elseif nSaoDangType == SaoDangType.ExtraSaoDang then    -- 额外扫荡
        actorData.extraSaoDangTimes = actorData.extraSaoDangTimes + 1
        actorData.extraSaoDangRemainTimes = actorData.extraSaoDangRemainTimes - 1
    end

    -- 发放奖励
    CommonFunc.Awards.Give(pActor, ActivityConfig[atvId].reward, GameLog.Log_Activity29, "Activity29|"..atvId)

    Actor.sendTipmsg(pActor, "扫荡成功", tstUI)

    -- 记录日志
    Actor.SendActivityLog(pActor, atvId,ActivityType, 2)

    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)

    -- 触发活跃事件
    if nSaoDangType == SaoDangType.CommonSaoDang then
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
    --print("ActivityType29.lua OnLoad 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
end

-- 活动开始
function OnStart(atvId, pActor)
    print("ActivityType29.lua OnStart 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)

    -- 开服第一天开始,初始化新玩家次数
    if 1 > System.getDaysSinceOpenServer() then
        return
    end

    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    if nil == actorData.lastChangeExtraVipLevel then
        actorData.lastChangeExtraVipLevel = 0
    end
    if nil == actorData.remainTimes then
        actorData.remainTimes = 0
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
        print("ActivityType29.lua OnStart not ActivityConfig or not ActivityConfig[atvId] atvId : "..atvId)
    end
    actorData.remainTimes = ndiffday

    if nil == actorData.extraSaoDangRemainTimes then
        local nVipLevel = Actor.GetMaxColorCardLevel(pActor)
        local nExtraSaoDang = 0
        if ActivityConfig and ActivityConfig[atvId] and ActivityConfig[atvId].vipBuyCount then
            nExtraSaoDang = (ActivityConfig[atvId].vipBuyCount[nVipLevel] or 0)
        end
        actorData.extraSaoDangRemainTimes = nExtraSaoDang
        actorData.lastChangeExtraVipLevel = nVipLevel
    end
    if nil == actorData.extraSaoDangTimes then
        actorData.extraSaoDangTimes = 0
    end
end

-- 活动红点数据
function OnGetRedPoint(atvId, pActor)
    print("ActivityType29.lua OnGetRedPoint 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
    
    -- 开服天数
    local nOpenDays = System.getDaysSinceOpenServer()
    local nZSLevel  = Actor.getIntProperty(pActor, PROP_ACTOR_CIRCLE)
    local nLevel    = Actor.getIntProperty(pActor, PROP_CREATURE_LEVEL)
    
    -- 挑战限制条件
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
    -- 剩余挑战(扫荡)次数不足
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    if not actorData.remainTimes or actorData.remainTimes <= 0 then
        ret = 0
    end

    return ret
end

-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    print("ActivityType29.lua OnReqData 玩家 ："..Actor.getName(pActor).." 活动Id ："..atvId)
    
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)

    -- 如果VIP等级发生变化，则增加相应次数
    local nVipLevel = Actor.GetMaxColorCardLevel(pActor)
    if actorData.lastChangeExtraVipLevel ~= nVipLevel then
        local nTimes = 0
        if ActivityConfig and ActivityConfig[atvId] and ActivityConfig[atvId].vipBuyCount then
            nTimes = (ActivityConfig[atvId].vipBuyCount[nVipLevel] or 0) - actorData.extraSaoDangTimes
        end

        if nTimes then
            actorData.extraSaoDangRemainTimes = nTimes

            actorData.lastChangeExtraVipLevel = nVipLevel
        else
            print("ActivityType29.lua OnReqData 玩家 ："..Actor.getName(pActor).." nTimes : "..nTimes)
        end
    end

    DataPack.writeWord(outPack, (actorData.remainTimes or 0))
    DataPack.writeByte(outPack, (actorData.extraSaoDangRemainTimes or 0))
    DataPack.writeByte(outPack, (actorData.extraSaoDangTimes or 0))
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    print("ActivityType29.lua OnOperator 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)

    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cEnterFuben then     -- 请求进入副本
        reqEnterFuben(atvId, pActor)
    elseif operaCode == ActivityOperate.cReqSaoDang then     -- 请求扫荡
        reqSaoDang(atvId, pActor, inPack)
    end
end

-- 进入副本
function OnEnterFuben(atvId, pActor, pFuben, pOwner)
    --print("ActivityType29.lua OnEnterFuben 玩家 ："..Actor.getName(pActor).. " 副本Id ："..fbId)
end

-- 玩家退出活动副本
function OnExitFuben(atvId, pActor, pFuben, pOwner)
    print("ActivityType29.lua OnExitFuben 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)

    if not ActivityConfig or not ActivityConfig[atvId] then
        print("ActivityType29.lua OnExitFuben not ActivityConfig or not ActivityConfig[atvId] 活动Id ："..atvId)
        return
    end

    -- 通关后才消耗门票跟次数
    if 1 == FubenDispatcher.GetReault(pFuben) then
        -- 单人副本活动，所有者必须为自己
        if pOwner == pActor then
            local fbcache = FubenDispatcher.GetCacheData(pFuben)
            if not fbcache.hasGetAward then
                if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor, 16, tmDefNoBagNum, tstUI) then
                    print("ActivityType29.lua OnReqFubenAward CheckBagNotEnough玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
                   return
                end
                CommonFunc.Awards.Give(pActor, ActivityConfig[atvId].reward, GameLog.Log_Activity29, "Activity29|"..atvId)

                Actor.sendTipmsg(pActor, "每日Boss任务完成，奖励已发放！", tstGetItem)

                fbcache.hasGetAward = 1

                local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
                -- 消耗次数
                if actorData.remainTimes > 0 then 
                    actorData.remainTimes = actorData.remainTimes - 1
                end

                -- 记录日志
                Actor.SendActivityLog(pActor, atvId, ActivityType, 2)

                -- 发送一个活动数据
                Actor.sendActivityData(pActor, atvId)

                -- 触发活跃事件
                Actor.triggerActiveEvent(pActor,nAchieveActivity,1 ,atvId)
                Actor.triggerActiveEvent(pActor, nAchieveCompleteActivity,1 ,atvId)
                Actor.triggerActiveEvent(pActor, nAchieveActivityType,1 ,ActivityType)
            end
        end
    else
        print("ActivityType29.lua OnExitFuben 1 ~= FubenDispatcher.GetReault(pFuben) 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
    end
end

-- 活动副本结束
function OnFubenFinish(atvId, pFuben, result, pOwner)
    print("ActivityType29.lua OnFubenFinish 活动Id ："..atvId.." result : "..result)
    
    --发送成功失败的旗帜
    if pOwner then
        if result == 1 then
            --完成副本任务
            --Actor.ExOnQuestEvent(pOwner, CQuestData.qtFuben, 12);
        end
        local npack = ActivityDispatcher.AllocResultPack(pOwner, atvId, result)
        if npack then
            DataPack.flush(npack)
        end
    end
end

-- 活动结束
function OnEnd(atvId, pActor)
    --print("ActivityType29.lua OnEnd 玩家 ："..Actor.getName(pActor).. " 活动Id ："..atvId)
end

ActivityDispatcher.Reg(ActivityEvent.OnLoad, ActivityType, OnLoad, "ActivityType29.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType29.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType29.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType29.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType29.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnterFuben, ActivityType, OnEnterFuben, "ActivityType29.lua")
ActivityDispatcher.Reg(ActivityEvent.OnExitFuben, ActivityType, OnExitFuben, "ActivityType29.lua")
ActivityDispatcher.Reg(ActivityEvent.OnFubenFinish, ActivityType, OnFubenFinish, "ActivityType29.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType29.lua")


-- 跨天
function OnNewDayArrive(pActor, ndiffday)
    print("ActivityType29.lua OnNewDayArrive 玩家 ："..Actor.getName(pActor).. " 跨 "..ndiffday.." 天")
    
    local runAtvIdList = Actor.getRunningActivityId(pActor, ActivityType)
    if runAtvIdList then
        -- 增加挑战(扫荡)的起始开服天数
        for i, atvId in ipairs(runAtvIdList) do
            
            -- 开服第一天开始；累加挑战(扫荡次数)次数:
            if 1 > System.getDaysSinceOpenServer() then
                return
            end

            local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
            if nil == actorData.lastChangeExtraVipLevel then
                actorData.lastChangeExtraVipLevel = 0
            end
            if nil == actorData.remainTimes then
                actorData.remainTimes = 0
            end
            if nil == actorData.extraSaoDangRemainTimes then
                actorData.extraSaoDangRemainTimes = 0
            end
            if nil == actorData.extraSaoDangTimes then
                actorData.extraSaoDangTimes = 0
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
                print("ActivityType29.lua OnNewDayArrive not ActivityConfig or ActivityConfig[atvId] atvId : "..atvId)
            end

            actorData.remainTimes = actorData.remainTimes + ndiffday

            -- 重置额外扫荡次数
            local nVipLevel = Actor.GetMaxColorCardLevel(pActor)
            local nExtraSaoDang = 0
            if ActivityConfig and ActivityConfig[atvId] and ActivityConfig[atvId].vipBuyCount then
                nExtraSaoDang = (ActivityConfig[atvId].vipBuyCount[nVipLevel] or 0)
            end
            actorData.extraSaoDangRemainTimes = nExtraSaoDang
            actorData.lastChangeExtraVipLevel = nVipLevel
            actorData.extraSaoDangTimes = 0

            -- 发送一个活动数据
            Actor.sendActivityData(pActor, atvId)
        end
    end
end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType29.lua")


