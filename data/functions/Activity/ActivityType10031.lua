module("ActivityType10031", package.seeall)


--[[
    个人数据：userData
    {
        PlatformLoginType = 0 ~ 3       贪玩 设备登录类型 pc:(0：网页登录；1：盒子登录)；2：手机登录；
        ReqMainGiftType                 贪玩 请求奖励类型 1：获取SVIP礼包领取状态；2：获取 绑定手机礼包；3：获取 QQ群 礼包 领取状态；4：获取 微信礼包 领取状态；5：获取 实名认证 礼包；6：获取 盒子下载 礼包；7：获取 三端互通 礼包
        
        RealNameAuth = 0 or 1           贪玩 实名认证 0：未实名认证；1：已实名认证
        BindPhone = 0 or 1              贪玩 绑定手机 0：未绑定手机；1：已绑定手机
        Age =                           贪玩 年龄

        PlatformLoginFlag               贪玩 设备登录类型标志 
        SVIPGiftFlag = 0 or 1           贪玩 SVIP 礼包领取标志
        BindPhoneGiftFlag = 0 or 1      贪玩 绑定手机 礼包领取标志
        QQGroupeGiftFlag = 0 or 1       贪玩 QQ群 礼包领取标志
        WeChatGiftFlag = 0 or 1         贪玩 微信 礼包领取标志
        RealNameAuthGiftFlag = 0 or 1   贪玩 实名认证 礼包领取标志
        DownLoadBoxGiftFlag = 0 or 1    贪玩 盒子下载 礼包领取标志
        PlatformLoginGiftFlag =         贪玩 三端互通 礼包领取标志
    }
]]--


--活动类型
ActivityType = 10031
--对应的活动配置
ActivityConfig = PlatformTanwanConfig


local PfId = System.getPfId()


local HttpStatus = {
    Failure = "0",   -- 请求失败
    Success = "1",	 -- 获取成功
}


-- 服务接口
Host = "www.tanwan.com"
Api = "/api/check_bind_idcard.php"
Port = ActivityConfig.port or "80"

function GetTanWanUserData(pActor)
    local var = Actor.getStaticVar(pActor)
    if nil == var.TanWanUserData then
        var.TanWanUserData = {}
    end
    return var.TanWanUserData
end


--------------------------------------------------------------------
-- 发送数据到客户端
--------------------------------------------------------------------


-- 发送 贪玩 玩家数据
function SendTanWanUserData(pActor)
    print("[Tip] ActivityType10031 SendTanWanUserData actorName : "..Actor.getName(pActor))

    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, cSendTanWanGift)
    if npack then
        local userData = GetTanWanUserData(pActor)

        DataPack.writeByte(npack, userData.RealNameAuth)
        DataPack.writeByte(npack, userData.BindPhone)

        DataPack.writeByte(npack, userData.PlatformLoginFlag)
        DataPack.writeByte(npack, userData.SVIPGiftFlag)
        DataPack.writeByte(npack, userData.BindPhoneGiftFlag)
        DataPack.writeByte(npack, userData.QQGroupeGiftFlag)
        DataPack.writeByte(npack, userData.WeChatGiftFlag)
        DataPack.writeByte(npack, userData.RealNameAuthGiftFlag)
        DataPack.writeByte(npack, userData.DownLoadBoxGiftFlag)
        DataPack.writeByte(npack, userData.PlatformLoginGiftFlag)
        DataPack.flush(npack)
    end
end

-- 检查玩家 SVIP礼包 领取状态
function CheckSVIPGift(pActor)
    print("[Tip] ActivityType10031 CheckSVIPGift actorName : "..Actor.getName(pActor))

    local userData = GetTanWanUserData(pActor)
    userData.ReqMainGiftType = 0

    if 1 == userData.SVIPGiftFlag then
        print("[Tip] ActivityType10031 CheckSVIPGift actorName : "..Actor.getName(pActor).." already get SVIPGift")
        return
    end

    if not ActivityConfig or not ActivityConfig.SVIPReward then
        print("[Tip] ActivityType10031 CheckSVIPGift not ActivityConfig or not ActivityConfig.SVIPReward")
        return
    end

    local cdkdata = getActorCdkData(pActor)
    if cdkdata then
        if cdkdata.codeTypeTimes then
            if cdkdata.codeTypeTimes[ActivityConfig.SVIPReward] then
                userData.SVIPGiftFlag = 1
            else
                print("[Tip] ActivityType10031 CheckSVIPGift actorName : "..Actor.getName(pActor).." not cdkdata.codeTypeTimes[ActivityConfig.SVIPReward]")
            end
        else
            print("[Tip] ActivityType10031 CheckSVIPGift actorName : "..Actor.getName(pActor).." not cdkdata.codeTypeTimes")
        end
    else
        print("[Tip] ActivityType10031 CheckSVIPGift actorName : "..Actor.getName(pActor).." not cdkdata")
    end

    SendTanWanUserData(pActor)
end

-- 发送 手机绑定礼包
function SendBindPhoneGift(pActor)
    print("[Tip] ActivityType10031 SendBindPhoneGift actorName : "..Actor.getName(pActor))

    local userData = GetTanWanUserData(pActor)
    userData.ReqMainGiftType = 0

    -- print("userData.BindPhone : "..userData.BindPhone)
    if 0 == userData.BindPhone then
        print("[Tip] ActivityType10031 SendBindPhoneGift actorName : "..Actor.getName(pActor).." 0 == userData.BindPhone")
        return
    end

    if 1 == userData.BindPhoneGiftFlag then
        print("[Tip] ActivityType10031 SendBindPhoneGift actorName : "..Actor.getName(pActor).." already get BindPhoneGift")
        return
    end

    if not ActivityConfig or not ActivityConfig.PhoneReward then
        print("[Tip] ActivityType10031 SendBindPhoneGift not ActivityConfig or not ActivityConfig.PhoneReward")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10031 SendBindPhoneGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.BindPhoneGiftFlag = 1
    
    CommonFunc.Awards.Give(pActor, ActivityConfig.PhoneReward, GameLog.Log_Activity10031)

    SendTanWanUserData(pActor)
end

-- 检查玩家 QQ群礼包 领取状态
function CheckQQGroupGift(pActor)
    print("[Tip] ActivityType10031 CheckQQGroupGift actorName : "..Actor.getName(pActor))

    local userData = GetTanWanUserData(pActor)
    userData.ReqMainGiftType = 0

    if 1 == userData.QQGroupeGiftFlag then
        print("[Tip] ActivityType10031 CheckQQGroupGift actorName : "..Actor.getName(pActor).." already get QQGroupeGift")
        return
    end

    if not ActivityConfig or not ActivityConfig.QQReward then
        print("[Tip] ActivityType10031 CheckQQGroupGift not ActivityConfig or not ActivityConfig.QQReward")
        return
    end

    local cdkdata = getActorCdkData(pActor)
    if cdkdata then
        if cdkdata.codeTypeTimes then
            if cdkdata.codeTypeTimes[ActivityConfig.QQReward] then
                userData.QQGroupeGiftFlag = 1
            else
                print("[Tip] ActivityType10031 CheckQQGroupGift actorName : "..Actor.getName(pActor).." not cdkdata.codeTypeTimes[ActivityConfig.QQReward]")
            end
        else
            print("[Tip] ActivityType10031 CheckQQGroupGift actorName : "..Actor.getName(pActor).." not cdkdata.codeTypeTimes")
        end
    else
        print("[Tip] ActivityType10031 CheckQQGroupGift actorName : "..Actor.getName(pActor).." not cdkdata")
    end

    SendTanWanUserData(pActor)
end

-- 检查玩家 SVIP礼包 领取状态
function CheckWeChatGift(pActor)
    print("[Tip] ActivityType10031 CheckWeChatGift actorName : "..Actor.getName(pActor))

    local userData = GetTanWanUserData(pActor)
    userData.ReqMainGiftType = 0

    if 1 == userData.WeChatGiftFlag then
        print("[Tip] ActivityType10031 CheckWeChatGift actorName : "..Actor.getName(pActor).." already get WeChatGift")
        return
    end

    if not ActivityConfig or not ActivityConfig.WechatReward then
        print("[Tip] ActivityType10031 CheckWeChatGift not ActivityConfig or not ActivityConfig.WechatReward")
        return
    end

    local cdkdata = getActorCdkData(pActor)
    if cdkdata then
        if cdkdata.codeTypeTimes then
            if cdkdata.codeTypeTimes[ActivityConfig.WechatReward] then
                userData.WeChatGiftFlag = 1
            else
                print("[Tip] ActivityType10031 CheckWeChatGift actorName : "..Actor.getName(pActor).." not cdkdata.codeTypeTimes[ActivityConfig.WechatReward]")
            end
        else
            print("[Tip] ActivityType10031 CheckWeChatGift actorName : "..Actor.getName(pActor).." not cdkdata.codeTypeTimes")
        end
    else
        print("[Tip] ActivityType10031 CheckWeChatGift actorName : "..Actor.getName(pActor).." not cdkdata")
    end

    SendTanWanUserData(pActor)
end

-- 发送 实名认证礼包
function SendRealNameAuthGift(pActor)
    print("[Tip] ActivityType10031 SendRealNameAuthGift actorName : "..Actor.getName(pActor))

    local userData = GetTanWanUserData(pActor)
    userData.ReqMainGiftType = 0

    -- print("userData.RealNameAuth : "..userData.RealNameAuth)
    if 0 == userData.RealNameAuth then
        print("[Tip] ActivityType10031 SendRealNameAuthGift actorName : "..Actor.getName(pActor).." 0 == userData.RealNameAuth")
        return
    end

    if 1 == userData.RealNameAuthGiftFlag then
        print("[Tip] ActivityType10031 SendRealNameAuthGift actorName : "..Actor.getName(pActor).." already get RealNameAuthGift")
        return
    end

    if not ActivityConfig or not ActivityConfig.IdentityReward then
        print("[Tip] ActivityType10031 SendRealNameAuthGift not ActivityConfig or not ActivityConfig.IdentityReward")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10031 SendRealNameAuthGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.RealNameAuthGiftFlag = 1
    
    CommonFunc.Awards.Give(pActor, ActivityConfig.IdentityReward, GameLog.Log_Activity10031)

    SendTanWanUserData(pActor)
end

-- 发送 盒子下载 礼包
function SendDownLoadBoxGift(pActor)
    print("[Tip] ActivityType10031 SendDownLoadBoxGift actorName : "..Actor.getName(pActor))

    local userData = GetTanWanUserData(pActor)
    userData.ReqMainGiftType = 0

    if 1 ~= userData.PlatformLoginType then
        print("[Tip] ActivityType10031 SendDownLoadBoxGift actorName : "..Actor.getName(pActor).." 1 ~= userData.PlatformLoginType")
        return
    end

    if 1 == userData.DownLoadBoxGiftFlag then
        print("[Tip] ActivityType10031 SendDownLoadBoxGift actorName : "..Actor.getName(pActor).." already get DownLoadBoxGift")
        return
    end

    if not ActivityConfig or not ActivityConfig.DownLoadBoxGift then
        print("[Tip] ActivityType10031 SendDownLoadBoxGift not ActivityConfig or not ActivityConfig.DownLoadBoxGift")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10031 SendDownLoadBoxGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.DownLoadGameBoxGiftFlag = 1
    
    CommonFunc.Awards.Give(pActor, ActivityConfig.DownLoadBoxGift, GameLog.Log_Activity10031)

    SendTanWanUserData(pActor)
end

-- 发送 三端互通 礼包
function SendPlatformLoginGift(pActor)
    print("[Tip] ActivityType10031 SendPlatformLoginGift actorName : "..Actor.getName(pActor))

    local userData = GetTanWanUserData(pActor)
    userData.ReqMainGiftType = 0

    if 1 == userData.PlatformLoginGiftFlag then
        print("[Tip] ActivityType10031 SendPlatformLoginGift actorName : "..Actor.getName(pActor).." already get PlatformLoginGift")
        return
    end

    if 4 >= userData.PlatformLoginFlag then
        print("[Tip] ActivityType10031 SendPlatformLoginGift actorName : "..Actor.getName(pActor).."4 >= userData.PlatformLoginFlag")
        return
    end

    if not ActivityConfig or not ActivityConfig.ClientReward then
        print("[Tip] ActivityType10031 SendPlatformLoginGift not ActivityConfig or not ActivityConfig.ClientReward")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10031 SendPlatformLoginGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.PlatformLoginGiftFlag = 1
    
    CommonFunc.Awards.Give(pActor, ActivityConfig.ClientReward, GameLog.Log_Activity10031)

    SendTanWanUserData(pActor)
end


--------------------------------------------------------------------
-- 请求平台玩家数据信息
--------------------------------------------------------------------


-- 设置 贪玩手机绑定、防沉迷信息
function SetTanWanUserInfo(paramPack,content,result)
    local nActorId = paramPack[1]
    local pActor = Actor.getActorById(nActorId)
    if not pActor then
        print("[Tip] ActivityType10031 SetTanWanUserInfo [" .. nActorId .. "] 已离线")
        return
    end
    print("[Tip] ActivityType10031 SetTanWanUserInfo [" .. Actor.getName(pActor) .. "] content:"..content)
    print("[Tip] ActivityType10031 SetTanWanUserInfo [" .. Actor.getName(pActor) .. "] result:"..result)

    if 0 == result then
        local status = string.match(content,"\"ret\":(%d+)")
        -- print(status)
        if (HttpStatus.Success == status) then
            local strRealNameAuth = string.match(content,"\"is_adult\":(%d+)")
            local strBindPhone = string.match(content,"\"bind_mobile\":(%d+)")
            local strAge = string.match(content,"\"Age\":(%d+)")

            local nRealNameAuth = 0
            local nBindPhone = 0
            local nAge = 0

            if "null" ~= strRealNameAuth then
                nRealNameAuth = tonumber(strRealNameAuth)
            end
            if "null" ~= strBindPhone then
                nBindPhone = tonumber(strBindPhone)
            end
            if "null" ~= strAge then
                nAge = tonumber(strAge)
            end

            local userData = GetTanWanUserData(pActor)
            userData.RealNameAuth = nRealNameAuth
            userData.BindPhone = nBindPhone
            userData.Age = nAge

            -- print(userData.ReqMainGiftType)

            if 0 == userData.ReqMainGiftType then
                SendTanWanUserData(pActor)
            elseif 2 == userData.ReqMainGiftType then -- 获取 绑定手机 礼包
                SendBindPhoneGift(pActor)
            elseif 5 == userData.ReqMainGiftType then -- 获取 实名认证 礼包
                SendRealNameAuthGift(pActor)
            end
        end
    end
end


-- 请求 贪玩手机绑定、防沉迷信息
function ReqTanWanUserInfo(pActor)
    print("[Tip] ActivityType10031 ReqTanWanUserInfo actorName : "..Actor.getName(pActor))

    local nActorId = Actor.getActorId(pActor)
    
    local userid = Actor.getAccount(pActor)
    local time = os.time()
    local key = "TWswCMjaS1ba4b1c5cUHFXAzLYy4f5uG"
    local sign = System.MD5(time..userid..System.MD5(key))

    local req = Api..'?userid='..userid..'&time='..time..'&sign='..sign

    print("[Tip] ActivityType10024 ReqMasterLuUserInfo [" .. Actor.getName(pActor) .. "] : ".. Host)
    print("[Tip] ActivityType10024 ReqMasterLuUserInfo [" .. Actor.getName(pActor) .. "] : ".. Port)
    print("[Tip] ActivityType10024 ReqMasterLuUserInfo [" .. Actor.getName(pActor) .. "] : ".. req)

    AsyncWorkDispatcher.Add(
        {'GetHttpContent',Host,Port,req},
        SetTanWanUserInfo,
        {nActorId}
    )
end


--------------------------------------------------------------------
-- 客户端请求协议回调
--------------------------------------------------------------------


-- 贪玩 玩家登录
function OnReqTanWanLogin(pActor, packet)
    print("[Tip] ActivityType10031 OnReqTanWanLogin actorName : "..Actor.getName(pActor))

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10031 OnReqTanWanLogin not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10031 OnReqTanWanLogin not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10031 OnReqTanWanLogin not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10031 OnReqTanWanLogin [非本平台活动]")  
        return --非本平台活动
    end

    -- 初始化 玩家数据
    local userData = GetTanWanUserData(pActor)
    userData.PlatformLoginType = DataPack.readByte(packet)

    if userData.PlatformLoginType < 0 or userData.PlatformLoginType > 2 then
        print("[Tip] ActivityType10031 OnReqTanWanLogin userData.PlatformLoginType < 0 or userData.PlatformLoginType > 2 actorName : "..Actor.getName(pActor))
        return  
    end

    if nil == userData.PlatformLoginType then
        userData.PlatformLoginType = 0
    end
    if nil == userData.ReqMainGiftType then
        userData.ReqMainGiftType = 0
    end
    if nil == userData.RealNameAuth then
        userData.RealNameAuth = 0
    end
    if nil == userData.BindPhone then
        userData.BindPhone = 0
    end
    if nil == userData.Age then
        userData.Age = 0
    end
    if nil == userData.PlatformLoginFlag then
        userData.PlatformLoginFlag = 0
    end
    if nil == userData.SVIPGiftFlag then
        userData.SVIPGiftFlag = 0
    end
    if nil == userData.BindPhoneGiftFlag then
        userData.BindPhoneGiftFlag = 0
    end
    if nil == userData.QQGroupeGiftFlag then
        userData.QQGroupeGiftFlag = 0
    end
    if nil == userData.WeChatGiftFlag then
        userData.WeChatGiftFlag = 0
    end
    if nil == userData.RealNameAuthGiftFlag then
        userData.RealNameAuthGiftFlag = 0
    end
    if nil == userData.DownLoadBoxGiftFlag then
        userData.DownLoadBoxGiftFlag = 0
    end
    if nil == userData.PlatformLoginGiftFlag then
        userData.PlatformLoginGiftFlag = 0
    end

    -- print("userData.PlatformLoginType : "..userData.PlatformLoginType)
    -- print("userData.PlatformLoginFlag 1111 : "..userData.PlatformLoginFlag)
    if 0 == System.getIntBit(userData.PlatformLoginFlag, userData.PlatformLoginType) then
        userData.PlatformLoginFlag = System.setIntBit(userData.PlatformLoginFlag, userData.PlatformLoginType, true)
        -- print("userData.PlatformLoginFlag 2222 : "..userData.PlatformLoginFlag)
    end

    -- 请求 贪玩平台 用户信息
    ReqTanWanUserInfo(pActor)
end


-- 贪玩 玩家登录
function OnReqTanWanGift(pActor, packet)
    print("[Tip] ActivityType10031 OnReqTanWanGift actorName : "..Actor.getName(pActor))

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10031 OnReqTanWanGift not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10031 OnReqTanWanGift not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10031 OnReqTanWanGift not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10031 OnReqTanWanGift [非本平台活动]")  
        return --非本平台活动
    end

    -- 初始化 玩家数据
    local userData = GetTanWanUserData(pActor)
    userData.ReqMainGiftType = DataPack.readByte(packet)

    if not userData.ReqMainGiftType or userData.ReqMainGiftType < 1 or userData.ReqMainGiftType > 7 then
        print("[Tip] ActivityType10031 OnReqTanWanGift actorName : "..Actor.getName(pActor).." not userData.ReqMainGiftType or userData.ReqMainGiftType < 1 or userData.ReqMainGiftType > 7")
        return 
    end

    if 1 == userData.ReqMainGiftType then -- 获取 SVIP 礼包领取状态
        CheckSVIPGift(pActor)
    elseif 2 == userData.ReqMainGiftType or 5 == userData.ReqMainGiftType then -- 获取 绑定手机 或 实名认证礼包
        ReqTanWanUserInfo(pActor)
    elseif 3 == userData.ReqMainGiftType then -- 获取 QQ群 礼包领取状态
        CheckQQGroupGift(pActor)
    elseif 4 == userData.ReqMainGiftType then -- 获取 微信 礼包领取状态
        CheckWeChatGift(pActor)
    elseif 6 == userData.ReqMainGiftType then -- 获取 盒子下载 礼包
        SendDownLoadBoxGift(pActor)
    elseif 7 == userData.ReqMainGiftType then -- 获取 三端互通 礼包
        SendPlatformLoginGift(pActor)
    end
end


NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqTanWanLogin, OnReqTanWanLogin)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqTanWanGift, OnReqTanWanGift)