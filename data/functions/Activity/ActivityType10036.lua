module("ActivityType10036", package.seeall)


--[[
    个人数据：userData
    {
        ReqMainGiftType                 顺网 请求奖励类型 0：默认类型(服务器自用)；1：获取微信礼包码领取状态；2：获取绑定手机礼包码领取状态；3：获取防沉迷礼包码领取状态；4：领取盒子下载礼包；5：获取登录礼包；6: 领取等级礼包
        ReqSubGiftType                  顺网 请求子奖励类型 0：默认类型(服务器自用)；1~7：请求登录奖励的天数 或 请求等级礼包的级数 
        LoginType = 0 ~ 3               顺网 登录类型 盒子登录：3
        LastLoginTime                   上一次登录时间


        LoginDays = 1~7                 顺网 盒子登录天数
        WeChatGiftFlag = 0 or 1         顺网 微信礼包 领取标志
        BindPhoneGiftFlag = 0 or 1      顺网 手机绑定礼包 领取标志
        FcmGiftFlag = 0 or 1            顺网 防沉迷礼包 领取标志
        BoxDownLoadGiftFlag = 0 or 1    顺网 盒子下载 领取标志
        BoxLoginGiftFlag                顺网 登录礼包 领取标志(只能领取七天)
        BoxLevelGiftFlag(Uint64)        顺网 等级礼包 领取标志
    }
]]--


--活动类型
ActivityType = 10036
--对应的活动配置
ActivityConfig = PlatformshunwangConfig


local PfId = System.getPfId()


function GetSWUserData(pActor)
    local var = Actor.getStaticVar(pActor)
    if nil == var.UserDataSW then
        var.UserDataSW = {}
    end
    return var.UserDataSW
end

-- 发送 顺网 玩家数据
function SendSWUserData(pActor)
    print("ActivityType10036 SendSWUserData actorName : "..Actor.getName(pActor))

    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, cSendSWUserData)
    if npack then
        local userData = GetSWUserData(pActor)

        -- print("userData.LoginDays 1111")
        -- print(userData.LoginDays)
        -- print("userData.LoginDays 2222")

        DataPack.writeUint64(npack, userData.LoginDays)
        DataPack.writeByte(npack, userData.WeChatGiftFlag)
        DataPack.writeByte(npack, userData.BindPhoneGiftFlag)
        DataPack.writeByte(npack, userData.FcmGiftFlag)
        DataPack.writeByte(npack, userData.BoxDownLoadGiftFlag)
        DataPack.writeByte(npack, userData.BoxLoginGiftFlag)
        DataPack.writeUint64(npack, userData.BoxLevelGiftFlag)
        DataPack.flush(npack)
    end
end

-- 查看 顺网 微信礼包领取情况
function CheckWeChatGift(pActor)
    print("ActivityType10036 CheckWeChatGift actorName : "..Actor.getName(pActor))
    
    local userData = GetSWUserData(pActor)
    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType = 0

    if not ActivityConfig or not ActivityConfig.WechatReward then
        print("ActivityType10036 CheckWeChatGift not ActivityConfig or not ActivityConfig.WechatReward")
        return
    end
    
    local cdkdata = getActorCdkData(pActor)
    if cdkdata then
        -- 微信礼包
        if cdkdata.codeTypeTimes then
            if cdkdata.codeTypeTimes[ActivityConfig.WechatReward] then
                userData.WeChatGiftFlag = 1
            end
        else
            print("ActivityType10036 CheckWeChatGift not cdkdata.codeTypeTimes")
        end
    else
        print("ActivityType10036 CheckWeChatGift not cdkdata")
    end

    SendSWUserData(pActor)
end

-- 查看 顺网 绑定手机礼包领取情况
function CheckBindPhoneGift(pActor)
    print("ActivityType10036 CheckBindPhoneGift actorName : "..Actor.getName(pActor))

    local userData = GetSWUserData(pActor)
    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType = 0

    if not ActivityConfig or not ActivityConfig.bindPhoneReward then
        print("ActivityType10036 CheckBindPhoneGift not ActivityConfig or not ActivityConfig.bindPhoneReward")
        return
    end

    local cdkdata = getActorCdkData(pActor)
    if cdkdata then
        -- 绑定手机礼包
        if cdkdata.codeTypeTimes then
            if cdkdata.codeTypeTimes[ActivityConfig.bindPhoneReward] then
                userData.WeChatGiftFlag = 1
            end
        else
            print("ActivityType10036 CheckBindPhoneGift not cdkdata.codeTypeTimes")
        end
    else
        print("ActivityType10036 CheckBindPhoneGift not cdkdata")
    end

    SendSWUserData(pActor)
end

-- 查看 顺网 防沉迷礼包领取情况
function CheckFcmGift(pActor)
    print("ActivityType10036 CheckFcmGift actorName : "..Actor.getName(pActor))

    local userData = GetSWUserData(pActor)
    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType = 0

    if 1 == userData.FcmGiftFlag then
        print("ActivityType10036 CheckFcmGift actorName : "..Actor.getName(pActor).." already get FcmGift")
        return
    end

    if not ActivityConfig or not ActivityConfig.FcmReward then
        print("ActivityType10036 CheckFcmGift not ActivityConfig or not ActivityConfig.FcmReward")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("ActivityType10036 CheckFcmGift actorName : "..Actor.getName(pActor).." not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.FcmGiftFlag = 1
    
    CommonFunc.Awards.Give(pActor, ActivityConfig.FcmReward, GameLog.Log_Activity10036)

    SendSWUserData(pActor)
end

-- 领取 顺网 盒子下载礼包
function SendSWBoxDownLoadGift(pActor)
    print("ActivityType10036 SendSWBoxDownLoadGift actorName : "..Actor.getName(pActor))
    
    local userData = GetSWUserData(pActor)
    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType = 0

    if not userData.LoginType or 3 ~= userData.LoginType then
        print("ActivityType10036 SendSWBoxDownLoadGift actorName : "..Actor.getName(pActor).." not userData.LoginType or 3 ~= userData.LoginType")
        return
    end

    if 1 == userData.BoxDownLoadGiftFlag then
        print("ActivityType10036 SendSWBoxDownLoadGift actorName : "..Actor.getName(pActor).." already get BoxDownLoadGift")
        return
    end

    if not ActivityConfig or not ActivityConfig.downloadBoxReward then
        print("ActivityType10036 SendSWBoxDownLoadGift not ActivityConfig or not ActivityConfig.downloadBoxReward")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("ActivityType10036 SendSWBoxDownLoadGift actorName : "..Actor.getName(pActor).." not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.BoxDownLoadGiftFlag = 1
    
    CommonFunc.Awards.Give(pActor, ActivityConfig.downloadBoxReward, GameLog.Log_Activity10036)

    SendSWUserData(pActor)
end

-- 领取 顺网 盒子登录礼包
function SendSWBoxLoginGift(pActor)
    print("ActivityType10036 SendSWBoxLoginGift actorName : "..Actor.getName(pActor))
    
    local userData = GetSWUserData(pActor)
    userData.ReqMainGiftType = 0

    if not userData.LoginType or 3 ~= userData.LoginType then
        print("ActivityType10036 SendSWBoxLoginGift actorName : "..Actor.getName(pActor).." not userData.LoginType or 3 ~= userData.LoginType")

        --重置请求登录奖励天数
        userData.ReqSubGiftType = 0

        return
    end

    if not userData.ReqSubGiftType or userData.ReqSubGiftType < 1 or userData.ReqSubGiftType > 7 then
        print("ActivityType10036 SendSWBoxLoginGift actorName : "..Actor.getName(pActor).." not userData.ReqSubGiftType or userData.ReqSubGiftType < 1 or userData.ReqSubGiftType > 7")

        --重置请求登录奖励天数
        userData.ReqSubGiftType = 0

        return
    end

    if userData.ReqSubGiftType >= userData.LoginDays then
        print("ActivityType10036 SendSWBoxLoginGift actorName : "..Actor.getName(pActor).." userData.ReqSubGiftType >= userData.LoginDays userData.ReqSubGiftType : "..userData.ReqSubGiftType.." userData.LoginDays : "..userData.LoginDays)

        --重置请求登录奖励天数
        userData.ReqSubGiftType = 0

        return
    end

    if 1 == System.getIntBit(userData.BoxLoginGiftFlag, userData.ReqSubGiftType - 1) then
        print("ActivityType10036 SendSWBoxLoginGift actorName : "..Actor.getName(pActor).." already get BoxLoginGift")

        --重置请求登录奖励天数
        userData.ReqSubGiftType = 0

        return
    end

    if not ActivityConfig or not ActivityConfig.loginGift or not ActivityConfig.loginGift[userData.ReqSubGiftType] or not ActivityConfig.loginGift[userData.ReqSubGiftType].awards then
        print("ActivityType10036 SendSWBoxLoginGift not ActivityConfig or not ActivityConfig.loginGift or not ActivityConfig.loginGift[userData.ReqSubGiftType] or not ActivityConfig.loginGift[userData.ReqSubGiftType].awards")

        --重置请求登录奖励天数
        userData.ReqSubGiftType = 0

        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10036 SendSWBoxLoginGift actorName : "..Actor.getName(pActor).." not CheckBagIsEnough")

        --重置请求登录奖励天数
        userData.ReqSubGiftType = 0

        return
    end

    -- 设置标志
    userData.BoxLoginGiftFlag = System.setIntBit(userData.BoxLoginGiftFlag, userData.ReqSubGiftType - 1, true)
    
    CommonFunc.Awards.Give(pActor, ActivityConfig.loginGift[userData.ReqSubGiftType].awards, GameLog.Log_Activity10036)

    --重置请求登录奖励天数
    userData.ReqSubGiftType = 0

    SendSWUserData(pActor)
end

-- 领取 顺网 盒子等级礼包
function SendSWBoxLevelGift(pActor)
    print("ActivityType10036 SendSWBoxLevelGift actorName : "..Actor.getName(pActor))
    
    local userData = GetSWUserData(pActor)
    userData.ReqMainGiftType = 0

    if not userData.LoginType or 3 ~= userData.LoginType then
        print("ActivityType10036 SendSWBoxLevelGift actorName : "..Actor.getName(pActor).." not userData.LoginType or 3 ~= userData.LoginType")

        --重置请求等级奖励等级
        userData.ReqSubGiftType = 0

        return
    end

    if not userData.ReqSubGiftType or userData.ReqSubGiftType < 1 or userData.ReqSubGiftType > 65 then
        print("ActivityType10036 SendSWBoxLevelGift actorName : "..Actor.getName(pActor).." not userData.ReqSubGiftType or userData.ReqSubGiftType < 1 or userData.ReqSubGiftType > 65")

        --重置请求等级奖励等级
        userData.ReqSubGiftType = 0

        return
    end

    if 1 == System.getIntBit(userData.BoxLevelGiftFlag, userData.ReqSubGiftType - 1) then
        print("ActivityType10036 SendSWBoxLevelGift actorName : "..Actor.getName(pActor).." already get BoxLevelGift")

        --重置请求等级奖励等级
        userData.ReqSubGiftType = 0

        return
    end

    if not ActivityConfig or not ActivityConfig.levelGift then
        print("ActivityType10036 SendSWBoxLevelGift not ActivityConfig or not ActivityConfig.levelGift")

        --重置请求等级奖励等级
        userData.ReqSubGiftType = 0

        return
    end

    if not ActivityConfig.levelGift[userData.ReqSubGiftType] or not ActivityConfig.levelGift[userData.ReqSubGiftType].lvl or not ActivityConfig.levelGift[userData.ReqSubGiftType].awards then
        print("ActivityType10036 SendSWBoxLevelGift not ActivityConfig.levelGift[userData.ReqSubGiftType] or not ActivityConfig.levelGift[userData.ReqSubGiftType].lvl or not ActivityConfig.levelGift[userData.ReqSubGiftType].awards userData.ReqSubGiftType : "..userData.ReqSubGiftType)

        --重置请求等级奖励等级
        userData.ReqSubGiftType = 0

        return
    end

    local nLevel = Actor.getIntProperty(pActor, PROP_CREATURE_LEVEL)
    if nLevel < ActivityConfig.levelGift[userData.ReqSubGiftType].lvl then
        print("ActivityType10036 SendSWBoxLevelGift actorName : "..Actor.getName(pActor).." nLevel < ActivityConfig.levelGift[userData.ReqSubGiftType].lvl userData.ReqSubGiftType : "..userData.ReqSubGiftType)

        --重置请求等级奖励等级
        userData.ReqSubGiftType = 0

        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10036 SendSWBoxLevelGift actorName : "..Actor.getName(pActor).." not CheckBagIsEnough")

        --重置请求等级奖励等级
        userData.ReqSubGiftType = 0

        return
    end

    -- 设置标志
    userData.BoxLevelGiftFlag = System.setIntBit(userData.BoxLevelGiftFlag, userData.ReqSubGiftType - 1, true)
    
    CommonFunc.Awards.Give(pActor, ActivityConfig.levelGift[userData.ReqSubGiftType].awards, GameLog.Log_Activity10036)

    --重置请求等级奖励等级
    userData.ReqSubGiftType = 0

    SendSWUserData(pActor)
end

--------------------------------------------------------------------
-- 客户端请求协议回调
--------------------------------------------------------------------

-- 顺网 玩家登录
function OnReqSWLogin(pActor, packet)
    print("ActivityType10036 OnReqSWLogin actorName : "..Actor.getName(pActor))
    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10036 OnReqSWLogin not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10036 OnReqSWLogin not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10036 OnReqSWLogin not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10036 OnReqSWLogin [非本平台活动]")  
        return --非本平台活动
    end

    local userData = GetSWUserData(pActor)
    if nil == userData.WeChatGiftFlag then
        userData.WeChatGiftFlag = 0
    end
    if nil == userData.BindPhoneGiftFlag then
        userData.BindPhoneGiftFlag = 0
    end
    if nil == userData.FcmGiftFlag then
        userData.FcmGiftFlag = 0
    end
    if nil == userData.BoxDownLoadGiftFlag then
        userData.BoxDownLoadGiftFlag = 0
    end
    if nil == userData.BoxLevelGiftFlag then
        userData.BoxLevelGiftFlag = 0
    end
    if nil == userData.BoxLoginGiftFlag then
        userData.BoxLoginGiftFlag = 0
    end

    userData.LoginType = DataPack.readByte(packet)

    -- print("userData.LoginType1111")
    -- print(userData.LoginType)
    -- print("userData.LoginType2222")

    -- 当天初始化
    if 3 == userData.LoginType then
        if nil == userData.LastLoginTime then
            userData.LastLoginTime = System.getCurrMiniTime()
            userData.LoginDays = 1
            --print("第一天")
        else
            if not System.isSameDay(userData.LastLoginTime, System.getCurrMiniTime()) then
                --print("跨一天")
                userData.LastLoginTime = System.getCurrMiniTime()
                userData.LoginDays = userData.LoginDays + 1
            end
        end
    end

    SendSWUserData(pActor)
end

function OnReqSWGift(pActor, packet)
    print("ActivityType10036 OnReqSWGift actorName : "..Actor.getName(pActor))

    local userData = GetSWUserData(pActor)
    userData.ReqMainGiftType = DataPack.readByte(packet)
    userData.ReqSubGiftType = DataPack.readByte(packet)

    if userData.ReqMainGiftType < 1 or userData.ReqMainGiftType > 6 then
        print("ActivityType10036 OnReqSWGift actorName : "..Actor.getName(pActor).." userData.ReqMainGiftType < 1 or userData.ReqMainGiftType > 6")
        return
    end

    if 1 == userData.ReqMainGiftType then       -- 1：获取微信礼包码领取状态；
        CheckWeChatGift(pActor)
    elseif 2 == userData.ReqMainGiftType  then  -- 2：获取绑定手机礼包码领取状态；
        CheckBindPhoneGift(pActor)
    elseif 3 == userData.ReqMainGiftType  then  -- 3：获取防沉迷礼包码领取状态；
        CheckFcmGift(pActor)
    elseif 4 == userData.ReqMainGiftType  then  -- 4：领取盒子下载礼包；
        SendSWBoxDownLoadGift(pActor)
    elseif 5 == userData.ReqMainGiftType  then  -- 5：获取登录礼包;
        SendSWBoxLoginGift(pActor)
    elseif 6 == userData.ReqMainGiftType  then  -- 6: 领取等级礼包
        SendSWBoxLevelGift(pActor)
    end
end

NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqSWLogin, OnReqSWLogin)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqSWGift, OnReqSWGift)




