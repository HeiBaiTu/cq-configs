module("ActivityType7", package.seeall)

--[[
    全局活动， 藏经峡谷，定时开放的打宝地图

    个人数据：ActorData[AtvId]
    {
 
    }

    全局缓存：Cache[AtvId]
    {
        fbHandle,               记录当前活动创建的副本，这个是多人副本，强制活动结束后才销毁
        scenHandle,             记录当前副本的场景
        actors = {actorid,...}  记录活动副本中的玩家id
    }

    全局数据：GlobalData[AtvId]
    {
       
    }
]]--

--活动类型
ActivityType = 7
--对应的活动配置
ActivityConfig = Activity7Config
if ActivityConfig == nil then
    assert(false)
end


--活动状态
local broadcastflags = {}
--broadcastflags[atvId]: 0 活动开始前的广播阶段
--broadcastflags[atvId]: 1 活动开始
--broadcastflags[atvId]: 666 剩余十分钟

--在场景中的玩家
actorsInFuben = {}
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
                        local fbHandle = Actor.getFubenHandle(pActor)
                        if cacheData.fbHandle == fbHandle then
                            actorsInFuben[atvId][actorId] = actorId
                        end
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

--请求进入副本
function reqEnterFuben(pActor, atvId)
    --local actorData = ActivityDispatcher.GetActorData(pActor,atvId)

    if ActivityConfig[atvId].openParam.level  then
       
        local actor_level = ActivityConfig[atvId].openParam.level
        if Actor.checkActorLevel(pActor,actor_level) ~=true then
            -- Actor.sendTipmsg(pActor, "等级不足!", tstEcomeny)
            return 
        end

    end

    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    --消耗检查
    local consumes = nil
    if ActivityConfig[atvId].enterExpends then
        consumes = ActivityConfig[atvId].enterExpends
        if CommonFunc.Consumes.CheckActorSources(pActor, consumes, tstUI) ~= true then
            return
        end
    end

    

    --进入副本
   local fbHandle = ActivityDispatcher.EnterFuben(atvId, pActor, ActivityConfig[atvId].fbId)
   if fbHandle then
        -- 消耗
        if consumes and CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity7, "藏经峡谷|"..atvId) ~= true then
            return
        end

        -- 记录进入的玩家
        local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
        if cacheData.actors == nil then
            cacheData.actors = {}
        end
        cacheData.actors[actorId] = actorId

        if actorsInFuben[atvId] == nil then
            actorsInFuben[atvId] = {}
        end
        actorsInFuben[atvId][actorId] = actorId
        Actor.triggerAchieveEvent(pActor, nAchieveActivity,1 ,atvId);
        Actor.triggerAchieveEvent(pActor, nAchieveCompleteActivity,1 ,atvId);
        -- 记录日志
        Actor.SendActivityLog(pActor,atvId,ActivityType,1)
   end

   

end


-- 踢出副本
function KickoutAllActors(atvId)
    if actorsInFuben[atvId] then
        for i,actorid in pairs(actorsInFuben[atvId]) do
            local pActor = Actor.getActorById(actorid)
            if pActor ~= nil then
                Actor.exitFubenAndBackCity(pActor)
            end
        end
        actorsInFuben[atvId] = nil
    end
end

-- 设置复活，正常回城复活
function SetAutoRelive(atvId,pActor)     
    local actorid = Actor.getActorId(pActor)
    actorsInFuben[atvId][actorid] = nil
    Actor.relive(pActor)
    Actor.clearReliveTimeOut(pActor)
    --Actor.setReliveTimeOut(pActor, 10)
    Actor.exitFubenAndBackCity(pActor)

    return
end

--------------------------------------------------------------------
-- 活动 回调注册
--------------------------------------------------------------------

-- 加载活动时（启动服务器从数据库返回的）
function OnLoad(atvId)
    --print("[GActivity 7] 藏经峡谷 活动数据加载，id："..atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local fbid = ActivityConfig[atvId].fbId
    local defsceneid = StaticFubens[fbid].defSceneID or StaticFubens[fbid].scenes[1]
    local fbHandle = Fuben.createFuBen(fbid)
    local scenHandle = Fuben.getSceneHandleById(defsceneid, fbHandle)
    cacheData.fbHandle = fbHandle
    cacheData.scenHandle = scenHandle
    Fuben.useDefaultCreateMonster(fbHandle, true)
end

-- 初始化玩家数据
function OnInit(atvId, pActor)
    --print("[GActivity 7] 藏经峡谷 "..Actor.getName(pActor).." 初始化 id："..atvId)
end

-- 活动开始
function OnStart(atvId)


    System.broadcastTipmsg("藏经峡谷将于5分钟后开放，请勇士们做好准备！",tstRevolving);

    broadcastflags[atvId] = 0
   

    ActivityDispatcher.ClearCacheData(atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    cacheData.actors = {}

    --创建副本并记录
    local fbid = ActivityConfig[atvId].fbId
    local defsceneid = StaticFubens[fbid].defSceneID or StaticFubens[fbid].scenes[1]
    local fbHandle = Fuben.createFuBen(fbid)
    local scenHandle = Fuben.getSceneHandleById(defsceneid, fbHandle)
    cacheData.fbHandle = fbHandle
    cacheData.scenHandle = scenHandle

    Fuben.useDefaultCreateMonster(fbHandle, true)

end

-- 活动结束
function OnEnd(atvId)
    --print("[Activity 7] 藏经峡谷 活动结束了，id："..atvId)
    broadcastflags[atvId] = 0
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    -- 踢出副本
    KickoutAllActors( atvId )
    -- 关闭副本
    Fuben.closeFuben( cacheData.fbHandle )
    -- 清空活动数据
    ActivityDispatcher.ClearCacheData( atvId )
end






-- 活动帧更新
function OnUpdate(atvId, curTime)
    --local cacheData = ActivityDispatcher.GetCacheData(atvId)

    --活动开始的提示
    if (System.isReachSecondBeforeActivityEnd(atvId,1800) ==true and broadcastflags[atvId] == 0 )then
        
        System.broadcastTipmsg("藏经峡谷已经开放，勇士们抓紧时间进入",tstChatSystem)
        System.broadcastTipmsg("藏经峡谷已经开放，勇士们抓紧时间进入",tstRevolving)
        broadcastflags[atvId] = 1

        System.sendAllActorOneActivityData(atvId) ;

        -- if actorsInFuben[atvId] then
        --     for i,actorid in pairs(actorsInFuben[atvId]) do
        --         local pActor = Actor.getActorById(actorid)
        --         if pActor ~= nil then
        --             -- 发送一个活动数据
        --             Actor.sendActivityData(pActor, atvId)
        --         end
        --     end
        -- end
        
    end
    
   

    --剩余十分钟的提示
    if( System.isReachSecondBeforeActivityEnd(atvId,600) ==true and broadcastflags[atvId] == 1) then
        System.broadcastTipmsg("藏经峡谷将于10分钟后关闭，勇士们抓紧时间进入",tstRevolving);
        broadcastflags[atvId] = 666
    end

end

-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    --活动前通告阶段不进入
    if broadcastflags[atvId] ==0 then
        Actor.sendTipmsg(pActor, "该活动暂未开启", tstUI)
        return 
    end 
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cEnterFuben then     -- 请求进入副本
        reqEnterFuben(pActor, atvId)
    end
end

--玩家退出活动副本
function OnExitFuben(atvId, pActor, pFuben)
    -- 玩家退出，从记录中排除
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    if cacheData.actors == nil then
        cacheData.actors = {}
    end
    local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    actorsInFuben[atvId][actorId] = nil
    
    -- 记录日志
    Actor.SendActivityLog(pActor,atvId,ActivityType,2)
end

--实体在活动副本中死亡
function OnEntityDeath(atvId, pEntity,pKiller,pFuben)
    
    if pEntity and Actor.getEntityType(pEntity) == enActor then
        -- 设置复活
        --SetAutoRelive(atvId, pEntity)
    end
end


--活动红点数据
function OnGetRedPoint(atvId, pActor)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    local ret = 0
    if broadcastflags[atvId] ~=0  then ret = 1 end
    local cfg = ActivityConfig[atvId]
    if cfg and cfg.openParam then
        if Actor.checkActorLevel(pActor,(cfg.openParam.level or 0)) ~=true then ret = 0 end
    end
    return ret

    
end
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType7.lua")




ActivityDispatcher.Reg(ActivityEvent.OnLoad, ActivityType, OnLoad, "ActivityType7.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType7.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType7.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType7.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType7.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType7.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType7.lua")
ActivityDispatcher.Reg(ActivityEvent.OnExitFuben, ActivityType, OnExitFuben, "ActivityType7.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEntityDeath, ActivityType, OnEntityDeath, "ActivityType7.lua")

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------
