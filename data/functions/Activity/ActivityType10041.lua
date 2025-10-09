module("ActivityType10041", package.seeall)


--[[
    2144沙城争霸 平台福利

    个人数据：userData
    {
        ReqMainGiftType = 0(默认值) ~ 2    1：手机绑定奖励；2：实名认证奖励

        YBCount         =                  累计充值元宝数
        SVIPGiftFlag    = 0 or 1           超级VIP奖励标志
        BindPhoneGiftFlag = 0 or 1         手机绑定奖励标志
        RealNameGiftFlag = 0 or 1          实名认证奖励标志
    }
]]--

-- 对应的活动配置
ActivityConfig = Platform2144sccsConfig

-- 平台Id
local PfId = System.getPfId()

-- 2144沙城争霸 获取玩家数据
function Get2144SCZBUserData(pActor)
    local var = Actor.getStaticVar(pActor)
    if nil == var.UserData2144SCZB then
        var.UserData2144SCZB = {}
    end
    return var.UserData2144SCZB
end

-- 2144沙城争霸 发送玩家数据
function Send2144SCZBUserData(pActor)
    print("ActivityType10041.lua Send2144SCZBUserData 玩家 : "..Actor.getName(pActor))

    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, cSend2144SCZBUserData)
    if npack then
        local userData = Get2144SCZBUserData(pActor)

        if ActivityConfig and ActivityConfig.type then
            local cdkdata = getActorCdkData(pActor)
            if cdkdata then
                if cdkdata.codeTypeTimes then
                    if cdkdata.codeTypeTimes[ActivityConfig.type] then
                        userData.SVIPGiftFlag = 1
                    end
                end
            end
        end

        DataPack.writeByte(npack, userData.SVIPGiftFlag)
        DataPack.writeByte(npack, userData.BindPhoneGiftFlag)
        DataPack.writeByte(npack, userData.RealNameGiftFlag)
        DataPack.flush(npack)
    end
end

-- 2144沙城争霸 发送手机绑定奖励
function Send2144SCZBBindPhoneGift(pActor)
    print("ActivityType10041.lua Send2144SCZBBindPhoneGift 玩家 : "..Actor.getName(pActor))

    if not ActivityConfig or not ActivityConfig.bindPhoneReward then
        print("ActivityType10041.lua Send2144SCZBBindPhoneGift not ActivityConfig or not ActivityConfig.bindPhoneReward")
        return
    end

    local userData = Get2144SCZBUserData(pActor)
    if 1 == userData.BindPhoneGiftFlag then
        print("ActivityType10041.lua Send2144SCZBBindPhoneGift  玩家 : "..Actor.getName(pActor).." already get BindPhoneGift")
        return
    end

    --检测格子 16 : 活动通用
    if CommonFunc.Awards.CheckBagIsEnough(pActor, 16, tmDefNoBagNum, tstUI) ~= true then
        print("ActivityType10041.lua Send2144SCZBBindPhoneGift not CheckBagIsEnough")
        return
    end

    CommonFunc.Awards.Give(pActor, ActivityConfig.bindPhoneReward, GameLog.Log_Activity10041)

    -- 设置标志位
    userData.BindPhoneGiftFlag = 1

    Send2144SCZBUserData(pActor)
end

-- 2144沙城争霸 发送手机绑定奖励
function Send2144SCZBRealNameGift(pActor)
    print("ActivityType10041.lua Send2144SCZBRealNameGift 玩家 : "..Actor.getName(pActor))

    if not ActivityConfig or not ActivityConfig.authentication then
        print("ActivityType10041.lua Send2144SCZBRealNameGift not ActivityConfig or not ActivityConfig.authentication")
        return
    end

    local userData = Get2144SCZBUserData(pActor)
    if 1 == userData.RealNameGiftFlag then
        print("ActivityType10041.lua Send2144SCZBRealNameGift  玩家 : "..Actor.getName(pActor).." already get RealNameGift")
        return
    end

    --检测格子 16 : 活动通用
    if CommonFunc.Awards.CheckBagIsEnough(pActor, 16, tmDefNoBagNum, tstUI) ~= true then
        print("ActivityType10041.lua Send2144SCZBRealNameGift not CheckBagIsEnough")
        return
    end

    CommonFunc.Awards.Give(pActor, ActivityConfig.authentication, GameLog.Log_Activity10041)

    -- 设置标志位
    userData.RealNameGiftFlag = 1

    Send2144SCZBUserData(pActor)
end

-- 2144沙城争霸 玩家登录
function OnReq2144SCZBLogin(pActor, packet)
    print("ActivityType10041.lua OnReq2144SCZBLogin 玩家 : "..Actor.getName(pActor))

    -- 平台验证
    if not PfId then
        print("ActivityType10041.lua OnReq2144SCZBLogin not PfId")
        return 
    end
    if not ActivityConfig or not ActivityConfig.SPID then
        print("ActivityType10041.lua OnReq2144SCZBLogin not ActivityConfig or not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("ActivityType10041.lua OnReq2144SCZBLogin tostring(PfId) ~= tostring(ActivityConfig.SPID) SPID : "..PfId)  
        return
    end

    local userData = Get2144SCZBUserData(pActor)
    if nil == userData.ReqMainGiftType then
        userData.ReqMainGiftType = 0
    end
    if nil == userData.SVIPGiftFlag then
        userData.SVIPGiftFlag = 0
    end
    if nil == userData.BindPhoneGiftFlag then
        userData.BindPhoneGiftFlag = 0
    end
    if nil == userData.RealNameGiftFlag then
        userData.RealNameGiftFlag = 0
    end

    Send2144SCZBUserData(pActor)
end

-- 2144沙城争霸 获取玩家数据
function OnReq2144SCZBGift(pActor, packet)
    print("ActivityType10041.lua OnReq2144SCZBGift 玩家 : "..Actor.getName(pActor))

    -- 平台验证
    if not PfId then
        print("ActivityType10041.lua OnReq2144SCZBGift not PfId")
        return 
    end
    if not ActivityConfig or not ActivityConfig.SPID then
        print("ActivityType10041.lua OnReq2144SCZBGift not ActivityConfig or not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("ActivityType10041.lua OnReq2144SCZBGift tostring(PfId) ~= tostring(ActivityConfig.SPID) SPID : "..PfId)  
        return
    end

    local userData = Get2144SCZBUserData(pActor)
    userData.ReqMainGiftType = DataPack.readByte(packet)
    if not userData.ReqMainGiftType then
        print("ActivityType10041.lua OnReq2144SCZBGift not userData.ReqMainGiftType 玩家 : "..Actor.getName(pActor))  
        return
    end

    if 1 == userData.ReqMainGiftType then       -- 请求 2144沙城争霸手机绑定奖励
        Send2144SCZBBindPhoneGift(pActor)
    elseif 2 == userData.ReqMainGiftType then   -- 请求 2144沙城争霸实名认证奖励
        Send2144SCZBRealNameGift(pActor)
    end
end

NetmsgDispatcher.Reg(enPlatforMwelfareID, cReq2144SCZBLogin, OnReq2144SCZBLogin)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cReq2144SCZBGift, OnReq2144SCZBGift)

