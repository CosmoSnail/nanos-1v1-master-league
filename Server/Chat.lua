local Commands = {}

Commands["/reload"] = function(player, args)
    Server.ReloadPackage("nanos-1v1-master-league")
end

Commands["/goal"] = function(player, args)
    Game.LastPlayerHitBall = player

    local team = (args[1] or "red"):lower()

    if team == "red" then
        TeleportBall(Config.GoalPointA)
    elseif team == "blue" then
        TeleportBall(Config.GoalPointB)
    else
        TeleportBall(Config.GoalPointA)
    end
end

Chat.Subscribe("PlayerSubmit", function(message, player)
    -- Split message into command + arguments
    local parts = {}
    for part in message:gmatch("%S+") do
        table.insert(parts, part)
    end

    local command = parts[1]
    table.remove(parts, 1) -- remaining parts are args

    local handler = Commands[command]
    if handler then
        if Config.EnableCommands then
            handler(player, parts)
        end
    end
end)