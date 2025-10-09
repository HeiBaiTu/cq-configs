module("ActivityType10015", package.seeall)

--[[
    全局个人活动 
    礼包活动，每周固定时间
    
    个人数据：ActorData[AtvId]
    {
        buy {index:num } --已购买的次数
        EndTime    --活动结束时间，在GPStart里维护
        dailyBuy --每日
    }
]]--

--活动类型
ActivityType = 10015
--对应的活动配置
ActivityConfig = Activity10015Config
if ActivityConfig == nil then
    assert(false)
end

--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------


--玩家请求购买礼包
function reqPurchaseGiftBox(pActor, atvId , indexId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData == nil then
        actorData = {}
    end
-- print("------------ActivityType : "..ActivityType)    
-- print("------------atvId : "..atvId)
-- print("------------indexId : "..indexId)
-- print("------------actorName : "..Actor.getName(pActor))


    if actorData.buy == nil then
        actorData.buy = {}
    end
    if actorData.dailyBuy == nil then
        actorData.dailyBuy = {}
    end
    local Cfg = ActivityConfig[atvId]

    if Cfg == nil then
        return;
    end
    local ThisCfg = Cfg[indexId]
    if ThisCfg then

        --提示没有购买次数
        if ThisCfg.BuyLimit then
            local leftNum = ThisCfg.BuyLimit - (actorData.buy[indexId] or 0)
            if leftNum <= 0 then
                Actor.sendTipmsg(pActor, "|C:0xf56f00&T:已无购买次数|", tstUI)
                return 
            end
        end
        if ThisCfg.Dailylimit then
            local leftNum = ThisCfg.Dailylimit - (actorData.dailyBuy[indexId] or 0)
            if leftNum <= 0 then
                Actor.sendTipmsg(pActor, "|C:0xf56f00&T:已无购买次数|", tstUI)
                return 
            end
        end

        --检查消耗是否满足条件
        if ThisCfg.price then
            if CommonFunc.Consumes.CheckActorSources(pActor, ThisCfg.price ,tstUI) ~= true then
                
                return
            end
        end

        --检查背包
        if CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmLeftBagNumNotEnough,tstUI) ~= true then
            return
        end

        --扣除消耗
        if CommonFunc.Consumes.Remove(pActor, ThisCfg.price, GameLog.Log_Activity10015, "每周礼包活动|"..atvId) ~= true then
            return
        end
--print("-----------11111")
        --发放奖励
        if ThisCfg.award then
            local decstr = "每周礼包活动";
            if ActivitiesConf[atvId] and ActivitiesConf[atvId].ActivityName then
                decstr = ActivitiesConf[atvId].ActivityName
            end
--print("-----------2222")
            CommonFunc.Awards.Give(pActor, ThisCfg.award, GameLog.Log_Activity10015,  decstr)
        end
--print("-----------3333")
        -- 记录日志
        Actor.SendActivityLog(pActor,atvId,ActivityType,2)
        
        Actor.sendTipmsgWithId(pActor, tmConsiBuySuccAddToBag, tstUI)
        if ThisCfg.BuyLimit then
            actorData.buy[indexId] = (actorData.buy[indexId] or 0) + 1;
        end
        if ThisCfg.Dailylimit then
            actorData.dailyBuy[indexId] = (actorData.dailyBuy[indexId] or 0) + 1;
        end
        if ThisCfg.tips then
            local name = Actor.getName(pActor);
            local str = string.format(ThisCfg.tips,name)
            System.broadcastTipmsgLimitLev(str, tstKillDrop)
        end
    end 

    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
end 


--------------------------------------------------------------------
-- 活动 回调注册
--------------------------------------------------------------------

-- 全局个人开始
function OnGPStart(atvId, pActor)
    --print("-------测试type类型 : 全局个人OnGPStart ---")
    --初始化活动个人数据
    
    --重置数据，重新开始
    --actorData.timesCount = 0
    
end 

--全局个人结束
function OnGPEnd(atvId, pActor)
    ActivityDispatcher.ClearActorData(pActor, atvId);
    --print("-------测试type类型 : 全局个人OnGPEnd ---")
    
end 


-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    
    if  outPack then
        local len = 0
        local Cfg = ActivityConfig[atvId]
        
        if Cfg then
            len = #Cfg;
        end
        DataPack.writeByte(outPack, (len or 0));
        local openDay = System.getDaysSinceOpenServer();
        if len > 0 then
            local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
            if actorData == nil then
                actorData = {}
            end;

            if actorData.buy == nil then
                actorData.buy = { }
            end
            if actorData.dailyBuy == nil then
                actorData.dailyBuy = {}
            end
            for _, cfg in pairs(Cfg) do
                DataPack.writeByte(outPack, (cfg.GiftBoxNum or 0))
                local leftNum = -1;
                if cfg.BuyLimit then
                    leftNum = cfg.BuyLimit - (actorData.buy[cfg.GiftBoxNum] or 0)
                    if leftNum < 0 then
                        leftNum = 0;
                    end
                end
                if cfg.Dailylimit then
                    leftNum = cfg.Dailylimit - (actorData.dailyBuy[cfg.GiftBoxNum] or 0)
                    if leftNum < 0 then
                        leftNum = 0;
                    end
                end
                DataPack.writeShort(outPack, (leftNum or 0))
            end
        end
    end
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cReqPurchaseGiftbag then --请求购买每周礼包
        local indexId = DataPack.readByte(inPack)
        reqPurchaseGiftBox(pActor, atvId , indexId)
    end
end


--活动红点数据
function OnGetRedPoint(atvId, pActor)
    local ret =  0 
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    if data == nil then
        data = {}
    end

    if data.buy == nil then
        data.buy = { }
    end
    if data.dailyBuy == nil then
        data.dailyBuy = {}
    end

    local Cfg = ActivityConfig[atvId]
    for _, cfg in pairs(Cfg) do
        if cfg.redType then
            local leftNum = -1;
            if cfg.BuyLimit then
                leftNum = cfg.BuyLimit - (data.buy[cfg.GiftBoxNum] or 0)
                if leftNum < 0 then
                    leftNum = 0;
                end
            end
            if cfg.Dailylimit then
                leftNum = cfg.Dailylimit - (data.dailyBuy[cfg.GiftBoxNum] or 0)
                if leftNum < 0 then
                    leftNum = 0;
                end
            end
            -- print("leftNum.."..leftNum.."..times.."..(data.dailyBuy[cfg.GiftBoxNum] or 0))
            if leftNum ~= 0 then
                ret = System.setIntBit(ret, cfg.GiftBoxNum -1, true)
            end
        end
    end
    return ret 
end 


--使用GPStart和GPEnd 这里需要在登陆时将结束时间传入，检查开始结束事件
function OnLoginGame(atvId,pActor)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData.EndTime == nil   then 
        actorData.EndTime = 0 
    end 
    System.CheckGPActivityStartEnd(pActor,atvId,actorData.EndTime)

end 

--------------------------我是分界线----------------------------
-- 初始化玩家数据
function OnInit(atvId, pActor)
    print("[GActivity 10015]  礼包活动"..Actor.getName(pActor).." 初始化 id："..atvId)
    ActivityDispatcher.ClearActorData(pActor, atvId)   
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    actorData.EndTime = System.getActivityEndMiniSecond(atvId)             
end

ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType10015.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGPStart, ActivityType, OnGPStart, "ActivityType10015.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGPEnd, ActivityType, OnGPEnd, "ActivityType10015.lua")
ActivityDispatcher.Reg(ActivityEvent.OnLoginGame, ActivityType, OnLoginGame, "ActivityType10015.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType10015.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType10015.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType10015.lua")

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 跨天，次数清零
function OnNewDayArrive(pActor,ndiffday)
    print("[PActivity 10015] "..Actor.getName(pActor).." 跨"..ndiffday.."天")
    local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
    if runAtvIdList == nil then return end
    for i,atvId in ipairs(runAtvIdList) do

        local data = ActivityDispatcher.GetActorData(pActor,atvId)
        data.dailyBuy = nil
        -- 发送一个活动数据
        Actor.sendActivityData(pActor, atvId)
    end
end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10015.lua")


