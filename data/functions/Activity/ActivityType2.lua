module("ActivityType2", package.seeall)

--[[
    个人活动，鉴定类活动

    个人数据：ActorData[AtvId]
    {
        usetimes[id]
        {
            times 每日已使用次数
        }

        count[id]
        {
            times 拥有次数
        }
        openDay 统计开服时间
        
    }

    全局缓存：Cache[fbId]
    {

    }

    全局数据：GlobalData[AtvId]
    {

    }
]]--

--活动类型
local ActivityType = 2
--对应的活动配置
local ActivityConfig = Activity2Config
if ActivityConfig == nil then
    assert(false)
end

local AppraisalMainConfig = AppraisalMainConfig
if AppraisalMainConfig == nil then
    assert(false)
end
--通用操作枚举
local Operate = {
    Appraisal = 6, --鉴定操作
}

--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------

--请求鉴定
function operaAppraisal(pActor, atvId, Conf, inPack)
    local nId = DataPack.readByte(inPack)
    -- print("operaAppraisal id:",nId)
    local errorcode = 0
    --消耗检查
    while(true) 
    do
        local data = ActivityDispatcher.GetActorData(pActor,atvId)
        local Conf = Conf[nId]
        if Conf == nil then
            errorcode = 1
            break
        end
        local consumes = Conf.number
        if CommonFunc.Consumes.CheckActorSources(pActor, consumes,tstUI) ~= true then
            -- Actor.sendTipmsgWithId(pActor, tmAppraisalNoItem, tstUI)
            errorcode = 2
            break
        end
        local extraCost = nil
        local myCount = GetOwnTimes(pActor, atvId, nId)
        local usetimes = GetDailyUseTimes(pActor, atvId, nId)
        if myCount ~= -1 then
            if myCount <= 0 then
                Actor.sendTipmsgWithId(pActor,tmAppraisalNoTimes, tstUI)
                errorcode = 3
                break
            end
        end
        
        --次数检查
        -- if Conf.frequency then
        --     if usetimes >= Conf.frequency then
        --         extraCost = Conf.gold
        --     end
        -- end
        extraCost = Conf.gold

        if extraCost and CommonFunc.Consumes.CheckActorSources(pActor, extraCost,tstUI) ~= true then
            -- Actor.sendTipmsgWithId(pActor, tmNoMoreCoin, tstUI)
            errorcode = 4
            break
        end
        if Conf.mexp then
            if(Actor.checkConsume(pActor, qatMultiExpUnused, 0, Conf.mexp)) then
                Actor.sendTipmsgWithId(pActor, tmdoubleExpFull, tstUI)
                errorcode = 5
                break
            end
        end
        if Actor.isMaxLevel(pActor) then
            Actor.sendTipmsgWithId(pActor, tmAppraisalMaxLevel, tstUI)
            errorcode = 6
            break 
        end
        -- 消耗
        if consumes and CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity2, "鉴定类活动|"..atvId) ~= true then
            errorcode = 7
            break
        end
        if extraCost and CommonFunc.Consumes.Remove(pActor, extraCost, GameLog.Log_Activity2, "鉴定类活动|"..atvId) ~= true then
            errorcode = 8
            break
        end 
        addUseTime(pActor, atvId, nId)

        if Conf.gexp then
            Actor.giveAward(pActor, qatMultiExpUnused, qatMultiExpUnused, Conf.gexp, 0, 0, 0,0, GameLog.Log_Activity2,"鉴定类活动|"..atvId)
        end
        -- 记录日志
        Actor.SendActivityLog(pActor,atvId,ActivityType,2)
        Actor.triggerAchieveEvent(pActor, nAchieveActivity,1 ,atvId);
        Actor.triggerAchieveEvent(pActor, nAchieveCompleteActivity,1 ,atvId);
        break
    end

    local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sAppraisal)
    -- local netPack = DataPack.allocPacket(pActor,enActivityID, sSendPersonActivityUpdate)
    if  outPack then
        DataPack.writeInt(outPack, nId) 
        DataPack.writeByte(outPack, errorcode) 
        DataPack.flush(outPack)
    end
end

--退出活动副本
function onExitAtivityFuben(pActor, atvId, fbId)

end

-- 添加使用次数
function addUseTime(pActor, atvId, nId)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    if data == nil then
        return
    end
    --每日已使用次数
    if data.usetimes == nil then
        data.usetimes = {}
    end
    --总的可使用次数
    if data.usetimes[nId] == nil then
        data.usetimes[nId] = 0
    end
    data.usetimes[nId] = data.usetimes[nId] + 1

    -- 扣除次数
    if data.count == nil then
        data.count = {}
    end
    if data.count[nId] == nil then
        data.count[nId] = 0
    end
    if data.count[nId] > 0 then
        data.count[nId] = data.count[nId] - 1
    end
end

-- 获取每日使用次数
function GetDailyUseTimes(pActor, atvId, nId)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    --每日已使用次数
    if data.usetimes == nil then
        data.usetimes = {}
    end
    if data.usetimes[nId] == nil then
        data.usetimes[nId] = 0
    end

    return data.usetimes[nId] or 0
end



-- 获取拥有次数
function GetOwnTimes(pActor, atvId, nId)

    -- local myCount = Conf.frequency
    -- if Conf.iscostfree and Conf.iscostfree == 0 then
    --     local data = ActivityDispatcher.GetActorData(pActor,atvId)
    --     if data.count == nil then
    --         data.count = 0
    --     end
    --     myCount = data.count
    -- end

    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    if data.count == nil then
        data.count = {}
    end

    return data.count[nId] or 0
end


--------------------------------------------------------------------
-- 活动 回调注册
--------------------------------------------------------------------

-- 活动开始
function OnStart(atvId, pActor)
    --清除上次活动个人数据
    ActivityDispatcher.ClearActorData(pActor, atvId)
    print("[PActivity 2] "..Actor.getName(pActor).." 活动开始了，id："..atvId)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    local openday = System.getDaysSinceOpenServer()
    -- data.count = openday * (ActivityConfig[atvId].count or 1)

    if data.openDay == nil then
        data.openDay = openday
    end
    if data.count == nil then
        data.count = {}
    end
    local Conf = AppraisalMainConfig[atvId]
    if Conf then
        for _, cfg in ipairs(Conf) do
            local addValue = 1;

            if cfg.iscostfree and cfg.iscostfree == 0 then
                addValue = openday
            end
            -- print("111111: "..addValue)
            data.count[cfg.id] = addValue* cfg.frequency;
        end
    end
    -- print("[Activity 2] "..Actor.getName(pActor).." 活动开始了，id："..atvId)
end

-- 活动结束
function OnEnd(atvId, pActor)
    print("[Activity 2] "..Actor.getName(pActor).." 活动结束了，id："..atvId)
end

-- 活动帧更新
function OnUpdate(atvId, curTime, pActor)
    --print("[Activity 1] "..Actor.getName(pActor).." 活动进行中，id："..atvId.." now:"..curTime)
end

-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    -- local data = ActivityDispatcher.GetActorData(pActor,atvId)
    -- print("请求活动数据，id：: "..data.count);
    local Conf = AppraisalMainConfig[atvId]
    local t = 0
    if Conf then
        t = #Conf
    end

    DataPack.writeInt(outPack, (t or 0))
    if Conf then
        for i,cfg in ipairs(Conf) do 
            DataPack.writeByte(outPack, (cfg.id or 0))
            local usetimes = GetDailyUseTimes(pActor, atvId, cfg.id)
            DataPack.writeInt(outPack, (usetimes or 0))
            local times = GetOwnTimes(pActor, atvId, cfg.id)
            DataPack.writeInt(outPack, (times or 0))
            
        end
    end
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- id对应配置
    -- print("[OnOperatorOnOperator 2] "..Actor.getName(pActor).." OnOperator，id："..atvId)
    local Conf = AppraisalMainConfig[atvId]
    if Conf == nil then
        return
        -- print("[Activity 2] "..Actor.getName(pActor).." 鉴定类型中找不到活动id："..atvId)
    end
    
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cAppraisal then     -- 请求水晶鉴定
        operaAppraisal(pActor,atvId,Conf,inPack)
    end
end

ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType2.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType2.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType2.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType2.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType2.lua")

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 进入副本
function OnEnterFuben(pActor, fbId)
    
end

-- 退出副本
function OnExitFuben(pActor, fbId)
    
end

-- 跨天，次数清零
function OnNewDayArrive(pActor,ndiffday)
    local openday = System.getDaysSinceOpenServer()
    local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
    if runAtvIdList == nil then 
        return 
    end
    for i,atvId in ipairs(runAtvIdList) do
        print("[Activity 2] "..Actor.getName(pActor).." 跨天,atvId="..atvId)
        local data = ActivityDispatcher.GetActorData(pActor,atvId)
        if data.count == nil then
            data.count = {}
        end

        if data.usetimes then
            data.usetimes = {}
        end
        if data.openDay == nil then
            data.openDay = 0
        end

        -- 按照离线时间 
        local offline_day = 1;
        offline_day = openday- data.openDay;
        if offline_day < 1 then
            offline_day = 1;
        end
        data.openDay = openday
        local Conf = AppraisalMainConfig[atvId]
        if Conf then
            for _, cfg in ipairs(Conf) do

                -- if data.count[cfg.id] == nil then
                --     data.count[cfg.id] = 0;
                -- end

                if cfg.iscostfree and cfg.iscostfree == 0 then
                    if data.count[cfg.id] == nil then
                        data.count[cfg.id] = openday * cfg.frequency
                    else
                        data.count[cfg.id] = offline_day* cfg.frequency + data.count[cfg.id];
                    end
                else
                    data.count[cfg.id] = cfg.frequency;
                end
            end
        end
        -- data.openDay = openday
        -- data.count = data.count + offday* (ActivityConfig[atvId].count or 5)

        -- 发送一个活动数据
        Actor.sendActivityData(pActor, atvId)
    end
end

ActorEventDispatcher.Reg(aeOnEnterFuben, OnEnterFuben, "ActivityType2.lua")
ActorEventDispatcher.Reg(aeOnExitFuben, OnExitFuben, "ActivityType2.lua")
ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType2.lua")
