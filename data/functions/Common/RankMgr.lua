module("RankMgr", package.seeall)

--#include "RankDef.txt" once
--脚本的排行榜统一用ID,因为通过ID可以去拿到默认值

-----------------------------------------------只有一个nPoint的排行榜----------------------------------------------------
--初始化排行榜
function Init(nRankId, numMax)
	if(type(nRankId) ~= 'number' or type(numMax) ~= 'number')then
		return print(actorId, nRankId)
	end
	local rankName = RankList[nRankId].strName	
	local ranking = Ranking.getRanking( nRankId )
	if(ranking ~= nil)then
		return false
	end
	ranking = Ranking.add( nRankId,rankName, numMax, 1, 10 )
	if(ranking == nil)then
		return false
	end
	if not Ranking.load(ranking, nil) then
		Ranking.addColumn(ranking, "name")
	end
	Ranking.addRef( ranking )
	return true
end

--获取排行榜数据
function GetValue(actorId, nRankId)
	if(type(actorId) ~= 'number' or type(nRankId) ~= 'number')then
		return print(actorId, nRankId)
	end
	local rankName = RankList[nRankId].strName
	local ranking = Ranking.getRanking( nRankId )
	if ranking then
		local item = Ranking.getItemPtrFromId( ranking, actorId)
		if item then	--已经榜上有名
			return Ranking.getPoint(item)
		end
	end
	return 0
end

--设置排行榜数据
function SetRank(actorId, nRankId, newValue )
	if(type(actorId) ~= 'number' or type(nRankId) ~= 'number' or type(newValue) ~= 'number')then
		return print(actorId, nRankId ,addValue)
	end
	local rankName = RankList[nRankId].strName
	local ranking = Ranking.getRanking( nRankId )
	if (ranking == nil) then
		return
	end
	local item = Ranking.getItemPtrFromId( ranking, actorId)
	if item then			--已经榜上有名
		Ranking.setItem(ranking, actorId, newValue)
		return true
	end			
	local pActor = System.getEntityPtrByActorID(actorId)	
	if(pActor == nil)then	-- 如果没记录,玩家又没在线,不处理	
		return false
	end	
	item = Ranking.addItem(ranking, actorId, newValue)
	if item then
		Ranking.setSub(item, 0, Actor.getName(pActor))
	end	
end

--增加排行榜数据
function AddValue(actorId, nRankId, addValue)
	if(type(actorId) ~= 'number' or type(nRankId) ~= 'number' or type(addValue) ~= 'number')then
		return print(actorId, nRankId ,addValue)
	end
	local rankName = RankList[nRankId].strName
	local ranking = Ranking.getRanking( nRankId )
	if (ranking == nil) then
		return
	end
	local item = Ranking.getItemPtrFromId( ranking, actorId)
	if item then	--已经榜上有名
		Ranking.updateItem(ranking, actorId, addValue)
		return true
	end			--新加的
	local pActor = System.getEntityPtrByActorID(actorId)	
	if(pActor == nil)then	-- 如果没记录,玩家又没在线,不处理	
		return false
	end		
	item = Ranking.addItem(ranking, actorId, addValue)
	if item then
		Ranking.setSub(item, 0, Actor.getName(pActor))
	end
	return true
end




--增加排行榜数据
function AddGuildRankValue(actorId, nRankId, addValue)
	if(type(actorId) ~= 'number' or type(nRankId) ~= 'number' or type(addValue) ~= 'number')then
		return print(actorId, nRankId ,addValue)
	end
	local rankName = RankList[nRankId].strName
	local ranking = Ranking.getRanking( nRankId )
	if (ranking == nil) then
		return
	end
	local item = Ranking.getItemPtrFromId( ranking, actorId)
	if item then	--已经榜上有名
		Ranking.updateItem(ranking, actorId, addValue)
		return true
	end			--新加的
	local name = System.getGuildName(actorId)	
	if(name == nil)then	-- 如果没记录,玩家又没在线,不处理	
		return false
	end		
	item = Ranking.addItem(ranking, actorId, addValue)
	if item then
		Ranking.setSub(item, 0, name)
	end
	return true
end

--发送排行榜前num名
function SendToClient(pActor, nRankId, num, rankLimit, systemId, msgId)
	if(type(nRankId) ~= 'number' or type(num) ~= 'number' or type(systemId) ~= 'number' or type(msgId) ~= 'number')then
		return print(actorId, nRankId)
	end
	local rankName = RankList[nRankId].strName
	local ranking = Ranking.getRanking( nRankId )
	if (ranking == nil) then
		return
	end
	local itemNum = Ranking.getRankItemCount(ranking)
	if num < Ranking.getRankItemCount(ranking) then
		itemNum = num
	end
	local pack = DataPack.allocPacket(pActor, systemId, msgId)
	if (pack == nil) then
		return
	end
	DataPack.writeByte(pack, itemNum)
	for idx=1,itemNum do
		local rankItem = Ranking.getItemFromIndex(ranking, idx-1)
		if rankItem then
			local playerId  = Ranking.getId(rankItem)
			local value 	= Ranking.getPoint(rankItem)
			local name 	 	= Ranking.getSub(rankItem, 0)
			DataPack.writeUInt(pack, playerId)
			DataPack.writeUInt(pack, value)
			DataPack.writeString(pack, name)
		end
	end
	--我的数据
	local myId = Actor.getActorId(pActor)
	local myStar 	= 0
	local myIdx 	= 0
	local item = Ranking.getItemPtrFromId( ranking, myId)
	if item then
		myStar = Ranking.getPoint(item) or 0
		if myStar < rankLimit then			--未上榜
			myIdx = 0
		else
			myIdx = Ranking.getIndexFromPtr(item) + 1
		end
	end	
	DataPack.writeUInt(pack, myStar)
	DataPack.writeWord(pack, myIdx)
	DataPack.flush(pack)
end

--将排行榜前num名放入数据包（不包括自己的排名）
function PushToPack(nRankId, num, pack)
	if(type(nRankId) ~= 'number' or type(num) ~= 'number')then
		return print(actorId, nRankId)
	end
	local rankName = RankList[nRankId].strName
	local ranking = Ranking.getRanking( nRankId )
	if (ranking == nil) then
		return
	end
	local itemNum = Ranking.getRankItemCount(ranking)
	if num < itemNum then
		itemNum = num
	end
	if (pack == nil) then
		return
	end
	DataPack.writeByte(pack, itemNum)
	for idx=1,itemNum do
		local rankItem = Ranking.getItemFromIndex(ranking, idx-1)
		if rankItem then
			local playerId  = Ranking.getId(rankItem)
			local value 	= Ranking.getPoint(rankItem)
			local name 	 	= Ranking.getSub(rankItem, 0)
			DataPack.writeUInt(pack, playerId)
			DataPack.writeUInt(pack, value)
			DataPack.writeString(pack, name)
			local pActor = Actor.getActorById(playerId);
			local handle = Actor.getHandle(pActor);
			DataPack.writeUint64(pack, handle)
		end
	end
end

--获取我的排名
function GetMyRank(pActor, nRankId)
	local rankName = RankList[nRankId].strName
	local ranking = Ranking.getRanking( nRankId )
	if (ranking == nil) then
		return 0
	end
    local myId = Actor.getActorId(pActor)
	local item = Ranking.getItemPtrFromId( ranking, myId)
	if item then
	     return Ranking.getIndexFromPtr(item) + 1
	else
	     return 0 
	end
end

--获取我的排名
function GetMyGuildRank(id, nRankId)
	local rankName = RankList[nRankId].strName
	local ranking = Ranking.getRanking( nRankId )
	if (ranking == nil) then
		return 0
	end
	local item = Ranking.getItemPtrFromId( ranking, id)
	if item then
	     return Ranking.getIndexFromPtr(item) + 1
	else
	     return 0 
	end
end

-----------------------------------------------多个value的排行榜----------------------------------------------------

--排行榜初始化函数
--RankName:排行榜的名称
--sRankFile:排行榜保存文件
--tbColumn:排行榜列 表 tbColumn = {"column0","column1","column2",}, {标题, 是否客户端显示}...} 
--nMax:发给客户端最多的行数
function InitEx(nRankId, tbColumn, nMax)
	if(type(nRankId) ~= 'number' or type(nMax) ~= 'number')then
		return print(nRankId, nMax)
	end
	rankName = RankList[nRankId].strName
	local sRankFile = rankName								--默认排行榜的名字就是文件的名字
	local ranking = Ranking.getRanking(nRankId) 			--通过排行名称获取排行对象
	if ranking ~= nil then  					  			--有排行对象则创建失败
		return false
	end
	ranking = Ranking.add(nRankId,rankName,nMax, 1, 10 )					--创建排行榜
	if ranking == nil then
		return false
	end
	local isLoad = Ranking.load(ranking,sRankFile)          --读取文件内容
	if isLoad == false then									--加载排行榜失败,进行标题初始化
		for i=1, table.getn(tbColumn) do
			Ranking.addColumn(ranking,tbColumn[i])			--添加列名字  
		end
	else
		local colCount = Ranking.GetRankColumnCount(ranking)--如果排行榜的文件已经存在	
		local srcSize= #tbColumn
		if colCount < srcSize then
			for i = colCount + 1, srcSize do
				Ranking.addColumn(ranking, tbColumn[i]) 	--添加列名字 
			end
		end
	end
	Ranking.addRef(ranking) 								--增加对此排行对象的引用计数
end

--设置排行榜的数据
--colIdx：从1开始，0是name
--在涉及到领取道具的时候，为了避免出现异常，必须判断一下返回值
function SetRankEx(actorId, nRankId, colIdx, newColValue)
	if(type(actorId) ~= 'number' or type(nRankId) ~= 'number')then
		return print(actorId, nRankId)
	end
	local rankName = RankList[nRankId].strName
	local ranking = Ranking.getRanking( nRankId )
	if (ranking == nil) then
		return false
	end
	local item = Ranking.getItemPtrFromId( ranking, actorId )
	if item then	--已经榜上有名
		Ranking.setSub(item, colIdx, newColValue)   				   --这里不一定能设置成功
		if Ranking.getSub(item, colIdx) ~= tostring(newColValue) then  --列没有设置成功
			return false
		end
		return true
	end				--新加的
	local pActor = System.getEntityPtrByActorID(actorId)	
	if(pActor == nil)then	-- 如果没记录,玩家又没在线,不处理	
		return false
	end	
	item = Ranking.addItem(ranking, actorId, newColValue)
	if (item == nil) then
		return false
	end
	Ranking.setSub(item, 0, Actor.getName(pActor))
	Ranking.setSub(item, colIdx, newColValue)
	if Ranking.getSub(item, colIdx) ~= tostring(newColValue) then  --列没有设置成功
		return false
	end		
	return true
end

--增加排行榜数据
function AddValueEx(actorId, nRankId, colIdx, addValue)
	if(type(actorId) ~= 'number' or type(nRankId) ~= 'number' or type(addValue) ~= 'number')then
		return print(actorId, nRankId ,addValue)
	end
	local rankName = RankList[nRankId].strName
	local ranking = Ranking.getRanking( nRankId )
	if (ranking == nil) then
		return
	end
	local item = Ranking.getItemPtrFromId( ranking, actorId)
	if item then	--已经榜上有名
		local newColValue = tonumber(Ranking.getSub(item, colIdx)) or 0
		newColValue = newColValue + addValue		
		Ranking.setSub(item, colIdx, newColValue)  
		return true
	end			--新加的
	local pActor = System.getEntityPtrByActorID(actorId)	
	if(pActor == nil)then	-- 如果没记录,玩家又没在线,不处理	
		return false
	end		
	item = Ranking.addItem(ranking, actorId, addValue)
	if item then
		Ranking.setSub(item, 0, Actor.getName(pActor))
	end
	return true
end

local function _getValueByItem(item, colIdx, nRankId)
	if (item == nil) then	
		return nil
	end
	if(type(colIdx) ~= 'number' or type(nRankId) ~= 'number')then
		return print(colIdx, nRankId)
	end	
	local colValue = Ranking.getSub(item, colIdx)
	local Default = RankList[nRankId].tabColumn[2][colIdx] --默认值
	if(Default == nil)then
		return nil
	end	
	if colValue == "-" then	--返回默认值
		return Default
	end
	if(type(Default) == 'string') then
		return colValue			
	end
	return tonumber(colValue) 	
end

-- 获取第colIdx列的数据
--如果排行榜不存在，必须返回nil，为无效数据，避免异常情况
function GetValueById(actorId, nRankId, colIdx)
	if(type(actorId) ~= 'number' or type(nRankId) ~= 'number')then
		return print(actorId, nRankId)
	end	
	local rankName = RankList[nRankId].strName
	local ranking = Ranking.getRanking( nRankId )
	if (ranking == nil) then
		return nil
	end
	local item = Ranking.getItemPtrFromId( ranking, actorId )
	return _getValueByItem(item,colIdx,nRankId)
end

--按名次获取第colIdx列的数据(名次从0开始)
function GetValueByIndx(rankIndx, nRankId, colIdx)
	if(type(rankIndx) ~= 'number' or type(nRankId) ~= 'number')then
		return print(rankIndx, nRankId)
	end
	local rankName = RankList[nRankId].strName
	local ranking = Ranking.getRanking( nRankId )
	if (ranking == nil) then
		return nil
	end
	local item = Ranking.getItemFromIndex( ranking, rankIndx )
	return _getValueByItem(item,rankIndx,nRankId)
end

-----------------------------------所有排行榜共用接口-----------------------------------
function Clear(nRankId)
	if(type(nRankId) ~= 'number')then
		return print(nRankId)
	end
	local rankName = RankList[nRankId].strName
	local ranking = Ranking.getRanking( nRankId )
	if(ranking == nil)then
		return
	end
	Ranking.clearRanking(ranking)
	Ranking.save(ranking, rankName, true)
end

--排行榜销毁函数
function Remove(nRankId)
	if(type(nRankId) ~= 'number')then
		return print(nRankId)
	end
	local rankName = RankList[nRankId].strName
	local sRankFile = rankName
	Ranking.save(ranking,sRankFile)
	Ranking.removeRanking(nRankId)
end

function Save(nRankId)
	if(type(nRankId) ~= 'number')then
		return print(nRankId)
	end
	local rankName = RankList[nRankId].strName
	local ranking = Ranking.getRanking( nRankId )
	if ranking then
		Ranking.save(ranking, rankName, true)
	end
end

--所有排行榜统一初始化
function AutoInit()
	--print(" Enter AutoInit")
	for RankId,RankInfo in pairs(RankList)do
		local tbColumn = RankInfo.tabColumn[1]
		local nMax = RankInfo.nMaxRecord
		if(0 <#tbColumn)then
			InitEx(RankId, tbColumn, nMax)
		else
			Init(RankId, nMax)
		end
	end
end


--[[
	-- 使用例子
	local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
	local colIdx = 1
	local newColValue = 99
	RankMgr.SetRankEx(actorId, 2001, colIdx, newColValue)
	newColValue = RankMgr.GetValueById(actorId, 2001, colIdx)
	print(newColValue)	
	--2001是排行榜的Id,定义在data\functions\Common\RankDef.txt
]]

