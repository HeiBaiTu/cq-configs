module("ActivityType12", package.seeall)

--[[
    个人活动————材料副本活动
    进副本扣进入消耗，通关扣取通关消耗及次数；
    次数与开服天数有关，从配置要求的开服天数以后开始每天叠加不清空；
    
    个人数据：ActorData[AtvId]
    {
        count,      当前的可进入次数
    }
]]--

--活动类型
ActivityType = 12
--对应的活动配置
ActivityConfig = Activity12Config
if ActivityConfig == nil then
    assert(false)
end

--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------

--请求扫荡
--使用扫荡券直接完成领奖
function reqsaodang(pActor, atvId, Conf)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)

    --在材料副本中不能进行扫荡
    if Actor.getFubenId(pActor) ==Conf.fbId then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:已在副本中|", tstUI)
        return 
    end 

    --开服天数不满足
    if (ActivityConfig[atvId].countstart or 0) > System.getDaysSinceOpenServer() then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:开服天数不足|", tstUI)
        return 
    end

    --等级、转身等级限制
    local limitLv = 0;
    local limitzsLv  = 0 ;
    local cfg = ActivityConfig[atvId]
    if cfg and cfg.openParam then
        limitLv =  (cfg.openParam.level or 0)
        limitzsLv = (cfg.openParam.zsLevel or 0)
    end
    local lv = Actor.getIntProperty( pActor, PROP_CREATURE_LEVEL )
    local zsLv = Actor.getIntProperty(pActor, PROP_ACTOR_CIRCLE)
    if lv < limitLv then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:等级不足|", tstUI) 
        return 
    end
    if zsLv < zsLv then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:转身不足|", tstUI)
        return 
    end 

    --消耗检查
    local consumes = nil
    -- if Conf.enterExpends then
    --     consumes = Conf.enterExpends
    --     if CommonFunc.Consumes.Check(pActor, consumes) ~= true then
    --         Actor.sendTipmsgWithId(pActor, tmNeedItemNotEnough, tstUI)
    --         return
    --     end
    -- end

    --检查扫荡所需特殊消耗
    if Conf.saodangExpends then
        consumes = Conf.saodangExpends
        if CommonFunc.Consumes.Check(pActor, consumes) ~= true then
            --Actor.sendTipmsgWithId(pActor, tmNeedItemNotEnough, tstUI)
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:扫荡卷不足|", tstUI)
            return
        end
    end

    --次数检查
    if data.count == nil then
        if (ActivityConfig[atvId].countstart or 0) < System.getDaysSinceOpenServer() then 
            local multi = 1
            if ActivityConfig[atvId].isFromOpenSrv then
                multi = System.getDaysSinceOpenServer()
                multi = multi - (ActivityConfig[atvId].countstart or 0) + 1 
            end
        
            if multi > 0 then 
                data.count = multi * (ActivityConfig[atvId].count or 1)
            else 
                data.count = 0  
            end 
        else 
            data.count = 0
        end 
    else 
        if data.count <= 0 then
            --Actor.sendTipmsg(pActor, "次数没了！", tstUI)
            Actor.sendTipmsgWithId(pActor, tmNoTimes, tstUI)--次数不足
            return
        end
    end

    --检查背包格子
    local awards = ActivityConfig[atvId].Persongift
    --if CommonFunc.Awards.CheckBagGridCount(pActor,awards) ~= true then
    --    return  
    --end
    if CommonFunc.Awards.CheckBagIsEnough(pActor,11,tmDefNoBagNum,tstUI) ~= true then
        return
    end

    -- 发放奖励
    CommonFunc.Awards.Give(pActor, awards, GameLog.Log_Activity12, "Activity12|"..atvId)
    
    --Actor.sendTipmsg(pActor, "成功领取奖励！", tstGetItem)

    -- 进入消耗
    local consumes = Conf.enterExpends
    -- if consumes then
    --     CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity12, OldLang.Log.l00093)
    -- end

    --扫荡附加消耗
    local saodangconusmes = Conf.saodangExpends
    if saodangconusmes then 
        CommonFunc.Consumes.Remove(pActor, saodangconusmes, GameLog.Log_Activity12, "材料副本活动|"..atvId)
    end 

    -- 消耗次数
    data.count = data.count - 1

    Actor.sendTipmsg(pActor, "扫荡成功", tstUI)

    -- 记录日志
    Actor.SendActivityLog(pActor,atvId,ActivityType,2)

    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
end

--请求进入副本
function reqEnterFuben(pActor, atvId, Conf, inPack)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)

    --开服天数不满足
    if (ActivityConfig[atvId].countstart or 0) > System.getDaysSinceOpenServer() then
        return 
    end
    
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
        if (ActivityConfig[atvId].countstart or 0) < System.getDaysSinceOpenServer() then 
            local multi = 1
            if ActivityConfig[atvId].isFromOpenSrv then
                multi = System.getDaysSinceOpenServer()
                multi = multi - (ActivityConfig[atvId].countstart or 0) + 1
            end
        
            if multi > 0 then 
                data.count = multi * (ActivityConfig[atvId].count or 1)
            else 
                data.count = 0  
            end 
        else 
            data.count = 0
        end 
        
    else
        if data.count <= 0 then
            --Actor.sendTipmsg(pActor, "次数没了！", tstUI)
            Actor.sendTipmsgWithId(pActor, tmNoTimes, tstUI)--次数不足
            return
        end
    end

    -- 记录日志
    Actor.SendActivityLog(pActor,atvId,ActivityType,1)


    --进入副本
   if  ActivityDispatcher.EnterFuben(atvId, pActor, Conf.fbId) ==nil then 
   end 

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
        multi = multi - (ActivityConfig[atvId].countstart or 0) + 1
    end

    if multi > 0 then 
        data.count = multi * (ActivityConfig[atvId].count or 1)
    else 
        data.count = 0  
    end 
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
        --print("[PActivity 12] "..Actor.getName(pActor).." 活动配置中找不到活动id："..atvId)
    end
    
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
--print("operatecode : "..operaCode)
    if operaCode == ActivityOperate.cEnterFuben then     -- 请求进入副本
        reqEnterFuben(pActor,atvId,Conf,inPack)
    elseif operaCode == ActivityOperate.cReqSaoDang then     -- 请求扫荡
        reqsaodang(pActor,atvId,Conf)
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
        if data.count >0 then 
            data.count = data.count - 1
        end 

        -- 消耗门票
        local consumes = Conf.enterExpends
        if consumes then
            CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity12, "材料副本活动|"..atvId)
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
            --Actor.ExOnQuestEvent(pOwner, CQuestData.qtFuben, 12);
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
                --if CommonFunc.Awards.CheckBagGridCount(pActor,awards) ~= true then
                --    return
                --end
                -- if CommonFunc.Awards.CheckBagIsEnough(pActor,11,tmDefNoBagNum,tstUI) ~= true then
                --    return
                -- end
                -- CommonFunc.Awards.Give(pActor, awards, GameLog.Log_Activity12, "Activity12")
                
                --邮件发送奖励
                local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
                local title = "材料副本任务奖励"
                local content = "恭喜您已完成材料副本任务！"
                SendMail(actorId, title, content, awards)
                Actor.sendTipmsg(pActor, "材料副本任务完成，奖励通过邮件发放！", tstGetItem)

                fbcache.hasGetAward = 1
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
    local limitzsLv  = 0 ;
    local cfg = ActivityConfig[atvId]
    if cfg and cfg.openParam then
        limitLv =  (cfg.openParam.level or 0)
        limitzsLv = (cfg.openParam.zsLevel or 0)
    end
    local lv = Actor.getIntProperty( pActor, PROP_CREATURE_LEVEL )
    local zsLv = Actor.getIntProperty(pActor, PROP_ACTOR_CIRCLE)
    if lv < limitLv then ret = 0 end
    if zsLv < zsLv then ret = 0 end 
    --开服天数不满足
    --if (ActivityConfig[atvId].countstart or 0) > System.getDaysSinceOpenServer() then
    --    ret = 0
    --end
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
ActivityDispatcher.Reg(ActivityEvent.OnCombineSrv, ActivityType, OnCombineSrv, "ActivityType12.lua")

ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType12.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType12.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType12.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType12.lua")
ActivityDispatcher.Reg(ActivityEvent.OnExitFuben, ActivityType, OnExitFuben, "ActivityType12.lua")
ActivityDispatcher.Reg(ActivityEvent.OnFubenFinish, ActivityType, OnFubenFinish, "ActivityType12.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqFubenAward, ActivityType, OnReqFubenAward, "ActivityType12.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType12.lua")

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 跨天，次数清零
function OnNewDayArrive(pActor,ndiffday)
    --print("[PActivity 12] "..Actor.getName(pActor).." 跨"..ndiffday.."天")
    local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
    if runAtvIdList == nil then 
        return 
    end
    for i,atvId in ipairs(runAtvIdList) do
        --print("[PActivity 12] "..Actor.getName(pActor).." 跨天加活动次数,atvId="..atvId)
        local data = ActivityDispatcher.GetActorData(pActor,atvId)
        if data.count == nil then
            data.count = 0
        end
        --跨天还是不满足开服天数要求
        if (ActivityConfig[atvId].countstart or 0) > System.getDaysSinceOpenServer() then 
            return 
        end 

        if ActivityConfig[atvId].IsAdd then
            data.count = data.count + ((ActivityConfig[atvId].count or 1) * ndiffday)
--print("----------diffday: "..ndiffday)
        else
            data.count = (ActivityConfig[atvId].count or 1)
        end

        -- 发送一个活动数据
        Actor.sendActivityData(pActor, atvId)
    end


end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType12.lua")
