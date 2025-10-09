module("MonDispatcher", package.seeall)
--[[
    个人数据：ActorData
    {
    }

    全局数据：GlobalData[fdId]
    {
    }

    缓存数据：CacheData[fdId]
    {

    }
]]--


local IniScenes =  {}
--注册场景
function InitScene(sceneId)
    if IniScenes== nil then
        IniScenes = {}
    end
    if IniScenes[sceneId] then
        return
    end
    
    IniScenes[sceneId] = sceneId;
end
-- 场景是否注册
function IsInitScene(sceneId)
    if IniScenes == nil then
        return false;
    end

    return IniScenes[sceneId] ~= nil;
end
local dispatcher = { }

_G.MonEvent =
{
    OnInitialize = 1,      --初始化
    OnEnterFuben = 2,      --玩家进入Boss副本[玩家指针，副本指针, pOwner]
    OnExitFuben = 3,       --玩家离开Boss副本[玩家指针，副本指针, pOwner]
    OnEntityDeath = 4,     --副本实体死亡    [被杀者指针，击杀者指针，副本指针, pOwner]
    OnEntityAttacked = 5,  --副本实体收到伤害[副本指针，受击者，攻击者, pOwner]
    OnReqData     = 6,     --boss数据
    OnCancelBL   = 7,--取消归属
    OnSetBossBL   = 8,--设置归属
    OnCheckEnterFuben = 9, --boss进入检查
    OnFubenFinish = 10,     --活动副本结束    [, 副本指针，结果, pOwner] 1为完成，0为失败，nil则结果未知（需要对应副本设置结果）
    OnReqEnterFuben = 11,     --请求进入副本    [玩家指针, bossid]
    Count = 12,
}
--------------------------------------------------------------------
-- Lua接口
--------------------------------------------------------------------

-- @brief 注册事件分发器
-- @param evId 事件id
-- @param atvType 活动类型
-- @param func 回调
function Reg(evId, nMonType,  func, file)

    --参数检查
	if evId == nil or func == nil or file == nil or nMonType == nil then 
		print( debug.traceback() )
		assert(false)
    end
    
    --事件范围检查
    if evId <= 0 or evId >= MonEvent.Count then
        assert(false)
    end

    --回调表初始化
    if dispatcher[evId] == nil then
        dispatcher[evId] = {}
    end
    if dispatcher[evId][nMonType] ~= nil then
        assert(false) -- 重复注册了
    end

    --注册
    dispatcher[evId][nMonType] = func
    print("[TIP][MonDispatcher Add nMonType(Type:"..nMonType..")] Event("..evId..") In File("..file..")")
end

-- @brief 获取副本怪物的全局数据（这个数据，是存文件的）
-- @param fdId 副本id
function GetGlobalData(fdId)
    if fdId == nil then
        assert(false)
    end
    local var = System.getStaticVar();
    if var.Mon == nil then
        var.Mon = {}
    end

    if var.Mon[fdId] == nil then
        var.Mon[fdId] = {}
    end

    return var.Mon[fdId]
end

-- @brief 清空某个bossId的全局数据（这个数据，是存文件的）
-- @param bossId bossId
function ClearGlobalData(fdId)
    if fdId == nil then
        assert(false)
    end
    local var = System.getStaticVar();
    if var.Mon == nil then
        var.Mon = {}
    end
    if var.Mon[fdId] then
        var.Mon[fdId] = nil
    end
end

-- @brief 获取某个活动的缓存数据（这个数据，不存储仅缓存）
-- @param fbId 活动id
function GetCacheData(fdId)
    if fdId == nil then
        assert(false)
    end
    local var = System.getDyanmicVar();
    if var.Mon == nil then
        var.Mon = {}
    end

    if var.Mon[fdId] == nil then
        var.Mon[fdId] = {}
    end

    return var.Mon[fdId]
end

-- @brief 清空boss副本的缓存数据（这个数据，不存储仅缓存）
-- @param fbId 活动id
function ClearCacheData(fdId)
    if fdId == nil then
        assert(false)
    end
    local var = System.getDyanmicVar();
    if var.Mon == nil then
        var.Mon = {}
    end
    if var.Mon[fdId] then
        var.Mon[fdId] = nil
    end
end




-- @brief 获取boss副本的个人数据（这个数据，是存数据库的）
-- @param atvId 活动id
function GetActorData(pActor, fdId)
    if fdId == nil or Actor.getEntityType(pActor) ~= enActor then
        assert(false)
    end
    local var = Actor.getStaticVar(pActor);
    if var.Mon == nil then
        var.Mon = {}
    end
    if var.Mon[fdId] == nil then
        var.Mon[fdId] = {}
    end

    return var.Mon[fdId]
end

-- @brief 清空某个boss副本的个人数据（这个数据，是存数据库的）
-- @param atvId 活动id
function ClearActorData(pActor, fdId)
    if fdId == nil or Actor.getEntityType(pActor) ~= enActor then
        assert(false)
    end
    local var = Actor.getStaticVar(pActor);
    if var.Mon == nil then
        var.Mon = {}
    end
    if var.Mon[fdId] then
        var.Mon[fdId] = nil
    end
end

-- @brief 进入活动副本
function EnterFuben(atvId,pActor,fbId)
    -- local result = Actor.reqEnterFuben(pActor, fbId)
    -- if result then

    --     -- 回复活动id与副本句柄的关联
    --     local npack = AllocOperReturn(pActor, atvId, ActivityOperate.sEnterFubenResult)
    --     if npack then
    --         DataPack.flush(npack)
    --     end

    --     -- 建立副本类型跟活动类型的对应关系
    --     local fbHandle = Actor.getFubenHandle(pActor)
    --     local pFuben = Fuben.getFubenPtrByHandle(fbHandle)
    --     local atvType = 0
    --     if (ActivitiesConf[atvId] and ActivitiesConf[atvId].ActivityType) then
    --         atvType = ActivitiesConf[atvId].ActivityType
    --     elseif (PActivitiesConf[atvId] and PActivitiesConf[atvId].ActivityType) then
    --         atvType = PActivitiesConf[atvId].ActivityType
    --     end
    --     FubenDispatcher.MapToActivity(pFuben, atvType, atvId)

    --     return fbHandle
    -- end
    -- return nil
end



--------------------------------------------------------------------
-- 活动副本回调
--------------------------------------------------------------------

function CheckEnterFuben(nMonType, nFubenId, nSceneId, pEntity)
    -- 玩家指针（个人活动判断需要一个玩家指针）
    if Actor.getEntityType(pEntity) ~= enActor then
        return
    end

    -- 触发玩家进入boss副本
    -- if IsInitScene(nSceneId) then
        OnEvent(nMonType, MonEvent.OnEnterFuben,nFubenId,nSceneId, pEntity)
    -- end
end

function CheckExitFuben(nMonType, nFubenId,nSceneId, pFuben, pEntity)
    -- 玩家指针
    if Actor.getEntityType(pEntity) ~= enActor then
        return
    end

    -- 触发玩家退出Boss副本事件
    OnEvent(nMonType, MonEvent.OnExitFuben, nFubenId, pFuben, nSceneId, pEntity)
end

function CheckFubenEntityDeath(nMonType,nFubenId, nSceneId, pFuben, pEntity, pKiller)
    -- 暂时只处理boss死亡

    if Actor.getEntityType(pEntity) == enPet then
        return
    end

    if Actor.getEntityType(pKiller) == enPet then
        pKiller = Actor.getMaster(pKiller)
    end

    -- 触发Boss副本实体死亡事件
    OnEvent(nMonType, MonEvent.OnEntityDeath,pFuben, nFubenId, nSceneId, pEntity, pKiller)
end

function CheckFubenEntityAttacked(nMonType, nFubenId, nSceneId, pFuben, pEntity, pAttacker)
    -- 玩家指针（个人活动判断需要一个玩家指针）
    local pActor = nil
    if Actor.getEntityType(pEntity) == enPet then
        return
    end
    if Actor.getEntityType(pAttacker) == enPet then
        pAttacker = Actor.getMaster(pAttacker)
    end
    -- 触发Boss副本实体受击事件
    OnEvent(nMonType, MonEvent.OnEntityAttacked, pFuben, nFubenId, nSceneId, pEntity, pAttacker)
    -- end
end

function CheckFubenFinish(nMonType,pFuben, result, pOwner)
    -- 玩家指针（个人活动判断需要一个玩家指针）
    local pActor = nil
    if Actor.getEntityType(pOwner) == enActor then
        pActor = pOwner
    end
    -- print("..nMonType.."..nMonType.."..result.."..result)
    -- 触发活动副本结束事件
    OnEvent(nMonType, MonEvent.OnFubenFinish, pFuben, result, pOwner)
end


-- @brief 进入Boss副本
function EnterMonFuben(nMonType,pActor,fbId, nSerial)
    local result = Actor.reqEnterFuben(pActor, fbId)
    if result then
        -- 建立副本类型跟活动类型的对应关系
        local fbHandle = Actor.getFubenHandle(pActor)
        local pFuben = Fuben.getFubenPtrByHandle(fbHandle)

        FubenDispatcher.MapToMonster(pFuben, nMonType, nSerial)

        return fbHandle
    end
    return nil
end
--公共副本
function EnterGlobalMonFuben(fbHandle,nMonType, fbId)
    -- 建立副本类型跟活动类型的对应关系
    local pFuben = Fuben.getFubenPtrByHandle(fbHandle)

    FubenDispatcher.MapToMonster(pFuben, nMonType, fbId)
end


function OnEvent(nMonType,evId, ...)
    --获取回调
    local callbacks = dispatcher[evId]

    --回调调用
    if callbacks and (callbacks[nMonType] ~= nil) then
        local func = callbacks[nMonType];
        return func(...)
    end
    return true;
end


