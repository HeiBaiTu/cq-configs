module("PlatformSoGouGift", package.seeall)

local CODE_CHECK_NULL = 0	   
local CODE_CHECK_SKIN_LOGIN = 1    -- 皮肤登陆
local CODE_CHECK_PLAZA_LOGIN = 2      -- 大厅登陆    

--对应的活动配置
ActivityConfigPT = PlatformSogouConfig-- skin 和大厅礼包
ActivityConfigLv = LevelSogouConfig
ActivityConfigLg = LoginSogouConfig

local PfId = System.getPfId()
local SOGOU_SPID = 23
 
local bagLimit = 16 --需要的格子数量

Host = ActivityConfigPT.host or "wan.sogou.com"
Port = ActivityConfigPT.port or "80"
Api = ActivityConfigPT.api or "/api/user/bindMobile/status.do"

function OnCheckSogouPlatform()
    -- 平台验证
    if not PfId then
        print("[Tip] [PlatformSogou] OnCheckSogouPlatform not PfId")
        return false
    end
    if not ActivityConfigPT then
        print("[Tip] [PlatformSogou] OnCheckSogouPlatform not ActivityConfigPT")
        return false
    end 
    if not ActivityConfigLv then
        print("[Tip] [PlatformSogou] OnCheckSogouPlatform not ActivityConfigLv")
        return false
    end 
    if not ActivityConfigLg then
        print("[Tip] [PlatformSogou] OnCheckSogouPlatform not ActivityConfigLg")
        return false
    end 
    if tostring(PfId) ~= tostring(SOGOU_SPID) then
        print("[Tip] [非本平台活动]")  
        return false--非本平台活动
    end
    return true
end

--对应的活动配置
function getSogouPlatformData(pActor)
    local var = Actor.getStaticVar(pActor)
    if var.PlatformSogouData == nil then
        var.PlatformSogouData = {} 
        var.PlatformSogouData.DataLevelGift = 0 
        var.PlatformSogouData.DataDailyGift = 0 


        var.PlatformSogouData.PlazaData = 0
        var.PlatformSogouData.SkinData = 0 
         
        var.PlatformSogouData.loginday = 1  
        var.PlatformSogouData.WEINXIN_LOGIN = 0  
        var.PlatformSogouData.PLAZA_LOGIN = 0  
        var.PlatformSogouData.SKIN_LOGIN = 0   
        var.PlatformSogouData.BINDPHONE = 0   --绑定手机

        print("[Tip] [PlatformSogou]init data")
    end
    return var.PlatformSogouData
end


function SendSogouPlatformData(pActor) 
    -- 平台验证
    if not OnCheckSogouPlatform() then 
        return 
    end
    
    local data = getSogouPlatformData(pActor)
          
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSogouLogonData)
    if npack then
        -- print("1111") 
        
        if data.loginday == nil then 
            data.loginday = 1
        end

        DataPack.writeByte(npack, (data.loginday or 1)) 
        DataPack.writeByte(npack, (data.WEINXIN_LOGIN or 0)) 
        DataPack.writeByte(npack, (data.SKIN_LOGIN or 0))  
        DataPack.writeByte(npack, (data.PLAZA_LOGIN or 0))   
 
        DataPack.writeUInt(npack, (data.DataDailyGift or 0))  
        DataPack.writeUInt(npack, (data.DataLevelGift or 0)) 

        DataPack.writeByte(npack, (data.BINDPHONE or 0))   

        print("[Tip] [PlatformSogou] ------DataPack.LevelGift=:".. tostring(data.DataLevelGift))
        print("[Tip] [PlatformSogou] ------DataPack.DailyGift=:".. tostring(data.DataDailyGift)) 
        DataPack.flush(npack)
    end
end

--------------------------------------------------------------------
-- CPP回调
--------------------------------------------------------------------
 
-- Sogou游戏玩家登录
function OnSogouLogon(pActor, packet)
    local nIndex1 = DataPack.readByte(packet) 
    print("[Tip] [PlatformSogou] OnSogouGameLogin:".. nIndex1)
 
    -- 平台验证
    if not OnCheckSogouPlatform() then 
        return 
    end   
    -- 当天初始化
    local data = getSogouPlatformData(pActor) 
    
    --更新登陆数据
    data.PlazaData = 0
    data.SkinData = 0
    if nIndex1 == 2 then
        data.PlazaData = 1
    elseif nIndex1 == 3 then 
        data.SkinData = 1
    end
    
    local Cfg = ActivityConfigPT 
    local data = getActorCdkData(pActor)
    if data then
        if data.codeTypeTimes then
            if data.codeTypeTimes[Cfg.CDkeytype] then
                data.WEINXIN_LOGIN = 1
            end
        end
    end
    if data.lastLoginTime == nil then
        data.lastLoginTime = System.getCurrMiniTime()    
        print("[Tip] [PlatformSogou] 564336434-----------------2-----------")
    end

    if data.loginday == nil then 
        data.loginday = 1
        print("[Tip] [PlatformSogou] 564336434----------------------------".. data.loginday)
    end
    SendSogouPlatformData(pActor)  
    --[[
    local account = Actor.getAccount(pActor)
    local aid = Actor.getActorId(pActor)
    local now = os.time() 
    local key = "{FD11BC5B-A515-48E5-B09A-FAA45839292B}" -- {FD11BC5B-A515-48E5-B09A-FAA45839292B}
    local sign = System.MD5(account, now, key)
    local req = Api..'?gid='..account..'&uid='..aid..'&time='..now.."&sign="..string.upper(sign)
    print("Require YYHallLogin[" .. Actor.getName(pActor) .. "] : ".. req)
    AsyncWorkDispatcher.Add(
        {'GetHttpContent',Host,Port,req},
        AfterCheckYYHall,
        {aid}
    )
    --]]

end 
-- 跨天
function OnNewDayArrive(pActor,ndiffday)
    print("[Tip] [PlatformSogou] OnNewDayArrive")

    -- 平台验证
    if not OnCheckSogouPlatform() then 
        print("[Tip] [PlatformSogou] -------------21321312312321is newday!") 
        return
    end 
   
    print("[Tip] [PlatformSogou] ------------000000000000000000000is newday!") 
    local currMiniTime = System.getCurrMiniTime()
    --local data = get4366Data(pActor)
    local data = getSogouPlatformData(pActor)--37平台数据
     
    if data.lastLoginTime then 
        print("[Tip] [PlatformSogou] -----------------222------------------is newday!".. data.loginDay) 
        if not System.isSameDay(data.lastLoginTime, System.getCurrMiniTime()) then
            data.lastLoginTime = System.getCurrMiniTime()
            data.loginDay = data.loginDay + 1
            
            print("[Tip] [PlatformSogou] ---------------333--------------------is newday!".. data.loginDay)  
            data.DataDailyGift = 0
        end

        SendSogouPlatformData(pActor)
    else
        
        data.lastLoginTime = System.getCurrMiniTime()
        data.loginDay = 1
        print("[Tip] [PlatformSogou] -------------3464646465444--------------------is newday!")  
    end
end 

--领取手机绑定礼包
function OnClickSogouBindPhone(pActor, packet) 
    print("[Tip] [PlatformSogou] OnClickSogouBindPhone")

    -- 平台验证
    if not OnCheckSogouPlatform() then 
        return 
    end
    local data = getSogouPlatformData(pActor)
    if data == nil then
        return
    end  

    local name = Actor.getName(pActor)

    if data.BINDPHONE == nil then
        data.BINDPHONE = 0
    end  
 
    if  ActivityConfigPT.PhoneReward == nil then
        print("[Tip] [PlatformSogou]没有此配置 SKIN_LOGIN Name = "..name)
        return
    end
    if data.BINDPHONE > 0 then
        print("[Tip] [PlatformSogou]SKIN_LOGIN 重复领取！Name = "..name)
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:奖励已领取|", tstUI)
        return
    end 
    if CommonFunc.Awards.CheckBagIsEnough(pActor, bagLimit, tmLeftBagNumNotEnough, tstUI) ~= true then
        return
    end
    
    local AwardCfg = ActivityConfigPT.PhoneReward 
    if AwardCfg then 
        
        --Actor.SendActivityLog(pActor, ActivityType, ActivityType, 1) 
        CommonFunc.Awards.Give(pActor, AwardCfg, GameLog.Log_PlatformSoGou)
        --Actor.SendActivityLog(pActor, ActivityType, ActivityType, 2)

        --提示 要配
        if ActivityConfigPT.tips then
            Actor.sendTipmsg(pActor, ActivityConfigPT.tips, tstUI)
        end
        print("[Tip]  [PlatformSogou]  BINDPHONE Gift Success ")
        data.BINDPHONE = data.BINDPHONE + 1 
    end

    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSogouGiftPhone)
    if npack then
               
        DataPack.writeByte(npack, 1)  --领取成功
        DataPack.flush(npack)

    end 
end
--领取皮肤登陆奖励
function OnClickSogouGiftSkin(pActor, packet) 
    print("[Tip] [PlatformSogou] OnClickSogouGiftSkin")

    -- 平台验证
    if not OnCheckSogouPlatform() then 
        return 
    end
    local data = getSogouPlatformData(pActor)
    if data == nil then
        return
    end  

    local name = Actor.getName(pActor)

    if data.SKIN_LOGIN == nil then
        return
    end  

    if data.SkinData == 0 then
        print("[Tip] [PlatformSogou] SkinData 登陆条件不满足  Name = "..name)
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:登陆条件不满足|", tstUI)
        return
    end 
    if  ActivityConfigPT.reward1 == nil then
        print("[Tip] [PlatformSogou]没有此配置 SKIN_LOGIN Name = "..name)
        return
    end
    if data.SKIN_LOGIN > 0 then
        print("[Tip] [PlatformSogou]SKIN_LOGIN 重复领取！Name = "..name)
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:奖励已领取|", tstUI)
        return
    end 
    if CommonFunc.Awards.CheckBagIsEnough(pActor, bagLimit, tmLeftBagNumNotEnough, tstUI) ~= true then
        return
    end
    
    local AwardCfg = ActivityConfigPT.reward1 
    if AwardCfg then 
        --Actor.SendActivityLog(pActor, ActivityType, ActivityType, 1) 
        CommonFunc.Awards.Give(pActor, AwardCfg, GameLog.Log_PlatformSoGou) 
        --Actor.SendActivityLog(pActor, ActivityType, ActivityType, 2)

        --提示 要配
        if ActivityConfigPT.tips1 then
            Actor.sendTipmsg(pActor, ActivityConfigPT.tips1, tstUI)
        end
        data.SKIN_LOGIN = data.SKIN_LOGIN + 1
        print("[Tip]  [PlatformSogou]  SKIN_LOGIN Gift Success ")
    end

    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSogouGiftSkin)
    if npack then
               
        DataPack.writeByte(npack, 1)  --领取成功
        DataPack.flush(npack)

    end 
end

--37大厅登陆新手礼包
function OnClickGiftRookie(pActor, packet) 
    -- 平台验证
    if not OnCheckSogouPlatform() then 
        return 
    end
    local data = getSogouPlatformData(pActor)
    if data == nil then
        return
    end  

    local name = Actor.getName(pActor)

    if data.PLAZA_LOGIN == nil then
        return
    end  
    if data.PlazaData == 0 then
        print("[Tip] [PlatformSogou] PlazaData登陆条件不满足  Name = "..name)
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:登陆条件不满足|", tstUI)
        return
    end 
  
    if  ActivityConfigPT.reward2 == nil then
        print("[Tip] [PlatformSogou]没有此配置 OnClickGiftRookie Name = "..name)
        return
    end
    if data.PLAZA_LOGIN > 0 then
        print("[Tip] [PlatformSogou]GiftFCM 重复领取！Name = "..name)
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:奖励已领取|", tstUI)
        return
    end 
     
    if CommonFunc.Awards.CheckBagIsEnough(pActor, bagLimit, tmLeftBagNumNotEnough, tstUI) ~= true then
        return
    end
    local AwardCfg = ActivityConfigPT.reward2 
    if AwardCfg then  
        --Actor.SendActivityLog(pActor, ActivityType,ActivityType,1) 
        CommonFunc.Awards.Give(pActor, AwardCfg, GameLog.Log_PlatformSoGou) 
        --Actor.SendActivityLog(pActor, ActivityType, ActivityType, 2)
        --提示 要配
        if ActivityConfigPT.tips2 then
            Actor.sendTipmsg(pActor, ActivityConfigPT.tips2, tstUI)
        end
        
        data.PLAZA_LOGIN = data.PLAZA_LOGIN + 1
        print("[Tip]  [PlatformSogou]  OnClickGiftRookie Success ")
    end
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSogouGiftRookie)
    if npack then
                   
        DataPack.writeByte(npack, 1)  --领取成功
        DataPack.flush(npack)
    end 
end
  
--登陆礼包 
function OnClickGiftLogin(pActor, packet)  
    local nIndex = DataPack.readByte(packet); 
    print("[Tip] [PlatformSogou] OnClickGiftLogin :".. nIndex)
    -- 平台验证
    if not OnCheckSogouPlatform() then 
        return 
    end
    
    local name = Actor.getName(pActor)

    local PlatformData = getSogouPlatformData(pActor)
    if PlatformData == nil then
        print("[Tip] [PlatformSogou] error data :".. nIndex)
        return
    end 
      
    if nIndex >= 32 then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项1|", tstUI)
        return  
    end 
    
    local LocalCfg = ActivityConfigLg
    if LocalCfg == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项2|", tstUI)
        return  
    end  
     
    local Cfg = LocalCfg[nIndex] 
    if Cfg == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项3|", tstUI)
        return
    end  
    if Cfg.reward == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此奖励4|", tstUI)
        return
    end
  
    --local nIndex = DataPack.readByte(packet)
    if nIndex > #LocalCfg then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项5|", tstUI)
        return
    end  
    if PlatformData.loginday == nil then  
        PlatformData.loginday = 1
    end  
   
    local count = 0
    local Idlocal = 0
    local CfgTmp = LocalCfg 
    if CfgTmp then
        --print("[Tip] [PlatformSogou] 222error ddata.Vip  :".. PlatformData.Vip )
        for key, value in pairs(CfgTmp) do 
 
            print("[Tip] [PlatformSogou] loginday data :".. key .. ":"..value.day .. ":"..Idlocal)
            if value.day > PlatformData.loginday then
                --Actor.sendTipmsg(pActor, "|C:0xf56f00&T:不满足条件|", tstUI)
                --return
            elseif nIndex == key and value.day <= PlatformData.loginday then
                Idlocal = key
                 
                break
            else
            end
            count = count + 1
        end
    end  
    print("[Tip] [PlatformSogou] loginday data :".. nIndex .. ":"..PlatformData.loginday .. ":"..Idlocal) 
    local Cfg = LocalCfg[Idlocal] 
    if Cfg == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项6|", tstUI)
        print("[Tip] [PlatformSogou] 222er212321ror 无此选项6  :")
        return  
    end 
    if Cfg.reward == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此奖励7|", tstUI)
        return  
    end  
 
    if CommonFunc.Awards.CheckBagIsEnough(pActor, bagLimit, tmLeftBagNumNotEnough, tstUI) ~= true then
        return
    end
  
    local AwardCfg = Cfg.reward 
    if AwardCfg then
        -- 领取检查 
        local flag = System.getIntBit(PlatformData.DataDailyGift, nIndex - 1) 
        if flag == 1 then
            print("[Tip] [PlatformSogou]DailyGift 重复领取！Name = "..name)
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:奖励已领取|", tstUI)
            return
        end  
  
        --Actor.SendActivityLog(pActor, ActivityType,ActivityType,1) 
        CommonFunc.Awards.Give(pActor, AwardCfg, GameLog.Log_PlatformSoGou) 
        --Actor.SendActivityLog(pActor, ActivityType, ActivityType, 2)
        --提示 要配
        if Cfg.tips then
            Actor.sendTipmsg(pActor, Cfg.tips, tstUI)
        end
        
        PlatformData.DataDailyGift = System.setIntBit(PlatformData.DataDailyGift, nIndex - 1, 1) --将indexId位置置为1 

        --print("[Tip] [PlatformSogou] ----4------DataDailyGift---::".. PlatformData.DataDailyGift)
    end 
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSogouGiftLogin)
    if npack then             
        DataPack.writeByte(npack, 1)  --领取成功          
        DataPack.writeUInt(npack, PlatformData.DataDailyGift)  
        DataPack.flush(npack) 
    end 
end

--37等级礼包
function OnClickGiftLevel(pActor, packet)  
    local nIndex = DataPack.readByte(packet); 
    print("[Tip] [PlatformSogou] OnClickGiftLevel :".. nIndex)
    -- 平台验证
    if not OnCheckSogouPlatform() then 
        return 
    end
    
    local PlatformData = getSogouPlatformData(pActor)
    if PlatformData == nil then
        return
    end 
 
    local name = Actor.getName(pActor)

    if nIndex >= 32 then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项1|", tstUI)
        return  
    end

    local LocalCfg = ActivityConfigLv
    if LocalCfg == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项2|", tstUI)
        return  
    end  
    
    local Cfg = LocalCfg[nIndex] 
    if Cfg == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项3|", tstUI)
        return
    end 
    if Cfg.reward == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此奖励4|", tstUI)
        return
    end
 
    --local nIndex = DataPack.readByte(packet)
    if nIndex > #LocalCfg then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项5|", tstUI)
        return
    end
 
    local lv = Actor.getIntProperty( pActor, PROP_CREATURE_LEVEL )
          
    local count = 0
    local Idlocal = 0
    local CfgTmp = LocalCfg
    if CfgTmp then
        for key, value in pairs(CfgTmp) do 
            print("[Tip] [PlatformSogou] ----2------DataLevelGift---:key:".. key.. ":"..value.level)
            if value.level > lv then   
            elseif nIndex == nIndex and value.level <= lv then
                Idlocal = key
                break
            else
            end
            count = count + 1
        end
    end  

    local Cfg = LocalCfg[Idlocal] 
    if Cfg == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此选项6|", tstUI)
        return  
    end 
    if Cfg.reward == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此奖励7|", tstUI)
        return  
    end  
 
    if CommonFunc.Awards.CheckBagIsEnough(pActor, bagLimit, tmLeftBagNumNotEnough, tstUI) ~= true then
        return
    end
 
    local AwardCfg = Cfg.reward 
    if AwardCfg then
        -- 领取检查 
        local flag = System.getIntBit(PlatformData.DataLevelGift, nIndex - 1) 
        if flag == 1 then
            print("[Tip] [PlatformSogou]LevelDaily 重复领取！Name = "..name)
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:奖励已领取|", tstUI)
            return
        end  
 
        --Actor.SendActivityLog(pActor, ActivityType,ActivityType,1) 
        CommonFunc.Awards.Give(pActor, AwardCfg, GameLog.Log_PlatformSoGou) 
        --Actor.SendActivityLog(pActor, ActivityType, ActivityType, 2)
        --提示 要配
        if Cfg.tips then
            Actor.sendTipmsg(pActor, Cfg.tips, tstUI)
        end
        
        PlatformData.DataLevelGift = System.setIntBit(PlatformData.DataLevelGift, nIndex - 1, 1) --将indexId位置置为1 

    end
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSogouGiftLevel)
    if npack then           
        DataPack.writeByte(npack, 1)  --领取成功          
        DataPack.writeUInt(npack, PlatformData.DataLevelGift)  
        DataPack.flush(npack) 
    end 
end
    
function OnClickGiftLogin2222(pActor, packet)    
    local data = getSogouPlatformData(pActor)
    if data == nil then
        print("[Tip]---------------------------212121-------------")
        return
    end 
    
    data.PlazaData = 0
    data.SkinData = 0 
    --data.DataLevelGift = 0 
    --data.DataDailyGift = 0
    data.loginday  = 12

    
    -- 活动结束 
    local Cfg = ActivityConfigPT
    --if Cfg == nil then 
        local data = getActorCdkData(pActor)
        if data then
            if data.codeTypeTimes then
                if data.codeTypeTimes[Cfg.CDkeytype] then
                    data.WEINXIN_LOGIN = 1
                end
            end
        end  
    --end

    print("[Tip] [PlatformSogou]init data")
    SendSogouPlatformData(pActor)
    OnClickSogouBindPhone(pActor, packet)  
end

--登陆 
NetmsgDispatcher.Reg(enPlatforMwelfareID, cSogouGiftPhone, OnClickSogouBindPhone)--搜狗手机绑定礼包 
NetmsgDispatcher.Reg(enPlatforMwelfareID, cSogouGiftSkin, OnClickSogouGiftSkin)--搜狗皮肤登陆  
NetmsgDispatcher.Reg(enPlatforMwelfareID, cSogouGiftRookie, OnClickGiftRookie)--搜狗新手礼包 
NetmsgDispatcher.Reg(enPlatforMwelfareID, cSogouGiftLogin, OnClickGiftLogin)--搜狗登陆礼包
NetmsgDispatcher.Reg(enPlatforMwelfareID, cSogouGiftLevel, OnClickGiftLevel)--搜狗等级礼包 



NetmsgDispatcher.Reg(enPlatforMwelfareID, cSogouLogon, OnSogouLogon)--搜狗登陆

--测试 
--NetmsgDispatcher.Reg(enMiscSystemID, cBuyMonthCard, OnClickGiftLogin2222)--37每日礼包
  
ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "PlatformSoGouGift.lua")  