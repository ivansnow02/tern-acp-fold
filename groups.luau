local Groups = {}

local function quote(value)
	return '"' .. value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\a "):gsub("\r", "") .. '"'
end

local function selector(node)
	return "[data-id=" .. quote(node.id) .. "]"
end

local function titleText(value)
	if type(value) == "string" then return value end
	local parts = {}
	if type(value) == "table" then
		for _, span in ipairs(value) do table.insert(parts, span.t or "") end
	end
	return table.concat(parts)
end

local function isThought(node)
	return node.k == "section" and (node.p or {}).role == "omp.thinking"
end

function Groups.css(surface)
	if not surface or surface.surface.id ~= "acp" or not surface.main then return "", 0 end
	local rules, count = {}, 0
	local children = surface.main.c or {}
	local lastUser = 0
	for index, node in ipairs(children) do
		if (node.p or {}).role == "omp.user" then lastUser = index end
	end
	for index, turn in ipairs(children) do
		if turn.k ~= "col" or (turn.p or {}).role ~= "omp.assistant" then continue end
		local run = {}
		local context = ""
		local turnSelector = ".sf-main > " .. selector(turn)
		local interactionRule = false
		local function flush(sealed)
			if sealed and #run > 0 and (#run > 1 or run[1].k == "tool") and (run[1].p or {}).collapsible == true then
				if not interactionRule then
					-- Tern 0.9.14 otherwise leaves distant + siblings stale after a toggle.
					table.insert(rules, turnSelector .. ":active > .sf { --acp-fold-pressed: 1; }")
					interactionRule = true
				end
				local names, totals, took, thoughts, intent = {}, {}, 0, 0, ""
				local failed, cancelled = 0, 0
				for _, node in ipairs(run) do
					local p = node.p or {}
					if isThought(node) then
						thoughts += 1
					else
						if intent == "" then intent = titleText(p.intent) end
						local name = titleText(p.title)
						if name == "" then name = p.name or "Tool" end
						if not totals[name] then table.insert(names, name); totals[name] = 0 end
						totals[name] += 1
						if p.status == "error" then failed += 1 end
						if p.status == "cancelled" then cancelled += 1 end
					end
					took += p.took or 0
				end
				local labels = {}
				if intent ~= "" then
					table.insert(labels, intent)
				elseif context ~= "" then
					table.insert(labels, context)
				else
					for _, name in ipairs(names) do
						table.insert(labels, name .. (if totals[name] > 1 then " ×" .. totals[name] else ""))
					end
				end
				if thoughts > 0 then
					table.insert(labels, tostring(thoughts) .. (if thoughts == 1 then " thought" else " thoughts"))
				end
				local prefix = if took > 0 then string.format("Worked for %.1fs", took / 1000) else "Worked"
				local label = prefix .. " · " .. table.concat(labels, " · ")
				local statuses = {}
				if failed > 0 then table.insert(statuses, tostring(failed) .. " failed") end
				if cancelled > 0 then table.insert(statuses, tostring(cancelled) .. " cancelled") end
				local status = table.concat(statuses, " · ") .. "  ›"
				local statusColor = if failed > 0 then "var(--bad)" else "var(--sf-c-muted)"
				local anchor = turnSelector .. " > " .. selector(run[1]) .. ".collapsed"
				local head = anchor .. " > .sf-" .. run[1].k .. "-head"
				table.insert(rules, anchor .. " { background: transparent !important; border: 0 !important; box-shadow: none !important; }")
				table.insert(rules, head .. " > * { display: none !important; }")
				table.insert(rules, head .. " { display: flex !important; flex-direction: row !important; align-items: center; width: 100% !important; max-width: 100% !important; min-width: 0; overflow: hidden; }")
				table.insert(rules, head .. "::before { content: " .. quote(label) .. "; color: var(--sf-c-muted); order: 0; flex: 1; min-width: 0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }")
				table.insert(rules, head .. "::after { content: " .. quote(status) .. "; color: " .. statusColor .. "; order: 1; flex-shrink: 0; white-space: nowrap; margin-left: 8px; }")
				table.insert(rules, anchor .. " > .sf-" .. run[1].k .. "-body { display: none !important; }")
				local gap = ""
				for i = 2, #run do
					table.insert(rules, anchor .. gap .. " + " .. selector(run[i]) .. " { display: none !important; }")
					gap ..= " + *"
				end
				count += 1
			end
			run = {}
		end
		for _, node in ipairs(turn.c or {}) do
			local p = node.p or {}
			local thought = isThought(node)
			local complete = (node.k == "tool" and (p.status == "done" or p.status == "error" or p.status == "cancelled")) or (thought and p.took ~= nil)
			if complete and p.collapsible == true then
				table.insert(run, node)
			elseif node.k == "tool" or thought then
				-- Unsettled items stay visible; their active prefix remains open.
				flush(complete)
			else
				flush(true)
				if node.k == "md" then
					context = titleText(p.text):match("[^\r\n]+") or ""
				end
			end
		end
		-- A later user closes historical turns, but an omitted tail is still unknown.
		flush(index < lastUser and (turn.more or 0) == 0)
	end
	return table.concat(rules, "\n"), count
end

return Groups
