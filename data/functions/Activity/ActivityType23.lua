module("ActivityType23", package.seeall)

--[[
    个人活动，膜拜活动

    个人数据：ActorData[AtvId]
    {
        count, 剩余膜拜次数
        dailytime 每日次数
        openDay 统计开服时间
    }

    全局缓存：Cache[fbId]
    {

    }

    全局数据：GlobalData[AtvId]
    {

    }
]]--

--活动类型
local ActivityType = 23
--对应的活动配置
local ActivityConfig = Activity23Config
local WorshipCommonConfig= WorshipCommonConfig
if ActivityConfig == nil then
    assert(false)
end

if WorshipCommonConfig == nil then
    assert(false)
end

--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------

--膜拜操作
function operaWorship(pActor, atvId, Conf, inPack)
    -- local nId = DataPack.readUInt(inPack)
    local nIndex = DataPack.readByte(inPack)
    local errorcode = 0
    local WorshipCfg = WorshipCommonConfig[atvId]
    if WorshipCfg == nil then
        return
    end
    while(true)
    do
        local data = ActivityDispatcher.GetActorData(pActor,atvId)

        --消耗检查
        local consumes = nil

        --次数检查

        if data.count == nil then
            data.count = Conf.count
        else
            if data.count <= 0 then
                Actor.sendTipmsgWithId(pActor, tmNoTimes, tstUI)
                errorcode = 2
                break
            end
        end
        if data.dailytime == nil then
            data.dailytime = 0
        end

        consumes = WorshipCfg.cost1
        if WorshipCfg.n then
            if data.dailytime >= WorshipCfg.n then
                consumes = WorshipCfg.cost2
            end
        end
        -- if WorshipCfg.rankid then

        --     local ranking = Ranking.getRanking(WorshipCfg.rankid )
        --     if ranking then
        --         local result = Ranking.CheckActorIdInRank(ranking, nId)
        --         if result == false then
        --             errorcode = 3
        --             Actor.sendTipmsgWithId(pActor, tmPleaseReferRank, tstUI)
        --             break
        --         end
        --     end
        -- end
        if consumes then
            if CommonFunc.Consumes.Check(pActor, consumes) ~= true then
                Actor.sendTipmsgWithId(pActor, tmNoMoreBindCoin, tstUI)
                errorcode = 1
                break
            end
        end
        if CommonFunc.Awards.CheckBagIsEnough(pActor,11,tmDefNoBagNum,tstUI) ~= true then
            return
        end
        -- 消耗
        if consumes and CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity4, "膜拜活动|"..atvId) ~= true then
            errorcode = 3
            break
        end
        if WorshipCfg.rewards then
            --CommonFunc.GiveCommonAward(pActor, WorshipCfg.rewards, GameLog.Log_Activity4,  "膜拜活动|"..atvId)
            
            if CommonFunc.Awards.Give(pActor, WorshipCfg.rewards, GameLog.Log_Activity4, "膜拜活动|"..atvId, 11 ) ~= true  then 
                return 
            end 

        end
        -- 操作成功
        Actor.triggerAchieveEvent(pActor, nAchieveActivity,1 ,atvId);
        Actor.triggerAchieveEvent(pActor, nAchieveCompleteActivity,1 ,atvId);
        -- print("count:",data.count)
        data.count = data.count - 1
        -- print("count111111:",data.count)
        data.dailytime =  data.dailytime + 1
        -- 记录日志
        Actor.SendActivityLog(pActor,atvId,ActivityType,2)
        break
    end

    local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sWorship)
    -- local netPack = DataPack.allocPacket(pActor,enActivityID, sSendPersonActivityUpdate)
    if  outPack then
        -- DataPack.writeUInt(outPack, nId)
        DataPack.writeByte(outPack, nIndex)
        DataPack.writeByte(outPack, errorcode) 
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
    print("[PActivity 23] "..Actor.getName(pActor).." 活动开始了，id："..atvId)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    local openday = System.getDaysSinceOpenServer() - ((PActivitiesConf[atvId].OpenSrvDate or 0) -1);
    data.count = openday * (ActivityConfig[atvId].count or 1)
    if data.openDay == nil then
        data.openDay = System.getDaysSinceOpenServer()
    end

end


-- function SendPushToPack(Cfg, pack)
--     local itemNum = 0;
--     if itemNum ~= -1 and (Cfg ~= nil and Cfg.rankid ~= nil) then
--         local ranking = Ranking.getRanking( Cfg.rankid )
--         if (ranking == nil) then
--             itemNum = 0
--         end

--         local itemNum = Ranking.getRankItemCount(ranking)
--         if (itemNum == nil) then
--             itemNum = 0
--         end

--         DataPack.writeByte(pack, itemNum)
--         for idx=1,itemNum do
--             local rankItem = Ranking.getItemFromIndex(ranking, idx-1)
--             if rankItem then
--                 local playerId  = Ranking.getId(rankItem)
--                 local name 	 	= Ranking.getSub(rankItem, 0)
--                 local sexJob 	= Ranking.getSub(rankItem, 1)
--                 DataPack.writeUInt(pack, playerId)
--                 DataPack.writeString(pack, name)
--                 DataPack.writeString(pack, sexJob)
--             end
--         end
--     else
--         DataPack.writeByte(pack, 0)
--     end
-- end


-- 活动结束
function OnEnd(atvId, pActor)
    print("[Activity 23] "..Actor.getName(pActor).." 活动结束了，id："..atvId)
end

-- 活动帧更新
function OnUpdate(atvId, curTime, pActor)
    --print("[Activity 1] "..Actor.getName(pActor).." 活动进行中，id："..atvId.." now:"..curTime)
end

-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    -- print("OnReqData:",data.count)
    DataPack.writeInt(outPack, (data.count or 0))
    -- local WorshipCfg = WorshipCommonConfig[atvId]
    -- -- 发送排行数据
    -- SendPushToPack(WorshipCfg, outPack)
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- id对应配置
    local Conf = ActivityConfig[atvId]
    if Conf == nil then
        print("[Activity 23] "..Actor.getName(pActor).." 活动配置中找不到活动id："..atvId)
    end
    
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cWorship then     -- 请求膜拜
        operaWorship(pActor,atvId,Conf,inPack)
    end
end

--活动红点数据
function OnGetRedPoint(atvId, pActor)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    local ret = 0
    if data.count and (data.count > 0) then ret = 1 end
    local cfg = ActivityConfig[atvId]
    if cfg and cfg.openParam then
        if Actor.checkActorLevel(pActor,(cfg.openParam.level or 0)) ~=true then ret = 0 end
    end
    return ret
end

ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType23.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType23.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType23.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType23.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType23.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType23.lua")

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 跨天，次数清零
function OnNewDayArrive(pActor)
    local openday = System.getDaysSinceOpenServer()
    
    local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
    if runAtvIdList == nil then 
        return 
    end
    for i,atvId in ipairs(runAtvIdList) do
        print("[Activity 23] "..Actor.getName(pActor).." 跨天清空活动次数,atvId="..atvId)
        local data = ActivityDispatcher.GetActorData(pActor,atvId)

        if data.count == nil then
            data.count = 0
        end
        if data.openDay == nil then
            data.openDay = (PActivitiesConf[atvId].OpenSrvDate or 0) -1
        end
        -- 按照离线时间 
        local offday = 1;
        -- print("OnNewDayArrive.."..data.openDay.."..openday.."..openday)
        offday = openday- data.openDay;
        if offday < 0 then
            offday = 1;
        end
        data.count = data.count + offday * (ActivityConfig[atvId].count or 1)
        -- print("OnNewDayArrive:",data.count)
        data.dailytime = 0
        
        data.openDay = openday
        -- 发送一个活动数据
        Actor.sendActivityData(pActor, atvId)
    end
end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType23.lua")
