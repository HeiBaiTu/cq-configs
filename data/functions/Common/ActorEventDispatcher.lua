module("ActorEventDispatcher", package.seeall)

local dispatcher = {}

-- @brief 注册事件分发器
-- @param evId 事件id
-- @param func 回调
function Reg(evId, func, file)
	
	--必须有参数
	if evId == nil or func == nil or file == nil then 
		print( debug.traceback() )
		print( file )
		assert(false)
	end

	--玩家事件
	if evId >= aeMaxEventCount or evId <= aeNoEvent then
		print("[ERROR][EventDispatcher] evId("..evId..") error!")
		assert(false)
	else
		if dispatcher[evId] == nil then
			dispatcher[evId] = {}
		end
		table.insert(dispatcher[evId], func)
		System.regScriptEvent(enType, evId)
	end
	print("[TIP][EventDispatcher] Add Actor Event("..evId..") In File("..file.."), And Index="..table.maxn(dispatcher[evId]))

	return true
end

function OnEvent(nIndex, evId, pActor, ...)
	local func = dispatcher[evId][nIndex]
	if func then
		return func(pActor, ...)
	end
	return false
end


--[[ 详细见：ActorEventDef.h

enum tagActorEventID
{
	aeNoEvent			= 0,	//未定义事件
	aeLevel				= 1,	//角色升级	参数1：当前等级数
	aeUserLogin			= 2,    //玩家登陆  参数1：是否第一次登录
	aeUserLogout		= 3,    //玩家登出  参数1：人物id
	aeOnActorDeath		= 4,	//人物死亡
	aeReliveTimeOut		= 5,	//判断复活时间是否超时（用户超过5分钟没有选择回城复活还是原地复活），如果到达，脚本处理，送回主城复活. 参数1：人物指针
	aeNewDayArrive		= 6,	//跨天或在线期间0点整[角色指针，天数]
	aeOnActorBeKilled	= 7,	//被玩家杀死		 [角色指针，杀人者指针]
	aeWithDrawYuanBao	= 8,	//提取元宝			 [角色指针，提取的元宝数量]
	aeConsumeYb			= 9,	//消费元宝			 [角色指针，消耗元宝数量]
	aeOnEnterFuben		= 10,	//玩家请求进入副本	 [角色指针，进入的副本id]
	aeOnExitFuben		= 11,	//玩家请求退出副本	 [角色指针，退出的副本id]
	aeGuild				= 12,	//帮派相关
	aeEquipComposite    = 13,   //装备合成			 [角色指针，目标装备ItemID]
	aeBuffRemoved		= 14,	//buff被删除事件
	aeLeaveTeam			= 15,	//离开队伍
	aeCircle			= 16,	//角色转生			 [角色指针，当前等级数]
	aeChangeName		= 17,	//改名
	aeAsyncOpResult		= 18,	//异步操作结果 参数1：类型 参数2：结果 参数3：操作方式 参数4：错误码 参数5：卡号 参数6：增值类型 参数7：Sub类型
	aeHero              = 19,   //英雄系统
	aeHurtMonster		= 20,	//对怪物造成伤害
};

]]

--return EventDispatcher