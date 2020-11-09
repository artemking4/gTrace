// gTrace by Artemking4
// A library to trace lua code

local GT = { }

function GT:ValueToString(v)
	local t = type(v)
	if t == "string" then return '"'..v..'"' end

	return tostring(v)
end

function GT.Hook(event, ...)
	//if event ~= "call" then return end
	if not GT.Trace then return end

	local info = debug.getinfo(2)
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

  local str = s

	str = str .. "("
	for k,v in pairs(args) do
		str = str .. v .. ((k == #args) and "" or ", ")
	end
	str = str .. ")"

	str = str .. " // " .. caller.short_src .. ":" .. caller.currentline

	print(str)
end

local function PrintInfo(infostr)
	infostr = tostring(infostr or "")
	print(string.rep("=", 120 - string.len(infostr) - 4) .. " " .. infostr .. " ==" )
end

function GT:Start()
	PrintInfo("Tracing started")
	self.Trace = true
	self.StartTime = SysTime()
	debug.sethook(self.Hook, "cr")
end

function GT:End()
	debug.sethook()
	self.Trace = true
	PrintInfo("Tracing done, code ran for: ".. (SysTime() - self.StartTime) .. "s")
end

return GT
