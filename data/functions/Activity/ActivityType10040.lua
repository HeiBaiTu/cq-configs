module("ActivityType10040", package.seeall)


--[[
    360沙城争霸 平台福利

    个人数据：userData
    {
        ReqMainGiftType = 0(默认值) ~ 2    请求奖励类型 服务器使用
        ReqSubGiftType1 = 0(默认值) ~ 2    请求奖励子类型 服务器使用
        LoginType       = 0~3             0：网页登录；1：微端登录；2：手机登录；3：360游戏大厅登录
        LastSignMonthOfYear = 1~12        上一次签到月份

        bigPlayerGiftFlag = 0 or 1        大玩家礼包领取标志
        monthSingGiftFlag                 月份签到领取标志
    }
]]--


--对应的活动配置
ActivityConfig = Platform360sccsConfig

-- 平台Id
local PfId = System.getPfId()

-- 360沙城争霸 获取玩家数据
function Get360SCZBUserData(pActor)
    local var = Actor.getStaticVar(pActor)
    if nil == var.UserData360SCZB then
        var.UserData360SCZB = {}
    end
    return var.UserData360SCZB
end

-- 360沙城争霸 发送玩家数据
function Send360SCZBUserData(pActor)
    --print("ActivityType10040.lua Send360SCZBUserData 玩家 : "..Actor.getName(pActor))

    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, cSend360SCZBUserData)
    if npack then
        local userData = Get360SCZBUserData(pActor)

        DataPack.writeByte(npack, userData.bigPlayerGiftFlag)
        DataPack.writeUInt(npack, userData.monthSingGiftFlag)
        DataPack.flush(npack)
    end
end

-- 360沙城争霸 发送大玩家奖励
function Send360SCZBBigPlayerGift(pActor)
    print("ActivityType10040.lua Send360SCZBBigPlayerGift 玩家 : "..Actor.getName(pActor))

    if not ActivityConfig or not ActivityConfig.BigPlayer then
        print("ActivityType10040.lua Send360SCZBBigPlayerGift not ActivityConfig or not ActivityConfig.BigPlayer")
        return
    end

    local userData = Get360SCZBUserData(pActor)
    if 1 == userData.bigPlayerGiftFlag then
        print("ActivityType10040.lua Send360SCZBBigPlayerGift 玩家 : "..Actor.getName(pActor).." already get BigPlayerGift")
        return
    end

    --检测格子 16 : 活动通用
    if CommonFunc.Awards.CheckBagIsEnough(pActor, 16, tmDefNoBagNum, tstUI) ~= true then
        print("ActivityType10040.lua Send360SCZBBigPlayerGift not CheckBagIsEnough")
        return
    end

    CommonFunc.Awards.Give(pActor, ActivityConfig.BigPlayer, GameLog.Log_Activity10040)

    -- 设置标志位
    userData.bigPlayerGiftFlag = 1

    Send360SCZBUserData(pActor)
end

-- 360沙城争霸 发送签到奖励
function Send360SCZBSignGift(pActor)
    print("ActivityType10040.lua Send360SCZBSignGift 玩家 : "..Actor.getName(pActor))

    local userData = Get360SCZBUserData(pActor)
    -- 跨月份，清空月份签到领取标志
    if System.getMonthOfNow() ~= userData.LastSignMonthOfYear then
        userData.LastSignMonthOfYear = 0
        userData.monthSingGiftFlag = 0
    end

    local nDayofMonth = System.getDayOfMonth() 
    if not ActivityConfig or not ActivityConfig.signreward or not ActivityConfig.signreward[nDayofMonth] then
        print("ActivityType10040.lua Send360SCZBSignGift not ActivityConfig or not ActivityConfig.BigPlayer")
        return
    end

    local userData = Get360SCZBUserData(pActor)
    if 1 ~= userData.LoginType and 3 ~= userData.LoginType then -- 1：微端登录；3:360大厅登录
        print("ActivityType10040.lua Send360SCZBSignGift 1 ~= userData.LoginType and 3 ~= userData.LoginType 玩家 : "..Actor.getName(pActor).." userData.LoginType : "..userData.LoginType)
        return
    end

    if 1 == System.getIntBit(userData.monthSingGiftFlag, nDayofMonth) then
        print("ActivityType10040.lua Send360SCZBSignGift 玩家 : "..Actor.getName(pActor).." already get SignGift nDayofMonth : "..nDayofMonth)
        return
    end

    --检测格子 16 : 活动通用
    if CommonFunc.Awards.CheckBagIsEnough(pActor, 16, tmDefNoBagNum, tstUI) ~= true then
        print("ActivityType10040.lua Send360SCZBSignGift not CheckBagIsEnough")
        return
    end

    CommonFunc.Awards.Give(pActor, ActivityConfig.signreward[nDayofMonth], GameLog.Log_Activity10040)

    -- 设置标志位
    userData.monthSingGiftFlag = System.setIntBit(userData.monthSingGiftFlag, nDayofMonth, 1)
    userData.LastSignMonthOfYear = System.getMonthOfNow()

    Send360SCZBUserData(pActor)
end

-- 360沙城争霸 玩家登录
function OnReq360SCZBLogin(pActor, packet)
    -- print("ActivityType10040.lua OnReq360SCZBLogin 玩家 : "..Actor.getName(pActor))

    -- 平台验证
    if not PfId then
        print("ActivityType10040.lua OnReq360SCZBLogin not PfId")
        return 
    end
    if not ActivityConfig or not ActivityConfig.SPID then
        print("ActivityType10040.lua OnReq360SCZBLogin not ActivityConfig or not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("ActivityType10040.lua OnReq360SCZBLogin tostring(PfId) ~= tostring(ActivityConfig.SPID) SPID : "..PfId)  
        return
    end

    local userData = Get360SCZBUserData(pActor)
    userData.LoginType = DataPack.readByte(packet)
    if nil == userData.LoginType or userData.LoginType < 0 or userData.LoginType > 3 then
        print("ActivityType10040.lua OnReq360SCZBLogin nil == userData.LoginType or userData.LoginType < 0 or userData.LoginType > 3 玩家 : "..Actor.getName(pActor))
        print(userData.LoginType)  
        return
    end
    if nil == userData.ReqMainGiftType then
        userData.ReqMainGiftType = 0
    end
    if nil == userData.LastSignMonthOfYear then
        userData.LastSignMonthOfYear = 0
    end
    if nil == userData.bigPlayerGiftFlag then
        userData.bigPlayerGiftFlag = 0
    end
    if nil == userData.monthSingGiftFlag then
        userData.monthSingGiftFlag = 0
    end

    Send360SCZBUserData(pActor)
end

-- 360沙城争霸 玩家请求平台福利
function OnReq360SCZBGift(pActor, packet)
    print("ActivityType10040.lua OnReq360SCZBGift 玩家 : "..Actor.getName(pActor))

    -- 平台验证
    if not PfId then
        print("ActivityType10040.lua OnReq360SCZBGift not PfId")
        return 
    end
    if not ActivityConfig or not ActivityConfig.SPID then
        print("ActivityType10040.lua OnReq360SCZBGift not ActivityConfig or not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("ActivityType10040.lua OnReq360SCZBGift tostring(PfId) ~= tostring(ActivityConfig.SPID) SPID : "..PfId)  
        return
    end

    local userData = Get360SCZBUserData(pActor)
    userData.ReqMainGiftType = DataPack.readByte(packet)
    if not userData.ReqMainGiftType then
        print("ActivityType10040.lua OnReq360SCZBGift not userData.ReqMainGiftType 玩家 : "..Actor.getName(pActor))  
        return
    end

    if 1 == userData.ReqMainGiftType then       -- 请求 360沙城争霸大玩家奖励
        Send360SCZBBigPlayerGift(pActor)
    elseif 2 == userData.ReqMainGiftType then   -- 请求 360沙城争霸签到奖励
        Send360SCZBSignGift(pActor)
    end
end

NetmsgDispatcher.Reg(enPlatforMwelfareID, cReq360SCZBLogin, OnReq360SCZBLogin)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cReq360SCZBGift, OnReq360SCZBGift)


-- 跨天处理
function OnNewDayArrive(pActor, ndiffday)
    print("ActivityType10040.lua OnNewDayArrive 玩家 : "..Actor.getName(pActor))

    -- 跨月份，清空月份签到领取标志
    local userData = Get360SCZBUserData(pActor)

    if nil == userData.LastSignMonthOfYear then
        return
    end

    if System.getMonthOfNow() ~= userData.LastSignMonthOfYear then
        userData.LastSignMonthOfYear = 0
        userData.monthSingGiftFlag = 0

        Send360SCZBUserData(pActor)
    end 
end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10040.lua")

