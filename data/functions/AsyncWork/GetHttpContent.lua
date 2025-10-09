
local addr = {}
local GHC_SUCCESS = 0
local GHC_ErrCreateSocket = -1
local GHC_ErrConnet = -2
local GHC_ErrSend = -3
local GHC_ErrRecv = -4

_G.GetHttpContent = function(host, port, url)

	if host == nil or port == nil or url == nil then
		return "", -100
	end

    --print("[GetHttpContent++++++++++++++++++++++++++++++++++++++++111++++++++++++++++:"..tostring(host) )
    --print("[GetHttpContent++++++++++++++++++++++++++++++++++++++++222++++++++++++++++:"..tostring(port) )
    --print("[GetHttpContent++++++++++++++++++++++++++++++++++++++++333++++++++++++++++:"..tostring(url) )
	local socket = LuaSocket:NewSocket()
	if socket == nil then
		print("create socket error!".. host)
		return "", GHC_ErrCreateSocket
	end
	if addr[host] == nil then
		-- GetHostByName在linux中不是线程安全的，所以这里只获取一次便保存下来，下次不需要再调用
		addr[host] = LuaSocket:GetHostByName(host)
	end
	local ret = socket:connect2(addr[host], port, 3)
	if ret ~= 0 then
		LuaSocket:Release(socket, 1)
		print(string.format("connect to host error:%s:%d, ret:%d", host, port, ret))
		return "", GHC_ErrConnet
	end
	socket:setSendTimeout(3)
	socket:setRecvTimeout(3)
	local str = string.format("GET %s HTTP/1.0\r\nHost:%s\r\n\r\n", url, host)
	-- print("GetContent send")
	-- print(str)
	ret = socket:send(str)
	if ret <= 0 then
		LuaSocket:Release(socket, 2)
		print(string.format("send to host error:%s:%d", host, port))
		return "", GHC_ErrSend
	end

    --print("[GetHttpContent++++++++++++++++++++++++++++6564546++++++++++:"..tostring(str) )
	local content = ""
	local len = 0
	content, len = socket:readall(len)
	if len <= 0 then
		LuaSocket:Release(socket, 3)
		print(string.format("recv content error:%s:%d", host, port))
		return "", GHC_ErrRecv
	end
	local _, es = string.find(content, "\r\n\r\n")
	if es ~= nil then
		content = string.sub(content, es + 1)
	end
	-- print("GetContent recv")
	-- print(content)
	LuaSocket:Release(socket, 4)

    --print("[GetHttpContent----------------------------------------------:"..tostring(content) )
	return content, GHC_SUCCESS 
end 

_G.PostHttpContent2 = function(host, port, url)

	if host == nil  or port == nil or url == nil then
		--print("[PostHttpContent2++++++++++++++++++++some nill:")
		return "", -100
	end
	mgs = url;

    --print("[PostHttpContent2-----+++++++++++++++++++++++++------------------2:"..tostring(mgs) )
    --print("[PostHttpContent2++++++++++++++++++++++++++++++++++--------------1:"..tostring(url) )
	local socket = LuaSocket:NewSocket()
	if socket == nil then
		print("create socket error!".. host)
		return "", GHC_ErrCreateSocket
	end
    --print("[PostHttpContent2-----+++++++++++++++++++++++++------------------3:"..tostring(mgs) )
	if addr[host] == nil then
		-- GetHostByName在linux中不是线程安全的，所以这里只获取一次便保存下来，下次不需要再调用
		addr[host] = LuaSocket:GetHostByName(host)
	end
    --print("[PostHttpContent2-----+++++++++++++++++++++++++------------------4:"..tostring(mgs) )
	local ret = socket:connect2(addr[host], port, 3)
    --print("[PostHttpContent2-----+++++++++++++++++++++++++------------------5:"..tostring(mgs) )
	if ret ~= 0 then
		LuaSocket:Release(socket, 1)
		print(string.format("connect to host error:%s:%d, ret:%d", host, port, ret))
		return "", GHC_ErrConnet
	end
    --print("[PostHttpContent2-----+++++++++++++++++++++++++------------------6:"..tostring(mgs) )
	socket:setSendTimeout(3)
	socket:setRecvTimeout(3)
	local str = mgs--string.format("POST %s HTTP/1.0\r\nHost: %s\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: %d\r\n\r\n%s", url, host, string.len(mgs), mgs)
	-- print("GetContent send")
	-- print(str)
    --print("[PostHttpContent2-----+++++++++++++++++++++++++------------------7:"..tostring(str) )
	ret = socket:send(str)
	if ret <= 0 then
		LuaSocket:Release(socket, 2)
		print(string.format("send to host error:%s:%d", host, 80))
		return "", GHC_ErrSend
	end

    --print("[PostHttpContent2-----+++++++++++++++++++++++++------------------8:"..tostring(str) )
	local content = ""
	local len = 0
	content, len = socket:readall(len)
	if len <= 0 then
		LuaSocket:Release(socket, 3)
		print(string.format("recv content error:%s:%d", host, port))
		return "", GHC_ErrRecv
	end
    --print("[PostHttpContent2-----+++++++++++++++++++++++++------------------9:"..tostring(str) )
	local _, es = string.find(content, "\r\n\r\n")
	if es ~= nil then
		content = string.sub(content, es + 1)
	end
    --print("[PostHttpContent2-----+++++++++++++++++++++++++------------------10:"..tostring(mgs) )
	-- print("GetContent recv")
	-- print(content)
	LuaSocket:Release(socket, 4)

    --print("[PostHttpContent2-----+++++++++++++++++++++++++------------------11:"..tostring(str) )
    --print("[GetHttpContent----------------------------------------------:"..tostring(content) )
	return content, GHC_SUCCESS 
end 
 