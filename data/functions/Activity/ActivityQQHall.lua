module("ActivityQQHall", package.seeall)

--[[
   
    QQ大厅特权
    
    个人数据：qqHallData
    {
        activeGift = 0/1 是否领取活跃礼包（0否，1是）
        registerGift = 0/1 是否领取注册礼包（0否，1是）
        lastLoginTime = 0 上一次通过YY大厅登录的时间戳
        loginDay = 1 通过YY大厅登录的累计天数
         levelGift = 00000000 32位 是否领取某天的登录礼包 
       
        --蓝钻
        newPlayerGift //新手礼包
        growupgift //成长礼包
        dailyGift //每日礼包
        blueDimandGift //蓝钻等级
        BlueLv //蓝钻等级
        Blue //蓝钻
        BlueYear //年费
    }
]]--
PlatformConfig = PlatformQQConfig
LoginConfig = LoginQQConfig

local PfId = System.getPfId()
--对应的活动配置
function getQQHallData(pActor)
    local var = Actor.getStaticVar(pActor)
    if var.qqHallData== nil then
        var.qqHallData = {}
    end
    return var.qqHallData
end

function SendQQHallData(pActor)
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [PlatformQQ] SendQQHallData ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [PlatformQQ] [非本平台活动]")  
            return --非本平台活动
        end
    end
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sGetQQhallInfos)
    if npack then
        -- print("1111")
        local data = getQQHallData(pActor)
        DataPack.writeByte(npack, (data.activeGift or 0)) --是否领取活跃礼包（0否，1是）
        DataPack.writeByte(npack, (data.registerGift or 0)) --是否领取认证礼包（0否，1是）
        DataPack.writeUInt(npack, (data.levelGift or 0))--礼包的领取标记 32 位
        DataPack.flush(npack)
    end
end


--------------------------------------------------------------------
-- CPP回调
--------------------------------------------------------------------

function OnQQHallLogin(pActor)

    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [PlatformQQ] OnQQHallLogin ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [PlatformQQ] [非本平台活动]")  
            return --非本平台活动
        end
    end

    -- 当天初始化
    local data = getQQHallData(pActor)
    if data.lastLoginTime == nil then
        data.lastLoginTime = System.getCurrMiniTime()
        --print("第一天")
    end
    -- print("1111")
    SendQQHallData(pActor);
end

--------------------------------------------------------------------
-- 客户端请求协议回调
-------------------------------------------------------------------
--登录
function OnReqQQHallLevelGift(pActor, packet)

    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [PlatformQQ] OnReqQQHallLevelGift ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [PlatformQQ] [非本平台活动]")  
            return --非本平台活动
        end
    end

    local idx = DataPack.readByte(packet)
    if idx > #LoginConfig then
        return
    end
    local conf = PlatformConfig
    local Cfg = LoginQQConfig[idx]
    idx = idx - 1
    local data = getQQHallData(pActor)
    if Cfg  then
        -- 领取检查data.levelGift
        if not data.levelGift then
            data.levelGift = 0
        end
        local flag = System.getIntBit(data.levelGift, idx)
        --print("loginGift="..data.levelGift.." flag="..flag)
        if flag == 1 then
            return
        end
        local lv = Actor.getIntProperty( pActor, PROP_CREATURE_LEVEL )

        if Cfg.level and ( lv < Cfg.level ) then
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:等级不足|", tstUI)
            return
        end
        if CommonFunc.Awards.CheckBagIsEnough(pActor,conf.bagtype,tmLeftBagNumNotEnough,tstUI) ~= true then
            return
        end
        -- 天数检查
        data.levelGift = System.setIntBit(data.levelGift, idx, true)
        CommonFunc.Awards.Give(pActor, Cfg.reward, GameLog.Log_QQhallLevel)
        SendQQHallData(pActor)
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)
    end
end

--注册
function OnReqQQHallRegisteGift(pActor, packet)

    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [PlatformQQ] OnReqQQHallRegisteGift ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [PlatformQQ] [非本平台活动]")  
            return --非本平台活动
        end
    end

    local data = getQQHallData(pActor)
    if data.registerGift then
        return 
    end
    local conf = PlatformConfig
    local awards = conf.reward1
    if CommonFunc.Awards.CheckBagIsEnough(pActor,conf.bagtype,tmLeftBagNumNotEnough,tstUI) ~= true then
        return
    end
    CommonFunc.Awards.Give(pActor, awards, GameLog.Log_QQhallRegiste)
    data.registerGift = 1;
    Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)
    SendQQHallData(pActor)
end
--认证
function OnReqQQHallIdActiveGift(pActor, packet)

    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [PlatformQQ] OnReqQQHallIdActiveGift ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [PlatformQQ] [非本平台活动]")  
            return --非本平台活动
        end
    end

    local conf = PlatformConfig
    local awards = conf.reward2
    local data = getQQHallData(pActor)
    if data.activeGift == 1 then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:重复领取|", tstUI)
        return 
    end
    if CommonFunc.Awards.CheckBagIsEnough(pActor,conf.bagtype,tmLeftBagNumNotEnough,tstUI) ~= true then
        return
    end
    CommonFunc.Awards.Give(pActor, awards, GameLog.Log_QQhallActive)
    data.activeGift = 1;
    Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)
    SendQQHallData(pActor)
end




NetmsgDispatcher.Reg(enPlatforMwelfareID, cGetQQHallInfos, OnQQHallLogin)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cGetQQqHallLevelAward, OnReqQQHallLevelGift)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cGetQQHallRegisteAward, OnReqQQHallRegisteGift)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cGetQQqHallActiveAward, OnReqQQHallIdActiveGift)
--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 跨天
function OnNewDayArrive(pActor,ndiffday)

    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [PlatformQQ] OnNewDayArrive ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [PlatformQQ] [非本平台活动]")  
            return --非本平台活动
        end
    end

    print("[ActivityTypeQQHall:OnNewDayArrive-001--")
    local currMiniTime = System.getCurrMiniTime()
    local data = getQQHallData(pActor)
    --print("[ActivityTypeQQHall:OnNewDayArrive-101--".. tostring(data.lastLoginTime))
    print("[ActivityTypeQQHall:OnNewDayArrive-123--".. tostring(data.dailyGift)) 
    print("[ActivityTypeQQHall:OnNewDayArrive-111--".. tostring(data.activeGift)) 
    --if data.lastLoginTime then
        print("[ActivityTypeQQHall:OnNewDayArrive-002--")
        if not System.isSameDay(data.lastLoginTime, System.getCurrMiniTime()) then
            data.lastLoginTime = System.getCurrMiniTime()
            -- data.loginDay = data.loginDay + 1
            data.activeGift = 0
            data.dailyGift = 0;
            
            print("[ActivityTypeQQHall:OnNewDayArrive-9123--".. tostring(data.dailyGift)) 
            print("[ActivityTypeQQHall:OnNewDayArrive-9111--".. tostring(data.activeGift)) 
        end

        SendQQHallData(pActor)
    --end
end 

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityQQHall.lua")


-----------
--蓝钻
-----------
function OnSetQQBlueDiamond(pActor, packet)

    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [PlatformQQ] OnSetQQBlueDiamond ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [PlatformQQ] [非本平台活动]")  
            return --非本平台活动
        end
    end

    local data = getQQHallData(pActor)
    local nBlue =DataPack.readByte(packet);
    local nBlueYear =DataPack.readByte(packet);
    local nBluelv =DataPack.readByte(packet);
    local nVip = 0;
    nVip = System.getValueMAKELONG(nBluelv, nBlueYear, nBlue);
    data.Blue = nBlue;
    data.BlueLv = nBluelv;
    data.BlueYear = nBlueYear;
    Actor.setUIntProperty(pActor,PROP_ACTOR_SUPPER_PLAY_LVL,nVip)
end


function SendQQBlueDiamondData(pActor)
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [PlatformQQ] SendQQBlueDiamondData ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [PlatformQQ] [非本平台活动]")  
            return --非本平台活动
        end
    end

    local npack = DataPack.allocPacket(pActor, enMiscSystemID, sGetQQBlueDiamond)
    if npack then
        local data = getQQHallData(pActor)
        DataPack.writeByte(npack, (data.newPlayerGift or 0)) --
        DataPack.writeUInt(npack, (data.growupgift or 0)) --
        DataPack.writeUInt(npack, (data.dailyGift or 0))--
        DataPack.writeUInt(npack, (data.blueDimandGift or 0))--
        DataPack.flush(npack)
    end
end


function GetQQBlueDiamonGift(pActor, packet)
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [PlatformQQ] GetQQBlueDiamonGift ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [PlatformQQ] [非本平台活动]")  
            return --非本平台活动
        end
    end

    local type = DataPack.readByte(packet)
    local idx = DataPack.readByte(packet)
    if type == 1 then --新手礼包
        GetQQBlueNewPlayerGift(pActor, idx)
    elseif type == 2 then --成长礼包
        GetQQBlueGrowUpGift(pActor, idx)
    elseif type == 3 then --每日礼包
        GetQQblueDailyGift(pActor, idx)
    elseif type == 4 then --蓝砖战神
        GetQQBlueFightGift(pActor, idx)
    end
end

function GetQQBlueNewPlayerGift(pActor, idx)
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [PlatformQQ] GetQQBlueNewPlayerGift ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [PlatformQQ] [非本平台活动]")  
            return --非本平台活动
        end
    end
    

    local conf = PlatformConfig
    local awards = conf.reward3
    local data = getQQHallData(pActor)
    if data.newPlayerGift then
        return 
    end
    if CommonFunc.Awards.CheckBagIsEnough(pActor,conf.bagtype,tmLeftBagNumNotEnough,tstUI) ~= true then
        return
    end
    CommonFunc.Awards.Give(pActor, awards, GameLog.Log_QQBlueNewPlayer)
    data.newPlayerGift = 1;
    Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)
    SendQQBlueDiamondData(pActor)
end

function GetQQBlueGrowUpGift(pActor, idx)
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [PlatformQQ] GetQQBlueGrowUpGift ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [PlatformQQ] [非本平台活动]")  
            return --非本平台活动
        end
    end
    

    if idx > #LoginConfig then
        return
    end
    local conf = PlatformConfig
    local Cfg = LevelBlueDiamondConfig[idx]
    idx = idx - 1
    local data = getQQHallData(pActor)
    if Cfg  then
        -- 领取检查data.levelGift
        if not data.growupgift then
            data.growupgift = 0
        end
        local flag = System.getIntBit(data.growupgift, idx)
        --print("loginGift="..data.levelGift.." flag="..flag)
        if flag == 1 then
            return
        end
        local lv = Actor.getIntProperty( pActor, PROP_CREATURE_LEVEL )

        if Cfg.level and ( lv < Cfg.level ) then
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:等级不足|", tstUI)
            return
        end
        if CommonFunc.Awards.CheckBagIsEnough(pActor,conf.bagtype,tmLeftBagNumNotEnough,tstUI) ~= true then
            return
        end
        -- 天数检查
        data.growupgift = System.setIntBit(data.growupgift, idx, true)
        CommonFunc.Awards.Give(pActor, Cfg.reward, GameLog.Log_QQBlueGrowUp)
        SendQQBlueDiamondData(pActor)
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)
    end
end

function GetQQblueDailyGift(pActor, idx)
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [PlatformQQ] GetQQblueDailyGift ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [PlatformQQ] [非本平台活动]")  
            return --非本平台活动
        end
    end

    local conf = PlatformConfig
    idx = idx - 1
    local data = getQQHallData(pActor)
    if not data.dailyGift then
        data.dailyGift = 0
    end
    local flag = System.getIntBit(data.dailyGift, idx)
    --print("loginGift="..data.levelGift.." flag="..flag)
    if flag == 1 then
        return
    end

    if data.Blue == nil then
        data.Blue = 0;
    end
    if data.BlueYear == nil then
        data.BlueYear = 0;
    end
    local Cfg = BlueDiamondDailyConfig[data.BlueLv]
    if Cfg then
        local awards = nil;
        if idx  == 0 then
            awards = Cfg.reward1
        elseif idx == 1 then
            if data.Blue == 2 then
                awards = Cfg.reward2
            end
        elseif idx == 2 then
            if data.BlueYear == 1 then
                awards = Cfg.reward3
            end
        else
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:不满足条件|", tstUI)
            return
        end
        if awards then
            if CommonFunc.Awards.CheckBagIsEnough(pActor,conf.bagtype,tmLeftBagNumNotEnough,tstUI) ~= true then
                return
            end
            -- 天数检查
            data.dailyGift = System.setIntBit(data.dailyGift, idx, true)
            CommonFunc.Awards.Give(pActor, awards, GameLog.Log_QQBlueGrowUp)
            SendQQBlueDiamondData(pActor)
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)
        end
    end
end

function GetQQBlueFightGift(pActor, idx)
end

NetmsgDispatcher.Reg(enMiscSystemID, CSetQQBlueDiamond, OnSetQQBlueDiamond)
NetmsgDispatcher.Reg(enMiscSystemID, CGetQQBlueDiamond, SendQQBlueDiamondData)
NetmsgDispatcher.Reg(enMiscSystemID, CGetQQBlueDiamondGift, GetQQBlueDiamonGift)