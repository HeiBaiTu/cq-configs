module("Platform37Gift", package.seeall)

local CODE_CHECK_NULL = 0	   
local CODE_CHECK_DOWNLOADBOX = 1    -- 盒子下载领取
local CODE_CHECK_PHONEGIFT = 2      -- 手机绑定 
local CODE_CHECK_FCM = 3            -- 防沉迷 

local CODE_SUCCESS = 0	    -- 成功
local CODE_INVALID = 4      -- 已被使用

--对应的活动配置
ActivityConfig = Platform37Config
local PfId = System.getPfId() 
local SrvId = System.getServerId()
 
local bagLimit = 16 --需要的格子数量

local ServiceConfCKD = CdkeyServiceConf[PfId] 
--BindPhoneHost = ServiceConfCKD.host                                                                 --"fgtest.bigrnet.com"
--BindPhonePort = ServiceConf.port                                                                    --"80"
--BindPhoneApi = "/Service/CheckBindPhoneCode.php"                                                     --"/H5CQ/develop/Service/CheckBindPhoneCode.php"
  
--http://gameapi.37.com/?a=get_user_info
-- 服务接口
Host = ActivityConfig.host or "gameapi.37.com"
Port = ActivityConfig.port or "80"
Api = ActivityConfig.api or "/"
PfKey = "VgvCLoGkwMdLsUPFnvAVr8QGvXBKLxRr"

function OnCheck37Platform() 
    -- 平台验证
    if not PfId then
        print("[Tip] [Platform37] OnCheck37Platform not PfId")
        return false
    end
    if not ActivityConfig then
        print("[Tip] [Platform37] OnCheck37Platform not ActivityConfig")
        return false
    end
    if not ActivityConfig.SPID then
        print("[Tip] [Platform37] OnCheck37Platform not ActivityConfig.SPID")
        return false
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] [非本平台活动]")  
        return false--非本平台活动
    end
    return true
end

--对应的活动配置
function get37PlatformData(pActor)
    local var = Actor.getStaticVar(pActor)
    if var.Platform37Data == nil then
        var.Platform37Data = {} 
        var.Platform37Data.DataLevelGift = 0 
        var.Platform37Data.DataDailyGift = 0 
        
        var.Platform37Data.phoneGift = 0 

        var.Platform37Data.downloadBox = 0  

        var.Platform37Data.FcmGift = 0

        var.Platform37Data.Vip = 0
        var.Platform37Data.hezi = 0
        var.Platform37Data.phone = 0
        var.Platform37Data.fcm = 0
        
        print("[Tip] [Platform37]init data")
    end
    return var.Platform37Data
end


function Send37PlatformData(pActor) 
    -- 平台验证
    if not OnCheck37Platform() then 
        return 
    end
    
    local data = get37PlatformData(pActor)
         
    if data.Vip == nil then
        data.Vip = 0
    end 
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSend37GameGitfData)
    if npack then
        -- print("1111")
        --local cdkFlag = 0;
        --local cdkdata = getActorCdkData(pActor)
        --if cdkdata then
        --    if cdkdata.codeTypeTimes then
        --        if cdkdata.codeTypeTimes[ActivityConfig.type] then
        --            cdkFlag = 1;
        --        end
        --    end
        --end
        -- dailyGift
        DataPack.writeByte(npack, (data.downloadBox or 0)) 
        DataPack.writeByte(npack, (data.phoneGift or 0))   
        DataPack.writeByte(npack, (data.FcmGift or 0))    
 
        DataPack.writeUInt(npack, (data.DataLevelGift or 0)) 
        DataPack.writeUInt(npack, (data.DataDailyGift or 0))  

        print("[Tip] [Platform37] ------DataPack.LevelGift=:".. tostring(data.DataLevelGift))
        print("[Tip] [Platform37] ------DataPack.DailyGift=:".. tostring(data.DataDailyGift))
        --DataPack.writeByte(npack, (data.idCardGift or 0)) --是否领取认证礼包（0否，1是）
        --DataPack.writeShort(npack, (data.loginDay or 1))--登录的天数
        --DataPack.writeUInt(npack, (data.loginGift or 0))--礼包的领取标记 32 位
        --DataPack.writeByte(npack, (data.loginTypeGift or 0)) --
        DataPack.flush(npack)
    end
end
  
local function AfterCheckBindPhoneLogon(paramPack, content, result) 
    print("[Tip] [Platform37] 登陆AfterCheckBindPhoneLogon -------------------------content:"..tostring(content).."result:"..tostring(result))  
    
    local aid = paramPack[1]
    local pActor = Actor.getActorById(aid)
    if not pActor  then 
        print("[Tip] [Platform37]error--玩家不在线- AfterCheckBindPhoneLogon"..tostring(aid))
        return 
    end

    local data = get37PlatformData(pActor)
    if data == nil then
        return
    end

    local data = get37PlatformData(pActor) 
      
    local res = CODE_SUCCESS
    local actid = 0
    if (result == 0) then --有反馈  
        local resPattern = "^(.*)(return_code%s*:%s)([^,]*)(.*)$"
        strCapture1, strCapture2, res, strCapture3, strCapture4 = string.match(content, resPattern)
        print("[Tip] [Platform37]   -------------------------param1:"..tostring(strCapture1).."|param2:"..tostring(strCapture2).."|param3:"..tostring(res).."|param4:"..tostring(strCapture3).."|param5:"..tostring(strCapture4)) 
 
        if (res == "0") then --可以领 
            data.phone = 0 --默认手机绑定，后面再查询
        else 
            print("[Tip] [Platform37] AfterCheckBindPhoneLogon : 已经领了, content: "..content)
            data.phone = 1 --默认手机绑定，后面再查询
        end 
    else
        res = CODE_HTTP
        print("[ERR] [Platform37]1  AfterCheckBindPhoneLogon : result("..result.."), content: "..content)
        data.phone = 0 --默认手机绑定，后面再查询
    end  
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sUse37GiftPhone)
    if npack then
        if data.phone == 0 then
            DataPack.writeByte(npack, 0)  
        else 
            DataPack.writeByte(npack, 1)  
        end
        DataPack.flush(npack)
    end
end
 
--------------------------------------------------------------------
-- CPP回调
--------------------------------------------------------------------

-- 7游戏玩家登录
function On37GameLogin(pActor, packet)   
   
    local name = Actor.getName(pActor)

    local nIndex1 = DataPack.readInt(packet)
    local nIndex2 = DataPack.readInt(packet)
    local nIndex3 = DataPack.readInt(packet)
    local nIndex4 = DataPack.readInt(packet)
    print("[Tip] [Platform37] On7GameLogin:".. nIndex1.. ":"..nIndex2.. ":"..nIndex3..":"..nIndex4.. ":name".. name)

    
    -- 平台验证
    if not OnCheck37Platform() then 
        return 
    end
    -- 当天初始化
    local data = get37PlatformData(pActor) 
     
    if nIndex1 > 0 then
        data.Vip = nIndex1 
    else 
        data.Vip = 0 
    end
    if nIndex2 == 1 then
        data.hezi = 1
    else 
        data.hezi = 0 
    end 
    
    data.phone = 0 --默认手机绑定，后面再查询

    if nIndex4 == 1 then
        data.fcm = 1
    else 
        data.fcm = 0 
    end
    
    if data.lastLoginTime == nil then
        data.lastLoginTime = System.getCurrMiniTime()  
    end

    Send37PlatformData(pActor)
        
    BindPhoneHost = ServiceConfCKD.host                                                                 --"fgtest.bigrnet.com"
    BindPhonePort = ServiceConfCKD.port                                                                    --"80"
    BindPhoneApi = "/Service/CheckBindPhoneCode.php"                                                     --"/H5CQ/develop/Service/CheckBindPhoneCode.php"
    
    local sActorId = Actor.getActorId(pActor)
    local req = BindPhoneApi..'?pfid='..PfId..'&aid='..sActorId..'&sid='..SrvId..'&check='..1
    print("[Platform37] GetHttpContent -------------------------ServiceHost:"..tostring(BindPhoneHost))
    print("[Platform37] GetHttpContent -------------------------ServicePort:"..tostring(BindPhonePort))
    print("[Platform37]  GetHttpContent -------------------------req:"..tostring(req))

    --加入异步工作 
    AsyncWorkDispatcher.Add(
        {'GetHttpContent', BindPhoneHost, BindPhonePort, req},
            AfterCheckBindPhoneLogon,
        {sActorId, 0}
    )
end
 
-- 跨天
function OnNewDayArrive(pActor,ndiffday)
    print("[Tip] [Platform37] OnNewDayArrive")

    -- 平台验证
    if not OnCheck37Platform() then 
        return 
    end 
   
    local currMiniTime = System.getCurrMiniTime()
    --local data = get4366Data(pActor)
    local data = get37PlatformData(pActor)--37平台数据
     
    if data.lastLoginTime then 
        if not System.isSameDay(data.lastLoginTime, System.getCurrMiniTime()) then
            data.lastLoginTime = System.getCurrMiniTime()
            --data.loginDay = data.loginDay + 1
            
            print("[Tip] [Platform37] -----------------------------------4newday!") 
            print("[Tip] [Platform37] OnNewDayArrive set newday!") 
            data.DataDailyGift = 0         

        end

        Send37PlatformData(pActor)
    end
end
--ctorEventDispatcher.Reg(aeUserLogout, OnUserLogout, "Activity37Gift.lua")

--领取下载盒子奖励
function OnClickDownloadBox(pActor, packet) 
    print("[Tip] [Platform37] OnClickDownloadBox")

    -- 平台验证
    if not OnCheck37Platform() then 
        return 
    end
    local data = get37PlatformData(pActor)
    if data == nil then
        return
    end  
    if data.downloadBox == nil then
        return
    end 
    if data.hezi == 0 then
        return
    end 

    local name = Actor.getName(pActor)

    if  ActivityConfig.downloadBoxReward == nil then
        print("[Tip] [Platform37]没有此配置 DownloadBox Name = "..name)
        return
    end
    if data.downloadBox > 0 then
        print("[Tip] [Platform37]DownloadBox 重复领取！Name = "..name)
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:奖励已领取|", tstUI)
        return
    end 
    if CommonFunc.Awards.CheckBagIsEnough(pActor, bagLimit, tmLeftBagNumNotEnough, tstUI) ~= true then
        return
    end
    
    local AwardCfg = ActivityConfig.downloadBoxReward 
    if AwardCfg then
        --系统广播
        --if AwardCfg.tips then
        --    local name = Actor.getName(pActor);
            -- 提示需要配置
            -- System.broadTipmsgWithParams(AwardCfg.tips ,tstKillDrop, name)
            -- System.broadTipmsgWithParams(AwardCfg.tips ,tstChatSystem, name)
        --end
        
        --Actor.SendActivityLog(pActor, ActivityType,ActivityType,1) 
        CommonFunc.Awards.Give(pActor, AwardCfg, GameLog.Log_Platform37) 
        --Actor.SendActivityLog(pActor, ActivityType, ActivityType, 2)
        --提示 要配
        if AwardCfg.downloadBoxUitips then
            Actor.sendTipmsg(pActor, AwardCfg.downloadBoxUitips, tstUI)
        end
        data.downloadBox = data.downloadBox + 1
        print("[Tip]  [Platform37]  DownloadBox Gift Success "..name)
    end

    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sUse37DownloadBox)
    if npack then
               
        DataPack.writeByte(npack, 1)  --领取成功
        DataPack.flush(npack)

    end 
end

--37手机绑定
function OnClickGiftPhone(pActor, packet) 
    if 1 then 
        return 
    end 
    -- 平台验证
    if not OnCheck37Platform() then 
        return 
    end
    local data = get37PlatformData(pActor)
    if data == nil then
        return
    end  
    if data.phoneGift == nil then
        data.phoneGift = 0
    end 
       
    if data.phone == 0 then
        return
    end 

    local name = Actor.getName(pActor)

    if  ActivityConfig.bindPhoneReward == nil then
        print("[Tip] [Platform37]没有此配置 GiftPhone Name = "..name)
        return
    end
    if data.phoneGift > 0 then
        print("[Tip] [Platform37]GiftFCM 重复领取！Name = "..name)
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:奖励已领取|", tstUI)
        return
    end 
     
    if CommonFunc.Awards.CheckBagIsEnough(pActor, bagLimit, tmLeftBagNumNotEnough, tstUI) ~= true then
        return
    end
    local AwardCfg = ActivityConfig.bindPhoneReward 
    if AwardCfg then  
        --Actor.SendActivityLog(pActor, ActivityType,ActivityType,1) 
        CommonFunc.Awards.Give(pActor, AwardCfg, GameLog.Log_Platform37) 
        --Actor.SendActivityLog(pActor, ActivityType, ActivityType, 2)
        --提示 要配
        if AwardCfg.bindPhoneUitips then
            Actor.sendTipmsg(pActor, AwardCfg.bindPhoneUitips, tstUI)
        end
        
        data.phoneGift = data.phoneGift + 1
        print("[Tip]  [Platform37]  GiftPhone Success "..name)
    end
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sUse37GiftPhone)
    if npack then
                   
        DataPack.writeByte(npack, 1)  --领取成功
        DataPack.flush(npack)
    end 
end

--37防沉迷
function OnClickGiftFCM(pActor, packet) 
    -- 平台验证
    if not OnCheck37Platform() then 
        return 
    end
    local data = get37PlatformData(pActor)
    if data == nil then
        return
    end  
    if data.FcmGift == nil then
        return
    end 
      
    if data.fcm ~= 1 then
        return
    end  
    local name = Actor.getName(pActor)

    if  ActivityConfig.FcmReward == nil then
        print("[Tip] [Platform37]没有此配置 GiftFCM！Name = "..name)
        return  
    end
    if data.FcmGift > 0 then
        print("[Tip] [Platform37]GiftFCM 重复领取！Name = "..name)
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:奖励已领取|", tstUI)
        return
    end 
    if CommonFunc.Awards.CheckBagIsEnough(pActor, bagLimit, tmLeftBagNumNotEnough, tstUI) ~= true then
        return
    end
    
    local AwardCfg = ActivityConfig.FcmReward 
    if AwardCfg then 
        --Actor.SendActivityLog(pActor, ActivityType,ActivityType,1) 
        CommonFunc.Awards.Give(pActor, AwardCfg, GameLog.Log_Platform37) 
        --Actor.SendActivityLog(pActor, ActivityType, ActivityType, 2)
        --提示 要配
        if AwardCfg.FcmUitips then
            Actor.sendTipmsg(pActor, AwardCfg.FcmUitips, tstUI)
        end
        
        data.FcmGift = data.FcmGift + 1
        print("[Tip]  [Platform37]  GiftFCM Gift Success "..name)
    end
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sUse37GiftFCM)
    if npack then 
              
        DataPack.writeByte(npack, 1)  --领取成功
        DataPack.flush(npack)

    end
end 
--37等级礼包

function OnClickGiftDaily(pActor, packet)  
    local nIndex = DataPack.readByte(packet); 
    print("[Tip] [Platform37] OnClickGiftDaily :".. nIndex)
    -- 平台验证
    if not OnCheck37Platform() then 
        return 
    end
    
    local name = Actor.getName(pActor)

    local PlatformData = get37PlatformData(pActor)
    if PlatformData == nil then
        print("[Tip] [Platform37] error data :".. nIndex)
        return
    end 
      
    if nIndex >= 32 then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项|", tstUI)
        return  
    end 
    if ActivityConfig.dailyGift == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项|", tstUI)
        return  
    end  
     
    local Cfg = ActivityConfig.dailyGift[nIndex] 
    if Cfg == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项|", tstUI)
        return
    end  
    if Cfg.awards == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此奖励|", tstUI)
        return
    end
 
    local LoginConfig = ActivityConfig.dailyGift 
    --local nIndex = DataPack.readByte(packet)
    if nIndex > #LoginConfig then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项|", tstUI)
        return
    end 
 
    if PlatformData.Vip == 0 then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:等级不足|", tstUI)
        return
    end
 
    local lv = PlatformData.Vip
    --local Cfg
    local count = 0
    local Idlocal = 0
    local CfgTmp = ActivityConfig.dailyGift
    print("[Tip] [Platform37] 111error ddata.Vip  :".. PlatformData.Vip )
    if CfgTmp then
        --print("[Tip] [Platform37] 222error ddata.Vip  :".. PlatformData.Vip )
        for key, value in pairs(CfgTmp) do 
 
            if value.viplvl > lv then
                --Actor.sendTipmsg(pActor, "|C:0xf56f00&T:不满足条件|", tstUI)
                --return
            elseif nIndex == key and value.viplvl <= lv then
                Idlocal = key
                
                print("[Tip] [Platform37] 333error ddata.Vip  :".. lv ..":"..value.viplvl..":"..nIndex)
                --Cfg = value
                break
            else
            end
            count = count + 1
        end
    end  

    print("[Tip] [Platform37]68764----------  :"..Idlocal ..":name"..name)
    local Cfg = ActivityConfig.dailyGift[Idlocal] 
    if Cfg == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项|", tstUI)
        print("[Tip] [Platform37] 222er212321ror 无此选项  :")
        return  
    end 
    if Cfg.awards == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此奖励|", tstUI)
        return  
    end  
 
    if CommonFunc.Awards.CheckBagIsEnough(pActor, bagLimit, tmLeftBagNumNotEnough, tstUI) ~= true then
        return
    end
 
    local AwardCfg = Cfg.awards 
    if AwardCfg then
        -- 领取检查 
        local flag = System.getIntBit(PlatformData.DataDailyGift, nIndex - 1) 
        if flag == 1 then
            print("[Tip] [Platform37]DailyGift 重复领取！Name = "..name)
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:奖励已领取|", tstUI)
            return
        end  
 
        --Actor.SendActivityLog(pActor, ActivityType,ActivityType,1) 
        CommonFunc.Awards.Give(pActor, AwardCfg, GameLog.Log_Platform37) 
        --Actor.SendActivityLog(pActor, ActivityType, ActivityType, 2)
        --提示 要配
        if Cfg.FcmUitips then
            Actor.sendTipmsg(pActor, Cfg.FcmUitips, tstUI)
        end
        
        PlatformData.DataDailyGift = System.setIntBit(PlatformData.DataDailyGift, nIndex - 1, 1) --将indexId位置置为1 

        print("[Tip] [Platform37] ------------- running 333"..name)
    end
    print("[Tip] [Platform37] ---OnClickGiftDaily:"..name)
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sUse37GiftDaily)
    if npack then             
        DataPack.writeByte(npack, 1)  --领取成功          
        DataPack.writeUInt(npack, PlatformData.DataDailyGift)  
        DataPack.flush(npack) 
    end 
end
--37等级礼包
function OnClickLevelDaily(pActor, packet)  
    local nIndex = DataPack.readByte(packet); 
    print("[Tip] [Platform37] OnClickLevelDaily :".. nIndex)
    -- 平台验证
    if not OnCheck37Platform() then 
        return 
    end
    
    local PlatformData = get37PlatformData(pActor)
    if PlatformData == nil then
        return
    end 
 
    local name = Actor.getName(pActor)

    if nIndex >= 32 then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项|", tstUI)
        return  
    end

    if ActivityConfig.levelGift == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项|", tstUI)
        return  
    end  
    
    local Cfg = ActivityConfig.levelGift[nIndex] 
    if Cfg == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项|", tstUI)
        return
    end 
    if Cfg.awards == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此奖励|", tstUI)
        return
    end

    local LoginConfig = ActivityConfig.levelGift 
    --local nIndex = DataPack.readByte(packet)
    if nIndex > #LoginConfig then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项|", tstUI)
        return
    end
 
    local lv = Actor.getIntProperty( pActor, PROP_CREATURE_LEVEL )
         
    local count = 0
    local Idlocal = 0
    local CfgTmp = ActivityConfig.levelGift
    if CfgTmp then
        for key, value in pairs(CfgTmp) do

            if value.lvl > lv then  
                --Actor.sendTipmsg(pActor, "|C:0xf56f00&T:不满足条件|", tstUI)
                --return
            elseif nIndex == key and value.lvl <= lv then
                Idlocal = key
                break
            else
            end
            count = count + 1
        end
    end  

    local Cfg = ActivityConfig.levelGift[Idlocal] 
    if Cfg == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项|", tstUI)
        return  
    end 
    if Cfg.awards == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此奖励|", tstUI)
        return  
    end  
 
    if CommonFunc.Awards.CheckBagIsEnough(pActor, bagLimit, tmLeftBagNumNotEnough, tstUI) ~= true then
        return
    end
 
    local AwardCfg = Cfg.awards 
    if AwardCfg then
        -- 领取检查 
        local flag = System.getIntBit(PlatformData.DataLevelGift, nIndex - 1) 
        if flag == 1 then
            print("[Tip] [Platform37]LevelDaily 重复领取！Name = "..name)
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:奖励已领取|", tstUI)
            return
        end  
 
        --Actor.SendActivityLog(pActor, ActivityType,ActivityType,1) 
        CommonFunc.Awards.Give(pActor, AwardCfg, GameLog.Log_Platform37) 
        --Actor.SendActivityLog(pActor, ActivityType, ActivityType, 2)
        --提示 要配
        if Cfg.FcmUitips then
            Actor.sendTipmsg(pActor, Cfg.FcmUitips, tstUI)
        end
        
        PlatformData.DataLevelGift = System.setIntBit(PlatformData.DataLevelGift, nIndex - 1, 1) --将indexId位置置为1 

    end
    print("[Tip] [Platform37] ---OnClickLevelDaily:"..name) 
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sUse37LevelDaily)
    if npack then           
        DataPack.writeByte(npack, 1)  --领取成功          
        DataPack.writeUInt(npack, PlatformData.DataLevelGift)  
        DataPack.flush(npack) 
    end 
end
   
function OnClickGiftDaily111(pActor, packet)   
    local data = get37PlatformData(pActor)
    if data == nil then
        return
    end
    if data.Vip == nil then
        data.Vip = 3   
    end
    data.Vip = 6   
    data.hezi = 1
    data.phone = 1
    data.fcm = 1 
    data.DataLevelGift = 56 
    data.DataDailyGift = 72
      
    print("[Tip] [Platform37]init data".. data.Vip)
    Send37PlatformData(pActor)
    OnClickGiftDaily(pActor, packet)  
end
 
 
local function AfterCheckBindPhone(paramPack, content, result) 
    print("[Tip] [Platform37] AfterCheckBindPhone -------------------------content:"..tostring(content).."result:"..tostring(result))   
    local res = CODE_SUCCESS
    local actid = 0
    if (result == 0) then --有反馈  
        local resPattern = "^(.*)(return_code%s*:%s)([^,]*)(.*)$"
        strCapture1, strCapture2, res, strCapture3, strCapture4 = string.match(content, resPattern)
        print("[Tip] [Platform37]   -------------------------param1:"..tostring(strCapture1).."|param2:"..tostring(strCapture2).."|param3:"..tostring(res).."|param4:"..tostring(strCapture3).."|param5:"..tostring(strCapture4)) 
 
        if (res == "0") then --可以领
   
            local aidPattern = "^(.*)(aid%s*:%s)([^,]*)(.*)$"
            strCapture1, strCapture2, actid, strCapture3, strCapture4 = string.match(content, aidPattern)
            print("[Tip] [Platform37] -------------------------param1:"..tostring(strCapture1).."|param2:"..tostring(strCapture2).."|param3:"..tostring(actid).."|param4:"..tostring(strCapture3).."|param5:"..tostring(strCapture4))
 
            actid = tonumber(actid)  
            if not PfId then
                print("[Tip] [Platform37]AfterCheckBindPhone OnCheck37Platform not PfId")
                return false
            end
            if not ActivityConfig then
                print("[Tip] [Platform37]AfterCheckBindPhone OnCheck37Platform not ActivityConfig")
                return false
            end
            if not ActivityConfig.SPID then
                print("[Tip] [Platform37]AfterCheckBindPhone OnCheck37Platform not ActivityConfig.SPID")
                return false
            end
            if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
                print("[Tip] [非本平台活动]")  
                return false--非本平台活动
            end
            if  ActivityConfig.bindPhoneReward == nil then
                print("[ERR] [Platform37] AfterCheckBindPhone没有此配置 GiftPhone  ")
                return
            end 
            local AwardCfg = ActivityConfig.bindPhoneReward 
            if AwardCfg then   
                SendMail(actid, "系统邮件", "尊敬的玩家：感谢您的支持，请查收您的手机绑定礼包奖励。", AwardCfg)  
                print("[Tip] [Platform37] AfterCheckBindPhone success : res("..res.."), content: "..content)
            end 
        else 
            print("[Tip] [Platform37] AfterCheckBindPhone : 已经领了, content: "..content)
        end 
    else
        res = CODE_HTTP
        print("[ERR] [Platform37]1  AfterCheckBindPhone : result("..result.."), content: "..content)
    end 
end
 
function OnCMDBackStageBindPhone(packet)  
    local sActorId = DataPack.readInt(packet)
    print("[Tip] [Platform37]--- BackStageBindPhone:"..tostring(sActorId))

    -- 平台验证
    if not OnCheck37Platform() then 
        print("[Tip] [Platform37]error--非本平台- BackStageBindPhone："..tostring(sActorId))
        return 
    end
             
    BindPhoneHost = ServiceConfCKD.host                                                                 --"fgtest.bigrnet.com"
    BindPhonePort = ServiceConfCKD.port                                                                    --"80"
    BindPhoneApi = "/Service/CheckBindPhoneCode.php"                                                     --"/H5CQ/develop/Service/CheckBindPhoneCode.php"
    
    local req = BindPhoneApi..'?pfid='..PfId..'&aid='..sActorId..'&sid='..SrvId..'&check='..0
    print("[Platform37] GetHttpContent -------------------------ServiceHost:"..tostring(BindPhoneHost))
    print("[Platform37] GetHttpContent -------------------------ServicePort:"..tostring(BindPhonePort))
    print("[Platform37]  GetHttpContent -------------------------req:"..tostring(req))

    --加入异步工作 
    AsyncWorkDispatcher.Add(
        {'GetHttpContent', BindPhoneHost, BindPhonePort, req},
        AfterCheckBindPhone,
        {sActorId, 0}
    )
    if 1 then  
        return 
    end 
    local pActor = Actor.getActorById(sActorId)
    if not pActor  then 
        print("[Tip] [Platform37]error--玩家不在线- BackStageBindPhone："..tostring(sActorId))
        return 
    end


    local data = get37PlatformData(pActor)
    if data == nil then
        return
    end  
    if data.phoneGift == nil then
        data.phoneGift = 0
    end 
       
    --if data.phone == 0 then
    --    return
    --end 

    local name = Actor.getName(pActor)

    if  ActivityConfig.bindPhoneReward == nil then
        print("[Tip] [Platform37]error 没有此配置 GiftPhone Name = "..name)
        return
    end
    if data.phoneGift > 0 then
        print("[Tip] [Platform37]error GiftFCM 重复领取！Name = "..name)
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:奖励已领取|", tstUI)
        return
    end 
     
    if CommonFunc.Awards.CheckBagIsEnough(pActor, bagLimit, tmLeftBagNumNotEnough, tstUI) ~= true then
        return
    end
    local AwardCfg = ActivityConfig.bindPhoneReward 
    if AwardCfg then  
        --Actor.SendActivityLog(pActor, ActivityType,ActivityType,1) 
        --CommonFunc.Awards.Give(pActor, AwardCfg, GameLog.Log_Platform37) 
        
        SendMail(sActorId, "系统邮件", "尊敬的玩家：感谢您的支持，请查收您的手机绑定礼包奖励。", AwardCfg)-- NewCdkeyAwards)
        --Actor.SendActivityLog(pActor, ActivityType, ActivityType, 2)
        --提示 要配
        if AwardCfg.bindPhoneUitips then
            Actor.sendTipmsg(pActor, AwardCfg.bindPhoneUitips, tstUI)
        end
        
        data.phoneGift = data.phoneGift + 1
        print("[Tip]  [Platform37]  GiftPhone Success "..name)
    end
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sUse37GiftPhone)
    if npack then
                   
        DataPack.writeByte(npack, 1)  --领取成功
        DataPack.flush(npack)
    end 
end
 
--登陆

NetmsgDispatcher.Reg(enPlatforMwelfareID, cUse37DownloadBox, OnClickDownloadBox)--37盒子下载礼包 
NetmsgDispatcher.Reg(enPlatforMwelfareID, cUse37GiftFCM, OnClickGiftFCM)--37防沉迷
NetmsgDispatcher.Reg(enPlatforMwelfareID, cUse37GiftPhone, OnClickGiftPhone)--37手机礼包
NetmsgDispatcher.Reg(enPlatforMwelfareID, cUse37GiftDaily, OnClickGiftDaily)--37每日礼包
NetmsgDispatcher.Reg(enPlatforMwelfareID, cUse37LevelDaily, OnClickLevelDaily)--37等级礼包

NetmsgDispatcher.Reg(enPlatforMwelfareID, c37Logon, On37GameLogin)--37等级礼包
--测试
--NetmsgDispatcher.Reg(enMiscSystemID, cBuyMonthCard, OnClickDownloadBox)--37盒子下载礼包
--NetmsgDispatcher.Reg(enMiscSystemID, cBuyMonthCard, OnClickGiftFCM)--37防沉迷 
  
ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "Platform37Gift.lua")
 