module("ActivityType10016", package.seeall)

--[[
   YY4366大厅特权
    
    个人数据：YYHallAtv
    {
       phoneGift = 0/1 是否领取手机礼包（0否，1是）
       idCardGift = 0/1 是否领取认证礼包（0否，1是）
       lastLoginTime = 0 上一次通过YY大厅登录的时间戳
       loginDay = 1 通过YY大厅登录的累计天数
       loginGift = 00000000 32位 是否领取某天的登录礼包 
       loginTypeGift
       loginType;//登录问题
    }
]]--
PlatformConfig = Platform4366Config
LoginConfig = Login4366Config
local PfId = System.getPfId()
--对应的活动配置
function get4366Data(pActor)
    local var = Actor.getStaticVar(pActor)
    if var.YY4366HallAtv== nil then
        var.YY4366HallAtv = {}
    end
    return var.YY4366HallAtv
end

function Send4366Data(pActor)
    
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [Platform4366] Send4366Data ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [Platform4366] [非本平台活动]")  
            return --非本平台活动
        end
    end
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sGet4366Infos)
    if npack then
        -- print("1111")
        local data = get4366Data(pActor)
        local cdkFlag = 0;
        local cdkdata = getActorCdkData(pActor)
        if cdkdata then
            if cdkdata.codeTypeTimes then
                if cdkdata.codeTypeTimes[PlatformConfig.type] then
                    cdkFlag = 1;
                end
            end
        end 
        DataPack.writeByte(npack, (cdkFlag or 0)) --是否领取cdk礼包（0否，1是）
        DataPack.writeByte(npack, (data.phoneGift or 0)) --是否领取手机礼包（0否，1是）
        DataPack.writeByte(npack, (data.idCardGift or 0)) --是否领取认证礼包（0否，1是）
        DataPack.writeShort(npack, (data.loginDay or 1))--登录的天数
        DataPack.writeUInt(npack, (data.loginGift or 0))--礼包的领取标记 32 位
        DataPack.writeByte(npack, (data.loginTypeGift or 0)) --
        DataPack.flush(npack)
    end
end


--------------------------------------------------------------------
-- CPP回调
--------------------------------------------------------------------

function OnYY4366HallLogin(pActor)
    
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [Platform4366] OnYY4366HallLogin ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [Platform4366] [非本平台活动]")  
            return --非本平台活动
        end
    end
    -- 当天初始化
    local data = get4366Data(pActor)
    if data.lastLoginTime == nil then
        data.lastLoginTime = System.getCurrMiniTime()
        data.loginDay = 1
        --print("第一天")
    else
        if not System.isSameDay(data.lastLoginTime, System.getCurrMiniTime()) then
            --print("跨一天")
            data.lastLoginTime = System.getCurrMiniTime()
            data.loginDay = data.loginDay + 1
        end
    end
    -- print("1111")
    Send4366Data(pActor);
end

--------------------------------------------------------------------
-- 客户端请求协议回调
-------------------------------------------------------------------
--登录
function OnReqYY4366HallLoginGift(pActor, packet) 
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [Platform4366] OnReqYY4366HallLoginGift ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [Platform4366] [非本平台活动]")  
            return --非本平台活动
        end
    end
 
    local idx = DataPack.readByte(packet)
    if idx > #LoginConfig then
        return
    end
    local conf = PlatformConfig
    local awards = LoginConfig[idx].reward
    idx = idx - 1
    local data = get4366Data(pActor)
    if awards and data.lastLoginTime then
        -- 领取检查
        if not data.loginGift then
            data.loginGift = 0
        end
        local flag = System.getIntBit(data.loginGift, idx)
        --print("loginGift="..data.loginGift.." flag="..flag)
        if flag == 1 then
            return
        end
        if (data.loginDay == nil) or (data.loginDay < idx ) then
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:登录天数不足|", tstUI)
            return
        end
        if CommonFunc.Awards.CheckBagIsEnough(pActor,conf.bagtype,tmLeftBagNumNotEnough,tstUI) ~= true then
            return
        end
        -- 天数检查
        if data.loginDay and (data.loginDay > idx )then
            data.loginGift = System.setIntBit(data.loginGift, idx, true)
            CommonFunc.Awards.Give(pActor, awards, GameLog.Log_4366Login)
            Send4366Data(pActor)
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)
        end
    end
end

--认证
function OnReqYY4366HallPhoneGift(pActor, packet) 
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [Platform4366] OnReqYY4366HallPhoneGift ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [Platform4366] [非本平台活动]")  
            return --非本平台活动
        end
    end
    local conf = PlatformConfig
    local awards = conf.reward2
    local data = get4366Data(pActor)
    if data.phoneGift then
        return 
    end
    if CommonFunc.Awards.CheckBagIsEnough(pActor,conf.bagtype,tmLeftBagNumNotEnough,tstUI) ~= true then
        return
    end
    CommonFunc.Awards.Give(pActor, awards, GameLog.Log_4366Phone)
    data.phoneGift = 1;
    Send4366Data(pActor)
end
--认证
function OnReqYY4366HallIdCardGift(pActor, packet)
     
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [Platform4366] OnReqYY4366HallIdCardGift ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [Platform4366] [非本平台活动]")  
            return --非本平台活动
        end
    end
    local conf = PlatformConfig
    local awards = conf.reward3
    local data = get4366Data(pActor)
    if data.idCardGift then
        return 
    end
    if CommonFunc.Awards.CheckBagIsEnough(pActor,conf.bagtype,tmLeftBagNumNotEnough,tstUI) ~= true then
        return
    end
    CommonFunc.Awards.Give(pActor, awards, GameLog.Log_4366IdCard)
    data.idCardGift = 1;
    Send4366Data(pActor)
end

function OnReqYY4366Login(pActor, packet)
     
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [Platform4366] OnReqYY4366Login ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [Platform4366] [非本平台活动]")  
            return --非本平台活动
        end
    end
    local idx = DataPack.readByte(packet)
    local data = get4366Data(pActor)
    data.loginType = idx;
end

function OnReqYY4366LoginTypeGift(pActor, packet)
    
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [Platform4366] OnReqYY4366LoginTypeGift ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [Platform4366] [非本平台活动]")  
            return --非本平台活动
        end
    end
    local conf = PlatformConfig
    local awards = conf.rewardClient
    local data = get4366Data(pActor)
    if data.loginTypeGift then
        return 
    end
    if data.loginType == nil or data.loginType == 0 then
        return
    end
    
    if CommonFunc.Awards.CheckBagIsEnough(pActor,conf.bagtype,tmLeftBagNumNotEnough,tstUI) ~= true then
        return
    end
    CommonFunc.Awards.Give(pActor, awards, GameLog.Log_4366ExeLogin)
    data.loginTypeGift = 1;
    Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)
    Send4366Data(pActor)
    Actor.setStaticCount(pActor, 10005, 1);
    
    local strName = Actor.getName(pActor)
    if conf and conf.tips then         
        local strTips = string.format(conf.tips,strName)
        System.broadcastTipmsgLimitLev(strTips, tstKillDrop)
    end

    if conf and conf.tips2 then         
        local strTips2 = string.format(conf.tips2,strName)
        System.broadcastTipmsgLimitLev(strTips2, tstChatSystem)
    end
end


NetmsgDispatcher.Reg(enPlatforMwelfareID, cGet4366Infos, OnYY4366HallLogin)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cGet4366LoginAward, OnReqYY4366HallLoginGift)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cGet4366PhoneAward, OnReqYY4366HallPhoneGift)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cGet4366IdCardAward, OnReqYY4366HallIdCardGift)
NetmsgDispatcher.Reg(enPlatforMwelfareID, c4366LoginType, OnReqYY4366Login)
NetmsgDispatcher.Reg(enPlatforMwelfareID, c4366LoginTypeGift, OnReqYY4366LoginTypeGift)
--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 跨天
function OnNewDayArrive(pActor,ndiffday)
    
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [Platform4366] OnNewDayArrive ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [Platform4366] [非本平台活动]")  
            return --非本平台活动
        end
    end

    local currMiniTime = System.getCurrMiniTime()
    local data = get4366Data(pActor)
    if data.lastLoginTime then
        if not System.isSameDay(data.lastLoginTime, System.getCurrMiniTime()) then
            data.lastLoginTime = System.getCurrMiniTime()
            data.loginDay = data.loginDay + 1
        end

        Send4366Data(pActor)
    end
end


ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10016.lua")
