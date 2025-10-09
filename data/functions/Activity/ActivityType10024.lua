module("ActivityType10024", package.seeall)


--[[
    个人数据：userData
    {
       LoginType = 0 or 1                      鲁大师 登录类型(1:游戏盒子登录)
       LastTime = 0                            鲁大师 上一次初始化的时间戳
       ReqMainGiftType = 0 ~ 4                 鲁大师 请求奖励类型((服务器使用 登录发送奖励数据)：0；
                                                                vip：1(一级子类型：1：称号奖励(二级子类型：奖励Id)；2：礼包奖励(二级子类型：奖励Id))；
                                                                会员：2(一级子类型：1：称号奖励(二级子类型：奖励Id)；2：礼包奖励(二级子类型：奖励Id)；3：每日奖励(二级子类型：奖励Id))；
                                                                手机礼包：3(一级子类型：1：手机绑定奖励(二级子类型：奖励Id)；2：防沉迷奖励(二级子类型：奖励Id))；
                                                                游戏盒子：4(一级子类型：1：下载奖励(二级子类型：奖励Id)；2：每日奖励(二级子类型：奖励Id)；3：等级奖励(二级子类型：奖励Id)))
       ReqSubGiftType = 1 ~ 2 or 1 ~ 3         鲁大师 请求奖励一级子类型
       ReqSubGiftType2 = 0 ~ 4                 鲁大师 请求奖励二级子类型(对应的奖励Id；0暂未使用)
       VipLevel = 0~9                          鲁大师 vip等级 0-9
       PlusLevel = 0，1-4                    鲁大师 超玩会等级 0，1-4
       BindPhone = 0 or 1                      鲁大师 绑定手机 0表示未绑定， 1表示绑定
       Fcm = 0 or 1                            鲁大师 防沉迷验证 0表示未通过防沉迷验证，1表示通过   
       SVIPGiftFlag = 0 or 1                   鲁大师 超级Vip 礼包领取标志
       DownLoadGameBoxGiftFlag = 0 or 1        鲁大师 游戏盒子下载 礼包领取标志
       BindPhoneGiftFlag = 0 or 1              鲁大师 手机绑定 礼包领取标志
       WeChatGiftFlag = 0 or 1                 鲁大师 微信 礼包领取标志
       FcmGiftFlag = 0 or 1                    鲁大师 防沉迷 礼包领取标志
       VipTitleFlag = 00000000 32位            鲁大师 Vip称号 礼包领取标志
       VipGiftFlag = 00000000 32位             鲁大师 Vip礼包 礼包领取标志
       MemberTitleFlag = 00000000 32位         鲁大师 会员称号 礼包领取标志
       MemberGiftFlag = 00000000 32位          鲁大师 会员礼包 礼包领取标志
       MemberDailyGiftFlag = 0 or 1            鲁大师 会员每日礼包 礼包领取标志
       GameBoxDailyGiftFlag = 0 or 1           鲁大师 游戏盒子每日礼包 礼包领取标志
       GameBoxLevelGiftFlag = 00000000 32位    鲁大师 游戏盒子等级礼包 礼包领取标志
    }
]]--


--活动类型
ActivityType = 10024
--对应的活动配置
ActivityConfig = PlatformludashiConfig
VipConfig= LudashivipConfig
MemberConfig = LudashimemberConfig

local PfId = System.getPfId()


local HttpStatus = {
    Success = "0",     -- 成功
    ArgError = "302",	 -- 参数错误
    SignError = "304", -- 签名错误
    LinkLost = "305",  -- 链接失效，超时
}

-- 服务接口
Host = ActivityConfig.host or "wan.ludashi.com"
Api = ActivityConfig.api or "/openApi/platformVipInfo"
Port = ActivityConfig.port or "80"


function GetMasterLuUserData(pActor)
    local var = Actor.getStaticVar(pActor)
    if nil == var.MasterLuUserData then
        var.MasterLuUserData = {}
    end
    return var.MasterLuUserData
end


--------------------------------------------------------------------
-- 请求平台玩家数据信息
--------------------------------------------------------------------


-- 请求 鲁大师用户信息
function ReqMasterLuUserInfo(pActor)
    print("[Tip] ActivityType10024 ReqMasterLuUserInfo")

    local nActorId = Actor.getActorId(pActor)

    local gid = "sbcq"
    local uid =  Actor.getAccount(pActor)
    local time = os.time()
    local token = "2cA4xA5BiwRPyZJEb#eJYmeS@NznzaH6"

    local sign = System.MD5(gid..uid..time..token)
    local req = Api..'?gid='..gid..'&uid='..uid..'&time='..time..'&sign='..sign

    -- print("[Tip] ActivityType10024 ReqMasterLuUserInfo [" .. Actor.getName(pActor) .. "] : ".. Host)
    -- print("[Tip] ActivityType10024 ReqMasterLuUserInfo [" .. Actor.getName(pActor) .. "] : ".. Port)
    -- print("[Tip] ActivityType10024 ReqMasterLuUserInfo [" .. Actor.getName(pActor) .. "] : ".. req)
    AsyncWorkDispatcher.Add(
        {'GetHttpContent',Host,Port,req},
        SetMasterLuUserData,
        {nActorId}
    )
end

-- 设置 鲁大师用户数据
function SetMasterLuUserData(paramPack,content,result)
    -- print("[Tip] ActivityType10024 SetMasterLuUserData content : "..content)
    -- print("[Tip] ActivityType10024 SetMasterLuUserData result : "..result)
    local nActorId = paramPack[1]
    local pActor = Actor.getActorById(nActorId)
    if not pActor then
        print("[Tip] ActivityType10024 SetMasterLuUserData [" .. nActorId .. "] 已离线")
        return
    end
    print("[Tip] ActivityType10024 SetMasterLuUserData [" .. Actor.getName(pActor) .. "] content:"..content)
    print("[Tip] ActivityType10024 SetMasterLuUserData result:"..result)

    if 0 == result then
        local status = string.match(content,"\"errno\":(%d+)")
        if (HttpStatus.Success == status) then
            local strVip = string.match(content,"\"vip\":(%d+)")
            local strPlus = string.match(content,"\"plus\":(%d+)")
            local strBindPhone = string.match(content,"\"bindPhone\":(%d+)")
            local strFcm = string.match(content,"\"fcm\":(%d+)")

            local nVip = 0
            local nPlus = 0
            local nBindPhone = 0
            local nFcm = 0

            if "null" ~= strVip then
                nVip = tonumber(strVip)
            end
            if "null" ~= strPlus then
                nPlus = tonumber(strPlus)
            end
            if "null" ~= strBindPhone then
                nBindPhone = tonumber(strBindPhone)
            end
            if "null" ~= strFcm then
                nFcm = tonumber(strFcm)
            end

            local userData = GetMasterLuUserData(pActor)
            userData.VipLevel = nVip
            userData.PlusLevel = nPlus
            userData.BindPhone = nBindPhone
            userData.Fcm = nFcm

            if 0 == userData.ReqMainGiftType then
                SendMasterLuUserData(pActor)
            elseif 1 == userData.ReqMainGiftType then -- vip：1(一级子类型：1：称号奖励；2：礼包奖励)
                SendVipAwards(pActor)
            elseif 2 == userData.ReqMainGiftType then -- 会员：2(一级子类型：1：称号奖励；2：礼包奖励；3：每日奖励)
                if 1 == userData.ReqSubGiftType or 2 == userData.ReqSubGiftType then
                    SendMemberAwards(pActor)
                elseif 3 == userData.ReqSubGiftType then
                    SendMemberDailyGift(pActor)
                end
            elseif 3 == userData.ReqMainGiftType then -- 手机礼包：3(一级子类型：1：手机绑定奖励；2：防沉迷奖励)；
                if 1 == userData.ReqSubGiftType then
                    SendBindPhoneGift(pActor)
                elseif 2 == userData.ReqSubGiftType then
                    SendFcmGift(pActor)
                end
            end
        end
    end
end

-- 发送 鲁大师玩家数据
function SendMasterLuUserData(pActor)
    print("[Tip] ActivityType10024 SendMasterLuUserData")

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10024 SendMasterLuUserData not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10024 SendMasterLuUserData not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10024 SendMasterLuUserData not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10024 SendMasterLuUserData [非本平台活动]")  
        return --非本平台活动
    end

    local userData = GetMasterLuUserData(pActor)
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSendMasterLuGitfData)
    if npack then
        local cdkdata = getActorCdkData(pActor)
        if cdkdata then
            -- 超级vip奖励
            if cdkdata.codeTypeTimes and PlatformConfig.type then
                if cdkdata.codeTypeTimes[PlatformConfig.type] then
                    userData.SVIPGiftFlag = 1
                end
            end

            -- 微信奖励
            if cdkdata.codeTypeTimes and PlatformConfig.type2 then
                if cdkdata.codeTypeTimes[PlatformConfig.type2] then
                    userData.WeChatGiftFlag = 1
                end
            end
        end

        DataPack.writeByte(npack, (userData.VipLevel or 0))
        DataPack.writeByte(npack, (userData.PlusLevel or 0))
        DataPack.writeByte(npack, (userData.BindPhone or 0))
        DataPack.writeByte(npack, (userData.Fcm or 0))
        DataPack.writeByte(npack, (userData.SVIPGiftFlag or 0))
        DataPack.writeByte(npack, (userData.DownLoadGameBoxGiftFlag or 0))
        DataPack.writeByte(npack, (userData.BindPhoneGiftFlag or 0))
        DataPack.writeByte(npack, (userData.WeChatGiftFlag or 0))
        DataPack.writeByte(npack, (userData.FcmGiftFlag or 0))
        DataPack.writeUInt(npack, (userData.VipTitleFlag or 0))
        DataPack.writeUInt(npack, (userData.VipGiftFlag or 0))
        DataPack.writeUInt(npack, (userData.MemberTitleFlag or 0))
        DataPack.writeUInt(npack, (userData.MemberGiftFlag or 0))
        DataPack.writeByte(npack, (userData.MemberDailyGiftFlag or 0))
        DataPack.writeByte(npack, (userData.GameBoxDailyGiftFlag or 0))
        DataPack.writeUInt(npack, (userData.GameBoxLevelGiftFlag or 0))
        DataPack.flush(npack)
    end
end


--------------------------------------------------------------------
-- 客户端请求协议回调
--------------------------------------------------------------------


-- 鲁大师玩家登录
function OnReqMasterLuLogin(pActor, packet)
    print("[Tip] ActivityType10024 OnReqMasterLuLogin")

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10024 OnReqMasterLuLogin not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10024 OnReqMasterLuLogin not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10024 OnReqMasterLuLogin not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10024 OnReqMasterLuLogin [非本平台活动]")  
        return --非本平台活动
    end

    local nLoginType = DataPack.readByte(packet) -- 1：游戏盒子登录

    local userData = GetMasterLuUserData(pActor)

    -- 初始化 登录类型
    userData.LoginType = nLoginType

    -- 初始化 每天奖励数据
    local currMiniTime = System.getCurrMiniTime()
    if nil == userData.LastTime then
        userData.LastTime = currMiniTime
        userData.MemberDailyGiftFlag = 0
        userData.GameBoxDailyGiftFlag = 0
    else
        if not System.isSameDay(userData.LastTime, currMiniTime) then
            userData.LastTime = currMiniTime
            userData.MemberDailyGiftFlag = 0
            userData.GameBoxDailyGiftFlag = 0
        end
    end
    
    -- 初始化 奖励 相关数据
    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType = 0
    userData.ReqSubGiftType2 = 0    

    -- 请求 鲁大师平台 用户信息
    ReqMasterLuUserInfo(pActor)
end

-- 请求 鲁大师奖励
function OnReqMasterLuGift(pActor, packet)
    print("[Tip] ActivityType10024 OnReqMasterLuGift")

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10024 OnReqMasterLuGift not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10024 OnReqMasterLuGift not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10024 OnReqMasterLuGift not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10024 OnReqMasterLuGift [非本平台活动]")  
        return --非本平台活动
    end

    local nMainGiftType = DataPack.readByte(packet)
    local nSubGiftType = DataPack.readByte(packet)
    local nSubGiftType2 = DataPack.readByte(packet)

    if nMainGiftType < 1 or nMainGiftType > 4 then
        print("[Tip] ActivityType10024 OnReqMasterLuGift nMainGiftType < 1 or nMainGiftType > 4")
        return
    end

    if 1 == nMainGiftType or 3 == nMainGiftType then
        if nSubGiftType < 1 or nSubGiftType > 2 then
            print("[Tip] ActivityType10024 OnReqMasterLuGift nSubGiftType < 1 or nSubGiftType > 2 : "..nMainGiftType)
            return 
        end
    elseif 2 == nMainGiftType or 4 == nMainGiftType then
        if nSubGiftType < 1 or nSubGiftType > 3 then
            print("[Tip] ActivityType10024 OnReqMasterLuGift nSubGiftType < 1 or nSubGiftType > 3 : "..nMainGiftType)
            return 
        end
    end

    local userData = GetMasterLuUserData(pActor)
    userData.ReqMainGiftType = nMainGiftType
    userData.ReqSubGiftType = nSubGiftType
    userData.ReqSubGiftType2 = nSubGiftType2

    if 4 ~= nMainGiftType then  -- 请求 鲁大师平台 用户信息
        ReqMasterLuUserInfo(pActor)
    else --游戏盒子：4(一级子类型：1：下载奖励(二级子类型：奖励Id)；2：每日奖励(二级子类型：奖励Id)；3：等级奖励(二级子类型：奖励Id)))
        if 1 == userData.ReqSubGiftType then
            SendDownLoadGameBoxGift(pActor)
        elseif 2 == userData.ReqSubGiftType then
            SendGameBoxDailyGift(pActor)
        elseif 3 == userData.ReqSubGiftType then
            SendGameBoxLevelGift(pActor)
        end 
    end
end

-- 发送 游戏盒子下载奖励
function SendDownLoadGameBoxGift(pActor)
    print("[Tip] ActivityType10024 SendDownLoadGameBoxGift ")

    local userData = GetMasterLuUserData(pActor)
    
    if not userData.LoginType then
        print("[Tip] ActivityType10024 SendDownLoadGameBoxGift not userData.LoginType")
        return
    end

    if 1 == userData.DownLoadGameBoxGiftFlag then
        print("[Tip] ActivityType10024 SendDownLoadGameBoxGift already get award")
        return
    end

    if not ActivityConfig.downloadBoxReward then
        print("[Tip] ActivityType10024 SendDownLoadGameBoxGift not ActivityConfig.downloadBoxReward")
        return
    end
        
    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10024 SendDownLoadGameBoxGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.DownLoadGameBoxGiftFlag = 1
    
    CommonFunc.Awards.Give(pActor, ActivityConfig.downloadBoxReward, GameLog.Log_Activity10024)

    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType = 0
    userData.ReqSubGiftType2 = 0

    SendMasterLuUserData(pActor)
end

-- 发送 绑定手机奖励
function SendBindPhoneGift(pActor)
    print("[Tip] ActivityType10024 SendBindPhoneGift")

    local userData = GetMasterLuUserData(pActor)

    if not userData.BindPhone or 1 ~= userData.BindPhone then
        print("[Tip] ActivityType10024 SendBindPhoneGift not userData.BindPhone or 1 ~= userData.BindPhone")
        return 
    end
    
    if 1 == userData.BindPhoneGiftFlag then
        print("[Tip] ActivityType10024 SendBindPhoneGift already get BindPhoneGift")
        return
    end

    if not ActivityConfig.bindPhoneReward then
        print("[Tip] ActivityType10024 SendBindPhoneGift not ActivityConfig.bindPhoneReward")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10022 SendBindPhoneGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.BindPhoneGiftFlag = 1

    CommonFunc.Awards.Give(pActor, ActivityConfig.bindPhoneReward, GameLog.Log_Activity10024)

    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType = 0
    userData.ReqSubGiftType2 = 0

    SendMasterLuUserData(pActor)
end

-- 发送 防沉迷奖励
function SendFcmGift(pActor)
    print("[Tip] ActivityType10024 SendFcmGift")

    local userData = GetMasterLuUserData(pActor)
    
    if not userData.Fcm or 1 ~= userData.Fcm then
        print("[Tip] ActivityType10024 SendBindPhoneGift not userData.Fcm or 1 ~= userData.Fcm")
        return 
    end

    if 1 == userData.FcmGiftFlag then
        print("[Tip] ActivityType10024 SendFcmGift already get FcmGift")
        return
    end

    if not ActivityConfig.FcmReward then
        print("[Tip] ActivityType10024 SendFcmGift not ActivityConfig.FcmReward")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10022 SendFcmGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.FcmGiftFlag = 1

    CommonFunc.Awards.Give(pActor, ActivityConfig.FcmReward, GameLog.Log_Activity10024)

    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType = 0
    userData.ReqSubGiftType2 = 0

    SendMasterLuUserData(pActor)
end

-- 发送 Vip奖励
function SendVipAwards(pActor)
    print("[Tip] ActivityType10024 SendVipAwards")

    local userData = GetMasterLuUserData(pActor)

    
    if not userData.VipLevel or userData.VipLevel < 0 or userData.VipLevel > 9 then
        print("[Tip] ActivityType10024 SendVipAwards not userData.VipLevel or userData.VipLevel < 0 or userData.VipLevel > 9")
        return
    end

    if userData.ReqSubGiftType < 1 or userData.ReqSubGiftType > 2 then
        print("[Tip] ActivityType10024 SendVipAwards userData.ReqSubGiftType < 1 or userData.ReqSubGiftType > 2")
        return
    end

    if not VipConfig then
        print("[Tip] ActivityType10024 SendVipAwards not VipConfig")
        return
    end

    if userData.ReqSubGiftType2 > #VipConfig then
        print("[Tip] ActivityType10024 SendVipAwards ReqSubGiftType2 > #VipConfig ReqSubGiftType : "..userData.ReqSubGiftType.."ReqSubGiftType2 : "..userData.ReqSubGiftType2)
        return
    end

    if not VipConfig[userData.ReqSubGiftType2].vipLevel then
        print("[Tip] ActivityType10024 SendVipAwards not VipConfig[userData.ReqSubGiftType2].vipLevel")
        return
    end

    if 1 == userData.ReqSubGiftType then
        if not VipConfig[userData.ReqSubGiftType2].titleReward then
            print("[Tip] ActivityType10024 SendVipAwards not VipConfig[userData.ReqSubGiftType2].titleReward")
            return
        end

        if userData.VipLevel >= VipConfig[userData.ReqSubGiftType2].vipLevel then
           if 0 == System.getIntBit(userData.VipTitleFlag, userData.ReqSubGiftType2 - 1) then
                --检测格子 16 : 活动通用
                if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
                    print("[Tip] ActivityType10024 SendVipAwards not CheckBagIsEnough")
                    return
                end

                -- 设置标志
                userData.VipTitleFlag = System.setIntBit(userData.VipTitleFlag, userData.ReqSubGiftType2 - 1, true)
                CommonFunc.Awards.Give(pActor, VipConfig[userData.ReqSubGiftType2].titleReward, GameLog.Log_Activity10024)
            else
                print("[Tip] ActivityType10024 SendVipAwards already get titleReward Id : "..userData.ReqSubGiftType2)
                return
            end
        else
            print("[Tip] ActivityType10024 SendVipAwards titleReward userData.VipLevel < VipConfig[userData.ReqSubGiftType2].vipLevel")
            return
        end
    elseif 2 == userData.ReqSubGiftType then
        if not VipConfig[userData.ReqSubGiftType2].giftReward then
            print("[Tip] ActivityType10024 SendVipAwards not VipConfig[userData.ReqSubGiftType2].giftReward")
            return
        end

        if userData.VipLevel >= VipConfig[userData.ReqSubGiftType2].vipLevel then
            if 0 == System.getIntBit(userData.VipGiftFlag, userData.ReqSubGiftType2 - 1) then
                --检测格子 16 : 活动通用
                if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
                    print("[Tip] ActivityType10024 SendVipAwards not CheckBagIsEnough")
                    return
                end

                -- 设置标志
                userData.VipGiftFlag = System.setIntBit(userData.VipGiftFlag, userData.ReqSubGiftType2 - 1, true)
                CommonFunc.Awards.Give(pActor, VipConfig[userData.ReqSubGiftType2].giftReward, GameLog.Log_Activity10024)
            else
                print("[Tip] ActivityType10024 SendVipAwards already get giftReward Id : "..userData.ReqSubGiftType2)
                return
            end
        else
            print("[Tip] ActivityType10024 SendVipAwards giftReward userData.VipLevel < VipConfig[userData.ReqSubGiftType2].vipLevel")
            return
        end
    end

    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType = 0
    userData.ReqSubGiftType2 = 0

    SendMasterLuUserData(pActor)
end

-- 发送 会员奖励
function SendMemberAwards(pActor)
    print("[Tip] ActivityType10024 SendMemberAwards")

    local userData = GetMasterLuUserData(pActor)
    
    if not userData.PlusLevel or userData.PlusLevel < 1 or userData.PlusLevel > 4 then
        print("[Tip] ActivityType10024 SendMemberAwards not userData.PlusLevel or userData.PlusLevel < 1 or userData.PlusLevel > 4")
        return
    end

    if userData.ReqSubGiftType < 1 or userData.ReqSubGiftType > 2 then
        print("[Tip] ActivityType10024 SendMemberAwards userData.ReqSubGiftType < 1 or userData.ReqSubGiftType > 2")
        return
    end

    if not MemberConfig then
        print("[Tip] ActivityType10024 SendMemberAwards not MemberConfig")
        return
    end

    if userData.ReqSubGiftType2 > #MemberConfig then
        print("[Tip] ActivityType10024 SendMemberAwards ReqSubGiftType2 > #MemberConfig ReqSubGiftType : "..userData.ReqSubGiftType.."ReqSubGiftType2 : "..userData.ReqSubGiftType2)
        return
    end

    if not MemberConfig[userData.ReqSubGiftType2].memberLevel then
        print("[Tip] ActivityType10024 SendMemberAwards not MemberConfig[userData.ReqSubGiftType2].memberLevel")
        return
    end


    if 1 == userData.ReqSubGiftType then
        if not MemberConfig[userData.ReqSubGiftType2].titleReward then
            print("[Tip] ActivityType10024 SendMemberAwards not MemberConfig[userData.ReqSubGiftType2].titleReward")
            return
        end

        if userData.PlusLevel >= MemberConfig[userData.ReqSubGiftType2].memberLevel then
            if 0 == System.getIntBit(userData.MemberTitleFlag, userData.ReqSubGiftType2 - 1) then
                --检测格子 16 : 活动通用
                if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
                    print("[Tip] ActivityType10024 SendMemberAwards not CheckBagIsEnough")
                    return
                end

                -- 设置标志
                userData.MemberTitleFlag = System.setIntBit(userData.MemberTitleFlag, userData.ReqSubGiftType2 - 1, true)
                CommonFunc.Awards.Give(pActor, MemberConfig[userData.ReqSubGiftType2].titleReward, GameLog.Log_Activity10024)
            else
                print("[Tip] ActivityType10024 SendMemberAwards already get titleReward Id : "..userData.ReqSubGiftType2)
                return
            end
        else
            print("[Tip] ActivityType10024 SendMemberAwards titleReward userData.PlusLevel < MemberConfig[userData.ReqSubGiftType2].memberLevel")
            return
        end
    elseif 2 == userData.ReqSubGiftType then
        if not MemberConfig[userData.ReqSubGiftType2].giftReward then
            print("[Tip] ActivityType10024 SendMemberAwards not MemberConfig[userData.ReqSubGiftType2].giftReward")
            return
        end

        if userData.PlusLevel >= MemberConfig[userData.ReqSubGiftType2].memberLevel then
            if 0 == System.getIntBit(userData.MemberGiftFlag, userData.ReqSubGiftType2 - 1) then
                --检测格子 16 : 活动通用
                if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
                    print("[Tip] ActivityType10024 SendMemberAwards not CheckBagIsEnough")
                    return
                end

                -- 设置标志
                userData.MemberGiftFlag = System.setIntBit(userData.MemberGiftFlag, userData.ReqSubGiftType2 - 1, true)
                CommonFunc.Awards.Give(pActor, MemberConfig[userData.ReqSubGiftType2].giftReward, GameLog.Log_Activity10024)
            else
                print("[Tip] ActivityType10024 SendMemberAwards already get giftReward Id : "..userData.ReqSubGiftType2)
                return
            end
        else
            print("[Tip] ActivityType10024 SendMemberAwards giftReward userData.PlusLevel < MemberConfig[userData.ReqSubGiftType2].memberLevel")
            return
        end
    end

    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType = 0
    userData.ReqSubGiftType2 = 0

    SendMasterLuUserData(pActor)
end

-- 发送 会员每日礼包
function SendMemberDailyGift(pActor)
    print("[Tip] ActivityType10024 SendMemberDailyGift")

    local userData = GetMasterLuUserData(pActor)

    if userData.PlusLevel < 1 or userData.PlusLevel > 4 then
        print("[Tip] ActivityType10024 SendMemberDailyGift userData.PlusLevel < 1 or userData.PlusLevel > 4")
        return
    end

    if 3 ~= userData.ReqSubGiftType  then
        print("[Tip] ActivityType10024 SendMemberDailyGift 3 ~= userData.ReqSubGiftType")
        return
    end

    if 1 == userData.MemberDailyGiftFlag then
        print("[Tip] ActivityType10024 SendMemberDailyGift already get MemberDailyGift")
        return
    end

    if not MemberConfig then
        print("[Tip] ActivityType10024 SendMemberDailyGift not MemberConfig")
        return
    end

    if not MemberConfig[userData.ReqSubGiftType] or not MemberConfig[userData.ReqSubGiftType].giftReward then
        print("[Tip] ActivityType10024 SendMemberDailyGift not MemberConfig[userData.ReqSubGiftType].giftReward")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10022 SendMemberDailyGift CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.MemberDailyGiftFlag = 1

    CommonFunc.Awards.Give(pActor, MemberConfig[userData.ReqSubGiftType].giftReward, GameLog.Log_Activity10024)

    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType = 0
    userData.ReqSubGiftType2 = 0

    SendMasterLuUserData(pActor)
end

-- 发送 游戏盒子每日礼包 
function SendGameBoxDailyGift(pActor)
    print("[Tip] ActivityType10024 SendGameBoxDailyGift")

    local userData = GetMasterLuUserData(pActor)
    if not userData.LoginType then
        print("[Tip] ActivityType10024 SendGameBoxDailyGift not userData.LoginType")
        return
    end

    if 1 == userData.GameBoxDailyGiftFlag then
        print("[Tip] ActivityType10024 SendGameBoxDailyGift already get GameBoxDailyGift")
        return
    end

    if not ActivityConfig or not ActivityConfig.boxdailyGift then
        print("[Tip] ActivityType10024 SendGameBoxDailyGift not ActivityConfig or not ActivityConfig.dailyGift")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10022 SendGameBoxDailyGift CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.GameBoxDailyGiftFlag = 1

    CommonFunc.Awards.Give(pActor, ActivityConfig.boxdailyGift, GameLog.Log_Activity10024)

    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType = 0
    userData.ReqSubGiftType2 = 0

    SendMasterLuUserData(pActor)
end
 
-- 发送 游戏盒子等级礼包 
function SendGameBoxLevelGift(pActor)
    print("[Tip] ActivityType10024 SendGameBoxLevelGift")

    local userData = GetMasterLuUserData(pActor)
    if not userData.LoginType then
        print("[Tip] ActivityType10024 SendGameBoxLevelGift not userData.LoginType")
        return
    end

    if userData.ReqSubGiftType2 < 1 or userData.ReqSubGiftType2 > #ActivityConfig.levelGift or not ActivityConfig.levelGift[userData.ReqSubGiftType2] then
        print("[Tip] ActivityType10024 SendGameBoxLevelGift userData.ReqSubGiftType2 < 1 or userData.ReqSubGiftType2 > #ActivityConfig.levelGift or not ActivityConfig.levelGift[userData.ReqSubGiftType2]")
        return
    end

    local nActorLevel = Actor.getIntProperty(pActor,PROP_CREATURE_LEVEL)
    if not ActivityConfig.levelGift[userData.ReqSubGiftType2].lvl or ActivityConfig.levelGift[userData.ReqSubGiftType2].lvl > nActorLevel then
        print("[Tip] ActivityType10024 SendGameBoxLevelGift not ActivityConfig.levelGift[userData.ReqSubGiftType2].lvl and ActivityConfig.levelGift[userData.ReqSubGiftType2].lvl > nActorLevel")
        return
    end

    if not ActivityConfig.levelGift[userData.ReqSubGiftType2].awards then
        print("[Tip] ActivityType10024 SendGameBoxLevelGift not ActivityConfig.levelGift[userData.ReqSubGiftType2].awards")
        return
    end

    if 1 == System.getIntBit(userData.GameBoxLevelGiftFlag, userData.ReqSubGiftType2 - 1) then
        print("[Tip] ActivityType10024 SendGameBoxLevelGift already get levelGift Id: "..userData.ReqSubGiftType2)
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10024 SendGameBoxLevelGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.GameBoxLevelGiftFlag = System.setIntBit(userData.GameBoxLevelGiftFlag, userData.ReqSubGiftType2 - 1, true)
    CommonFunc.Awards.Give(pActor, ActivityConfig.levelGift[userData.ReqSubGiftType2].awards, GameLog.Log_Activity10024)

    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType = 0
    userData.ReqSubGiftType2 = 0

    SendMasterLuUserData(pActor)
end


NetmsgDispatcher.Reg(enPlatforMwelfareID, cMasterLuLogin, OnReqMasterLuLogin)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqMasterLuAward, OnReqMasterLuGift)


-- 跨天
function OnNewDayArrive(pActor,ndiffday)
    print("[Tip] ActivityType10024 OnNewDayArrive")

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10024 OnNewDayArrive not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10024 OnNewDayArrive not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10024 OnNewDayArrive not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10024 OnNewDayArrive [非本平台活动]")  
        return --非本平台活动
    end

    local currMiniTime = System.getCurrMiniTime()
    local data = GetMasterLuUserData(pActor)
    if data.LastTime then
        if not System.isSameDay(data.LastTime, currMiniTime) then
            --print("跨一天")
            data.LastTime = currMiniTime
            data.MemberDailyGiftFlag = 0
            data.GameBoxDailyGiftFlag = 0
            SendMasterLuUserData(pActor)
        end
        -- SendData(pActor)
    end
end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10024.lua")