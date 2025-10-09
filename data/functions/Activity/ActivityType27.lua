module("ActivityType27", package.seeall)

--[[
    沙巴克(开服第三天)

    个人数据：ActorData[AtvId]
    {
    }

    全局缓存：Cache[AtvId]
    {   
        sbkArea[sceneid] //sceneid  场景id
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
        paodianTime,
        warNotice,--沙巴克皇宫可以开始占领！公告
    }

    全局数据：GlobalData[AtvId]
    {
        sbkGuild sbk领主id
    }
]]--

--活动类型
ActivityType = 27
--对应的活动配置
ActivityConfig = Activity27Config
-- if ActivityConfig == nil then
--     assert(false)
-- end
local SbkState = 0;
-- 活动状态
local AtvStatus =
{
    PreEnter = 1,   --活动前5分钟（走马灯全服公告，不给进入）
    Start = 2,      --开始
    Sbk = 3,      --沙巴克时间
    End = 4,        --结束了（发奖励，等待活动时间结束）
}
local PaodianTime = 0;
--------------------------------------------------------------------
-- 活动 回调注册
--------------------------------------------------------------------

-- 加载活动时（启动服务器从数据库返回的）
function OnLoad(atvId)
    print("[GActivity 27] 沙巴克 活动数据加载，id："..atvId)
end

-- 初始化玩家数据
function OnInit(atvId, pActor)
    print("[GActivity 27] 沙巴克 "..Actor.getName(pActor).." 初始化 id："..atvId)
end

-- 活动开始
function OnStart(atvId)
    setSbkAwardFlag(nil);
    print("[GActivity 27] 沙巴克 活动开始了，id："..atvId)
end

-- 活动结束
function OnEnd(atvId)
    local Cfg = ActivityConfig
    if Cfg then
        -- System.broadcastTipmsgLimitLev(Cfg.endsbk, tstBigRevolving)
        -- System.broadcastTipmsgLimitLev(Cfg.endsbk, tstChatSystem)
        
        local cacheData = ActivityDispatcher.GetCacheData(atvId);
        local globalData = ActivityDispatcher.GetGlobalData(atvId);
        if globalData.sbkGuild then
            local guildName = Guild.getGuildName(globalData.sbkGuild)
            if guildName then
                local str = string.format(Cfg.endsbk, guildName)
                System.broadcastTipmsgLimitLev(str, tstBigRevolving)
                -- print("..on")
                System.broadcastTipmsgLimitLev(str, tstChatSystem)
            end
        end
        if cacheData.sbkArea then
            for _, sceneid in Ipairs(cacheData.sbkArea) do
                -- print("vvvv.."..sceneid)
                Fuben.ResetFubenSceneConfig(sceneid);
            end
        end
       
    end
    
    SbkState = AtvStatus.End
    ActivityDispatcher.ClearCacheData(atvId);
    print("[GActivity 27] 沙巴克 活动结束了，id："..atvId)
end


--公告
function SendNotice(avtId, curTime)
    local cfg = ActivityConfig
    local cacheData = ActivityDispatcher.GetCacheData(avtId);
    if cfg == nil then
        return;
    end
end

-- function OnReqData(atvId, pActor)

-- end
-- 活动帧更新
function OnUpdate(atvId, curTime)
    SendNotice(atvId, curTime);
    DealSbkAreaAttr(atvId, curTime);
    dealGuildSbk(atvId,curTime);
    dealPaodianExp(atvId,curTime)
end


--p泡点
function dealPaodianExp(atvId, curTime)
    --检测沙巴克占领是否开启
    local cacheData = ActivityDispatcher.GetCacheData(atvId);
    local Cfg = ActivityConfig
    local startTime = System.getRunningActivityStartTime(atvId)
    if Cfg then
        if Cfg.starttime then
            -- local startTime = System.getRunningActivityStartTime(atvId)
            if curTime < (startTime + Cfg.starttime) then
                return
            end
        end
        if cacheData.paodianTime == nil then
            cacheData.paodianTime = 0
        end
        if curTime >= cacheData.paodianTime then
            cacheData.paodianTime = curTime + 5
            if Cfg.idx then
                addPaodianExp(cacheData.actors, Cfg.idx,atvId);
            end
        end
    end
end

--沙巴克行为
function dealGuildSbk(atvId, curTime)
    --检测沙巴克占领是否开启
    local Cfg = ActivityConfig
    local startTime = System.getRunningActivityStartTime(atvId)
    local cacheData = ActivityDispatcher.GetCacheData(atvId);
    -- print("dealGuild.."..startTime)
    if Cfg then
        if Cfg.wartime then
            local startTime = System.getRunningActivityStartTime(atvId)
            if curTime < (startTime + Cfg.wartime) then
                return
            end

            if not cacheData.warNotice and Cfg.wartimestr then
                cacheData.warNotice = 1
                System.broadcastTipmsgLimitLev(Cfg.wartimestr, tstRevolving)
                System.broadcastTipmsgLimitLev(Cfg.wartimestr, tstChatSystem)
            end
        end
        
        local globalData = ActivityDispatcher.GetGlobalData(atvId);
        if globalData.sbkGuild == nil then
            globalData.sbkGuild = 0
        end
        -- print("dealGuildSbk.."..cacheData.sbkGuild)
        if Cfg.winmap then
            local guildId = Fuben.GetNowSceneGuildList(Cfg.winmap);
            if guildId > 0 and globalData.sbkGuild ~= guildId then
                globalData.sbkGuild = guildId
                Guild.setSbkGuildId(guildId);
                local guildName = Guild.getGuildName(guildId)
                if guildName then
                    local str = string.format(Cfg.sbknotic, guildName)
                    -- print("..dealGuildSbk"..str)
                    System.broadcastTipmsgLimitLev(str, tstRevolving)
                    System.broadcastTipmsgLimitLev(str, tstChatSystem)
                end
            end
        end
    end
end

-- 处理活动开始 设置sbk区域为战斗区域
function DealSbkAreaAttr(atvId, curTime)
    local cacheData = ActivityDispatcher.GetCacheData(atvId);
    local Cfg = ActivityConfig
    local startTime = System.getRunningActivityStartTime(atvId)
    if Cfg and Cfg.starttime then
        if curTime > (startTime + Cfg.starttime) then
            -- SbkState = AtvStatus.Sbk
            if SbkState ~= AtvStatus.Sbk then
                SbkState = AtvStatus.Sbk
                System.sendAllActorOneActivityData(atvId);
                ActivityDispatcher.BroadPopup(atvId);
            end

            if cacheData.needDealarea == nil then
                cacheData.needDealarea = {}
            end
            
            if cacheData.sbkArea == nil then
                cacheData.sbkArea = {}
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
                -- print("西门吹雪 .."..area.sceneid)
                cacheData.sbkArea[area.sceneid] = area.sceneid
            end
            cacheData.needDealarea = nil;
            --设置战斗区域
        end
    end
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
end

-- 活动区域需要处理新增区域属性
function OnEnterArea(atvId, pActor)
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

    local x,y = Actor.getEntityPosition(pActor,0,0)
    -- 已经初始化完成
    if cacheData.areaAttr[sceneId] then
        return;
    end
    -- print("来了吗.."..sceneId)
    cacheData.areaAttr[sceneId] = 1; 
    local area = {};
    area.sceneid = sceneId;
    area.x = x
    area.y = y
    -- -- print("OnEnterArea x.."..x.." y.."..y);
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

function OnGetRedPoint(atvId, pActor)
    local ret = 0
    if SbkState == AtvStatus.Sbk then ret = 1 end
    return ret
end

ActivityDispatcher.Reg(ActivityEvent.OnLoad, ActivityType, OnLoad, "ActivityType27.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType27.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType27.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType27.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdate, ActivityType, OnUpdate, "ActivityType27.lua")
-- ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType27.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnterArea, ActivityType, OnEnterArea, "ActivityType27.lua")
ActivityDispatcher.Reg(ActivityEvent.OnExitArea, ActivityType, OnExitArea, "ActivityType27.lua")
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType27.lua")