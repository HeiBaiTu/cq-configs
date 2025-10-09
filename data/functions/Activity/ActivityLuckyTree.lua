-- module("ActivityLuckyTree", package.seeall)
math.randomseed(System.getCurrMiniTime())
--[[
   
    摇钱树
    
    个人数据：treedata
    {
        dailyTimes --每日要钱次数 
        lastLoginTime --登录时间
        nowVip --当前vip
    }
]]--
TreeConstConfig = MoneytreeconstConfig
MoneytreeRewardConfig = MoneytreeRewardConfig
--对应的活动配置
function getLuckyTreeData(pActor)
    local var = Actor.getStaticVar(pActor)
    if var.treeData== nil then
        var.treeData = {}
    end
    return var.treeData
end

function SendLuckyTreeData(pActor)
    local npack = DataPack.allocPacket(pActor, enMiscSystemID, sLuckyTree)
    if npack then
        local data = getLuckyTreeData(pActor)
        DataPack.writeUInt(npack, (data.dailyTimes or 0))--礼包的领取标记 32 位
        DataPack.flush(npack)
    end
end

--------------------------------------------------------------------
-- 客户端请求协议回调
-------------------------------------------------------------------
function OnLuckyTreeLogin(pActor) 
    --print("[ActivityLuckyTree:OnLuckyTreeLogin-----------1------------874--------------------2213----------------23------------ ")
    local data = getLuckyTreeData(pActor);
    if data.lastLoginTime == nil then
        data.lastLoginTime = System.getCurrMiniTime()
        if TreeConstConfig and TreeConstConfig.times then
            local vip = Actor.GetMaxColorCardLevel(pActor);
            data.dailyTimes = TreeConstConfig.times[vip+1];
            data.nowVip = vip+1;
        end
        
        --print("第一天")
    end
    SendLuckyTreeData(pActor);
end

function getMoneyTreeAward()
    local openDay = System.getDaysSinceOpenServer()
    local awardCfgs = {};
    local nMinDay = 0;
    if MoneytreeRewardConfig == nil then
        return nil
    end
    for _, awardCfg in pairs(MoneytreeRewardConfig) do
        if awardCfg.Opendaylimit <= openDay and awardCfg.Opendaylimit > nMinDay then
            nMinDay = awardCfg.Opendaylimit
        end
    end

    local nMaxRand = 0;
    for _, awardCfg in pairs(MoneytreeRewardConfig) do
        if awardCfg.Opendaylimit == nMinDay then
            nMaxRand = nMaxRand + awardCfg.rate;
            table.insert(awardCfgs, awardCfg)
        end
    end

    local value = math.random(nMaxRand);
    local nRandValue = 0;
    for _, cfg in pairs(awardCfgs) do
        nRandValue = nRandValue + cfg.rate 
        if value <= nRandValue then
            return cfg
        end
    end
    return nil
end

function OnRockLuckyTree(pActor, packet)
    --print("[ActivityLuckyTree:OnRockLuckyTree----------3253------------23274--------------------123213---------------123------------ ")
    local data = getLuckyTreeData(pActor)
    if data == nil then
        return
    end
    if (not data.dailyTimes) or (data.dailyTimes <= 0) then
        -- Actor.sendTipmsgWithId(pActor, tmMoneyTreeNoTimes, tstUI);
        return;
    end

    if TreeConstConfig.limit then
        if Actor.checkCommonLimit(pActor,
                                (TreeConstConfig.limit.level or 0), 
                                (TreeConstConfig.limit.zsLevel or 0),
                                (TreeConstConfig.limit.vip or 0), 
                                (TreeConstConfig.limit.office or 0) ) == false then

            return;
        end
    end
    local costYb = 0;
    if CommonFunc.Consumes.CheckActorSources(pActor, TreeConstConfig.cost1, 0) ~= true then
        --print("[ActivityLuckyTree:return--------&&&&&&&&&&&&&&&&&----------- costYb:"..tostring(costYb))
        if CommonFunc.Consumes.CheckActorSources(pActor, TreeConstConfig.cost2, tstUI) ~= true then
            return;
        end
        costYb = 1;
    end 
    --print("[ActivityLuckyTree:return--------&&&&&&&&&&&&&&&&&1111-------------------- costYb:"..tostring(costYb))
    --return;
    -- if CommonFunc.Awards.CheckBagIsEnough(pActor,8,tmLeftBagNumNotEnough,tstUI) ~= true then
    --     print("4444")
    --     return
    -- end
    
    if costYb == 1 then
        CommonFunc.Consumes.Remove(pActor, TreeConstConfig.cost2, GameLog.Log_MoneyTree, "摇钱树")
    else
        CommonFunc.Consumes.Remove(pActor, TreeConstConfig.cost1, GameLog.Log_MoneyTree, "摇钱树")
    end
    local AwardCfg = getMoneyTreeAward();
    if AwardCfg then
        if AwardCfg.tips then
            local name = Actor.getName(pActor);
            System.broadTipmsgWithParams(AwardCfg.tips ,tstKillDrop, name)
            System.broadTipmsgWithParams(AwardCfg.tips ,tstChatSystem, name)
        end
        CommonFunc.Awards.Give(pActor, AwardCfg.reward, GameLog.Log_MoneyTree)
        if AwardCfg.Uitips then
            Actor.sendTipmsg(pActor, AwardCfg.Uitips, tstUI);
        end
        
    end
    data.dailyTimes = data.dailyTimes - 1;
    SendLuckyTreeData(pActor)
end


function UpdateTreeTimes(pActor)
    local currMiniTime = System.getCurrMiniTime()
    local data = getLuckyTreeData(pActor)
    local vip = Actor.GetMaxColorCardLevel(pActor);
    local times = TreeConstConfig.times[vip+1];
    if data.nowVip then
        times = times - (TreeConstConfig.times[data.nowVip] or 0)
    end
    data.dailyTimes = (data.dailyTimes or 0) + times;
    data.nowVip = vip+1

    SendLuckyTreeData(pActor)
end
--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------
-- 跨天
function OnNewDayArrive(pActor,ndiffday)
    local currMiniTime = System.getCurrMiniTime()
    local data = getLuckyTreeData(pActor)
    if data.lastLoginTime then
        if not System.isSameDay(data.lastLoginTime, System.getCurrMiniTime()) then
            data.lastLoginTime = System.getCurrMiniTime()
            if TreeConstConfig and TreeConstConfig.times then
                local vip = Actor.GetMaxColorCardLevel(pActor);
                data.dailyTimes = TreeConstConfig.times[vip+1];
                data.nowVip = vip+1
            end
        end

        SendLuckyTreeData(pActor)
    end
end


ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityLuckyTree.lua")


NetmsgDispatcher.Reg(enMiscSystemID, cLuckyTree, OnLuckyTreeLogin)
NetmsgDispatcher.Reg(enMiscSystemID, cGetLuckyMoney, OnRockLuckyTree)