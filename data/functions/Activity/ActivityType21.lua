module("ActivityType20", package.seeall)

--[[
    沙巴克

    个人数据：ActorData[AtvId]
    {
    }

    全局缓存：Cache[AtvId]
    {   
        sbkArea[sceneid] //sceneid  场景id
        {
           state  //状态
        }
        needDealarea
        {
            area
            {
                sceneid, //场景id
                x,  x坐标
                y,  y坐标
            }
        }
        paodianTime,
        warNotice,--沙巴克皇宫可以开始占领！公告
    }

    全局数据：GlobalData[AtvId]
    {
        sbkGuild sbk领主id
    }
]]--

--活动类型
ActivityType = 21
--对应的活动配置
ActivityConfig = Activity21Config
--排行榜id
RANKING_ID_1 = RANK_DEFINE_ACTIVITY20 --玩家积分
RANKING_ID_2 = RANK_DEFINE_ACTIVITY21 --行会积分
-- if ActivityConfig == nil then
--     assert(false)
-- end
local SbkState = 0;
-- 活动状态
local AtvStatus =
{
    PreEnter = 1,   --活动前5分钟（走马灯全服公告，不给进入）
    Start = 2,      --开始
    Sbk = 3,      --沙巴克时间
    End = 4,        --结束了（发奖励，等待活动时间结束）
}




--助攻列表
attackerList=
{
    --[atvId] =
    --{
    --  [handle,被攻击者] = 
    --  {
    --      [attkHandle,攻击者] = 最新攻击时间
    --  }
    --}
}

--阶段奖励的领取记录，记录下一次要领取的阶段索引
actorAwardIdx =
{
    --[atvId] =
    --{
    --  [aid] = idx
    --}
}

--在场景中的玩家
actorsInFuben =
{
    --[atvId] =
    --{
    --  [actorId] = actorId
    --}
}
--在场景中的玩家
guildsInFuben =
{
    --[guild] =
    --{
    --  [actorId] = actorId
    --}
}

local PaodianTime = 0;
--------------------------------------------------------------------
-- 活动 回调注册
--------------------------------------------------------------------

-- 加载活动时（启动服务器从数据库返回的）
function OnLoad(atvId)
    print("[GActivity 20] 沙巴克 活动数据加载，id："..atvId)
end

-- 初始化玩家数据
function OnInit(atvId, pActor)
    print("[GActivity 20] 沙巴克 "..Actor.getName(pActor).." 初始化 id："..atvId)
end

-- 活动开始
function OnStart(atvId)
    setSbkAwardFlag(nil);
    --清空排行榜
    RankMgr.Clear(RANKING_ID_1)
    RankMgr.Clear(RANKING_ID_2)
    Guild.setSbkGuildId(0);
    local globalData = ActivityDispatcher.GetGlobalData(atvId);
    globalData.sbkGuild = 0
    print("[GActivity 20] 沙巴克 活动开始了，id："..atvId)
end

-- 活动结束
function OnEnd(atvId)
    local Cfg = ActivityConfig
    if Cfg then
        -- System.broadcastTipmsgLimitLev(Cfg.endsbk, tstBigRevolving)
        -- System.broadcastTipmsgLimitLev(Cfg.endsbk, tstChatSystem)
        
        local cacheData = ActivityDispatcher.GetCacheData(atvId);
        local globalData = ActivityDispatcher.GetGlobalData(atvId);
        if globalData.sbkGuild then
            local guildName = Guild.getGuildName(globalData.sbkGuild)
            if guildName then
                local str = string.format(Cfg.endsbk, guildName)
                System.broadcastTipmsgLimitLev(str, tstBigRevolving)
                -- print("..on")
                System.broadcastTipmsgLimitLev(str, tstChatSystem)
            end
        end
        if cacheData.sbkArea then
            for _, sceneid in Ipairs(cacheData.sbkArea) do
                -- print("vvvv.."..sceneid)
                Fuben.ResetFubenSceneConfig(sceneid);
            end
        end
       
    end
     -- 发送奖励
     SendRankAward( atvId )
     SendSbkguildAward();
     -- 补发阶段奖励
     SendScoreAward(atvId)
    SbkState = AtvStatus.End
    ActivityDispatcher.ClearCacheData(atvId);
    actorAwardIdx[atvId] = nil
    attackerList[atvId] = nil
    actorsInFuben[atvId] = nil
    guildsInFuben= {};
    print("[GActivity 20] 沙巴克 活动结束了，id："..atvId)
end


--公告
function SendNotice(avtId, curTime)
    local cfg = ActivityConfig
    local cacheData = ActivityDispatcher.GetCacheData(avtId);
    if cfg == nil then
        return;
    end
end



-- 发送积分奖励
function SendScoreAward(atvId)
    local MaxIdx = #ActivityConfig.phaseAward
    local title = ActivityConfig.phaseAwardMailTT
    
    if actorAwardIdx[atvId] == nil then
        return
    end
    for aid,awdIdx in pairs(actorAwardIdx[atvId]) do
        if actorAwardIdx[atvId][aid] ~= nil then
            local rankValue = RankMgr.GetValue(aid, RANKING_ID_1)
            -- rankValue = rankValue+ 100
            -- print("SendScoreAward.."..rankValue)
            local award = nil;
            for i=1,MaxIdx do
                local awardConf = ActivityConfig.phaseAward[i]
                
                if awardConf then
                    if rankValue >= awardConf.value then
                        award = awardConf;
                    end
                end
            end
            -- print("awardConf.."..(award.value or 0).."..type.."..type(award.awards))
            if award then
                local content = string.format(ActivityConfig.phaseAwardMailCT, award.value)
                SendCrossServerMail(aid, title, content, award.awards)
            end
        end
    end
end



-- 发送排名奖励
function SendRankAward(atvId)
    local ranking = Ranking.getRanking( RANKING_ID_2 )
    if ranking then
        
        local itemNum = Ranking.getRankItemCount(ranking)
        local idx = 0

        for i=idx,itemNum do
            local rankItem = Ranking.getItemFromIndex(ranking, i)
            local guildid = Ranking.getId(rankItem)
            System.sendGuildSBKRank(guildid, i+1);
        end
    end
end

-- 发送排名奖励
function SendSbkguildAward()
    System.sendSBKGuild();
end

---处理结束邮件问题
function OnSendGuildMail(atvId, pActor)
    local ActorType = Actor.getEntityType(pActor)--类型
    if ActorType ==enActor then 
        local cfg = ActivityConfig
        if cfg and cfg.mailtitle and cfg.mailcontent then
            local actorid = Actor.getActorId(pActor)
            SendCrossServerMail(actorid,srvid, cfg.mailtitle, cfg.mailcontent)
        end
    end
end

-- end
-- 活动帧更新
function OnUpdate(atvId, curTime)
    SendNotice(atvId, curTime);
    DealSbkAreaAttr(atvId, curTime);
    dealGuildSbk(atvId,curTime);
    dealPaodianExp(atvId,curTime)
    
end


--p泡点
function dealPaodianExp(atvId, curTime)
    --检测沙巴克占领是否开启
    local cacheData = ActivityDispatcher.GetCacheData(atvId);
    local Cfg = ActivityConfig
    local startTime = System.getRunningActivityStartTime(atvId)
    if Cfg then
        if Cfg.starttime then
            if curTime < (startTime + Cfg.starttime) then
                return
            end
        end
        if cacheData.paodianTime == nil then
            cacheData.paodianTime = 0
        end
        if actorsInFuben[atvId] == nil then
            actorsInFuben[atvId] = {}
        end

        if curTime >= cacheData.paodianTime then
            cacheData.paodianTime = curTime + 10
            for i,actorid in pairs(actorsInFuben[atvId]) do
                local pActor = Actor.getActorById(actorid)
                if pActor ~= nil then
                    local guildid = Actor.getGuildId(pActor);
                    if guildid > 0 then
                        -- 行会积分
                        RankMgr.AddGuildRankValue(guildid, RANKING_ID_2, ActivityConfig.addScoreAuto)
                        SendRankData(atvId,pActor);
                        BroadSbkRankData(atvId);
                    end
                    RankMgr.AddValue(actorid, RANKING_ID_1, ActivityConfig.addScoreAuto)
                    local curVal = RankMgr.GetValue(actorid, RANKING_ID_1)
                    -- OnDealAchieve(atvId, pActor)
                    Actor.sendTipmsg(pActor, "持续参加活动，积分+"..ActivityConfig.addScoreAuto.."，当前积分为："..curVal, tstGetItem)
                    SendMyRankData(atvId,pActor)
                    hasMan = true
                end
            end
            if hasMan then
                RankMgr.Save(RANKING_ID_1);
                RankMgr.Save(RANKING_ID_2);
            end
        end
    end
end

--沙巴克行为
function dealGuildSbk(atvId, curTime)
    --检测沙巴克占领是否开启
    local Cfg = ActivityConfig
    local startTime = System.getRunningActivityStartTime(atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId);
    -- print("dealGuild.."..startTime)
    if Cfg then
        if Cfg.wartime then
            local startTime = System.getRunningActivityStartTime(atvId)
            if curTime < (startTime + Cfg.wartime) then
                return
            end

            if not cacheData.warNotice and Cfg.wartimestr then
                cacheData.warNotice = 1
                System.broadcastTipmsgLimitLev(Cfg.wartimestr, tstRevolving)
                System.broadcastTipmsgLimitLev(Cfg.wartimestr, tstChatSystem)
            end
        end
        
        local globalData = ActivityDispatcher.GetGlobalData(atvId);
        if globalData.sbkGuild == nil then
            globalData.sbkGuild = 0
        end
        if Cfg.winmap then
            local guildId = Fuben.GetNowSceneGuildList(Cfg.winmap);
            if guildId > 0 and globalData.sbkGuild ~= guildId then
                globalData.sbkGuild = guildId
                Guild.setSbkGuildId(guildId);
                local guildName = Guild.getGuildName(guildId)
                if guildName then
                    local str = string.format(Cfg.sbknotic, guildName)
                    System.broadcastTipmsgLimitLev(str, tstRevolving)
                    System.broadcastTipmsgLimitLev(str, tstChatSystem)
                end
            end
        end
    end
end

-- 处理活动开始 设置sbk区域为战斗区域
function DealSbkAreaAttr(atvId, curTime)
    local cacheData = ActivityDispatcher.GetCacheData(atvId);
    local Cfg = ActivityConfig
    local startTime = System.getRunningActivityStartTime(atvId)
    if Cfg and Cfg.starttime then
        if curTime > (startTime + Cfg.starttime) then
            if SbkState ~= AtvStatus.Sbk then
                SbkState = AtvStatus.Sbk
                System.sendAllActorOneActivityData(atvId);
                ActivityDispatcher.BroadPopup(atvId);
            end

            if cacheData.needDealarea == nil then
                cacheData.needDealarea = {}
            end
            
            if cacheData.sbkArea == nil then
                cacheData.sbkArea = {}
            end
            -- 已经设置OK
            for _, area in Ipairs(cacheData.needDealarea) do
                if Cfg.areaattr and Cfg.areaattr.attri then
                    for _, attr in pairs(Cfg.areaattr.attri) do
                        local index = Fuben.GetAreaListIndex(area.sceneid, area.x, area.y)
                        local hScene = Fuben.getSceneHandleById(area.sceneid, 0)
                        if index > 0 then
                            Fuben.setSceneAreaAttri(hScene, index, attr.type, attr.value, NULL, (Cfg.areaattr.notips or 0)); 
                        end
                    end
                end
                -- print("西门吹雪 .."..area.sceneid)
                cacheData.sbkArea[area.sceneid] = area.sceneid
            end
            cacheData.needDealarea = nil;
            --设置战斗区域
        end
    end
end


--发送玩家下一次领取奖励的索引
function SendNextAwardIndex(pActor, atvId)
    local npack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sNextAwardIndex)
    if npack then
        local aid = Actor.getActorId(pActor)
            
        

	    DataPack.writeByte(npack, (actorAwardIdx[atvId][aid] or 1))
        DataPack.flush(npack)
    end
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
end

-- 活动区域需要处理新增区域属性
function OnEnterArea(atvId, pActor)
    local cacheData = ActivityDispatcher.GetCacheData(atvId);
    local sceneId = Actor.getSceneId(pActor);
    if cacheData.areaAttr == nil then
        cacheData.areaAttr = {}
    end

    -- 记录进入的玩家
    local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    if actorsInFuben[atvId] == nil then
        actorsInFuben[atvId] = {}
    end
    actorsInFuben[atvId][actorId] = actorId
    local guildid = Actor.getGuildId(pActor);
    if guildsInFuben[guildid] == nil then
        guildsInFuben[guildid] = {}
    end
    guildsInFuben[guildid][actorId] = 1;

    
    if actorAwardIdx[atvId] == nil then
        actorAwardIdx[atvId] = {}
    end

    if actorAwardIdx[atvId][actorId] == nil then
        actorAwardIdx[atvId][actorId] = 1
    end

    local x,y = Actor.getEntityPosition(pActor,0,0)
    -- 已经初始化完成
    if cacheData.areaAttr[sceneId] then
        return;
    end
    print("来了吗.."..sceneId)
    cacheData.areaAttr[sceneId] = 1; 
    local area = {};
    area.sceneid = sceneId;
    area.x = x
    area.y = y
    -- -- print("OnEnterArea x.."..x.." y.."..y);
    if cacheData.needDealarea == nil then
        cacheData.needDealarea = {}
    end

    cacheData.needDealarea[sceneId] = area
    -- 发送下一次领取奖励的索引
    -- SendNextAwardIndex(pActor, atvId)
    -- table.insert(cacheData.needDealarea, area);
end


-- 离开活动区域
function OnExitArea(atvId, pActor)
   
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    if actorsInFuben[atvId] == nil then
        actorsInFuben[atvId] = {}
    end

    local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    actorsInFuben[atvId][actorId] = 0
    local guildid = Actor.getGuildId(pActor);
    if guildsInFuben[guildid] == nil then
        guildsInFuben[guildid] = {}
    end
    guildsInFuben[guildid][actorId] = 0;
end 

function OnGetRedPoint(atvId, pActor)
    local ret = 0
    -- print("SbkState.."..SbkState)
    if SbkState == AtvStatus.Sbk then ret = 1 end
    return ret
end



--实体在活动副本中死亡
function OnEntityDeath(atvId, pEntity)
    --print(debug.traceback("Stack trace"))
    local killerHandle = Actor.getKillHandle(pEntity);
    local pKiller = Actor.getEntity(killerHandle)
    if pKiller then
        
        local entityType = Actor.getEntityType(pEntity)--被击杀者的类型
        local killerType = Actor.getEntityType(pKiller)--击杀者的类型
        -- print("111111111111111111..killerType"..killerType.."..entityType.."..entityType)
        if killerType == enActor then
            if entityType == enActor then
                -- 杀玩家获得积分
                local killerId = Actor.getIntProperty( pKiller, PROP_ENTITY_ID )
                -- print("222enActor.."..killerId)
                RankMgr.AddValue(killerId, RANKING_ID_1, ActivityConfig.addScoreKill)
                local guildid = Actor.getGuildId(pKiller);
                if guildid > 0 then
                    -- 行会积分
                    RankMgr.AddGuildRankValue(guildid, RANKING_ID_2, ActivityConfig.addScoreKill)
                    SendRankData(atvId,pKiller);
                    BroadSbkRankData(atvId);
                end
                SendMyRankData(atvId, pKiller);
                Actor.sendTipmsg(pKiller, "你成功击败["..Actor.getName(pEntity).."]，积分+"..ActivityConfig.addScoreKill, tstGetItem)

                -- 被玩家击杀的玩家获得的积分
                local entityId = Actor.getIntProperty( pEntity, PROP_ENTITY_ID )
                RankMgr.AddValue(entityId, RANKING_ID_1, ActivityConfig.addScoreBeKill)
                local guildid = Actor.getGuildId(pEntity);
                if guildid > 0 then
                    -- 行会积分
                    RankMgr.AddGuildRankValue(guildid, RANKING_ID_2, ActivityConfig.addScoreBeKill)
                    SendRankData(atvId,pEntity);
                    BroadSbkRankData(atvId);
                end
                SendMyRankData(atvId, pEntity);
                Actor.sendTipmsg(pEntity, "你被["..Actor.getName(pKiller).."]击败了，积分+"..ActivityConfig.addScoreBeKill, tstGetItem)
            else
                -- 杀守卫获得积分
                local killerId = Actor.getIntProperty( pKiller, PROP_ENTITY_ID )
                -- print("33333enActor.."..killerId)
                RankMgr.AddValue(killerId, RANKING_ID_1, ActivityConfig.addScoreGuard)
                local guildid = Actor.getGuildId(pKiller);
                if guildid > 0 then
                    -- 行会积分
                    RankMgr.AddGuildRankValue(guildid, RANKING_ID_2, ActivityConfig.addScoreGuard)
                    SendRankData(atvId,pKiller);
                    BroadSbkRankData(atvId);
                end
                SendMyRankData(atvId, pKiller);
                -- OnDealAchieve(atvId, pKiller)
                Actor.sendTipmsg(pKiller, "你击败守卫，积分+"..ActivityConfig.addScoreGuard, tstGetItem)
            end

            if not attackerList[atvId] then attackerList[atvId] = {} end

            -- 助攻积分
            local handle = Actor.getHandle(pEntity)
            local entityName = Actor.getName(pEntity)
            if attackerList[atvId][handle] then
                local nowTime = System.getCurrMiniTime()
                local killerHandle = Actor.getHandle(pKiller)
                for attkHandle,time in pairs(attackerList[atvId][handle]) do
                    if nowTime - time <= ActivityConfig.helpTime and killerHandle ~= attkHandle then
                        local pActor = Actor.getEntity(attkHandle)
                        if pActor then
                            local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
                            RankMgr.AddValue(actorId, RANKING_ID_1, ActivityConfig.addScoreHelpKill)
                            local guildid = Actor.getGuildId(pActor);
                            if guildid > 0 then
                                -- 行会积分
                                RankMgr.AddGuildRankValue(guildid, RANKING_ID_2, ActivityConfig.addScoreHelpKill)
                                SendRankData(atvId,pActor);
                                BroadSbkRankData(atvId);
                            end
                            SendMyRankData(atvId, pActor);
                            -- OnDealAchieve(atvId, pActor)
                            Actor.sendTipmsg(pActor, "你助攻击败["..entityName.."]，积分+"..ActivityConfig.addScoreHelpKill, tstGetItem)
                        end
                    end
                end
            end
            attackerList[atvId][handle] = nil
        end
        SendRankData(atvId,pKiller)
        -- BroadSbkRankData(atvId);
        SendMyRankData(atvId, pKiller);
    end
end

-- 活动副本中，实体守到攻击
function OnEntityAttacked(atvId, pEntity, pAttacker)

    -- 攻击者必须为玩家，才记录助攻
    if Actor.getEntityType(pAttacker) == enActor then
        -- print("222222222222222222222222")
        -- 通过句柄作为key（因为守卫的id是一样的，所以只能通过handle区分）
	    local handle = Actor.getHandle(pEntity)
        local attkHandle = Actor.getHandle(pAttacker)
        
        if not attackerList[atvId] then attackerList[atvId] = {} end

        local info = attackerList[atvId][handle]
        if not info then
            attackerList[atvId][handle] = { [attkHandle] = System.getCurrMiniTime() }
        else
            info[attkHandle] = System.getCurrMiniTime()
        end
    end
end

function BroadSbkRankData(atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId);
    local fbHandle = Fuben.getStaticFubenHandle()
    if cacheData.sbkArea then
        for _, sceneid in Ipairs(cacheData.sbkArea) do
            BroadRankData(atvId, fbHandle, sceneid)
        end
    end
end

--广播排行榜数据
function BroadRankData(atvId,fbHandle,sceneId)
    -- 广播所有玩家排行榜数据
    local npack = ActivityDispatcher.AllocOperReturnEx(atvId, ActivityOperate.sCSSBKGuildRank)
    if npack then
        RankMgr.PushToPack(RANKING_ID_2, 4, npack)
        DataPack.broadcastScene(npack,fbHandle,sceneId)
        ActivityDispatcher.FreePacketEx(npack)
    end
end

--发送行会排行数据
function SendRankData(atvId,pActor)
    local guildid = Actor.getGuildId(pActor);
    if guildid > 0 then
        local npack = ActivityDispatcher.AllocOperReturnEx(atvId, ActivityOperate.sCSSBKMyGuildRank)
        if npack then
            DataPack.writeUInt(npack, RankMgr.GetValue(guildid,RANKING_ID_2))
            DataPack.writeWord(npack, RankMgr.GetMyGuildRank(guildid,RANKING_ID_2))
            DataPack.broadGuild(npack,guildid)
            ActivityDispatcher.FreePacketEx(npack)
        end
    end
end

--发送玩家排行数据
function SendMyRankData(atvId,pActor)
    local npack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sCSSBKMyRank)
    if npack then
        local actorid = Actor.getActorId(pActor);
        DataPack.writeUInt(npack, RankMgr.GetValue(actorid,RANKING_ID_1))
        DataPack.writeByte(npack, 1)
        DataPack.flush(npack)
    end
end

ActivityDispatcher.Reg(ActivityEvent.OnAtvAreaDeath, ActivityType, OnEntityDeath, "ActivityType21.lua")
ActivityDispatcher.Reg(ActivityEvent.OnAtvAreaAtk, ActivityType, OnEntityAttacked, "ActivityType21.lua")
ActivityDispatcher.Reg(ActivityEvent.OnLoad, ActivityType, OnLoad, "ActivityType21.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType21.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType21.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType21.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType21.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnterArea, ActivityType, OnEnterArea, "ActivityType21.lua")
ActivityDispatcher.Reg(ActivityEvent.OnExitArea, ActivityType, OnExitArea, "ActivityType21.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType21.lua")