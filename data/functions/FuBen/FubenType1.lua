module("FubenType1", package.seeall)

--[[
    刷怪进度通关副本

    个人数据：ActorData[fbId]
    {
        
    }

    全局缓存：Cache[fbId]
    {
        [pFuben] = 
        {
            wave,   当前波数
            phase,  当前阶段 0无 1创建 2开始 3进行中 4结算 5结束
            scenId, 副本当前场景
        }
    }

    全局数据：GlobalData[fbId]
    {
    }
]]--

--副本类型
local FubenType = 1
--对应的副本配置
local FubenConfig = FubenType1Conf
if FubenConfig == nil then
    assert(false)
end

local EnterCheckType = 
{
    Activity = 1,   --检查活动开启，param1=活动id
    Level = 2,      --检查等级达到，param1=等级，param2=转生
}

local PhaseType =
{
    Create = 1,     --创建
    Start = 2,      --开始
    Running = 3,    --进行中
    Finish = 4,     --完成
}

--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------

function getCacheDataByHandle(fbHandle)
    local pFuben = Fuben.getFubenPtrByHandle(fbHandle)
    return Fuben.getDyanmicVar(pFuben)
end

--广播进度
function BroadSchedule(pFuben)
    local fbId = Fuben.getFubenIdByPtr(pFuben)
    local fbHandle = Fuben.getFubenHandle(pFuben)
    local sceneId = Fuben.getSceneId(fbHandle)
    local scenHandle = Fuben.getSceneHandleById(sceneId,fbHandle)

    --分配一个广播包
    local npack = FubenDispatcher.AllocPacketEx(enFubenSystemID, sFubenSchedule)

    --副本数据
    local thisdata = FubenDispatcher.GetCacheData(pFuben)
    local curWave = thisdata.wave or 1  --当前波数
    local totalWave = #FubenConfig[fbId].fbRefresh --总波数
    local leftCount = Fuben.getLiveMonsterCount(scenHandle,0) --剩余怪物数量
    DataPack.writeByte(npack, curWave)
    DataPack.writeByte(npack, totalWave)
    DataPack.writeByte(npack, leftCount)

    --广播当前场景
    DataPack.broadcastScene(npack,fbHandle,sceneId)

    --释放广播包
    ActivityDispatcher.FreePacketEx(npack)
    return npack
end

--玩家进入副本
function OnActorEnter(fbId, fbEnterType, pFuben, scenId, pActor)
    
    local fbHandle = Fuben.getFubenHandle(pFuben)
    local scenHandle = Fuben.getSceneHandleById(scenId,fbHandle)

    --单人副本
    if fbEnterType == FubenEnterType.Single then
        local thisdata = FubenDispatcher.GetCacheData(pFuben)
        thisdata.wave = 0
        thisdata.phase = PhaseType.Start
        thisdata.scenId = scenId
    --组队副本
    elseif fbEnterType == FubenEnterType.Team then
    --多人副本
    elseif fbEnterType == FubenEnterType.All then
    end

    
end

--检查波数刷怪
function OnCheckWave(fbId, fbEnterType, pFuben, curTime)
    
    local thisdata = FubenDispatcher.GetCacheData(pFuben)
    local fbHandle = Fuben.getFubenHandle(pFuben)
    local scenHandle = Fuben.getSceneHandleById(thisdata.scenId,fbHandle)

    -- 刷第一波怪
    if thisdata.phase == PhaseType.Start then
        --清空当前副本内所有的怪物
        -- Fuben.clearSceneEntity(scenHandle, 1);
        thisdata.phase = PhaseType.Running
        thisdata.wave = 1
        local fresh = FubenConfig[fbId].fbRefresh
        if fresh and fresh[1] then
            local wave = fresh[1]
            Fuben.createMonstersInRange(scenHandle, wave.entityid, wave.x-wave.range, wave.y-wave.range, wave.x+wave.range, wave.y+wave.range, wave.count, 0)
        end
        BroadSchedule(pFuben)
    -- 刷怪检测
    elseif thisdata.phase == PhaseType.Running then
        local fresh = FubenConfig[fbId].fbRefresh
        if fresh and fresh[thisdata.wave] then
            local wave = fresh[thisdata.wave]
            local leftCount = Fuben.getLiveMonsterCount(scenHandle,wave.entityid) --剩余怪物数量
            if leftCount <= 0 then
                if fresh[thisdata.wave + 1] then
                    thisdata.wave = thisdata.wave + 1
                    wave = fresh[thisdata.wave]
                    Fuben.createMonstersInRange(scenHandle, wave.entityid, wave.x-wave.range, wave.y-wave.range, wave.x+wave.range, wave.y+wave.range, wave.count, 0)
                else
                    thisdata.phase = PhaseType.Finish
                    FubenDispatcher.SetResult(pFuben,1)
                    BroadSchedule(pFuben)
                end
            end
        else
            thisdata.phase = PhaseType.Finish
            FubenDispatcher.SetResult(pFuben,1)
            BroadSchedule(pFuben)
        end
    -- 结束
    elseif thisdata.phase == PhaseType.Finish then
        FubenDispatcher.SetResult(pFuben,1)
        thisdata.phase = nil
    end
end

--------------------------------------------------------------------
-- 副本 回调注册
--------------------------------------------------------------------

-- 检查玩家进入
function OnCheckEnter(fbId, fbEnterType, pActor)
    local Conf = FubenConfig[fbId]
    if Conf == nil then
        return false
    end

    -- 这个进入条件需要全部满足
    if Conf.fbEnterLimit then
        for i,cond in ipairs(Conf.fbEnterLimit) do
            if cond.type == EnterCheckType.Activity then
                if Actor.isActivityRunning(pActor, cond.param1) == false then
                    Actor.sendTipmsg(pActor, "活动："..cond.param1.." 并未开启!", tstUI)
                    return false
                end
            elseif cond.type == EnterCheckType.Level then
                if Actor.checkActorLevel(pActor, cond.param1, (cond.param2 or 0)) == false then
                    Actor.sendTipmsg(pActor, "等级转生不满足："..cond.param1.."级别"..(cond.param2 or 0).."转!", tstUI)
                    return false
                end
            end
        end
    end
    -- 这个进入条件满足一条即可
    if Conf.fbEnterPass then
        for i,cond in ipairs(Conf.fbEnterPass) do
            if cond.type == EnterCheckType.Activity then
                if Actor.isActivityRunning(pActor, cond.param1) then
                    return true
                end
            elseif cond.type == EnterCheckType.Level then
                if Actor.checkActorLevel(pActor, cond.param1, (cond.param2 or 0)) then
                    return true
                end
            end
        end
        return false
    end
    return true
end

-- 副本创建
function OnCreate(fbId, fbEnterType, pFuben)
    local thisdata = FubenDispatcher.GetCacheData(pFuben)
    
    -- 重置数据
    thisdata.wave = 0
    thisdata.phase = PhaseType.Create
    thisdata.scenId = 0
end

-- 副本内实体进入
function OnEnter(fbId, fbEnterType, pFuben, scenId, pEntity)
    if Actor.getEntityType(pEntity) == enActor then
        OnActorEnter(fbId, fbEnterType, pFuben, scenId, pEntity)
    end
end

-- 副本帧更新
function OnUpdate(fbId, fbEnterType, pFuben, curTime)
    --检查波数刷怪
    OnCheckWave(fbId, fbEnterType, pFuben, curTime)
end

-- 实体死亡
function OnDeath(fbId, fbEnterType, pFuben, scenId, pEntity)
    if Actor.getEntityType(pEntity) == enMonster then
        BroadSchedule(pFuben)
    end
end

FubenDispatcher.Reg(FubenEvent.OnCheckEnter, FubenType, OnCheckEnter, "FubenType1.lua")
FubenDispatcher.Reg(FubenEvent.OnCreate, FubenType, OnCreate, "FubenType1.lua")
FubenDispatcher.Reg(FubenEvent.OnEnter, FubenType, OnEnter, "FubenType1.lua")
FubenDispatcher.Reg(FubenEvent.OnUpdate, FubenType, OnUpdate, "FubenType1.lua")
FubenDispatcher.Reg(FubenEvent.OnDeath, FubenType, OnDeath, "FubenType1.lua")
