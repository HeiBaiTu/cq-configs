module("TanWanChatReport", package.seeall)


Host = "yyhunfuht.bigrnet.com"
Api = "/tanwan/api/wechat"
Port = "80"


local HttpStatus = {
    Success = "10001",	 -- 访问成功
    Send = "10009",	     -- 可以发送
}


function AfterCheckTanWanChatReport(paramPack,content,result)
    print("TanWanChatReport AfterCheckTanWanChatReport")

    local nActorId = paramPack[1]
    local pActor = Actor.getActorById(nActorId)
    if not pActor then
        print("[Tip] TanWanChatReport AfterCheckTanWanChatReport [" .. nActorId .. "] 已离线")
        return
    end
    print("[Tip] TanWanChatReport AfterCheckTanWanChatReport [" .. Actor.getName(pActor) .. "] content:"..content)
    print("[Tip] TanWanChatReport AfterCheckTanWanChatReport [" .. Actor.getName(pActor) .. "] result:"..result)

    if 0 == result then
        local status = string.match(content,"\"status\":(%d+)")
        local code = string.match(content,"\"code\":(%d+)")

        if HttpStatus.Success == status then
            print("TanWanChatReport OnReqTanWanChatReport visit Success!")
        else
            print("TanWanChatReport OnReqTanWanChatReport visit Fail! status : "..status)
        end

        if HttpStatus.Send == code then
            print("TanWanChatReport OnReqTanWanChatReport can Send!")
        else
            print("TanWanChatReport OnReqTanWanChatReport can't Send! code : "..code)
        end
    end
end


-- --------------------------------------------------------------------
-- -- CPP回调
-- --------------------------------------------------------------------


function OnReqTanWanChatReport(nServerId, szServerName, szAccount, nActorId, szActorName, nTanWanChannleId, szMsg, szSendToActorName)
    print("TanWanChatReport OnReqTanWanChatReport nServerId ："..nServerId.." szServerName : "..szServerName.." Account: "..szAccount.." nActorId : "..nActorId.." ActorName : "..szActorName.." nTanWanChannleId : "..nTanWanChannleId.." SendToActorName : "..szSendToActorName)
    print("TanWanChatReport OnReqTanWanChatReport ".." msg: "..szMsg)

    local game_server_id = nServerId
    local game_server_name = szServerName
    local uid = szAccount
    local username = szAccount
    local role_id = nActorId
    local role_name = szActorName
    local content_type = nTanWanChannleId
    local content = szMsg
    local to_role_name = szSendToActorName
    local send_time = os.time()

    local req = Api..'?game_server_id='..game_server_id..'&game_server_name='..game_server_name..'&uid='..uid..'&username='..username..'&role_id='..role_id
    req = req..'&role_name='..role_name..'&content_type='..content_type..'&content='..content..'&to_role_name='..to_role_name..'&send_time='..send_time

    -- print("TanWanChatReport OnReqTanWanChatReport [" .. Actor.getName(pActor) .. "] Host : ".. Host)
    -- print("TanWanChatReport OnReqTanWanChatReport [" .. Actor.getName(pActor) .. "] Port : ".. Port)
    -- print("TanWanChatReport OnReqTanWanChatReport [" .. Actor.getName(pActor) .. "] req : ".. req)

    AsyncWorkDispatcher.Add(
        {'GetHttpContent',Host,Port,req},
        AfterCheckTanWanChatReport,
        {nActorId}
    )
end

