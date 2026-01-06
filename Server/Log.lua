Package.Require("Tables.lua")
Package.Require("Config.lua")

local original_print = print
function print(...)
    local parts = {}
    for i = 1, select('#', ...) do
        local v = select(i, ...)
        parts[#parts + 1] = tostring(v)
    end
    local msg = "🐌 " .. table.concat(parts, " ")
    if (Config.LogLevel == LogLevel.GameChat) then
        if Chat and Chat.BroadcastMessage then
            Chat.BroadcastMessage(msg)
        end
        original_print(msg)
    elseif (Config.LogLevel == LogLevel.Console) then
        original_print(msg)
    end
end