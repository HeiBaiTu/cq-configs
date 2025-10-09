module("ActivityType10002", package.seeall)

--[[
    个人活动
   礼包活动

    个人数据：ActorData[AtvId]
    {
        buy {index:num } --已购买的次数
    }

    全局缓存：Cache[AtvId]
    {   
        
    }

    全局数据：GlobalData[AtvId]
    {
    
    }
]]--

--活动类型
ActivityType = 10002
--对应的活动配置
ActivityConfig = Activity10002Config
if ActivityConfig == nil then
    assert(false)
end



--玩家请求购买礼包
function reqPurchaseGiftBox(pActor, atvId , indexId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData == nil then
        actorData = {}
    end

    if actorData.buy == nil then
        actorData.buy = {}
    end
    local Cfg = ActivityConfig[atvId]

    if Cfg == nil then
        return;
    end
    local ThisCfg = Cfg[indexId]
    if ThisCfg then
        local atvOpenDay = System.getPActivityOpenDay(atvId);
        --检测开放购买天数
        if ThisCfg.BuyDayLmt then
            if (atvOpenDay + ThisCfg.BuyDayLmt -1) > System.getDaysSinceOpenServer() then 
                Actor.sendTipmsg(pActor, "|C:0xf56f00&T:未开放购买 请耐心等待|", tstUI)
                return 
            end 
        end 

        if ThisCfg.timeLimit then
            if (atvOpenDay + ThisCfg.timeLimit -1) < System.getDaysSinceOpenServer() then 
                Actor.sendTipmsg(pActor, "|C:0xf56f00&T:购买时间已结束|", tstUI)
                return 
            end 
        end 

        --提示没有购买次数
        if ThisCfg.BuyLimit then
            local leftNum = ThisCfg.BuyLimit - (actorData.buy[indexId] or 0)
            if leftNum <= 0 then
                Actor.sendTipmsg(pActor, "|C:0xf56f00&T:已无购买次数|", tstUI)
                return 
            end
        end

        --检查消耗是否满足条件
        if ThisCfg.price then
            if CommonFunc.Consumes.CheckActorSources(pActor, ThisCfg.price ,tstUI) ~= true then
                --Actor.sendTipmsgWithId(pActor, tmNomoreYubao, tstUI)
                return
            end
        end

        --检查格子够不够
        -- if CommonFunc.Awards.CheckBagIsEnough(pActor,10) ~= true then
        --     Actor.sendTipmsgWithId(pActor, tmLeftBagNumNotEnough, tstUI)
        --     return
        -- end
        if CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmLeftBagNumNotEnough,tstUI) ~= true then
            return
        end

        --扣除消耗
        if CommonFunc.Consumes.Remove(pActor, ThisCfg.price, GameLog.Log_Activity10002, "礼包活动|"..atvId) ~= true then
            return
        end

        if ThisCfg.award then
            --CommonFunc.GiveCommonAward(pActor, ThisCfg.award, GameLog.Log_Activity10002,  "礼包活动|"..atvId)
            CommonFunc.Awards.Give(pActor, ThisCfg.award, GameLog.Log_Activity10002,  "礼包活动|"..atvId)
        end

        -- 记录日志
        Actor.SendActivityLog(pActor,atvId,ActivityType,2)
        
        Actor.sendTipmsgWithId(pActor, tmConsiBuySuccAddToBag, tstUI)
        if ThisCfg.BuyLimit then
            actorData.buy[indexId] = (actorData.buy[indexId] or 0) + 1;
        end
    end 

    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
end 



--------------------------我是分界线----------------------------

-- 初始化玩家数据
function OnInit(atvId, pActor)
    print("[GActivity 10002]  特惠礼包"..Actor.getName(pActor).." 初始化 id："..atvId)
    ActivityDispatcher.ClearActorData(pActor, atvId);
    -- local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    -- local Cfg = ActivityConfig[atvId]
    -- if actorData.LeftPurchaseGiftBoxTimes == nil then
    --     actorData.LeftPurchaseGiftBoxTimes = {}
    --     for i = 1, Cfg.GiftBoxNum do
    --         if Cfg.GiftTable[i] and (Cfg.GiftTable[i].timesLimit ~= nil ) then
    --             --if i == Cfg.GiftTable[i].id then 
    --                 actorData.LeftPurchaseGiftBoxTimes[i] = Cfg.GiftTable[i].timesLimit
    --             --end 
    --         end 
    --     end
    -- end                      
end

--活动开始
function OnStart(atvId, pActor)
    print("[activitytype10002] ---onstart  atvId:"..atvId)
end


-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cReqPurchaseGiftbag then --请求购买特惠礼包
        local indexId = DataPack.readByte(inPack)
        reqPurchaseGiftBox(pActor, atvId , indexId)
    end
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
            for _, cfg in pairs(Cfg) do
                DataPack.writeByte(outPack, (cfg.GiftBoxNum or 0))
                local leftNum = -1;
                if cfg.BuyLimit then
                    leftNum = cfg.BuyLimit - (actorData.buy[cfg.GiftBoxNum] or 0)
                    if leftNum < 0 then
                        leftNum = 0;
                    end
                end
                DataPack.writeByte(outPack, (leftNum or 0))
            end
        end
    end
end



-- 活动结束
function OnEnd(atvId, pActor)
    ActivityDispatcher.ClearActorData(pActor, atvId)
end

ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType10002.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType10002.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType10002.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType10002.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType10002.lua")
