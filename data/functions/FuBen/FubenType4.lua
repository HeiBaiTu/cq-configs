module("FubenType4", package.seeall)

--[[
    刷怪进度通关副本，退出自动发放奖励（若没领取的话）

    个人数据：ActorData[fbId]
    {
        
    }

    全局缓存：Cache[fbId]
    {
        [pFuben] = 
        {
            owner,  所有者玩家id，若为0，则是公共副本
            wave,   当前波数
            phase,  当前阶段 0无 1创建 2开始 3进行中 4结算 5结束
            scenId, 副本当前场景
            hasAwards,  是否可领取奖励
            isGot,  是否已领取
        }
    }

    全局数据：GlobalData[fbId]
    {
    }
]]--

--副本类型
local FubenType = 4
--对应的副本配置
local FubenConfig = FubenType4Conf
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
    End = 5,        --结束
}

--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------

function getCacheDataByHandle(fbHandle)
    local pFuben = Fuben.getFubenPtrByHandle(fbHandle)
    return Fuben.getDyanmicVar(pFuben)
end


--玩家进入副本
function OnActorEnter(fbId, fbEnterType, pFuben, scenId, pActor)
    
    local fbHandle = Fuben.getFubenHandle(pFuben)
    local scenHandle = Fuben.getSceneHandleById(scenId,fbHandle)

    --单人副本
    if fbEnterType == FubenEnterType.Single then
        local thisdata = FubenDispatcher.GetCacheData(pFuben)
        if thisdata.owner == 0 then
            thisdata.owner = Actor.getActorId(pActor)
            thisdata.wave = 0
            thisdata.phase = PhaseType.Start
            thisdata.hasAwards = false
            thisdata.isGot = false
            --设置副本时间
            Fuben.setSceneTime(scenHandle, (FubenConfig[fbId].fbTime or 0))
        end
        thisdata.scenId = scenId
    --组队副本
    elseif fbEnterType == FubenEnterType.Team then
    --多人副本
    elseif fbEnterType == FubenEnterType.All then
 
    end


end

--玩家死亡，10秒后才能复活
function OnActorDeath(fbId, fbEnterType, pFuben, scenId, pActor)
    --Actor.setReliveTimeOut(pActor, 10)
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
                if Actor.checkActorLevel(pActor, cond.param1, cond.param2) then
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
    thisdata.owner = 0
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

-- 副本内实体退出
function OnExit(fbId, fbEnterType, pFuben, scenId, pEntity)
    if Actor.getEntityType(pEntity) == enActor then
        --OnGetAward(fbId, fbEnterType, pFuben, scenId, pEntity)
        -- ActivityDispatcher.CheckExitFuben(ActivityType8.ActivityType, pEntity, pFuben)
    end
end

-- 副本帧更新
function OnUpdate(fbId, fbEnterType, pFuben, curTime)
    local thisdata = FubenDispatcher.GetCacheData(pFuben)
    local fbHandle = Fuben.getFubenHandle(pFuben)
    local scenHandle = Fuben.getSceneHandleById(thisdata.scenId,fbHandle)

end

-- 副本内实体死亡
function OnDeath(fbId, fbEnterType, pFuben, scenId, pEntity)
    if Actor.getEntityType(pEntity) == enActor then
        --OnActorDeath(fbId, fbEnterType, pFuben, scenId, pEntity)
    end

end

-- 请求获取副本奖励
function OnGetAward(fbId, fbEnterType, pFuben, nSceneId, pActor)

end

FubenDispatcher.Reg(FubenEvent.OnCheckEnter, FubenType, OnCheckEnter, "FubenType4.lua")
FubenDispatcher.Reg(FubenEvent.OnCreate, FubenType, OnCreate, "FubenType4.lua")
FubenDispatcher.Reg(FubenEvent.OnEnter, FubenType, OnEnter, "FubenType4.lua")
FubenDispatcher.Reg(FubenEvent.OnExit, FubenType, OnExit, "FubenType4.lua")
FubenDispatcher.Reg(FubenEvent.OnUpdate, FubenType, OnUpdate, "FubenType4.lua")
FubenDispatcher.Reg(FubenEvent.OnDeath, FubenType, OnDeath, "FubenType4.lua")
FubenDispatcher.Reg(FubenEvent.OnGetAward, FubenType, OnGetAward, "FubenType4.lua")
