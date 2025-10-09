module("ActivityType13", package.seeall)
math.randomseed(System.getCurrMiniTime())
--[[
    个人活动————驻守任务
    进副本扣进入消耗，通关扣取通关消耗及次数；
    次数与开服天数有关，从配置要求的开服天数以后开始每天叠加不清空；
    
    个人数据：ActorData[AtvId]
    {
        count,      当前的可进入次数
        
        atvStat，   活动状态，0 非进行状态， 1 驻守任务进行中, 2 任务成功
        sceneIdIndex,    随机分配的本次场景id
        timeIndex,  本次分配的时间index
        assignEndTime, 本次分配场景的结束时间

    }
]]--

--活动类型
ActivityType = 13
--对应的活动配置
ActivityConfig = Activity13Config
if ActivityConfig == nil then
    assert(false)
end


-----------------------------我是分界线---------------------------
-----------------------------功能函数-----------------------------
--成功完成邮件发放奖励
function onTaskSucc(atvId,pActor,awards)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
--print("-------------------data.count : "..data.count) 
    --邮件发送奖励
    local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    local title = "驻守任务奖励"
    local content = "恭喜您已完成驻守任务！"
    SendMail(actorId, title, content, awards)

    --消耗次数
    data.count = data.count - 1
    
--print("-------------------data.count : "..data.count)
    Actor.sendTipmsg(pActor, "驻守任务完成，奖励通过邮件发放", tstUI)

    --回到最近的回城点
    Actor.returnCity(pActor) 

    -- 记录日志
    Actor.SendActivityLog(pActor,atvId,ActivityType,2)
   
    --数据重置
    data.atvStat = 0  
    Actor.triggerAchieveEvent(pActor, nAchieveActivity,1 ,atvId);
    Actor.triggerAchieveEvent(pActor, nAchieveCompleteActivity,1 ,atvId);

    --发送一个活动数据
    Actor.sendActivityData(pActor, atvId)

end 








--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------
--请求扫荡
--使用扫荡券直接完成领奖
function reqsaodang(pActor, atvId, Conf)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)

    --开服天数不满足
    if ActivityConfig[atvId].countstart > System.getDaysSinceOpenServer() then 
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

    -- --次数检查
    -- if data.count == nil then
    --     if ActivityConfig[atvId].countstart < System.getDaysSinceOpenServer() then 
    --         local multi = 1
    --         if ActivityConfig[atvId].isFromOpenSrv then
    --             multi = System.getDaysSinceOpenServer()
    --             multi = multi - (ActivityConfig[atvId].countstart) +1 
    --         end
        
    --         if multi > 0 then 
    --             data.count = multi * (ActivityConfig[atvId].count or 1)
    --         else 
    --             data.count = 0  
    --         end 
    --     else 
    --         data.count = 0
    --     end 
    -- else 
        if data.count <= 0 then
            --Actor.sendTipmsg(pActor, "次数没了！", tstUI)
            Actor.sendTipmsgWithId(pActor, tmNoTimes, tstUI)--次数不足
            return
        end
--     end


    if data.atvStat == 2  then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:已处于驻守任务中|", tstUI)
        return 
    end 
    
    local awards = ActivityConfig[atvId].Persongift


    --检查背包格子
    local awards = ActivityConfig[atvId].Persongift
    if CommonFunc.Awards.CheckBagIsEnough(pActor,13,tmDefNoBagNum,tstUI) ~= true then
        return
    end
    -- 发放奖励
    CommonFunc.Awards.Give(pActor, awards, GameLog.Log_Activity13, "Activity13|"..atvId)

    --邮件发送奖励
    -- local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    -- local title = "驻守任务"
    -- local content = "恭喜您已完成驻守任务！"
    -- SendMail(actorId, title, content, awards)

    -- 消耗次数
    data.count = data.count - 1

    -- 进入消耗
    local consumes = Conf.enterExpends
    -- if consumes then
    --     CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity13, OldLang.Log.l00093)
    -- end

    --扫荡附加消耗
    local saodangconusmes = Conf.saodangExpends
    if saodangconusmes then 
        CommonFunc.Consumes.Remove(pActor, saodangconusmes, GameLog.Log_Activity13, "驻守任务|"..atvId)
    end 
--print("-------------------data.count : "..data.count)
    Actor.sendTipmsg(pActor, "扫荡成功", tstUI)

    -- 记录日志
    Actor.SendActivityLog(pActor,atvId,ActivityType,2)
    Actor.triggerAchieveEvent(pActor, nAchieveActivity,1 ,atvId);
    Actor.triggerAchieveEvent(pActor, nAchieveCompleteActivity,1 ,atvId);
    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
 
end


--请求进入驻守地图
function reqZhuShou(pActor, atvId, Conf)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)

    --开服天数不满足
    if ActivityConfig[atvId].countstart > System.getDaysSinceOpenServer() then 
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
    if Conf.enterExpends then
        consumes = Conf.enterExpends
        if CommonFunc.Consumes.CheckActorSources(pActor, consumes, tstUI) ~= true then
            return
        end
    end

    

    --次数检查
    -- if data.count == nil then
    --     if ActivityConfig[atvId].countstart < System.getDaysSinceOpenServer() then 
    --         local multi = 1
    --         if ActivityConfig[atvId].isFromOpenSrv then
    --             multi = System.getDaysSinceOpenServer()
    --             multi = multi - (ActivityConfig[atvId].countstart) +1 
    --         end
        
    --         if multi > 0 then 
    --             data.count = multi * (ActivityConfig[atvId].count or 1)
    --         else 
    --             data.count = 0  
    --         end 
    --     else 
    --         data.count = 0
    --     end 
        
    -- else
        if data.count <= 0 then
            --Actor.sendTipmsg(pActor, "次数没了！", tstUI)
            Actor.sendTipmsgWithId(pActor, tmNoTimes, tstUI)--次数不足
            return
        end
    --end

    local SceneIndex = 1 
    local timeIndex  = 1 


    if data.atvStat == nil then 
        data.atvStat = 0 
    end 

    if data.atvStat == 2  then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:已处于驻守任务中|", tstUI)
        return 
    end 

    --新进活动状态
    if data.atvStat ==0  then 
        
        if Conf.sceneTable.count then 
            SceneIndex = math.random(Conf.sceneTable.count)
        end 

        if Conf.durationTime.count then 
            timeIndex = math.random(Conf.durationTime.count)
        end 


        if Conf.sceneTable.Table[SceneIndex] then 
            --随机进入场景
            local mapId = Conf.sceneTable.Table[SceneIndex].mapid
            local posx = Conf.sceneTable.Table[SceneIndex].x
            local posy = Conf.sceneTable.Table[SceneIndex].y
            --随机进入场景
            Actor.enterScene(pActor , mapId , posx , posy ) 
        else 
            --print("enter scene error , please check activity config , atvId= "..atvId)
            return 
        end 
        data.assignEndTime = System.getCurrMiniTime() + Conf.durationTime.Table[timeIndex] 
    --挑战失败再次进入状态
    elseif data.atvStat == 1 then

        SceneIndex = data.sceneIdIndex 
        timeIndex  =  data.timeIndex

        if Conf.sceneTable.Table[SceneIndex] then 

            local mapId = Conf.sceneTable.Table[SceneIndex].mapid
            local posx = Conf.sceneTable.Table[SceneIndex].x
            local posy = Conf.sceneTable.Table[SceneIndex].y
            --进入场景
            Actor.enterScene(pActor, mapId , posx , posy)
        else 
            --print("enter scene error , please check activity config , atvId= "..atvId)
            return 
        end 

        data.assignEndTime = System.getCurrMiniTime() + Conf.durationTime.Table[timeIndex] 
    end 

    --消耗门票
    if consumes then
        CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity13, "驻守任务|"..atvId)
    end
    --数据设置
    data.atvStat = 2  
    data.sceneIdIndex = SceneIndex
    data.timeIndex = timeIndex

    --发送一个活动数据
    --Actor.sendActivityData(pActor, atvId)

    -- 记录日志
    Actor.SendActivityLog(pActor,atvId,ActivityType,1)

    --协议开始驻守flag
    local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendzhushoustatus)
    if  outPack then
        DataPack.writeByte(outPack, 66)
        DataPack.writeUInt(outPack, (Conf.durationTime.Table[timeIndex] or 0))
        --DataPack.writeUInt(outPack, (data.assignEndTime or 0))
        
        DataPack.flush(outPack)
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

        multi = multi - (ActivityConfig[atvId].countstart) +1 
    end

    if multi > 0 then 
        data.count = multi * (ActivityConfig[atvId].count or 1)
    else 
        data.count = (ActivityConfig[atvId].count or 1)  
    end 


    data.atvStat = 0  
    data.sceneIdIndex = 1 
    data.timeIndex = 1
    data.assignEndTime = 0 
end

-- 活动结束
function OnEnd(atvId, pActor)
    ActivityDispatcher.ClearActorData(pActor, atvId)
end

-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    -- if data.count ==nil then 
    --     local multi = 1
    --     if ActivityConfig[atvId].isFromOpenSrv then
    --         multi = System.getDaysSinceOpenServer()
    --         multi = multi - (ActivityConfig[atvId].countstart) +1 
    --     end

    --     if multi > 0 then 
    --         data.count = multi * (ActivityConfig[atvId].count or 1)
    --     else 
    --         data.count = 0  
    --     end 
    -- end 

    if data.atvStat ==nil then data.atvStat = 0 end 


    DataPack.writeByte(outPack, (data.atvStat or 0))
--print("-------------------data.count : "..data.count)
    DataPack.writeInt(outPack, (data.count or 0))
           
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- id对应配置
    local Conf = ActivityConfig[atvId]
    if Conf == nil then
        --print("[PActivity 13] "..Actor.getName(pActor).." 活动配置中找不到活动id："..atvId)
    end
    
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
--print("operateCode:  "..operaCode)
    if operaCode == ActivityOperate.cEnterFuben then     -- 请求进入副本
        reqZhuShou(pActor,atvId,Conf)
    elseif operaCode == ActivityOperate.cReqSaoDang then     -- 请求扫荡
        reqsaodang(pActor,atvId,Conf)
    end
end

-- 活动帧更新
function OnUpdate(atvId, curTime,pActor)
    local data =  ActivityDispatcher.GetActorData(pActor, atvId)
    if data.atvStat ==nil then data.atvStat = 0 end 

    if data.atvStat == 2 and (data.assignEndTime <= curTime)  then 
        local Conf = ActivityConfig[atvId]
        onTaskSucc(atvId,pActor,Conf.Persongift)
    end  

    math.randomseed(System.getCurrMiniTime())

end

--在普通野外地图的活动死亡
function OnAtvAreaDeath(atvId, pEntity)
    if pEntity and (Actor.getEntityType(pEntity) ==enActor) then 

        local data =  ActivityDispatcher.GetActorData(pEntity, atvId)
        if data.assignEndTime ~= nil  then 
            if (data.assignEndTime > System.getCurrMiniTime()) then 
                if data.atvStat == nil then 
                    data.atvStat = 0 
                end 
                if data.atvStat == 2 then 
                    data.atvStat = 1  
                    Actor.sendTipmsg(pEntity, "|C:0xf56f00&T:驻守任务失败|", tstUI)
                    --协议结束驻守flag
                    local outPack = ActivityDispatcher.AllocOperReturn(pEntity, atvId, ActivityOperate.sSendzhushoustatus)
                    if  outPack then
                        DataPack.writeByte(outPack, 0)
                        DataPack.writeUInt(outPack,  0)
                        --DataPack.writeUInt(outPack, (data.assignEndTime or 0))

                        DataPack.flush(outPack)
                    end
                end 
                
            end  
        end       
        
    end 
end 

-- 活动区域需要处理新增区域属性
function OnEnterArea(atvId, pActor)
    

end 


-- 离开活动区域
function OnExitArea(atvId, pActor)
    local data =  ActivityDispatcher.GetActorData(pActor, atvId)
 
    if data.assignEndTime ~= nil then 
        if (data.assignEndTime > System.getCurrMiniTime()) then 
            if data.atvStat == nil then 
                data.atvStat = 0 
            end 
            if data.atvStat == 2 then 
                data.atvStat = 1  
                Actor.sendTipmsg(pActor, "|C:0xf56f00&T:驻守任务失败|", tstUI)
                --协议结束驻守flag
                local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendzhushoustatus)
                if  outPack then
                    DataPack.writeByte(outPack, 0)
                    DataPack.writeUInt(outPack,  0)
                    --DataPack.writeUInt(outPack, (data.assignEndTime or 0))

                    DataPack.flush(outPack)
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
    if ActivityConfig[atvId].countstart > System.getDaysSinceOpenServer() then 
        ret = 0 
    end
    return ret
end

function OnCombineSrv(atvId, ndiffDay, pActor)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    if data.count == nil then
        data.count = 0
    end
    
    data.count = data.count + (1 * ndiffDay)
    
    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)


end 
ActivityDispatcher.Reg(ActivityEvent.OnCombineSrv, ActivityType, OnCombineSrv, "ActivityType13.lua")


ActivityDispatcher.Reg(ActivityEvent.OnAtvAreaDeath, ActivityType, OnAtvAreaDeath, "ActivityType13.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnterArea, ActivityType, OnEnterArea, "ActivityType13.lua")
ActivityDispatcher.Reg(ActivityEvent.OnExitArea, ActivityType, OnExitArea, "ActivityType13.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType13.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType13.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType13.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType13.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType13.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType13.lua")

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 跨天，次数清零
function OnNewDayArrive(pActor,ndiffday)
    --print("[PActivity 13] "..Actor.getName(pActor).." 跨"..ndiffday.."天")
    local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
    if runAtvIdList == nil then 
        return 
    end
    for i,atvId in ipairs(runAtvIdList) do
        --print("[PActivity 13] "..Actor.getName(pActor).." 跨天加活动次数,atvId="..atvId)
        local data = ActivityDispatcher.GetActorData(pActor,atvId)
        if data.count == nil then
            data.count = 0
        end
        --跨天还是不满足开服天数要求
        if ActivityConfig[atvId].countstart > System.getDaysSinceOpenServer() then 
            return 
        end
        --重置玩家活动状态
        if data.atvStat == nil or data.atvStat == 1    then 
            data.atvStat = 0  
        end  

        if ActivityConfig[atvId].isFromOpenSrv then
            data.count = data.count + ((ActivityConfig[atvId].count or 1) * ndiffday)
        else
            data.count = (ActivityConfig[atvId].count or 1)
        end

        -- 发送一个活动数据
        Actor.sendActivityData(pActor, atvId)
    end


end

function OnUserLogout(pActor,actorId)
    --local pActor = Actor.getActorById(actorId)

    local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
    if runAtvIdList == nil then 
        return 
    end
    for i,atvId in ipairs(runAtvIdList) do
        local data = ActivityDispatcher.GetActorData(pActor,atvId)
        if data.assignEndTime ~= nil then 
            if (data.assignEndTime > System.getCurrMiniTime()) then 
                if data.atvStat == nil then 
                    data.atvStat = 0 
                end 
                if data.atvStat == 2 then 
                    data.atvStat = 1  
                    Actor.sendTipmsg(pActor, "|C:0xf56f00&T:驻守任务失败|", tstUI)
                end 
                
            end  
        end 
    end

end 

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType13.lua")
ActorEventDispatcher.Reg(aeUserLogout, OnUserLogout, "ActivityType13.lua")

