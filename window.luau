local Groups = require("./groups")
local enabled = tern.kv.get("enabled") ~= false
local sheets = {}
local timer = nil

local function sheet(pane)
	return "pane-" .. string.format("%.0f", pane)
end

local function refresh(cx, pane)
	local header = cx.session:surface(pane, { depth = 0, nodes = 1 })
	if not header or header.surface.id ~= "acp" then return false end
	local surface = cx.session:surface(pane, { depth = 2, nodes = 5000 })
	local css = Groups.css(surface)
	if sheets[pane] ~= css then
		sheets[pane] = css
		tern.css(sheet(pane), css)
	end
	return true
end

local function tick(cx, force)
	timer = nil
	if not enabled then return end
	local busy = false
	for _, pane in ipairs(cx.session:panes()) do
		if pane.kind == "agent" and (force or pane.busy or sheets[pane.pane] == nil) then
			local acp = refresh(cx, pane.pane)
			if acp and pane.busy then busy = true end
		end
	end
	if busy then
		timer = tern.timer(1000, tick)
	end
end

local function update(cx)
	if timer then timer:cancel(); timer = nil end
	tick(cx, true)
end

tern.command({
	id = "toggle",
	title = "ACP: Toggle tool groups / 切换工具分组",
	group = "ACP Tool Groups",
	icon = "terminal",
	run = function(cx)
		enabled = not enabled
		tern.kv.set("enabled", enabled)
		for pane, css in pairs(sheets) do
			tern.css(sheet(pane), if enabled then css else "")
		end
		update(cx)
		cx:toast("info", if enabled then "ACP tool groups enabled / 已开启" else "ACP tool groups disabled / 已关闭")
	end,
})

tern.on("focus", function(_, cx) update(cx) end)
tern.on("agent_state", function(_, cx) update(cx) end)
tern.on("agent_finished", function(_, cx) update(cx) end)
tern.on("pane_closed", function(ev)
	if sheets[ev.pane] then
		tern.css(sheet(ev.pane), "")
		sheets[ev.pane] = nil
	end
end)
tern.timer(0, update)
