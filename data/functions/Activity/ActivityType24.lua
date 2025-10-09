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
local ActivityType = 24
--对应的活动配置
local ActivityConfig = Activity24Config

-- 活动结束
function OnEnd(atvId)
    print("[Activity 24] 活动结束了，id："..atvId)
    System.KickAllCrossServerActor();
end



ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType24.lua")

