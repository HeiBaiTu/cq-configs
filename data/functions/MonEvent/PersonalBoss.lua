module("PersonalBoss", package.seeall)
BossConfig = BossConfig
--[[
    个人数据：ActorData[]
    {
        
    }

    全局数据：GlobalData
    {

    }
]]--
MonTabType = 9; --
--对应的活动配置
if BossConfig == nil then
    assert(false)
end

--退出副本
function OnExitFuben(nFdId,pFuben, nSceneId, pActor)
    -- 通关后才消耗门票跟次数
    if FubenDispatcher.GetReault(pFuben) == 1 then
        local fbcache = FubenDispatcher.GetCacheData(pFuben)
        -- local Cfg = ShenZhuangBossConfig
        -- if Cfg then
            -- 补充退出结算
        OnReqFubenAward(pFuben, pActor, pActor)
        if fbCacheData then
            fbCacheData.ownerId = 0
        end
       
            -- 消耗次数
            -- Actor.addStaticCount(pActor, Cfg.pid,-1);
        -- end
    end
end

--活动请求结算
function OnReqFubenAward(pFuben, pActor, pOwner)
    -- 单人副本活动，所有者必须为自己
    if pOwner == pActor then
        if FubenDispatcher.GetReault(pFuben) == 1 then
            local fbcache = FubenDispatcher.GetCacheData(pFuben)
            local cfg = getRealCfg((fbcache.nSerial or 0))
            if not fbcache.hasGetAward  then
                --邮件发送奖励
                local data = MonDispatcher.GetActorData(pActor,cfg.fbid)
                if cfg and cfg.firstprize and data.isFirst == nil then
                    local actorId = Actor.getIntProperty( pOwner, PROP_ENTITY_ID )
                    local monsterName = System.getMonsterNameById(cfg.entityid);
                    local title = string.format("%s首杀奖励！", monsterName)
                    local content = string.format("恭喜您首杀%s，以下是给您的奖励，请接收！", monsterName)
                    SendMail(actorId, title, content, cfg.firstprize)
                    data.isFirst = 1;
                    -- Actor.addStaticCount(pActor, cfg.pid,-1);
                end
                fbcache.hasGetAward = 1
                if cfg then
                    Actor.addStaticCount(pActor, cfg.staticType,-1);
                    Actor.SendSzBossTimes(pActor);
                end
            end
        end
    end
end

--活动副本结束
function OnFubenFinish(pFuben, result, pOwner)
    --发送成功失败的旗帜
    if pOwner then
        if FubenDispatcher.GetReault(pFuben) == 1 then
            local fbcache = FubenDispatcher.GetCacheData(pFuben)
            local Cfg = getRealCfg((fbcache.nSerial or 0))
            if not fbcache.hasGetAward  then
                --邮件发送奖励
                if Cfg then
                    local data = MonDispatcher.GetActorData(pOwner,Cfg.fbid)
                    if Cfg.firstprize and data.isFirst == nil then
                        local actorId = Actor.getIntProperty( pOwner, PROP_ENTITY_ID )
                        local monsterName = System.getMonsterNameById(Cfg.entityid);
                        local title = string.format("%s首杀奖励！", monsterName)
                        local content = string.format("恭喜您首杀%s，以下是给您的奖励，请接收！", monsterName)
                        SendMail(actorId, title, content, Cfg.firstprize)
                        data.isFirst = 1;
                    end
                    Actor.addStaticCount(pOwner, Cfg.staticType,-1);
                    Actor.SendSzBossTimes(pOwner);
                    ---处理超时
                    FubenDispatcher.SetFubenTimeout(Cfg.fbid, pFuben);
                    Actor.sendTipmsgWithId(pOwner, tmChallengBossSucess, tstUI)
                end
                fbcache.hasGetAward = 1
            end
        end
    end
end


function getRealCfg(nSerial)
    local data = nil
    for _, cfg in pairs(BossConfig) do
        if cfg.Serial == nSerial then
            data = cfg
            break
        end
    end
    return data
end

--记录参与奖的玩家
function OnReqEnterFuben(pActor, nFubenId, nSerial)
    --进入副本
    return MonDispatcher.EnterMonFuben(MonTabType, pActor, nFubenId, nSerial)
end

MonDispatcher.Reg(MonEvent.OnExitFuben, MonTabType, OnExitFuben, "PersonalBoss.lua")
MonDispatcher.Reg(MonEvent.OnFubenFinish, MonTabType, OnFubenFinish, "PersonalBoss.lua")
MonDispatcher.Reg(MonEvent.OnReqEnterFuben, MonTabType, OnReqEnterFuben, "PersonalBoss.lua")
--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 跨天，次数清零
function OnNewDayArrive(pActor, ndiffday)
    local openday = System.getDaysSinceOpenServer()
    local Cfg = ShenZhuangBossConfig
    if Cfg then
        local times = 0;
        if openday >= Cfg.popenday then
            local day = Actor.getStaticCount(pActor, Cfg.pid+1);

            if day == 0 then
                day = Cfg.popenday-1;
            end
            ndiffday = openday - day
            if ndiffday > 0 then
                times = Cfg.ptimes * ndiffday;
                -- print("times.."..times)
                Actor.addStaticCount(pActor, Cfg.pid, times)
                Actor.setStaticCount(pActor, Cfg.pid+1, openday)
            end
           
        end
    end
end
ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "PersonalBoss.lua")
