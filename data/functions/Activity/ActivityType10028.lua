module("ActivityType10028", package.seeall)


--[[
    个人数据：userData
    {
        ReqMainGiftType = 0 or 1        请求奖励主类型 1: 检查SVIP礼包是否领取；2：请求手机绑定礼包
        BindPhone = 0 or 1              QiDian 是否绑定手机：0：未绑定；1：已绑定
        SVIPGiftFlag      = 0 or 1      QiDian SVIP 礼包领取标志
        BindPhoneGiftFlag = 0 or 1      QiDian 手机绑定 礼包领取标志
    }
]]--


--活动类型
ActivityType = 10024
--对应的活动配置
ActivityConfig = PlatformqidianConfig


local PfId = System.getPfId()


local HttpStatus = {
    Success = "0",     -- 成功
    Other = "",        -- 失败
}


-- 服务接口
Host = "yyhunfurepeat.bigrnet.com"
Api = "/Service/GetQiDianCode.php"

Port = ActivityConfig.port or "80"



-- 设置 qidian用户数据
function SetQiDianUserData(paramPack,content,result)
    local nActorId = paramPack[1]
    local pActor = Actor.getActorById(nActorId)
    if not pActor then
        print("[Tip] ActivityType10028 SetQiDianUserData [" .. nActorId .. "] 已离线")
        return
    end
    print("[Tip] ActivityType10028 SetQiDianUserData [" .. Actor.getName(pActor) .. "] content:"..content)
    print("[Tip] ActivityType10028 SetQiDianUserData result:"..result)

    if 0 == result then
        local status = string.match(content,"\"ReturnCode\":(%d+)")
        if (HttpStatus.Success == status) then
            local strBindPhone = string.match(content,"\"bind\":(%d+)")

            local nBindPhone = 0

            if "null" ~= strBindPhone then
                nBindPhone = tonumber(strBindPhone)
            end

            local userData = GetQiDianUserData(pActor)
            userData.BindPhone = nBindPhone

            if 0 == userData.ReqMainGiftType then
                SendQiDianUserData(pActor)
            elseif 2 == userData.ReqMainGiftType then -- 领取 绑定手机礼包
                SendBindPhoneGift(pActor)
            end
        end
    end
end


function GetQiDianUserData(pActor)
    local var = Actor.getStaticVar(pActor)
    if nil == var.QiDianUserData then
        var.QiDianUserData = {}
    end
    return var.QiDianUserData
end

-- 发送 qidian玩家数据
function SendQiDianUserData(pActor)
    print("[Tip] ActivityType10028 SendQiDianUserData")
    local userData = GetQiDianUserData(pActor)
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSendQiDianUserData)
    if npack then
        DataPack.writeByte(npack, userData.BindPhone)
        DataPack.writeByte(npack, userData.SVIPGiftFlag)
        DataPack.writeByte(npack, userData.BindPhoneGiftFlag)
        DataPack.flush(npack)
    end
end


--------------------------------------------------------------------
-- 请求平台玩家数据信息
--------------------------------------------------------------------


-- 请求 qidian用户信息
function ReqQiDianUserInfo(pActor)
    print("[Tip] ActivityType10028 ReqQiDianUserInfo")

    local nActorId = Actor.getActorId(pActor)

    local gameId = 589
    local userId =  Actor.getAccount(pActor)
    local timestamp = os.time()
    local key = "8g9f87h64kj5hhgo456db1sv787e"

    local sign = System.MD5(gameId..timestamp..userId..key)
    local req = Api..'?gameId='..gameId..'&userId='..userId..'&timestamp='..timestamp..'&sign='..string.lower(sign)

    print("[Tip] ActivityType10028 ReqQiDianUserInfo [" .. Actor.getName(pActor) .. "] : ".. Host)
    print("[Tip] ActivityType10028 ReqQiDianUserInfo [" .. Actor.getName(pActor) .. "] : ".. Port)
    print("[Tip] ActivityType10028 ReqQiDianUserInfo [" .. Actor.getName(pActor) .. "] : ".. req)
    AsyncWorkDispatcher.Add(
        {'GetHttpContent',Host,Port,req},
        SetQiDianUserData,
        {nActorId}
    )
end


--------------------------------------------------------------------
-- 客户端请求协议回调
--------------------------------------------------------------------


-- 检查 是否领取SVIP礼包
function CheckSVIPGift(pActor)
    print("[Tip] ActivityType10028 CheckSVIPGift")

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10028 CheckSVIPGift not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10028 CheckSVIPGift not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10028 CheckSVIPGift not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10028 CheckSVIPGift [非本平台活动]")  
        return --非本平台活动
    end

    if not ActivityConfig.svipRewardId then
        print("[Tip] ActivityType10028 CheckSVIPGift not ActivityConfig.svipRewardId")
        return
    end

    local cdkdata = getActorCdkData(pActor)
    local userData = GetQiDianUserData(pActor)
    if cdkdata then
        -- 超级vip奖励
        if cdkdata.codeTypeTimes then
            if cdkdata.codeTypeTimes[ActivityConfig.svipRewardId] then
                userData.SVIPGiftFlag = 1
            else
                print("[Tip] ActivityType10028 CheckSVIPGift not dkdata.codeTypeTimes[ActivityConfig.svipRewardId]")
            end
        else
            print("[Tip] ActivityType10028 CheckSVIPGift not cdkdata.codeTypeTimes")
        end
    else
        print("[Tip] ActivityType10028 CheckSVIPGift not cdkdata")
    end

    userData.ReqMainGiftType = 0

    SendQiDianUserData(pActor)
end

-- 发送 手机绑定礼包
function SendBindPhoneGift(pActor)
    print("[Tip] ActivityType10028 SendBindPhoneGift")

    local userData = GetQiDianUserData(pActor)
    if 1 == userData.BindPhoneGiftFlag then
        print("[Tip] ActivityType10028 SendBindPhoneGift already get BindPhoneGift")
        return
    end
    
    if not ActivityConfig or not ActivityConfig.bindPhoneReward then
        print("[Tip] ActivityType10028 SendBindPhoneGift already get BindPhoneGift")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10028 SendBindPhoneGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.BindPhoneGiftFlag = 1

    CommonFunc.Awards.Give(pActor, ActivityConfig.bindPhoneReward, GameLog.Log_Activity10028)

    userData.ReqMainGiftType = 0

    SendQiDianUserData(pActor)

    Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)
end

-- QiDian 玩家登录
function OnReqQiDianLogin(pActor)
    print("[Tip] ActivityType10028 OnReqQiDianLogin")

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10028 OnReqQiDianLogin not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10028 OnReqQiDianLogin not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10028 OnReqQiDianLogin not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10028 OnReqQiDianLogin [非本平台活动]")  
        return --非本平台活动
    end

    -- 初始化玩家数据
    local userData = GetQiDianUserData(pActor)
    if nil == userData.ReqMainGiftType then
        userData.ReqMainGiftType = 0
    end
    if nil == userData.BindPhone then
        userData.BindPhone = 0
    end
    if nil == userData.SVIPGiftFlag then
        userData.SVIPGiftFlag = 0
    end
    if nil == userData.BindPhoneGiftFlag then
        userData.BindPhoneGiftFlag = 0
    end

    -- 请求 qidian平台 用户信息
    ReqQiDianUserInfo(pActor)
end

-- QiDian 玩家登录
function OnReqQiDianGift(pActor, packet)
    print("[Tip] ActivityType10028 OnReqQiDianGift")

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10028 OnReqQiDianGift not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10028 OnReqQiDianGift not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10028 OnReqQiDianGift not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10028 OnReqQiDianGift [非本平台活动]")  
        return --非本平台活动
    end

    local userData = GetQiDianUserData(pActor)
    userData.ReqGiftMainType = DataPack.readByte(packet)
    if not userData.ReqGiftMainType or userData.ReqGiftMainType < 1 or userData.ReqGiftMainType > 2 then
        print("[Tip] ActivityType10028 OnReqQiDianGift not userData.ReqGiftMainType or userData.ReqGiftMainType < 1 or userData.ReqGiftMainType > 2")
        return
    end

    if 1 == userData.ReqGiftMainType then     -- 获取SVIP礼包领取标志
        CheckSVIPGift(pActor)
    elseif 2 == userData.ReqGiftMainType then -- 获取手机绑定礼包
        SendBindPhoneGift(pActor)
    end
end


NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqQiDianLogin, OnReqQiDianLogin)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqQiDianGift,  OnReqQiDianGift)