module("ActivityType10001", package.seeall)

--[[
    个人活动
   累计充值活动

    个人数据：ActorData[AtvId]
    {
        LeftgetgiftTimes[i] = 1  当前档奖励位领取标志位
    }

    全局缓存：Cache[AtvId]
    {   
        
    }

    全局数据：GlobalData[AtvId]
    {
    
    }
]]--

--活动类型
ActivityType = 10001
--对应的活动配置
ActivityConfig = Activity10001Config
if ActivityConfig == nil then
    assert(false)
end


--客户端请求角色剩余次数数据
function reqActorTimesData(pActor,atvId) 
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendActorDataTimes)
    local currentYuanBaoCount = Actor.getIntProperty(pActor,PROP_ACTOR_DRAW_YB_COUNT)
    
     if  outPack then
        DataPack.writeUInt(npack, currentYuanBaoCount)
         DataPack.writeByte(outPack, ActivityConfig[atvId].LevelNum) 
         for i = 1, ActivityConfig[atvId].LevelNum do
            DataPack.writeByte(outPack, i )
            DataPack.writeByte(outPack, actorData.LeftgetgiftTimes[i])
        end
         DataPack.flush(outPack)
     end

end 

--玩家请求奖励
function reqGetAward(pActor, atvId , indexId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    local currentYuanBaoCount = Actor.getIntProperty(pActor,PROP_ACTOR_DRAW_YB_COUNT)
    local awards = ActivityConfig[atvId].GiftTable[indexId].awards
    if ActivityConfig[atvId].GiftTable ~=nil then 
        --if indexId ~= ActivityConfig[atvId].GiftTable[indexId].level then return end 
        if nil == awards then return end 
        if currentYuanBaoCount == nil then return end 
        if actorData.LeftgetgiftTimes[indexId] ==nil then return end 
        -- if CommonFunc.Awards.CheckBagGridCount(pActor,awards) ~= true then
        --     Actor.sendTipmsgWithId(pActor, tmLeftBagNumNotEnough, tstUI)
        --     return
        -- end
        if CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmLeftBagNumNotEnough,tstUI) ~= true then
            return
        end

        local levelYuanbao = ActivityConfig[atvId].GiftTable[indexId].value
        if (levelYuanbao ~=nil )and (currentYuanBaoCount >=levelYuanbao) and (actorData.LeftgetgiftTimes[indexId] == 1 )  then 
            --CommonFunc.GiveCommonAward(pActor, awards, GameLog.Log_Activity10001,  "累计充值活动|"..atvId)
            CommonFunc.Awards.Give(pActor, awards, GameLog.Log_Activity10001, "累计充值活动|"..atvId)

            actorData.LeftgetgiftTimes[indexId] = 0
            Actor.sendTipmsgWithId(pActor, tmMailGetItemSuccess, tstUI)

            -- 记录日志
            Actor.SendActivityLog(pActor,atvId,ActivityType,2)
            
        end 
    end 

    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
    
end 




-----------------------------------------------我是分界线----------------------------------------------------------------------

-- 初始化玩家数据
function OnInit(atvId, pActor)
    --print("[GActivity 10001] 累计充值 "..Actor.getName(pActor).." 初始化 id："..atvId)                
end

--活动开始
function OnStart(atvId, pActor)
    --print("[activitytype10001] 累计充值---onstart  atvId:"..atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData.LeftgetgiftTimes == nil then
        actorData.LeftgetgiftTimes = {}
        for i = 1, ActivityConfig[atvId].LevelNum do
            actorData.LeftgetgiftTimes[i] = 1
        end
    end  
end


-- 通用操作
function OnOperator(atvId, pActor, inPack)

    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
--print("-------operatro:"..operaCode)
    if operaCode == ActivityOperate.cReqLeijichongzhiGift then --请求获取阶段奖励
        local indexId = DataPack.readByte(inPack)
--print("-------indexId:"..indexId)
        reqGetAward(pActor, atvId , indexId)
    end
end


-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    local currentYuanBaoCount = Actor.getIntProperty(pActor,PROP_ACTOR_DRAW_YB_COUNT)

    if actorData.LeftgetgiftTimes == nil then
        actorData.LeftgetgiftTimes = {}
        for i = 1, ActivityConfig[atvId].LevelNum do
            actorData.LeftgetgiftTimes[i] = 1
        end
    end 

    if  outPack then
        DataPack.writeUInt(outPack, currentYuanBaoCount)
         DataPack.writeByte(outPack, ActivityConfig[atvId].LevelNum) 
         for i = 1, ActivityConfig[atvId].LevelNum do
            DataPack.writeByte(outPack, i )
            DataPack.writeByte(outPack, actorData.LeftgetgiftTimes[i])
        end
    end
end



-- 活动结束
function OnEnd(atvId, pActor)
    --local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    --actorData.LeftgetgiftTimes = nil
    ActivityDispatcher.ClearActorData(pActor, atvId)
    
end


ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType10001.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType10001.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType10001.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType10001.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType10001.lua")
