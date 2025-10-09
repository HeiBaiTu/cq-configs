module("NetmsgDispatcher", package.seeall)

local dispatcher = {}

-- @brief 注册网络包的处理函数
-- @param sysId 系统id
-- @param cmd   系统内的消息号
function Reg(sysId, cmdId, func)
	if cmdId == nil or sysId == nil then print( debug.traceback() ) end
	if sysId > 256 or cmdId > 256 then
		print("[ERROR][NetmsgDispatcher] sysId("..sysId..") or cmdId("..cmdId..") error!")
		assert(false)
		return
	end
	dispatcher[sysId] = dispatcher[sysId] or {}
	dispatcher[sysId][cmdId] = func
	System.regScriptNetMsg(sysId, cmdId)
	return true
end

function OnNetMsg(sysId, cmdId, actor, pack)
	if not dispatcher[sysId] then return end

	local func = dispatcher[sysId][cmdId]
	print("玩家:"..Actor.getActorId(actor)..",收到消息请求,系统:"..sysId..",协议:"..cmdId)
	if func then
		func(actor, pack)
	end
end

_G.OnNetMsg=OnNetMsg


--[[ 详细见：LogicServerCmd.h


]]