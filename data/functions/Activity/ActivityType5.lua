module("ActivityType5", package.seeall)

--[[
    NPC,夺宝类活动

    个人数据：ActorData[AtvId]
    {
        count, 剩余领取个人宝箱次数
        uint_times, 分配宝箱次数时候的时间
        
    }

    全局缓存：Cache[fbId]
    {

        AtvArea[sceneid] //sceneid  场景id
        {
           state  //状态
        }
        needDealarea
        {
            area
            {
                sceneid, //场景id
                x,  x坐标
                y,  y坐标
            }
        }

        actors = {actorid,...}  记录活动副本中的玩家id
        nextAutoTime,           下一次自动加经验的时间戳

        bigTreasureFlag,        本次活动大宝箱是否已经掉落
        canPicktime, //可捡取的时间
    }

    全局数据：GlobalData[AtvId]
    {

    }
]]--

--活动类型
local ActivityType = 5
--对应的活动配置
local ActivityConfig = Activity5Config

if ActivityConfig == nil then
    assert(false)
end


--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------

--领取个人宝箱操作
function getPersonBox(pActor, atvId, Conf, inPack)
    local errorcode = 0
 
    

    local data = ActivityDispatcher.GetActorData(pActor,atvId)

  
    while(true)
    do
        if data.uint_times ==nil then
            data.uint_times = 0
        end
        if data.count ==nil then
            data.count = 1
        end
        

        --次数检查
        if System.getActivityEndMiniSecond(atvId)==0 then 
            --Actor.sendTipmsg(pActor, "获取互动时间错误", tstUI)
            break
        end

        if data.count == 0 and data.uint_times ~=System.getActivityEndMiniSecond(atvId) then
            data.count = 1 
        else
            if data.count <=0 then
                
                Actor.sendTipmsgWithId(pActor, tmGetDuoBaoGiftYet, tstUI)
                errorcode = 1
                break
            end
        end
     
        -- 记录日志
        Actor.SendActivityLog(pActor,atvId,ActivityType,1)

        --检查背包
        if CommonFunc.Awards.CheckBagIsEnough(pActor,1,tmDefNoBagNum,tstUI) ~= true then
            return
        end

        if Conf.Persongift then
            --CommonFunc.GiveCommonAward(pActor, Conf.Persongift, GameLog.Log_Activity5, "夺宝类活动|"..atvId)
            CommonFunc.Awards.Give(pActor, Conf.Persongift, GameLog.Log_Activity5, "夺宝类活动|"..atvId)
        
            Actor.sendTipmsgWithId(pActor, tmGetDuoBaoGiftSucc, tstUI)
        end
        data.uint_times =System.getActivityEndMiniSecond(atvId)
        -- 操作成功
        data.count = 0
        
        -- 记录日志
        Actor.SendActivityLog(pActor,atvId,ActivityType,2)
        Actor.triggerAchieveEvent(pActor, nAchieveActivity,1 ,7);
        Actor.triggerAchieveEvent(pActor, nAchieveCompleteActivity,1 ,7);
        
        
        break
    end

    local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendPersonBox)
    -- local netPack = DataPack.allocPacket(pActor,enActivityID, sSendPersonActivityUpdate)
    if  outPack then

        DataPack.writeByte(outPack, errorcode) 
        DataPack.flush(outPack)
    end

    Actor.sendActivityData(pActor, atvId)
    
end

--送宝掉大宝箱
function getBigTreasure(pActor, atvId, Conf, inPack)
    local errorcode = 1
 
  
    local cacheData = ActivityDispatcher.GetCacheData(atvId)


    while(true)
    do

        --时间限制检查
        if( System.isReachSecondBeforeActivityEnd(atvId,300) ~=true) then
            
            Actor.sendTipmsgWithId(pActor, tmActivityUnReachsongbaoTime, tstUI)
            break
        end

        --次数检查
        if cacheData.bigTreasureFlag == nil then
            cacheData.bigTreasureFlag = 1
        else
            if cacheData.bigTreasureFlag == 0 then
                
                Actor.sendTipmsgWithId(pActor, tmSongBaoYet, tstUI)
                break
            end
        end
     
        --掉落组掉落
        if Conf.bigTreasure then
            if Item.drop_item_in_random_area_byGroupID(Conf.sceneId, Conf.npcPosx, Conf.npcPosy, Conf.bigTreasure,Conf.picktime,Conf.tipsid) ~=true then
                break
            end 
            
            Actor.sendTipmsgWithId(pActor, tmSongBaoSuccess, tstUI)
            errorcode = 0
        end

        -- 操作成功
        cacheData.bigTreasureFlag = 0
        
        
        break
    end

   
     local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendBigTreasure)
     
     if  outPack then
         -- DataPack.writeUInt(outPack, nId)
        -- DataPack.writeByte(outPack, nIndex)
         DataPack.writeByte(outPack, errorcode) 
         DataPack.flush(outPack)
     end
end



--送宝掉大宝箱
function AutoBigTreasure(atvId)

    --时间限制检查
    if( System.isReachSecondBeforeActivityEnd(atvId,300) ~=true) then
        return
    end
    local Conf = ActivityConfig[atvId]
    if Conf == nil then
        return
    end
    -- print("cacheData.bigTreasureFlag.."..(cacheData.bigTreasureFlag or 0))
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    if cacheData == nil then
        cacheData = {}
    end
    if cacheData.bigTreasureFlag and cacheData.bigTreasureFlag == 0 then
        return
    end
    --次数检查
    if cacheData.bigTreasureFlag == nil then
        cacheData.bigTreasureFlag = 1
    end
    --掉落组掉落
    if Conf.bigTreasure then 
        Item.drop_item_in_random_area_byGroupID(Conf.sceneId, Conf.npcPosx, Conf.npcPosy, Conf.bigTreasure,Conf.picktime,Conf.tipsid)
    end
    -- 操作成功
    cacheData.bigTreasureFlag = 0
    cacheData.canPicktime = System.getCurrMiniTime() + Conf.picktime;
    local fbHandle = Fuben.getStaticFubenHandle();
    BroadCanPickTime(atvId,fbHandle,Conf.sceneId);
end

-- 处理活动开始 
function DealAtvAreaAttr(atvId, curTime)
    local cacheData = ActivityDispatcher.GetCacheData(atvId);
    local Cfg = ActivityConfig[atvId]
    local startTime = System.getRunningActivityStartTime(atvId)
    if Cfg  then
        if curTime > startTime then
            if cacheData.needDealarea == nil then
                cacheData.needDealarea = {}
            end           
            if cacheData.AtvArea == nil then
                cacheData.AtvArea = {}
            end
            -- 已经设置OK
            for _, area in Ipairs(cacheData.needDealarea) do
                if Cfg.areaattr and Cfg.areaattr.attri then
                    for _, attr in pairs(Cfg.areaattr.attri) do
                        local index = Fuben.GetAreaListIndex(area.sceneid, area.x, area.y)
                        local hScene = Fuben.getSceneHandleById(area.sceneid, 0)
                        if index > 0 then
                            Fuben.setSceneAreaAttri(hScene, index, attr.type, attr.value, NULL, (Cfg.areaattr.notips or 0)); 
                        end
                    end
                end
                cacheData.AtvArea[area.sceneid] = area.sceneid
            end
            cacheData.needDealarea = nil;
            --设置战斗区域
        end 
        
    end
end


--发送玩家当前剩余时间信息
function SendLeftTimeInfo(pActor, atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    if cacheData and cacheData.canPicktime then
        local npack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sDuoBaoPickLeftTime)
        if npack then
            DataPack.writeInt(npack, cacheData.canPicktime)
            DataPack.flush(npack)
        end
    end
    
end



--广播排行榜数据
function BroadCanPickTime(atvId,fbHandle,sceneId)
    -- 广播所有玩家排行榜数据
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    if cacheData and cacheData.canPicktime then
        local npack = ActivityDispatcher.AllocOperReturnEx(atvId, ActivityOperate.sDuoBaoPickLeftTime)
        if npack then
            DataPack.writeInt(npack, cacheData.canPicktime)
            DataPack.broadcastScene(npack,fbHandle,sceneId)
            ActivityDispatcher.FreePacketEx(npack)
        end
    end
    
end

--p泡点经验
function dealPaodianExp(atvId, curTime)
    
    local cacheData = ActivityDispatcher.GetCacheData(atvId);
    local Cfg = ActivityConfig[atvId]
    
    if Cfg then
        
        if cacheData.paodianTime == nil then
            cacheData.paodianTime = 0
        end
        -- print("dealGuildSbk111111.."..curTime.." time .."..cacheData.paodianTime)
        if curTime >= cacheData.paodianTime then
            cacheData.paodianTime = curTime + 5
            if Cfg.idx then
                addPaodianExp(cacheData.actors, Cfg.idx,atvId);
            end
        end
    end
end
--------------------------------------------------------------------
-- 活动 回调注册
--------------------------------------------------------------------

-- 活动开始
function OnStart(atvId)
    --print("[GActivity 5] 夺宝 活动开始了，id："..atvId)

    --data.count = 1
    System.broadcastTipmsg("夺宝地图已经开放，勇士们抓紧时间进入!",tstChatSystem);
    System.broadcastTipmsg("夺宝地图已经开放，勇士们抓紧时间进入!",tstRevolving);

    --初始化全局缓存数据
    --ActivityDispatcher.ClearCacheData(atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    cacheData.bigTreasureFlag = 1
    cacheData.actors = {}
    cacheData.nextAutoTime = 0

    --所有玩家推送活动数据
    System.sendAllActorOneActivityData(atvId) ;
    ActivityDispatcher.BroadPopup(atvId);

end

-- 活动结束
function OnEnd(atvId)
    

    local Cfg = ActivityConfig[atvId]
    if Cfg then
        local cacheData = ActivityDispatcher.GetCacheData(atvId);
        if cacheData.AtvArea then
            for _, sceneid in Ipairs(cacheData.AtvArea) do
                --print("vvvv.."..sceneid)
                Fuben.ResetFubenSceneConfig(sceneid);
            end
        end
    end 
    -- 清空活动数据
    ActivityDispatcher.ClearCacheData( atvId )
    --print("[GActivity 5] 夺宝 活动结束了，id："..atvId)
 
end

-- 进入活动区域
-- 执行泡点经验等逻辑
function OnEnterArea(atvId,pActor)
    local cacheData = ActivityDispatcher.GetCacheData(atvId);
    local sceneId = Actor.getSceneId(pActor);
    if cacheData.areaAttr == nil then
        cacheData.areaAttr = {}
    end

    -- 记录进入的玩家
    local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    if cacheData.actors == nil then
        cacheData.actors = {}
    end
    cacheData.actors[actorId] = actorId
    SendLeftTimeInfo(pActor,atvId);

    local x,y = Actor.getEntityPosition(pActor,0,0)
    -- 已经初始化完成
    if cacheData.areaAttr[sceneId] then
        return;
    end
    
    cacheData.areaAttr[sceneId] = 1; 
    local area = {};
    area.sceneid = sceneId;
    area.x = x
    area.y = y
    
    if cacheData.needDealarea == nil then
        cacheData.needDealarea = {}
    end
    cacheData.needDealarea[sceneId] = area
    -- table.insert(cacheData.needDealarea, area);
end



-- 离开活动区域
function OnExitArea(atvId, pActor)

          
    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    if cacheData.actors == nil then
         cacheData.actors = {}
    end
    local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
    cacheData.actors[actorId] = 0
              

end 

-- 活动帧更新
function OnUpdate(atvId, curTime)

    local cacheData = ActivityDispatcher.GetCacheData(atvId)
    local Cfg = ActivityConfig[atvId]

    DealAtvAreaAttr(atvId, curTime);
    
    dealPaodianExp(atvId,curTime)
    AutoBigTreasure(atvId);

end

-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    local data = ActivityDispatcher.GetActorData(pActor,atvId)

    if data.count ==nil then
        data.count = 1
    end
    --print("OnReqData:",data.count)

end

-- 通用操作
function OnOperator(atvId, pActor, inPack)

    -- id对应配置
    local Conf = ActivityConfig[atvId]
    if Conf == nil then
        --print("[Activity 4] "..Actor.getName(pActor).." 活动配置中找不到活动id："..atvId)
    end
    
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    --print("operaCode = "..operaCode)

    if operaCode == ActivityOperate.cGetPersonBox then     -- 领取个人宝箱
        getPersonBox(pActor,atvId,Conf,inPack)
    end
    if operaCode == ActivityOperate.cGetTreasure then     -- 送宝
        getBigTreasure(pActor,atvId,Conf,inPack)
    end
end

-- 初始化玩家数据
function OnInit(atvId, pActor)
    print("[GActivity 5] 夺宝 "..Actor.getName(pActor).." 初始化 id："..atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    actorData.count = nil
end

--活动红点数据
function OnGetRedPoint(atvId, pActor)
    
    local ret = 1
    local data = ActivityDispatcher.GetActorData(pActor,atvId)
    if data.count and (data.count == 0 ) then
        ret = 0
    end  
    return ret

end
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType5.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType5.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType5.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType5.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType5.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType5.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType5.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnterArea, ActivityType, OnEnterArea, "ActivityType5.lua")
ActivityDispatcher.Reg(ActivityEvent.OnExitArea, ActivityType, OnExitArea, "ActivityType5.lua")

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------



-- 跨天，次数清零
function OnNewDayArrive(pActor,atvId)

end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType5.lua")