module("BossEvent10", package.seeall)
AwardBossConfig = BossConfig
--[[
    个人数据：ActorData[fubenId]
    {
        nextLoginTime 下次进入时间
    }

    全局数据：GlobalData
    {

    }

    缓存数据：CacheData[nSceneId]
    {
        fbHandle 
        scenHandle
        monster[monId] --怪物列表
        {
            monId --怪物id  
            BossId --bossId
            attack {} --攻击者id
            beLonglist {} --曾经归属者
            beLongId  --归属者id
        }
        canDelete ---当前副本可删除
        inFuben {} --副本人数
        monNum --boss数量
        
    }
]]--
MonsterType = 10; --往后递增
--对应的活动配置
if AwardBossConfig == nil then
    assert(false)
end

function OnInitialize(fubenId, nSceneId, nMonId)
    local fbHandle = nil
    if fubenId and fubenId > 0 then 
        fbHandle = Fuben.createFuBen(fubenId)
        MonDispatcher.InitScene(nSceneId);
        local pFuben = Fuben.getFubenPtrByHandle(fbHandle);
        FubenDispatcher.ClearFubenTimeout(fubenId,pFuben);
        -- MonDispatcher.EnterGlobalMonFuben(fbHandle, MonsterType, fubenId)
    else
        fbHandle = Fuben.getStaticFubenHandle();
    end
    if fbHandle then
        MonDispatcher.EnterGlobalMonFuben(fbHandle, MonsterType, fubenId)
        local scenHandle = Fuben.getSceneHandleById(nSceneId, fbHandle);
        if scenHandle then
            local cacheData = MonDispatcher.GetCacheData(fubenId);

            cacheData[nSceneId] = {}

            -- 初始化怪物
            if cacheData[nSceneId].monster == nil then
                cacheData[nSceneId].monster = {}
            end
            if fubenId > 0 then
                cacheData[nSceneId].canDelete = 1;
            end
            local nId = nMonId % 100000

            if cacheData[nSceneId].monster[nId] == nil then
                cacheData[nSceneId].monster[nId] = {}
            end
            if cacheData[nSceneId].monNum == nil then
                cacheData[nSceneId].monNum = 0
            end
            cacheData[nSceneId].monNum = cacheData[nSceneId].monNum + 1
            if cacheData[nSceneId].monster[nId].attack == nil then
                cacheData[nSceneId].monster[nId].attack = {};
            end

            cacheData[nSceneId].monster[nId].nMonId = nId
            cacheData[nSceneId].monster[nId].nBossId = nMonId
            cacheData[nSceneId].fbHandle = fbHandle
            cacheData[nSceneId].scenHandle = scenHandle
        end
    end
end

--发奖
function SendAward(nfdId, nSceneId, nBossId)
    -- local fdId = Fuben.getFubenIdByPtr(pFuben);
    local cacheData = MonDispatcher.GetCacheData(nfdId);
    if cacheData[nSceneId] == nil then
        return
    end
    if cacheData[nSceneId].monster == nil then
        return
    end

    if cacheData[nSceneId].monster[nBossId] == nil then
        return 
    end
    local bossData = cacheData[nSceneId].monster[nBossId]
    local awardCfg = getAwardCfg(nBossId)
    if awardCfg then
    --归属奖
        if bossData.beLongId and awardCfg.ascription then
            if cacheData[nSceneId].inFuben[bossData.beLongId] and cacheData[nSceneId].inFuben[bossData.beLongId] ~= 0 then
                SendCrossServerMail(bossData.beLongId, awardCfg.mailTitle, awardCfg.mailContent1, awardCfg.ascription);
                
                SendResult(bossData.beLongId, bossData.beLongId, awardCfg.ascription);
                
                --删除其他奖项
                local pActor = Actor.getActorById(bossData.beLongId);
                Actor.triggerAchieveEvent(pActor, nAchieveKillSZBoss, 1);
                Actor.triggerAchieveEvent(pActor, nAchieveGetSZBossAward, 1, 1);
                DealFightResult(pActor)
                if  bossData.attack and bossData.attack[bossData.beLongId] then
                    -- print("归属奖.."..bossData.beLongId)
                    bossData.attack[bossData.beLongId] = 0
                end

                if  bossData.beLonglist and bossData.beLonglist[bossData.beLongId] then
                    bossData.beLonglist[bossData.beLongId] = 0
                end
            end
        end
    --勇者奖 -- 
        if bossData.beLonglist and awardCfg.brave then
            for _, id in Ipairs(bossData.beLonglist) do
                -- print("勇者奖.."..id)
                if cacheData[nSceneId].inFuben[id] and cacheData[nSceneId].inFuben[id] ~= 0 then 
                    -- print("勇者奖.."..id)
                    if bossData.beLongId and bossData.beLongId ~= id then
                        SendCrossServerMail(id, awardCfg.mailTitle, awardCfg.mailContent2, awardCfg.brave);
                        
                        SendResult(bossData.beLongId, id, awardCfg.brave);
                    end
                    if  bossData.attack and bossData.attack[id] then
                        bossData.attack[id] = 0
                    end
                    local pActor = Actor.getActorById(id);
                    Actor.triggerAchieveEvent(pActor, nAchieveKillSZBoss, 1);
                    Actor.triggerAchieveEvent(pActor, nAchieveGetSZBossAward, 1, 2);
                    DealFightResult(pActor)
                end
               
            end
        end
        -- print("nfdId.."..nfdId.."..scene.."..nSceneId.."..nBossId.."..nBossId)
    ---参与奖
        local cacheData = MonDispatcher.GetCacheData(nfdId);
        if cacheData[nSceneId].inFuben and awardCfg.partake  then
            -- print("bbbb.."..bossData.attack[16781916])

            for i, actorId in Ipairs(cacheData[nSceneId].inFuben) do
                --print("参与奖.."..actorId)
                if actorId ~= 0 then
                    
                    -- local pActor1111 = Actor.getActorById(actorId);
                    -- local strName = Actor.getName(pActor1111);

                    if bossData.attack and bossData.attack[actorId] ~= 0 then
                        -- print("strName2222 : "..strName)
                        SendCrossServerMail(actorId, awardCfg.mailTitle, awardCfg.mailContent3, awardCfg.partake);

                        SendResult(bossData.beLongId, actorId, awardCfg.partake);
    
                        local pActor = Actor.getActorById(actorId);
                        Actor.triggerAchieveEvent(pActor, nAchieveKillSZBoss, 1);
                        Actor.triggerAchieveEvent(pActor, nAchieveGetSZBossAward, 1, 3);
                        DealFightResult(pActor)
                    else
                        -- print("strName3333 : "..strName)
                    end
                end
            end
        end
        
    end
end

--发送归属者名字和玩家获得的奖励
function SendResult(beLongId, actorId, awardTable)
    --print("SendResult : beLongId ", beLongId, " actorId : ", actorId)
    local pBeLongActor = Actor.getActorById(beLongId);
    if not pBeLongActor then
        --print("SendResult : not pBeLongActor")
        return
    end

    local pActor = Actor.getActorById(actorId);
    if not pActor then
        --print("SendResult : not pActor")
        return
    end

    if not awardTable or type(awardTable) ~= "table" then
        --print("SendResult : not awardTable or type(awardTable) ~= table")
        return
    end

    local pPacket = DataPack.allocPacket(pActor, enBossSystemID, sSendBossResult);
    if pPacket then
        --print("SendResult : pPacket")
        DataPack.writeString(pPacket, Actor.getName(pBeLongActor));
        local nCount = 0;
        for _, award1 in pairs(awardTable) do
            if award1 and type(award1) == "table" then
                nCount = nCount + 1
            end
        end
        DataPack.writeByte(pPacket, nCount);

        for i, award2 in pairs(awardTable) do

            local nAwardType = 0;
            local nAwardId = 0;
            local nAwardCount = 0;
            for key, value in pairs(award2) do
               if key == "type" then
                    nAwardType = value
               elseif key == "id" then
                    nAwardId = value
               elseif key == "count" then
                    nAwardCount = value
               end
            end

            --print("SendResult pPacket : ", nAwardType, nAwardId, nAwardCount)
            DataPack.writeUInt(pPacket, nAwardType);
            DataPack.writeUInt(pPacket, nAwardId);
            DataPack.writeUInt(pPacket, nAwardCount);
        end
        DataPack.flush(pPacket);
    end

end

function test(nSceneId, nBossId)
-- local title = "神装BOSS"
--     local content = "恭喜你在神装BOSS副本中获得参与奖！"
    -- print("bbbb.."..bossData.attack[16781916])
    local cacheData = MonDispatcher.GetCacheData(7);
    for i, actorId in Ipairs(cacheData[nSceneId].monster[nBossId].attack) do
        -- print("参与奖.."..actorId)
        -- if cacheData[nSceneId].inFuben[actorId] then 
        --     SendMail(actorId, title, content, awardCfg.partake);
        --     local pActor = Actor.getActorById(actorId);
        --     DealFightResult(pActor)
        -- end
    end
end


-- 踢出副本
function KickoutAllActors(nFdId, nSceneId)
    local cacheData = MonDispatcher.GetCacheData(nFdId);

    if cacheData[nSceneId] == nil then
        return
    end
    -- print("踢出副本")
    if cacheData[nSceneId].inFuben then
        for i,actorid in Ipairs(cacheData[nSceneId].inFuben ) do
            -- print("踢出副本.."..actorid)
            if actorid ~= 0 then
                local pActor = Actor.getActorById(actorid)
                if pActor then
                    --满血结束血量
                    local maxhp = Actor.getIntProperty(pActor,PROP_CREATURE_MAXHP)
                    Actor.changeHp(pActor, maxhp)
                    Actor.exitFubenAndBackCity(pActor)
                end
            end
            
        end
    end
end

-- 回血回蓝
function ResetAllActors(nFdId, nSceneId)
    local cacheData = MonDispatcher.GetCacheData(nFdId);

    if cacheData[nSceneId] == nil then
        return
    end

    --print("nFdId : "..nFdId.." nSceneId : "..nSceneId)
    if cacheData[nSceneId].inFuben then
        for i,actorid in Ipairs(cacheData[nSceneId].inFuben ) do
            --print("满血 actorid : " .. actorid)
            if actorid ~= 0 then
                local pActor = Actor.getActorById(actorid)
                if pActor then
                    --print("死亡 Actor.getReliveTimeOut(pActor) : " .. Actor.getReliveTimeOut(pActor))
                    if Actor.getReliveTimeOut(pActor) > 0 then
                        Actor.clearReliveTimeOut(pActor)
                    end

                    --满血结束血量
                    local maxHp = Actor.getIntProperty(pActor,PROP_CREATURE_MAXHP)
                    Actor.changeHp(pActor, maxHp)

                    local maxMp = Actor.getIntProperty(pActor,PROP_CREATURE_MAXMP)
                    Actor.changeMp(pActor, maxMp)

                end
            end
            
        end
    end
end

--发送归属
function SendClinetBossBeLong(nFubenId, nSceneId, pActor)
    local cacheData = MonDispatcher.GetCacheData(nFubenId);
    if cacheData == nil then
        return;
    end

    if cacheData[nSceneId] == nil then
        return
    end
    if cacheData[nSceneId].monster == nil then
        return
    end
    local npack = DataPack.allocPacket(pActor, enBossSystemID, sBossBelong)
    if npack then
        DataPack.writeByte(npack, (monNumor or 0))
        -- print("SendClinetBossBeLong")
        InitClientData(npack, cacheData[nSceneId].monster)
        DataPack.flush(npack);
    end
end


--场景内发送归属
function SendAllClinetBossBeLong(nFubenId, nSceneId)
    local cacheData = MonDispatcher.GetCacheData(nFubenId);
    if cacheData == nil then
        return;
    end

    if cacheData[nSceneId] == nil then
        return
    end
    if cacheData[nSceneId].monster == nil then
        return
    end

    local npack = DataPack.allocPacketEx()
    if npack then
        DataPack.writeByte(npack,enBossSystemID)
        DataPack.writeByte(npack,sBossBelong)
        DataPack.writeByte(npack, (cacheData[nSceneId].monNumor or 0))
        -- print("SendAllClinetBossBeLong")
        InitClientData(npack, cacheData[nSceneId].monster)
        DataPack.broadcastScene(npack, cacheData[nSceneId].fbHandle,nSceneId)
    end
end

---返回当前场景内所有归属信息
function InitClientData(npack, monster)
    if monster then
        for _, data in Ipairs(monster) do

            DataPack.writeInt(npack, (data.nBossId or 0))
            local id = 0;
            if data.beLongId then
                id = 1
            end
            -- print("InitClientData.."..id.."..data.beLongId.."..(data.beLongId or 0))
            DataPack.writeByte(npack, id)
            returnDataPacket(npack, data.beLongId)
        end
    end
end
--设置返回归属信息
function returnDataPacket(npack, beLongId)
    local actor = System.getEntityPtrByActorID(beLongId);
    if actor then
        local name = Actor.getName(actor);
        local actorId = Actor.getIntProperty( actor, PROP_ENTITY_ID )
        local hp = Actor.getIntProperty( actor, PROP_CREATURE_HP )
        local maxhp = Actor.getIntProperty( actor, PROP_CREATURE_MAXHP )
        local sex = Actor.getIntProperty( actor, PROP_ACTOR_SEX )
        local job = Actor.getIntProperty( actor, PROP_ACTOR_VOCATION )
        local sbk = Actor.MyGuildIsSbk( actor )
        local guildname = Actor.getGuildName(actor);
        DataPack.writeUInt(npack, (actorId or 0))
        DataPack.writeByte(npack, (job or 0))
        DataPack.writeByte(npack, (sex or 0))
        DataPack.writeString(npack, (name or ""))
        DataPack.writeString(npack, (guildname or ""))
        DataPack.writeByte(npack, (sbk or 0))
        DataPack.writeInt(npack, (maxhp or 0))
        DataPack.writeInt(npack, (hp or 0))
        local handle = Actor.getHandle(actor)
        DataPack.writeUint64(npack, (handle or 0))
    end
end


--判断当前玩家是否属于归属者
function AttackIsBeLong(nFdId, nSceneId, actorId)
    local cacheData = MonDispatcher.GetCacheData(nFdId);
    if cacheData[nSceneId] == nil then
        return false
    end
    if cacheData[nSceneId].monster == nil then
        return false
    end
    for _, data in Ipairs(cacheData[nSceneId].monster) do
        if data.beLongId then 
            if actorId == data.beLongId then
                return true;
            end
        end
    end
    return false
end


---取消归属
function CancelMonsterBeLong(nFdId, nSceneId, nActorId)
    local cacheData = MonDispatcher.GetCacheData(nFdId);
    if cacheData[nSceneId] == nil then
        return false
    end
    if cacheData[nSceneId].monster == nil then
        return false
    end
    for _, data in Ipairs(cacheData[nSceneId].monster) do
        -- print("data.beLongId.."..(data.beLongId or 0).."..nActorId.."..nActorId)
        if data.beLongId then
            if nActorId == data.beLongId then
                -- cacheData[nSceneId].monster[data.monId].beLongId = nil
                data.beLongId = nil
            end
        end
       
    end
end

----callback 脚本

--实体死亡
function OnEntityDeath(pFuben, nFdId, nSceneId, pEntity, pKiller)
    local fdId = Fuben.getFubenIdByPtr(pFuben);
    if fdId ~= nFdId then
        return
    end
    local cacheData = MonDispatcher.GetCacheData(fdId);

    if cacheData[nSceneId] == nil then
        return
    end
    local deathId = Actor.getIntProperty(pEntity, PROP_ENTITY_ID)
    if Actor.getEntityType(pEntity) == enMonster then
        if cacheData[nSceneId].monster == nil then
            return
        end

        if cacheData[nSceneId].monster[deathId] == nil then
            return
        end

        --boss死亡触发奖励
        local isNotice = true;
        local awardCfg = getAwardCfg(deathId)
        if awardCfg and awardCfg.dienotice then
            if awardCfg.day and awardCfg.day > 0 then
                local openday = System.getDaysSinceOpenServer()
                if openday > awardCfg.day then
                    isNotice = false;
                end    
            end
            if isNotice then
                local actor = System.getEntityPtrByActorID((cacheData[nSceneId].monster[deathId].beLongId or 0));
                if actor then
                    local name = Actor.getName(actor);
                    local str = string.format(awardCfg.dienotice, name)
                    System.broadcastTipmsgLimitLev(str, tstChatSystem)
                end
            end
        end
        SendAward(nFdId, nSceneId, deathId);

        ResetAllActors(nFdId, nSceneId);

        FubenDispatcher.SetFubenTimeout(nFdId, pFuben);
        -- KickoutAllActors(nFdId, nSceneId);
        -- if cacheData[nSceneId].canDelete then
        --     Fuben.closeFuben( cacheData[nSceneId].fbHandle )
        -- end

        cacheData[nSceneId] = nil
    end
end

--退出副本
function OnExitFuben(nFdId,pFuben, nSceneId, pActor)
    local cacheData = MonDispatcher.GetCacheData(nFdId);
    if cacheData == nil then
        return;
    end

    if cacheData[nSceneId] == nil then
        return
    end

    local actorId = Actor.getIntProperty(pActor, PROP_ENTITY_ID )
    if cacheData[nSceneId].inFuben == nil then
        return
    end
    -- print("退出副本.."..actorId.."..nFdId.."..nFdId.."..nSceneId.."..nSceneId)
    if AttackIsBeLong(nFdId, nSceneId, actorId) then
        CancelMonsterBeLong(nFdId, nSceneId, actorId);
        Actor.CancelBeLongBoss(pActor);
        SendAllClinetBossBeLong(nFdId, nSceneId)
    end
    -- print("退出副本.."..actorId)
    cacheData[nSceneId].inFuben[actorId] = 0 -- 记录
    local actorData = MonDispatcher.GetActorData(pActor, nFdId);
    if actorData == nil then
        return;
    end

    --场景超时
    if not FubenDispatcher.GetActivityKickFlag(pFuben) then
        actorData.nextLoginTime = System.getCurrMiniTime() + 30
    end
    -- print("退出副本.."..actorData.nextLoginTime)

end

--记录参与奖的玩家
function OnEnterFuben(nFubenId, nSceneId, pActor)
    local cacheData = MonDispatcher.GetCacheData(nFubenId);
    if cacheData == nil then
        return;
    end

    if cacheData[nSceneId] == nil then
        return
    end
    local actorId = Actor.getIntProperty(pActor, PROP_ENTITY_ID )
    if cacheData[nSceneId].inFuben == nil then
        cacheData[nSceneId].inFuben = {}
    end
   

    -- print("记录参与奖的玩家.."..actorId)
    cacheData[nSceneId].inFuben[actorId] = actorId -- 记录
    SendClinetBossBeLong(nFubenId, nSceneId, pActor);
end



--判断玩家是否在当前副本
function IsInFuben(nFubenId, nSceneId, nActorId)
    local cacheData = MonDispatcher.GetCacheData(nFubenId);
    if cacheData == nil then
        return false
    end

    if cacheData[nSceneId] == nil then
        return false
    end

    if cacheData[nSceneId].inFuben == nil then
        return false;
    end
   
    if cacheData[nSceneId].inFuben[nActorId] and cacheData[nSceneId].inFuben[nActorId] == nActorId then
        return true;
    end
    return false;
end

--记录参与奖的玩家
function OnEntityAttacked(pFuben, nFdId, nSceneId, pEntity, pAttacker)
    local cacheData = MonDispatcher.GetCacheData(nFdId);
    if cacheData[nSceneId] == nil then
        return
    end
    
    local monId = Actor.getIntProperty( pEntity, PROP_ENTITY_ID )
    -- print("Actor.getEntityType(pEntity).."..Actor.getEntityType(pEntity).."..monId.."..monId)
    if Actor.getEntityType(pEntity) == enMonster then

        if cacheData[nSceneId].monster == nil then
            return
        end

        if cacheData[nSceneId].monster[monId] == nil then
            return
        end
        -- print("..monId.."..monId)
        if cacheData[nSceneId].monster[monId].beLonglist == nil then
            cacheData[nSceneId].monster[monId].beLonglist = {}
        end
        ---攻击者死亡
        if Actor.isDeath(pAttacker) then
            return;
        end
        local actorId = Actor.getIntProperty(pAttacker, PROP_ENTITY_ID )
        -- print("..actorId.."..monId)
        if cacheData[nSceneId].monster[monId].beLongId == nil then
            -- print("OnEntityAttacked  beLongId  ")
            if IsInFuben(nFdId, nSceneId, actorId) then
                cacheData[nSceneId].monster[monId].beLongId = actorId
                Actor.SetBeLongBoss(pAttacker, (cacheData[nSceneId].monster[monId].nBossId or cacheData[nSceneId].monster[monId].nMonId), nSceneId)
                cacheData[nSceneId].monster[monId].beLonglist[actorId] = actorId

                SendAllClinetBossBeLong(nFdId, nSceneId)
            end
        end
        if cacheData[nSceneId].monster[monId].attack == nil then
            cacheData[nSceneId].monster[monId].attack = {}
        end
        if cacheData[nSceneId].monster[monId].attack[actorId] == nil then
            cacheData[nSceneId].monster[monId].attack[actorId] = actorId -- 记录
        end
       
    elseif Actor.getEntityType(pEntity) == enActor then
        -- InitClientData
        --判断归属者是否收到伤害
        if AttackIsBeLong(nFdId, nSceneId, monId) then
            -- print("AttackIsBeLong")
            SendAllClinetBossBeLong(nFdId, nSceneId)
        end
    end
end


--获取数据
function OnReqData(nFdId, nSceneId, nMonId, inPacket)
    -- local fdId = Fuben.getFubenIdByPtr(pFuben);
    local cacheData = MonDispatcher.GetCacheData(nFdId);
    local maxHp = 0;
    local leftHp = 0;
    if cacheData[nSceneId] then
        if cacheData[nSceneId].scenHandle then
            maxHp = Fuben.getMonsterMaxHp(cacheData[nSceneId].scenHandle, nMonId);
            leftHp = Fuben.getMonsterHp(cacheData[nSceneId].scenHandle, nMonId);
        end
    end
    DataPack.writeInt(inPacket, (maxHp or 0)) 
    DataPack.writeInt(inPacket, (leftHp or 0)) 
end




--取消boss 归属
function OnCancelBL(nFdId, nSceneId, nMonId, pActor)
    local cacheData = MonDispatcher.GetCacheData(nFdId);
    if cacheData == nil then
        return;
    end

    if cacheData[nSceneId] == nil then
        return
    end

    if cacheData[nSceneId].monster == nil then
        cacheData[nSceneId].monster = {}
    end
    nMonId = nMonId %100000; 
   
    if cacheData[nSceneId].monster[nMonId] == nil then
        return
    end
    -- print("nMonId.."..nMonId)
    cacheData[nSceneId].monster[nMonId].beLongId = nil;
    --击杀者触发 归属
    if pActor then
        local nextId = Actor.getIntProperty(pActor, PROP_ENTITY_ID )
        -- print("OnCancelBL")
        cacheData[nSceneId].monster[nMonId].beLongId = nextId;
        Actor.SetBeLongBoss(pActor, (cacheData[nSceneId].monster[nMonId].nBossId or cacheData[nSceneId].monster[nMonId].nMonId), nSceneId)
        --统计归属者id
        if cacheData[nSceneId].monster[nMonId].beLonglist == nil then
            cacheData[nSceneId].monster[nMonId].beLonglist = {}
        end
        cacheData[nSceneId].monster[nMonId].beLonglist[nextId] = nextId
    end
    SendAllClinetBossBeLong(nFdId, nSceneId);
end

-- 设置boss 归属
function OnSetBossBL(nFdId, nSceneId, nMonId, pActor)
    local cacheData = MonDispatcher.GetCacheData(nFubenId);
    if cacheData == nil then
        return;
    end

    if cacheData[nSceneId] == nil then
        return
    end
    local actorId = Actor.getIntProperty(pActor, PROP_ENTITY_ID )
    if cacheData[nSceneId].monster == nil then
        cacheData[nSceneId].monster = {}
    end

    if cacheData[nSceneId].monster[nMonId] and cacheData[nSceneId].monster[nMonId].beLongId then
        -- print("OnSetBossBL")
        cacheData[nSceneId].monster[nMonId].beLongId = actorId;
        SendAllClinetBossBeLong(nFdId, nSceneId)
    end
end



function getAwardCfg(nId)
    local data = nil
    for _, cfg in pairs(AwardBossConfig) do
        if cfg.entityid then
            if cfg.entityid == nId then
                data = cfg
                break
            end
        end
    end
    return data
end



function getBossCfg(nId)
    local data = nil
    for _, cfg in pairs(AwardBossConfig) do
        local id = (cfg.Serial or 0)*100000 + (cfg.entityid or 0)
        if id == nId then
            data = cfg
            break
        end
    end
    return data
end

function getRealCfg(nSerial)
    local data = nil
    for _, cfg in pairs(AwardBossConfig) do
        if cfg.Serial == nSerial then
            data = cfg
            break
        end
    end
    return data
end

function DealFightResult(pActor)
    local Cfg = ShenZhuangBossConfig
    if Cfg and pActor then
       Actor.addStaticCount(pActor, Cfg.id, -1)
       Actor.SendSzBossTimes(pActor);
    end
end
--进入检查
function OnCheckEnterFuben(nFdId, nSceneId, nMonId, pActor)
    local Cfg = getBossCfg(nMonId);

    if Cfg and Cfg.fbid then

        local actorData = MonDispatcher.GetActorData(pActor, nFdId);
        if actorData == nil then
            return true;
        end
        -- print("1212121.."..(actorData.nextLoginTime or 0).."..."..System.getCurrMiniTime())
        if actorData.nextLoginTime and actorData.nextLoginTime > System.getCurrMiniTime() then
            Actor.sendTipmsg(pActor, "请30秒后再进入！", tstUI)
            return false
        end
    end
    return true
end


--记录参与奖的玩家
function OnReqEnterFuben(pActor, nFubenId)
    --进入副本
    return MonDispatcher.EnterMonFuben(MonTabType, pActor, nFubenId)
    
end

MonDispatcher.Reg(MonEvent.OnInitialize, MonsterType, OnInitialize, "BossEvent10.lua")
MonDispatcher.Reg(MonEvent.OnEntityDeath,MonsterType, OnEntityDeath, "BossEvent10.lua")
MonDispatcher.Reg(MonEvent.OnEntityAttacked, MonsterType,OnEntityAttacked, "BossEvent10.lua")
MonDispatcher.Reg(MonEvent.OnEnterFuben,MonsterType,  OnEnterFuben, "BossEvent10.lua")
MonDispatcher.Reg(MonEvent.OnExitFuben,MonsterType,  OnExitFuben, "BossEvent10.lua")
MonDispatcher.Reg(MonEvent.OnCancelBL, MonsterType, OnCancelBL, "BossEvent10.lua")
MonDispatcher.Reg(MonEvent.OnSetBossBL, MonsterType, OnSetBossBL, "BossEvent10.lua")
MonDispatcher.Reg(MonEvent.OnCheckEnterFuben,MonsterType, OnCheckEnterFuben, "BossEvent10.lua")
MonDispatcher.Reg(MonEvent.OnReqData, MonsterType, OnReqData, "BossEvent10.lua")
MonDispatcher.Reg(MonEvent.OnReqEnterFuben, MonsterType, OnReqEnterFuben, "BossEvent10.lua")

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 跨天，次数清零
function OnNewDayArrive(pActor, ndiffday)
    local openday = System.getDaysSinceOpenServer()
    local Cfg = ShenZhuangBossConfig

    --次元钥匙
    if Cfg then
        if openday >= Cfg.ciyuaopenday then
            local nOpenTime = System.getOpenServerRelToday() + ((Cfg.ciyuaopenday or 0) -1) * 24*3600;
            local nDiffTime = math.max(nOpenTime, Cfg.SetTime or 0);

            local bNewActor = false
            local nTime = Actor.getStaticCount(pActor, Cfg.ciyuanid+1);
            if nTime == 0 then
                -- nTime = System.getToday();
                bNewActor = true
            end

            local nOffDay = 0;
            if nTime ~= nDiffTime then
                --nTime = System.getToday();

                --print("nTime : "..nTime.." nDiffTime : "..nDiffTime.."..nOpenTime.."..nOpenTime.."..openday.."..System.getOpenServerToday())

                if bNewActor then
                    nTime = System.getToday();
                    nOffDay = math.ceil( (math.abs(nTime - nDiffTime)) / (24*3600) ) + 1;
                else
                    --print("bNewActor : ", bNewActor)
                    nOffDay = math.ceil( (math.abs(nTime - nDiffTime)) / (24*3600) )+ndiffday;
                end
                Actor.setStaticCount(pActor, Cfg.ciyuanid+1, nDiffTime)
            end

            --print("nOffDay : "..nOffDay.." ndiffday : "..ndiffday)

            if nOffDay ~= 0 then
                ndiffday = nOffDay
            end

            Actor.addStaticCount(pActor, Cfg.ciyuanid, ndiffday * (Cfg.times or 1) )
        end
    end
end



ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "BossEvent10.lua")

