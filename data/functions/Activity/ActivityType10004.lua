module("ActivityType10004", package.seeall)

--[[
    个人活动
   七天登录

    个人数据：ActorData[AtvId]
    {
        AwardBitMap = 1  当前档奖励位图   二进制的从右到左为从1到32天，1表示已领取
        LoginInDays = 5  登录天数

        LastLoginIsNo_OfOpenday = 5, 记录上次签到是开服的第几号
    }

    全局缓存：Cache[AtvId]
    {   
        
    }

    全局数据：GlobalData[AtvId]
    {
    
    }
]]--

--活动类型
ActivityType = 10004
--对应的活动配置
ActivityConfig = Activity10004Config
if ActivityConfig == nil then
    assert(false)
end

--[[


]]



--玩家请求领取礼包
function reqGetGiftBox(pActor, atvId , indexId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if ActivityConfig[atvId][indexId] == nil then 
        --print("index 参数错误") 
        return 
    end  
    local Cfg = ActivityConfig[atvId][indexId]
    local awards = Cfg.GiftTable 

    

    --提示已领取无法多次领取
    if System.getIntBit(actorData.AwardBitMap,indexId)  == 1  then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:您已领取该奖励|", tstUI)
        return 
    end 
    --登录天数不足
    if actorData.LoginInDays <indexId then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:登录天数不足|", tstUI)    
        return 
    end 
    --检查格子够不够
    if CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) ~= true then
        return
    end

    --CommonFunc.GiveCommonAward(pActor, awards, GameLog.Log_Activity10004,  "七天登录领取礼包|"..atvId)
    CommonFunc.Awards.Give(pActor, awards, GameLog.Log_Activity10004,  "七天登录领取礼包|"..atvId)

--print("------------bitmap: "..actorData.AwardBitMap.."indexId: "..indexId)
    actorData.AwardBitMap = System.setIntBit(actorData.AwardBitMap, indexId, 1) --将indexId位置置为1
--print("------------bitmap: "..actorData.AwardBitMap)
    Actor.sendTipmsgWithId(pActor, tmMailGetItemSuccess, tstUI)
        
    -- 记录日志
    Actor.SendActivityLog(pActor,atvId,ActivityType,1)
    

    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
end 



--------------------------我是分界线----------------------------

-- 初始化玩家数据
function OnInit(atvId, pActor)
    --ActivityDispatcher.ClearActorData(pActor, atvId)
    --print("[GActivity 10004]  七天登录"..Actor.getName(pActor).." 初始化 id："..atvId)
    -- local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    -- if actorData.AwardBitMap == nil then
    --     actorData.AwardBitMap = 0
    -- end  
    -- if actorData.LoginInDays == nil then
    --     actorData.LoginInDays = 0
    -- end  
    -- if actorData.LastLoginIsNo_OfOpenday == nil then
    --     actorData.LastLoginIsNo_OfOpenday = 0
    -- end                       
end

--活动开始
function OnStart(atvId, pActor)
    ActivityDispatcher.ClearActorData(pActor, atvId)
    --print("[activitytype 10004] 七天登录活动---onstart  atvId:"..atvId)

    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData.AwardBitMap == nil then
        actorData.AwardBitMap = 0
    end  
    if actorData.LoginInDays == nil then
        actorData.LoginInDays = 0
    end  
    if actorData.LastLoginIsNo_OfOpenday == nil then
        actorData.LastLoginIsNo_OfOpenday = 0
    end  
end


-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cReqPurchaseGiftbag then --请求领取七天奖励
        local indexId = DataPack.readByte(inPack)
--print("---------operator : "..operaCode.."-------indexId : "..indexId)
        reqGetGiftBox(pActor, atvId , indexId)
    end
end


-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)

    if actorData.AwardBitMap == nil then
        actorData.AwardBitMap = 0
    end  
    if actorData.LoginInDays == nil then
        actorData.LoginInDays = 0
    end  
    if actorData.LastLoginIsNo_OfOpenday == nil then
        actorData.LastLoginIsNo_OfOpenday = 0
    end  

     if  outPack then  
        DataPack.writeUInt(outPack, actorData.AwardBitMap) 
--print("atvId : 10004  awardBitMap: "..actorData.AwardBitMap)
        DataPack.writeByte(outPack, actorData.LoginInDays)  
--print("atvId : 10004  loginDays: "..actorData.LoginInDays)
     end
end

function OnLoginGame(atvId,pActor)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData.LoginInDays == nil then
        actorData.LoginInDays = 0
    end 
    if actorData.LastLoginIsNo_OfOpenday == nil then
        actorData.LastLoginIsNo_OfOpenday = 0
    end 
    if actorData.AwardBitMap == nil then
        actorData.AwardBitMap = 0
    end  
    local openday = System.getDaysSinceOpenServer()
--print("call func ___  onLoginGame()")
    if actorData.LastLoginIsNo_OfOpenday ~= openday then
        actorData.LoginInDays = actorData.LoginInDays +1
        actorData.LastLoginIsNo_OfOpenday = openday 
        -- 发送一个活动数据
        Actor.sendActivityData(pActor, atvId)
    end 

end 



-- 活动结束
function OnEnd(atvId, pActor)
     
    --local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    --actorData.AwardBitMap = nil               --当前档奖励位图   二进制的从右到左为从1到32天，1表示已领取
    --actorData.LoginInDays = nil               --登录天数
    --actorData.LastLoginIsNo_OfOpenday = nil     --记录上次签到是开服的第几号

    ActivityDispatcher.ClearActorData(pActor, atvId)
end


--活动红点数据
function OnGetRedPoint(atvId, pActor)
    local ret = 0
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    local Cfg = ActivityConfig[atvId]

    if actorData.LoginInDays == nil then
        actorData.LoginInDays = 0
    end 
    if actorData.AwardBitMap == nil then
        actorData.AwardBitMap = 0
    end 
    
    if Cfg ~=nil then 
        for i = 1 , #Cfg do 
--print("----------------------actorData.LoginDays: "..actorData.LoginInDays)
--print("----------------------actorData.AwardBitMap: "..actorData.AwardBitMap)
            if (actorData.LoginInDays >= i) and (System.getIntBit(actorData.AwardBitMap,i)  == 0)  then 
                ret = System.setIntBit(ret, i, 1) --对应位为1表示该奖励可领取
            end 
        end 
    end 
    return ret
end
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType10004.lua")


-- 活动帧更新
function OnUpdate(atvId, curTime)
--print("------------------10004-------------------curTime: "..curTime) 
--print("------------------10004-------------------today LinchenTime: "..System.getToday()) 
end 
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType10004.lua")


ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType10004.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType10004.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType10004.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType10004.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType10004.lua")
ActivityDispatcher.Reg(ActivityEvent.OnLoginGame, ActivityType, OnLoginGame, "ActivityType10004.lua")



------------------------------我是分割线------------------------

-- 跨天,
function OnNewDayArrive(pActor,ndiffday)
    --print("[ActivityType10004 ] "..Actor.getName(pActor).." 跨"..ndiffday.."天")
    local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
    if runAtvIdList == nil then 
        return 
    end
    if runAtvIdList then
        for i,atvId in ipairs(runAtvIdList) do
            OnLoginGame(atvId,pActor)
            -- 发送一个活动数据
            Actor.sendActivityData(pActor, atvId)
        end
        
    end
end
ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10004.lua")
