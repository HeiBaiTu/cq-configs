module("ActivityType10005", package.seeall)

--[[
    个人活动
    每日签到

    个人数据：ActorData[AtvId]
    {
        MonthBitFlag   = 11110011, 本月签到地图  二进制的从右到左为从1到32天，1表示该日期已签到
        AwardBitMap = 10011  当前档奖励位图   二进制的从右到左为从1到32天，1表示已领取
        LoginInDays = 5  签到天数

        LastLoginMonthofYear  = 1 , 上次签到的月份
        LastLoginIsNo_OfMonth = 31, 上次签到是当月的第几号
        LastLogingLinchengSec = ..  上次签到当天凌晨的绝对时间
    }

    全局缓存：Cache[AtvId]
    {   
        
    }

    全局数据：GlobalData[AtvId]
    {
    }
]]--

--活动类型
ActivityType = 10005
--对应的活动配置
ActivityConfig = Activity10005Config
SignPrizeCfg= SignPrizeConfig
if ActivityConfig == nil then
    assert(false)
end


--local Lingchengsec = System.getToday()  --获取今日凌晨unsigned int 时间

--local dayNo_  = System.getDayOfMonth();  --今天是当月的第几号

--local MonthNo_ = System.getMonthOfNow(); --当前月份


function nextMonthClear(pActor,atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    local dayofMonth = System.getDayOfMonth() 
    --local LinChengSec = System.getToday() 
    local MonthofYear  = System.getMonthOfNow();

    if actorData.LastLoginMonthofYear ==nil then 
        actorData.LastLoginMonthofYear = 0 ; 
    end 
    
    --跨月了，数据清空
    if actorData.LastLoginMonthofYear ~= MonthofYear then 
        actorData.MonthBitFlag = 0
        actorData.AwardBitMap = 0
        actorData.LoginInDays = 0
        actorData.LastLoginIsNo_OfMonth = 0
        actorData.LastLogingLinchengSec = 0
        actorData.LastLoginMonthofYear  = 0
    end 
end  

--特权后台打卡不需要提示
function backStageQiandao(pActor, atvId)
    nextMonthClear(pActor,atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    local dayofMonth = System.getDayOfMonth() 
    local LinChengSec = System.getToday() 

    --今日已经打卡
    if (actorData.LastLogingLinchengSec == LinChengSec) and ( System.getIntBit(actorData.MonthBitFlag,dayofMonth)  == 1) then 
        --Actor.sendTipmsg(pActor, "您已打卡成功 无需多次打卡", tstUI)
        return 
    end 

    actorData.MonthBitFlag = System.setIntBit(actorData.MonthBitFlag, dayofMonth, 1) --将本月的第n天位置置为1
    actorData.LastLoginIsNo_OfMonth = dayofMonth 
    actorData.LastLogingLinchengSec = LinChengSec
    actorData.LoginInDays = actorData.LoginInDays +1   --可以在某个位置设置校验MonthBitFlag 是否有问题, 先不处理
    
    local MonthofYear  = System.getMonthOfNow();
    actorData.LastLoginMonthofYear = MonthofYear 
    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)

end 

--请求打卡
function reqQiandao(pActor, atvId)
    nextMonthClear(pActor,atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    local dayofMonth = System.getDayOfMonth() 
    local LinChengSec = System.getToday() 

    --今日已经打卡
    if (actorData.LastLogingLinchengSec == LinChengSec) and ( System.getIntBit(actorData.MonthBitFlag,dayofMonth)  == 1) then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:今日已签到成功，无需重复签到|", tstUI)
        return 
    end 
    --检查格子够不够
    if CommonFunc.Awards.CheckBagIsEnough(pActor,1,tmDefNoBagNum,tstUI) ~= true then
        return
    end

    actorData.MonthBitFlag = System.setIntBit(actorData.MonthBitFlag, dayofMonth, 1) --将本月的第n天位置置为1
    actorData.LastLoginIsNo_OfMonth = dayofMonth 
    actorData.LastLogingLinchengSec = LinChengSec
    actorData.LoginInDays = actorData.LoginInDays +1   --可以在某个位置设置校验MonthBitFlag 是否有问题, 先不处理
    
    local MonthofYear  = System.getMonthOfNow();
    actorData.LastLoginMonthofYear = MonthofYear
    
    if SignPrizeCfg[dayofMonth] and SignPrizeCfg[dayofMonth].prz then
        CommonFunc.Awards.Give(pActor, SignPrizeCfg[dayofMonth].prz, GameLog.Log_Activity10005, "每日签到|"..atvId)
    end

    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)

     -- 记录日志
    Actor.SendActivityLog(pActor,atvId,ActivityType,1)

end 



--玩家请求领取礼包
function reqGetGiftBox(pActor, atvId , indexId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    local Cfg = ActivityConfig[atvId]
    
    if Cfg ~=nil then 
       --检查indexId参数是否合法
       for i= 1 , #Cfg do 
            if (Cfg[i].GiftNums ==indexId) then 
                if nil == Cfg[i].GiftTable then return end 
                break 
            end 
            if i == #Cfg and Cfg[i].GiftNums ~=indexId  then 
                --print("请求index参数错误")
                return  --没有找到该天数对应的奖励
            end 
       end 
       --配置检查

       --登录天数不足
        if actorData.LoginInDays <indexId then 
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:打卡天数不足|", tstUI)    
            return 
        end 

        
        --提示已领取无法多次领取
        if System.getIntBit(actorData.AwardBitMap,indexId)  == 1  then 
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:您已领取该奖励|", tstUI)
            return
        end

        --检查格子够不够
        if CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) ~= true then
            return
        end

        for i= 1 , #Cfg do
            if (Cfg[i].GiftNums ==indexId) then
                --CommonFunc.GiveCommonAward(pActor, Cfg[i].GiftTable, GameLog.Log_Activity10005,  "每日签到领取礼包|"..atvId)
                CommonFunc.Awards.Give(pActor, Cfg[i].GiftTable, GameLog.Log_Activity10005,  "每日签到领取礼包|"..atvId)

                actorData.AwardBitMap = System.setIntBit(actorData.AwardBitMap, indexId, 1) --将indexId位置置为1
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
function OnInit(atvId, pActor)
end

--活动开始
function OnStart(atvId , pActor)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)

    nextMonthClear(pActor,atvId)

    if actorData.MonthBitFlag == nil then
        actorData.MonthBitFlag = 0
    end
    if actorData.AwardBitMap == nil then
        actorData.AwardBitMap = 0
    end
    if actorData.LoginInDays == nil then
        actorData.LoginInDays = 0
    end
    if actorData.LastLoginIsNo_OfMonth == nil then
        actorData.LastLoginIsNo_OfMonth = 0
    end
    if actorData.LastLogingLinchengSec == nil then
        actorData.LastLogingLinchengSec = 0
    end
    if actorData.LastLoginMonthofYear == nil then
        actorData.LastLoginMonthofYear = 0
    end
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cReqPurchaseGiftbag then --请求领取签到奖励
        local indexId = DataPack.readByte(inPack)
--print("---------operator : "..operaCode.."-------indexId : "..indexId)
        reqGetGiftBox(pActor, atvId , indexId)
    elseif operaCode == ActivityOperate.cReqAtvQianDao then --请求签到
--print("---------operator : "..operaCode)
        reqQiandao(pActor, atvId)
    end
end

-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)

    nextMonthClear(pActor,atvId)

    if actorData.MonthBitFlag == nil then
        actorData.MonthBitFlag = 0
    end
    if actorData.AwardBitMap == nil then
        actorData.AwardBitMap = 0
    end
    if actorData.LoginInDays == nil then
        actorData.LoginInDays = 0
    end
    if actorData.LastLoginIsNo_OfMonth == nil then
        actorData.LastLoginIsNo_OfMonth = 0
    end
    if actorData.LastLogingLinchengSec == nil then
        actorData.LastLogingLinchengSec = 0
    end
    if actorData.LastLoginMonthofYear == nil then
        actorData.LastLoginMonthofYear = 0
    end

    if  outPack then
        DataPack.writeUInt(outPack, (actorData.MonthBitFlag or 0))   --签到地图
--print("monthbitMap:  "..actorData.MonthBitFlag)
        DataPack.writeUInt(outPack, (actorData.AwardBitMap or 0))    --领取地图
--print("awardbitMap:  "..actorData.AwardBitMap)
        DataPack.writeByte(outPack, (actorData.LoginInDays or 0 ))    --签到天数
--print("days:  "..actorData.LoginInDays)
    end
end

function OnLoginGame(atvId,pActor)
    -- if Actor.IsHasFreePrivilege(pActor) then
    --     backStageQiandao(pActor, atvId)
    -- end
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData.MonthBitFlag == nil then
        actorData.MonthBitFlag = 0
    end
    if actorData.AwardBitMap == nil then
        actorData.AwardBitMap = 0
    end
    if actorData.LoginInDays == nil then
        actorData.LoginInDays = 0
    end
    if actorData.LastLoginIsNo_OfMonth == nil then
        actorData.LastLoginIsNo_OfMonth = 0
    end
    if actorData.LastLogingLinchengSec == nil then
        actorData.LastLogingLinchengSec = 0
    end
    if actorData.LastLoginMonthofYear == nil then
        actorData.LastLoginMonthofYear = 0
    end
end

-- 活动结束
function OnEnd(atvId, pActor)
    ActivityDispatcher.ClearActorData(pActor, atvId)
end

--活动红点数据
function OnGetRedPoint(atvId, pActor)
    local ret = 0
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    local dayofMonth = System.getDayOfMonth()
    local Cfg = ActivityConfig[atvId]
    if System.getIntBit(actorData.MonthBitFlag,dayofMonth) == 0 then
        ret = 1  --最低位1表示当天未签到
    end

    if Cfg ~= nil then
        for i = 1, #Cfg do
            --print("---------------------- actorData.LoginDays: "..(actorData.LoginInDays or -1))
            --print("---------------------- actorData.AwardBitMap: "..actorData.AwardBitMap)
            if ((actorData.LoginInDays or 0) >= Cfg[i].GiftNums) and (System.getIntBit(actorData.AwardBitMap, Cfg[i].GiftNums) == 0) then
                ret = System.setIntBit(ret, i, 1) --对应位为1表示该奖励可领取
            end
        end
    end
    return ret
end

ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType10005.lua")
ActivityDispatcher.Reg(ActivityEvent.OnLoginGame, ActivityType, OnLoginGame, "ActivityType10005.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType10005.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType10005.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType10005.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType10005.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType10005.lua")

------------------------------我是分割线------------------------

-- 跨天，次数清零
function OnNewDayArrive(pActor,ndiffday)
    --print("[ActivityType10005 ] "..Actor.getName(pActor).." 跨"..ndiffday.."天")
    local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
    if runAtvIdList == nil then 
        return 
    end
    if runAtvIdList then
        for i,atvId in ipairs(runAtvIdList) do
            nextMonthClear(pActor,atvId)
            OnLoginGame(atvId,pActor)
            -- 发送一个活动数据
            Actor.sendActivityData(pActor, atvId)
        end
    end
end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10005.lua")