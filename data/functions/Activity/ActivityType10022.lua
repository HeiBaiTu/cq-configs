module("ActivityType10022", package.seeall)


--[[
    个人活动（玩法），360大玩家特权
    
    个人数据：userData
    {
        ReqMainGiftType = 0(默认值) or 1    服务器使用
        ReqSubGiftType1 = 0(默认值) or 1    服务器使用
        privilegeGift = 0 or 1 是否领取 360大玩家特权
        Fcm = 0 ~ 2            防沉迷 0:未填写身份证，1：成年，2：未成年
        FcmGiftFlag = 0 or 1   防沉迷 礼包领取标志 
    }
]]--


--活动类型
ActivityType = 10022
--对应的活动配置
ActivityConfig = Platform360Config
local PfId = System.getPfId()


local HttpStatus = {
    Success = "0",      -- 成功
    ArgError = "-4",    -- param gkey error
    SignError = "-2",   -- sign error
}


Host = ActivityConfig.host or "game.api.1360.com"
Api = ActivityConfig.api or "/authcheck"
Port = ActivityConfig.port or "80"


function GetUserData(pActor)
    print("[Tip]  ActivityType10022 GetUserData")

    local var = Actor.getStaticVar(pActor)
    if var.userData== nil then
        var.userData = {}
    end
    
    return var.userData
end


--------------------------------------------------------------------
-- CPP回调
--------------------------------------------------------------------

-- 360玩家登录
function On360Login(pActor)
    print("[Tip]  ActivityType10022 On360Login")

    -- 平台验证
    if not PfId then
        print("[Tip]  ActivityType10022 On360Login not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip]  ActivityType10022 On360Login not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip]  ActivityType10022 On360Login not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip]  [Platform360] [非本平台活动]")  
        return --非本平台活动
    end

    
    local userData = GetUserData(pActor)
    if userData.ReqMainGiftType == nil then
        userData.ReqMainGiftType = 0
    end
    if userData.ReqSubGiftType1 == nil then
        userData.ReqSubGiftType1 = 0
    end
    if userData.privilegeGift == nil then
        userData.privilegeGift = 0
    end
    if userData.Fcm == nil then
        userData.Fcm = 0
    end
    if userData.FcmGiftFlag == nil then
        userData.FcmGiftFlag = 0
    end

    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSend360UserPrivilegeData)
    if npack then
        --print("[Tip]  ActivityType10022 On360Login sSend360UserPrivilegeData ")
        DataPack.writeByte(npack, (userData.privilegeGift or 0))        -- 是否领取 360大玩家特权 礼包  0否1是
        DataPack.writeByte(npack, (userData.Fcm or 0))                  -- 防沉迷 0:未填写身份证，1：成年，2：未成年
        DataPack.writeByte(npack, (userData.FcmGiftFlag or 0))          -- 防沉迷 礼包领取标志
        DataPack.flush(npack)
    end
end


--------------------------------------------------------------------
-- 客户端请求协议回调
--------------------------------------------------------------------

-- 请求 360大玩家特权 礼包
function OnReq360PrivilegeGift(pActor)
    print("[Tip] ActivityType10022 OnReq360PrivilegeGift")

    -- 平台验证
    if not PfId then
        print("[Tip]  ActivityType10022 OnReq360PrivilegeGift not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip]  ActivityType10022 OnReq360PrivilegeGift not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip]  ActivityType10022 OnReq360PrivilegeGift not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip]  [Platform360] [非本平台活动]")  
        return --非本平台活动
    end

    local userData = GetUserData(pActor)
    if userData.privilegeGift == 1 then
        print("[Tip] ActivityType10022 OnReq360PrivilegeGift userData.privilegeGift == 1 ")
        return
    end
    
    if not ActivityConfig.reward1 then
        print("[Tip] ActivityType10022 OnReq360PrivilegeGift not ActivityConfig.reward1 ")
        return
    end
        
    --检测格子 16 : 活动通用
    if CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) ~= true then
        print("[Tip] ActivityType10022 OnReq360PrivilegeGift CheckBagIsEnough ")
        return
    end
    
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSend360UserPrivilegeData)
    if npack then
        
        userData.privilegeGift = 1

        DataPack.writeByte(npack, (userData.privilegeGift or 1))        -- 是否领取 360大玩家特权 礼包  0否1是
        DataPack.writeByte(npack, (userData.Fcm or 0))                  -- 防沉迷 0:未填写身份证，1：成年，2：未成年
        DataPack.writeByte(npack, (userData.FcmGiftFlag or 0))          -- 防沉迷 礼包领取标志
        DataPack.flush(npack)

        local awards = ActivityConfig.reward1

        Actor.SendActivityLog(pActor,ActivityType,ActivityType,1)
            
        CommonFunc.Awards.Give(pActor, awards, GameLog.Log_ActivityType10022)

        Actor.SendActivityLog(pActor,ActivityType,ActivityType,2)

        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)

        print("[Tip] ActivityType10022 OnReq360PrivilegeGift Success ")
    end

end

-- 请求奖励
function OnReq360Gift(pActor, packet)
    print("[Tip] ActivityType10022 OnReq360Gift")

    -- 平台验证
    if not PfId then
        print("[Tip]  ActivityType10022 OnReq360Gift not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip]  ActivityType10022 OnReq360Gift not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip]  ActivityType10022 OnReq360Gift not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip]  [Platform360] [非本平台活动]")  
        return --非本平台活动
    end

    local userData = GetUserData(pActor)
    userData.ReqMainGiftType = DataPack.readByte(packet) 
    userData.ReqSubGiftType1 = DataPack.readByte(packet)

    if not userData.ReqMainGiftType then
        print("[Tip]  ActivityType10022 OnReq360Gift not userData.ReqMainGiftType")  
        return
    end

    if not userData.ReqSubGiftType1 then
        print("[Tip]  ActivityType10022 OnReq360Gift not userData.ReqSubGiftType1")  
        return
    end

    if 1 == userData.ReqMainGiftType then
        if 1 == userData.ReqSubGiftType1 then
            Req360UserInfo(pActor)
        end
    end
end

-- 发送 防沉迷奖励
function SendFcmGift(pActor)
    print("[Tip] ActivityType10022 SendFcmGift")

    local userData = GetUserData(pActor)

    userData.ReqMainGiftType = 0 
    userData.ReqSubGiftType1 = 0

    if not userData.Fcm or userData.Fcm == 0 then
        print("[Tip] ActivityType10022 SendFcmGift not Fcm certification")
        return
    end

    if 1 == userData.FcmGiftFlag then
        print("[Tip] ActivityType10022 SendFcmGift already get FcmGift")
        return
    end

    if not ActivityConfig or not ActivityConfig.authentication then
        print("[Tip] ActivityType10022 SendFcmGift not ActivityConfig or not ActivityConfig.authentication")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10022 SendFcmGift CheckBagIsEnough ")
        return
    end

    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSend360UserPrivilegeData)
    if npack then
        
        userData.FcmGiftFlag = 1
        DataPack.writeByte(npack, (userData.privilegeGift or 0))        -- 是否领取 360大玩家特权 礼包  0否1是
        DataPack.writeByte(npack, (userData.Fcm or 0))                  -- 防沉迷 0:未填写身份证，1：成年，2：未成年
        DataPack.writeByte(npack, (userData.FcmGiftFlag or 1))          -- 是否领取 360大玩家特权 礼包  0否1是
        DataPack.flush(npack)

        Actor.SendActivityLog(pActor,ActivityType,ActivityType,1)
            
        CommonFunc.Awards.Give(pActor, ActivityConfig.authentication, GameLog.Log_ActivityType10022)

        Actor.SendActivityLog(pActor,ActivityType,ActivityType,2)

        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)

        print("[Tip] ActivityType10022 SendFcmGift Success ")
    end
end

NetmsgDispatcher.Reg(enPlatforMwelfareID, cReq360UserPrivilegeGift, OnReq360PrivilegeGift)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cReq360Gift, OnReq360Gift)


--------------------------------------------------------------------
-- 请求平台玩家数据信息
--------------------------------------------------------------------


-- 设置 360用户数据
function Set360UserData(paramPack,content,result)
    print("[Tip] ActivityType10022 Set360UserData content : "..content)
    print("[Tip] ActivityType10022 Set360UserData result : "..result)
    local nActorId = paramPack[1]
    local pActor = Actor.getActorById(nActorId)
    if not pActor then
        print("[Tip] ActivityType10022 Set360UserData [" .. nActorId .. "] 已离线")
        return
    end
    print("[Tip] ActivityType10022 Set360UserData [" .. Actor.getName(pActor) .. "] content:"..content)
    print("[Tip] ActivityType10022 Set360UserData result:"..result)

    if 0 == result then
        local status = string.match(content,"\"errno\":(%d+)")
        if (HttpStatus.Success == status) then

            local strFcm = string.match(content,"\"status\":(%d+)")
            local nFcm = 0

            if "null" ~= strFcm then
                nFcm = tonumber(strFcm)
            end

            local userData = GetUserData(pActor)
            userData.Fcm = nFcm

            if 1 == userData.ReqMainGiftType then
                if 1 == userData.ReqSubGiftType1 then
                    SendFcmGift(pActor)
                end
            end
        end
    end
end


-- 请求 360用户信息
function Req360UserInfo(pActor)
    print("[Tip] ActivityType10022 Req360UserInfo")

    local nActorId = Actor.getActorId(pActor)

    local gkey = "sbcq"
    local qid =  Actor.getAccount(pActor)
    local time = os.time()
    local key = "uyTs8udOvowF3KAMsPbe3f1Kvfsyww1L"

    local sign = System.MD5(gkey..qid..time..key)
    local req = Api..'?&qid='..qid..'&gkey='..gkey..'&time='..time..'&sign='..sign

    print("[Tip] ActivityType10022 Req360UserInfo [" .. Actor.getName(pActor) .. "] : ".. Host)
    print("[Tip] ActivityType10022 Req360UserInfo [" .. Actor.getName(pActor) .. "] : ".. Port)
    print("[Tip] ActivityType10022 Req360UserInfo [" .. Actor.getName(pActor) .. "] : ".. req)
    AsyncWorkDispatcher.Add(
        {'GetHttpContent',Host,Port,req},
        Set360UserData,
        {nActorId}
    )
end

