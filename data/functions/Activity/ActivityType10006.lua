module("ActivityType10006", package.seeall)

--[[
    个人活动
    登录基金

    个人数据：ActorData[AtvId]
    {
        AwardBitMap = 1  当前档奖励位图   二进制的从右到左为从1到32天，1表示已领取
        LoginInDays = 5  登录天数

        LastLoginIsNo_OfOpenday = 5, 记录上次签到是开服的第几号
        PURCHASEFLAG = 0  购买标志，0 未购买，1 已购买
    }

    全局缓存：Cache[AtvId]
    {   
        
    }

    全局数据：GlobalData[AtvId]
    {
    
    }
]]--

--活动类型
ActivityType = 10006
--对应的活动配置
ActivityConfig = Activity10006Config
if ActivityConfig == nil then
    assert(false)
end

--[[




]]


--玩家请求购买基金
function reqPurchaseJiJing(pActor, atvId )
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    local Cfg = ActivityConfig[atvId][1]

    if Cfg.consume ~=nil then 

        if Cfg.buyDayLmt >= System.getDaysSinceOpenServer() then 
            --检查消耗是否满足条件
            local consumes = Cfg.consume
            if CommonFunc.Consumes.CheckActorSources(pActor, consumes,tstUI) ~= true then
                --Actor.sendTipmsgWithId(pActor, tmNomoreYubao, tstUI)
                return
            end

            --扣除消耗
            if consumes and CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity10006, "登录基金购买 | " .. atvId) == true then
                actorData.PURCHASEFLAG = 1
            end
        end 
    
    end
--print("--------------------purchaseFlag : "..actorData.PURCHASEFLAG)
    --触发当日登录
    OnLoginGame(atvId,pActor)


     -- 记录日志
     Actor.SendActivityLog(pActor,atvId,ActivityType,1)

    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
end 



--玩家请求领取奖励
function reqGetGift(pActor, atvId , indexId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    
    local Cfg = ActivityConfig[atvId]

    if Cfg ~=nil then 
        

       --检查indexId参数是否合法
       for i= 1 , #Cfg do 
            if (Cfg[i].needDays ==indexId) then 
                break 
            end 
            if i == #Cfg and Cfg[i].needDays ~=indexId  then 
                --print("请求index参数错误")
                return  --没有找到该天数对应的奖励
            end 
       end 
        
        --提示已领取无法多次领取
        if System.getIntBit(actorData.AwardBitMap,indexId)  == 1  then 
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:您已领取该奖励|", tstUI)
            return 
        end 

        --登录天数不够
        if actorData.LoginInDays <indexId then 
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:登录天数不够|", tstUI)    
            return 
        end 

        --检查格子够不够
        if CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmGiftNoBagNum,tstUI) ~= true then
            return
        end


        for i= 1 , #Cfg do 
            if (Cfg[i].needDays ==indexId) then 
                if Cfg[i].GiftTable == nil then return end 
                local award = Cfg[i].GiftTable
                --CommonFunc.GiveCommonAward(pActor, award, GameLog.Log_Activity10006,  "登录基金领取 | " .. atvId)
                CommonFunc.Awards.Give(pActor, award, GameLog.Log_Activity10006,  "登录基金领取 | " .. atvId)
                
--print("------------bitmap: "..actorData.AwardBitMap.."indexId: "..indexId)
                actorData.AwardBitMap = System.setIntBit(actorData.AwardBitMap, indexId, 1) --将indexId位置置为1
--print("------------bitmap: "..actorData.AwardBitMap)
                Actor.sendTipmsgWithId(pActor, tmMailGetItemSuccess, tstUI)
                break 
            end  
       end 
    end 

    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
end 



--------------------------我是分界线----------------------------

-- 初始化玩家数据
function OnLoad(atvId, pActor)
    --print("[GActivity 10006]  登录基金"..Actor.getName(pActor).." OnLoad id："..atvId)    
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
    if actorData.PURCHASEFLAG == nil then
        actorData.PURCHASEFLAG = 0
    end
    local Cfg = ActivityConfig[atvId][1]
    if Cfg.buyDayLmt < System.getDaysSinceOpenServer() and actorData.PURCHASEFLAG == 0 then 
--print("------------------------------------before close one activity 100006")
            Actor.closeOneActivity(pActor,atvId)
    end            
end


--活动开始
function OnStart(atvId, pActor)
    ActivityDispatcher.ClearActorData(pActor, atvId)
    --print("[activitytype 10006] 登录基金---onstart  atvId:"..atvId)

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
    if actorData.PURCHASEFLAG == nil then
        actorData.PURCHASEFLAG = 0
    end
    local Cfg = ActivityConfig[atvId][1]
    if Cfg.buyDayLmt < System.getDaysSinceOpenServer() and actorData.PURCHASEFLAG == 0 then 
--print("------------------------------------before close one activity 100006")
            Actor.closeOneActivity(pActor,atvId)
    end 
end


-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
--print("---------operator : "..operaCode)
    if   operaCode == ActivityOperate.cReqPurchaseJiJin   then --请求购买基金 
        reqPurchaseJiJing(pActor, atvId )
    elseif operaCode == ActivityOperate.cReqGetJiJinAward then --请求领取基金奖励
        local indexId = DataPack.readByte(inPack)
--print("---------operator : "..operaCode.."-------indexId : "..indexId)
        reqGetGift(pActor, atvId , indexId)
    end
end


-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    local Cfg = ActivityConfig[atvId][1]

    if actorData.AwardBitMap == nil then
        actorData.AwardBitMap = 0
    end  
    if actorData.LoginInDays == nil then
        actorData.LoginInDays = 0
    end  
    if actorData.LastLoginIsNo_OfOpenday == nil then
        actorData.LastLoginIsNo_OfOpenday = 0
    end  
    if actorData.PURCHASEFLAG == nil then
        actorData.PURCHASEFLAG = 0
    end  

    local openday = System.getDaysSinceOpenServer()

    local EndMiniTime = System.getToday() + (Cfg.buyDayLmt-openday +1)*86400

    local LeftTime = EndMiniTime - System.getCurrMiniTime() 
    if LeftTime <= 0 then LeftTime = 0 end 

--print("-----------------------actorData.AwardBitMap: "..actorData.AwardBitMap.."-----------------------------")
    if  outPack then  
        DataPack.writeByte(outPack, actorData.PURCHASEFLAG)  
        DataPack.writeUInt(outPack, actorData.AwardBitMap) 
        DataPack.writeByte(outPack, actorData.LoginInDays) 
        DataPack.writeUInt(outPack, LeftTime) 
    end
end

function OnLoginGame(atvId,pActor)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    local openday = System.getDaysSinceOpenServer()

    if actorData.PURCHASEFLAG == 1 then 
        if actorData.LastLoginIsNo_OfOpenday ~= openday then
            actorData.LoginInDays = actorData.LoginInDays +1
            actorData.LastLoginIsNo_OfOpenday = openday 
        end 
    end 
end 



-- 活动结束
function OnEnd(atvId, pActor)
--print(Actor.getName(pActor).."------------------------activityType10006.OnEnd------")
     
    ActivityDispatcher.ClearActorData(pActor, atvId)
    --local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    --actorData.AwardBitMap = nil               --当前档奖励位图   二进制的从右到左为从1到32天，1表示已领取
    --actorData.LoginInDays = nil               --登录天数
    --actorData.LastLoginIsNo_OfOpenday = nil     --记录上次签到是开服的第几号
    --actorData.PURCHASEFLAG = nil                --购买标志
    

end

--活动红点数据
function OnGetRedPoint(atvId, pActor)
    local ret = 0
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    local Cfg = ActivityConfig[atvId]
    if actorData.AwardBitMap == nil then
        actorData.AwardBitMap = 0
    end  
    if actorData.LoginInDays == nil then
        actorData.LoginInDays = 0
    end  
    
    if Cfg ~=nil then 
        for i = 1 , #Cfg do 
--print("----------------------actorData.LoginDays: "..actorData.LoginInDays)
--print("----------------------actorData.AwardBitMap: "..actorData.AwardBitMap)
            if (actorData.LoginInDays >= i) and (System.getIntBit(actorData.AwardBitMap,Cfg[i].needDays)  == 0)  then 
                ret = System.setIntBit(ret, i, 1) --对应位为1表示该奖励可领取
            end 
        end 
    end 
    return ret
end
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType10006.lua")


-- 活动帧更新
function OnUpdate(atvId, curTime)
--print("------------------10006-------------------curTime: "..curTime) 
--print("------------------10006-------------------today LinchenTime: "..System.getToday()) 

end 
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType10006.lua")


--ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType10006.lua")
ActivityDispatcher.Reg(ActivityEvent.OnLoginGame, ActivityType, OnLoginGame, "ActivityType10006.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType10006.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType10006.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType10006.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType10006.lua")

-- 跨天
function OnNewDayArrive(pActor,ndiffday)
    --print("[ActivityType10006 ] "..Actor.getName(pActor).." 跨"..ndiffday.."天")
    
    local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
    if runAtvIdList == nil then 
        return 
    end
    if runAtvIdList then
        for i,atvId in ipairs(runAtvIdList) do
            local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
            if actorData.PURCHASEFLAG == nil then actorData.PURCHASEFLAG = 0 end 

            local Cfg = ActivityConfig[atvId][1]
            if Cfg.buyDayLmt < System.getDaysSinceOpenServer() and actorData.PURCHASEFLAG == 0 then 
                Actor.closeOneActivity(pActor,atvId)
            end 

            OnLoginGame(atvId,pActor)
            -- 发送一个活动数据
            Actor.sendActivityData(pActor, atvId)
        end
        
    end
    
    
end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10006.lua")

