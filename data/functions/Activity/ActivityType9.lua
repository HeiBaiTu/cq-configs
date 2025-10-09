module("ActivityType9", package.seeall)

--[[
    全局活动， 独闯天涯，定时开放的闯关地图,每层10个怪客户端也是写死的，修改需要客户端同步改

    个人数据：ActorData[AtvId]
    {
        count, 剩余领取个人宝箱次数
        uint_times, 分配礼包次数时候的时间，用这个保证只领一次

        bigTreasurecount ，剩余神秘大奖领取次数
        uint_times_big, 分配神秘大奖时候的时间，用这个保证只领一次

        --floorNow  ,当前闯到第几层了
        monsterCount  ,当前层杀怪数
        
    }


    全局缓存：Cache[AtvId]
    {
        fbHandle,               记录当前活动创建的副本，这个是多人副本，强制活动结束后才销毁
        scenHandle,             记录当前副本的场景
        actors = {actorid,...}  记录活动副本中的玩家id

        bigTreasureNum ,         排名奖励剩余礼包数量，策划上是50个
    }

    全局数据：GlobalData[AtvId]
    {
       
    }
]]--

--活动类型
ActivityType = 9
--对应的活动配置
ActivityConfig = Activity9Config
if ActivityConfig == nil then
    assert(false)
end

actorsInFuben = {}

local broadcastflags = {}
--broadcastflags[atvId]: 0 活动开始前的10min
--broadcastflags[atvId]: 1 活动开启前的1min
--broadcastflags[atvId]: 2 活动开始
--broadcastflags[atvId]: 666 剩余十分钟


--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------

--每次进入副本都从新开始
function ClearQuestState(atvId,pActor)
    
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    actorData.monsterCount = 0
end 

--请求进入副本
function reqEnterFuben(pActor, atvId)
    --local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    if data.uint_times ==nil then
        data.uint_times = 0
    end
    if data.count ==nil then
        data.count = 1
    end
    

    --进入限制检查
    if System.getActivityEndMiniSecond(atvId)==0 then 
        --Actor.sendTipmsg(pActor, "获取活动时间错误", tstUI)
        return
    end

    if data.count == 0 and data.uint_times ~=System.getActivityEndMiniSecond(atvId) then
        data.count = 1 
    end

    if data.count <=0 then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:您已完成独闯天涯挑战 无法再次参加|", tstUI)
        return 
    end

    if ActivityConfig[atvId].openParam.level  then
        local actor_level = ActivityConfig[atvId].openParam.level
        if Actor.checkActorLevel(pActor,actor_level) ~=true then
            -- Actor.sendTipmsg(pActor, "|C:0xf56f00&T:等级不足", tstEcomeny)
            return 
        end

    end


    --消耗检查
    local consumes = nil
    if ActivityConfig[atvId].enterExpends then
        consumes = ActivityConfig[atvId].enterExpends
        if CommonFunc.Consumes.Check(pActor, consumes) ~= true then
            -- Actor.sendTipmsg(pActor, "|C:0xf56f00&T:绑金不足", tstEcomeny)
            Actor.sendTipmsgWithId(pActor, tmNeedItemNotEnough, tstUI)
            return
        end
    end

    ClearQuestState(atvId,pActor)

    --进入副本
   local fbHandle = ActivityDispatcher.EnterFuben(atvId, pActor, ActivityConfig[atvId].fbId)
   if fbHandle then
        -- 消耗
        if consumes and CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity9, "独闯天涯|"..atvId) ~= true then
            return
        end

        -- 记录日志
        Actor.SendActivityLog(pActor,atvId,ActivityType,1)

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
        --print("atvId = "..atvId.." actorId="..actorsInFuben[atvId][actorId])
    else  --print("___________________________________________enterFuben error ")
   end

   

end

--领取个人物品奖励
function getGiftBox(pActor,atvId,Conf,inPack)
    local errorcode = 0
 
    local data = ActivityDispatcher.GetActorData(pActor,atvId)

    if Actor.getFubenId(pActor) ~= Conf.fbId then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:请在夺宝战七层领取奖励|", tstUI)
        return 
    end 

  
    while(true)
    do
        if data.uint_times ==nil then
            data.uint_times = 0
        end
        if data.count ==nil then
            data.count = 1
        end
        

        --次数检查
        if System.getActivityEndMiniSecond(atvId)==0 then 
            --Actor.sendTipmsg(pActor, "获取活动时间错误", tstUI)
            break
        end

        if data.count == 0 and data.uint_times ~=System.getActivityEndMiniSecond(atvId) then
            data.count = 1
        else
            if data.count <=0 then
                Actor.sendTipmsgWithId(pActor, tmGetChuangGuanGiftYet, tstUI)
                errorcode = 1
                break
            end
        end
     
        

        if Conf.Persongift then
            CommonFunc.GiveCommonAward(pActor, Conf.Persongift, GameLog.Log_Activity9, "独闯天涯个人奖励|"..atvId)
            Actor.sendTipmsgWithId(pActor, tmGetChuangGuanGiftSucc, tstUI)
        end
        data.uint_times =System.getActivityEndMiniSecond(atvId)
        -- 操作成功
        --print("count:",data.count)
        data.count = 0
        Actor.triggerAchieveEvent(pActor, nAchieveActivity,1 ,atvId);
        Actor.triggerAchieveEvent(pActor, nAchieveCompleteActivity,1 ,atvId);
        --print("count now=:"..data.count)

        -- 记录日志
        Actor.SendActivityLog(pActor,atvId,ActivityType,2)

        -- 发送一个活动数据
        Actor.sendActivityData(pActor, atvId)
        
        break
    end

    local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendPersonBox)
    -- local netPack = DataPack.allocPacket(pActor,enActivityID, sSendPersonActivityUpdate)
    if  outPack then
        -- DataPack.writeUInt(outPack, nId)
       -- DataPack.writeByte(outPack, nIndex)
        DataPack.writeByte(outPack, errorcode) 
        DataPack.flush(outPack)
    end

end 


--请求领取排名奖励， 限制50个
function getBigTreasure(pActor, atvId, Conf, inPack)
    local errorcode = 1
 
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)

    if Actor.getFubenId(pActor) ~= Conf.fbId then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:请在夺宝战七层领取奖励|", tstUI)
        return 
    end 

    
    while(true)
    do

        if data.uint_times_big ==nil then
            data.uint_times_big = 0
        end
        if data.bigTreasurecount ==nil then
            data.bigTreasurecount = 1
        end

        --一场活动只能领一个
        if System.getActivityEndMiniSecond(atvId)==0 then 
            --Actor.sendTipmsg(pActor, "获取活动时间错误", tstUI)
            break
        end

        if data.bigTreasurecount == 0 and data.uint_times_big ~=System.getActivityEndMiniSecond(atvId) then
            data.bigTreasurecount = 1 
        else
            if data.bigTreasurecount <=0 then
                Actor.sendTipmsgWithId(pActor, tmGetSpeedAwardYet, tstUI)
                errorcode = 1
                break       --已领取，break
            end
        end

        --总的可领取次数检查
        if cacheData.bigTreasureNum == nil then
            cacheData.bigTreasureNum = Conf.bigTreasureNum
        else
            if cacheData.bigTreasureNum <= 0 then
                Actor.sendTipmsg(pActor, "神速礼包已发放完毕", tstUI)
                break       --奖励发放完毕，break
            end
        end

        --检测格子
        if CommonFunc.Awards.CheckBagIsEnough(pActor,1,tmDefNoBagNum,tstUI) ~= true then
            return
        end
     
        --领取神秘大奖，排名奖励
        if Conf.bigTreasure and data.bigTreasurecount == 1 then
            --CommonFunc.GiveCommonAward(pActor, Conf.bigTreasure, GameLog.Log_Activity9, "独闯天涯排名奖励|"..atvId)  
            CommonFunc.Awards.Give(pActor, Conf.bigTreasure, GameLog.Log_Activity9, "独闯天涯排名奖励|"..atvId)  
            Actor.sendTipmsgWithId(pActor, tmGetSpeedAwardSucess, tstUI)
            errorcode = 0
        end
        -- 操作成功
        --print("排名奖励:",cacheData.bigTreasureNum)
        if cacheData.bigTreasureNum >0 then
            cacheData.bigTreasureNum = cacheData.bigTreasureNum -1
        end

        data.bigTreasurecount = 0
        data.uint_times_big =System.getActivityEndMiniSecond(atvId)

        --print("排名奖励 个数剩余=:"..cacheData.bigTreasureNum)
        
        break
    end

   
     local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendBonusNum)
     -- local netPack = DataPack.allocPacket(pActor,enActivityID, sSendPersonActivityUpdate)
     if  outPack then
         -- DataPack.writeUInt(outPack, nId)
        -- DataPack.writeByte(outPack, nIndex)
         DataPack.writeByte(outPack, cacheData.bigTreasureNum) 
         --DataPack.writeByte(outPack, errorcode) 
         DataPack.flush(outPack)
     end



end

--请求奖励数量
function getBonusNums(pActor, atvId, Conf, inPack)

    

    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    if cacheData.bigTreasureNum == nil then
        cacheData.bigTreasureNum = Conf.bigTreasureNum
    end 
    local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendBonusNum)
    -- local netPack = DataPack.allocPacket(pActor,enActivityID, sSendPersonActivityUpdate)
    if  outPack then
        -- DataPack.writeUInt(outPack, nId)
       -- DataPack.writeByte(outPack, nIndex)
        DataPack.writeByte(outPack, cacheData.bigTreasureNum) 
--print("---------------------------------------cacheData.bigTreasureNum"..cacheData.bigTreasureNum)
        DataPack.flush(outPack)
    end
end 

--请求当前刷怪数
function getMonsterNums(pActor, atvId, Conf, inPack)
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)

    local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendMonsterNum)
    -- local netPack = DataPack.allocPacket(pActor,enActivityID, sSendPersonActivityUpdate)
    if  outPack then
        -- DataPack.writeUInt(outPack, nId)
       -- DataPack.writeByte(outPack, nIndex)
       if actorData.monsterCount > 127 then
            actorData.monsterCount = 127
       end
        DataPack.writeByte(outPack, actorData.monsterCount) 
        --DataPack.writeByte(outPack, 10) 
        DataPack.flush(outPack)
    end
end 

-- 踢出副本
function KickoutAllActors(atvId)
    if actorsInFuben ==nil then
        return 
    end 
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
    --print("[GActivity 9] 独闯天涯 活动数据加载，id："..atvId)
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
    --print("[GActivity 9] 独闯天涯 "..Actor.getName(pActor).." 初始化 id："..atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    actorData.deathLimit = nil
    actorData.nextLoginTime = nil
end

-- 活动开始
function OnStart(atvId)
    --System.broadcastTipmsg("独闯天涯活动将在10分钟后开启，请各位勇士做好准备",tstRevolving);
    --System.broadcastTipmsg("独闯天涯活动将在10分钟后开启，请各位勇士做好准备",tstChatNotice)
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
    cacheData.bigTreasureNum = nil

    Fuben.useDefaultCreateMonster(fbHandle, true)
end

-- 活动结束
function OnEnd(atvId)
    --print("[Activity 9] 独闯天涯 活动结束了，id："..atvId)
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

    --活动开始前1min的提示
    if (broadcastflags[atvId] == 0 )then
        
        --System.broadcastTipmsg("独闯天涯活动将在1分钟后开启，请各位勇士做好准备",tstRevolving)
        --System.broadcastTipmsg("独闯天涯活动将在1分钟后开启，请各位勇士做好准备",tstChatNotice)
        broadcastflags[atvId] = 1
    end
    
    --活动开始的提示
    if( broadcastflags[atvId] == 1) then
        System.broadcastTipmsg("独闯天涯活动已开启，请各位勇士积极参与",tstRevolving)
        System.broadcastTipmsg("独闯天涯活动已开启，请各位勇士积极参与",tstChatNotice)
        broadcastflags[atvId] = 2
        ActivityDispatcher.BroadPopup(atvId);

        if actorsInFuben[atvId] then
            for i,actorid in pairs(actorsInFuben[atvId]) do
                local pActor = Actor.getActorById(actorid)
                if pActor ~= nil then
                    -- 发送一个活动数据
                    Actor.sendActivityData(pActor, atvId)
                end
            end
        end
    end

    --活动结束前10min的提示
    if( System.isReachSecondBeforeActivityEnd(atvId,600) ==true and broadcastflags[atvId] == 2) then
        System.broadcastTipmsg("独闯天涯活动将在十分钟后关闭入口，请还未参加活动的勇士抓紧时间",tstRevolving)
        System.broadcastTipmsg("独闯天涯活动将在十分钟后关闭入口，请还未参加活动的勇士抓紧时间",tstChatNotice)
        broadcastflags[atvId] = 666
    end

end

-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)

--测试用完删
--broadcastflags[atvId] = 2 
--测试用完删


    --活动前通告阶段不进入
    if broadcastflags[atvId] <2 then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:该活动暂未开启|", tstUI)
        return 
    end 

    -- id对应配置
    local Conf = ActivityConfig[atvId]
    if Conf == nil then
        --print("[Activity 4] "..Actor.getName(pActor).." 活动配置中找不到活动id："..atvId)
    end
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
--print("__________________________________before request___________________operator: "..operaCode)
    -- 请求进入副本
    if operaCode == ActivityOperate.cEnterFuben then     
        reqEnterFuben(pActor, atvId)
    end

    --领取奖励
    if operaCode == ActivityOperate.cGetPersonBox then     
        getGiftBox(pActor,atvId,Conf,inPack)
    end

    --请求排名奖励，先到先得50个
    if operaCode == ActivityOperate.cGetTreasure then     
        getBigTreasure(pActor,atvId,Conf,inPack)
    end

    --npc请求排名奖励剩余个数
    if operaCode == ActivityOperate.cGetBonusNum then 
        getBonusNums(pActor, atvId, Conf, inPack)
    end

    --npc请求当前刷怪数
    if  operaCode == ActivityOperate.cGetMonsterNum then 
        getMonsterNums(pActor, atvId, Conf, inPack)
    end 
end

function OnEnterFuben(atvId, pActor, pFuben)
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)

    local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendMonsterNum)
    -- local netPack = DataPack.allocPacket(pActor,enActivityID, sSendPersonActivityUpdate)
    if  outPack then
       
        DataPack.writeByte(outPack, 0) 
        DataPack.flush(outPack)
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
end

--实体在活动副本中死亡
function OnEntityDeath(atvId, pEntity,pKiller,pFuben)
    
    if pEntity and Actor.getEntityType(pEntity) == enActor then
        -- 设置复活
        --SetAutoRelive(atvId, pEntity)
    end
    if pEntity and Actor.getEntityType(pEntity) == enMonster then
        if pKiller and Actor.getEntityType(pKiller) == enActor then 
            local actorData = ActivityDispatcher.GetActorData(pKiller,atvId)
            if actorData.monsterCount ==nil then
                actorData.monsterCount = 0
            end 
            actorData.monsterCount = actorData.monsterCount +1 

            local outPack = ActivityDispatcher.AllocOperReturn(pKiller, atvId, ActivityOperate.sSendMonsterNum)
            -- local netPack = DataPack.allocPacket(pActor,enActivityID, sSendPersonActivityUpdate)
            if  outPack then
                
               if actorData.monsterCount > 127 then
                    actorData.monsterCount = 127
               end
                DataPack.writeByte(outPack, actorData.monsterCount) 
                --DataPack.writeByte(outPack, 10) 
                DataPack.flush(outPack)
            end

            if actorData.monsterCount < 10 then 
                Actor.sendTipmsg(pKiller, "当前已击杀怪物"..actorData.monsterCount.."/10", tstUI)
            else 
                Actor.sendTipmsgWithId(pKiller, tmkillMonsterEnoughYet, tstUI)
            end 
        end 
    end 
end


--活动红点数据
function OnGetRedPoint(atvId, pActor)
    local ret = 1
    local data = ActivityDispatcher.GetActorData(pActor,atvId)

    if (broadcastflags[atvId] <2) or (data.count and (data.count == 0 )) then
        ret = 0
    end

    local cfg = ActivityConfig[atvId]
    if cfg and cfg.openParam then
        if Actor.checkActorLevel(pActor,(cfg.openParam.level or 0)) ~=true then ret = 0 end
    end   
    return ret
end
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType9.lua")

ActivityDispatcher.Reg(ActivityEvent.OnLoad, ActivityType, OnLoad, "ActivityType9.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType9.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType9.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType9.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType9.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType9.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType9.lua")
ActivityDispatcher.Reg(ActivityEvent.OnExitFuben, ActivityType, OnExitFuben, "ActivityType9.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEntityDeath, ActivityType, OnEntityDeath, "ActivityType9.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnterFuben, ActivityType, OnEnterFuben, "ActivityType9.lua") 

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------