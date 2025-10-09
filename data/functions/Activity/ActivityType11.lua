module("ActivityType11", package.seeall)
math.randomseed(System.getCurrMiniTime())
--[[
    全局活动， 夜战沃玛三

    个人数据：ActorData[AtvId]
    {
        nextLoginTime,  退出后下次可进来的时间戳
        curCamp,       玩家当前所处阵营
        MaxMultiHit,   当前连击，被击败置0
        curBuffLevel,  当前buff等级 0--10
        isFirst 第一次
    }

    全局缓存：Cache[AtvId]
    {
        fbHandle,               记录当前活动创建的副本，这个是多人副本，强制活动结束后才销毁
        scenHandle,             记录当前副本的场景
        actors = {actorid,...}  记录活动副本中的玩家id
        nextAutoTime,           下一次自动加积分的时间戳
        firstHalfNotice,        上半场开场公告标记
        secondHalfNotice,       下半场开场公告标记
        broadcastTime,          下一次广播的时间戳

    
        nextCamp ,              下个人分配的阵营
        nextAssignTime,         下一次分配阵营的时间
        AssignTimes,            重新分配阵营的次数
    }

    全局数据：GlobalData[AtvId]
    {
        status,                 活动状态，这个即使服务器重启了，也要保存这个数据
        nextChgStatusTime,      下一次活动状态改变的时间戳
    }
]]--

--活动类型
ActivityType = 11
--对应的活动配置
ActivityConfig = Activity11Config
if ActivityConfig == nil then
    assert(false)
end

--排行榜id
RANKING_ID = RANK_DEFINE_ACTIVITY11

local campType_Blue = 1 
local campType_Red  = 2 

local CampChangeTipFlag_10Sec = 0

--活动状态
local AtvStatus =
{
    FirstHalf = 1,  --上半场（自由击杀不限复活次，自由进出）
    SecondHalf = 2, --下半场（限复活次数，可出不可进）
    End = 3,        --结束了（发奖励，等待活动时间结束）
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

--分配阵营
function assignCamp(atvId)

    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local campType   = 0 
	--两边没人随机分配
	if not cacheData.nextCamp then
		campType = math.random(2)  --产生1,2随机数，改变阵营序号需要处理下参数
	else
		campType = cacheData.nextCamp
    end
    
    cacheData.nextCamp = (campType == campType_Red) and campType_Blue or campType_Red

    return campType 
end 

--buff加强
function BuffPlus(pActor,atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    if actorData.curBuffLevel == nil  then 
        actorData.curBuffLevel  = 0 
    end 

    if actorData.curBuffLevel ==10 then 
        return 
    end 

    actorData.curBuffLevel = actorData.curBuffLevel +1 

    local Cfg = ActivityConfig[atvId].buffIndex[actorData.curBuffLevel]
    if Cfg.level ~= actorData.curBuffLevel then 
        return 
    end 

    for _, buffId in pairs(Cfg.Index) do
        -- print("11111111111111111111.."..buffId)
        Actor.addBuffById(pActor, buffId)
    end
    Actor.sendTipmsg(pActor, "|C:0xda1e00&T:逆袭BUFF效果提升|", tstFigthing)

end 

--buff削弱
function BuffDecrease(pActor,atvId)

    if Actor.getEntityType(pActor) ~= enActor then 
        return 
    end 

    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    if actorData.curBuffLevel == nil  then 
        actorData.curBuffLevel  = 0 
    end 

    if actorData.curBuffLevel ==0 then 
        return 
    end 

    local Cfg = ActivityConfig[atvId].buffIndex[actorData.curBuffLevel]
    if Cfg.level ~= actorData.curBuffLevel then 
        return 
    end 

    for _, buffId in pairs(Cfg.Index) do
         --print("2222222222222222.."..buffId)
        Actor.delBuffById(pActor, buffId)
    end
    actorData.curBuffLevel = actorData.curBuffLevel -1 

    if actorData.curBuffLevel == 0 then 
        return 
    end 

    Cfg = ActivityConfig[atvId].buffIndex[actorData.curBuffLevel]
    if Cfg.level ~= actorData.curBuffLevel then 
        return 
    end 

    for _, buffId in pairs(Cfg.Index) do
         --print("11111111111111111111.."..buffId)
        Actor.addBuffById(pActor, buffId)
    end

end 


--删除buff
function RemoveBuff(actorid,atvId)
    
    local pActor = Actor.getActorById(actorid)
    if pActor == nil then 
        return 
    end 
    Actor.RemoveGroupBuff(pActor, 19 , 25 ); --组批量删除buff
    
end 

--再次进入时保留原buff
function addCurBuff(pActor, atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    if actorData.curBuffLevel == nil  then 
        actorData.curBuffLevel  = 0 
    end 

    if (actorData.curBuffLevel  <= 0) or (actorData.curBuffLevel  > 10 )then return end   


    local Cfg = ActivityConfig[atvId].buffIndex[actorData.curBuffLevel]
    if Cfg.level ~= actorData.curBuffLevel then 
        return 
    end 

    for _, buffId in pairs(Cfg.Index) do
        -- print("11111111111111111111.."..buffId)
        Actor.addBuffById(pActor, buffId)
    end

end  



--请求进入副本
function reqEnterFuben(pActor, atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)

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
            Actor.sendTipmsg(pActor, "道具或金币元宝不足!", tstEcomeny)
            return
        end
    end

    --次数检查
    if ActivityConfig[atvId].count and ActivityConfig[atvId].count > 0 then
        if actorData.count == nil then
            actorData.count = 1
        else
            if actorData.count >= ActivityConfig[atvId].count then
                Actor.sendTipmsg(pActor, "超过今日的次数了！"..actorData.count.."/"..ActivityConfig[atvId].count, tstUI)
                return
            end
            actorData.count = actorData.count + 1
        end
    end
    
    -- 消耗
    if consumes and CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity11, "夜战沃玛三|"..atvId) ~= true then
        return
    end

    --进入副本
   local fbHandle = ActivityDispatcher.EnterFuben(atvId, pActor, ActivityConfig[atvId].fbId)
   if fbHandle then
        -- 设置排行榜
        --RankMgr.SetRank(actorId, RANKING_ID, 0)

        -- 记录日志
        Actor.SendActivityLog(pActor,atvId,ActivityType,1)

        -- 重置下次进入时间
        actorData.nextLoginTime = nil

        --actorData.curBuffLevel = 0
             

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
        
        -- 记录进入奖励索引
        if actorAwardIdx[atvId] == nil then
            actorAwardIdx[atvId] = {}
        end

        if actorAwardIdx[atvId][actorId] == nil then
            actorAwardIdx[atvId][actorId] = 1
        end

        --进入副本分配阵营
        actorData.curCamp = assignCamp(atvId) 
        Actor.setCampId(pActor, actorData.curCamp or 0)

        addCurBuff(pActor,atvId) 

--print(Actor.getName(pActor).."————阵营为："..actorData.curCamp)

        --回到本阵营
        if actorData.curCamp == campType_Blue then 
            Actor.enterScene(pActor,unpack(ActivityConfig[atvId].nEnterRangeA))
        else 
            Actor.enterScene(pActor,unpack(ActivityConfig[atvId].nEnterRangeB))
        end 

        --重置连击
        actorData.MaxMultiHit = 0 

        -- 发送下一次领取奖励的索引
        SendNextAwardIndex(pActor, atvId)

        -- 发送场次信息
        SendCurrentTimeInfo(pActor, atvId)
        SendAssignCampTimeInfo(pActor, atvId)

        -- 禁止普通频道聊天
        --Actor.setChatForbit(pActor, ciChannelNear, true)

        -- 广播一次排行榜
        local fbHandle = cacheData.fbHandle
        local sceneId = Fuben.getSceneId(cacheData.scenHandle)
        RankMgr.Save(RANKING_ID)
        BroadRankData(atvId, fbHandle, sceneId)

        -- 强制阵营模式
        Actor.setPkMode(pActor,fpZY)


   end
end

--请求领取阶段奖励
function reqGetPhaseAward(pActor, atvId)
    local aid = Actor.getActorId(pActor)
    
    if actorAwardIdx[atvId] == nil then
        actorAwardIdx[atvId] = {}
    end

    if actorAwardIdx[atvId][aid] == nil then
        actorAwardIdx[atvId][aid] = 1
    end

    local curIdx = actorAwardIdx[atvId][aid]

    local awardConf = ActivityConfig[atvId].phaseAward[curIdx]
    if awardConf then
        local actorid = Actor.getActorId(pActor)
        local curVal = RankMgr.GetValue(actorid, RANKING_ID)
        if curVal >= awardConf.value then
            local awards = awardConf.awards
            if CommonFunc.Awards.CheckBagIsEnough(pActor,1,tmDefNoBagNum,tstUI) ~= true then
                return
            end
            --print("[GActivity 11] "..Actor.getName(pActor).." 领取阶段奖励，".."id="..atvId.." ".."index="..curIdx)
            CommonFunc.Awards.Give(pActor, awards, GameLog.Log_Activity11, "Activity11LevelAward|"..atvId)
            actorAwardIdx[atvId][aid] = actorAwardIdx[atvId][aid] + 1
            -- if actorAwardIdx[atvId][aid] == 2 then
            --     Actor.triggerAchieveEvent(pActor, nAchieveActivity,1 ,atvId);
            --     Actor.triggerAchieveEvent(pOwner, nAchieveCompleteActivity,1 ,atvId);
            -- end
            SendNextAwardIndex(pActor, atvId)
        end
    end
end

--广播排行榜数据
function BroadRankData(atvId,fbHandle,sceneId)
    -- 广播所有玩家排行榜数据
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


--随机重新分配阵营
function randAssignCamp(atvId)
    math.randomseed(System.getCurrMiniTime()) --重置随机种子
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    cacheData.nextCamp = nil 

    if actorsInFuben[atvId] then

        -- 缓存一份数组形式的在场角色列表
        local actorsArray = {}
        local i = 1
        for _,actorid in pairs(actorsInFuben[atvId]) do
            actorsArray[i] = actorid
            --local pActor = Actor.getActorById(actorid)
            --print("(1) actorid = " .. " " .. i .. Actor.getName(pActor))
            i = i + 1
        end

        -- 按积分排序一次
        table.sort(actorsArray,function(actorid1,actorid2)
            local rankValue1 = RankMgr.GetValue(actorid1, RANKING_ID)
            local rankValue2 = RankMgr.GetValue(actorid2, RANKING_ID)
            return rankValue1 > rankValue2
        end)

        -- 调整一下排序（策划要求）
        local should_change = true
        local num = table.maxn(actorsArray)
        for i = 1, num, 2 do
            if should_change then
                local aid = actorsArray[i]
                actorsArray[i] = actorsArray[i+1]
                actorsArray[i+1] = aid
                --local pActor1 = Actor.getActorById(actorsArray[i])
                --local pActor2 = Actor.getActorById(actorsArray[i+1])
                --print("(2) actorid " .. Actor.getName(pActor1) .. " " .. Actor.getName(pActor2))
            end
            if should_change then 
                should_change = false
            else
                should_change = true
            end
        end

        --分阵营
        for i,actorid in ipairs(actorsArray) do
            local pActor = Actor.getActorById(actorid)
            if pActor ~= nil then
                local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
                actorData.curCamp = assignCamp(atvId) 
                Actor.setCampId(pActor, actorData.curCamp or 0)
                --print(Actor.getName(pActor).."————阵营为："..actorData.curCamp)
                --满血阵营安全区复活----------------------------------------------------
                --回血回蓝
	            local maxhp = Actor.getIntProperty(pActor,PROP_CREATURE_MAXHP)
	            Actor.changeHp(pActor, maxhp)
	            local maxmp = Actor.getIntProperty(pActor,PROP_CREATURE_MAXMP)
                Actor.changeMp(pActor, maxmp )

                Actor.clearReliveTimeOut(pActor)
	            Actor.onRelive(pActor)
	
	            --清除击杀者信息
                --ClearKillerData(pActor)
                
                --回到本阵营
                if actorData.curCamp == campType_Blue then 
                    Actor.enterScene(pActor,unpack(ActivityConfig[atvId].nEnterRangeA))
                else 
                    Actor.enterScene(pActor,unpack(ActivityConfig[atvId].nEnterRangeB))
                end 

            end
        end
    end 
            

end 

--发送玩家下一次领取奖励的索引
function SendNextAwardIndex(pActor, atvId)
    local npack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sNextAwardIndex)
    if npack then
        local aid = Actor.getActorId(pActor)
            
        if actorAwardIdx[atvId] == nil then
            actorAwardIdx[atvId] = {}
        end

        if actorAwardIdx[atvId][aid] == nil then
            actorAwardIdx[atvId][aid] = 1
        end

	    DataPack.writeByte(npack, (actorAwardIdx[atvId][aid] or 1))
        DataPack.flush(npack)
    end
end

--发送玩家当前场次时间信息
function SendCurrentTimeInfo(pActor, atvId)
    local npack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendTime)
    if npack then
        local globalData = ActivityDispatcher.GetGlobalData(atvId)
        DataPack.writeByte(npack, (globalData.status-2))
        local leftTime = globalData.nextChgStatusTime - System.getCurrMiniTime()
        DataPack.writeUInt(npack, leftTime)
        DataPack.flush(npack)
    end
end

--发送玩家阵营调增时间信息
function SendAssignCampTimeInfo(pActor, atvId)
    local npack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendAssignCampTime)
    if npack then
        local cacheData = ActivityDispatcher.GetCacheData(atvId)
        DataPack.writeByte(npack, cacheData.AssignTimes)
        local leftTime = cacheData.nextAssignTime - System.getCurrMiniTime()
        DataPack.writeUInt(npack, leftTime)

        DataPack.flush(npack)
    end
end


--广播当前场次时间信息
function BroadCurrentTimeInfo(atvId,fbHandle,sceneId)
    local npack = ActivityDispatcher.AllocOperReturnEx(atvId, ActivityOperate.sSendTime)
    if npack then
        local globalData = ActivityDispatcher.GetGlobalData(atvId)
	    DataPack.writeByte(npack, (globalData.status-2))
        local leftTime = globalData.nextChgStatusTime - System.getCurrMiniTime()
        DataPack.writeUInt(npack, leftTime)

        DataPack.broadcastScene(npack,fbHandle,sceneId)
        ActivityDispatcher.FreePacketEx(npack)
    end
end

--广播阵营调整时间信息
function BroadAssignCampTimeInfo(atvId,fbHandle,sceneId)
    local npack = ActivityDispatcher.AllocOperReturnEx(atvId, ActivityOperate.sSendAssignCampTime)
    if npack then
        local cacheData = ActivityDispatcher.GetCacheData(atvId)
        DataPack.writeByte(npack, cacheData.AssignTimes)
        local leftTime = cacheData.nextAssignTime - System.getCurrMiniTime()
        DataPack.writeUInt(npack, leftTime)

        DataPack.broadcastScene(npack,fbHandle,sceneId)
        ActivityDispatcher.FreePacketEx(npack)
    end
end

-- 发送排名奖励
function SendRankAward(atvId)
    if ActivityConfig[atvId].rankAward then
        local rankAward = ActivityConfig[atvId].rankAward
        local ranking = Ranking.getRanking( RANKING_ID )
        if ranking then
            local title = "夜战沃玛三"
            local itemNum = Ranking.getRankItemCount(ranking)
            local idx = 1
            for _,awardInfo in ipairs(rankAward) do
                local rankNum = awardInfo.value
                if rankNum > itemNum then
                    rankNum = itemNum
                end
                for i=idx,rankNum do
                    local rankItem = Ranking.getItemFromIndex(ranking, i-1)
                    local actorId = Ranking.getId(rankItem)
                    local title = "夜战沃玛三"
                    local content = string.format("恭喜你在夜战沃玛三中取得第%d名！", i)
                    SendMail(actorId, title, content, awardInfo.awards)
                    local pActor = Actor.getActorById(actorId)
                    local name = RankMgr.GetValueById(actorId, RANKING_ID, 0)
                    --print("[GActivity 11] 夜战沃玛三(id:"..atvId..") "..(name or actorId).." 获得第"..i.."名！")
                end
                idx = rankNum + 1
                if idx > itemNum then
                    --print("[GActivity 11] 夜战沃玛三(id:"..atvId..") 奖励发完! 一共"..rankNum.."人获得上榜奖励!")
                    return
                end
            end
        end
    end
end

-- 发送积分奖励
function SendScoreAward(atvId)
    local MaxIdx = #ActivityConfig[atvId].phaseAward
    -- local title = "夜战沃玛三未领奖励"
        
    if actorAwardIdx[atvId] == nil then
        return
    end
    for aid,awdIdx in pairs(actorAwardIdx[atvId]) do
        if actorAwardIdx[atvId][aid] ~= nil then
            local rankValue = RankMgr.GetValue(aid, RANKING_ID)
            for i=awdIdx,MaxIdx do
                local awardConf = ActivityConfig[atvId].phaseAward[i]
                if awardConf then
                    if rankValue >= awardConf.value then
                        local content = string.format("你在夜战沃玛三中还有积分%d档的奖励未领取！", awardConf.value)
                        SendMail(aid, ActivityConfig[atvId].title, content, awardConf.awards)
                        actorAwardIdx[atvId][aid] = actorAwardIdx[atvId][aid] + 1
                        -- local pActor = Actor.getActorById(aid)
                        -- if actorAwardIdx[atvId][aid] == 2 and pActor then
                        --     Actor.triggerAchieveEvent(pActor, nAchieveActivity,1 ,atvId);
                        --     Actor.triggerAchieveEvent(pOwner, nAchieveCompleteActivity,1 ,atvId);
                        -- end
                        --print("[GActivity 11] aid:"..aid.." 补发阶段奖励，".."id="..atvId.." ".."积分档次:"..awardConf.value)
                    end
                end
            end
        end
    end
end

-- 设置复活，分场次，上半场随意复活（不设置它），下半场限制3次，超过就踢出去
function SetAutoRelive(atvId,pActor,pFuben)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    if globalData.status == AtvStatus.SecondHalf then
        local deathLimit = FubenDispatcher.GetReliveCount(pFuben, pActor)
        if (deathLimit == nil) or (deathLimit == -1) then
            FubenDispatcher.SetReliveCount(pFuben, pActor, 3)
        end
    end
end

--------------------------------------------------------------------
-- 活动 回调注册
--------------------------------------------------------------------

-- 加载活动时（启动服务器从数据库返回的）
function OnLoad(atvId)
    --print("[GActivity 11] 夜战沃玛三 活动数据加载，id："..atvId)
    
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId) 
    cacheData.nextAssignTime = System.getCurrMiniTime() + 300




    --local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local fbid = ActivityConfig[atvId].fbId
    local defsceneid = StaticFubens[fbid].defSceneID or StaticFubens[fbid].scenes[1]
    local fbHandle = Fuben.createFuBen(fbid)
    local scenHandle = Fuben.getSceneHandleById(defsceneid, fbHandle)
    cacheData.fbHandle = fbHandle
    cacheData.scenHandle = scenHandle
end

-- 初始化玩家数据
function OnInit(atvId, pActor)
    -- print("[GActivity 11] 夜战沃玛三 "..Actor.getName(pActor).." 初始化 id："..atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    actorData.nextLoginTime = nil
    actorData.curBuffLevel = 0
    actorData.isFirst = nil
end


-- 活动开始
function OnStart(atvId)
    -- print("[GActivity 11] 夜战沃玛三 活动开始了，id："..atvId)
    ActivityDispatcher.ClearCacheData(atvId)
    ActivityDispatcher.ClearGlobalData(atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)

    cacheData.nextAutoTime = 0
    cacheData.actors = {}
    cacheData.broadcastTime = 0
    cacheData.nextAssignTime = System.getCurrMiniTime() + 300
    cacheData.AssignTimes = 0 
    cacheData.nextCamp = nil 
    CampChangeTipFlag_10Sec = cacheData.nextAssignTime - 10 

    globalData.status = AtvStatus.FirstHalf
    globalData.nextChgStatusTime = System.getCurrMiniTime() + ActivityConfig[atvId].firstHalfTime
    
    if globalData.openTimes == nil then
        local currentId = System.getCurrMiniTime();
        globalData.openTimes = currentId
    else
        globalData.openTimes = globalData.openTimes + 1
    end

    --创建副本并记录
    local fbid = ActivityConfig[atvId].fbId
    local defsceneid = StaticFubens[fbid].defSceneID or StaticFubens[fbid].scenes[1]
    local fbHandle = Fuben.createFuBen(fbid)
    local scenHandle = Fuben.getSceneHandleById(defsceneid, fbHandle)
    cacheData.fbHandle = fbHandle
    cacheData.scenHandle = scenHandle

    --清空排行榜
    RankMgr.Clear(RANKING_ID)
end

-- 活动结束
function OnEnd(atvId)

    --删除buff
    if actorsInFuben[atvId] then
        for i,actorid in pairs(actorsInFuben[atvId]) do
            local pActor = Actor.getActorById(actorid)
            if pActor ~= nil then
                local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
                actorData.curBuffLevel = nil 
                RemoveBuff(actorid,atvId)
                -- 清阵营
                Actor.setCampId(pActor, 0)
                -- 强制和平模式
                Actor.setPkMode(pActor,fpPeaceful)
            end
        end
    end

    --print("[GActivity 11] 夜战沃玛三 活动结束了，id："..atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)

    local pFuben = ActivityDispatcher.GetFuben(atvId)
    if pFuben then
        -- 设置副本结果
        FubenDispatcher.SetResult(pFuben,1)
        -- 延迟踢出副本
        FubenDispatcher.KictoutAfter(pFuben,15)
    end

    -- 广播第一名
     local ranking = Ranking.getRanking( RANKING_ID )
     if ranking then
         local rankItem = Ranking.getItemFromIndex(ranking, 0)
         local name = Ranking.getSub(rankItem, 0)
            if rankItem then
                System.broadcastTipmsgLimitLev("夜战沃玛三活动结束了，恭喜玩家 "..name.." 获得第一名！", tstRevolving)
                System.broadcastTipmsgLimitLev("夜战沃玛三活动结束了，恭喜玩家 "..name.." 获得第一名！", tstChatSystem)
            end 
     end

    -- 发送奖励
    SendRankAward( atvId )

    -- 补发阶段奖励
    SendScoreAward(atvId)

    -- 关闭副本
    --Fuben.closeFuben( cacheData.fbHandle )

    -- 清空活动数据
    ActivityDispatcher.ClearCacheData( atvId )
    ActivityDispatcher.ClearGlobalData( atvId )
    actorAwardIdx[atvId] = nil
    attackerList[atvId] = nil
    actorsInFuben[atvId] = nil
end

CHG = true

-- 活动帧更新
function OnUpdate(atvId, curTime)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)

    if cacheData.AssignTimes == nil then cacheData.AssignTimes = 0 end 

    -- 检测活动结束
    if globalData and globalData.status and globalData.status == AtvStatus.End then
        return
    end

    if globalData.status == AtvStatus.FirstHalf then
        if cacheData.firstHalfNotice == nil then
            System.broadcastTipmsgLimitLev(ActivityConfig[atvId].noticeFirstHalf, tstRevolving)
            cacheData.firstHalfNotice = 1
            BroadCurrentTimeInfo(atvId, cacheData.fbHandle, Fuben.getSceneId(cacheData.scenHandle))
            BroadAssignCampTimeInfo(atvId, cacheData.fbHandle, Fuben.getSceneId(cacheData.scenHandle))
            -- 发送一个活动数据
            -- Actor.sendActivityData(pActor, atvId)
            System.sendAllActorOneActivityData(atvId);
            ActivityDispatcher.BroadPopup(atvId);
        end
    end

    if curTime > CampChangeTipFlag_10Sec and cacheData.AssignTimes < 3 then
        --debug information
        --print("curTime:"..curTime.."-----TipFlag_10sec:"..CampChangeTipFlag_10Sec.."-----assigntime:"..cacheData.AssignTimes)
        System.broadcastTipmsgLimitLev("10秒后阵营调整", tstRevolving)
        CampChangeTipFlag_10Sec = curTime +300 
    end 

    if CHG then
        cacheData.nextAssignTime = curTime
        CHG = false
        print("换换换！")
    end

    --重新分配阵营
    if curTime > cacheData.nextAssignTime then
        if CHG == false or cacheData.AssignTimes < 3 then 
            cacheData.AssignTimes = cacheData.AssignTimes +1 
            cacheData.nextAssignTime = cacheData.nextAssignTime + 300 
            randAssignCamp(atvId)
            BroadAssignCampTimeInfo(atvId, cacheData.fbHandle, Fuben.getSceneId(cacheData.scenHandle))
        end 
    end

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
                if pActor ~= nil then
                    RankMgr.AddValue(actorid, RANKING_ID, ActivityConfig[atvId].addScoreAuto)
                    OnDealAchieve(atvId, pActor)
                    local curVal = RankMgr.GetValue(actorid, RANKING_ID)
                    Actor.sendTipmsg(pActor, "持续参加活动，积分+"..ActivityConfig[atvId].addScoreAuto.."，当前积分为："..curVal, tstGetItem)
                    SendRankData(atvId,pActor)
                    hasMan = true
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

    -- 场次检测
    if curTime > (globalData.nextChgStatusTime or 0) then
        globalData.status = (globalData.status or 0) + 1
    end
end

-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
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
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    if cacheData.actors == nil then
        cacheData.actors = {}
    end
    local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    RemoveBuff(actorId,atvId)
    actorsInFuben[atvId][actorId] = nil

    -- 玩家下次进入时间限制
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    actorData.nextLoginTime = System.getCurrMiniTime() + 30

    -- 记录日志
    Actor.SendActivityLog(pActor,atvId,ActivityType,2)

    -- 清阵营
    Actor.setCampId(pActor, 0)

    -- 强制和平模式
    Actor.setPkMode(pActor,fpPeaceful)
   

    -- 恢复禁止普通频道聊天
    --Actor.setChatForbit(pActor, ciChannelNear, false)

end

--实体在活动副本中死亡
function OnEntityDeath(atvId, pEntity,pKiller,pFuben)
    if pEntity and (Actor.getEntityType(pEntity) ==enActor) then 

        local actorDataEntity =  ActivityDispatcher.GetActorData(pEntity, atvId)
        actorDataEntity.MaxMultiHit = 0 

        BuffPlus(pEntity,atvId)  --buff提升
        
    end 
    
    if pKiller and (Actor.getEntityType(pKiller) ==enActor) then
         
        local entityType = Actor.getEntityType(pEntity)--被击杀者的类型
        local killerType = Actor.getEntityType(pKiller)--击杀者的类型

        
        BuffDecrease(pKiller,atvId)  --buff削弱
        

        if killerType == enActor then
            if entityType == enActor then
                -- 杀玩家获得积分
                local killerId = Actor.getIntProperty( pKiller, PROP_ENTITY_ID )
                RankMgr.AddValue(killerId, RANKING_ID, ActivityConfig[atvId].addScoreKill)
                OnDealAchieve(atvId, pKiller)
                Actor.sendTipmsg(pKiller, "你成功击败["..Actor.getName(pEntity).."]，积分+"..ActivityConfig[atvId].addScoreKill, tstGetItem)

                -- 被玩家击杀的玩家获得的积分
                local entityId = Actor.getIntProperty( pEntity, PROP_ENTITY_ID )
                RankMgr.AddValue(entityId, RANKING_ID, ActivityConfig[atvId].addScoreBeKill)
                OnDealAchieve(atvId, pEntity)
                Actor.sendTipmsg(pEntity, "你被["..Actor.getName(pKiller).."]击败了，积分+"..ActivityConfig[atvId].addScoreBeKill, tstGetItem)

                --连胜超神公告
                local actorDataKiller =  ActivityDispatcher.GetActorData(pKiller, atvId)
                actorDataKiller.MaxMultiHit = actorDataKiller.MaxMultiHit + 1  
                if actorDataKiller.MaxMultiHit >= 10 then 
                    System.broadcastTipmsgLimitLev(Actor.getName(pKiller).."在夜战沃玛三已经超神！！", tstRevolving)
                elseif actorDataKiller.MaxMultiHit ==8 then 
                    System.broadcastTipmsgLimitLev(Actor.getName(pKiller).."无人可挡，在夜战沃玛三取得了八连胜！", tstRevolving)
                elseif actorDataKiller.MaxMultiHit ==5 then
                    System.broadcastTipmsgLimitLev(Actor.getName(pKiller).."主宰比赛，在夜战沃玛三取得了五连胜！", tstRevolving)
                elseif actorDataKiller.MaxMultiHit ==3 then 
                    System.broadcastTipmsgLimitLev(Actor.getName(pKiller).."在夜战沃玛三取得了三连胜！", tstRevolving)
                end


                -- 设置复活
                --SetAutoRelive(atvId, pEntity, pFuben)
            else
                -- 杀守卫获得积分
                local killerId = Actor.getIntProperty( pKiller, PROP_ENTITY_ID )
                RankMgr.AddValue(killerId, RANKING_ID, ActivityConfig[atvId].addScoreGuard)
                OnDealAchieve(atvId, killerId)
                Actor.sendTipmsg(pKiller, "你击败守卫，积分+"..ActivityConfig[atvId].addScoreGuard, tstGetItem)
            end

            if not attackerList[atvId] then attackerList[atvId] = {} end

            -- 助攻积分
            local handle = Actor.getHandle(pEntity)
            local entityName = Actor.getName(pEntity)
            if attackerList[atvId][handle] then
                local nowTime = System.getCurrMiniTime()
                local killerHandle = Actor.getHandle(pKiller)
                for attkHandle,time in pairs(attackerList[atvId][handle]) do
                    if nowTime - time <= ActivityConfig[atvId].helpTime and killerHandle ~= attkHandle then
                        local pActor = Actor.getEntity(attkHandle)
                        if pActor then
                            local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
                            RankMgr.AddValue(actorId, RANKING_ID, ActivityConfig[atvId].addScoreHelpKill)
                            OnDealAchieve(atvId, pActor)
                            Actor.sendTipmsg(pActor, "你助攻击败["..entityName.."]，积分+"..ActivityConfig[atvId].addScoreHelpKill, tstGetItem)
                        end
                    end
                end
            end
            attackerList[atvId][handle] = nil
        else
            -- 设置复活
            --SetAutoRelive(atvId, pEntity, pFuben)
        end
        SendRankData(atvId,pKiller)
    end
end

-- 活动副本中，实体守到攻击
function OnEntityAttacked(atvId, pEntity, pAttacker, pFuben)

    -- 攻击者必须为玩家，才记录助攻
    if Actor.getEntityType(pAttacker) == enActor then
        
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

-- 活动副本结束
function OnFubenFinish(atvId, pFuben, result)
    --广播成功失败的旗帜（带上自己的排行数据）
    for i,actorid in pairs(actorsInFuben[atvId]) do
        local pActor = Actor.getActorById(actorid)
        if pActor then
            local npack = ActivityDispatcher.AllocResultPack(pActor, atvId, 1)
            if npack then
                local actorId = Actor.getActorId(pActor)
                DataPack.writeUInt(npack, RankMgr.GetValue(actorId,RANKING_ID))
                DataPack.writeWord(npack, RankMgr.GetMyRank(pActor,RANKING_ID))
                DataPack.flush(npack)
            end
        end
    end
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

--活动红点数据
function OnGetRedPoint(atvId, pActor)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    local ret = 0
    --  local limitLv = 0;
    -- if cfg and cfg.openParam then
    --     limitLv =  (cfg.openParam.level or 0)
    -- end
    -- local lv = Actor.getIntProperty( pActor, PROP_CREATURE_LEVEL )

    if globalData.status and (globalData.status == AtvStatus.FirstHalf) then ret = 1 end
    -- if lv < limitLv then
    --     ret = 0;
    -- end

    local cfg = ActivityConfig[atvId]
    if cfg and cfg.openParam then
        if Actor.checkActorLevel(pActor,(cfg.openParam.level or 0)) ~=true then ret = 0 end
    end
    return ret
end
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType11.lua")

ActivityDispatcher.Reg(ActivityEvent.OnLoad, ActivityType, OnLoad, "ActivityType11.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType11.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType11.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType11.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType11.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType11.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType11.lua")
ActivityDispatcher.Reg(ActivityEvent.OnExitFuben, ActivityType, OnExitFuben, "ActivityType11.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEntityDeath, ActivityType, OnEntityDeath, "ActivityType11.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEntityAttacked, ActivityType, OnEntityAttacked, "ActivityType11.lua")
ActivityDispatcher.Reg(ActivityEvent.OnFubenFinish, ActivityType, OnFubenFinish, "ActivityType11.lua")

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------
