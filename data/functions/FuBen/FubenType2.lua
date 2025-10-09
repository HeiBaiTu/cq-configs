module("FubenType2", package.seeall)

--[[
    PVP副本，带刷守卫

    个人数据：ActorData[fbId]
    {
    }

    全局缓存：Cache[fbId]
    {
        [pFuben] = 
        {
            curSceneId : 副本的当前场景id
            nextCheckGuard: 下一次检测守卫生成的时间戳
            guardCount = {[i] = num}
        }
    }

    全局数据：GlobalData[fbId]
    {
    }
]]--

--副本类型
local FubenType = 2
--对应的副本配置
local FubenConfig = FubenType2Conf
if FubenConfig == nil then
   assert(false)
end

local EnterCheckType = 
{
    Activity = 1,   --检查活动开启，param1=活动id
    Level = 2,      --检查等级达到，param1=等级，param2=转生
}

--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------

--检查刷守卫怪
function OnCheckGuard(fbId, pFuben, curTime)
    local thisdata = FubenDispatcher.GetCacheData(pFuben)
    if (thisdata.nextCheckGuard or 0) < curTime then
        local fbHandle = Fuben.getFubenHandle(pFuben)
        local scenHandle = Fuben.getSceneHandleById(thisdata.curSceneId,fbHandle)
        local freshConf = FubenConfig[fbId].fbRefresh
        thisdata.nextCheckGuard = (thisdata.nextCheckGuard or 0) + 10
        for i,info in ipairs(freshConf) do
            if thisdata.guardCount == nil then
                thisdata.guardCount = {}
            end
            if (thisdata.guardCount[i] or 0) <= 0 then
                local pMonster = Fuben.createOneMonsters(scenHandle, info.entityid, info.x, info.y, 1, 0)
                if pMonster then
                    thisdata.guardCount[i] = (thisdata.guardCount[i] or 0) + 1
                    Actor.setMonsterProperty(pMonster, PROP_MONSTER_BORNPOINT, i)
                end
            end
        end
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
                    --Actor.sendTipmsg(pActor, "等级转生不满足："..cond.param1.."级"..(cond.param2 or 0).."转!", tstUI)
                    Actor.sendTipmsgWithId(pActor, tmLevelLimited, tstUI)
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
    local curSceneId = 0
    curSceneId = StaticFubens[fbId].defSceneID
    if curSceneId == nil then
        curSceneId = StaticFubens[fbId].scenes[1]
    end
    
    local thisdata = FubenDispatcher.GetCacheData(pFuben)
    thisdata.curSceneId = curSceneId
end

-- 副本内实体进入
function OnEnter(fbId, fbEnterType, pFuben, scenId, pEntity)
        
    if Actor.getEntityType(pEntity) == enActor then
        --回血回蓝
        local maxhp = Actor.getIntProperty(pEntity,PROP_CREATURE_MAXHP)
        Actor.changeHp(pEntity, maxhp)
        local maxmp = Actor.getIntProperty(pEntity,PROP_CREATURE_MAXMP)
        Actor.changeMp(pEntity, maxmp)
        Actor.removePet(pEntity)
    end
        
    --单人PVP副本
    if fbEnterType == FubenEnterType.Single then
    --组队PVP副本
    elseif fbEnterType == FubenEnterType.Team then
    --多人PVP副本
    elseif fbEnterType == FubenEnterType.All then
    end
end

-- 副本帧更新
function OnUpdate(fbId, fbEnterType, pFuben, curTime)

    --检测守卫怪
    OnCheckGuard(fbId, pFuben, curTime)
    
end

-- 副本内实体死亡
function OnDeath(fbId, fbEnterType, pFuben, scenId, pEntity)
    local killerHandle = Actor.getKillHandle(pEntity)
    local pKiller = Actor.getEntity(killerHandle)

    if Actor.getEntityType(pEntity) == enMonster then
        local thisdata = FubenDispatcher.GetCacheData(pFuben)
        if thisdata.guardCount == nil then
            thisdata.guardCount = {}
        end
        local i = Actor.getIntProperty(pEntity, PROP_MONSTER_BORNPOINT)
        local freshConf = FubenConfig[fbId].fbRefresh
        if freshConf and freshConf[i] then
            thisdata.guardCount[i] = thisdata.guardCount[i] - 1
        end
    end
end

FubenDispatcher.Reg(FubenEvent.OnCheckEnter, FubenType, OnCheckEnter, "FubenType2.lua")
FubenDispatcher.Reg(FubenEvent.OnCreate, FubenType, OnCreate, "FubenType2.lua")
FubenDispatcher.Reg(FubenEvent.OnEnter, FubenType, OnEnter, "FubenType2.lua")
FubenDispatcher.Reg(FubenEvent.OnUpdate, FubenType, OnUpdate, "FubenType2.lua")
FubenDispatcher.Reg(FubenEvent.OnDeath, FubenType, OnDeath, "FubenType2.lua")
