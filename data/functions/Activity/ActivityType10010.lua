module("ActivityType10010", package.seeall)
--[[
    个人活动————开服特定寻宝
    抽奖活动！
    
    个人数据：ActorData[AtvId]
    {
        count,      已抽奖次数

    }
]]--

--活动类型
ActivityType = 10010
--对应的活动配置
ActivityConfig = Activity10010Config
if ActivityConfig == nil then
    assert(false)
end

--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------
--请求抽奖
function reqXunBao(pActor, atvId, Conf)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)

    local openday = System.getDaysSinceOpenServer()
    local Config = Conf[openday]
    --消耗检查
    -- local consumes = Config.DrawPrice
    -- if consumes then
    --     if CommonFunc.Consumes.CheckActorSources(pActor, consumes,tstUI) ~= true then
    --         --Actor.sendTipmsgWithId(pActor, tmNomoreYubao, tstUI)
    --         return
    --     end
    -- end
    if not Config then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:数据有误|", tstUI)
        return
    end

    --第N次免费抽奖
    local isFree = false
    local nTimes = 0
    if data.count == nil then
        nTimes = 1
    else
        nTimes = data.count + 1
    end
    for i, num in pairs(Config.freeNum) do
        if nTimes == num then
            isFree = true
            break
        end
    end

    local consumes = Config.FirstCost
    if not isFree then
        if Config.FirstCost then
            if CommonFunc.Consumes.CheckActorSources(pActor, Config.FirstCost) ~= true then
                consumes = nil
            end
        end
        if consumes == nil then
            if CommonFunc.Consumes.CheckActorSources(pActor, Config.DrawPrice,tstUI) ~= true then
                return
            end
            consumes = Config.DrawPrice
        end
    end

    --次数检查
    if data.count == nil then
        data.count = 0 
    else 
        if data.count >= Config.Maxcount then
            Actor.sendTipmsgWithId(pActor, tmNoTimes, tstUI)--次数不足
            return
        end
    end

    --背包检查，需要1格
    if CommonFunc.Awards.CheckBagIsEnough(pActor,12) ~= true then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:背包不足，装备、材料包裹必须剩余1格|", tstUI)
        return
    end

    --local awards = ActivityConfig[atvId].Persongift
    local groupID = Config.NormalDropId
    for i , specialId in pairs(Config.SpecialCount) do
        if data.count == (specialId-1) then 
            groupID = Config.SpecialDropId
        end 
    end 
--print("------------------11111111111111111111:groutID :"..groupID)
    --执行掉落组抽奖
    local strName = Actor.getName(pActor)
    local RetTabel = Actor.ChouJiangByGroupId(pActor, groupID ,GameLog.Log_Activity10010,"抽奖活动| "..atvId )
--print("retTabel Type: "..type(RetTabel)..#RetTabel)
    if RetTabel then 
        for _, wupin in pairs(RetTabel) do
            if wupin ~=nil then 
                if Config.tips and Config.tips[wupin.Id] then         
                    local strTips = string.format(Config.tips[wupin.Id].tips,strName)
                    System.broadcastTipmsgLimitLev(strTips, tstKillDrop)
                    strTips = string.format(Config.tips[wupin.Id].tips_,strName)
                    System.broadcastTipmsgLimitLev(strTips, tstChatSystem)
                end
            end
        end
        --协议发送抽奖结果
        local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendChouJiangResult)
        if  outPack then
            
            DataPack.writeByte(outPack, #RetTabel)
            for _, wupin in pairs(RetTabel) do
                if wupin ~=nil then 
                    DataPack.writeUInt(outPack, wupin.Type)
                    DataPack.writeUInt(outPack, wupin.Id)
                    DataPack.writeUInt(outPack, wupin.Count)
                end 
            end
            DataPack.flush(outPack)
        end
    else 
--print("------------------11111111111111111111")
    end   

    

    -- 扣取次数
    data.count = data.count + 1

    -- 扣取消耗
    if consumes and not isFree then
        CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity10010, "抽奖活动 | " .. atvId)
    end

     -- 记录日志
     Actor.SendActivityLog(pActor,atvId,ActivityType,1)
     
    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
 
end



--------------------------------------------------------------------
-- 活动 回调注册
--------------------------------------------------------------------

-- 活动开始
function OnStart(atvId, pActor)
    --初始化活动个人数据
    ActivityDispatcher.ClearActorData(pActor, atvId)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    if data.count ==nil then data.count = 0 end 
end

-- 活动结束
function OnEnd(atvId, pActor)
    ActivityDispatcher.ClearActorData(pActor, atvId)
end

-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    if data.count ==nil then data.count = 0 end 
    
    DataPack.writeWord(outPack, (data.count or 0))    
    

end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- id对应配置
    local Conf = ActivityConfig[atvId]
    if Conf == nil then
        --print("[PActivity 10010] "..Actor.getName(pActor).." 活动配置中找不到活动id："..atvId)
    end
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cReqXunBao then     -- 请求寻宝抽奖
        reqXunBao(pActor,atvId,Conf)
    end
end



ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType10010.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType10010.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType10010.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType10010.lua")

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 跨天，次数清零
function OnNewDayArrive(pActor,ndiffday)
    --print("[PActivity 10010] "..Actor.getName(pActor).." 跨"..ndiffday.."天")
    local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
    if runAtvIdList == nil then 
        return 
    end
    for i,atvId in ipairs(runAtvIdList) do
        --print("[PActivity 10010] "..Actor.getName(pActor).." 跨天活动次数归零,atvId="..atvId)
        local data = ActivityDispatcher.GetActorData(pActor,atvId)
        data.count = 0
        -- 发送一个活动数据
        Actor.sendActivityData(pActor, atvId)
        
    end
end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10010.lua")
