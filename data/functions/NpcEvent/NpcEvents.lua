
NpcFuncs = {}

local NpcConf = Npc
local NpcFunctionsConf = NpcFunctions

if NpcConf==nil or NpcFunctionsConf==nil then
    assert(false, "NPC的功能分类配置找不到。")
end

--#include "NpcShop.txt" once  		--npc商店
--#include "NpcTeleport.txt" once  	--npc传送
--#include "NpcUIFuncs.txt" once  	--npc传送

function OnNpcEvent(pActor, nNpcHandle, nNpcId, nFuncId, pDPack)
	
	if NpcFunctionsConf[nFuncId] and NpcFunctionsConf[nFuncId].funcType then
		local funcType = NpcFunctionsConf[nFuncId].funcType
		local npcFunc = NpcFuncs[funcType]
		if npcFunc then
			print("[OnNpcEvent] nNpcHandle:" .. nNpcHandle .." nNpcId:"..nNpcId.." nFuncId:"..nFuncId.." funcType:"..funcType)
			print(npcFunc)
			return npcFunc(pActor, nNpcHandle, nNpcId, nFuncId, pDPack)
		else
			print("[ERROR][OnNpcEvent] 没有该功能的NPC实现; nNpcHandle:" .. nNpcHandle .." nNpcId:"..nNpcId.." nFuncId:"..nFuncId.." funcType:"..funcType)
		end
	else
		print("[ERROR][OnNpcEvent] 配置没有该功能ID; nNpcHandle:" .. nNpcHandle .." nNpcId:"..nNpcId.." nFuncId:"..nFuncId)
	end
end

function OnNpcTimer(npcId, funcName, ... )
	local npcFunc = NpcDialog[npcId]
	if npcFunc then
		local realFunc = npcFunc[funcName]
		if realFunc then
			realFunc(unpack(arg))
		end
	end
end
