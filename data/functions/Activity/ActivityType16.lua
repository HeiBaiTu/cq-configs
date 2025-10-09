module("ActivityType16", package.seeall)

--[[
    个人活动
    每日签到

    个人数据：ActorData[AtvId]
    {
    }

    全局缓存：Cache[AtvId]
    {   
        
    }

    全局数据：GlobalData[AtvId]
    {
        LastLoginMonthofYear  = 1 , 上次签到的月份
        donatelist[id] 
    }
]]--

--活动类型
ActivityType = 16
--对应的活动配置
ActivityConfig = Activity16Config
-- if ActivityConfig == nil then
--     assert(false)
-- end

--排行榜id
RANKING_ID = RANK_DEFINE_ACTIVITY16

function nextMonthClear(atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    local dayofMonth = System.getDayOfMonth() 
    --local LinChengSec = System.getToday() 
    local MonthofYear  = System.getMonthOfNow();

    if globalData.LastLoginMonthofYear ==nil then 
        globalData.LastLoginMonthofYear = 0 ; 
    end 
    if globalData.donatelist ==nil then 
        globalData.donatelist = {} ; 
    end 
    
    --跨月了，数据清空
    if globalData.LastLoginMonthofYear ~= MonthofYear then 
        local Cfg = ActivityConfig
        if Cfg and Cfg.content then 
            System.broadcastTipmsgLimitLev(Cfg.content, tstBigRevolving)
            System.broadcastTipmsgLimitLev(Cfg.content, tstChatSystem)
        end
        --清空排行榜
        ActivityDispatcher.ClearGlobalData(atvId)
        RankMgr.Clear(RANKING_ID)

        globalData.donatelist = {} ; 
        globalData.LastLoginMonthofYear = MonthofYear;
    end
end  

--玩家请求领取礼包
function reqDonate(pActor, atvId , num)
    --print("[GActivity 16]reqDonate-------------------------------------------------------------- 捐献 活动数据加载，id："..atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    local Cfg = ActivityConfig 

    if Cfg then 

        local nowRankId = RankMgr.GetMyRank(pActor,RANKING_ID);
        local aid = Actor.getActorId(pActor)
        if num <= 0 or num < Cfg.minValue then 
            Actor.sendTipmsgWithParams(pActor, tmDonateRankNoDonate,tstUI);
            return 
        end
        local cost = {}
        local cost1= {}
        cost1["type"] = Cfg.costtype;
        cost1["id"] = Cfg.costid;
        cost1["count"] = num;
        table.insert(cost, cost1)
        if cost then
            if CommonFunc.Consumes.CheckActorSources(pActor, cost ,tstUI) ~= true then
                return
            end
        end
        --扣除消耗
        if cost then
            if CommonFunc.Consumes.Remove(pActor, cost, GameLog.Log_Activity16, "捐献排行|"..atvId) ~= true then
                return
            end
        end
        RankMgr.AddValue(aid, RANKING_ID, num)
        local rankId = RankMgr.GetMyRank(pActor,RANKING_ID);
        if rankId >  #Cfg.rankList then
            rankId = 0;
        end
        if rankId > 0 and nowRankId ~= rankId and Cfg.inrank then
            local str = string.format(Cfg.inrank,rankId)
            Actor.sendTipmsg(pActor, str,tstUI);
            if Cfg.tips[rankId] then
                local name = Actor.getName(pActor);
                local str = string.format(Cfg.tips[rankId],name)
                System.broadcastTipmsgLimitLev(str, tstKillDrop)
            end
        end
       globalData.donatelist[aid] = (globalData.donatelist[aid] or 0) + num;
       Actor.sendTipmsgWithParams(pActor, tmDonateRanksuccess,tstUI,num);
       -- 记录日志
       Actor.SendActivityLog(pActor,atvId,ActivityType,2)
       
    end 

    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
end 



--------------------------我是分界线----------------------------

-- 初始化玩家数据
function OnInit(atvId, pActor)                  
end

--活动开始
function OnStart(atvId)
    nextMonthClear(atvId)
end


-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cDonateRank then --捐献
        local num = DataPack.readInt(inPack)
        reqDonate(pActor, atvId , num)
    end
end


-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    --print("[GActivity 16]OnReqData-------------------------------------------------------------- 捐献 活动数据加载，id："..atvId)
    nextMonthClear(atvId);
    local Cfg = ActivityConfig
    if Cfg == nil then 
        return;
    end
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    
    local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    local donateValue = 0;
    if globalData.donatelist then
        donateValue = (globalData.donatelist[actorId] or 0)
    end
    if  outPack then  
        DataPack.writeInt(outPack, (donateValue or 0))   --
        local rankId = RankMgr.GetMyRank(pActor,RANKING_ID);
        if rankId >  #Cfg.rankList then
            rankId = 0;
        end
        DataPack.writeWord(outPack, rankId)
        local num = Cfg.showRank

        --print("[GActivity 16]OnReqData------------------------rankId："..tostring(rankId))
        RankMgr.PushToPack(RANKING_ID, num, outPack)
    end

end


function OnLoginGame(atvId,pActor)
    nextMonthClear(atvId)
    local rankId = RankMgr.GetMyRank(pActor,RANKING_ID);
    if rankId > 0 then
        local Cfg = ActivityConfig
        if Cfg and Cfg.rankList[rankId] then
            for _, buffId in pairs(Cfg.rankList[rankId]) do
                Actor.addBuffById(pActor, buffId)
            end
        end
    end
end 

function sendRankInfo(atvId)
    local num = 6;
    local Cfg = ActivityConfig
    if Cfg then 
        num = Cfg.showRank
    end
    local npack = ActivityDispatcher.AllocOperReturnEx(atvId, ActivityOperate.sSendRankData)
    if npack then
        RankMgr.PushToPack(RANKING_ID, num, npack)
        ActivityDispatcher.FreePacketEx(npack)
    end
end 


-- 活动结束
function OnEnd(atvId)
    local Cfg = ActivityConfig
    if Cfg and Cfg.content then 
        System.broadcastTipmsgLimitLev(Cfg.content, tstBigRevolving)
        System.broadcastTipmsgLimitLev(Cfg.content, tstChatSystem)
    end
    ActivityDispatcher.ClearGlobalData(atvId)
end

function OnUpdate(atvId, curTime)
    nextMonthClear(atvId)
end
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType16.lua")
ActivityDispatcher.Reg(ActivityEvent.OnLoginGame, ActivityType, OnLoginGame, "ActivityType16.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType16.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType16.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType16.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType16.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType16.lua")
