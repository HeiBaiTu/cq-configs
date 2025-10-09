module("ActivityType10014", package.seeall)
--[[
    
    微信礼包

    个人数据：ActorData[AtvId]
    {
    }

    全局缓存：Cache[AtvId]
    {   
        
    }

    全局数据：GlobalData[AtvId]
    {
    
    }
]]--

--活动类型
ActivityType = 10014
--对应的活动配置
ActivityConfig = Activity10014Config
if ActivityConfig == nil then
    assert(false)
end


--------------------------我是分界线----------------------------
-- 初始化玩家数据
function OnInit(atvId, pActor)
    -- local Cfg = ActivityConfig[atvId];
    -- if Cfg == nil then
    --     return;
    -- end
    -- local data = getActorCdkData(pActor)
    -- if data then
    --     if data.codeTypeTimes then
    --         if data.codeTypeTimes[Cfg.cdktype] then
    --             Actor.closeOneActivity(pActor,atvId)
    --         end
    --     end
    -- end 
end

--活动开始
function OnStart(atvId, pActor)
    -- local Cfg = ActivityConfig[atvId];
    -- if Cfg == nil then
    --     return;
    -- end
    -- local data =getActorCdkData(pActor)
    -- if data then
    --     if data.codeTypeTimes then
    --         if data.codeTypeTimes[Cfg.cdktype] then
    --             Actor.closeOneActivity(pActor,atvId)
    --         end
    --     end
    -- end 
end


-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    -- local Cfg = ActivityConfig[atvId];
    -- if Cfg == nil then
    --     return;
    -- end
    -- local data = getActorCdkData(pActor)
    -- if data then
    --     if data.codeTypeTimes then
    --         if data.codeTypeTimes[Cfg.cdktype] then
    --             Actor.closeOneActivity(pActor,atvId)
    --         end
    --     end
    -- end 
end

-- 活动结束
function OnUpdate(atvId, curTime, pActor)
    local Cfg = ActivityConfig[atvId];
    if Cfg == nil then
        return;
    end
    local data = getActorCdkData(pActor)
    if data then
        if data.codeTypeTimes then
            if data.codeTypeTimes[Cfg.cdktype] then
                Actor.closeOneActivity(pActor,atvId)
            end
        end
    end 
end


ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType10014.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType10014.lua")

ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType10014.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType10014.lua")