--module("PcDownLoadGift", package.seeall)

--[[
    微端功能 个人数据
    PcClientData = {
        pcGift
    }
]]

local FcmServiceHostHttp = "http://fcmds.sdo.com"  
local FcmServiceHost = "fcmds.sdo.com"   ---/http://fcmds.sdo.com/heartbeat //"devops.191game.com"
local FcmServicePort = "80"
local FcmHeartbeateUrl = "/heartbeat"
local FcmUseroffline = "/useroffline"
local FcmUseronline = "/useronline"
local Fcmappid = "1100012" 

local FcmSecretkey = "01mbv7nqqj4f34m7zjnd14a9zfamvphx"
local FcmAccounttype = 1
local FcmMerchant_name = "1_1100012_7429"
local FcmSignature_method = "MD5"

local FcmIpadd = "16777343"
local FcmSevPort = 443

PlatformConfig = NativeRewardConfig 
local PfId = System.getPfId()

function getActorPcClientData(pActor)
    if Actor.getEntityType(pActor) ~= enActor then
        assert(false)
    end
    local var = Actor.getStaticVar(pActor);
    if var.PcClientData == nil then
        var.PcClientData = {}
    end

    return var.PcClientData
end

function OnPcDownLoadGift(pActor, packet)
    if PfId ~= nil and PlatformConfig.SPID ~= nil and table.getn(PlatformConfig.SPID) > 0 then
        --print("[Tip] [PlatformQQ] SendQQHallData ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)
        local Can = 0
        for k, v in ipairs(PlatformConfig.SPID) do
           -- print(k,v)
            --print("[Tip] [NativeRewardConfig] NativeRewardConfig333 ---------------- SPID MSG:"..tostring(v))
            if tostring(PfId) == tostring(v) then
                Can = Can + 1
            end
        end
        --print("[Tip] [NativeRewardConfig] NativeRewardConfig444 ---------------- SPID count:"..tostring(Can))
        if Can == 0 then
            print("[Tip] [NativeRewardConfig] [非本平台活动]")
            return --非本平台活动
        end
    end

    local data = getActorPcClientData(pActor)
    if data.pcGift then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:已领取|", tstUI)
        return
    end
    local conf = PlatformConfig

    if conf and conf.reward then
        CommonFunc.Awards.Give(pActor, conf.reward, GameLog.Log_PcGift)
    end

    data.pcGift = 1;
    Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)
    SendPcClientState(pActor);
    Actor.setStaticCount(pActor, 10005, 1);

    local strName = Actor.getName(pActor)
    if conf and conf.tips then 
        local strTips = string.format(conf.tips,strName)
        System.broadcastTipmsgLimitLev(strTips, tstKillDrop)
    end

    if conf and conf.tips2 then 
        local strTipm2 = string.format(conf.tips2,strName)
        System.broadcastTipmsgLimitLev(strTipm2, tstChatSystem)
    end
end

function SendPcClientState(pActor)
    local npack = DataPack.allocPacket(pActor, enDefaultEntitySystemID, sPcClientDownLoadState)
    if npack then
        -- print("1111")
        local data = getActorPcClientData(pActor)
        DataPack.writeByte(npack, (data.pcGift or 0)) --
        DataPack.flush(npack)
    end
end
 
-- 回调
local function AfterGetHttpContent(paramPack, content, result) 
    local aid = paramPack[1]
    print("[Tip] [SQFcm] AfterGetHttpContent --------------------------aid:"..aid.."------------------- content:"..tostring(content))  

    --测试数据local strContent00 = "{\"return_code\":-10250031,\"return_message\":\"Server reject, no authority, remote ip is 49.234.73.200\",\"data\":{}}"
    
    local strPattern11 = "^(.*)(return_code%s*\"%s*)(%b:,)(.*)$"
    local strPattern22 = "^(.*)(return_message\"%s*:%s*)(%b\"\")(.*)$"

    --local strContent = "abcde  csdn = {博客}  csdn.net" 
    --local strPattern = "^(.*)(csdn%s*=%s*)(%b{})(.*)$" 
    --local strCapture1, strCapture2, strCapture3, strCapture4 = string.match(strContent, strPattern)
 
    --print("t------"..tostring(strCapture1).."------"..tostring(strCapture2).."------"..tostring(strCapture3).."------"..tostring(strCapture4))
    if result == 0 then
        local strCapture1, strCapture2, return_code, strCapture3, strCapture4 = string.match(content, strPattern11)
        local strCapture1, strCapture2, return_message, strCapture4 = string.match(content, strPattern22)
        --local return_code = string.match(strContent00,"return_code\":-(%a+),\"return")
        --local return_message = string.match(strContent00,"return_message\":\"(%a+)\",\"") 
        --code = (string.gsub(return_code, "^[%s\n\r\t]*(.-)[%s\n\r\t]*$", "%1"))
        --message = (string.gsub(return_message, "^[%s\n\r\t]*(.-)[%s\n\r\t]*$", "%1"))
        --code = string.match(return_code,":%s+,")
        --message = string.match(return_message, "\"%s+\"")
        print("[Tip] [SQFcm] AfterGetHttpContent ----------return_code:"..tostring(return_code) )
        print("[Tip] [SQFcm] AfterGetHttpContent ---------return_message:"..tostring(return_message) )  
        --print("[return_code-----------------------------------------------------------------------return_code:"..tostring(code) )
        --print("[return_message--------------------------------------------------------------------return_message:"..tostring(message) ) 
    end 
end

local function GetHttpContentOnline(paramPack, content, result) 
    local aid = paramPack[1]
    print("[Tip] [SQFcm] GetHttpContentOnline --------------------------aid:"..aid.."------------------- content:"..tostring(content)) 
 
    local strPattern11 = "^(.*)(return_code%s*\"%s*)(%b:,)(.*)$"
    local strPattern22 = "^(.*)(return_message\"%s*:%s*)(%b\"\")(.*)$"
 
    if result == 0 then
        local strCapture1, strCapture2, return_code, strCapture3, strCapture4 = string.match(content, strPattern11)
        local strCapture1, strCapture2, return_message, strCapture4 = string.match(content, strPattern22) 
        print("[Tip] [SQFcm] GetHttpContentOnline ----------return_code:"..tostring(return_code) )
        print("[Tip] [SQFcm] GetHttpContentOnline ---------return_message:"..tostring(return_message) ) 
        
        if(tostring(return_code) == ": 0,") then

            local strPattern33 = "^(.*)(remainingTime%s*\"%s*)(%b:,)(.*)$" 
           
            local str1, str2, remainingTime, str4 = string.match(content, strPattern33) 
            print("[Tip] [SQFcm] GetHttpContentOnline ----------remainingTime:"..tostring(remainingTime)) 
            if remainingTime == nil then
                return
            end      
            local sscount = string.len(remainingTime)
   
            if(sscount > 2) then 
                res = string.sub(remainingTime, 2, sscount - 1)   
                print("[GetHttpContentOnline---------------------------------remainingTime = :"..tostring(res))
                local remaining =  tonumber(res)
                local pActor = Actor.getActorById(actorid)
                --Actor.changeFcmTime(pActor, remaining) 
                print("[Tip] [SQFcm] GetHttpContentOnline ----------remainingTime"..tostring(remaining)) 
            end
      
        end     
    end 
end
-- 防沉迷
function OnFcmUseOnline(pActor, packet) 
    local ntype = DataPack.readByte(packet)
    local nMsg = DataPack.readByte(packet)
    local nSub = DataPack.readByte(packet)
    --local ServerIndex = DataPack.readint(packet) 
    print("[Tip] [SQFcm] OnFcmUseOnline -------------------------id:"..tostring(ntype).."nMsg:"..tostring(nMsg).."nSub:"..tostring(nSub)  )
 
    --local AccountName = DataPack.readString(packet)
    --local code = DataPack.readString(packet)
    --print("[Tip] OnFcmUseOnline : code = " .. tostring(code).."name"..Actor.getName(pActor))

   --加入异步工作
   --local account = Actor.getAccount(pActor)
   --local aid = Actor.getActorId(pActor)

    --即时生成
    local eventtime = System.getCurrMiniTime()
    local match_eventtime = os.date("%Y-%m-%d %H:%M:%S", os.time()) 
    local characterid = Actor.getName(pActor);
    local PfId = System.getPfId()
    local SrvId = System.getServerId() 
    local account = 'om00748880396.pt'--Actor.getAccount(pActor)--盛趣正式账号 om00748880396.pt'om00748880396.pt'--
    local aid = Actor.getActorId(pActor)
    local str_guid = System.MD5(tostring(eventtime))
    --local nYear,  nMonth, nDay
	--System.getDate(nYear,  nMonth, nDay) 
    --local nHour, nMinute, nSecond, nMiliSecond
	--System.getTime(nHour, nMinute, nSecond, nMiliSecond) 
    --print("[OnFcmUseOnline--eventtime------------------------------------"..tostring(eventtime))
    --print("[OnFcmUseOnline--str_guid------------------------------------"..tostring(str_guid))
    --固定
    local reqSign = 'accounttype='..FcmAccounttype..'&appid='..Fcmappid..'&areaid='..'1'..'&characterid='..aid..'&endpointip='..FcmIpadd..'&endpointport='..FcmSevPort..'&eventtime='..match_eventtime..'&groupid='..SrvId..'&guid='..tostring(str_guid)..'&merchant_name='..tostring(FcmMerchant_name)..'&signature_method='..tostring(FcmSignature_method)..'&timestamp='..tostring(eventtime)..'&userid='..tostring(account)
    local reqSign1 = 'accounttype='..FcmAccounttype..'appid='..Fcmappid..'areaid='..'1'..'characterid='..aid..'endpointip='..FcmIpadd..'endpointport='..FcmSevPort..'eventtime='..match_eventtime..'groupid='..SrvId..'guid='..tostring(str_guid)..'merchant_name='..tostring(FcmMerchant_name)..'signature_method='..tostring(FcmSignature_method)..'timestamp='..tostring(eventtime)..'userid='..tostring(account)

    local sign = System.MD5(tostring(reqSign1..FcmSecretkey))
    --print("[OnFcmUseOnline--reqSign1-----------------reqSign1Size:-------------------"..string.len(tostring(reqSign1..FcmSecretkey)))
    
    print("[Tip] [SQFcm] OnFcmUseOnline -------------------------reqSign:"..tostring(reqSign1)) 
    print("[Tip] [SQFcm] OnFcmUseOnline -------------------------FcmSecretkey:"..tostring(FcmSecretkey)) 
    print("[Tip] [SQFcm] OnFcmUseOnline -------------------------sign:"..tostring(sign)) 

    local req = FcmUseronline..'?'..reqSign..'&signature='..tostring(sign)

    AsyncWorkDispatcher.Add(
        {'GetHttpContent', FcmServiceHost, FcmServicePort, req},
        GetHttpContentOnline,
        {aid, 0}
    )
end

function OnFcmUseOffline(pActor, packet)
    local ntype = DataPack.readByte(packet)
    local nMsg = DataPack.readByte(packet)
    local nSub = DataPack.readByte(packet) 
    print("[Tip] [SQFcm] OnFcmUseOffline -------------------------id:"..tostring(ntype).."nMsg:"..tostring(nMsg).."nSub:"..tostring(nSub)  )
 
    --local code = DataPack.readString(packet)
    --print("[Tip] OnFcmUseOnline : code = " .. tostring(code).."name"..Actor.getName(pActor))

    --即时生成
    local eventtime = System.getCurrMiniTime()
    local match_eventtime = os.date("%Y-%m-%d %H:%M:%S", os.time()) 
    local characterid = Actor.getName(pActor);
    local PfId = System.getPfId()
    local SrvId = System.getServerId() 
    local account = 'om00748880396.pt'--Actor.getAccount(pActor)--'om00748880396.pt'--
    local aid = Actor.getActorId(pActor)
    local str_guid = System.MD5(tostring(eventtime)) 
    --print("[OnFcmUseOnline--str_guid------------------------------------"..tostring(str_guid))
    --固定
    local reqSign = 'accounttype='..FcmAccounttype..'&appid='..Fcmappid..'&areaid='..'1'..'&characterid='..aid..'&endpointip='..FcmIpadd..'&endpointport='..FcmSevPort..'&eventtime='..match_eventtime..'&groupid='..SrvId..'&guid='..tostring(str_guid)..'&merchant_name='..tostring(FcmMerchant_name)..'&signature_method='..tostring(FcmSignature_method)..'&timestamp='..tostring(eventtime)..'&userid='..tostring(account)
    local reqSign1 = 'accounttype='..FcmAccounttype..'appid='..Fcmappid..'areaid='..'1'..'characterid='..aid..'endpointip='..FcmIpadd..'endpointport='..FcmSevPort..'eventtime='..match_eventtime..'groupid='..SrvId..'guid='..tostring(str_guid)..'merchant_name='..tostring(FcmMerchant_name)..'signature_method='..tostring(FcmSignature_method)..'timestamp='..tostring(eventtime)..'userid='..tostring(account)

    local sign = System.MD5(tostring(reqSign1..FcmSecretkey))
    --print("[OnFcmUseOnline--reqSign1-----------------reqSign1Size:-------------------"..string.len(tostring(reqSign1..FcmSecretkey)))
    
    print("[Tip] [SQFcm] OnFcmUseOffline -------------------------reqSign:"..tostring(reqSign1)) 
    print("[Tip] [SQFcm] OnFcmUseOffline -------------------------FcmSecretkey:"..tostring(FcmSecretkey)) 
    print("[Tip] [SQFcm] OnFcmUseOffline -------------------------sign:"..tostring(sign)) 
 
    local req = FcmUseroffline..'?'..reqSign..'&signature='..tostring(sign)
  
    AsyncWorkDispatcher.Add(
        {'GetHttpContent', FcmServiceHost, FcmServicePort, req},
        AfterGetHttpContent,
        {aid, 0}
    )
end 

function OnFcmUseHeatbeat2(ppActor, packet) 
    local ntype = DataPack.readByte(packet)
    local nMsg = DataPack.readByte(packet)
    local nSub = DataPack.readByte(packet)

    local nCount = DataPack.readByte(packet)
    print("[Tip] [SQFcm] OnFcmUseHeatbeat2 -------------------------id:"..tostring(ntype).."nMsg:"..tostring(nMsg).."nSub:"..tostring(nSub) .."nCount："..tostring(nCount) ) 
  
    local eventtime = System.getCurrMiniTime()
    local PfId = System.getPfId()
    local SrvId = System.getServerId() 

    --固定
    local reqSign = 'appid='..Fcmappid..'ip='..FcmIpadd..'merchant_name='..tostring(FcmMerchant_name)..'signature_method='..tostring(FcmSignature_method)..'timestamp='..tostring(eventtime)
    local reqSign1 = 'appid='..Fcmappid..'&ip='..FcmIpadd..'&merchant_name='..tostring(FcmMerchant_name)..'&signature_method='..tostring(FcmSignature_method)..'&timestamp='..tostring(eventtime)

    local msghead = "usersinfo=["
    local msgItem = ""
  	for i = 1,  nCount do
        --print("[OnFcmUseHeatbeat2----------------------------------------i："..tostring(i))
        local actorid = DataPack.readUInt(packet)
        --print("[OnFcmUseHeatbeat2----------------------------------------i："..tostring(actorid))
        local pActor = Actor.getActorById(actorid)
        print("[Tip] [SQFcm] OnFcmUseHeatbeat2 usersinfo---------------------- name:"..Actor.getName(pActor).."actorid:"..tostring(actorid)) 
        
        if pActor == nil then
            break
        end
        local characterid = Actor.getName(pActor);
        local account = 'om00748880396.pt'--Actor.getAccount(pActor)
        local aid = Actor.getActorId(pActor)

        msgItem = msgItem..'{\"areaid\":'..'1'..',\"groupid\":'..SrvId..',\"userid\":\"'..account..'\",\"accounttype\":'..FcmAccounttype..',\"characterid\":\"'..aid..'\"},'
        --if(i < nCount)
        --{
        --    msgItem = msgItem..','
        --}
  	end
    if msgItem == "" then
        return
    end
    local msg = msghead..msgItem..']'

    local sign = System.MD5(tostring(reqSign..msg..FcmSecretkey))
    local req = FcmHeartbeateUrl..'?'..reqSign1..'&signature='..tostring(sign)

    print("[Tip] [SQFcm] OnFcmUseHeatbeat -------------------------reqSign:"..tostring(reqSign1))
    print("[Tip] [SQFcm] OnFcmUseHeatbeat -------------------------FcmSecretkey:"..tostring(FcmSecretkey))
    print("[Tip] [SQFcm] OnFcmUseHeatbeat -------------------------sign:"..tostring(sign))

	local str = string.format("POST %s HTTP/1.1\r\nHost: %s\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: %d\r\n\r\n%s",  req, FcmServiceHost, string.len(msg), msg)

    ---AsyncWorkDispatcher.Add({'Test', 1,2},AfterGetHttpContent,{expect=1+1})
    AsyncWorkDispatcher.Add(
        {'PostHttpContent2', FcmServiceHost, FcmServicePort, str},
        AfterGetHttpContent,
        {aid, 0}
    )
    print("[Tip] [SQFcm] OnFcmUseHeatbeat -------------------------msghead:"..tostring(msghead))
end
function OnFcmUseHeatbeat(pActor, packet) 
    local ntype = DataPack.readByte(packet)
    local nMsg = DataPack.readByte(packet)
    local nSub = DataPack.readByte(packet)
   -- print("[OnFcmUseHeatbeat----------------------------------------------------------------------- id:"..tostring(ntype).."nMsg:"..tostring(nMsg).."nSub:"..tostring(nSub)  )

    local code = DataPack.readString(packet)
   -- print("[Tip] OnFcmUseOnline : code = " .. tostring(code).."name"..Actor.getName(pActor))
 
    --即时生成
    local eventtime = System.getCurrMiniTime()
    local characterid = Actor.getName(pActor);
    local PfId = System.getPfId()
    local SrvId = System.getServerId() 
    local account = Actor.getAccount(pActor)
    local aid = Actor.getActorId(pActor)
    --固定
    local reqSign = 'appid='..Fcmappid..'ip='..FcmIpadd..'merchant_name='..tostring(FcmMerchant_name)..'signature_method='..tostring(FcmSignature_method)..'timestamp='..tostring(eventtime)
    local reqSign1 = 'appid='..Fcmappid..'&ip='..FcmIpadd..'&merchant_name='..tostring(FcmMerchant_name)..'&signature_method='..tostring(FcmSignature_method)..'&timestamp='..tostring(eventtime)

    local msg = 'usersinfo=[{\"areaid\":'..'1'..',\"groupid\":'..SrvId..',\"userid\":\"'..account..'\",\"accounttype\":'..FcmAccounttype..',\"characterid\":\"'..aid..'\"}]'

    local sign = System.MD5(tostring(reqSign..msg..FcmSecretkey))
    local req = FcmHeartbeateUrl..'?'..reqSign1..'&signature='..tostring(sign)

   -- print("[OnFcmUseHeatbeat--reqSign1------------------------------------"..tostring(reqSign1))
    --print("[OnFcmUseHeatbeat--FcmSecretkey------------------------------------"..tostring(FcmSecretkey))
    --print("[OnFcmUseHeatbeat--sign------------------------------------"..tostring(sign))

	local str = string.format("POST %s HTTP/1.1\r\nHost: %s\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: %d\r\n\r\n%s",  req, FcmServiceHost, string.len(msg), msg)

    ---AsyncWorkDispatcher.Add({'Test', 1,2},AfterGetHttpContent,{expect=1+1})
    AsyncWorkDispatcher.Add(
        {'PostHttpContent2', FcmServiceHost, FcmServicePort, str},
        AfterGetHttpContent,
        {aid, 0}
    )
end

NetmsgDispatcher.Reg(enDefaultEntitySystemID, cGetPcClientDownLoadGift, OnPcDownLoadGift)
-- 防沉迷
NetmsgDispatcher.Reg(enMiscSystemID, sFcmUseOnline, OnFcmUseOnline)
NetmsgDispatcher.Reg(enMiscSystemID, sFcmUseOffline, OnFcmUseOffline)
--NetmsgDispatcher.Reg(enMiscSystemID, sFcmUseHeatbeat, OnFcmUseHeatbeat)
NetmsgDispatcher.Reg(enMiscSystemID, sFcmAllUseHeatbeat, OnFcmUseHeatbeat2)
