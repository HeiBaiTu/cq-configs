module("ActivityDispatcher", package.seeall)
--[[
    个人数据：ActorData[AtvId]
    {
        openTimes,  该全局活动的参与标记
    }

    全局数据：GlobalData[AtvId]
    {
        openTimes,  该全局活动的开启次数
    }

    缓存数据：CacheData[atvId]
    {
        fbHandle,   当前活动的副本句柄
    }
]]--
local dispatcher = { }

_G.ActivityEvent =
{
    OnLoad          = 1,        --活动加载        [活动id]              注意：若为个人活动，传入 '玩家指针'
    OnInit          = 2,        --活动初始化      [活动id，玩家指针]    注意：用于处理再次开启的全局活动（同一活动id），重置初始化旧数据
    OnStart         = 3,        --活动开始        [活动id]              注意：若为个人活动，传入 '玩家指针'
    OnEnd           = 4,        --活动结束        [活动id]              注意：若为个人活动，传入 '玩家指针'
    OnUpdate        = 5,        --活动帧更新      [活动id，当前时间]    注意：若为个人活动，传入 '玩家指针'
    OnReqData       = 6,        --请求活动数据    [活动id, 玩家指针, outPack]
    OnOperator      = 7,        --通用操作        [活动id，玩家指针，inPack]
    OnEnterArea     = 8,        --进入活动区域    [活动id, 玩家指针]
    OnExitArea      = 9,        --离开活动区域    [活动id, 玩家指针]
    OnEnterFuben    = 10,       --玩家进入活动副本[活动id，玩家指针，副本指针, pOwner]
    OnExitFuben     = 11,       --玩家离开活动副本[活动id，玩家指针，副本指针, pOwner]
    OnEntityDeath   = 12,       --副本实体死亡    [活动id, 被杀者指针，击杀者指针，副本指针, pOwner]
    OnEntityAttacked= 13,       --活动副本实体受击[活动id, 副本指针，受击者，攻击者, pOwner]
    OnFubenFinish   = 14,       --活动副本结束    [活动id, 副本指针，结果, pOwner] 1为完成，0为失败，nil则结果未知（需要对应副本设置结果）
    OnReqFubenAward = 15,       --请求副本结算    [活动id, 副本指针，pActor, pOwner]
    OnGetRedPoint   = 16,       --请求红点数据    [活动id, 玩家指针] 返回值为红点值
    OnLoginGame     = 17,       --登录游戏        [活动id，玩家指针] 活动登录事件   //登陆时活动如果开启会触发
    OnUpdateActivity= 18,       --更新数据        [活动id，玩家指针] 注意：若为个人活动，传入 '玩家指针'
    OnAtvAreaDeath  = 19,       --普通场景活动区域死亡   [活动id，玩家指针]
    OnCombineSrv    = 20,       --合服后首次登陆    [活动id，合服后的开服天数差值，玩家指针]  个人活动
    OnGPStart       = 21,       --全局个人活动的玩家Start  [活动id，玩家指针]  Global_Person_Activity
    OnGPEnd         = 22,       --全局个人活动的玩家End    [活动id，玩家指针] Global_Person_Activity
    OnAtvGG         = 23,       --活动复活结束    [活动id，玩家指针]
    OnAtvAreaAtk    = 24,       --普通场景活动区域实体受击     [活动id，受击者，攻击者]
    OnOnAtvRank     = 25,       --活动排行榜      [活动id，当前时间]
    Count           = 26,
}

--通用操作协议枚举
_G.ActivityOperate = {
    cEnterFuben = 1,     --请求进入副本
    cGetPhaseAward = 2,  --请求领取阶段奖励
    cWorship = 3,        --请求膜拜操作
    cAppraisal = 4,      --请求鉴定操作
    cGetPersonBox = 5,    --请求个人奖励      --npc活动
    cGetTreasure = 6,    --送宝、排名奖励     --npc活动  
    cGetBonusNum = 7,     --npc请求剩余奖励数量  --独闯天涯
    cInspire = 8,        --鼓舞             --boss
    cGetMonsterNum = 9,   --npc请求当前杀怪数 --独闯天涯
    cReqAtvQianDao  = 10,  --打卡活动，请求打卡
    cReqLeijichongzhiGift = 11, --请求领取累计充值奖励 --累计充值活动
    cReqPurchaseGiftbag   = 12, --请求购买特惠礼包/领取首冲奖励/七天登录领奖/打卡活动领奖
    cReqPurchaseJiJin     = 13, --请求购买基金
    cReqGetJiJinAward     = 14, --请求领取基金奖励
    cReqGetAchieveAward   = 15, --请求达标类对应奖励
    cReqSaoDang           = 16, --扫荡
    cReqXunBao            = 17, --寻宝  抽奖活动（开服特定寻宝）
    cActiveOrderWar       = 18, --激活战令
    cBuyOrderWarLv        = 19, --购买战令等级
    cDeleteItem           = 20, --删除道具
    cGetAllAward          = 21, --战令一键领取
    cGetZLAward           = 22, --战令领取
    cGetQuestAward        = 23, --任务领取
    cDonateRank           = 24, --捐献
    cReqExchange          = 25, --兑换
    cZLShopInfo           = 26, --战令商店
    cBuyZLShop            = 27, --购买战令数据
    cCheckCSActivity      = 28, --跨服入口支持
  

    sSendRankData = 1,    --广播排行数据    -- 竞技大乱斗
    sSendMyRankData = 2,  --发送自己的排行数据 -- 竞技大乱斗
    sSendPhaseAward = 3,  --发送奖励内容
    sEnterFubenResult = 4,--进入活动副本的结果回复
    sWorship = 5,        --回复膜拜操作
    sAppraisal = 6,      --回复鉴定操作
    sNextAwardIndex = 7, --下一个奖励的索引
    sSendPersonBox = 8,  --回复个人奖励请求     --npc活动
    sSendBigTreasure = 9, --回复送宝、排名奖励  --NPC活动
    sSendTime = 10,       --发送时间
    sSendBonusNum = 11,     --回复剩余奖励数量      --独闯天涯
    sInspire  = 12,       --返回鼓舞id          --boss
    sSendMonsterNum = 13,   --回复npc请求当前杀怪数  --独闯天涯
    sSendAssignCampTime =14, --发送阵营调整时间     --沃玛三
    sSendActorDataTimes = 15,  --回复玩家数据      --累计充值活动灰按钮/特惠礼包活动回复玩家参与次数
    sSendChouJiangResult = 16, --回复寻宝/抽奖结果       --寻宝活动
    sSendzhushoustatus   = 17, --回复驻守开始
    sSendWorldBossTime   = 18, --世界boss 剩余时间
    sDuoBaoPickLeftTime   = 19, --夺宝 剩余时间
    sZLShopInfo   = 20, --战令商店
    sZLBuyShop   = 21, --购买战令商品
    sZLShopChange   = 22, --战令商品发生变化
    sCSSBKGuildRank   = 23, --前四名跨服沙巴克排行
    sCSSBKMyGuildRank   = 24, --个人工会排名
    sCSSBKMyRank   = 25, --个人排名
    sCheckCSActivity      = 28, --跨服入口支持
}

--------------------------------------------------------------------
-- Lua接口
--------------------------------------------------------------------

-- @brief 注册事件分发器
-- @param evId 事件id
-- @param atvType 活动类型
-- @param func 回调
function Reg(evId, atvType, func, file)

    --参数检查
	if atvType == nil or evId == nil or func == nil or file == nil then 
		print( debug.traceback() )
		assert(false)
    end
    
    --事件范围检查
    if evId <= 0 or evId >= ActivityEvent.Count then
        assert(false)
    end

    --回调表初始化
    if dispatcher[evId] == nil then
        dispatcher[evId] = {}
    end
    if dispatcher[evId][atvType] ~= nil then
        assert(false) -- 重复注册了
    end

    --注册
    dispatcher[evId][atvType] = func
    print("[TIP][ActivityDispatcher] Add Activity(Type:"..atvType..") Event("..evId..") In File("..file.."), And Index="..table.maxn(dispatcher[evId]))
end

-- @brief 获取某个活动的全局数据（这个数据，是存文件的）
-- @param atvId 活动id
function GetGlobalData(atvId)
    if atvId == nil then
        assert(false)
    end
    local var = System.getStaticVar();
    if var.Activity == nil then
        var.Activity = {}
    end

    if var.Activity[atvId] == nil then
        var.Activity[atvId] = {}
    end

    return var.Activity[atvId]
end

-- @brief 清空某个活动的全局数据（这个数据，是存文件的）
-- @param atvId 活动id
function ClearGlobalData(atvId)
    if atvId == nil then
        assert(false)
    end
    local var = System.getStaticVar();
    if var.Activity == nil then
        var.Activity = {}
    end
    if var.Activity[atvId] then
        var.Activity[atvId] = nil
    end
end

-- @brief 获取某个活动的缓存数据（这个数据，不存储仅缓存）
-- @param fbId 活动id
function GetCacheData(atvId)
    if atvId == nil then
        assert(false)
    end
    local var = System.getDyanmicVar();
    if var.Activity == nil then
        var.Activity = {}
    end

    if var.Activity[atvId] == nil then
        var.Activity[atvId] = {}
    end

    return var.Activity[atvId]
end

-- @brief 清空某个活动的缓存数据（这个数据，不存储仅缓存）
-- @param fbId 活动id
function ClearCacheData(atvId)
    if atvId == nil then
        assert(false)
    end
    local var = System.getDyanmicVar();
    if var.Activity == nil then
        var.Activity = {}
    end
    if var.Activity[atvId] then
        var.Activity[atvId] = nil
    end
end

-- @brief 获取某个活动的个人数据（这个数据，是存数据库的）
-- @param atvId 活动id
function GetActorData(pActor, atvId)
    if atvId == nil or Actor.getEntityType(pActor) ~= enActor then
        assert(false)
    end
    local var = Actor.getStaticVar(pActor);
    if var.Activity == nil then
        var.Activity = {}
    end
    if var.Activity[atvId] == nil then
        var.Activity[atvId] = {}
    end

    return var.Activity[atvId]
end

-- @brief 清空某个活动的个人数据（这个数据，是存数据库的）
-- @param atvId 活动id
function ClearActorData(pActor, atvId)
    if atvId == nil or Actor.getEntityType(pActor) ~= enActor then
        assert(false)
    end
    local var = Actor.getStaticVar(pActor);
    if var.Activity == nil then
        var.Activity = {}
    end
    if var.Activity[atvId] then
        local openTimes = var.Activity[atvId].openTimes
        var.Activity[atvId] = {}
        var.Activity[atvId].openTimes = openTimes
    end
end

-- @brief 分配一个通用旗帜结果包，需要外部自己调用flush方法
-- @note result 0失败 1成功
function AllocResultPack(pActor, atvId, result)
    local npack = DataPack.allocPacket(pActor, enActivityID, SActivityResult)
    if npack then
        DataPack.writeUInt(npack, atvId)
        DataPack.writeByte(npack, (result or 0))
    end
    return npack
end

-- @brief 分配一个通用旗帜结果包（注意：这是广播包），需要外部自己调用FreePacketEx释放包
function AllocResultPackEx(atvId, result)
    local npack = DataPack.allocPacketEx()
    if npack then
        DataPack.writeUInt(npack, atvId)
        DataPack.writeByte(npack, (result or 0))
    end
    return npack
end

-- @brief 分配一个通用回复包，需要外部自己调用flush方法
function AllocOperReturn(pActor, atvId, operaCode)
    local npack = DataPack.allocPacket(pActor, enActivityID, sActivityOperator)
    if npack then
        DataPack.writeUInt(npack, atvId)
        DataPack.writeByte(npack, operaCode)
    end
    return npack
end

-- @brief 分配一个通用回复包（注意：这是广播包），需要外部自己调用FreePacketEx释放包
function AllocOperReturnEx(atvId, operaCode)
    local npack = DataPack.allocPacketEx()
    if npack then
        DataPack.writeByte(npack,enActivityID)
        DataPack.writeByte(npack,sActivityOperator)
        DataPack.writeUInt(npack,atvId)
        DataPack.writeByte(npack,operaCode)
    end
    return npack
end

-- @brief 释放一个通用回复（注意：这是广播包）
function FreePacketEx(npack)
    if npack then
        DataPack.freePacketEx(npack)
    end
end

-- @brief 进入活动副本
function EnterFuben(atvId,pActor,fbId)
    local result = Actor.reqEnterFuben(pActor, fbId)
    if result then

        -- 回复活动id与副本句柄的关联
        local npack = AllocOperReturn(pActor, atvId, ActivityOperate.sEnterFubenResult)
        if npack then
            DataPack.flush(npack)
        end

        -- 建立副本类型跟活动类型的对应关系
        local fbHandle = Actor.getFubenHandle(pActor)
        local pFuben = Fuben.getFubenPtrByHandle(fbHandle)
        local atvType = 0
        if (ActivitiesConf[atvId] and ActivitiesConf[atvId].ActivityType) then
            atvType = ActivitiesConf[atvId].ActivityType
        elseif (PActivitiesConf[atvId] and PActivitiesConf[atvId].ActivityType) then
            atvType = PActivitiesConf[atvId].ActivityType
        end
        FubenDispatcher.MapToActivity(pFuben, atvType, atvId)

        return fbHandle
    end
    return nil
end

-- @brief 通过活动id获取对应副本
-- @param atvId 活动id
-- @return 副本指针
function GetFuben(atvId)
    local atvCacheData = GetCacheData(atvId)
    local fbHandle = atvCacheData.fbHandle
    if fbHandle then
        local pFuben = Fuben.getFubenPtrByHandle(fbHandle)
        if pFuben then
            local nAtvId = FubenDispatcher.GetActivityId(pFuben)
            if nAtvId == atvId then
                return pFuben
            end
        end
    end
end

-- @brief 发送活动弹框
-- @param pActor 玩家指针
-- @param atvId 活动id
function SendPopup(pActor, atvId)
    local npack = DataPack.allocPacket(pActor, enActivityID, SActivityPopup)
    if npack then
        DataPack.writeUInt(npack, atvId)
        DataPack.flush(npack)
    end
end

-- @brief 广播活动弹框
-- @param atvId 活动id
-- @param fbHandle 副本句柄
-- @param sceneId 场景id
function BroadPopup(atvId)
    --等级 转生限制
    local lv = 0;
    local zsLv = 0;
    local Cfg = ActivitiesConf[atvId];
    if Cfg then
        if Cfg.TipsLevelLimit then
            lv = Cfg.TipsLevelLimit.level
            zsLv = Cfg.TipsLevelLimit.zsLevel
        end
    end
    local npack = DataPack.allocPacketEx()
    if npack then
        DataPack.writeByte(npack,enActivityID)
        DataPack.writeByte(npack,SActivityPopup)
        DataPack.writeUInt(npack,atvId)

        DataPack.broadcasetWorld(npack, lv, zsLv)
        DataPack.freePacketEx(npack)
    end
end

--------------------------------------------------------------------
-- CPP回调
--------------------------------------------------------------------

function CheckInitActivity(atvType, atvId, pActor)
    local globalData = GetGlobalData(atvId)
    local actorData = GetActorData(pActor, atvId)
    if globalData.openTimes ~= actorData.openTimes then
        local callbacks = dispatcher[ActivityEvent.OnInit]
        if callbacks[atvType] then
            local func = callbacks[atvType]
            func(atvId, pActor)
        end
        actorData.openTimes = globalData.openTimes
        print("[全局活动id"..atvId.."初始化] 重置开启次数:"..(globalData.openTimes or 0).." 玩家："..Actor.getName(pActor))
    end
end

function CheckReqData(func, atvType, atvId, pActor, outPack)
    --print("[Activity"..atvType.."."..atvId.."] "..Actor.getName(pActor).." 请求活动数据!")

    -- 红点值
    local val = 0
    local callbacks = dispatcher[ActivityEvent.OnGetRedPoint]
    if callbacks and (callbacks[atvType] ~= nil) then
        local result = callbacks[atvType](atvId, pActor)
        val = result or 0
    end
    DataPack.writeByte(outPack, val)

    -- 活动详细数据
    if func then
        func(atvId, pActor, outPack)
    end
end

function OnEvent(evId, atvType, atvId, ...)
    
    --获取回调
    local callbacks = dispatcher[evId]

    --回调调用
    if evId == ActivityEvent.OnLoad then --活动加载（数据库来的）
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnStart then --活动开启
        -- 周循环活动，需要记录开启次数
        if ActivitiesConf[atvId] then
            local globalData = GetGlobalData(atvId)
            if globalData.openTimes == nil then
                local currentId = System.getCurrMiniTime();
                globalData.openTimes = currentId
            else
                globalData.openTimes = globalData.openTimes + 1
            end
            print("[全局活动id"..atvId.."开始] 记录开启次数:"..globalData.openTimes)
        end
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnEnd then --活动结束
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnUpdate then --活动帧更新
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnReqData then --请求活动数据
        if ActivitiesConf[atvId] then
            CheckInitActivity(atvType, atvId, ...)
        end
        local func = nil
        if callbacks and (callbacks[atvType] ~= nil) then
            func = callbacks[atvType];
        end
        CheckReqData(func, atvType, atvId, ...)
    elseif evId == ActivityEvent.OnOperator then --通用操作
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnEnterFuben then --玩家进入活动副本
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnExitFuben then --玩家退出活动副本
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnEntityDeath then --副本实体死亡
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnEnterArea then --进入活动区域
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnExitArea then --离开活动区域
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnEntityAttacked then --活动副本实体受击
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnFubenFinish then --活动副本结束
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId ==  ActivityEvent.OnAtvAreaDeath then --普通场景活动区域死亡
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId ==  ActivityEvent.OnAtvAreaAtk then --普通场景活动区域死亡
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnLoginGame then --登录相关
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnUpdateActivity then --更新
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnCombineSrv then --合服
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnGPStart then --全局个人的开始
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnGPEnd then --全局个人的结束
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnOnAtvRank then --全局个人的结束
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    elseif evId == ActivityEvent.OnAtvGG then --全局个人的结束
        if callbacks and (callbacks[atvType] ~= nil) then
            local func = callbacks[atvType];
            func(atvId, ...)
        end
    end

    return true
end

--------------------------------------------------------------------
-- 活动副本回调
--------------------------------------------------------------------

function CheckEnterFuben(atvType, atvId, pFuben, pEntity, pOwner)
    -- 玩家指针（个人活动判断需要一个玩家指针）
    local pActor = nil
    if Actor.getEntityType(pOwner) == enActor then
        pActor = pOwner
    elseif Actor.getEntityType(pEntity) == enActor then
        pActor = pEntity
    elseif Actor.getEntityType(pEntity) == enPet then
        pActor = Actor.getMaster(pEntity)
    else
        return
    end

    -- 触发玩家进入活动副本事件
    if Actor.isActivityRunning(pActor,atvId) then
        if Actor.getEntityType(pEntity) == enActor then
            print("[Activity"..atvType.."."..atvId.."] [FbId="..Fuben.getFubenIdByPtr(pFuben).."]"..Actor.getName(pEntity).." 进入活动副本！")
            OnEvent(ActivityEvent.OnEnterFuben, atvType, atvId, pEntity, pFuben, pOwner)
        end
    end
end

function CheckExitFuben(atvType, atvId, pFuben, pEntity, pOwner)
    -- 玩家指针（个人活动判断需要一个玩家指针）
    local pActor = nil
    if Actor.getEntityType(pOwner) == enActor then
        pActor = pOwner
    elseif Actor.getEntityType(pEntity) == enActor then
        pActor = pEntity
    elseif Actor.getEntityType(pEntity) == enPet then
        pActor = Actor.getMaster(pEntity)
    else
        return
    end

    -- 触发玩家退出活动副本事件
    if Actor.isActivityRunning(pActor,atvId) then
        if Actor.getEntityType(pEntity) == enActor then
            print("[Activity"..atvType.."."..atvId.."] [FbId="..Fuben.getFubenIdByPtr(pFuben).."]"..Actor.getName(pEntity).." 退出活动副本！")
            OnEvent(ActivityEvent.OnExitFuben, atvType, atvId, pEntity, pFuben, pOwner)
        end
    end
end

function CheckFubenEntityDeath(atvType, atvId, pFuben, pEntity, pKiller, pOwner)
    -- 玩家指针（个人活动判断需要一个玩家指针）
    local pActor = nil
    if Actor.getEntityType(pOwner) == enActor then
        pActor = pOwner
    elseif Actor.getEntityType(pEntity) == enActor then
        pActor = pEntity
    elseif Actor.getEntityType(pKiller) == enActor then
        pActor = pKiller
    elseif Actor.getEntityType(pEntity) == enPet then
        pActor = Actor.getMaster(pEntity)
    elseif Actor.getEntityType(pKiller) == enPet then
        pActor = Actor.getMaster(pKiller)
    else
        return
    end

    -- 触发活动副本实体死亡事件
    if Actor.isActivityRunning(pActor,atvId) then
        -- if pFuben and pEntity and pKiller then
        --     print("[Activity"..atvType.."."..atvId.."] [FbId="..Fuben.getFubenIdByPtr(pFuben).."]"..Actor.getName(pEntity).." 被 "..Actor.getName(pKiller).." 杀死！")
        -- end
        OnEvent(ActivityEvent.OnEntityDeath, atvType, atvId, pEntity, pKiller, pFuben, pOwner)
    end
end

function CheckFubenEntityAttacked(atvType, atvId, pFuben, pEntity, pAttacker, pOwner)
    -- 玩家指针（个人活动判断需要一个玩家指针）
    local pActor = nil
    if Actor.getEntityType(pOwner) == enActor then
        pActor = pOwner
    elseif Actor.getEntityType(pEntity) == enActor then
        pActor = pEntity
    elseif Actor.getEntityType(pAttacker) == enActor then
        pActor = pAttacker
    elseif Actor.getEntityType(pEntity) == enPet then
        pActor = Actor.getMaster(pEntity)
    elseif Actor.getEntityType(pAttacker) == enPet then
        pActor = Actor.getMaster(pAttacker)
    else
        return
    end

    -- 触发活动副本实体受击事件
    if Actor.isActivityRunning(pActor,atvId) then
        --print("[Activity"..atvType.."."..atvId.."] [FbId="..Fuben.getFubenIdByPtr(pFuben).."]"..Actor.getName(pEntity).." 受到 "..Actor.getName(pAttacker).." 攻击！")
        OnEvent(ActivityEvent.OnEntityAttacked, atvType, atvId, pEntity, pAttacker, pFuben, pOwner)
    end
end

function CheckFubenFinish(atvType, atvId, pFuben, result, pOwner)
    -- 玩家指针（个人活动判断需要一个玩家指针）
    local pActor = nil
    if Actor.getEntityType(pOwner) == enActor then
        pActor = pOwner
    end

    -- 触发活动副本结束事件
    if Actor.isActivityRunning(pActor,atvId) then
        print("[Activity"..atvType.."."..atvId.."] [FbId="..Fuben.getFubenIdByPtr(pFuben).."]"..(Actor.getName(pOwner) or "").." 活动副本结束，结果为("..(result or 0)..")！")
        OnEvent(ActivityEvent.OnFubenFinish, atvType, atvId, pFuben, result, pOwner)
    end
end

function CheckFubenAward(atvType, atvId, pFuben, pActor, pOwner)
    -- 触发活动副本结算事件
    if Actor.isActivityRunning(pActor,atvId) then
        print("[Activity"..atvType.."."..atvId.."] [FbId="..Fuben.getFubenIdByPtr(pFuben).."]"..Actor.getName(pActor).." 请求副本结算！")
        OnEvent(ActivityEvent.OnReqFubenAward, atvType, atvId, pFuben, result, pOwner)
    end
end
