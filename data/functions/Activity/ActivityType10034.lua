module("ActivityType10034", package.seeall)


--[[
    个人数据：userData
    {
        ReqMainGiftType                 2144 请求奖励类型 0：默认类型(服务器自用)；1：绑定手机奖励；2：完善资料奖励

        BindPhoneGiftFlag = 0 or 1      2144 绑定手机 礼包领取标志
        RealNameAuthenGiftFlag = 0 or 1 2144 完善资料 礼包领取标志
    }
]]--


--活动类型
ActivityType = 10034
--对应的活动配置
ActivityConfig = Platform2144Config


local PfId = System.getPfId()


function Get2144UserData(pActor)
    local var = Actor.getStaticVar(pActor)
    if nil == var.UserData2144 then
        var.UserData2144 = {}
    end
    return var.UserData2144
end

-- 发送 2144 玩家数据
function Send2144UserData(pActor)
    print("ActivityType10034 Send2144UserData actorName : "..Actor.getName(pActor))

    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, cSend2144UserData)
    if npack then
        local userData = Get2144UserData(pActor)

        DataPack.writeByte(npack, userData.BindPhoneGiftFlag)
        DataPack.writeByte(npack, userData.RealNameAuthenGiftFlag)
        DataPack.flush(npack)
    end
end

-- 发送 手机绑定奖励
function SendBindPhoneGift(pActor)
    print("ActivityType10034 SendBindPhoneGift")

    local userData = Get2144UserData(pActor)
    userData.ReqMainGiftType = 0

    if 1 == userData.BindPhoneGiftFlag then
        print("ActivityType10034 SendBindPhoneGift already get BindPhoneGift!")
        return
    end

    if not ActivityConfig or not ActivityConfig.bindPhoneReward then
        print("ActivityType10034 SendBindPhoneGift not ActivityConfig or not ActivityConfig.bindPhoneReward!")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10034 SendBindPhoneGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.BindPhoneGiftFlag = 1
    
    CommonFunc.Awards.Give(pActor, ActivityConfig.bindPhoneReward, GameLog.Log_Activity10034)

    Send2144UserData(pActor)
end

-- 发送 手机绑定奖励
function SendRealNameAuthenGift(pActor)
    print("ActivityType10034 SendRealNameAuthenGift")

    local userData = Get2144UserData(pActor)
    userData.ReqMainGiftType = 0

    if 1 == userData.RealNameAuthenGiftFlag then
        print("ActivityType10034 SendRealNameAuthenGift already get RealNameAuthenGift!")
        return
    end

    if not ActivityConfig or not ActivityConfig.authentication then
        print("ActivityType10034 SendRealNameAuthenGift not ActivityConfig or not ActivityConfig.authentication!")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10034 SendRealNameAuthenGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.RealNameAuthenGiftFlag = 1
    
    CommonFunc.Awards.Give(pActor, ActivityConfig.authentication, GameLog.Log_Activity10034)

    Send2144UserData(pActor)
end

-- 2144 用户登录
function OnReq2144Login(pActor)
    print("ActivityType10034 OnReq2144Login")
    
    local userData = Get2144UserData(pActor)
    if nil == userData.BindPhoneGiftFlag then
        userData.BindPhoneGiftFlag = 0
    end
    if nil == userData.RealNameAuthenGiftFlag then
        userData.RealNameAuthenGiftFlag = 0
    end

    Send2144UserData(pActor)
end

-- 请求 2144 奖励
function OnReq2144Gift(pActor, packet)
    print("ActivityType10034 OnReq2144Gift")

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10034 OnReq2144Gift not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10034 OnReq2144Gift not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10034 OnReq2144Gift not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10034 OnReq2144Gift [非本平台活动]")  
        return --非本平台活动
    end

    -- 初始化 玩家数据
    local userData = Get2144UserData(pActor)
    userData.ReqMainGiftType = DataPack.readByte(packet)

    print(userData.ReqMainGiftType)

    if not userData.ReqMainGiftType or userData.ReqMainGiftType < 1 or userData.ReqMainGiftType > 2 then
        print("ActivityType10034 OnReq2144Gift not userData.ReqMainGiftType or userData.ReqMainGiftType < 1 or userData.ReqMainGiftType > 2")
           
        return --非本平台活动
    end

    if 1 == userData.ReqMainGiftType then
        SendBindPhoneGift(pActor)
    elseif 2 == userData.ReqMainGiftType then
        SendRealNameAuthenGift(pActor)
    end
end


NetmsgDispatcher.Reg(enPlatforMwelfareID, cReq2144Login, OnReq2144Login)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cReq2144Gift, OnReq2144Gift)