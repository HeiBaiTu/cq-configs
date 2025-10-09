module("CrossServerDispatcher", package.seeall)
--[[
    actorData[AtvId]
    {
        mCrossActorId, --原服玩家id
        mRawSrvId --原服跨服serverid
    }
]]--
----------------------------------------------------------
---跨服角色处理
----------------------------------------------------------

--获取玩家数据
function GetGlobalData(nActorId)
    if nActorId == nil then
        assert(false)
    end
    local var = System.getStaticVar();
    if var.globalCsData == nil then
        var.globalCsData = {}
    end

    if var.globalCsData[nActorId] == nil then
        var.globalCsData[nActorId] = {}
    end

    return var.globalCsData[nActorId]
end

-- 初始化
function InitActor(nActorId, nCrossActorId, nRawSrvId)
    local globalData = GetGlobalData(nActorId);
    if globalData.actorData == nil then
        globalData.actorData = {}
    end
    print("InitActor.."..nActorId.."..nCrossActorId.."..nCrossActorId.."..nRawSrvId.."..nRawSrvId)
    globalData.actorData.mCrossActorId = nCrossActorId;
    globalData.actorData.mRawSrvId = nRawSrvId;
end

-- 初始化
function GetCrossServerActor(nActorId)
    local globalData = GetGlobalData(nActorId);
    if globalData.actorData == nil then
        return 0, 0
    end
    local data =  globalData.actorData;
    print("mCrossActorId.."..data.mCrossActorId.."..mRawSrvId.."..data.mRawSrvId)
    return data.mCrossActorId,data.mRawSrvId;
end

----------------------------------------------------------
---跨服账号处理
----------------------------------------------------------
--获取玩家数据

-- @brief 获取某个活动的缓存数据（这个数据，不存储仅缓存）
-- @param fbId 活动id
function GetCenterCacheData(atvId)
    if atvId == nil then
        assert(false)
    end
    local var = System.getDyanmicVar();
    if var.centerAccountData == nil then
        var.centerAccountData = {}
    end

    if var.centerAccountData[atvId] == nil then
        var.centerAccountData[atvId] = {}
    end

    return var.centerAccountData[atvId]
end

-- 初始化
function InitCSAccount(nAcouuntId, nRawSrvId, pActor)
    local nKey = string.format("%d%d", nAcouuntId,nRawSrvId);
    print("InitCSAccount nAcouuntId.."..nAcouuntId.."..nAcouuntId.."..nRawSrvId.."..nKey.."..nKey)
    local globalData = GetCenterCacheData(nKey);
    local handle = Actor.getHandle(pActor)
    globalData[nKey] = handle
end

-- 初始化
function DeleteCSAccount(nAcouuntId, nRawSrvId)
    local nKey = string.format("%d%d", nAcouuntId,nRawSrvId);
    print("DeleteCSAccount nAcouuntId.."..nAcouuntId.."..nAcouuntId.."..nRawSrvId.."..nKey.."..nKey)
    local globalData = GetCenterCacheData(nKey);
    
    local pActor = Actor.getEntity(globalData[nKey] or 0)
    if pActor then
        Actor.KickUserAccount(pActor)
    end
    globalData[nKey] = nil
end

-- function CheckCSAccount(nAcouuntId, nRawSrvId)
--     local nKey = string.format("%d%d", nAcouuntId,nRawSrvId);
--     print("CheckCSAccount nAcouuntId.."..nAcouuntId.."..nAcouuntId.."..nRawSrvId.."..nKey.."..nKey)
--     local globalData = GetCenterCacheData(nKey);

--     return (globalData[nKey] or 0)
-- end