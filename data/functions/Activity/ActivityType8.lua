module("ActivityType8", package.seeall)

--[[
    全局活动，世界boss

    个人数据：ActorData[AtvId]
    {
        buffValue,     鼓舞属性
        nextLoginTime,  退出后下次可进来的时间戳
        inspire { 
            [1] = {times, addvalue }
        }  鼓舞次数
        isFirst 第一次
    }

    全局缓存：Cache[AtvId]
    {
        fbHandle,               记录当前活动创建的副本，这个是多人副本，强制活动结束后才销毁
        scenHandle,             记录当前副本的场景
        actors = {actorid,...}  记录活动副本中的玩家id
        notice{}               公告 
        referFlag,              刷新标志位  
        status       
    }

    全局数据：GlobalData[AtvId]
    {
        bossLv,                 boss等级
        bossDeath,                  是否死亡
        killerName,             击杀者昵称
        killerId,               击杀者id
        atvStartTime,           当前活动开始时间
        isAward             --是否发奖
    }
]]--

--活动类型
ActivityType = 8
--对应的活动配置
ActivityConfig = Activity8Config
if ActivityConfig == nil then
    assert(false)
end

--排行榜id
RANKING_ID = RANK_DEFINE_ACTIVITY4

-- 活动状态
local AtvStatus =
{
    PreEnter = 1,   --活动前5分钟（走马灯全服公告，不给进入）
    Start = 2,      --开始
    End = 3,        --结束了（发奖励，等待活动时间结束）
}
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

--活动前走马灯通告的时间戳
preEnterNoticeTime = 0

--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------

--请求进入副本
function reqEnterFuben(pActor, atvId)
    -- print("[GActivity 8] "..Actor.getName(pActor).." 请求进入副本 id"..atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)

    --退出后登入的时间限制
    if actorData.nextLoginTime and actorData.nextLoginTime > System.getCurrMiniTime()  then
        Actor.sendTipmsg(pActor, "请30秒后再进入！", tstUI)
        return
    end

    if globalData.bossDeath then
        Actor.sendTipmsgWithId(pActor, tmBossDeath, tstUI)
        return
    end

    -- 这个阶段还不能进入
    if cacheData.status == AtvStatus.PreEnter then
        Actor.sendTipmsgWithId(pActor, tmNoInOpenTime, tstUI)
        -- Actor.sendTipmsg(pActor, "活动当前阶段不能进入！", tstUI)
        return
    end

    --进入副本
    
   local fbHandle = ActivityDispatcher.EnterFuben(atvId, pActor, ActivityConfig[atvId].fbId)
   if fbHandle then
        -- 重置下次进入时间
        actorData.nextLoginTime = nil

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
        -- print("atvId = "..atvId.." actorId="..actorsInFuben[atvId][actorId])

        -- 广播一次排行榜
        local fbHandle = cacheData.fbHandle
        local sceneId = Fuben.getSceneId(cacheData.scenHandle)
        RankMgr.Save(RANKING_ID)
        BroadRankData(atvId, fbHandle, sceneId)
        SendRankData(atvId,pActor)
        -- 强制全体和平模式
        Actor.setPkMode(pActor,fpPeaceful)
        addInspireBuff(pActor, atvId);
        SendLeftTimeInfo(pActor, atvId);
   end
end


--广播排行榜数据
function BroadRankData(atvId,fbHandle,sceneId)
    -- 广播所有玩家排行榜数据
    local npack = ActivityDispatcher.AllocOperReturnEx(atvId, ActivityOperate.sSendRankData)
    if npack then
        RankMgr.PushToPack(RANKING_ID, 100, npack)
        DataPack.broadcastScene(npack,fbHandle,sceneId)
        ActivityDispatcher.FreePacketEx(npack)
    end
end
--玩家鼓舞
function ActorInspire(pActor, atvId, type)
    -- print("[GActivity 8] "..Actor.getName(pActor).." 玩家鼓舞 id "..atvId.." type "..type)
    local globalData = ActivityDispatcher.GetGlobalData(atvId);
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId);
    local errorcode = 0;
    local value = 0;
    local lefttimes = 0;
    while(true) 
    do
        if actorsInFuben[atvId] then
            --初始化鼓舞数据
            if actorData.inspire == nil then
                actorData.inspire = {}
            end
            if actorData.inspire[type] == nil then
                actorData.inspire[type] = {};
            end

            local Cfg = ActivityConfig[atvId].inspire
            if Cfg == nil then
                errorcode = 1;
                break
            end

            local inspireCfg = Cfg[type] 
            if inspireCfg == nil or inspireCfg.type ~= type then
                errorcode = 1;
                break
            end
            if actorData.inspire[type].times == nil then
                actorData.inspire[type].times = 0;
            end

            if actorData.inspire[type].times >= inspireCfg.times then
                errorcode = 2;
                break;
            end

            if inspireCfg.costs and CommonFunc.Consumes.Check(pActor, inspireCfg.costs) ~= true then
                errorcode = 3;
                break;
            end
            
            if inspireCfg.costs and CommonFunc.Consumes.Remove(pActor, inspireCfg.costs, GameLog.Log_Activity8, "世界boss|"..atvId) ~= true then
                errorcode = 4
                break
            end
            if actorData.buffValue == nil then
                actorData.buffValue = 0;
            end

            -- actorData.buffValue = actorData.buffValue + inspireCfg.value;
            actorData.buffValue = actorData.buffValue + 1;
            if actorData.inspire[type].addvalue == nil then
                actorData.inspire[type].addvalue = 0;
            end
            actorData.inspire[type].addvalue = actorData.inspire[type].addvalue + inspireCfg.value;
            value = actorData.inspire[type].addvalue
            -- print("鼓舞.."..actorData.inspire[type].addvalue )
            addInspireBuff(pActor, atvId);
            Actor.sendTipmsgWithId(pActor, tmBossGwSuccess, tstUI)
            actorData.inspire[type].times = actorData.inspire[type].times + 1;
            lefttimes = inspireCfg.times - actorData.inspire[type].times ;
            break;
        else
            errorcode = 5;
        end
        break;
    end
    local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sInspire)
    if  outPack then
        DataPack.writeByte(outPack, errorcode) 
        DataPack.writeByte(outPack, type) 
        DataPack.writeInt(outPack, (value or 0)) 
        DataPack.writeInt(outPack, (lefttimes or 0)) 
        DataPack.flush(outPack)
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
--发送最后一击奖励
function SendLastAttackaward(atvId)
    if ActivityConfig[atvId].lastattack then
        local globalData = ActivityDispatcher.GetGlobalData(atvId);
        -- print("击杀世界BOSS..atcid.."..atvId.."...2222.."..(globalData.killerId or 0))
        if globalData.killerId == nil then
            return;
        end
        local title = "世界BOSS"
        local content = string.format("恭喜你击杀世界BOSS！")
        SendMail(globalData.killerId, title, content, ActivityConfig[atvId].lastattack)
    end 
end

-- 发送排名奖励
function SendRankAward(atvId)
    if ActivityConfig[atvId].rankAward then
        local rankAward = ActivityConfig[atvId].rankAward
        local ranking = Ranking.getRanking( RANKING_ID )
        if ranking then
            local title = "世界BOSS"
            local itemNum = Ranking.getRankItemCount(ranking)
            local idx = 1
            for _,awardInfo in ipairs(rankAward) do
                local rankNum = awardInfo.value
                -- print("rankNum:"..rankNum.." itemNum:"..itemNum)
                if rankNum > itemNum then
                    rankNum = itemNum
                end
                for i=idx,rankNum do
                    local rankItem = Ranking.getItemFromIndex(ranking, i-1)
                    local actorId = Ranking.getId(rankItem)
                    local title = "世界BOSS"
                    local content = string.format("恭喜你在世界BOSS中取得第%d名！", i)
                    SendMail(actorId, title, content, awardInfo.awards)
                    -- local pActor = Actor.getActorById(actorId)
                    -- Actor.triggerAchieveEvent(pActor, nAchieveActivity,1 ,atvId);
                    -- Actor.triggerAchieveEvent(pOwner, nAchieveCompleteActivity,1 ,atvId);
                    local name = RankMgr.GetValueById(actorId, RANKING_ID, 0)
                    -- print("[GActivity 8] 世界BOSS(id:"..atvId..") "..(name or actorId).." 获得第"..i.."名！")
                end
                idx = rankNum + 1
                if idx > itemNum then
                    -- print("[GActivity 8] 世界BOSS(id:"..atvId..") 奖励发完! 一共"..rankNum.."人获得上榜奖励!")
                    return
                end
            end
        end
    end
end

-- 踢出副本
function KickoutAllActors(atvId)
    if actorsInFuben[atvId] then
        for i,actorid in pairs(actorsInFuben[atvId]) do
            local pActor = Actor.getActorById(actorid)
            if pActor ~= nil then
                Actor.exitFubenAndBackCity(pActor)
                RemoveInspireBuff(pActor, atvId) --清除鼓舞buff
            end
        end
        actorsInFuben[atvId] = nil
    end
end


function addInspireBuff(pActor, atvId)
    local Cfg = ActivityConfig[atvId]
    if Cfg == nil and Cfg.buffid == nil then
        return
    end
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId);
    if actorData == nil then
        actorData = {}
    end
    local job = Actor.getIntProperty( pActor, PROP_ACTOR_VOCATION )
    for _, cfg in pairs(Cfg.buffid) do

        if cfg.times == actorData.buffValue then

            for _, id in pairs(cfg.buffid) do
                Actor.addBuffById(pActor, id);
            end
                 
            -- Actor.addBuffValueById(pActor, cfg.id, (actorData.buffValue or 0));
        end
    end
end

function RemoveInspireBuff(pActor, atvId)
    local Cfg = ActivityConfig[atvId]
    if Cfg == nil and Cfg.buffid == nil then
        return
    end
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId);
    if actorData == nil then
        actorData = {}
    end

    for _, cfg in pairs(Cfg.buffid) do
        if cfg.times == actorData.buffValue then

            for _, id in pairs(cfg.buffid) do

                Actor.delBuffById(pActor, id);
            end
        end
        -- Actor.delBuffById(actorid, cfg.id);
    end
end


--------------------------------------------------------------------
-- 活动 回调注册
--------------------------------------------------------------------

-- 加载活动时（启动服务器从数据库返回的）
function OnLoad(atvId)
    print("[GActivity 8] 世界boss 活动数据加载，id："..atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local fbid = ActivityConfig[atvId].fbId
    local defsceneid = StaticFubens[fbid].defSceneID or StaticFubens[fbid].scenes[1]
    local fbHandle = Fuben.createFuBen(fbid)
    local scenHandle = Fuben.getSceneHandleById(defsceneid, fbHandle)
    cacheData.fbHandle = fbHandle
    cacheData.scenHandle = scenHandle
    local pFuben = Fuben.getFubenPtrByHandle(fbHandle)
    FubenDispatcher.MapToActivity(pFuben,ActivityType, atvId);
end

-- 初始化玩家数据
function OnInit(atvId, pActor)
    print("[GActivity 8] 世界boss "..Actor.getName(pActor).." 初始化 id："..atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    actorData.buffValue = nil
    actorData.nextLoginTime = nil
    actorData.inspire = nil
    actorData.isFirst = nil
end

-- 活动开始
function OnStart(atvId)
    print("[GActivity 8] 世界boss 活动开始了，id："..atvId)
    CheckNewActivity(atvId);
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    cacheData.actors = {}
    --创建副本并记录
    local fbid = ActivityConfig[atvId].fbId
    local defsceneid = StaticFubens[fbid].defSceneID or StaticFubens[fbid].scenes[1]
    local fbHandle = Fuben.createFuBen(fbid)
    local scenHandle = Fuben.getSceneHandleById(defsceneid, fbHandle)
    cacheData.fbHandle = fbHandle
    cacheData.scenHandle = scenHandle
    local pFuben = Fuben.getFubenPtrByHandle(fbHandle)
    FubenDispatcher.MapToActivity(pFuben,ActivityType, atvId);
    --清空排行榜
    RankMgr.Clear(RANKING_ID)
end

function ClearGlobalData(atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    -- print("一支穿云箭，千军万马来相见！！")
    globalData.bossDeath = nil
    globalData.killerId = nil
    globalData.killerName = nil
    globalData.isAward = nil;
end

-- 活动结束
function OnEnd(atvId)
    print("[GActivity 8] 世界boss 活动结束了，id："..atvId)
    SendWorldBossAward(atvId)
    -- 踢出副本
    KickoutAllActors( atvId )
    -- 未死亡
    noDeathResult(atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId);
    -- 关闭副本
    Fuben.closeFuben( cacheData.fbHandle )

    -- 清空活动数据
    ActivityDispatcher.ClearCacheData( atvId )
    
end

function SendWorldBossAward(atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    if globalData.isAward then
        return;
    end

    local cacheData = ActivityDispatcher.GetCacheData(atvId);

    if globalData.killerName ~= nil then
        System.broadcastTipmsgLimitLev("恭喜"..globalData.killerName.."击杀了世界BOSS，获得了大量奖励", tstRevolving)
        System.broadcastTipmsgLimitLev("恭喜"..globalData.killerName.."击杀了世界BOSS，获得了大量奖励", tstChatSystem)
    end
    local pFuben = ActivityDispatcher.GetFuben(atvId)
    if pFuben then
        FubenDispatcher.SetResult(pFuben,1)
        -- 延迟踢出副本
        local nowtime = System.getCurrMiniTime() + 15
        FubenDispatcher.KictoutAfter(pFuben, nowtime)
    end
    -- 发送奖励
    SendRankAward( atvId )
    --最后一击
    SendLastAttackaward(atvId);
    globalData.isAward = 1;
    
end



--公告
function SendNotice(avtId, curTime)
    local cfg = ActivityConfig[avtId]
    local cacheData = ActivityDispatcher.GetCacheData(avtId);
    if cfg == nil then
        return;
    end

    if cfg.notice then
        for _, notice in pairs(cfg.notice) do
            
            if cacheData.notice == nil then
                cacheData.notice = {}
            end
            if notice.id then
                local startTime = System.getRunningActivityStartTime(avtId)
                if (curTime > startTime + notice.time) and cacheData.notice[notice.id] == nil then
                    if cacheData.status == nil then
                        cacheData.status = AtvStatus.PreEnter
                    end
                   
                    System.broadcastTipmsgLimitLev(notice.content, tstBigRevolving)
                    System.broadcastTipmsgLimitLev(notice.content, tstChatSystem)
                    cacheData.notice[notice.id] = 1;
                end
            end
        end
    end
end

-- 刷新boss
function CreateWorldBoss(avtId, curTime)
    
    local globalData = ActivityDispatcher.GetGlobalData(avtId);
    if globalData.bossDeath then
        return
    end

    local Cfg = ActivityConfig[avtId]
    if Cfg == nil or Cfg.bossinfo == nil then
        return
    end
    local cacheData = ActivityDispatcher.GetCacheData(avtId);
    if cacheData.referFlag then
        return
    end

    -- print("..avtId.."..avtId.."avtId.."..(globalData.bossDeath or 0))
    local startTime = System.getRunningActivityStartTime(avtId)
    if cacheData.scenHandle and (curTime >= startTime + Cfg.starttime) then

        if globalData.bossLv == nil then
            globalData.bossLv =1;
        end
        TestMsg(globalData.bossLv)
        cacheData.status = AtvStatus.Start
        local bossGrowValue =  1.1 ^ (globalData.bossLv-1) *100
        Fuben.createOneMonsters(cacheData.scenHandle, Cfg.bossinfo.bossid, Cfg.bossinfo.x, Cfg.bossinfo.y, 1,0,0, NULL, 0, (bossGrowValue or 100));
        cacheData.referFlag = 1;
        System.sendAllActorOneActivityData(avtId);
        ActivityDispatcher.BroadPopup(avtId);
    end
end

function CheckNewActivity(atvId)
    local  globalData = ActivityDispatcher.GetGlobalData(atvId);
    local endTime = System.getActivityEndMiniSecond(atvId)
    if globalData.atvEndTime == nil or globalData.atvEndTime ~= endTime then
        -- print("改革春风吹满地！！")
        ClearGlobalData(atvId)
        ActivityDispatcher.ClearCacheData(atvId);
        globalData.atvEndTime = endTime
    end
end

-- 活动帧更新
function OnUpdate(atvId, curTime)
    -- 检测活动结束
    -- CheckNewActivity(atvId);
    -- 公告
    SendNotice(atvId, curTime)
    -- 刷新boss
    CreateWorldBoss(atvId, curTime)
end

-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId);
    local Cfg = ActivityConfig[atvId];
    if Cfg and Cfg.inspire then
        local len = #Cfg.inspire;
        DataPack.writeByte(outPack, (len or 0)) 
        for _, cfg in pairs(Cfg.inspire) do
            DataPack.writeByte(outPack, (cfg.type or 0))
            local data = GetActorInpires(atvId, cfg.type, pActor);
            local addvalue = 0;
            local times = cfg.times;
            if data then
                addvalue = data.addvalue;
                times = times - data.times
                if times < 0 then
                    times = 0
                end
            end
            DataPack.writeInt(outPack,  addvalue)
            DataPack.writeInt(outPack, (times or 0))
        end
    end
end


-- 获取活动数据
function GetActorInpires(atvId, type, pActor)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId);
    if actorData.inspire == nil then
        actorData.inspire = {}
        local inspire = {}
        inspire.times = 0;
        inspire.addvalue = 0;
        actorData.inspire[type] = inspire;
    end
    return actorData.inspire[type]
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cEnterFuben then     -- 请求进入副本
        reqEnterFuben(pActor, atvId)
    elseif operaCode == ActivityOperate.cInspire then --鼓舞
        local type = DataPack.readByte(inPack);
        ActorInspire(pActor, atvId, type)
    end
end



--发送玩家当前剩余时间信息
function SendLeftTimeInfo(pActor, atvId)
    local npack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendWorldBossTime)
    if npack then
        local nEndTime = System.getActivityEndMiniSecond(atvId);
        local leftTime = nEndTime - System.getCurrMiniTime()
	    DataPack.writeUInt(npack, leftTime)
        DataPack.flush(npack)
    end
end

--玩家退出活动副本
function OnExitFuben(atvId, pActor, pFuben)

    -- 玩家退出，从记录中排除
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    if cacheData == nil then
        return
    end

    if cacheData.actors == nil then
        cacheData.actors = {}
    end
    local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    actorsInFuben[atvId][actorId] = nil
    -- 记录日志
    Actor.SendActivityLog(pActor,atvId,ActivityType,2)
    -- 玩家下次进入时间限制
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    actorData.nextLoginTime = System.getCurrMiniTime() + 30
    RemoveInspireBuff(pActor,atvId );

end

--实体在活动副本中死亡 TODO 缺个助攻积分
function OnEntityDeath(atvId, pEntity,pKiller,pFuben)
   
end


function noDeathResult(atvId)
    local Cfg = ActivityConfig[atvId];
    if Cfg then
        local globalData = ActivityDispatcher.GetGlobalData(atvId)
        if globalData.bossDeath then
            return
        end

        local time = 0;
        local bossLv = 0;

        for _, cfg in pairs(ActivityConfig[atvId].growlist) do
            if cfg.time >=  time then
                time = cfg.time
                bossLv = cfg.addlv
            end
        end
        if globalData.bossLv == nil then
            globalData.bossLv = 1;
        end

        globalData.bossLv = globalData.bossLv + bossLv;
        if  globalData.bossLv < 1 then
            globalData.bossLv = 1
        end
        TestMsg(globalData.bossLv)
    end
end

function TestMsg(lv)
    local msg = "世界BOSS当前等级：%d"
    local str = string.format(msg, (lv or 0));
    -- System.SendChatMsg(str, 4)
    System.broadcastTipmsgLimitLev(str, tstChatSystem)
end

function setBossGrowLv(atvId, killTime)
    local Cfg = ActivityConfig[atvId];
    if Cfg then

        local globalData = ActivityDispatcher.GetGlobalData(atvId)
        local cacheData = ActivityDispatcher.GetCacheData(atvId)
        local startTime = System.getRunningActivityStartTime(atvId)
        local costtime = killTime - (startTime + Cfg.starttime);
        if costtime < 0 then
            costtime = 0
        end

        local time = 0;
        local bossLv = 0;
        for _, cfg in pairs(ActivityConfig[atvId].growlist) do
            if costtime < cfg.time then
                bossLv = cfg.addlv
                break
            end
        end
        -- print("bossLv.."..bossLv)
        globalData.bossLv = globalData.bossLv + bossLv;
        if  globalData.bossLv < 1 then
            globalData.bossLv = 1
        end
        TestMsg(globalData.bossLv)
        -- print("globalData.bossLv .."..(globalData.bossLv or 0))
    end
end

function OnEntityHurt(atvId, pEntity, damage, isKiller, killTime)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    if actorsInFuben[atvId] and globalData.bossDeath == nil then
    -- if  globalData.bossDeath == nil then
        -- 攻击boss 获得积分
        local killerId = Actor.getIntProperty(pEntity, PROP_ENTITY_ID )
        local addSocre = damage * 0.2 + ActivityConfig[atvId].addScoreKill;

        addSocre = math.floor(addSocre)

        RankMgr.AddValue(killerId, RANKING_ID, addSocre)
        OnDealAchieve(atvId, pEntity);
        local fbHandle = cacheData.fbHandle
        local sceneId = Fuben.getSceneId(cacheData.scenHandle)
        BroadRankData(atvId, fbHandle, sceneId)
        SendRankData(atvId,pEntity)
        if isKiller ~= nil and isKiller == 1 and globalData.bossDeath == nil then
            -- local killerId = Actor.getIntProperty(pEntity, PROP_ENTITY_ID )
            local killName = Actor.getName(pEntity )
            globalData.killerId = killerId
            globalData.killerName = killName;
            globalData.bossDeath = killTime;
            -- print("bossdeath "..atvId.." ..atvId."..globalData.killerId)
            setBossGrowLv(atvId, killTime);
            -- SendWorldBossAward(atvId, 1);
            System.closeActivityRunning(atvId, true);
            System.sendAllActorOneActivityData(atvId);
        end
    end
end

--活动副本结束
function OnFubenFinish(atvId, pFuben, result, pOwner)
    if actorsInFuben[atvId] then
        for i,actorid in pairs(actorsInFuben[atvId]) do
            local pActor = Actor.getActorById(actorid)
            if pActor then
                --满血结束血量
                -- local maxhp = Actor.getIntProperty(pActor,PROP_CREATURE_MAXHP)
                -- Actor.changeHp(pActor, maxhp)
                local npack = ActivityDispatcher.AllocResultPack(pActor, atvId, 1)
                if npack then
                    local actorId = Actor.getActorId(pActor)
                    WorldBossResult(atvId, npack, actorId)
                    DataPack.writeWord(npack, RankMgr.GetMyRank(pActor,RANKING_ID))
                    DataPack.flush(npack)
                end
            end
        end
    end
end


function WorldBossResult(atvId, npack, actorId)
    local ranking = Ranking.getRanking( RANKING_ID )
    if ranking then
        for i = 1, 3 do
            local rankItem = Ranking.getItemFromIndex(ranking, i-1)
            local name = "";
            if(rankItem) then
                local actorId = Ranking.getId(rankItem)
                name = Ranking.getSub(rankItem, 0)
            end

            DataPack.writeString(npack, name or "")
        end
    end

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    DataPack.writeString(npack, globalData.killerName or "")
    local iskiller = 0;
    if actorId == globalData.killerId then
        iskiller = 1
    end
    DataPack.writeWord(npack, iskiller)
end

function OnGetRedPoint(atvId, pActor)
    local result = System.isActivityRunning(atvId)
    local ret = 0
    
    -- if result then ret = 1 end
    local cacheData = ActivityDispatcher.GetCacheData(atvId)

    if cacheData.status and cacheData.status == AtvStatus.Start then ret = 1 end
    -- local cfg = ActivityConfig[atvId]
    -- if cfg and cfg.openParam then
    --     if Actor.checkActorLevel(pActor,(cfg.openParam.level or 0)) ~=true then ret = 0 end
    -- end

    return ret
end

----处理成就问题
function OnDealAchieve(atvId, pActor)
    local actorid = Actor.getActorId(pActor)
    local curVal = RankMgr.GetValue(actorid, RANKING_ID)
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    if actorData and actorData.isFirst == nil and curVal >= 1000 then
        Actor.triggerAchieveEvent(pActor,nAchieveActivity,1 ,atvId);
        Actor.triggerAchieveEvent(pActor, nAchieveCompleteActivity,1 ,atvId);
        actorData.isFirst = 1;
    end
    
end

ActivityDispatcher.Reg(ActivityEvent.OnFubenFinish, ActivityType, OnFubenFinish, "ActivityType8.lua")
ActivityDispatcher.Reg(ActivityEvent.OnLoad, ActivityType, OnLoad, "ActivityType8.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType8.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType8.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType8.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType8.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType8.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType8.lua")
ActivityDispatcher.Reg(ActivityEvent.OnExitFuben, ActivityType, OnExitFuben, "ActivityType8.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEntityDeath, ActivityType, OnEntityDeath, "ActivityType8.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType8.lua")
-- ActivityDispatcher.Reg(ActivityEvent.OnEntityHurt, ActivityType, OnEntityHurt, "ActivityType8.lua")
--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------


-- 杀怪
function OnHurtMonster(pActor,damage,isKiller,killTime)
    -- print("[PActivity 8] "..Actor.getName(pActor).." damage："..damage.."isKiller： "..isKiller.." killTime: "..killTime)
    local pFuben = Actor.getFubenPrt(pActor);
    if pFuben and FubenDispatcher.IsActivityFuben(pFuben) then
        local atvType = FubenDispatcher.GetActivityType(pFuben);
        -- print("[PActivity 8] "..pFuben)
        if atvType == ActivityType then
            local atvId = FubenDispatcher.GetActivityId(pFuben);
            -- print("[PActivity 8] "..Actor.getName(pActor).." atvId："..atvId)
            OnEntityHurt(atvId, pActor, damage, isKiller, killTime);
        end
    end
end

ActorEventDispatcher.Reg(aeHurtMonster, OnHurtMonster, "ActivityType8.lua")