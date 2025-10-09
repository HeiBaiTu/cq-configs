module("FubenDispatcher", package.seeall)
--[[
    缓存数据：CacheData[fbId]
    {
        atvId,          建立 活动副本 与 活动id 的对应关系
        atvType,        副本类型到活动类型列表的映射，用以建立副本类型跟活动类型的对应关系
        ownerId,        单人副本的归属者id
        timeFlag,       超时设置标志
        kickFlag,       超时后踢出标志
        result,         副本结果 1成功，0失败，nil则未知（超时后，若未设置1，则设置为0）
        relive[aid] = -1~n 对应玩家的复活次数
    }
]]--

local campType_Blue = 1 
local campType_Red  = 2 

local dispatcher = {}

_G.FubenEnterType = 
{
    Single = 0, --单人进入类副本
    Team = 1,   --队伍进入类副本
    All = 2,    --多人进入类副本
}

_G.FubenEvent =
{
    OnCheckEnter = 1,   --进入检查     [副本id，进入类型，玩家指针]   注意：需要返回值true/false
    OnCreate = 2,       --副本创建     [副本id，进入类型，副本指针]
    OnEnter = 3,        --实体进入副本 [副本id，进入类型，副本指针，场景id，实体指针]
    OnExit = 4,         --实体退出副本 [副本id，进入类型，副本指针，场景id，实体指针]
    OnUpdate = 5,       --副本帧更新   [副本id，进入类型，副本指针，当前时间]
    OnDeath = 6,        --实体死亡     [副本id，进入类型，副本指针，场景id，实体指针]
    OnGetAward = 7,    	--获取副本奖励 [副本id，进入类型，副本指针，场景id，玩家指针]
    OnTimeout = 8,      --副本超时     [副本id，进入类型，副本指针]
    OnAttacked = 9,     --实体收到攻击 [副本id，进入类型，副本指针，场景id，受击者，攻击者] 注意：怪物攻击怪物不触发
    Count = 10,
}

--------------------------------------------------------------------
-- Lua接口
--------------------------------------------------------------------

-- @brief 注册事件分发器
-- @param evId 事件id
-- @param fbType 副本类型
-- @param func 回调
function Reg(evId, fbType, func, file)

	--参数检查
	if fbType == nil or evId == nil or func == nil or file == nil then 
		print( debug.traceback() )
		assert(false)
	end

    --事件范围检查
    if evId <= 0 or evId >= FubenEvent.Count then
        assert(false)
    end

    --回调表初始化
    if dispatcher[evId] == nil then
        dispatcher[evId] = {}
    end
    if dispatcher[evId][fbType] ~= nil then
        assert(false) -- 重复注册了
    end

    --注册
    dispatcher[evId][fbType] = func
    print("[TIP][FubenDispatcher] Add Fuben(Type:"..fbType..") Event("..evId..") In File("..file.."), And Index="..table.maxn(dispatcher[evId]))
end

-- @brief 获取某个副本的全局数据（这个数据，是存文件的）
-- @param fbId 副本id
function GetGlobalData(fbId)
    if fbId == nil then
        assert(false)
    end
    local var = System.getStaticVar();
    if var.Fubens == nil then
        var.Fubens = {}
    end

    if var.Fubens[fbId] == nil then
        var.Fubens[fbId] = {}
    end

    return var.Fubens[fbId]
end

-- @brief 清空某个副本的全局数据（这个数据，是存文件的）
-- @param fbId 副本id
function ClearGlobalData(fbId)
    if fbId == nil then
        assert(false)
    end
    local var = System.getStaticVar();
    if var.Fubens == nil then
        var.Fubens = {}
    end
    if var.Fubens[fbId] then
        var.Fubens[fbId] = nil
    end
end

-- @brief 获取某个副本的缓存数据（这个数据，不存储仅缓存）
-- @param pFuben 副本指针
function GetCacheData(pFuben)
    if pFuben == nil then
        assert(false)
    end
    return Fuben.getDyanmicVar(pFuben)
end

-- @brief 清空某个副本的缓存数据（这个数据，不存储仅缓存）
-- @param pFuben 副本指针
function ClearCacheData(pFuben)
    if pFuben == nil then
        assert(false)
    end
    Fuben.clearDynamicVar(pFuben)
end

-- @brief 获取某个副本的个人数据（这个数据，是存数据库的）
-- @param pActor 玩家指针
-- @param fbId 副本id
function GetActorData(pActor, fbId)
    if fbId == nil or Actor.getEntityType(pActor) ~= enActor then
        assert(false)
    end
    local var = Actor.getStaticVar(pActor);
    if var.Fubens == nil then
        var.Fubens = {}
    end

    if var.Fubens[fbId] == nil then
        var.Fubens[fbId] = {}
    end

    return var.Fubens[fbId]
end

-- @brief 清空某个副本的个人数据（这个数据，是存数据库的）
-- @param pActor 玩家指针
-- @param fbId 副本id
function ClearActorData(pActor, fbId)
    if fbId == nil or Actor.getEntityType(pActor) ~= enActor then
        assert(false)
    end
    local var = Actor.getStaticVar(pActor);
    if var.Fubens == nil then
        var.Fubens = {}
    end
    if var.Fubens[fbId] then
        var.Fubens[fbId] = nil
    end
end

-- @brief 设置复活剩余次数
-- @param pActor 玩家指针
-- @param fbId 副本id
-- @param idx 复活选项索引（0为自动复活的，大于1的为复活选项卡的索引）
-- @param count 次数限制（若设置为nil，则自动应用配置的，相当于重置；-1为无限制）
function SetReliveCount(pActor, fbId, idx, count)
    local actorData = GetActorData(pActor, fbId)
    if actorData.relive == nil then
        actorData.relive = {}
    end
    if count == nil then
        local ConfId = (StaticFubens[fbId] and StaticFubens[fbId].reliveConfId) or 1
        local ReliveConf = ReliveConfig[ConfId] or ReliveConfig[1]
        if idx == 0 then
            actorData.relive[idx] = ReliveConf.limit
        else
            actorData.relive[idx] = ReliveConf.selectInfo[idx].limit or -1
        end
    else
        actorData.relive[idx] = count
    end
end

-- @brief 设置副本结果（有结果后，再次设置无效）
-- @param pFuben 副本指针
-- @param result 1为成功，0为失败
function SetResult(pFuben, result)
    local cacheData = GetCacheData(pFuben)
    if not cacheData.result then
        cacheData.result = result
    end
    CheckActivityFubenFinish(pFuben)
end

-- @brief 获取副本结果
-- @param pFuben 副本指针
-- @return 1为成功，0为失败，nil为未知
function GetReault(pFuben)
    local cacheData = GetCacheData(pFuben)
    return cacheData.result
end

-- @brief 判断是否为活动副本
-- @param pFuben 副本指针
function IsActivityFuben(pFuben)
    local fbCacheData = FubenDispatcher.GetCacheData(pFuben)
    return fbCacheData.atvType ~= nil
end


-- @brief 判断是否为Mon副本
-- @param pFuben 副本指针
function IsMonFuben(pFuben)
    local fbCacheData = FubenDispatcher.GetCacheData(pFuben)
    return fbCacheData.nMonType ~= nil
end

-- @brief 获取副本对应的活动id
-- @param pFuben 副本指针
-- @return 若非活动副本，则返回nil
function GetActivityId(pFuben)
    local fbCacheData = FubenDispatcher.GetCacheData(pFuben)
    return fbCacheData.atvId
end

-- @brief 获取副本对应的活动Type
-- @param pFuben 副本指针
-- @return 若非活动副本，则返回nil
function GetActivityType(pFuben)
    local fbCacheData = FubenDispatcher.GetCacheData(pFuben)
    return fbCacheData.atvType
end

-- @brief 获取副本对应的活动,超时后踢出标志
-- @param pFuben 副本指针
-- @return 若非活动副本，则返回nil
function GetActivityKickFlag(pFuben)
    local fbCacheData = FubenDispatcher.GetCacheData(pFuben)
    return fbCacheData.kickFlag 
end

-- @brief 是否为单人副本
-- @param pFuben 副本指针
function IsSingleFuben(pFuben)
    local fbId = Fuben.getFubenIdByPtr(pFuben)
    if StaticFubens[fbId].enterType == FubenEnterType.Single then
        local fbCacheData = FubenDispatcher.GetCacheData(pFuben)
        if fbCacheData.ownerId then
            return true
        end
    end
end

-- @brief 获取副本所有者（目前仅对单人副本）
-- @param pFuben 副本指针
-- @return 玩家指针（若非单人副本，则返回nil）
function GetOwner(pFuben)
    local fbCacheData = FubenDispatcher.GetCacheData(pFuben)
    return Actor.getActorPtrById(fbCacheData.ownerId)
end

-- @brief 延迟踢出
-- @param pFuben 副本指针
-- @param timeout 超时时间（默认10秒）
function KictoutAfter(pFuben, timeout)
    local cacheData = GetCacheData(pFuben)
    cacheData.kickFlag = 1
    Fuben.setFbTime(pFuben, timeout or 10)
end

-- @brief 设置复活次数
-- @param pFuben 副本指针
-- @param pActor 玩家指针
-- @param count 次数
function SetReliveCount(pFuben, pActor, count)
    if (not pFuben) or (not pActor) then
        return
    end
    local aid = Actor.getActorId(pActor)
    local cacheData = GetCacheData(pFuben)
    if not cacheData.relive then cacheData.relive = {} end
    cacheData.relive[aid] = count
end

-- @brief 获取复活次数
-- @param pFuben 副本指针
-- @param pActor 玩家指针
-- @return -1为不限次数，nil为异常
function GetReliveCount(pFuben, pActor)
    if (not pFuben) or (not pActor) then
        return nil
    end
    local aid = Actor.getActorId(pActor)
    local cacheData = GetCacheData(pFuben)
    if not cacheData.relive then cacheData.relive = {} end
    return cacheData.relive[aid] or -1
end

-- @brief 分配一个广播包，需要外部自己调用FreePacketEx释放包
function AllocPacketEx(systemId, cmdId)
    local npack = DataPack.allocPacketEx()
    if npack then
        DataPack.writeByte(npack,systemId)
        DataPack.writeByte(npack,cmdId)
    end
    return npack
end

-- @brief 释放一个通用回复（注意：这是广播包）
function FreePacketEx(npack)
    if npack then
        DataPack.freePacketEx(npack)
    end
end

--------------------------------------------------------------------
-- CPP回调
--------------------------------------------------------------------

function OnCreateEvent(fbId, fbEnterType, pFuben)
    -- 设置副本超时，如果需要的话
    local FubenConf = StaticFubens[fbId]
    if FubenConf and FubenConf.timeOut then
        local cacheData = GetCacheData(pFuben)
        if not cacheData.timeFlag then
            Fuben.setFbTime(pFuben, FubenConf.timeOut)
            cacheData.timeFlag = 1
        end
    end
end

function OnEnterEvent(fbId, fbEnterType, pFuben, scenId, pEntity)

    -- 记录单人副本归属
    if fbEnterType == FubenEnterType.Single then
        if Actor.getEntityType(pEntity) == enActor then
            local fbCacheData = FubenDispatcher.GetCacheData(pFuben)
            fbCacheData.ownerId = Actor.getActorId(pEntity)
        end
    end
    
    -- 进入新场景时，发送剩余时间，如果需要的话
    local FubenConf = StaticFubens[fbId]
    if FubenConf and FubenConf.timeOut then
        if Actor.getEntityType(pEntity) == enActor then
            local netPack = DataPack.allocPacket(pEntity, enFubenSystemID, sFubenRestTime)
            if netPack then
                DataPack.writeInt(netPack, Fuben.getFbTime(pFuben))
                DataPack.flush(netPack)
            end
        end
    end

    -- 进入活动场景检测
    if IsActivityFuben(pFuben) then
        local cacheData = GetCacheData(pFuben)
        ActivityDispatcher.CheckEnterFuben(cacheData.atvType, cacheData.atvId, pFuben, pEntity, Actor.getActorById(cacheData.ownerId))
    end
    if IsMonFuben(pFuben) then
        local cacheData = GetCacheData(pFuben)
        MonDispatcher.CheckEnterFuben(cacheData.nMonType, fbId,scenId,pEntity)
    end
end

function OnExitEvent(fbId, fbEnterType, pFuben, scenId, pEntity)
    -- 离开活动场景检测
    if IsActivityFuben(pFuben) then
        local cacheData = GetCacheData(pFuben)
        ActivityDispatcher.CheckExitFuben(cacheData.atvType, cacheData.atvId, pFuben, pEntity, Actor.getActorById(cacheData.ownerId))
    end
    if IsMonFuben(pFuben) then
        local cacheData = GetCacheData(pFuben)
        MonDispatcher.CheckExitFuben(cacheData.nMonType, fbId,scenId,pFuben, pEntity)
    end
end

function OnEntityDeathEvent(fbId, fbEnterType, pFuben, scenId, pEntity)
    -- 检查活动副本内实体死亡
    if IsActivityFuben(pFuben) then
        local killerHandle = Actor.getKillHandle(pEntity)
        local pKiller = Actor.getEntity(killerHandle)
        local cacheData = GetCacheData(pFuben)
        ActivityDispatcher.CheckFubenEntityDeath(cacheData.atvType, cacheData.atvId, pFuben, pEntity, pKiller, Actor.getActorById(cacheData.ownerId))
    end
    if IsMonFuben(pFuben) then
        local cacheData = GetCacheData(pFuben)
        local killerHandle = Actor.getKillHandle(pEntity)
        local pKiller = Actor.getEntity(killerHandle)
        MonDispatcher.CheckFubenEntityDeath(cacheData.nMonType, fbId, scenId,pFuben, pEntity, pKiller)
    end
end

function OnAttackedEvent(fbId, fbEnterType, pFuben, scenId, pEntity, pAttacker)
    -- 检查活动副本内实体收到攻击
    if IsActivityFuben(pFuben) then
        local cacheData = GetCacheData(pFuben)
        ActivityDispatcher.CheckFubenEntityAttacked(cacheData.atvType, cacheData.atvId, pFuben, pEntity, pAttacker, Actor.getActorById(cacheData.ownerId))
    end
    if IsMonFuben(pFuben) then
        local cacheData = GetCacheData(pFuben)
        MonDispatcher.CheckFubenEntityAttacked(cacheData.nMonType, fbId, scenId, pFuben,pEntity, pAttacker)
    end
end

function OnTimeoutEvent(fbId, fbEnterType, pFuben)
    -- 超时设置踢出时间，如果需要的话
    local FubenConf = StaticFubens[fbId]
    if FubenConf then
        local cacheData = GetCacheData(pFuben)
        --第二次超时，则表示踢出了
        if not cacheData.kickFlag then
            Fuben.setFbTime(pFuben, FubenConf.kickTime or 12)
            cacheData.kickFlag = 1

            --若副本没成功，超时就表示失败了
            if not cacheData.result then
                cacheData.result = 0
            end

            -- 检查活动副本结束
            CheckActivityFubenFinish(pFuben)
        elseif cacheData.kickFlag then
            Fuben.ExitAllFbActor(pFuben)
        end
    end
end


function SetFubenTimeout(fbId, pFuben)
    -- 超时设置踢出时间，如果需要的话
    local FubenConf = StaticFubens[fbId]
    if FubenConf then
        local cacheData = GetCacheData(pFuben)
        if not cacheData.kickFlag then
            Fuben.setFbTime(pFuben, FubenConf.kickTime or 12)
            cacheData.kickFlag = 1

            --若副本没成功，超时就表示失败了
            if not cacheData.result then
                cacheData.result = 0
            end
        end
    end
end

function ClearFubenTimeout(fbId, pFuben)
    -- 超时设置踢出时间，如果需要的话
    local FubenConf = StaticFubens[fbId]
    if FubenConf then
        local cacheData = GetCacheData(pFuben)
        if cacheData then
            Fuben.setFbTime(pFuben,0)
            cacheData.kickFlag = nil
            cacheData.result = nil
        end
    end
end

function OnGetAwardEvent(fbId, fbEnterType, pFuben, nSceneId, pActor)
    -- 检查活动副本结算请求
    if IsActivityFuben(pFuben) then
        local cacheData = GetCacheData(pFuben)
        ActivityDispatcher.CheckFubenAward(cacheData.atvType, cacheData.atvId, pFuben, pActor, Actor.getActorById(cacheData.ownerId))
    end
end

function OnEvent(evId, fbType, fbId, fbEnterType, ...)
    
    if evId == FubenEvent.OnCreate then --副本创建
        OnCreateEvent(fbId, fbEnterType, ...)
    elseif evId == FubenEvent.OnEnter then --实体进入副本
        OnEnterEvent(fbId, fbEnterType, ...)
    elseif evId == FubenEvent.OnExit then --实体退出副本
        OnExitEvent(fbId, fbEnterType, ...)
    elseif evId == FubenEvent.OnDeath then --副本实体死亡
        OnEntityDeathEvent(fbId, fbEnterType, ...)
    elseif evId == FubenEvent.OnAttacked then --实体收到攻击
        OnAttackedEvent(fbId, fbEnterType, ...)
    elseif evId == FubenEvent.OnTimeout then --副本超时
        OnTimeoutEvent(fbId, fbEnterType, ...)
    elseif evId == FubenEvent.OnGetAward then --获取副本奖励
        OnGetAwardEvent(fbId, fbEnterType, ...)
    end

    --获取回调
    local callbacks = dispatcher[evId]
    if callbacks == nil or callbacks[fbType] == nil then
        return true
    end
    local func = callbacks[fbType];

    --回调调用
    if evId == FubenEvent.OnCheckEnter then --副本进入检查
        return func(fbId, fbEnterType, ...)
    else
        func(fbId, fbEnterType, ...)
    end
    return true
end

-- 玩家死亡回调，用以发送复活信息
function OnActorDeath(pActor, pFuben)
    --if Actor.getReliveTimeOut(pActor) == 0 then
        local fbId = Fuben.getFubenIdByPtr(pFuben)
        local ConfId = (StaticFubens[fbId] and StaticFubens[fbId].reliveConfId) or 1
        local ReliveConf = ReliveConfig[ConfId] or ReliveConfig[1]
        local aid = Actor.getActorId(pActor)
        local cacheData = GetCacheData(pFuben)
        if not cacheData.relive then cacheData.relive = {} end
        if not cacheData.relive[aid] then
            cacheData.relive[aid] = ReliveConf.limit or -1
        end
        local reliveCount = cacheData.relive[aid]

        -- 维护次数
        if reliveCount > 0 then
            cacheData.relive[aid] = reliveCount - 1
        elseif reliveCount == 0 then
            Actor.clearReliveTimeOut(pActor)
            local maxhp = Actor.getIntProperty(pActor,PROP_CREATURE_MAXHP)
            Actor.changeHp(pActor, maxhp)
            local maxmp = Actor.getIntProperty(pActor,PROP_CREATURE_MAXMP)
            Actor.changeMp(pActor, maxmp)
            local atvId = GetActivityId(pFuben);
            local atvType = GetActivityType(pFuben);
            ActivityDispatcher.OnEvent(ActivityEvent.OnAtvGG, atvType, atvId, pActor);
            Actor.exitFubenAndBackCity(pActor)
            --Actor.addState(pActor, esStateDeath)
            --Actor.updateActorEntityProp(pActor)
            --Actor.removeState(pActor, esStateDeath)
            --Actor.updateActorEntityProp(pActor)
            cacheData.relive[aid] = nil
            return
        end

        -- 设置自动复活时间
        -- 复活特权
		local nCurReviveDuration = Actor.getIntProperty2(pActor, PROP_ACTOR_CURREVIVEDURATION);
        if nCurReviveDuration ~= 0 then
            Actor.setReliveTimeOut(pActor, (ReliveConf.VipRevive or 5))
        else
            Actor.setReliveTimeOut(pActor, (ReliveConf.expire or 10))
        end

        -- 通知死亡复活框
        local npack = DataPack.allocPacket(pActor, enDefaultEntitySystemID, sActorReliveInfo)
        if npack then
            DataPack.writeByte(npack, ConfId)
            DataPack.writeByte(npack, reliveCount)
            local count = (ReliveConf.selectInfo and #ReliveConf.selectInfo) or 0
            DataPack.writeByte(npack, count)
            local actorData = GetActorData(pActor, fbId)
            if actorData.relive == nil then
                actorData.relive = {}
            end
            if count > 0 then
                for i=1,count do
                    if actorData.relive[i] == nil then
                        actorData.relive[i] = ReliveConf.selectInfo[i].limit or -1
                    end
                    DataPack.writeByte(npack, actorData.relive[i])
                end
            end
            
            -- 添加击杀者名字
            local h_killer = Actor.getKillHandle(pActor)
            local pKiller = Actor.getEntity(h_killer)
            local name = ""
            if pKiller then
                name = Actor.getName(pKiller)
            end
            DataPack.writeString( npack, name )
            DataPack.flush(npack)
        end
    --end
end

-- 复活选项
function OnClickReqRelive (pActor, packet)  
	local confId = DataPack.readByte(packet)
    local idx = DataPack.readByte(packet) + 1

	--获取当前副本复活配置
	local pFuben = Actor.getFubenPrt(pActor)
	local fbId = Fuben.getFubenIdByPtr(pFuben)
	local ConfId = (StaticFubens[fbId] and StaticFubens[fbId].reliveConfId) or 1
	local ReliveConf = ReliveConfig[ConfId] or ReliveConfig[1]

	--配置id验证
	if confId ~= ConfId then
		return
	end

	--复活选项配置
	local selectInfo = ReliveConf.selectInfo[idx]
	if selectInfo then

		--消耗检查
		local consumes = {}
		if selectInfo.consume then
			table.insert( consumes, selectInfo.consume )
			if CommonFunc.Consumes.Check(pActor, consumes) ~= true then
				Actor.sendTipmsg(pActor, "|C:0xf56f00&T:道具或金币元宝不足!|", tstEcomeny)
				return
			end
		end

        --次数检查
        if selectInfo.limit and selectInfo.limit > 0 then
            local actorData = GetActorData(pActor, fbId)
            
            if actorData.relive[idx] == nil then
                actorData.relive[idx] = selectInfo.limit
            else
                if actorData.relive[idx] == 0 then
                    Actor.sendTipmsg(pActor, "超过次数了！"..actorData.relive[idx].."/"..selectInfo.limit, tstUI)
                    return
                end
                actorData.relive[idx] = actorData.relive[idx] - 1
            end
        end

        -- 消耗
        if consumes and CommonFunc.Consumes.Remove(pActor, consumes,GameLog.Log_Relive , "复活") ~= true then
            return
        end

        --回血回蓝
        local maxhp = Actor.getIntProperty(pActor,PROP_CREATURE_MAXHP)
        Actor.changeHp(pActor, maxhp * ((selectInfo.hp or 100)/100))
        local maxmp = Actor.getIntProperty(pActor,PROP_CREATURE_MAXMP)
        Actor.changeMp(pActor, maxmp * ((selectInfo.mp or 100)/100))

        -- 原地复活
        if selectInfo.type == 1 then
        -- 随机复活
        elseif selectInfo.type == 2 then
            System.telportRandPos(pActor)
        -- 副本固定点复活
        elseif selectInfo.type == 3 then
            if ReliveConf.FixedPosi then
                local sceneId = Actor.getSceneId(pActor)
                Actor.enterScene(pActor, sceneId, ReliveConf.FixedPosi.x, ReliveConf.FixedPosi.y)
            else
                Actor.relive(pActor)
            end
        -- 回城安全区复活
        elseif selectInfo.type == 4 or selectInfo.type == 6 then
            if Fuben.isFuben(pFuben) then
                Actor.exitFubenAndBackCity(pActor)
            else
                Actor.relive(pActor)
            end
        -- 本方阵营复活
        elseif selectInfo.type == 5 then
            
            
        end

        --清除复活倒计时
        Actor.clearReliveTimeOut(pActor)
        Actor.onRelive(pActor)
        TranRedActorToRedSceen(pActor)
        --Actor.removeState(pActor, esStateDeath)
        --Actor.updateActorEntityProp(pActor)
	end
end

NetmsgDispatcher.Reg(enDefaultEntitySystemID, cChooseRelive, OnClickReqRelive)

--------------------------------------------------------------------
-- 活动副本回调
--------------------------------------------------------------------

-- 映射副本跟活动的对应关系
function MapToActivity(pFuben, atvType, atvId)
    if atvType then
        local fbCacheData = FubenDispatcher.GetCacheData(pFuben)
        if fbCacheData.atvType == nil then
            fbCacheData.atvId = atvId
            fbCacheData.atvType = atvType
            local atvCacheData = ActivityDispatcher.GetCacheData(atvId)
            atvCacheData.fbHandle = Fuben.getFubenHandle(pFuben)
        end
    end
end

-- 映射副本跟Monster的对应关系
function MapToMonster(pFuben, nMonType, nSerial)
    if nMonType then
        local fbCacheData = FubenDispatcher.GetCacheData(pFuben)
        if fbCacheData.nMonType == nil then
            fbCacheData.nMonType = nMonType
            fbCacheData.nSerial = nSerial
        end
    end
end

-- 检查活动副本结束
function CheckActivityFubenFinish(pFuben)
    if IsActivityFuben(pFuben) then
        local cacheData = GetCacheData(pFuben)
        ActivityDispatcher.CheckFubenFinish(cacheData.atvType, cacheData.atvId, pFuben, cacheData.result, Actor.getActorById(cacheData.ownerId))
    end
    if IsMonFuben(pFuben) then
        local cacheData = GetCacheData(pFuben)
        MonDispatcher.CheckFubenFinish(cacheData.nMonType, pFuben, cacheData.result, Actor.getActorById(cacheData.ownerId))
    end
end
