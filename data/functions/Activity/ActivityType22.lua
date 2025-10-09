module("ActivityType22", package.seeall)

--[[
    跨服入口

    个人数据：ActorData[AtvId]
    {
        
    }

    全局缓存：Cache[fbId]
    {

    }

    全局数据：GlobalData[AtvId]
    {

    }
]]--

--活动类型
local ActivityType = 22
--对应的活动配置
local ActivityConfig = Activity22Config


--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------
function operaResult(pActor, atvId, Conf, inPack)
    local errorCode = 0;
    local nOpenDay = System.getDaysSinceOpenServer();
    local Cfg = ActivityConfig[atvId]
    if Cfg and Cfg.openParam then
    
        if Actor.checkCommonLimit(pActor,(Cfg.openParam.level or 0), (Cfg.openParam.zsLevel or 0),
        (Cfg.openParam.vip or 0), (Cfg.openParam.office or 0)) == false then
            errorCode = 1
        end
        if (Cfg.openParam.openDay or 0) > nOpenDay then
            errorCode = 2
        end
    end
    print("errorCode.."..errorCode)
    local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.cCheckCSActivity)
    if  outPack then
        DataPack.writeByte(outPack, errorCode) 
        DataPack.flush(outPack)
    end
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cCheckCSActivity then
        operaResult(pActor,atvId)
    end
end

function OnGetRedPoint(atvId, pActor)
    local ret = 1
    return ret
end

ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType22.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType22.lua")

