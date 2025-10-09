module("ActivityType10037", package.seeall)


--[[
    个人数据：userData
    {
        ReqMainGiftType                               迅玩 请求奖励类型 0：默认类型(服务器自用)；1：会员专属称号礼包；2：会员特权礼包；3：会员每日礼包；
        ReqSubGiftType                                迅玩 请求子奖励类型 0：默认类型(服务器自用)；(1位：白金会员；2位：超级会员；3位：白金年费会员；4位：超级年费会员；)

        MemberTitleGiftFlag = 00000000 32位           迅玩 会员专属称号    领取标志(1位：白金会员；2位：超级会员；3位：白金年费会员；4位：超级年费会员；)
        MemberPrivilegeGiftFlag = 00000000 32位       迅玩 特权礼包       领取标志(1位：白金会员；2位：超级会员；3位：白金年费会员；4位：超级年费会员；)
        MemberDailyGiftFlag = 00000000 32位           迅玩 每日礼包       领取标志(1位：白金会员；2位：超级会员；3位：白金年费会员；4位：超级年费会员；)   
    }
]]--


--活动类型
ActivityType = 10037
--对应的活动配置
ActivityConfig = PlatformxunwanConfig
ActivityTitleConfig = XunwantitleConfig


local PfId = System.getPfId()


function GetXunWanUserData(pActor)
    local var = Actor.getStaticVar(pActor)
    if nil == var.XunWanUserData then
        var.XunWanUserData = {}
    end
    return var.XunWanUserData
end

-- 发送 迅玩 会员礼包领取标志
function SendXunWanUserData(pActor)
    print("ActivityType10037 SendXunWanUserData actorName : "..Actor.getName(pActor))

    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, cSendXunWanUserData)
    if npack then
        local userData = GetXunWanUserData(pActor)

        DataPack.writeUInt(npack, userData.MemberTitleGiftFlag)
        DataPack.writeUInt(npack, userData.MemberPrivilegeGiftFlag)
        DataPack.writeUInt(npack, userData.MemberDailyGiftFlag)
        DataPack.flush(npack)
    end
end

-- 发送 迅玩 会员专属称号礼包
function SendXunWanMemberTitleGift(pActor)
    print("ActivityType10037 SendXunWanMemberTitleGift actorName : "..Actor.getName(pActor))

    local userData = GetXunWanUserData(pActor)
    userData.ReqMainGiftType = 0

    if not userData.ReqSubGiftType or not ActivityTitleConfig then
        print("ActivityType10037 SendXunWanMemberTitleGift not userData.ReqSubGiftType or not ActivityTitleConfig")

        print(userData.ReqSubGiftType)

        --重置(请求奖励子类型与奖励索引相对应)
        userData.ReqSubGiftType = 0

        return
    end

    if userData.ReqSubGiftType < 1 or userData.ReqSubGiftType > #ActivityTitleConfig then
        print("ActivityType10037 SendXunWanMemberTitleGift actorName : "..Actor.getName(pActor).." userData.ReqSubGiftType < 1 or userData.ReqSubGiftType > #ActivityTitleConfig userData.ReqSubGiftType : "..userData.ReqSubGiftType)

        --重置(请求奖励子类型与奖励索引相对应)
        userData.ReqSubGiftType = 0

        return
    end

    if 1 == System.getIntBit(userData.MemberTitleGiftFlag, userData.ReqSubGiftType - 1) then
        print("ActivityType10037 SendXunWanMemberTitleGift actorName : "..Actor.getName(pActor).." already get memberLevel "..userData.ReqSubGiftType.." MemberTitleGift!")

        --重置(请求奖励子类型与奖励索引相对应)
        userData.ReqSubGiftType = 0

        return
    end

    if not ActivityTitleConfig[userData.ReqSubGiftType] or not ActivityTitleConfig[userData.ReqSubGiftType].titleReward then
        print("ActivityType10037 SendXunWanMemberTitleGift not ActivityTitleConfig[userData.ReqSubGiftType] or not ActivityTitleConfig[userData.ReqSubGiftType].titleReward userData.ReqSubGiftType : "..userData.ReqSubGiftType)

        --重置(请求奖励子类型与奖励索引相对应)
        userData.ReqSubGiftType = 0

        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("ActivityType10037 SendXunWanMemberTitleGift actorName : "..Actor.getName(pActor).." not CheckBagIsEnough")

        --重置(请求奖励子类型与奖励索引相对应)
        userData.ReqSubGiftType = 0

        return
    end

    -- 设置标志
    userData.MemberTitleGiftFlag = System.setIntBit(userData.MemberTitleGiftFlag, userData.ReqSubGiftType - 1, true)
    
    CommonFunc.Awards.Give(pActor, ActivityTitleConfig[userData.ReqSubGiftType].titleReward, GameLog.Log_Activity10037)

    --重置(请求奖励子类型与奖励索引相对应)
    userData.ReqSubGiftType = 0

    SendXunWanUserData(pActor)
end

-- 发送 迅玩 会员特权礼包
function SendXunWanMemberPrivilegeGift(pActor)
    local userData = GetXunWanUserData(pActor)
    userData.ReqMainGiftType = 0

    if not userData.ReqSubGiftType or not ActivityConfig or not ActivityConfig.vipGift then
        print("ActivityType10037 SendXunWanMemberPrivilegeGift not userData.ReqSubGiftType or not ActivityConfig or not ActivityConfig.vipGift")

        print(userData.ReqSubGiftType)

        --重置(请求奖励子类型与奖励索引相对应)
        userData.ReqSubGiftType = 0

        return
    end

    if userData.ReqSubGiftType < 1 or userData.ReqSubGiftType > #ActivityConfig.vipGift then
        print("ActivityType10037 SendXunWanMemberPrivilegeGift actorName : "..Actor.getName(pActor).." userData.ReqSubGiftType < 1 or userData.ReqSubGiftType > #ActivityConfig.vipGift userData.ReqSubGiftType : "..userData.ReqSubGiftType)

        --重置(请求奖励子类型与奖励索引相对应)
        userData.ReqSubGiftType = 0

        return
    end

    if 1 == System.getIntBit(userData.MemberPrivilegeGiftFlag, userData.ReqSubGiftType - 1) then
        print("ActivityType10037 SendXunWanMemberPrivilegeGift actorName : "..Actor.getName(pActor).." already get memberLevel "..userData.ReqSubGiftType.." MemberPrivilegeGift!")

        --重置(请求奖励子类型与奖励索引相对应)
        userData.ReqSubGiftType = 0

        return
    end

    if not ActivityConfig.vipGift[userData.ReqSubGiftType] or not ActivityConfig.vipGift[userData.ReqSubGiftType].awards then
        print("ActivityType10037 SendXunWanMemberPrivilegeGift not ActivityConfig.vipGift[userData.ReqSubGiftType] or not ActivityConfig.vipGift[userData.ReqSubGiftType].awards userData.ReqSubGiftType : "..userData.ReqSubGiftType)

        --重置(请求奖励子类型与奖励索引相对应)
        userData.ReqSubGiftType = 0

        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("ActivityType10037 SendXunWanMemberPrivilegeGift actorName : "..Actor.getName(pActor).." not CheckBagIsEnough")

        --重置(请求奖励子类型与奖励索引相对应)
        userData.ReqSubGiftType = 0

        return
    end

    -- 设置标志
    userData.MemberPrivilegeGiftFlag = System.setIntBit(userData.MemberPrivilegeGiftFlag, userData.ReqSubGiftType - 1, true)
    
    CommonFunc.Awards.Give(pActor, ActivityConfig.vipGift[userData.ReqSubGiftType].awards, GameLog.Log_Activity10037)

    --重置(请求奖励子类型与奖励索引相对应)
    userData.ReqSubGiftType = 0

    SendXunWanUserData(pActor)
end

-- 发送 迅玩 会员每日礼包
function SendXunWanMemberDailyGift(pActor)
    local userData = GetXunWanUserData(pActor)
    userData.ReqMainGiftType = 0

    if not userData.ReqSubGiftType or not ActivityConfig or not ActivityConfig.dailyGift then
        print("ActivityType10037 SendXunWanMemberDailyGift not userData.ReqSubGiftType or not ActivityConfig or not ActivityConfig.dailyGift")

        print(userData.ReqSubGiftType)

        --重置(请求奖励子类型与奖励索引相对应)
        userData.ReqSubGiftType = 0

        return
    end

    if userData.ReqSubGiftType < 1 or userData.ReqSubGiftType > #ActivityConfig.dailyGift then
        print("ActivityType10037 SendXunWanMemberDailyGift actorName : "..Actor.getName(pActor).." userData.ReqSubGiftType < 1 or userData.ReqSubGiftType > #ActivityConfig.dailyGift userData.ReqSubGiftType : "..userData.ReqSubGiftType)

        --重置(请求奖励子类型与奖励索引相对应)
        userData.ReqSubGiftType = 0

        return
    end

    if 1 == System.getIntBit(userData.MemberDailyGiftFlag, userData.ReqSubGiftType - 1) then
        print("ActivityType10037 SendXunWanMemberDailyGift actorName : "..Actor.getName(pActor).." already get memberLevel "..userData.ReqSubGiftType.." MemberDailyGift!")

        --重置(请求奖励子类型与奖励索引相对应)
        userData.ReqSubGiftType = 0

        return
    end

    if not ActivityConfig.dailyGift[userData.ReqSubGiftType] or not ActivityConfig.dailyGift[userData.ReqSubGiftType].awards then
        print("ActivityType10037 SendXunWanMemberDailyGift not ActivityConfig.dailyGift[userData.ReqSubGiftType] or not ActivityConfig.dailyGift[userData.ReqSubGiftType].awards userData.ReqSubGiftType : "..userData.ReqSubGiftType)

        --重置(请求奖励子类型与奖励索引相对应)
        userData.ReqSubGiftType = 0

        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("ActivityType10037 SendXunWanMemberDailyGift actorName : "..Actor.getName(pActor).." not CheckBagIsEnough")

        --重置(请求奖励子类型与奖励索引相对应)
        userData.ReqSubGiftType = 0

        return
    end

    -- 设置标志
    userData.MemberDailyGiftFlag = System.setIntBit(userData.MemberDailyGiftFlag, userData.ReqSubGiftType - 1, true)
    
    CommonFunc.Awards.Give(pActor, ActivityConfig.dailyGift[userData.ReqSubGiftType].awards, GameLog.Log_Activity10037)

    --重置(请求奖励子类型与奖励索引相对应)
    userData.ReqSubGiftType = 0

    SendXunWanUserData(pActor)
end


--------------------------------------------------------------------
-- 客户端请求协议回调
--------------------------------------------------------------------

-- 迅玩 玩家登录
function OnReqXunWanLogin(pActor)
    print("ActivityType10037 OnReqXunWanLogin actorName : "..Actor.getName(pActor))
    -- 平台验证
    if not PfId then
        print("ActivityType10037 OnReqXunWanLogin not PfId")
        return 
    end
    if not ActivityConfig then
        print("ActivityType10037 OnReqXunWanLogin not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("ActivityType10037 OnReqXunWanLogin not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("ActivityType10037 OnReqXunWanLogin [非本平台活动]")  
        return --非本平台活动
    end

    local userData = GetXunWanUserData(pActor)
    if nil == userData.MemberTitleGiftFlag then
        userData.MemberTitleGiftFlag = 0
    end
    if nil == userData.MemberPrivilegeGiftFlag then
        userData.MemberPrivilegeGiftFlag = 0
    end
    if nil == userData.MemberDailyGiftFlag then
        userData.MemberDailyGiftFlag = 0
    end

    SendXunWanUserData(pActor)
end

-- 请求 迅玩 奖励
function OnReqXunWanGift(pActor, packet)
    print("ActivityType10037 OnReqXunWanGift actorName : "..Actor.getName(pActor))
    -- 平台验证
    if not PfId then
        print("ActivityType10037 OnReqXunWanGift not PfId")
        return 
    end
    if not ActivityConfig then
        print("ActivityType10037 OnReqXunWanGift not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("ActivityType10037 OnReqXunWanGift not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("ActivityType10037 OnReqXunWanGift [非本平台活动]")  
        return --非本平台活动
    end

    local userData = GetXunWanUserData(pActor)
    userData.ReqMainGiftType = DataPack.readByte(packet)
    userData.ReqSubGiftType = DataPack.readByte(packet)

    if not userData.ReqMainGiftType or userData.ReqMainGiftType < 1 or userData.ReqMainGiftType > 3 then
        print("ActivityType10037 OnReqXunWanGift actorName : "..Actor.getName(pActor).." userData.ReqMainGiftType < 1 or userData.ReqMainGiftType > 3")
        
        print(userData.ReqMainGiftType)
        
        return
    end

    if 1 == userData.ReqMainGiftType then       -- 1：获取会员专属称号礼包；
        SendXunWanMemberTitleGift(pActor)
    elseif 2 == userData.ReqMainGiftType  then  -- 2：获取会员特权礼包；
        SendXunWanMemberPrivilegeGift(pActor)
    elseif 3 == userData.ReqMainGiftType  then  -- 3：会员每日礼包；
        SendXunWanMemberDailyGift(pActor)
    end
end


--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 跨天
function OnNewDayArrive(pActor,ndiffday)
    print("ActivityType10037 OnNewDayArrive actorName : "..Actor.getName(pActor).." 跨 "..ndiffday.." 天")
    local userData = GetXunWanUserData(pActor)
    if userData.MemberDailyGiftFlag then
        userData.MemberDailyGiftFlag = 0
        SendXunWanUserData(pActor)
    end
end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10037.lua")

NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqXunWanLogin, OnReqXunWanLogin)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqXunWanGift, OnReqXunWanGift)
