local GT = { }

function GT:TableToString(tbl)
	local str = "{ "
	for k,v in pairs(tbl) do str = str .. "[" .. self:ValueToString(k) .. "] = " .. self:ValueToString(v) .. ", " end
	return str .. " }"
end

function GT:ValueToString(v)
	local t = type(v)
	if t == "string" then return '"'..v..'"' end
	if t == "table" then
		if v == _G then return "_G" end
		if v == debug.getregistry() then return "debug.getregistry()" end

		for k,tv in pairs(_G) do
			if tv == v then return "_G[".. self:ValueToString(k) .."]" end
		end

		return self:TableToString(v)
	end

	return tostring(v)
end

function GT.Hook(event, line)
	if not GT.Trace then return end

	local info = debug.getinfo(2)

  if jit then
	  info = table.Merge(info, jit.util.funcinfo(info.func))
  end

	local caller = debug.getinfo(3)
	if info.func == GT.End then GT.Trace = false return end
	local s = info.name or "@anonymous"

	local args = { }
	for i = 1, (info.nparams or 0) do
		local k, v = debug.getlocal(2, i)
		table.insert(args, GT:ValueToString(v))
	end

	if info.isvararg then
		local i = -1

		while true do
			local k, v = debug.getlocal(2, i)
			if v == nil then break end
			table.insert(args, GT:ValueToString(v))

			i = i - 1
		end
	end

	if #args == 0 and info.addr then
		local cache = {}
		for i = 1, 128 do
			local k, v = debug.getlocal(2, i)
			if v == nil then
				table.insert(cache, nil)
				if #cache > 5 then break end
			else
				for k,v in pairs(cache) do
					table.insert(args, GT:ValueToString(v))
				end

				table.insert(args, GT:ValueToString(v))
				table.Empty(cache)
			end
		end

		if #args == 0 then
			local i = -1

			while true do
				local k, v = debug.getlocal(2, i)
				if v == nil then break end
				table.insert(args, GT:ValueToString(v))

				i = i - 1
			end
		end
	end

  local str = s

	str = str .. "("
	for k,v in pairs(args) do
		str = str .. v .. ((k == #args) and "" or ", ")
	end
	str = str .. ")"

	str = str .. "\t\t\t// " .. caller.short_src .. ":" .. caller.currentline

	print(str)
end

local function PrintInfo(infostr)
	infostr = tostring(infostr or "")
	print(string.rep("=", 120 - string.len(infostr) - 4) .. " " .. infostr .. " ==" )
end

function GT:GetTime()
  return (SysTime or os.clock or function() return 0 end)()
end

function GT:Start()
	PrintInfo("Tracing started")
	self.Trace = true
	self.StartTime = self:GetTime()
	debug.sethook(self.Hook, "c")
end

function GT:End()
	debug.sethook()
	self.Trace = true
	PrintInfo("Tracing done, code ran for: ".. (self:GetTime() - self.StartTime) .. "s")
end

return GT
