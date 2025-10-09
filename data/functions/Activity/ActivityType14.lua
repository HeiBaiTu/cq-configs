module("ActivityType14", package.seeall)

--[[
    玛法战令

    个人数据：ActorData[AtvId]
    {
        award[index]
        {
        }
        int sorce  //积分
        daily --每日
        ever --永久
        openTime
    }

    全局缓存：Cache[AtvId]
    {   
        
    }

    全局数据：GlobalData[AtvId]
    {
        int nNumber --活动编号
    }
]]--

--活动状态
local AtvType =
{
    Type1 = 1,   --普通类型
    Type2 = 2,  --黄金
    Type3 = 3, --至尊
}

--活动类型
ActivityType = 14
--对应的活动配置
ActivityConfig = Activity14Config
ActivitySetConfig = ActivitysetConfig
ShopCfg = Activity14shopConfig
if ActivityConfig == nil then
    assert(false)
end

if ActivitySetConfig == nil then
    assert(false)
end


--玩家请求领取奖励
function reqGetAward(pActor, atvId ,nType, indexId)
    -- print("nType.."..(nType or 0).."..indexId.."..indexId);
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    if globalData == nil then
        return
    end

    -- local id = Actor.getIntProperty(pActor, PROP_ENTITY_ID);
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:数据异常,请重新登录|", tstUI)
        return
    end

    local Cfg = nil;
    if ActivityConfig[atvId] then
        local AtvCfg = ActivityConfig[atvId][(globalData.nNumber or 1)];
        if AtvCfg then
            Cfg = AtvCfg[indexId]
        end
    end
    if Cfg == nil then
        return
    end

    
    local SetCfg = ActivitySetConfig[atvId];
    if SetCfg == nil then
        return 
    end

    local setCfg = SetCfg[(globalData.nNumber or 1)];
    if setCfg == nil then
        return 
    end

    local sorce = Actor.getConsume(pActor, setCfg.timer,setCfg.timer)
    -- local sorce = Actor.getStaticCount(pActor, setCfg.timer)
    --初始化数据

    if actorData == nil then
        actorData = {}
    end

    --判断逻辑
    if sorce < Cfg.accumulate then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:条件未达成|", tstUI)
        return
    end

    --未购买
    local data = actorData[nType];
    if data == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:该特权未激活|", tstUI)
        return
    end
    
    --提示已领取无法多次领取
    if data[indexId] then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:您已领取该奖励|", tstUI)
        return 
    end 
    
    
    --检查格子够不够
    if CommonFunc.Awards.CheckBagIsEnough(pActor,setCfg.bagremain,setCfg.tips,tstUI) ~= true then
        return
    end

    --普通奖励
    if Cfg.rewardA and nType == AtvType.Type1 then
        CommonFunc.GiveCommonAward(pActor, Cfg.rewardA, GameLog.Log_Activity14,  "玛法凭证奖励|"..atvId)
    end
    --黄金
    if Cfg.rewardB and nType == AtvType.Type2 then
        CommonFunc.GiveCommonAward(pActor, Cfg.rewardB, GameLog.Log_Activity14,  "黄金凭证奖励|"..atvId)
    end

    actorData[nType][indexId] = 1;

    Actor.sendTipmsgWithId(pActor, tmMailGetItemSuccess, tstUI)
    -- 记录日志
    Actor.SendActivityLog(pActor,atvId,ActivityType,2)
    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
    SendZLMoney(pActor);
end




--玩家请求领取奖励
function reqGetAllAward(pActor, atvId )
    -- print("11111.."..atvId);
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    if globalData == nil then
        return
    end

    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:数据异常,请重新登录|", tstUI)
        return
    end

    local Cfg = nil;
    if ActivityConfig[atvId] then
        Cfg = ActivityConfig[atvId][(globalData.nNumber or 1)];
    end
    if Cfg == nil then
        return
    end

    -- print("fgfgfgf.."..atvId);
    local SetCfg = ActivitySetConfig[atvId];
    if SetCfg == nil then
        return 
    end
    -- print("hhhh.."..atvId);
    local setCfg = SetCfg[(globalData.nNumber or 1)];
    if setCfg == nil then
        return 
    end

    local sorce = Actor.getConsume(pActor, setCfg.timer,setCfg.timer)
    --初始化数据

    if actorData == nil then
        actorData = {}
    end

    local nSuccess = false;
    for index = 1, 60 do
        local cfg =  Cfg[index]
        if cfg and sorce >= cfg.accumulate then
            if actorData[AtvType.Type1] and actorData[AtvType.Type1][cfg.tokenlevel] == nil then
                if CommonFunc.Awards.CheckBagIsEnough(pActor,setCfg.bagremain,setCfg.tips,tstUI) ~= true then
                    Actor.sendActivityData(pActor, atvId)
                    return
                end
                nSuccess = true;
                if cfg.rewardA then
                    CommonFunc.GiveCommonAward(pActor, cfg.rewardA, GameLog.Log_Activity14,  "玛法凭证奖励|"..atvId)
                end
            
                actorData[AtvType.Type1][cfg.tokenlevel] = 1;
            end
            if actorData[AtvType.Type2] and actorData[AtvType.Type2][cfg.tokenlevel] == nil then
                if CommonFunc.Awards.CheckBagIsEnough(pActor,setCfg.bagremain,setCfg.tips,tstUI) ~= true then
                    Actor.sendActivityData(pActor, atvId)
                    return
                end
                nSuccess = true;
                if cfg.rewardB then
                    CommonFunc.GiveCommonAward(pActor, cfg.rewardB, GameLog.Log_Activity14,  "黄金凭证奖励|"..atvId)
                end
            
                actorData[AtvType.Type2][cfg.tokenlevel] = 1;
            end
        end
    end
    if nSuccess then
         -- 记录日志
        Actor.SendActivityLog(pActor,atvId,ActivityType,2)
        Actor.sendTipmsgWithId(pActor, tmMailGetItemSuccess, tstUI)
        -- 发送一个活动数据
        Actor.sendActivityData(pActor, atvId)
    end
  
end

--购买
function buyOrderWarLv(pActor, atvId , lv)
    -- print("lv.."..lv)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    if globalData == nil then
        return
    end
    -- local id = Actor.getIntProperty(pActor,PROP_ENTITY_ID);
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData == nil then
        actorData = {}
    end

    local SetCfg = ActivitySetConfig[atvId];
    if SetCfg == nil then
        return 
    end

    local setCfg = SetCfg[(globalData.nNumber or 1)];
    if setCfg == nil then
        return 
    end
   
    local sorce = Actor.getConsume(pActor, setCfg.timer,setCfg.timer)
    -- print("sorce.."..sorce)
    -- local sorce = Actor.getStaticCount(pActor, setCfg.timer)
    local nowlv = getNowLv(atvId, (globalData.nNumber or 1), (sorce or 0))
    -- print("nowlv.."..nowlv)
    nowlv = (nowlv or 0) + lv
    -- print("add nowlv.."..nowlv)
    local value = 0;
    local limitLv = 0;
    if ActivityConfig[atvId] then
        local Cfg = ActivityConfig[atvId][(globalData.nNumber or 1)];
        if Cfg and Cfg[nowlv] then
            value = Cfg[nowlv].accumulate
            limitLv = Cfg[nowlv].levellimit
        end
    end
    if Actor.checkActorLevel(pActor, limitLv) ~= true then

        Actor.sendTipmsgWithParams(pActor, tmNeedLv, tstUI, limitLv)
        return
    end
    -- print("value.."..value)
    value = value - (sorce or 0);
    -- print("now value.."..value)
    if value < 0 then
        value = 0;
    end

    if value == 0 then
        return;
    end

    local SetCfg = ActivitySetConfig[atvId];
    if SetCfg == nil then
        return 
    end

    local setCfg = SetCfg[(globalData.nNumber or 1)];
    if setCfg == nil then
        return 
    end

    local Cost = {}
    local cost = {}
    cost.type = 4
    cost.id = 4
    cost.count = value/setCfg.proportion
    table.insert(Cost, cost);
    if CommonFunc.Consumes.CheckActorSources(pActor, Cost, tstUI) ~= true then
        return
    end
    
    if Cost and CommonFunc.Consumes.Remove(pActor, Cost, GameLog.Log_Activity14, "购买战令等级|"..atvId) ~= true then
        return
    end

    -- sorce = (sorce or 0 ) + value;
    Actor.giveAward(pActor, setCfg.timer,setCfg.timer,value)
    -- Actor.sendTipmsgWithId(pActor, tmMailGetItemSuccess, tstUI)
    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)

     -- 记录日志
     Actor.SendActivityLog(pActor,atvId,ActivityType,2)
end


--激活
function activeOrderWar(pActor, atvId , nType)
    -- print("nType.."..nType)
    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    if globalData == nil then
        return
    end

    -- local id = Actor.getIntProperty(pActor, PROP_ENTITY_ID)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:数据异常,请重新登录|", tstUI)
        return;
    end

    local SetCfg = ActivitySetConfig[atvId];
    if SetCfg == nil then
        return 
    end

    local Cfg = SetCfg[(globalData.nNumber or 1)];
    if Cfg == nil then
        return 
    end

    if actorData == nil then
        actorData = {}
    end
    local data = actorData[nType]
    if data then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无法重复购买|", tstUI)
        return
    end

    if Cfg.mergelimit then
        if Actor.checkCommonLimit(pActor,
                                (Cfg.mergelimit.level or 0), 
                                (Cfg.mergelimit.zsLevel or 0),
                                (Cfg.mergelimit.vip or 0), 
                                (Cfg.mergelimit.office or 0) ) == false then
            Actor.sendTipmsgWithId(pActor, Cfg.vipnotips, tstUI)
            return;
        end
    end

    local cost = {};
    if (nType == AtvType.Type2 or nType == AtvType.Type3 )  then --黄金凭证价格
        if actorData[AtvType.Type2] == nil then
            if Cfg.rewardBPrice then
                local price = {};
                price.type = Cfg.rewardBPrice.type
                price.id = Cfg.rewardBPrice.id
                price.count = Cfg.rewardBPrice.count
                table.insert(cost, price)
            end
           
        end
    end
    if nType == AtvType.Type3 and Cfg.rewardCPrice then -- 至尊凭证价格 包含黄金凭证
        
        if CommonFunc.Awards.CheckBagIsEnough(pActor,Cfg.VIPbagremain,Cfg.VIPtips,tstUI) ~= true then
            return
        end

        if #cost == 0 then
            table.insert(cost, Cfg.rewardCPrice)
        else
            for _, r in pairs(cost) do
                if r.type == Cfg.rewardCPrice.type and r.id == Cfg.rewardCPrice.id then

                    r.count = r.count + Cfg.rewardCPrice.count;
                end
            end
        end
    end
    --检查消耗是否满足条件
    if cost then
        if CommonFunc.Consumes.CheckActorSources(pActor, cost ,tstUI) ~= true then
            return
        end
    end
    --扣除消耗
    if cost then
        if CommonFunc.Consumes.Remove(pActor, cost, GameLog.Log_Activity14, "激活凭证|"..atvId) ~= true then
            return
        end
    end

    if nType == AtvType.Type3 then
        if actorData[AtvType.Type2] == nil then
            actorData[AtvType.Type2] = {}
        end
        actorData[AtvType.Type3] = {}
        Actor.giveAward(pActor, Cfg.timer,Cfg.timer, Cfg.VIPintegral)
        SendAward(pActor,atvId, (globalData.nNumber or 1));
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:至尊凭证激活成功|", tstUI)
    else
        actorData[AtvType.Type2] = {}
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:黄金凭证激活成功|", tstUI)
    end

    local name = Actor.getName(pActor);
    System.broadTipmsgWithParams(tmAtv14Tips, tstKillDrop, name)
    System.broadTipmsgWithParams(tmAtv14Tips, tstChatSystem, name)
   
    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
     -- 记录日志
     Actor.SendActivityLog(pActor,atvId,ActivityType,2)
end


function SendAward(pActor,atvId, nNumber)

    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:数据异常,请重新登录|", tstUI)
        return;
    end
    local AtvCfg = Activity14Config[atvId];
    if AtvCfg == nil then
        return
    end
    local Cfg = AtvCfg[(nNumber or 1)];
    if Cfg == nil then
        return 
    end

    for _, cfg in pairs(Cfg) do

        if cfg.rewardC then
            CommonFunc.GiveCommonAward(pActor, cfg.rewardC, GameLog.Log_Activity14,  "至尊凭证激活奖励|"..atvId)
        end
    end
end


--
function getAwardIndexCfg(atvId, nNumber, indexId)
    if ActivityConfig then
        local Cfg = ActivityConfig[atvId][nNumber];
        if Cfg then
            for _, cfg in pairs(Cfg) do
                if cfg.tokenlevel == indexId then
                    return cfg;
                end
            end
        end
    end
    return nil;
end


function getNowLv(atvId, nNumber, sorce)
    local lv = 0;
    if ActivityConfig then
        local Cfg = ActivityConfig[atvId][nNumber];
        if Cfg then
            for _, cfg in pairs(Cfg) do
                if sorce >= cfg.accumulate and cfg.tokenlevel > lv then
                    lv = cfg.tokenlevel;
                end
            end
        end
    end
    return lv;
end
--------------------------我是分界线----------------------------
-- 初始化玩家数据
function OnInit(atvId, pActor)
    --
    local AtvOpentime = System.getRunningActivityStartTimeRelToday(atvId);
    local id = Actor.getStaticCount(pActor, 623);
    if id ~= atvId then
        print("[GActivity14 新活动]  战令活动"..Actor.getName(pActor).." 初始化 id："..atvId)
        Actor.setStaticCount(pActor,622, 0);--积分清空
        ActivityDispatcher.ClearActorData(pActor,atvId);
        Actor.setStaticCount(pActor,623, atvId);
        local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
        actorData.openTime = AtvOpentime;
    end
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if AtvOpentime ~= (actorData.openTime or 0) then
        print("[GActivity14 重复活动]  战令活动"..Actor.getName(pActor).." 初始化 id："..atvId)
        Actor.setStaticCount(pActor,622, 0);--积分清空
        ActivityDispatcher.ClearActorData(pActor,atvId);
        Actor.setStaticCount(pActor,623, atvId);
        local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
        actorData.openTime = AtvOpentime;
    end
end

--活动开始
function OnStart(atvId)
    -- print("[activitytype 14] 战令活动---onstart  atvId:"..atvId)

    ActivityDispatcher.ClearGlobalData(atvId)
    local globalData = ActivityDispatcher.GetGlobalData(atvId);
    if globalData == nil then
        globalData = {}
    end
    if globalData.openTimes == nil then
        local currentId = System.getCurrMiniTime();
        globalData.openTimes = currentId
    end
    --初始化
    local openDay = System.getDaysSinceOpenServer();
    local SetCfg = ActivitySetConfig[atvId];
    if SetCfg == nil then
        return 
    end

    for _, cfg in pairs(SetCfg) do
        if openDay >= cfg.openday then
            globalData.nNumber = cfg.number;
        end
    end
    print("[activitytype 14] 战令活动---onstart  atvId: "..(globalData.nNumber or 0))
    -- ActivityDispatcher.ClearActorData(pActor, atvId)
    
end
--商城
function SendShopInfo(pActor, atvId)
    local nMaxLen = 0
    if ShopCfg then
        nMaxLen = #ShopCfg;
    end
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId);
    if actorData.daily == nil then
        actorData.daily = {}
    end
    if actorData.ever == nil then
        actorData.ever = {}
    end
    local npack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sZLShopInfo)
    if npack and ShopCfg then
        local value = Actor.getStaticCount(pActor, 624);--战令积分
        DataPack.writeInt(npack, value);
        DataPack.writeWord(npack, nMaxLen);

        for _, cfg in pairs(ShopCfg) do
            DataPack.writeWord(npack, cfg.shopid)
            local nLeftTime = -1;
            if cfg.limittimes then
                if cfg.daily then
                    nLeftTime = cfg.limittimes - (actorData.daily[cfg.shopid] or 0)
                else
                    nLeftTime = cfg.limittimes - (actorData.ever[cfg.shopid] or 0)
                end
            end
        end
	    DataPack.writeShort(npack, nLeftTime)
        DataPack.flush(npack)
    end
end

--战令币更新
function SendZLMoney(pActor)
    local npack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sZLBuyShop)
    if npack then
        local value = Actor.getStaticCount(pActor, 624);--战令积分
        DataPack.writeInt(npack, (value or 0))
        DataPack.flush(npack)
    end
end
function SendZLShopChange(pActor, index, times)
    local npack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sZLShopChange)
    if npack then
        DataPack.writeWord(npack, index)
        DataPack.writeShort(npack, times)
        DataPack.flush(npack)
    end
end
--购买
function BuyShop(pActor, atvId, index, Count)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId);
    if ShopCfg[index] == nil then
        return;
    end

    if ShopCfg[index].showlimit then
        if Actor.checkCommonLimit(pActor,
                                (ShopCfg[index].showlimit.level or 0), 
                                (ShopCfg[index].showlimit.zsLevel or 0),
                                (ShopCfg[index].showlimit.vip or 0), 
                                (ShopCfg[index].showlimit.office or 0) ) == false then
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:条件不满足|", tstUI)
            return;
        end
    end
    if ShopCfg[index].limittimes then
        local nBuyTimes = 0;
        if cfg.daily then
            nBuyTimes =  (actorData.daily[cfg.shopid] or 0)
        else
            nBuyTimes = (actorData.ever[cfg.shopid] or 0)
        end

        if (nBuyTimes + Count) > ShopCfg[index].limittimes then
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:次数已达上限|", tstUI)
            return;
        end
    end
    if CommonFunc.Consumes.CheckActorSources(pActor, ShopCfg[index].price,tstUI) ~= true then
        return;
    end

    if CommonFunc.Awards.CheckBagIsEnough(pActor,8,tmLeftBagNumNotEnough,tstUI) ~= true then
        return
    end
    CommonFunc.Consumes.Remove(pActor, ShopCfg[index].price, GameLog.Log_Activity14, "战令商店")
    CommonFunc.GiveCommonAward(pActor, ShopCfg[index].shop, GameLog.Log_Activity14,  "战令商店")
    if ShopCfg[index].limittimes then
        local nLeftTime = ShopCfg[index].limittimes;
        if cfg.daily then
            actorData.daily[ShopCfg[index].shopid] = (actorData.daily[ShopCfg[index].shopid] or 0) + Count
            nLeftTime = nLeftTime - (actorData.daily[ShopCfg[index].shopid] or 0)
        else
            actorData.ever[ShopCfg[index].shopid] = (actorData.ever[ShopCfg[index].shopid] or 0) + Count
            nLeftTime = nLeftTime - (actorData.ever[ShopCfg[index].shopid] or 0)
        end
        SendZLShopChange(pActor,index, nLeftTime)
    end
    SendZLMoney(pActor);
end
-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cGetZLAward then --请求领取奖励
        local nType = DataPack.readByte(inPack)
        local indexId = DataPack.readByte(inPack)
        reqGetAward(pActor, atvId , nType, indexId)
    elseif operaCode == ActivityOperate.cActiveOrderWar then --激活
        local indexId = DataPack.readByte(inPack)
        activeOrderWar(pActor, atvId , indexId)
    elseif operaCode == ActivityOperate.cBuyOrderWarLv then --购买等级
        local lv = DataPack.readByte(inPack)
        buyOrderWarLv(pActor, atvId , lv)
    elseif operaCode == ActivityOperate.cGetAllAward then --
        reqGetAllAward(pActor, atvId)
    elseif operaCode == ActivityOperate.cZLShopInfo then --战令商店信息
        SendShopInfo(pActor, atvId)
    elseif operaCode == ActivityOperate.cBuyZLShop then --购买战令商品
        local index = DataPack.readWord(inPack);
        local count = DataPack.readWord(inPack);
        BuyShop(pActor, atvId,index,count)
    end
end


-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    -- print("[PActivity14 战令活动 id:.."..atvId.."请求数据]")

    if outPack == nil then
        return
    end
    local globalData = ActivityDispatcher.GetGlobalData(atvId);
    if globalData == nil then
        globalData = {}
    end

    local AtvCfg = ActivityConfig[atvId]
    if AtvCfg == nil then
        return
    end

    Cfg = AtvCfg[(globalData.nNumber or 1)]
    
    local len = 0;

    if Cfg then
        len = #Cfg;
    end

    local SetCfg = ActivitySetConfig[atvId]
    if SetCfg == nil then
        return 
    end

    local setCfg = SetCfg[(globalData.nNumber or 1)];
    if setCfg == nil then
        return 
    end

    local id = Actor.getStaticCount(pActor, 623);
    -- print("id.."..id.."..actid.."..atvId)
    if id ~= atvId then
        Actor.setStaticCount(pActor,622, 0);--积分清空
        -- Actor.setStaticCount(pActor,624, 0);--战令币清空
        ActivityDispatcher.ClearActorData(pActor,atvId);
        Actor.setStaticCount(pActor,623, atvId);
    end

    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)

    if actorData == nil then
        actorData = {}
        --默认初始1
        actorData[AtvType.Type1] = {}
    end
    if actorData[AtvType.Type1] == nil then
        actorData[AtvType.Type1] = {}
    end
    
    -- print("nNumber.."..(globalData.nNumber or 1))
    DataPack.writeInt(outPack, atvId)   
    DataPack.writeByte(outPack, (globalData.nNumber or 1))   
    local sorce = Actor.getConsume(pActor, setCfg.timer,setCfg.timer)
    DataPack.writeInt(outPack, (sorce or 0))  
    -- print("sorce.."..(sorce or 1))
    local nowlv = getNowLv(atvId, (globalData.nNumber or 1), (sorce or 0))
    DataPack.writeInt(outPack, (nowlv or 0))  
    local dataType1 = actorData[AtvType.Type1]
    local dataType2 = actorData[AtvType.Type2]
    local stateType = 0;
    if dataType2 then stateType = 1 end;
    DataPack.writeByte(outPack, (stateType or 0)) --黄金
    stateType = 0;
    if actorData[AtvType.Type3] then stateType = 1 end;
    DataPack.writeByte(outPack, (stateType or 0)) --至尊
    --长度
    DataPack.writeByte(outPack, (len or 0))  
    if Cfg then

        for _, cfg in pairs(Cfg) do
            DataPack.writeByte(outPack, cfg.tokenlevel)
            local state = 0;
            if sorce >= cfg.accumulate then
                state = 2
            end

            if dataType1 and cfg.rewardA then
                if dataType1[cfg.tokenlevel] then state = 1 end
            else state = 0
            end
            DataPack.writeByte(outPack, state)
            if sorce >= cfg.accumulate then state = 2 end

            if dataType2 and cfg.rewardB then
                if dataType2[cfg.tokenlevel] then state = 1 end
            else state = 0
            end
            -- print("state.."..state)
            DataPack.writeByte(outPack, state)
        end
    end
end

-- 活动结束
function OnEnd(atvId)
    print("[PActivity 14] 活动id.."..atvId.."..结束")

    -- dealMail(atvId);
    ActivityDispatcher.ClearGlobalData(atvId)
end

--活动红点
function OnGetRedPoint(atvId, pActor)
    local ret = 0

    local globalData = ActivityDispatcher.GetGlobalData(atvId);
    if globalData == nil then
        globalData = {}
    end


    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)

    if actorData == nil then
        actorData = {}
        --默认初始1
        actorData[AtvType.Type1] = {}
    end

    local SetCfg = ActivitySetConfig[atvId];
    if SetCfg == nil then
        return 
    end

    local setCfg = SetCfg[(globalData.nNumber or 1)];
    if setCfg == nil then
        return 
    end
    local id = Actor.getStaticCount(pActor, 623);
    -- print("id.."..id.."..actid.."..atvId)
    if id ~= atvId then
        Actor.setStaticCount(pActor,622, 0);
        -- Actor.setStaticCount(pActor,624, 0);--战令币清空
        ActivityDispatcher.ClearActorData(pActor,atvId);
        Actor.setStaticCount(pActor,623, atvId);
    end

    local sorce = Actor.getConsume(pActor, setCfg.timer,setCfg.timer)

    local AtvCfg = ActivityConfig[atvId]
    if AtvCfg == nil then
        return
    end
    Cfg = AtvCfg[(globalData.nNumber or 1)]
    if Cfg == nil then
        return
    end
    for _, cfg in pairs(Cfg) do
        if sorce >= cfg.accumulate then
            if actorData[AtvType.Type1] and cfg.rewardA then
                if actorData[AtvType.Type1][cfg.tokenlevel] == nil then
                    ret = 1;
                    break;
                end
            end
            if actorData[AtvType.Type2] and cfg.rewardB then
                if actorData[AtvType.Type2][cfg.tokenlevel] == nil then
                    ret = 1;
                    break;
                end
            end
        end
    end 
    return ret
end



---更新活动数据
function OnUpdateActivity(pActor, atvId)
 
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)

    if actorData == nil then
        actorData = {}
        actorData[AtvType.Type1] ={}
    end
    Actor.sendActivityData(pActor, atvId)
    SendZLMoney(pActor);
 end
 

ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType14.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType14.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType14.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType14.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType14.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType14.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdateActivity, ActivityType, OnUpdateActivity, "ActivityType14.lua")