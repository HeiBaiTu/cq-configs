module("ActivityType26", package.seeall)

--[[
    全局活动，跨服逃脱试炼 

    个人数据：ActorData[AtvId]
    {
        nextLoginTime   退出后下次可进来的时间戳
        isFirst ,       第一次
        nLifeStatus     玩家生命状态(0：存活；     1：死亡；)
    }

    全局缓存：Cache[AtvId]
    {
        fbHandle,                       记录当前活动创建的副本，这个是多人副本，强制活动结束后才销毁
        scenHandle,                     记录当前副本的场景
        actors = {actorid,...}          记录活动副本中的玩家id
        nextAutoTime,                   下一次自动加积分的时间戳
        broadcastTime,                  下一次广播的时间戳
        escapeActors = {actorid,...}    记录活动副本中的已逃脱玩家id
        escapeActorsNames = {actorName,...}    记录活动副本中的已逃脱玩家名称
    }
    全局数据：GlobalData[AtvId]
    {
        nEscapePlayerNum,      当前已逃脱玩家人数
        nEndTime,              活动阶数时间戳
    }
]]--

--活动类型
ActivityType = 26
--对应的活动配置
ActivityConfig = Activity26Config
if ActivityConfig == nil then
    assert(false)
end

--排行榜id
RANKING_ID = RANK_DEFINE_ACTIVITY26

--在场景中的玩家
actorsInFuben =
{
    --[atvId] =
    --{
    --  [actorId] = actorId
    --}
}

--玩家任务状态
actorsEscapeFromFuben =
{
    --[atvId] =
    --{
    --  [actorId] = actorId
    --}
}

--已逃脱玩家名称
actorsNameEscapeFromFuben =
{
    --[atvId] =
    --{
    --  [index] = actorName
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
                        local fbHandle = Actor.getFubenHandle(pActor)
                        if cacheData.fbHandle == fbHandle then
                            actorsInFuben[atvId][actorId] = actorId
                        end
                    end
                end
            end

            actorsEscapeFromFuben[atvId] = {}
            if cacheData and cacheData.escapeActors then
                for i,actorId in Ipairs(cacheData.escapeActors) do
                    if cacheData.fbHandle == fbHandle then
                        actorsEscapeFromFuben[atvId][actorId] = actorId
                    end
                end
            end

            actorsNameEscapeFromFuben[atvId] = {}
            if cacheData and cacheData.escapeActorsNames then
                for nIndex,actorName in Ipairs(cacheData.escapeActorsNames) do
                    if cacheData.fbHandle == fbHandle then
                        actorsNameEscapeFromFuben[atvId][nIndex] = actorName
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
    print("[GActivity 26] reqEnterFuben() "..Actor.getName(pActor))
    local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    if actorsEscapeFromFuben[atvId] and actorsEscapeFromFuben[atvId][actorId] then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:您已经结算过名次，无法再次参与活动|", tstUI)
        return
    end

    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)

    --等级、转身等级限制
    local nLimitLv = 0;
    local nLimitZSLv  = 0 ;
    local cfg = ActivityConfig[atvId]
    if cfg and cfg.openParam then
        nLimitLv =  (cfg.openParam.level or 0)
        nLimitZSLv = (cfg.openParam.zsLevel or 0)
    end
    if Actor.getIntProperty(pActor, PROP_CREATURE_LEVEL) < nLimitLv then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:等级不足|", tstUI)
        return
    end
    if Actor.getIntProperty(pActor, PROP_ACTOR_CIRCLE) < nLimitZSLv then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:转生不足|", tstUI)
        return
    end

    --退出后登入的时间限制
    if actorData.nextLoginTime and actorData.nextLoginTime > System.getCurrMiniTime()  then
        Actor.sendTipmsg(pActor, "请30秒后再进入！")
        return
    end

    --消耗检查
    local consumes = nil
    if ActivityConfig[atvId].enterExpends then
        consumes = ActivityConfig[atvId].enterExpends
        if CommonFunc.Consumes.Check(pActor, consumes) ~= true then
            -- Actor.sendTipmsg(pActor, "道具或金币元宝不足!", tstEcomeny)
            Actor.sendTipmsgWithId(pActor, tmNeedItemNotEnough, tstUI)
            return
        end
    end
    
    -- 消耗
    if consumes and CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity26, "逃脱试炼|"..atvId) ~= true then
        return
    end
    
    --进入副本
   local fbHandle = ActivityDispatcher.EnterFuben(atvId, pActor, ActivityConfig[atvId].fbId)
   if fbHandle then
        -- 重置玩家状态
        actorData.nLifeStatus = 0

        -- 重置下次进入时间
        actorData.nextLoginTime = nil

        -- 记录进入的玩家
        if cacheData.actors == nil then
            cacheData.actors = {}
        end
        cacheData.actors[actorId] = actorId
        
        -- 初始化已逃脱玩家
        if cacheData.escapeActors == nil then
            cacheData.escapeActors = {}
        end

        if cacheData.escapeActorsNames == nil then
            cacheData.escapeActorsNames = {}
        end

        if actorsInFuben[atvId] == nil then
            actorsInFuben[atvId] = {}
        end
        actorsInFuben[atvId][actorId] = actorId

        if actorsEscapeFromFuben[atvId] == nil then
            actorsEscapeFromFuben[atvId] = {}
        end

        if actorsNameEscapeFromFuben[atvId] == nil then
            actorsNameEscapeFromFuben[atvId] = {}
        end

        -- 通知玩家当前已经逃脱的玩家数
        local globalData = ActivityDispatcher.GetGlobalData(atvId)
        local npack = DataPack.allocPacket(pActor, enActivityID, sSendCompletPlayerNum)
        if npack then
            DataPack.writeWord(npack, globalData.nEscapePlayerNum or 0)
            for i,actorid in pairs(actorsEscapeFromFuben[atvId]) do
                DataPack.writeUInt(npack, actorid)
            end
            DataPack.flush(npack)
        end

        -- 禁止普通频道聊天
        Actor.setChatForbit(pActor, ciChannelNear, true)

        -- 广播一次排行榜
        local fbHandle = cacheData.fbHandle
        local sceneId = Fuben.getSceneId(cacheData.scenHandle)
        RankMgr.Save(RANKING_ID)
        BroadRankData(atvId, fbHandle, sceneId)

        -- 强制全体pk模式
        Actor.setPkMode(pActor,fpPk)
   end
end

--请求领取奖励
function reqGetPhaseAward(pActor, atvId)
    print("[GActivity 26] reqGetPhaseAward() "..Actor.getName(pActor))
    local actorId = Actor.getActorId(pActor)
    if RankMgr.GetValue(actorId,RANKING_ID) < ActivityConfig[atvId].Standardscore then
        return
    end

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    globalData.nEscapePlayerNum = globalData.nEscapePlayerNum + 1



    local nCurIdx = 1
    local nMaxIdx = #ActivityConfig[atvId].rankAward
    for i=1,nMaxIdx do
        local awardConf = ActivityConfig[atvId].rankAward[i]
        if awardConf then
            if globalData.nEscapePlayerNum > awardConf.value then
                nCurIdx = nCurIdx + 1
            end
        end
    end


    if nCurIdx > nMaxIdx then
        nCurIdx = nMaxIdx
    end

    local awardConf = ActivityConfig[atvId].rankAward[nCurIdx]
    if awardConf then
        -- 已逃脱的玩家
        local cacheData = ActivityDispatcher.GetCacheData(atvId)
        if cacheData.escapeActors == nil then
            cacheData.escapeActors = {}
        end
        if cacheData.escapeActorsNames == nil then
            cacheData.escapeActorsNames = {}
        end
        cacheData.escapeActors[actorId] = actorId
        cacheData.escapeActorsNames[globalData.nEscapePlayerNum] = Actor.getName(pActor)

        -- 广播当前已经逃脱的人数
        local npack = DataPack.allocPacketEx()
        if npack then
            DataPack.writeByte(npack,enActivityID)
            DataPack.writeByte(npack,sSendCompletPlayerNum)

            -- 玩家已逃脱
            actorsEscapeFromFuben[atvId][actorId] = actorId

            DataPack.writeWord(npack,globalData.nEscapePlayerNum)
            for i,actorid in pairs(actorsEscapeFromFuben[atvId]) do
                DataPack.writeUInt(npack, actorid)
            end

            local fbHandle = cacheData.fbHandle
            local sceneId = Fuben.getSceneId(cacheData.scenHandle)
            DataPack.broadcastScene(npack, fbHandle, sceneId)
            DataPack.freePacketEx(npack)
        end

        
        actorsNameEscapeFromFuben[atvId][globalData.nEscapePlayerNum] = Actor.getName(pActor)

        -- 聊天框、走马灯广播第一名
        if globalData.nEscapePlayerNum == 1 and actorsNameEscapeFromFuben[atvId][globalData.nEscapePlayerNum] then
            System.broadcastTipmsgLimitLev("恭喜 "..actorsNameEscapeFromFuben[atvId][globalData.nEscapePlayerNum].." 率先完成【跨服】逃脱试炼活动！", tstRevolving)
            System.broadcastTipmsgLimitLev("恭喜 "..actorsNameEscapeFromFuben[atvId][globalData.nEscapePlayerNum].." 率先完成【跨服】逃脱试炼活动！", tstChatSystem)
        end

        -- 发送排名奖励
        local mainContent = string.format(ActivityConfig[atvId].mailContent1, globalData.nEscapePlayerNum)
        SendAward(atvId, pActor, globalData.nEscapePlayerNum, ActivityConfig[atvId].mailTitle1, mainContent, awardConf.awards)

        -- 玩家积分清零
        RankMgr.SetRank(actorId, RANKING_ID, 0)

        -- 踢出副本
        Actor.exitFubenAndBackCity(pActor)
    end
end

--广播排行榜数据
function BroadRankData(atvId,fbHandle,sceneId)
    local npack = ActivityDispatcher.AllocOperReturnEx(atvId, ActivityOperate.sSendRankData)
    if npack then
        RankMgr.PushToPack(RANKING_ID, 4, npack)
        DataPack.broadcastScene(npack,fbHandle,sceneId)
        ActivityDispatcher.FreePacketEx(npack)
    end
end

--发送玩家排行数据
function SendRankData(atvId,pActor)
    local npack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendMyRankData)
    if npack then
        local actorId = Actor.getActorId(pActor)
        DataPack.writeUInt(npack, RankMgr.GetValue(actorId,RANKING_ID))
        DataPack.writeWord(npack, RankMgr.GetMyRank(pActor,RANKING_ID))
        DataPack.flush(npack)
    end
end

-- 设置复活
function SetAutoRelive(atvId,pActor,pFuben)
    local deathLimit = FubenDispatcher.GetReliveCount(pFuben, pActor)
    if (deathLimit == nil) or (deathLimit == -1) then
        FubenDispatcher.SetReliveCount(pFuben, pActor, ActivityConfig[atvId].Rebirthsecond)
    end
end

--广播当前场次时间信息
function BroadCurrentTimeInfo(atvId,fbHandle,sceneId)
    local npack = ActivityDispatcher.AllocOperReturnEx(atvId, ActivityOperate.sSendTime)
    if npack then
        local globalData = ActivityDispatcher.GetGlobalData(atvId)
        DataPack.writeByte(npack, 0)
        local nLeftTime = globalData.nEndTime - System.getCurrMiniTime()
        DataPack.writeUInt(npack, nLeftTime)
        DataPack.broadcastScene(npack,fbHandle,sceneId)
        ActivityDispatcher.FreePacketEx(npack)
    end
end

--------------------------------------------------------------------
-- 活动 回调注册
--------------------------------------------------------------------

-- 加载活动时（启动服务器从数据库返回的）
function OnLoad(atvId)
    print("[GActivity 26] 跨服逃脱试炼 活动数据加载，id："..atvId)
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
    print("[GActivity 26] 跨服逃脱试炼 "..Actor.getName(pActor).." 初始化 id："..atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    -- actorData.nextLoginTime = nil
    actorData.isFirst = nil
    actorData.nextLoginTime = nil
    actorData.nLifeStatus = nil
end

-- 活动开始
function OnStart(atvId)
    print("[GActivity 26] 跨服逃脱试炼 活动开始了，id："..atvId)
    ActivityDispatcher.ClearCacheData(atvId)
    ActivityDispatcher.ClearGlobalData(atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)

    cacheData.nextAutoTime = 0
    cacheData.actors = {}
    cacheData.escapeActors = {}
    cacheData.escapeActorsNames = {}
    cacheData.broadcastTime = 0

    globalData.nEscapePlayerNum = 0
    globalData.nEndTime = System.getCurrMiniTime() + ActivityConfig[atvId].Duration

    --创建副本并记录
    local fbid = ActivityConfig[atvId].fbId
    local defsceneid = StaticFubens[fbid].defSceneID or StaticFubens[fbid].scenes[1]
    local fbHandle = Fuben.createFuBen(fbid)
    local scenHandle = Fuben.getSceneHandleById(defsceneid, fbHandle)
    cacheData.fbHandle = fbHandle
    cacheData.scenHandle = scenHandle
	
	Fuben.useDefaultCreateMonster(fbHandle, true)

    --清空排行榜
    RankMgr.Clear(RANKING_ID)
end

-- 活动结束
function OnEnd(atvId)
    print("[GActivity 26] 跨服逃脱试炼 活动结束了，id："..atvId)
    -- local cacheData = ActivityDispatcher.GetCacheData(atvId)

    -- 参与奖
    for i,actorid in pairs(actorsInFuben[atvId]) do
        if actorsInFuben[atvId][actorid] then
            local pActor = Actor.getActorById(actorid)
            -- 参与奖发送的排名为：0
            SendAward(atvId, pActor, 0, ActivityConfig[atvId].mailTitle2, ActivityConfig[atvId].mailContent2, ActivityConfig[atvId].partakeAward)
        end
    end

    local pFuben = ActivityDispatcher.GetFuben(atvId)
    if pFuben then
        -- 设置副本结果
        FubenDispatcher.SetResult(pFuben,1)
        -- 延迟踢出副本
        FubenDispatcher.KictoutAfter(pFuben,15)
    end

    -- 清空活动数据
    ActivityDispatcher.ClearCacheData( atvId )
    ActivityDispatcher.ClearGlobalData( atvId )
    actorsInFuben[atvId] = nil
    actorsEscapeFromFuben[atvId] = nil
    actorsNameEscapeFromFuben[atvId] = nil
end

-- 活动帧更新
function OnUpdate(atvId, curTime)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)

    BroadCurrentTimeInfo(atvId, cacheData.fbHandle, Fuben.getSceneId(cacheData.scenHandle))

    -- 有玩家时才处理
    if actorsInFuben[atvId] then

        local hasMan = false

        -- 泡点
        if (cacheData.nextAutoTime or 0) - curTime > ActivityConfig[atvId].autoTime then
            cacheData.nextAutoTime = curTime
        end
        if curTime > (cacheData.nextAutoTime or 0) then
            cacheData.nextAutoTime = curTime + ActivityConfig[atvId].autoTime
            for i,actorid in pairs(actorsInFuben[atvId]) do
                local pActor = Actor.getActorById(actorid)
                local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
                if pActor ~= nil and actorData.nLifeStatus == 0 then
                    RankMgr.AddValue(actorid, RANKING_ID, ActivityConfig[atvId].addScoreAuto)
                    OnDealAchieve(atvId, pActor)
                    local curVal = RankMgr.GetValue(actorid, RANKING_ID)
                    Actor.sendTipmsg(pActor, "持续参加活动，积分+"..ActivityConfig[atvId].addScoreAuto.."，当前："..curVal, tstGetItem)
                    SendRankData(atvId,pActor)
                    hasMan = true
                end

                if pActor ~= nil and actorData.nLifeStatus == 1 then
                    --  玩家死亡时需要提示：角色复活期间无法获取积分
                    Actor.sendTipmsg(pActor, "角色复活期间无法获取积分", tstGetItem)
                end
            end
            if hasMan then
                RankMgr.Save(RANKING_ID)
            end
        end

        -- 每秒广播一次
        if (cacheData.broadcastTime or 0) - curTime > 1 then
            cacheData.broadcastTime = curTime
        end
        if curTime > (cacheData.broadcastTime or 0) then
            cacheData.broadcastTime = curTime + 1
            local fbHandle = cacheData.fbHandle
            local sceneId = Fuben.getSceneId(cacheData.scenHandle)
            BroadRankData(atvId, fbHandle, sceneId)
        end
    end
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cEnterFuben then     -- 请求进入副本
        reqEnterFuben(pActor, atvId)
    elseif operaCode == ActivityOperate.cGetPhaseAward then --请求获取阶段奖励
        reqGetPhaseAward(pActor, atvId)
    end
end

--玩家退出活动副本
function OnExitFuben(atvId, pActor, pFuben)
    -- 玩家退出，从记录中排除
    local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    if cacheData.actors and cacheData.actors[actorId] then
        cacheData.actors[actorId] = nil
    end
    
    actorsInFuben[atvId][actorId] = nil

    -- 玩家下次进入时间限制
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    actorData.nextLoginTime = System.getCurrMiniTime() + 30

    -- 玩家积分清零
    RankMgr.SetRank(actorId, RANKING_ID, 0)

    -- 恢复禁止普通频道聊天
    Actor.setChatForbit(pActor, ciChannelNear, false)
    
    -- 完成
    Actor.SendActivityLog(pActor,atvId,ActivityType,2)
end

--实体在活动副本中死亡
function OnEntityDeath(atvId, pEntity,pKiller,pFuben)

    if pKiller then
        local entityType = Actor.getEntityType(pEntity)--被击杀者的类型
        local killerType = Actor.getEntityType(pKiller)--击杀者的类型

        if entityType == enActor then
            --  玩家死亡时需要提示：角色复活期间无法获取积分
            Actor.sendTipmsg(pEntity, "角色复活期间无法获取积分", tstGetItem)

            -- 设置玩家状态
            local actorData = ActivityDispatcher.GetActorData(pEntity,atvId)
            actorData.nLifeStatus = 1
        end

        if killerType == enActor then
            local killerId = Actor.getIntProperty( pKiller, PROP_ENTITY_ID )
            if entityType == enActor then
                -- 击杀杀玩家获得积分
                local nEntityServerId = Actor.getActorRawServerId(pEntity)--被击杀玩家的服务器ID
                local nKillerServerId = Actor.getActorRawServerId(pKiller)--击杀玩家的服务器ID
                if nEntityServerId and nKillerServerId then
                    if nEntityServerId == nKillerServerId then  --击杀本服玩家
                        RankMgr.AddValue(killerId, RANKING_ID, ActivityConfig[atvId].addScoreHelpKill)
                        OnDealAchieve(atvId, pKiller)
                        Actor.sendTipmsg(pKiller, "你成功击败本服玩家["..Actor.getName(pEntity).."]，积分+"..ActivityConfig[atvId].addScoreHelpKill, tstGetItem)
                    else                                        --击杀非本服玩家
                        
                        RankMgr.AddValue(killerId, RANKING_ID, ActivityConfig[atvId].addScoreKill)
                        OnDealAchieve(atvId, pKiller)
                        Actor.sendTipmsg(pKiller, "你成功击败其他服玩家["..Actor.getName(pEntity).."]，积分+"..ActivityConfig[atvId].addScoreKill, tstGetItem)
                    end
                end
                -- 设置复活
                SetAutoRelive(atvId, pEntity, pFuben)
            else
                -- 杀守卫获得积分
                RankMgr.AddValue(killerId, RANKING_ID, ActivityConfig[atvId].addScoreGuard)
                OnDealAchieve(atvId, pKiller)
                Actor.sendTipmsg(pKiller, "你击败试炼怪物，积分+"..ActivityConfig[atvId].addScoreGuard, tstGetItem)
            end
        else
            -- 设置复活
            SetAutoRelive(atvId, pEntity, pFuben)
        end
        SendRankData(atvId,pKiller)
    end
end

-- 活动副本结束
function OnFubenFinish(atvId, pFuben, result)
    print("[GActivity 26] OnFubenFinish()")
end

--活动红点数据
function OnGetRedPoint(atvId, pActor)
    local ret = 1
    local nLimitLv = 0;
    local nLimitZSLv  = 0 ;
    local cfg = ActivityConfig[atvId]
    if cfg and cfg.openParam then
        nLimitLv =  (cfg.openParam.level or 0)
        nLimitZSLv = (cfg.openParam.zsLevel or 0)
    end
    if Actor.getIntProperty( pActor, PROP_CREATURE_LEVEL ) < nLimitLv or Actor.getIntProperty( pActor, PROP_ACTOR_CIRCLE ) < nLimitZSLv then ret = 0 end
    return ret
end

----处理成就问题
function OnDealAchieve(atvId, pActor)
    local ActorType = Actor.getEntityType(pActor)--类型
    if ActorType ==enActor then 
        local actorid = Actor.getActorId(pActor)
        local curVal = RankMgr.GetValue(actorid, RANKING_ID)
        local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
        if actorData and actorData.isFirst == nil and curVal >= 50 then
            Actor.triggerAchieveEvent(pActor,nAchieveActivity,1 ,atvId);
            Actor.triggerAchieveEvent(pActor, nAchieveCompleteActivity,1 ,atvId);
            actorData.isFirst = 1;
        end
    end
end

-- 玩家在活动副本中复活
function OnEnterFuben(atvId, pActor)
    print("[GActivity 26] OnEnterFuben()"..Actor.getName(pActor))
    local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    if actorsInFuben[atvId][actorId] then
        local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
        actorData.nLifeStatus = 0
    end
end

-- 发送奖励
function SendAward(atvId, pActor, nRankNum, mailTitle, mailContent, awardList)
    local nActorId = Actor.getActorId(pActor)
    SendCrossServerMail(nActorId, mailTitle, mailContent, awardList);

    -- 发送前 3 名玩家的名字以及自己的奖励
    local npack = ActivityDispatcher.AllocResultPack(pActor, atvId, 1)
    if npack then
        DataPack.writeUInt(npack, nRankNum);
        local nNumbers = 0
        for nIndex,strActorName in pairs(actorsNameEscapeFromFuben[atvId]) do
            nNumbers = nNumbers + 1
        end
                
        if nNumbers > 3 then
            nNumbers = 3
        end

        for nCurIndex=1, nNumbers do
            if actorsNameEscapeFromFuben[atvId][nCurIndex] then
                DataPack.writeString(npack, actorsNameEscapeFromFuben[atvId][nCurIndex])
            end
        end

        if nNumbers < 3 then
            for i=nNumbers + 1, 3 do
                DataPack.writeString(npack, "") 
            end
        end

        local awardConf = awardList
        local nCount = 0;
        for _, award1 in pairs(awardConf) do
            if award1 and type(award1) == "table" then
                nCount = nCount + 1
            end
        end
        DataPack.writeByte(npack, nCount);

        for i, award2 in pairs(awardConf) do

            local nAwardType = 0;
            local nAwardId = 0;
            local nAwardCount = 0;
            for key, value in pairs(award2) do
                if key == "type" then
                    nAwardType = value
                elseif key == "id" then
                    nAwardId = value
                elseif key == "count" then
                    nAwardCount = value
                end
            end

            DataPack.writeUInt(npack, nAwardType);
            DataPack.writeUInt(npack, nAwardId);
            DataPack.writeUInt(npack, nAwardCount);
        end
        DataPack.flush(npack)
    end
end

ActivityDispatcher.Reg(ActivityEvent.OnLoad, ActivityType, OnLoad, "ActivityType26.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType26.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType26.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType26.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType26.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType26.lua")
ActivityDispatcher.Reg(ActivityEvent.OnExitFuben, ActivityType, OnExitFuben, "ActivityType26.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEntityDeath, ActivityType, OnEntityDeath, "ActivityType26.lua")
ActivityDispatcher.Reg(ActivityEvent.OnFubenFinish, ActivityType, OnFubenFinish, "ActivityType26.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType26.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnterFuben, ActivityType, OnEnterFuben, "ActivityType26.lua")