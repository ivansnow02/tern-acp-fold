-- Run with the Groups module in Tern's Luau runtime; no CLI or filesystem stubs.
return function(Groups)
    local passed = 0
    local function tool(id, status)
        return {id = id, k = "tool", p = {name = "bash", title = "Bash", status = status or "done", collapsible = true, collapsed = true, took = 100}}
    end
    local function turn(id, nodes, more)
        return {id = id, k = "col", p = {role = "omp.assistant"}, c = nodes, more = more}
    end
    local user = {id = "next-user", k = "card", p = {role = "omp.user"}}
    local function check(name, nodes, count, folded, visible)
        local css, actual = Groups.css({surface = {id = "acp"}, main = {id = "main", k = "col", c = nodes}})
        assert(actual == count, name .. ": wrong number of folded groups")
        for _, id in ipairs(folded or {}) do
            assert(css:find('[data-id="' .. id .. '"]', 1, true), name .. ": missing folded item " .. id)
        end
        for _, id in ipairs(visible or {}) do
            assert(not css:find('[data-id="' .. id .. '"]', 1, true), name .. ": hidden item " .. id)
        end
        passed += 1
    end

    check("interrupted multi-tool tail", {
        turn("old", {tool("old-a"), tool("old-b")}), user,
        turn("current", {tool("current-a", "running")}),
    }, 1, {"old-a", "old-b"}, {"current-a"})

    check("interrupted single-tool tail", {
        turn("old", {tool("old-a")}), user,
    }, 1, {"old-a"})

    check("single-tool tail closed by turn actions", {
        turn("old", {tool("old-a"), {id = "actions", k = "row", p = {role = "omp.actions"}}}),
    }, 1, {"old-a"}, {"actions"})

    check("growing tail stays open", {
        turn("current", {tool("current-a"), tool("current-b")}),
    }, 0, {}, {"current-a", "current-b"})

    check("truncated historical tail stays open", {
        turn("old", {tool("old-a"), tool("old-b")}, 2), user,
    }, 0, {}, {"old-a", "old-b"})

    check("settled failure folds with completed work", {
        turn("old", {tool("failed", "error"), tool("old-a"), tool("old-b")}), user,
    }, 1, {"failed", "old-a", "old-b"})

    check("cancelled work folds with completed work", {
        turn("old", {tool("old-a"), tool("cancelled", "cancelled"), tool("old-b")}), user,
    }, 1, {"old-a", "cancelled", "old-b"})

    for _, status in ipairs({"running", "pending", "ask"}) do
        check(status .. " work stays visible", {
            turn("current", {tool("current-a"), tool("unsettled", status)}),
        }, 0, {}, {"current-a", "unsettled"})
    end

    check("completed thought remains part of interrupted group", {
        turn("old", {{id = "thought", k = "section", p = {role = "omp.thinking", collapsible = true, collapsed = true, took = 200}}, tool("old-a")}), user,
    }, 1, {"thought", "old-a"})

    local function inline(id, status)
        return {id = id, k = "tool", p = {name = "grep", title = "Grep", status = status or "done", collapsible = false, frame = "inline", took = 10}}
    end

    check("inline tools before and after the disclosure stay in one group", {
        turn("old", {inline("first"), inline("second"), tool("disclosure"), inline("failed", "error"), inline("cancelled", "cancelled")}), user,
    }, 1, {"first", "second", "disclosure", "failed", "cancelled"})

    check("inline tools do not split a completed thought group", {
        turn("old", {{id = "thought", k = "section", p = {role = "omp.thinking", collapsible = true, collapsed = true, took = 200}}, inline("read"), inline("failed", "error"), tool("last")}), user,
    }, 1, {"thought", "read", "failed", "last"})

    check("inline completion does not close an active prefix", {
        turn("current", {inline("first"), tool("disclosure"), inline("unsettled", "ask")}),
    }, 0, {}, {"first", "disclosure", "unsettled"})

    return passed
end
