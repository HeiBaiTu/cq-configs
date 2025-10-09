module("ActivityType28", package.seeall)


--[[
    全局活动，秘境打宝 

    个人数据：actorData[AtvId]
    {
        nextLoginTime,  退出后下次可进来的时间戳
    }

    全局数据：GlobalData[AtvId]
    {
        actors = {actorid,...}                      记录活动副本中的玩家id
        secretBoxScore={actorid=scores ,...}        记录活动副本中的玩家秘境宝箱数量(积分)
	    wordsBoxScore={actorid=scores ,...} 		记录活动副本中的玩家字诀宝箱数量(积分)
	    materialsBoxScore={actorid=scores ,...} 	记录活动副本中的玩家材料宝箱数量(积分)
        clearGlobalData = nil or 1                  记录活动副本中是否需要清理全局活动数据
    }

    全局缓存：Cache[AtvId]
    {
        fbHandle,                       记录当前活动创建的副本，这个是多人副本，强制活动结束后才销毁
    }
]]--


--活动类型
ActivityType = 28
--对应的活动配置
ActivityConfig = Activity28Config


--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------

-- 请求进入副本
function reqEnterFuben(pActor, atvId)
    print("ActivityType28 reqEnterFuben 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor).." 角色Id : "..Actor.getIntProperty( pActor, PROP_ENTITY_ID ))

    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)

    -- 清空数据
    if globalData.clearGlobalData then
        ClearSecretGlobalData(atvId)
    end

    --退出后登入的时间限制
    if actorData.nextLoginTime and actorData.nextLoginTime > System.getCurrMiniTime()  then
        Actor.sendTipmsg(pActor, "请30秒后再进入！")
        return
    end

    --等级、转身等级限制
    local nLimitLv = 0
    local nLimitZSLv  = 0 
    if ActivityConfig and ActivityConfig[atvId] and ActivityConfig[atvId].openParam then
        nLimitLv =  (ActivityConfig[atvId].openParam.level or 0)
        nLimitZSLv = (ActivityConfig[atvId].openParam.zsLevel or 0)
    end
    local nLv = Actor.getIntProperty( pActor, PROP_CREATURE_LEVEL )
    local nZSLv = Actor.getIntProperty(pActor, PROP_ACTOR_CIRCLE)
    if nLv < nLimitLv then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:等级不足|", tstUI) 
        return 
    end
    if nZSLv < nLimitZSLv then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:转身不足|", tstUI)
        return 
    end 

    --消耗检查
    local consumes = nil
    if ActivityConfig[atvId].enterExpends then
        consumes = ActivityConfig[atvId].enterExpends
        if CommonFunc.Consumes.Check(pActor, consumes) ~= true then
            Actor.sendTipmsgWithId(pActor, tmNeedItemNotEnough, tstUI)
            return
        end
    end

    -- 消耗
    if consumes and CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity28, "秘境打宝|"..atvId) ~= true then
        return
    end

    --进入副本
    local fbHandle = ActivityDispatcher.EnterFuben(atvId, pActor, ActivityConfig[atvId].fbId)
    if fbHandle then
        -- 重置下次进入时间
        actorData.nextLoginTime = nil

        -- 记录进入的玩家
        local nActorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
        if nil == globalData.actors then
            globalData.actors = {}
        end
        globalData.actors[nActorId] = nActorId
        if nil == globalData.secretBoxScore then
            globalData.secretBoxScore = {}
        end
        if nil == globalData.wordsBoxScore then
            globalData.wordsBoxScore = {}
        end
        if nil == globalData.materialsBoxScore then
            globalData.materialsBoxScore = {}
        end

        -- 发送 秘境打宝 玩家的秘境宝箱数量(积分)、字诀宝箱数量(积分)、材料宝箱数量(积分)
        SendActorTypesScore(atvId, pActor)

        -- 发送本场活动剩余时间
        local npack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendTime)
        if npack then
            DataPack.writeByte(npack, 0)
            
            local nEndTime = System.getActivityEndMiniSecond(atvId)
            local nLeftTime = nEndTime - System.getCurrMiniTime()
            
            DataPack.writeUInt(npack, nLeftTime)
            DataPack.flush(npack)
        end

        -- 进入副本
        Actor.SendActivityLog(pActor,atvId,ActivityType,1)
    end
end

-- 请求 秘境宝箱数量(积分)、字诀宝箱数量(积分)、材料宝箱数量(积分)
function OnReqTypesScore(pActor, packet)
    print("ActivityType28 OnReqTypesScore 玩家 "..Actor.getName(pActor))

    local nActivityId = DataPack.readByte(packet)
    if not nActivityId or not ActivityConfig or not ActivityConfig[nActivityId] then
        print("ActivityType28 OnReqTypesScore 玩家 "..Actor.getName(pActor).." not nActivityId or not ActivityConfig or not ActivityConfig[nActivityId]")
        return
    end

    local globalData = ActivityDispatcher.GetGlobalData(nActivityId)
    if nil == globalData.secretBoxScore or nil == globalData.wordsBoxScore or nil == globalData.materialsBoxScore then
        print("ActivityType28 OnReqTypesScore 玩家 "..Actor.getName(pActor).." nil == globalData.secretBoxScore or nil == globalData.wordsBoxScore or nil == globalData.materialsBoxScore")
        return
    end

    SendActorTypesScore(nActivityId, pActor)
end

-- 更新 秘境打宝 玩家的秘境宝箱数量(积分)、字诀宝箱数量(积分)、材料宝箱数量(积分)
function UpdateActorTypesScore(atvId, pActor, nScoresType, nScore)
    print("ActivityType28 UpdateActorTypesScore 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor).." 角色Id : "..Actor.getIntProperty( pActor, PROP_ENTITY_ID ).." nScoresType : "..nScoresType.." nScore : "..nScore)
    
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    local nActorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    if nil == globalData.actors or nil == globalData.actors[nActorId] then
        print("ActivityType28 UpdateActorTypesScore nil == globalData.actors or nil == globalData.actors[nActorId] 玩家 : "..Actor.getName(pActor))
        return
    end

    if qatSecretBoxScore == nScoresType then
        globalData.secretBoxScore[nActorId] = (globalData.secretBoxScore[nActorId] or 0) + nScore
        print("ActivityType28 UpdateActorTypesScore 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor).." 当前秘境宝箱积分 : "..globalData.secretBoxScore[nActorId])
    elseif qatWordsBoxScore == nScoresType then
        globalData.wordsBoxScore[nActorId] = (globalData.wordsBoxScore[nActorId] or 0) + nScore
        print("ActivityType28 UpdateActorTypesScore 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor).." 当前字诀宝箱积分 : "..globalData.wordsBoxScore[nActorId])
    elseif qatMaterialsBoxScore == nScoresType then
        globalData.materialsBoxScore[nActorId] = (globalData.materialsBoxScore[nActorId] or 0) + nScore
        print("ActivityType28 UpdateActorTypesScore 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor).." 当前材料宝箱积分 : "..globalData.materialsBoxScore[nActorId])
    end

    SendActorTypesScore(atvId, pActor)
end

-- 发送 秘境打宝 玩家的秘境宝箱数量(积分)、字诀宝箱数量(积分)、材料宝箱数量(积分)
function SendActorTypesScore(atvId, pActor)
    print("ActivityType28 SendActorTypesScore 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))
    
    local npack = DataPack.allocPacket(pActor, enActivityID, sSendActorTypesScores)
    if npack then
        local globalData = ActivityDispatcher.GetGlobalData(atvId)
        local nActorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
        DataPack.writeUInt(npack, globalData.secretBoxScore[nActorId] or 0)
        DataPack.writeUInt(npack, globalData.wordsBoxScore[nActorId] or 0)
        DataPack.writeUInt(npack, globalData.materialsBoxScore[nActorId] or 0)
        DataPack.flush(npack)
    end
end

-- 发送 活动奖励
function SendAward(atvId)
    print("ActivityType28 SendAward 活动Id ："..atvId)

    if not ActivityConfig or not ActivityConfig[atvId] then
        print("ActivityType28 SendAward not ActivityConfig or not ActivityConfig[atvId]")
        return
    end

    if not ActivityConfig[atvId].AwardA or "table" ~= type(ActivityConfig[atvId].AwardA) or #ActivityConfig[atvId].AwardA < 1 or not ActivityConfig[atvId].mailTitle1 or not ActivityConfig[atvId].mailContent1 then
        print("ActivityType28 SendAward not ActivityConfig[atvId].AwardA or table ~= type(ActivityConfig[atvId].AwardA) or #ActivityConfig[atvId].AwardA < 1 or not ActivityConfig[atvId].mailTitle1 or not ActivityConfig[atvId].mailContent1")
        return
    end

    if not ActivityConfig[atvId].AwardB or "table" ~= type(ActivityConfig[atvId].AwardB) or #ActivityConfig[atvId].AwardB < 1 or not ActivityConfig[atvId].mailTitle1 or not ActivityConfig[atvId].mailContent1 then
        print("ActivityType28 SendAward not ActivityConfig[atvId].AwardB or table ~= type(ActivityConfig[atvId].AwardB) or #ActivityConfig[atvId].AwardB < 1 or not ActivityConfig[atvId].mailTitle1 or not ActivityConfig[atvId].mailContent1")
        return
    end

    if not ActivityConfig[atvId].AwardC or "table" ~= type(ActivityConfig[atvId].AwardC) or #ActivityConfig[atvId].AwardC < 1 or not ActivityConfig[atvId].mailTitle1 or not ActivityConfig[atvId].mailContent1 then
        print("ActivityType28 SendAward not ActivityConfig[atvId].AwardC or table ~= type(ActivityConfig[atvId].AwardC) or #ActivityConfig[atvId].AwardC < 1 or not ActivityConfig[atvId].mailTitle1 or not ActivityConfig[atvId].mailContent1")
        return
    end

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    for i, actorId in Ipairs(globalData.actors) do
        print(actorId)
        if globalData.secretBoxScore[actorId] then
            local tempAwardA = {}
            for j = 1, #ActivityConfig[atvId].AwardA do
                tempAwardA[j] = {}
                tempAwardA[j].type = ActivityConfig[atvId].AwardA[j].type
                tempAwardA[j].id = ActivityConfig[atvId].AwardA[j].id
                tempAwardA[j].count = ActivityConfig[atvId].AwardA[j].count
                print("globalData.secretBoxScore[actorId] : "..globalData.secretBoxScore[actorId].." tempAwardA[j].count : "..tempAwardA[j].count)
                tempAwardA[j].count = globalData.secretBoxScore[actorId] * tempAwardA[j].count
                print("tempAwardA[j].count : "..tempAwardA[j].count)
            end
            SendCrossServerMail(actorId, ActivityConfig[atvId].mailTitle1, ActivityConfig[atvId].mailContent1, tempAwardA)
        else
            print("ActivityType28 SendAward not globalData.secretBoxScore[actorId]")
        end

        if globalData.wordsBoxScore[actorId] then
            local tempAwardB = {}
            for j = 1, #ActivityConfig[atvId].AwardB do
                tempAwardB[j] = {}
                tempAwardB[j].type = ActivityConfig[atvId].AwardB[j].type
                tempAwardB[j].id = ActivityConfig[atvId].AwardB[j].id
                tempAwardB[j].count = ActivityConfig[atvId].AwardB[j].count
                print("globalData.wordsBoxScore[actorId] : "..globalData.wordsBoxScore[actorId].." tempAwardB[j].count : "..tempAwardB[j].count)
                tempAwardB[j].count = globalData.wordsBoxScore[actorId] * tempAwardB[j].count
                print("tempAwardB[j].count : "..tempAwardB[j].count)
            end
            SendCrossServerMail(actorId, ActivityConfig[atvId].mailTitle2, ActivityConfig[atvId].mailContent2, tempAwardB)
        else
            print("ActivityType28 SendAward not globalData.wordsBoxScore[actorId]")
        end

        if globalData.materialsBoxScore[actorId] then
            local tempAwardC = {}
            for j = 1, #ActivityConfig[atvId].AwardC do
                tempAwardC[j] = {}
                tempAwardC[j].type = ActivityConfig[atvId].AwardC[j].type
                tempAwardC[j].id = ActivityConfig[atvId].AwardC[j].id
                tempAwardC[j].count = ActivityConfig[atvId].AwardC[j].count
                print("globalData.materialsBoxScore[actorId] : "..globalData.materialsBoxScore[actorId].." tempAwardC[j].count : "..tempAwardC[j].count)
                tempAwardC[j].count = globalData.materialsBoxScore[actorId] * tempAwardC[j].count
                print("tempAwardC[j].count : "..tempAwardC[j].count)
            end
            SendCrossServerMail(actorId, ActivityConfig[atvId].mailTitle3, ActivityConfig[atvId].mailContent3, tempAwardC)
        else
            print("ActivityType28 SendAward not globalData.materialsBoxScore[actorId]")
        end
    end
end

-- 踢出副本
function KickoutAllActors(atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    if nil == globalData.actors then
        return 
    end 
    if nil == globalData.actors then
        for i,actorid in pairs(nil == globalData.actors) do
            local pActor = Actor.getActorById(actorid)
            if pActor ~= nil then
                Actor.exitFubenAndBackCity(pActor)
            end
        end
        globalData.actors = nil
    end
end

-- 清理 秘境寻宝 全局数据
function ClearSecretGlobalData(atvId)
    print("ActivityType28 ClearData 活动Id ："..atvId)

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    globalData.actors = nil
    globalData.secretBoxScore = nil
    globalData.wordsBoxScore = nil
    globalData.materialsBoxScore = nil
    globalData.clearGlobalData = nil
end


--------------------------------------------------------------------
-- 活动 回调注册
--------------------------------------------------------------------
-- 加载活动时（启动服务器从数据库返回的）
function OnLoad(atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local fbid = ActivityConfig[atvId].fbId
    local fbHandle = Fuben.createFuBen(fbid)
    cacheData.fbHandle = fbHandle

    --副本中启用默认的场景刷怪方式
    Fuben.useDefaultCreateMonster(fbHandle, true)
end

-- 初始化玩家数据
function OnInit(atvId, pActor)
    print("ActivityType28 OnInit 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))

    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    actorData.nextLoginTime = nil
end

-- 活动开始
function OnStart(atvId)
    print("ActivityType28 OnStart 活动Id ："..atvId)

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    globalData.actors = {}
    globalData.secretBoxScore = {}
    globalData.wordsBoxScore = {}
    globalData.materialsBoxScore = {}
    globalData.clearGlobalData = 1

    --创建副本并记录
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local fbid = ActivityConfig[atvId].fbId
    local fbHandle = Fuben.createFuBen(fbid)
    cacheData.fbHandle = fbHandle
	
    --副本中启用默认的场景刷怪方式
	Fuben.useDefaultCreateMonster(fbHandle, true)
end

-- 活动结束
function OnEnd(atvId)
    print("ActivityType28 OnEnd 活动Id ："..atvId)

    local pFuben = ActivityDispatcher.GetFuben(atvId)
    if pFuben then
        -- 设置副本结果
        FubenDispatcher.SetResult(pFuben,1)
        -- 延迟踢出副本
        FubenDispatcher.KictoutAfter(pFuben,15)
    end

    --发放奖励
    SendAward(atvId)

    --清空数据
    ClearSecretGlobalData(atvId)

    local cacheData = ActivityDispatcher.GetCacheData(atvId)

    -- -- 踢出副本
    -- KickoutAllActors( atvId )
    
    -- 关闭副本
    Fuben.closeFuben( cacheData.fbHandle )
    -- 清空活动数据
    ActivityDispatcher.ClearCacheData( atvId )
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    print("ActivityType28 OnOperator 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))

    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cEnterFuben then     -- 请求进入副本
        reqEnterFuben(pActor, atvId)
    end
end

--玩家退出活动副本
function OnExitFuben(atvId, pActor, pFuben)
    print("ActivityType28 OnExitFuben 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))

    -- 玩家下次进入时间限制
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    actorData.nextLoginTime = System.getCurrMiniTime() + 30
    
    -- 退出副本
    Actor.SendActivityLog(pActor,atvId,ActivityType,2)
end

--活动副本结束
function OnFubenFinish(atvId, pFuben, result, pOwner)
    print("ActivityType28 OnFubenFinish 活动Id ："..atvId)

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    for i, actorId in Ipairs(globalData.actors) do
        print(actorId)
        local pActor = Actor.getActorById(actorId)
        if pActor then
            local npack = ActivityDispatcher.AllocResultPack(pActor, atvId, result)
            if npack then
                DataPack.writeUInt(npack, globalData.secretBoxScore[actorId] or 0)
                DataPack.writeUInt(npack, globalData.wordsBoxScore[actorId] or 0)
                DataPack.writeUInt(npack, globalData.materialsBoxScore[actorId] or 0)
                DataPack.flush(npack)
            else
                print("ActivityType28 OnFubenFinish 活动Id ："..atvId.." not npack")
            end
        else
            print("ActivityType28 OnFubenFinish 活动Id ："..atvId.." not pActor")
        end
    end
end

--活动红点数据
function OnGetRedPoint(atvId, pActor)
    print("ActivityType28 OnGetRedPoint 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))

    local nRet = 1
    local nLimitLv = 0
    local nLimitZS = 0
    if ActivityConfig and ActivityConfig[atvId] and ActivityConfig[atvId].openParam then
        nLimitLv =  (ActivityConfig[atvId].openParam.level or 0)
        nLimitZS =  (ActivityConfig[atvId].openParam.zsLevel or 0)
    end
    local nLv = Actor.getIntProperty( pActor, PROP_CREATURE_LEVEL )
    local nZSLv = Actor.getIntProperty(pActor, PROP_ACTOR_CIRCLE)
    if nLv < nLimitLv or nZSLv < nLimitZS then nRet = 0 end
    return nRet
end

ActivityDispatcher.Reg(ActivityEvent.OnLoad, ActivityType, OnLoad, "ActivityType28.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType28.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType28.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType28.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType28.lua")
ActivityDispatcher.Reg(ActivityEvent.OnExitFuben, ActivityType, OnExitFuben, "ActivityType28.lua")
ActivityDispatcher.Reg(ActivityEvent.OnFubenFinish, ActivityType, OnFubenFinish, "ActivityType28.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType28.lua")


NetmsgDispatcher.Reg(enActivityID, cReqXunWanGift, cReqActorTypesScores)

