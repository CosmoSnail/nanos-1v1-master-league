local Commands = {}

Commands["/help"] = function(player, args)
    Chat.SendMessage(player, "/goal [red|blue] - score a goal for that team")
    Chat.SendMessage(player, "/fireworks [end] - goal fireworks (end: the end of game ones)")
    Chat.SendMessage(player, "/reload - reload the game-mode")
    Chat.SendMessage(player, "/swap - switch to the other team")
end

Commands["/fireworks"] = function(player, args)
    if args[1] == "end" then
        SpawnFireworksEndGame()
    else
        SpawnFireworksGoal()
    end
end

Commands["/reload"] = function(player, args)
    Server.ReloadPackage(Package.GetName())
end

Commands["/swap"] = function(player, args)
    local character = player:GetControlledCharacter()
    if not character then return end

    local team = Ternary(character:GetTeam() == Team.TeamA, Team.TeamB, Team.TeamA)
    character:SetTeam(team)

    -- a new car on the other side, with that team's color, hat and boost
    local vehicle = character:GetVehicle()
    if vehicle then
        vehicle:Destroy()
    end
    SpawnVehicle(character)
    player:SetCameraRotation(Ternary(team == Team.TeamA, Rotator(0, 0, 0), Rotator(0, 180, 0)))

    Chat.SendMessage(player, "You are now on the " .. Ternary(team == Team.TeamA, "blue", "red") .. " team")
end

Commands["/goal"] = function(player, args)
    Game.LastPlayerHitBall = player

    local team = (args[1] or "red"):lower()

    if team == "red" then
        TeleportBall(Config.GoalPointA)
    elseif team == "blue" then
        TeleportBall(Config.GoalPointB)
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