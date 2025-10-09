module("ActivityType6", package.seeall)
math.randomseed(System.getCurrMiniTime())
--[[
    全局活动，散财鹿

    

    全局缓存：Cache[fbId]
    {

    }

    全局数据：GlobalData[AtvId]
    {
        refertime 刷新时间
        referid  刷新id
    }
]]--

--活动类型
local ActivityType = 6
--对应的活动配置
local ActivityConfig = Activity6Config
-- local LooseMoneyConfig= LooseMoneyConfig
if ActivityConfig == nil then
    assert(false)
end

-- if LooseMoneyConfig == nil then
--     assert(false)
-- end
--------------------------------------------------------------------
-- 活动刷新 逻辑
--------------------------------------------------------------------
function OnRefer(atvId, curTime)
    local cfg = ActivityConfig[atvId]
    if cfg == nil then
        return
    end

    local data = ActivityDispatcher.GetGlobalData(atvId)
    if data.refertime == nil then
        data.refertime = 0
    end

    if data.referid == nil then
        data.referid = 0
    end
    -- 获取刷新坐标
    local nReferPos = nil
    if curTime >= data.refertime then
        nReferPos = GetReferPos(cfg, data.referid )
    end
    if nReferPos == nil then
        return
    end
    local sceneHandle = Fuben.getSceneHandleById(nReferPos.map, 0);
    if sceneHandle == nil then
        return
    end
    local tReferPosInfo = Fuben.getreateMonsterPosXY(sceneHandle, nReferPos.x, nReferPos.y, nReferPos.range)
    if tReferPosInfo == nil then
        return;
    end

    -- print("tReferPosInfo x: "..tReferPosInfo.x.. " y: "..tReferPosInfo.y)

    local pMonster
    local refreshSuccess = false

    if 1 < (cfg.refreshNum or 0) then
        for i = 1, cfg.refreshNum do
            local rangeX = math.random(1, nReferPos.range)
            local rangeY = math.random(1, nReferPos.range)
            pMonster = Fuben.createMonster(sceneHandle, cfg.monsterid, tReferPosInfo.x + rangeX, tReferPosInfo.y + rangeY)
            if pMonster then refreshSuccess = true end
        end
    else
        pMonster = Fuben.createMonster(sceneHandle, cfg.monsterid, tReferPosInfo.x, tReferPosInfo.y)
        if pMonster then refreshSuccess = true end
    end

    if refreshSuccess then
        if cfg.notice then
            local str = string.format(cfg.content,tReferPosInfo.x,tReferPosInfo.y,nReferPos.map, tReferPosInfo.name, tReferPosInfo.x, tReferPosInfo.y)
            -- local str = string.format(cfg.content, tReferPosInfo.name, tReferPosInfo.x, tReferPosInfo.y)
            System.broadcastTipmsgLimitLev(str, tstBigRevolving)
            System.broadcastTipmsgLimitLev(str, tstChatSystem)
            -- System.SendChatMsg(str, 4)
        end
    end
    data.refertime = curTime + cfg.refertime
end

--------------------------------------------------------------------

function GetReferPos(Conf, nlastReferId)
    if Conf == nil then
        return nil
    end
    local data = {}
    if Conf.pos then
        for _, cfg in ipairs(Conf.pos) do
            if Conf.same and nlastReferId ~= cfg.id then
                table.insert(data,cfg)
            end
        end
    end

    local len = #data
    -- print("len.."..len)
    if len > 0 then
        -- print(math.random(len))
        return data[math.random(len)]
    end
    return nil
end
--------------------------------------------------------------------
-- 活动 回调注册
--------------------------------------------------------------------

-- 活动开始
function OnStart(atvId)
     --初始化全局活动
    print("[PActivity 6] 活动开始了，id："..atvId)
    local data = ActivityDispatcher.GetGlobalData(atvId)
    data.refertime = 0
    data.referid = 0
end



-- 活动结束
function OnEnd(atvId)
    print("[Activity 6] 活动结束了，id："..atvId)
    ActivityDispatcher.ClearGlobalData(atvId);
end

-- 活动帧更新
function OnUpdate(atvId, curTime)
    OnRefer(atvId,curTime)
end

-- 获取活动数据
function OnReqData(atvId)
    -- print("[Activity 6] 请求活动数据，id："..atvId)
end

-- 通用操作
function OnOperator(atvId)
    
end

--活动红点数据
function OnGetRedPoint(atvId, pActor)
    local ret = 1
    return ret
end
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType6.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType6.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType6.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType6.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType6.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType6.lua")
