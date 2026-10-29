local Commands = {}

Commands["/help"] = function(player, args)
    Chat.SendMessage(player, "/goal [red|blue] - score a goal for that team")
    Chat.SendMessage(player, "/fireworks [end] - goal fireworks (end: the end of game ones)")
    Chat.SendMessage(player, "/reload - reload the game-mode")
    Chat.SendMessage(player, "/swap - switch to the other team")
    Chat.SendMessage(player, "/hat [number|name] - change your team's hat (next one if empty)")
    Chat.SendMessage(player, "/end - end the game now (during the end screen: start the next one)")
end

Commands["/hat"] = function(player, args)
    local character = player:GetControlledCharacter()
    if not character then return end

    local team = character:GetTeam()
    local current = Ternary(team == Team.TeamA, Game.HatA, Game.HatB)
    local other = Ternary(team == Team.TeamA, Game.HatB, Game.HatA)

    local hat
    if args[1] then
        local index = tonumber(args[1])
        if index then
            hat = Hats[index]
        else
            local search = args[1]:lower()
            for _, h in ipairs(Hats) do
                if h.name:lower():find(search, 1, true) then
                    hat = h
                    break
                end
            end
        end
        if not hat then
            for i, h in ipairs(Hats) do
                Chat.SendMessage(player, i .. " - " .. h.name:gsub("^polygon%-hats::", ""))
            end
            return
        end
    else
        -- the next hat in the list, skipping the other team's
        local index = 0
        for i, h in ipairs(Hats) do
            if h.name == current.name then index = i end
        end
        repeat
            index = index % #Hats + 1
            hat = Hats[index]
        until hat.name ~= other.name or #Hats <= 2
    end

    SetTeamHat(team, hat)
    Chat.BroadcastMessage("The " .. Ternary(team == Team.TeamA, "blue", "red") .. " team now wears " .. hat.name:gsub("^polygon%-hats::", ""))
end

Commands["/end"] = function(player, args)
    if Game.State == State.Ended then
        StartNewGame()
        return
    end
    Game.Timer = 0
    Events.BroadcastRemote("UpdateTime", Reliability.Reliable, Game.Timer)
    EndGame()
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
    -- the goal (and a hit) goes to the player if they are on that team, like a real touch
    if Game.State == State.Running then
        AddBallTouch(player)
    end

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