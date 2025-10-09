module("ActivityType10032", package.seeall)


--[[
    个人数据：userData
    {
        ReqMainGiftType                 哥们 请求奖励类型 0：默认类型(服务器自用)；1：绑定手机奖励

        BindPhone = 0 or 1              哥们 绑定手机 0：未绑定手机；1：已绑定手机
        BindPhoneGiftFlag = 0 or 1      哥们 绑定手机 礼包领取标志
    }
]]--


--活动类型
ActivityType = 10032
--对应的活动配置
ActivityConfig = PlatformGame2Config


local PfId = System.getPfId()


local HttpStatus = {
    Error = "0",     -- 请求错误
    Success = "1",	 -- 用户已绑定手机
    Failure = "2",	 -- 用户未绑定手机
}


-- 服务接口
Host = "ldsht.bigrnet.com"
Api = "/game2/user/index"
Port = "80"


function GetGame2UserData(pActor)
    local var = Actor.getStaticVar(pActor)
    if nil == var.Game2UserData then
        var.Game2UserData = {}
    end
    return var.Game2UserData
end


--------------------------------------------------------------------
-- 发送数据到客户端
--------------------------------------------------------------------


-- 发送 Game2 玩家数据
function SendGame2UserData(pActor)
    print("[Tip] ActivityType10032 SendGame2UserData actorName : "..Actor.getName(pActor))

    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, cSendTaGame2Gift)
    if npack then
        local userData = GetGame2UserData(pActor)

        DataPack.writeByte(npack, userData.BindPhone)
        DataPack.writeByte(npack, userData.BindPhoneGiftFlag)
        DataPack.flush(npack)
    end
end

-- 发送 Game2 绑定手机 奖励
function SendBindPhoneGift(pActor)
    print("[Tip] ActivityType10032 SendBindPhoneGift actorName : "..Actor.getName(pActor))

    local userData = GetGame2UserData(pActor)
    userData.ReqMainGiftType = 0

    if 1 ~= userData.BindPhone then
        print("[Tip] ActivityType10032 SendBindPhoneGift actorName : "..Actor.getName(pActor).." 1 ~= userData.BindPhone userData.BindPhone : "..userData.BindPhone)
        return
    end

    if 1 == userData.BindPhoneGiftFlag then
        print("[Tip] ActivityType10032 SendBindPhoneGift actorName : "..Actor.getName(pActor).." already get BindPhoneGift")
        return
    end

    if not ActivityConfig or not ActivityConfig.PhoneReward then
        print("[Tip] ActivityType10032 SendBindPhoneGift not ActivityConfig or not ActivityConfig.PhoneReward")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10032 SendBindPhoneGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.BindPhoneGiftFlag = 1
    
    CommonFunc.Awards.Give(pActor, ActivityConfig.PhoneReward, GameLog.Log_Activity10032)

    SendGame2UserData(pActor)
end


--------------------------------------------------------------------
-- 请求平台玩家数据信息
--------------------------------------------------------------------


-- 设置 Game2 玩家手机绑定状态
function SetGame2UserInfo(paramPack,content,result)
    local nActorId = paramPack[1]
    local pActor = Actor.getActorById(nActorId)
    if not pActor then
        print("[Tip] ActivityType10032 SetGame2UserInfo [" .. nActorId .. "] 已离线")
        return
    end
    print("[Tip] ActivityType10032 SetGame2UserInfo [" .. Actor.getName(pActor) .. "] content:"..content)
    print("[Tip] ActivityType10032 SetGame2UserInfo [" .. Actor.getName(pActor) .. "] result:"..result)

    if 0 == result then
        local status = string.match(content,"\"status\":(%d+)")
        local userData = GetGame2UserData(pActor)

        if (HttpStatus.Success == status) then
            userData.BindPhone = tonumber(status)
        end

        print("status : "..status.." userData.BindPhone : "..userData.BindPhone)

        if 0 == userData.ReqMainGiftType then
            SendGame2UserData(pActor)
        elseif 1 == userData.ReqMainGiftType then --请求手机绑定奖励
            SendBindPhoneGift(pActor)
        end
    end
end


-- 请求 贪玩手机绑定信息
function ReqGame2UserInfo(pActor)
    local nActorId = Actor.getActorId(pActor)
    
    local uid = Actor.getAccount(pActor)
    local req = Api..'?uid='..uid
    print("[Tip] ActivityType10032 ReqGame2UserInfo [" .. Actor.getName(pActor) .. "] : ".. Host)
    print("[Tip] ActivityType10032 ReqGame2UserInfo [" .. Actor.getName(pActor) .. "] : ".. Port)
    print("[Tip] ActivityType10032 ReqGame2UserInfo [" .. Actor.getName(pActor) .. "] : ".. req)


    AsyncWorkDispatcher.Add(
        {'GetHttpContent',Host,Port,req},
        SetGame2UserInfo,
        {nActorId}
    )
end


--------------------------------------------------------------------
-- 客户端请求协议回调
--------------------------------------------------------------------


-- 贪玩 玩家登录
function OnReqGame2Login(pActor)
    print("[Tip] ActivityType10032 OnReqGame2Login actorName : "..Actor.getName(pActor))

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10032 OnReqGame2Login not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10032 OnReqGame2Login not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10032 OnReqGame2Login not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10032 OnReqGame2Login [非本平台活动]")  
        return --非本平台活动
    end

    -- 初始化 玩家数据
    local userData = GetGame2UserData(pActor)
    if nil == userData.ReqMainGiftType then
        userData.ReqMainGiftType = 0
    end
    if nil == userData.BindPhone then
        userData.BindPhone = 0
    end
    if nil == userData.BindPhoneGiftFlag then
        userData.BindPhoneGiftFlag = 0
    end

    -- 请求 贪玩平台 用户信息
    ReqGame2UserInfo(pActor)
end

-- 贪玩 玩家登录
function OnReqGame2Gift(pActor, packet)
    print("[Tip] ActivityType10032 OnReqGame2Gift actorName : "..Actor.getName(pActor))

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10032 OnReqGame2Gift not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10032 OnReqGame2Gift not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10032 OnReqGame2Gift not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10032 OnReqGame2Gift [非本平台活动]")  
        return --非本平台活动
    end

    -- 初始化 玩家数据
    local userData = GetGame2UserData(pActor)
    userData.ReqMainGiftType = DataPack.readByte(packet)

    if not userData.ReqMainGiftType or userData.ReqMainGiftType < 1 or userData.ReqMainGiftType > 1 then
        print("[Tip] ActivityType10032 OnReqGame2Gift actorName : "..Actor.getName(pActor).." not userData.ReqMainGiftType or userData.ReqMainGiftType < 1 or userData.ReqMainGiftType > 1")
        return 
    end

    if 1 == userData.ReqMainGiftType then -- 获取 手机绑定 奖励
        ReqGame2UserInfo(pActor)
    end
end


NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqGame2Login, OnReqGame2Login)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqGame2Gift, OnReqGame2Gift)
