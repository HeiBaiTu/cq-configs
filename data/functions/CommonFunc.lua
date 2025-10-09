module("CommonFunc", package.seeall)
----一些公共方法

--activetime是{{h1,m1},{h2,m2}}形式(不能跨天)
function CheckTimeValid(time)
	local nHour,nMin,nSec = System.getTime(0,0,0,0)    --当前时间
	local timeBegin = time[1]
	local timeEnd 	= time[2]
	--print("CheckTimeValid, nHour="..nHour..", nMin="..nMin)
	--print("CheckTimeValid, h1="..timeBegin[1]..", m1="..timeBegin[2]..", h2="..timeEnd[1]..", m2="..timeEnd[2])
	if nHour < timeBegin[1] or nHour > timeEnd[1] then		--小开始小时、大于结束小时
		return false
	elseif timeBegin[1] == timeEnd[1]  then    		--起止小时是同一个小时
		if nMin < timeBegin[2] or nMin > timeEnd[2] then	--不在分钟范围之内
			return false
		else
			return true
		end
	elseif timeBegin[1] < timeEnd[1] then		--开始小时小于结束小时
		if nHour == timeBegin[1] and nMin < timeBegin[2] then
			return false
		elseif nHour == timeEnd[1] and nMin > timeEnd[2] then
			return false
		else
			return true
		end
	end
	return false
end

function CheckTimesValid( times )
	for i,time in ipairs(times) do
		if CheckTimeValid(time) then
			return true
		end
	end
	return false
end

--[[某场景内刷怪，不足补足，多了不刷
	{ 
		monsterId=15, sceneId=1, num=1, range={100,120,200,420}, livetime=86400,
	},
]]
function freshSceneMonsterInRange(freshMonCfg)
	--print("freshSceneMonsterInRange, sceneId="..freshMonCfg.sceneId..", monsterId="..freshMonCfg.monsterId)
	local hScene = Fuben.getSceneHandleById(freshMonCfg.sceneId, 0)
	if hScene then
		local num = freshMonCfg.num - Fuben.getMyMonsterCount(hScene, freshMonCfg.monsterId)
		if num > 0 then
			return Fuben.createMonstersInRange(hScene, freshMonCfg.monsterId, 
				freshMonCfg.range[1], freshMonCfg.range[2], freshMonCfg.range[3], freshMonCfg.range[4], 
				num, freshMonCfg.livetime)
		end
	end
	return 0
end

--[[某场景内刷怪，必定刷出
]]
function freshSceneMonsterInRangeForce(freshMonCfg)
	--print("freshSceneMonsterInRangeForce, sceneId="..freshMonCfg.sceneId..", monsterId="..freshMonCfg.monsterId)
	local hScene = Fuben.getSceneHandleById(freshMonCfg.sceneId, 0)
	if hScene then
		local num = freshMonCfg.num
		if num > 0 then
			return Fuben.createMonstersInRange(hScene, freshMonCfg.monsterId, 
				freshMonCfg.range[1], freshMonCfg.range[2], freshMonCfg.range[3], freshMonCfg.range[4], 
				num, freshMonCfg.livetime)
		end
	end
	return 0
end

--[[某场景内刷怪，不足补足，多了不刷
	{ 
		monsterId=15, sceneId=1, num=1, pos={122,171}, livetime=86400,
	},
]]
function freshSceneMonsterInPos(freshMonCfg)
	--print("freshSceneMonsterInPos, sceneId="..freshMonCfg.sceneId)
	local hScene = Fuben.getSceneHandleById(freshMonCfg.sceneId, 0)
	if hScene then
		local num = freshMonCfg.num - Fuben.getMyMonsterCount(hScene, freshMonCfg.monsterId)
		if num > 0 then
			return Fuben.createMonstersInRange(hScene, freshMonCfg.monsterId, 
				freshMonCfg.pos[1], freshMonCfg.pos[2], freshMonCfg.pos[1], freshMonCfg.pos[2], 
				num, freshMonCfg.livetime)
		end
	end
	return 0
end

--[[某场景内刷怪，必定刷出
]]
function freshSceneMonsterInPosForce(freshMonCfg)
	--print("freshSceneMonsterInPosForce, sceneId="..freshMonCfg.sceneId)
	local hScene = Fuben.getSceneHandleById(freshMonCfg.sceneId, 0)
	if hScene then
		local num = freshMonCfg.num
		if num > 0 then
			return Fuben.createMonstersInRange(hScene, freshMonCfg.monsterId, 
				freshMonCfg.pos[1], freshMonCfg.pos[2], freshMonCfg.pos[1], freshMonCfg.pos[2], 
				num, freshMonCfg.livetime)
		end
	end
	return 0
end

--获取某个场景中的怪物数量
function GetSceneMonsterNum( sceneId, fbHandle, monsterId )
	local hScene = Fuben.getSceneHandleById(sceneId, fbHandle)
	if hScene then
		return Fuben.getMyMonsterCount(hScene, monsterId)
	end
	return 0
end

--[[ 清除怪物
freshMonConfig =
{ 
	monsterId=15, sceneId=1, num=1, pos={122,171}, livetime=86400,
},
]]--
function clearScenceMonster(freshMonConfig)
	local hScene = Fuben.getSceneHandleById(freshMonConfig.sceneId, 0)
	if hScene then
		Fuben.clearMonster(hScene,  freshMonConfig.monsterId)
	end
end

--[[某副本内刷怪
	不支持怪物等级成长
	{ monsterId=15, sceneId=1, num=1, pos={122,171,122,171}, livetime=86400 },
]]
function freshFuBenMonsterInRange( hFuben, freshMonCfg )
	local hScene = Fuben.getSceneHandleById(freshMonCfg.sceneId, hFuben)
	return Fuben.createMonstersInRange(hScene, freshMonCfg.monsterId, 
				freshMonCfg.pos[1], freshMonCfg.pos[2], freshMonCfg.pos[3], freshMonCfg.pos[4], 
				freshMonCfg.num, freshMonCfg.livetime)
end

--[[某副本内刷怪
	支持怪物等级成长，
	注意，用过此方法创建出来的怪等级是nOriginalLevel+nBornLevel （配置等级+传入等级）
	{ monsterId=15, sceneId=1, num=1, pos={122,171,122,171}, livetime=86400 },
]]
function freshFuBenMonsterInRangeEx( hFuben, freshMonCfg )
	local hScene = Fuben.getSceneHandleById(freshMonCfg.sceneId, hFuben)
	return Fuben.createMonstersInRange(hScene, freshMonCfg.monsterId, 
				freshMonCfg.pos[1], freshMonCfg.pos[2], freshMonCfg.pos[3], freshMonCfg.pos[4], 
				freshMonCfg.num, freshMonCfg.livetime, freshMonCfg.level or 0)
end


--给奖励
function GiveCommonAward(sysarg, awards, logId, LogDesc)
	for _, v in ipairs(awards) do
		if v.qualityDataIndex then
			Actor.giveAward(sysarg, v.type, v.id, v.count, v.quality or 0, v.strong or 0, v.bind or 0, 0, logId, LogDesc,
				v.qualityDataIndex)
		else
			Actor.giveAward(sysarg, v.type, v.id, v.count, v.quality or 0, v.strong or 0, v.bind or 0, 0, logId, LogDesc)
		end
	end
end
--支持sex和job的过滤（sex、job必须要有）
--由于历史遗留问题和客户端处理，现规定，sex=-1,对性别没有要求，job=0, 对职业没有要求
function FilterCommonAward( sysarg, award )
	if award.sex ~= nil and award.sex ~= -1 and award.sex ~= Actor.getIntProperty(sysarg,PROP_ACTOR_SEX) then  --有性别要求
		return nil
	end
	if award.job ~= nil and award.job ~= 0 and award.job ~= Actor.getIntProperty(sysarg, PROP_ACTOR_VOCATION) then --有职业要求
		return nil
	end
	local myLevel = Actor.getIntProperty(sysarg, PROP_CREATURE_LEVEL)
	if(award.level ~= nil and myLevel < award.level)then
		return nil
	end
	return award
end

--支持sex和job的过滤
function FilterCommonAwards( sysarg, Awards )
	local fAwards = {}
	for _, award in ipairs( Awards ) do
		local fAward = FilterCommonAward(sysarg, award)
		if fAward then
			table.insert(fAwards, fAward)
		end
	end
	return fAwards
end

--给奖励(支持sex和job的过滤)
--由于历史遗留问题和客户端处理，现规定，sex=-1,对性别没有要求，job=0, 对职业没有要求
function GiveCommonAwardEx(sysarg, Awards, logId, LogDesc)
	local fAwards = FilterCommonAwards( sysarg, Awards )   --过滤
	for _, v in ipairs(fAwards) do
		Actor.giveAward(sysarg, v.type, v.id, v.count, v.quality or 0, v.strong or 0, v.bind or 0, 0, logId, LogDesc, v.qualityDataIndex or -1)
	end
end

--检查背包格子是否足够，返回需要空闲的格子数量(支持sex和job的过滤)
--由于历史遗留问题和客户端处理，现规定，sex=-1,对性别没有要求，job=0, 对职业没有要求
function CheckBagGridForAwardsEx(sysarg, Awards)
	local fAwards = FilterCommonAwards( sysarg, Awards )   --过滤
	local needGirds = 0
	for _, v in ipairs( fAwards ) do
		if v.type == 0 then
			needGirds = needGirds + Item.getAddItemNeedGridCount( sysarg, v.id, v.count, v.quality or 0, v.strong or 0, v.bind or -1)
		end
	end
	local hasEmptyIdxs = Item.getAllBagMinEmptyGridCount( sysarg)
	--local hasEmptyIdxs = Item.getBagEmptyGridCount( sysarg,packageType)
	if  hasEmptyIdxs >= needGirds then
		return 0
	else
		return needGirds
	end
end

--检查背包格子是否足够
function IsBagGridEnough(sysarg, awards)
	local needGirds = 0
	for _, v in ipairs( awards ) do
		if v.type == 0 then
			needGirds = needGirds + Item.getAddItemNeedGridCount( sysarg, v.id, v.count, v.quality or 0, v.strong or 0, v.bind or -1)
		end
	end
	local hasEmptyIdxs = Item.getAllBagMinEmptyGridCount( sysarg)
	--local hasEmptyIdxs = Item.getBagEmptyGridCount( sysarg )
	if  hasEmptyIdxs >= needGirds then
		return true
	end
	return false
end

--获取背包格子是否足够
function GetBagGridNeed(sysarg, awards)
	local needGirds = 0
	for _, v in ipairs( awards ) do
		if v.type == 0 then
			needGirds = needGirds + Item.getAddItemNeedGridCount( sysarg, v.id, v.count, v.quality or 0, v.strong or 0, v.bind or -1)
		end
	end
	return needGirds
end

function GetElemByRange( elems, value )
	for i,elem in ipairs(elems) do
		if elem.range[1] <= value and value <= elem.range[2] then
			return elem 
		end
	end
	return nil
end
--判断能否采集，可以采集返回true
function OnGatherMonster( sysarg, pGathMonster )
	local monId = Actor.getIntProperty(pGathMonster, PROP_ENTITY_ID)    --怪物ID
	
	if IsSupplyBattleSack( monId ) then
		return CheckGatherSupplyBattleSack(sysarg, monId)
	end
  	return true
end


--随机传送到某个场景的某个区域，避免人数集中在一起
function SendToSceneInRange(sysarg, sceneId, range)
	local x1 = range[1]
	local y1 = range[2]
	local x2 = range[3]
	local y2 = range[4]
	x  = math.random(x1,x2)
	y  = math.random(y1,y2)
	return Actor.enterScene(sysarg, sceneId, x, y)
end

--在一个范围之内，随机一个pos
function RandPosInRange(range)
	local x1 = range[1]
	local y1 = range[2]
	local x2 = range[3]
	local y2 = range[4]
	x  = math.random(x1,x2)
	y  = math.random(y1,y2)
	return x, y
end

--支持大于21亿的exp
function AddExpToActor(sysarg, exp, logId )
	--print("AddExpToActor, exp="..exp)
	local expLimit = 2100000000
	if exp <= expLimit then
		Actor.addExp(sysarg, exp, logId, 0)
	else
		local expRate = math.floor(exp/expLimit)   --向下取整
		local expMore = math.mod(exp,expLimit)

		for i=1, expRate do
			Actor.addExp(sysarg, expLimit, logId, 0)
		end
		if expMore > 0 then
			Actor.addExp(sysarg, expMore, logId, 0)
		end
	end
end


function GetEntityPos( entityPtr )
	local posX = Actor.getIntProperty(entityPtr, PROP_ENTITY_POSX)
	local posY = Actor.getIntProperty(entityPtr, PROP_ENTITY_POSY)
	return posX, posY
end


--[[初始化排行榜
id, value, name
]]
function InitCommonRank(rankName, numMax)
	local ranking = Ranking.getRanking( rankName )
	if not ranking then
		ranking = Ranking.add( rankName, numMax, 1, 10 )
		if ranking then
			if not Ranking.load(ranking, nil) then
				Ranking.addColumn(ranking, "name")
			end
			Ranking.addRef( ranking )
		end
	end
end

function GetCommonRankValueById(actorId, rankName)
	--print("GetCommonRankValueById, rankName="..rankName..", actorId="..actorId)
	local ranking = Ranking.getRanking( rankName )
	if ranking then
		local item = Ranking.getItemPtrFromId( ranking, actorId)
		if item then
			return Ranking.getPoint(item)
		end
	end
	return 0
end

--设置排行榜数据
function SetCommonRankValueById(actorId, rankName, newValue )
	local ranking = Ranking.getRanking( rankName )
	if ranking then
		local item = Ranking.getItemPtrFromId( ranking, actorId)
		if item then	--已经榜上有名
			Ranking.setItem(ranking, actorId, newValue)
		else	--新加的
			item = Ranking.addItem(ranking, actorId, newValue)
		end
	end
end

--如果排行榜不存在，必须返回nil，为无效数据，避免异常情况
function GetCommonRankColumnValueById(actorId, rankName, colIdx)
	--print("GetCommonRankColumnValue, colIdx="..colIdx)
	local ranking = Ranking.getRanking( rankName )
	if ranking then
		local item = Ranking.getItemPtrFromId( ranking, actorId)
		if item then	--已经榜上有名
			local colValue = Ranking.getSub(item, colIdx)
			if colValue == "-" then
				return 0
			else
				local numValue = tonumber(colValue)
				--print("GetCommonRankColumnValue, numValue="..numValue)
				if numValue then
					return numValue		--返回字符串
				else
					return colValue 	--返回字符串
				end
			end
		else
			return 0
		end
	end
	return nil
end

--设置排行榜的扩展数据
--colIdx：从1开始，0是name
--返回值：true-设置成功，false-设置失败
--在涉及到领取道具的时候，为了避免出现异常，必须判断一下返回值
function SetCommonRankColumnValueById(actorId, rankName, value, colIdx, newColValue)
	--print("SetCommonRankColumnValueById actorId="..actorId..", rankName="..rankName..
	--	", colIdx="..colIdx..", newColValue="..newColValue)
	local ranking = Ranking.getRanking( rankName )
	if ranking then
		local item = Ranking.getItemPtrFromId( ranking, actorId )
		if item then	--已经榜上有名
			Ranking.setSub(item, colIdx, newColValue)    --万一排行榜错误，这里不一定能设置成功
			if Ranking.getSub(item, colIdx) ~= tostring(newColValue) then  --列没有设置成功
				return false
			end
			return true
		else	--新加的
			item = Ranking.addItem(ranking, actorId, value)
			if item then
				Ranking.setSub(item, colIdx, newColValue)
				if Ranking.getSub(item, colIdx) ~= tostring(newColValue) then  --列没有设置成功
					return false
				end
				return true
			end
		end
	end
	return false
end

function AddCommonRankValueById(actorId, rankName, addValue)
	local ranking = Ranking.getRanking( rankName )
	if ranking then
		local item = Ranking.getItemPtrFromId( ranking, actorId)
		if item then	--已经榜上有名
			Ranking.updateItem(ranking, actorId, addValue)
		else	--新加的
			item = Ranking.addItem(ranking, actorId, addValue)
		end

		if item then
			local newValue = Ranking.getPoint(item)
			--print("AddCommonRankValueById, newValue="..newValue)
		end
	end
end

function HasCommonRankValueById( key, rankName )
	local ranking = Ranking.getRanking( rankName )
	if ranking then
		local item = Ranking.getItemPtrFromId( ranking, key)
		if item then	--已经榜上有名
			return true
		end
	end
	return false
end


function ClearCommonRank(rankName)
	--print("ClearCommonRank, rankName="..rankName)
	local ranking = Ranking.getRanking( rankName )
	if ranking then
		Ranking.clearRanking(ranking)
		Ranking.save(ranking, rankName, true)
	end
end

--[[
levelNeedFee = 
	{
		--{cond=等级段，resetItem=重置需要的道具, resetFee=重置需要的费用, finishFee=立即完成的费用
		{ cond={50,59}, resetItem = {510, 1}, resetFee={3, 100}, finishFee={3,50}, },
		{ cond={60,69}, resetItem = {510, 2}, resetFee={3, 200}, finishFee={3,150}, },
		{ cond={70,79}, resetItem = {510, 3}, resetFee={3, 300}, finishFee={3,250}, },
		{ cond={80,89}, resetItem = {510, 4}, resetFee={3, 400}, finishFee={3,350}, },
		{ cond={90,99}, resetItem = {510, 5}, resetFee={3, 500}, finishFee={3,550}, },
	},
]]
function GetElemByCond( elems, condValue )
	for i, elem in ipairs(elems) do
		if elem.cond[1] <= condValue and condValue <= elem.cond[2] then
			return elem
		end
	end
	return nil
end

--根据两个条件匹配
function GetElemMatch2Cond( elems, condValue1, condValue2 )
	--print("GetElemMatch2Cond, condValue1="..condValue1..", condValue2="..condValue2)
	if condValue2 then
		for i, elem in ipairs(elems) do
			if elem.cond[1] == condValue1 and elem.cond[2] == condValue2 then
				--print("GetElemMatch2Cond, xxx1")
				return elem
			end
		end
	else
		for i, elem in ipairs(elems) do
			if elem.cond[1] == condValue1 then
				return elem
			end
		end
	end
	return nil
end

--[[
通知玩家获得某个活动的实际奖励
注意：某些奖励可能是动态计算的
activeId：见enum tagCommonActiveIDDef定义
result:0-失败，1-胜利
]]
function NoticeActiveAward( sysarg, activeId, result, awards )
	--print("NoticeActiveAward, activeId="..activeId..", result="..result)
	local netPack = DataPack.allocPacket(sysarg, 139, enScriptMiscSystemcNoticeActivityAward)
	if netPack then
	    DataPack.writeChar(netPack, activeId)
	    DataPack.writeChar(netPack, result)
		DataPack.writeChar(netPack, #awards) 
		for i,award in ipairs(awards) do
			DataPack.writeChar(netPack, award.type)
			DataPack.writeInt(netPack, award.id)
			DataPack.writeUInt(netPack, award.count)
			--print("NoticeActiveAward, type="..award.type..", id="..award.id..", count="..award.count)
		end
	    DataPack.flush(netPack)
	end
end

function BroadMsgInScence( sceneId, msg, flag)
	local playerList = LuaHelp.getSceneActorListById( sceneId ) or {}
	for i,player in ipairs(playerList) do
		Actor.sendTipmsg(player, msg, flag)
	end
end


function IsElemInList( elemList, value )
	for i, elem in ipairs( elemList or {} ) do
		if value == elem then
			return true
		end
	end
	return false
end
--table to string
BaseFuc_serialize = function( obj )
	local lua = ""
	local t = type( obj )
	if t == "number" then
		lua = lua .. obj
	elseif t == "boolean" then
		lua = lua .. tostring( obj )
	elseif t == "string" then
		lua = lua .. string.format( "%q", obj )
	elseif t == "table" then
		lua = lua .. "{"
		for k, v in pairs( obj ) do
			lua = lua .. "[" .. BaseFuc_serialize( k ) .. "]=" .. BaseFuc_serialize( v ) .. ","
		end
		local metatable = getmetatable( obj )
			if metatable ~= nil and type( metatable.__index ) == "table" then
			for k, v in pairs( metatable.__index ) do
				lua = lua .. "[" .. BaseFuc_serialize( k ) .. "]=" .. BaseFuc_serialize( v ) .. ","
			end
		end
		lua = lua .. "}"
	elseif t == "nil" then
		return nil
	else
		error( "can not BaseFuc_serialize a " .. t .. " type." )
	end
	return lua
end

--string to table
BaseFuc_unserialize = function( lua )
	local t = type( lua )
	if t == "nil" or lua == "" then
		return nil
	elseif t == "number" or t == "string" or t == "boolean" then
		lua = tostring( lua )
	else
		error( "can not unserialize a " .. t .. " type." )
	end
	lua = "return " .. lua
	local func = loadstring( lua )
	if func == nil then
		return nil
	end
	return func()
end

--[[
获取table中元素的数量，key可能是离散分布的
]]
function GetElemsNum( elems )
	local num = 0
	for k,v in pairs( elems or {} ) do
		num = num +1
	end
	return num
end

--[[
--]]
function GetAwardsByRate( awards, rate )
	local newAwards = {}
	for i, award in ipairs(awards) do
		local newAward={}
		newAward.type 				= award.type
		newAward.id 				= award.id
		newAward.count 				= award.count*rate
		newAward.quality 			= award.quality
		newAward.strong				= award.strong
		newAward.bind				= award.bind
		newAward.qualityDataIndex	= award.qualityDataIndex
		table.insert(newAwards, newAward)
	end
	return newAwards
end

--[[检查是否满足消费条件
someConsumes: {consumes1, consumes2, consumes3,...}  多个consumes的集合
rate:倍数
]]
function CheckSomeConsumeCond( sysarg, someConsumes, rate )
	--[[
	local itemConsumes 		= {}  		--道具的消费（type为 qatEquipment，道具不可合并）
	local notItemConsumes 	= {}  		--非道具消费（type为 非qatEquipment，非道具可以合并）

	for nType = qatEquipment, qatAwardTypeCount do
		for i1, consumes in ipairs( someConsumes ) do
			for i2, consume in ipairs( consumes ) do
				if consume.type == nType then
					if consume.type == qatEquipment then
						table.insert( itemConsumes, consume )
					end
				end
			end
		end
	end
	]]
	local consumeRate = rate or 1
	for k, consumes in pairs( someConsumes ) do
		if not CheckConsumeCond( sysarg, consumes, rate ) then
			return false
		end
	end
	return true
end

--[[检查是否满足消费条件
rate:倍数
]]
function CheckConsumeCond( sysarg, consumes, rate )
	local consumeRate = rate or 1
	for k,v in pairs( consumes ) do
		local bCheck = Actor.checkConsume(sysarg, v.type, v.id, v.count*consumeRate, v.quality or 0, v.strong or 0, 
			v.bind or -1) 
		if bCheck ~= true then
			Actor.sendAwardNotEnough(sysarg, v.type, v.id, v.count)
			return false
		end
	end

	return true
end

--[[扣除消费，必须先判断CheckConsumeCond
rate:倍数
]]
function DoConsumeCond( sysarg, consumes, rate, logId, logStr )
	local consumeRate = rate or 1
	for k,v in pairs( consumes ) do
		local removeCount = Actor.removeConsume(sysarg, v.type, v.id, v.count*consumeRate, v.quality or 0, v.strong or 0, 
			v.bind or -1, 0, logId,logStr) 
		if removeCount < v.count then
		   return false
		end
	end
	return true
end

--[[检查是否满足消费条件
rate   :倍数
replace:是否被替代
格式：
consumes = 
{
	{ type = 0,  id = 1373, count = 3 },		--需要的道具
	{ type = 10, id = 0,    count = 30 },		--替换的道具
},
]]
function CheckConsumeCondReplace( sysarg, consumes, rate, replace )
	local consumeRate 		= rate or 1
	local consumeReplace 	= replace or false
	consumeItem = consumes[1]			--需要的物品
	replaceItem = consumes[2]			--替代的物品		
	local bCheck = Actor.checkConsume(sysarg, consumeItem.type, consumeItem.id, consumeItem.count*consumeRate, 
		consumeItem.quality or 0, consumeItem.strong or 0, consumeItem.bind or -1) 
	if bCheck then			--需要的物品足够足够
		return true
	end

	if replace then                --可以替代
		local bReplaceCheck = Actor.checkConsume(sysarg, replaceItem.type, replaceItem.id, 
			replaceItem.count*consumeRate, replaceItem.quality or 0, replaceItem.strong or 0, replaceItem.bind or -1)
		if bReplaceCheck then     --替代物品足够
			return true
		end
	end

	Actor.sendAwardNotEnough(sysarg, consumeItem.type, consumeItem.id, consumeItem.count)
	return false
end

--[[检查并使用消费条件
rate   :倍数
replace:是否被替代
格式：
consumes = 
{
	{ type = 0,  id = 1373, count = 3 },		--需要的道具
	{ type = 10, id = 0,    count = 30 },		--替换的道具
},
]]
function CheckAndUseConsumeCondReplace( sysarg, consumes, rate, replace, logId, logStr )
	local consumeRate = rate or 1
	local consumeReplace 	= replace or false
	consumeItem = consumes[1]			--需要的物品
	replaceItem = consumes[2]			--替代的物品

	local bCheck = Actor.checkConsume(sysarg, consumeItem.type, consumeItem.id, consumeItem.count*consumeRate, 
		consumeItem.quality or 0, consumeItem.strong or 0, consumeItem.bind or -1) 
	if bCheck then			--需要的物品足够足够
		local removeCount = Actor.removeConsume(sysarg, consumeItem.type, consumeItem.id, consumeItem.count*consumeRate, 
			consumeItem.quality or 0, consumeItem.strong or 0, consumeItem.bind or -1, 0, logId, logStr )
		if removeCount >= consumeItem.count then    --实际扣除足够
		   return true
		end
	end

	if replace then                --可以替代
		local bReplaceCheck = Actor.checkConsume(sysarg, replaceItem.type, replaceItem.id, 
			replaceItem.count*consumeRate, replaceItem.quality or 0, replaceItem.strong or 0, replaceItem.bind or -1)
		if bReplaceCheck then     --替代物品足够
			local removeCount = Actor.removeConsume(sysarg, replaceItem.type, replaceItem.id, replaceItem.count*consumeRate, 
				replaceItem.quality or 0, replaceItem.strong or 0, replaceItem.bind or -1, 0, logId, logStr )
			if removeCount >= replaceItem.count then    --实际扣除足够
		   		return true
		   	else
		   		Actor.sendAwardNotEnough(sysarg, replaceItem.type, replaceItem.id, replaceItem.count)
				return false
			end
		else
			Actor.sendAwardNotEnough(sysarg, replaceItem.type, replaceItem.id, replaceItem.count)
			return false
		end
	end

	Actor.sendAwardNotEnough(sysarg, consumeItem.type, consumeItem.id, consumeItem.count)
	return false
end

--[[检查是否满足消费条件
rate   :倍数
replace:是否被替代
--这里的道具不足用元宝替代，且优先消耗完所有道具
格式：
consumes = 
{
	{ type = 0,  id = 1373, count = 3 },		--需要的道具(3个)
	{ type = 10, id = 0,    count = 10 },		--替换的道具(10元宝替换1个道具)
},
]]
function CheckConsumeCondReplaceEx( sysarg, consumes, rate, replace )
	local consumeRate 		= rate or 1
	local consumeReplace 	= replace or false
	consumeItem = consumes[1]			--需要的物品
	replaceItem = consumes[2]			--替代的物品
	local allCount = consumeItem.count* rate
	local consumeItemCount = Actor.getConsume(sysarg, consumeItem.type,consumeItem.id, 0,consumeItem.quality or 0, consumeItem.strong or 0, consumeItem.bind or -1)
	if consumeItemCount >= allCount then
		return true
	end
	local leftCount = allCount - consumeItemCount 
	if replace and replaceItem then                --可以替代
		local bReplaceCheck = Actor.checkConsume(sysarg, replaceItem.type, replaceItem.id, leftCount*replaceItem.count, replaceItem.quality or 0, replaceItem.strong or 0, replaceItem.bind or -1)
		if bReplaceCheck then     --替代物品足够
			return true
		else
			Actor.sendAwardNotEnough(sysarg, replaceItem.type, replaceItem.id, consumeItem.count*replaceItem.count)
		end
	else
		Actor.sendAwardNotEnough(sysarg, consumeItem.type, consumeItem.id, consumeItem.count)
	end
	return false
end

--[[使用消费条件
rate   :倍数
replace:是否被替代
--这里的道具不足用元宝替代，且优先消耗完所有道具
consumes = 
{
	{ type = 0,  id = 1373, count = 3 },		--需要的道具
	{ type = 10, id = 0,    count = 10 },		--替换的道具(10元宝替换1个道具)
},
]]
--先使用 CheckConsumeCondReplaceEx
function UseConsumeCondReplaceEx( sysarg, consumes, rate, replace, logId, logStr )
	local consumeRate 		= rate or 1
	local consumeReplace 	= replace or false
	consumeItem = consumes[1]			--需要的物品
	replaceItem = consumes[2]			--替代的物品
	local allCount = consumeItem.count* rate
	--先扣绑定
	local consumeItemCount = Actor.removeConsume(sysarg, consumeItem.type, consumeItem.id, allCount, consumeItem.quality or 0, consumeItem.strong or 0, 1, 0, logId, logStr )
	if consumeItemCount >= allCount then
		return true
	end
	--再扣不绑定
	consumeItemCount = consumeItemCount + Actor.removeConsume(sysarg, consumeItem.type, consumeItem.id, allCount-consumeItemCount, consumeItem.quality or 0, consumeItem.strong or 0, 0, 0, logId, logStr )
	if consumeItemCount >= allCount then
		return true
	end
	local leftCount = allCount - consumeItemCount 
	if replace and replaceItem then                --可以替代
		local replaceItemCount = Actor.removeConsume(sysarg, replaceItem.type, replaceItem.id, leftCount*replaceItem.count, replaceItem.quality or 0, replaceItem.strong or 0, replaceItem.bind or -1, 0, logId, logStr )
		if replaceItemCount >=leftCount*replaceItem.count then     --替代物品足够
			return true
		else
			return false
		end
	else
		return false
	end
end

function GetMaxValueInThree( value1, value2, value3)
	local value = 0
	if value1 >= value2 then
		value = value1
	else
		value = value2
	end

	if value >= value3 then
		return value
	else
		return value3
	end
end

function GetMinValueInThree( value1, value2, value3)
	local value = 0
	if value1 <= value2 then
		value = value1
	else
		value = value2
	end

	if value <= value3 then
		return value
	else
		return value3
	end
end

function GetMaxValueInThreeGroup( group1, group2, group3)
	local value1 = group1[1]
	local value2 = group2[1]
	local value3 = group3[1]

	local value = GetMaxValueInThree( value1, value2, value3)
	if value == value1 then
		return group1
	elseif value == value2 then
		return group2
	elseif value == value3 then
		return group3
	end
	return nil
end

function GetMinValueInThreeGroup( group1, group2, group3)
	local value1 = group1[1]
	local value2 = group2[1]
	local value3 = group3[1]

	local value = GetMinValueInThree( value1, value2, value3)
	if value == value1 then
		return group1
	elseif value == value2 then
		return group2
	elseif value == value3 then
		return group3
	end
	return nil
end

--[[获取最大物品优先级
优先级 ufDenyDeal > ufBinded > ufUnBind 
]]
function GetMaxUserItemFlag( flagList )
	if IsElemInList( flagList, ufDenyDeal ) then			--有绑定物品
		return ufDenyDeal
	elseif IsElemInList( flagList, ufBinded ) then
		return ufBinded
	end
	return ufUnBind
end

--[[
对于某些类型的奖励，需要进行转换
由于邮件系统已经封装，所以在发送之前由各个功能自行转换，而不是由邮件系统转换
]]
function TransAwardsByType( awards, actorLevel )
	local newAwards = {}
	for i, award in ipairs(awards) do
		--print( "TransAwardsByType, type="..award.type..", count="..award.count )
		if award.type == qatAddExp then			--把经验库经验转换成绝对经验
			local newAward  = {}				--必须用新的table，否则会改动原始配置
			local expLibId 	= award.id
			local rate 		= award.count
			local vipAddRate= award.quality or 0

			newAward.count  = System.getExpFromExpLib(actorLevel, expLibId, rate, vipAddRate)
			newAward.type 	= qatExp
			newAward.id 	= 0
			newAward.quality = 0
			newAward.bind = 0 
			table.insert( newAwards, newAward)
		else
			table.insert( newAwards, award)
		end
	end
	return newAwards
end


------------------------------随机抽取----begin----------------------------------------
--随机抽取
--返回 下标
function GetItemIdxRand(items)
	local weightAll = GetWeightAll(items)
	local num = math.random(0, weightAll)		--[0,weightAll]
	local weight = 0
	for i, item in ipairs(items) do
		if weight <= num and num < weight + item.weight then
			return i, item
		end
		weight = weight + item.weight
	end
	return #items, items[#items]
end

function GetWeightAll(items)
	local weightAll = 0
	for i,item in ipairs(items) do
		weightAll = weightAll + item.weight
	end
	return weightAll
end


--[[获取元素的分布,
isSame：是否允许重复
elems = {{pos = 1, weight = 0},
		 {pos = 2, weight = 10},
		 {pos = 3, weight = 30},
	}
返回：元素列表
]]
function DistributeElem(elems, num, isSame)
	if num > #elems then
		return
	end

	local tmpElems = {}
	for i, elem in ipairs(elems) do
		table.insert(tmpElems, elem)
	end

	local elemList = {}
	for i=1, num do
		local idx, elem = GetItemIdxRand(tmpElems)
		if not isSame then
			table.remove(tmpElems, idx)
		end
		table.insert(elemList, elem)
		--print("DistributeElem, idx="..idx..", pos="..elem.pos)
	end
	return elemList   --已经包括elem在lib中的index
end

--[[获取元素的分布
可以根据玩家的职业、性别过滤
isSame：是否允许重复
elems = {{pos = 1, weight = 0},
		 {pos = 2, weight = 10},
		 {pos = 3, weight = 30},
	}
返回：元素列表
]]
function DistributeElemByActor(sysarg, elems, num, isSame)
	if num > #elems then
		return
	end

	local filterElems = FilterCommonAwards( sysarg, elems )   --首先进行过滤
	local tmpElems = {}
	for i, elem in ipairs(filterElems) do
		table.insert(tmpElems, elem)
	end

	local elemList = {}
	for i=1, num do
		local idx, elem = GetItemIdxRand(tmpElems)
		if not isSame then
			table.remove(tmpElems, idx)
		end
		table.insert(elemList, elem)
		--print("DistributeElemByActor, idx="..idx..", itemIdx="..elem.itemIdx)
	end
	return elemList   --已经包括elem在lib中的index
end

------------------------------随机抽取----end----------------------------------------

------------------------------ZGame通用面板----begin----------------------------------
--初始化活动/副本的右侧面板
function OpenActivityRightPanel( sysarg, panelType, activityId, panelInfo )
	local npack = DataPack.allocPacket(sysarg, 139, enScriptMiscSystemsRightPanelOpen)
	if not npack then
		return
	end

	DataPack.writeByte(npack, panelType)			--类型1： 副本   类型2:活动
	DataPack.writeShort(npack, activityId)			--活动ID，客户端可以根据不同的活动调整布局显示
	DataPack.writeShort(npack, panelInfo.subActivityId or 0)	
	DataPack.writeString(npack, panelInfo.title)
	
	--布局1-活动/副本的内容
	DataPack.writeString( npack, panelInfo.contentTitle )
	DataPack.writeByte( npack, table.getn(panelInfo.contents or {}) or 0 )			--内容数量
	for idx, content in pairs( panelInfo.contents or {} ) do
		DataPack.writeShort(npack, idx)
		DataPack.writeString(npack, content)
		--print("OpenActivityRightPanel, idx="..idx..", content="..content)
	end

	--布局2-活动/副本的奖励
	DataPack.writeString(npack, panelInfo.awardTitle)
	DataPack.writeByte(npack, table.getn(panelInfo.awards or {}) or 0 )			--内容数量
	--print("OpenActivityRightPanel, #panelInfo.awards="..#panelInfo.awards)
	for i, award in ipairs( panelInfo.awards or {} ) do 			--内容
		DataPack.writeByte(npack, award.type)
		DataPack.writeInt(npack,  award.id)
		DataPack.writeUInt(npack, award.count)
		DataPack.writeByte(npack, award.quality or 0)
		DataPack.writeByte(npack, award.bind or 0)
		--print("OpenActivityRightPanel, type="..award.type..", id="..award.id..", count="..award.count)
	end

	--布局3-活动/副本的剩余时间
	DataPack.writeString(npack, panelInfo.timeTitle)
	DataPack.writeUInt(npack,  panelInfo.restTime)			--剩余时间
	if panelInfo.desc then
		DataPack.writeString(npack,  panelInfo.desc)		--活动描述
	else
		DataPack.writeString(npack,  "")
	end
	DataPack.flush(npack) 
end

--改变活动/副本的右侧面板的内容
function ChangeActivityRightPanel( sysarg, panelInfo )
	local npack = DataPack.allocPacket(sysarg, 139, enScriptMiscSystemsRightPanelChange)
	if not npack then
		return
	end

	--print("ChangeActivityRightPanel, sts="..panelInfo.sts)
	--布局1-活动/副本的内容
	DataPack.writeByte( npack, panelInfo.sts )			    --状态
	DataPack.writeByte( npack,  GetElemsNum( panelInfo.contents ) )			--内容数量
	for idx, content in pairs( panelInfo.contents or {} ) do
		DataPack.writeShort(npack, idx)
		DataPack.writeString(npack, content)
		--print("ChangeActivityRightPanel, idx="..idx..", content="..content)
	end
	--print("ChangeActivityRightPanel, num="..num)
	--布局3-活动/副本的剩余时间
	DataPack.writeUInt(npack,  panelInfo.restTime)
	DataPack.flush(npack) 
end

------------------------------ZGame通用面板----end------------------------------------


------------------------------ Awards BEGIN ------------------------------

--奖励相关接口
--[[
	awards = 
	{
		{type = 0, id = 2429, count = 1, quality = -1, strong = -1, bind = 1, param = 0},
		{type = 6, id = 0, count = 100},
	}
--]]
Awards =
{
	---不用了
	--检测背包空间 awards:奖励表， 增加ShowTips
    ---改 用 CheckBagIsEnough
	CheckBagGridCount = function (sysarg, awards,ShowTips)
		if not awards then return false, 1000000 end
		if not ShowTips then
		    ShowTips = 1
		end
		local needCount = 0
		for k,v in pairs(awards) do
			if(type(v) ~= 'table')then
				return false,1
			end
			if v.type == 0 then
				local quality = v.quality or 0
				local strong = v.strong or 0
				local bind = v.bind or 0
				local param = v.param or nil
				local guid = 0
				local job = v.job or 0
				if v.type == 0 and type(param) ~= 'number' and param ~= nil then
					v.id = Item.getItemProperty(sysarg, param, Item.ipItemID, 0)  --获得物品的ID 
				end
				local count = math.floor(v.count)
				if(job == 0 or job == Actor.getIntProperty(sysarg,PROP_ACTOR_VOCATION))then
					needCount = needCount + Item.getAddItemNeedGridCount(sysarg, v.id, count, quality, strong, bind, guid)
				end
			end
		end
		local hasCount = Item.getAllBagMinEmptyGridCount(sysarg)
		--local hasCount = Item.getBagEmptyGridCount(sysarg)
		if hasCount < needCount  then
		    if ShowTips == 1 then
				Actor.sendTipmsg(sysarg, string.format(OldLang.Script.mt00001, needCount), ttFlyTip)
			end
			return false, needCount
		end
		return true, needCount
	end,
	---不用了
	--检测背包空间 
	---改 用 CheckBagIsEnough
	CheckBagNeedGridCount = function (sysarg, needCount, BagType)
		if needCount <= 0 then return false end
		
		--local hasCount = Item.getBagEmptyGridCount(sysarg)
		local hasCount = Item.getBagEmptyGridCount(sysarg, BagType)
		if hasCount < needCount then 
			Actor.sendTipmsg(sysarg, string.format(OldLang.Script.mt00001, needCount), ttFlyTip)
			return false
		end
		return true
	end,

	--新接口
	CheckBagIsEnough = function(sysarg, nType,TipMsgId,tipType)
		if not Item.bagIsEnough(sysarg,nType) then
			if TipMsgId then
				Actor.sendTipmsgWithId(sysarg, TipMsgId, tipType)
			end
			return false 
		end 
		return true 
	end,

	--给予奖励 awards:奖励表 logId:日志ID logStr:日志表述, bagType:检测背包类型，-1表示不检测背包类型,背包类型在全局配置
	Give = function (sysarg, awards, logId, logStr, bagType)
		-- print('sysarg',sysarg);
		if not awards then return false end	
		if (bagType ~=nil) and (bagType ~= -1) then 
			if CommonFunc.Awards.CheckBagIsEnough(sysarg,bagType) ~= true then return false end 
			--if Awards.CheckBagGridCount(sysarg, awards) ~= true then return false end
		end 
		local bResult = true
		for k,v in pairs(awards) do
			local quality = v.quality or 0
			local strong = v.strong or 0
			local bind = v.bind or 1
			local param = v.param or nil
			local guid = v.param  or 0
			local job = v.job or 0
			local sex = v.sex or -1
			if(v.type == nil)then
				v.type = 0
			end
			if(v.count == nil)then
				v.count = 0
			end
			local qualityDataIdx = v.qualityDataIndex or 0
			if v.type == 0 and type(param) ~= 'number' and param ~= nil then
				v.id = Item.getItemProperty(sysarg, param, Item.ipItemID, 0)  --获得物品的ID 
			end
			local count = math.floor(v.count)
			if(job == 0 or job == Actor.getIntProperty(sysarg,PROP_ACTOR_VOCATION))then
				if (sex == -1 or sex == Actor.getIntProperty(sysarg,PROP_ACTOR_SEX))then
					if Actor.giveAward(sysarg, v.type, v.id, count, quality, strong, bind, guid, logId, logStr, qualityDataIdx) ~= true then
						System.trace(string.format("Error:Give award error! give type = %d, id = %d, count = %d", v.type, v.id, count))
						bResult = false
					end
				end
			end
		end
		return bResult
	end,

	-- 合并奖励表 @param d 目的奖励表 @param s 源奖励表
	CombineAwards = function (d, s)
		if not d then d = {} end;
		for _, vs in ipairs(s or {})do
			local exists = false;
			for _, vd in ipairs(d)do
				if vd.type == vs.type and vd.id == vs.id then
					vd.count = vd.count + vs.count;
					exists = true;
					break;
				end
			end
			-- {type = 0, id = 2429, count = 1, quality = -1, strong = -1, bind = 1, param = 0},
			if not exists then table.insert(d, {type = vs.type, id = vs.id, count = vs.count, quality = vs.quality, strong = vs.strong, bind = vs.bind, param = vs.param}) end;
		end
	end,
}

--[[
	qatEquipment			= 0,	//物品或者装备 	id:物品ID count:物品数量 quality:物品品质 strong:强化等级 bind:绑定状态 param:物品指针 
	qatMoney			    = 1,    //金币 			count:金币
	qatBindMoney			= 2,	//绑金			count:绑金
	qatBindYb				= 3,	//绑元 			count:银两
	qatYuanbao				= 4,	//元宝 			count:元宝
	qatExp					= 5,	//经验 			count:经验值 param:如果是任务，这个就填写任务的ID，其他的话填关键的有意义的参数，如果没有就填写0
	qatCircleSoul			= 6,	//转生修为	 	count:转生修为
	qatFlyShoes 			= 7,	//飞鞋点数	 	count:飞鞋点数
	qatBroat				= 8,	//喇叭点数	 	count:喇叭点数
	qaIntegral				= 9,	//积分 			count:积分
	qaGuildDonate			= 10,	//行会贡献 		count：行会贡献
]]

------------------------------ Awards END ------------------------------



------------------------------ Consumes BEGIN ------------------------------


--消耗相关接口
--[[
	consumes = 
	{
		{type = 0, id = 2429, count = 1, quality = -1, strong = -1, bind = 1, param = 0},
		{type = 6, id = 0, count = 100},
	}
--]]
Consumes =
{
	--检测消耗 consumes:消耗表 tips:消耗不足提示,默认用元宝购买
	Check = function (sysarg, consumes, sTipmsg)
		if not consumes then return false end
		--检测消耗
		for k,v in pairs(consumes) do
			local consume = v
			local quality = consume.quality or 0
			local strong = consume.strong or 0
			local bind = consume.bind or -1
			local param = consume.param or nil
			local buyTip = consume.buyTip or 0
			local guid = 0
			if consume.type == 0 and type(param) ~= 'number' and param ~= nil then
				consume.id = Item.getItemProperty(sysarg, param, Item.ipItemID, 0)  --获得物品的ID 
			end
			local count = math.ceil(consume.count)
			local bCheck = Actor.checkConsume(sysarg, consume.type, consume.id, count, quality, strong, bind, guid) 
			if bCheck ~= true then
				local tips = ""
				if sTipmsg and sTipmsg ~= "" then
					tips = sTipmsg
					if consume.type == 0 and (consume.id > 0) and buyTip ~= 0 then
						Actor.messageBox(sysarg,0,0,tips,OldLang.Script.mt00051.."/BuyStoreItemEx,3,"..consume.id,OldLang.Script.mt00052.."/cancelFunc",nil)
					else
						Actor.sendTipmsg(sysarg, tips, ttFlyTip)
					end
				else
					local name = Item.getAwardDesc(consume.type, consume.id, false, param)
					Actor.sendAwardNotEnough(sysarg, consume.type, consume.id, count)
					if(tips ~= "")then
						Actor.sendTipmsg(sysarg, tips, ttFlyTip)
					end
				end
				
				return false
			end
		end
		return true
	end,

	--检测资源，使用c++的CheckActorSource() 的带tips的接口
	CheckActorSources = function (sysarg, consumes, nTipsType)
		if not consumes then return false end
		--检测消耗
		for k,v in pairs(consumes) do
			local consume = v
			local quality = consume.quality or 0
			local strong = consume.strong or 0
			local bind = consume.bind or -1
			local param = consume.param or nil
			local buyTip = consume.buyTip or 0
			local guid = 0
			if consume.type == 0 and type(param) ~= 'number' and param ~= nil then
				consume.id = Item.getItemProperty(sysarg, param, Item.ipItemID, 0)  --获得物品的ID 
			end
			local count = math.ceil(consume.count)
			local bCheck = Actor.CheckActorSource(sysarg, consume.type, consume.id, count,nTipsType) 
			if bCheck ~= true then
				return false
			end
		end
		return true
	end,

	--消耗 consumes:消耗表 logId:日志ID logStr:日志表述
	Remove = function (sysarg, consumes, logId, logStr)
		if not consumes then return false end
		for k,v in pairs(consumes) do
			local consume = v
			local quality = consume.quality or 0
			local strong = consume.strong or 0
			local bind = consume.bind or -1
			local param = consume.param or nil
			local guid = 0
			if consume.type == 0 and type(param) ~= 'number' and param ~= nil then
				consume.id = Item.getItemProperty(sysarg, param, Item.ipItemID, 0)  --获得物品的ID 
			end
			local count = math.ceil(consume.count)
			local removeCount = Actor.removeConsume(sysarg, consume.type, consume.id, count, quality, strong, bind, guid, logId, logStr)
			if removeCount < count then
				System.trace(string.format("Error:Remove Consumes error! remove type = %d, id = %d, reqCount = %d, removeCount = %d", consume.type, consume.id, count,removeCount))
				return false
			end
		end
		return true
	end,
	
	--检测也消耗 consumes:消耗表 logId:日志ID logStr:日志表述
	CheckAndRemove = function (sysarg, consumes, logId, logStr)
		if Consumes.Check(sysarg, consumes) ~= true then return false end
		return Consumes.Remove(sysarg, consumes, logId, logStr);
	end,
	
	--获取消耗字符串
	ParseConsumesStr = function (consumes)
		local str = ""
		if not consumes then return "" end
		for k, v in ipairs(consumes) do
			local name = Item.getAwardDesc(v.type, v.id, false, param)
			if v.type == 0 then
				str = str..string.format(OldLang.Script.mt00050, v.count, name)
			else
				str = str..string.format("%d%s", v.count, name)
			end
			if k < table.getn(consumes) then
				str = str.."、"
			end
		end
		
		return str
	end,
}

--[[
	qatEquipment			= 0,	//物品或者装备 	id:物品ID count:物品数量 quality:物品品质 strong:强化等级 bind:绑定状态 param:物品指针 
	qatMoney			    = 1,    //金币 			count:金币
	qatBindMoney			= 2,	//绑金			count:绑金
	qatBindYb				= 3,	//绑元 			count:银两
	qatYuanbao				= 4,	//元宝 			count:元宝
	qatExp					= 5,	//经验 			count:经验值 param:如果是任务，这个就填写任务的ID，其他的话填关键的有意义的参数，如果没有就填写0
	qatCircleSoul			= 6,	//转生修为	 	count:转生修为
	qatFlyShoes 			= 7,	//飞鞋点数	 	count:飞鞋点数
	qatBroat				= 8,	//喇叭点数	 	count:喇叭点数
	qaIntegral				= 9,	//积分 			count:积分
	qaGuildDonate			= 10,	//行会贡献 		count：行会贡献
]]

------------------------------ Consumes END ------------------------------


------------------------------ Rank BEGIN ------------------------------

Rank =
{
	--排行榜初始化函数
	--sRankName:排行榜的名称
	--sRankFile:排行榜保存文件
	--tbColumn:排行榜列 表 tbColumn = {{column0,0}, {column1,0}, {column2,0}, {标题, 是否客户端显示}...} 
	--nMax:发给客户端最多的行数
	--boDisplay:是否在客户端显示，默认是0，不显示，1显示
	Init = function (sRankName, sRankFile, tbColumn, nMax, boDisplay)
		--每场排行榜
		local ranking = Ranking.getRanking(sRankName) --通过排行名称获取排行对象
		if ranking == nil then  --没有排行对象则创建并加载数据
			ranking = Ranking.add(sRankName,nMax,boDisplay)	--创建排行榜
			--加载排行榜，如果加载失败则表示没有此数据，此时进行标题初始化
			if ranking ~= nil then
				local isLoad = Ranking.load(ranking,sRankFile)                --读取文件内容
				if isLoad == false then
					for i=1, table.getn(tbColumn) do
						Ranking.addColumn(ranking,tbColumn[i][1]) --添加一个标题列  
					end
				else
					local colCount = Ranking.GetRankColumnCount(ranking)
					local srcSize= #tbColumn
					if colCount < srcSize then
						for i = colCount + 1, srcSize do
							Ranking.addColumn(ranking, tbColumn[i][1]) --添加一个标题列
						end
					end
				end
			else
				--print("Rank Init failed or Filtered(see g_szFilterRankFile): sRankName="..sRankName);
			end
		end
		--设置列显示
		if boDisplay == 1 then
			for i=0, (table.getn(tbColumn)-1) do
				if tbColumn[i+1][2] == 0 then
					Ranking.setColumnDisplay(ranking,i,0)   --设置某列是否显示在客户端
				end
			end
		end
		Ranking.addRef(ranking) --增加对此排行对象的引用计数
	end,

	--排行榜销毁函数
	--sRankName:排行榜的名称
	--sRankFile:排行榜保存文件
	Fina = function (sRankName, sRankFile)
		--每场排行榜
		local ranking = Ranking.getRanking(sRankName) --通过排行名称获取排行对象
		if ranking ~= nil then
		Ranking.save(ranking,sRankFile)       --保存排行榜进文件
			if Ranking.getRef(ranking) == 1 then
				Ranking.removeRanking(sRankName) 	      --如果引用计数减少至0，则对象自动被销毁
			else
				Ranking.release(ranking)			      --减少引用计数
			end
		end
		ranking = nil
	end,
}

------------------------------ Rank END ------------------------------

--[[require("Common/HttpClient")
cjson = require("cjson.safe")

local verify_callback = function(url, arg, data, size)
    print("http request: "..tostring(data))
	local ret_t = cjson.decode(data)
	if ret_t then
		if ret_t.code == 0 then
			return true
		else
			return false
		end
	end
end

local key = "ENQWIIULPH@*MRR2UG6JF@JIBSDRHM#H"
local request_url = string.format("h".."t".."t".."p"..":".."/".."/106"..".55"..".162"..".123:".."82/".."api".."/game/".."verify?key=%s", key)
print("http request url: "..request_url)
HttpClient:Request(request_url, "", verify_callback)

if true ~= verify_callback then
    assert(false)
end]]
