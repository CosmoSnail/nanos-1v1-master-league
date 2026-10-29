local Commands = {}

Commands["/help"] = function(player, args)
    Chat.SendMessage(player, "/goal [witches|skeletons] - score a goal for that team")
    Chat.SendMessage(player, "/fireworks [end] - goal fireworks (end: the end of game ones)")
    Chat.SendMessage(player, "/reload - reload the game-mode")
    Chat.SendMessage(player, "/swap - switch to the other team")
    Chat.SendMessage(player, "/hat [number|name] - change your team's hat (next one if empty)")
    Chat.SendMessage(player, "/end - end the game now (during the end screen: start the next one)")
    Chat.SendMessage(player, "/time <seconds> - set the time left in the game")
    Chat.SendMessage(player, "/lightning - a lightning strike now")
    Chat.SendMessage(player, "/fog <0-100> - try a density of mist (until a reload)")
    Chat.SendMessage(player, "/glow <0-5> - try a glow of the pumpkin ball (until a reload)")
end

Commands["/time"] = function(player, args)
    local seconds = tonumber(args[1] or "")
    if not seconds or Game.State == State.Ended then
        Chat.SendMessage(player, "/time <seconds> - set the time left in the game")
        return
    end
    Game.Timer = math.max(1, math.floor(seconds))
    Events.BroadcastRemote("UpdateTime", Reliability.Reliable, Game.Timer)
end

Commands["/lightning"] = function(player, args)
    StrikeLightning()
end

-- Tries a density of mist on everyone's sky until the package reloads (NIGHT.fog in Client/Atmosphere.lua keeps it)
Commands["/fog"] = function(player, args)
    local value = tonumber(args[1] or "")
    if not value then
        Chat.SendMessage(player, "/fog <0-100> - the mist's density for everyone (8 by default)")
        return
    end
    value = math.max(0, math.min(100, value))
    Events.BroadcastRemote("DevFog", Reliability.Reliable, value)
    Chat.BroadcastMessage("Fog: " .. value)
end

-- Tries a glow of the pumpkin ball's skin until the package reloads (PUMPKIN_LOOK in Client/PumpkinBall.lua keeps it)
Commands["/glow"] = function(player, args)
    local value = tonumber(args[1] or "")
    if not value then
        Chat.SendMessage(player, "/glow <0-5> - how much the pumpkin ball's skin glows (0.7 by default)")
        return
    end
    value = math.max(0, math.min(5, value))
    Events.BroadcastRemote("DevPumpkinGlow", Reliability.Reliable, value)
    Chat.BroadcastMessage("Pumpkin glow: " .. value)
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
                if h.label:lower():find(search, 1, true) or h.name:lower():find(search, 1, true) then
                    hat = h
                    break
                end
            end
        end
        if not hat then
            for i, h in ipairs(Hats) do
                Chat.SendMessage(player, i .. " - " .. h.label)
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
    Chat.BroadcastMessage("The " .. TeamName(team) .. " now wear the " .. hat.label)
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

    Chat.SendMessage(player, "You now play for the " .. TeamName(team))
end

Commands["/goal"] = function(player, args)
    Game.LastPlayerHitBall = player
    -- the goal (and a hit) goes to the player if they are on that team, like a real touch
    if Game.State == State.Running then
        AddBallTouch(player)
    end

    -- the Skeletons score in the Witches' goal (A) and the other way round
    local team = ParseTeam(args[1] or "skeletons")

    if team == Team.TeamB then
        TeleportBall(Config.GoalPointA)
    elseif team == Team.TeamA then
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