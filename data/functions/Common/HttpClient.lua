HttpClient = {}

function HttpClient:Start()
	if nil == self.requester then 
		self.requester = HttpRequester:create()
		self.requester:retain()
		self.requester:setCallback(LUA_CALLBACK(self, self.RequestCallback))
		self.request_list = {}
	end
end

function HttpClient:Update(dt)
end

function HttpClient:Stop()
	if nil ~= self.requester then
		self.requester:release()
		self.requester = nil
		self.request_list = nil
	end
end

-- 请求
function HttpClient:Request(url, arg, callback)
	if nil == self.requester then return end

	local key = self.requester:addRequest(url, arg, 0)
	if key < 0 then
		print("HttpRequest fail url:" .. url)
		return false
	end

	self.request_list[key] = callback
	return true
end

function HttpClient:RequestCallback(url, arg, data, size, key)
	if nil == self.requester then return end

	local callback = self.request_list[key]
	if nil ~= callback then
		callback(url, arg, data, size)
		self.request_list[key] = nil
	end
end

function HttpClient:UrlEncode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str	
end

HttpClient:Start()