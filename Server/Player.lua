Package.Require('Vehicle.lua')
Package.Require('Tables.lua')

function SpawnPlayer(player)

    local character = Character(Vector(0, 0, 100), Rotator(0, 0, 0), "nanos-world::SK_Mannequin")
    local team = GetTeamToJoin()
    character:SetTeam(team)

    player:Possess(character)

	player:SetCameraArmLength(200, true)
    if team == Team.TeamA then
        player:SetCameraRotation(Rotator(0, 0, 0))
    else
        player:SetCameraRotation(Rotator(0, 180, 0))
    end

    SpawnVehicle(character)

    if Game.State ~= State.Running then
        character:SetInputEnabled(false)
    end

    Events.BroadcastRemote("UpdateScoreA", Game.ScoreA)
    Events.BroadcastRemote("UpdateScoreB", Game.ScoreB)
end

function InitPlayers()
    Player.Subscribe("Spawn", SpawnPlayer)

    for _, player in pairs(Player.GetAll()) do
        SpawnPlayer(player)
    end
end

function GetTeamToJoin()
    local teamACount = 0
    local teamBCount = 0

    for _, player in pairs(Player.GetAll()) do
        local character = player:GetControlledCharacter()
        if character then
            local team = character:GetTeam()
            if team == Team.TeamA then
                teamACount = teamACount + 1
            elseif team == Team.TeamB then
                teamBCount = teamBCount + 1
            end
        end
    end

    if teamACount <= teamBCount then
        return Team.TeamA
    else
        return Team.TeamB
    end
end

function ShuffleTeams()
    local players = Player.GetAll()
    local count = #players
    local indices = {}
    for i = 1, count do
        indices[i] = i
    end

    -- shuffle indices (Fisher–Yates)
    for i = count, 2, -1 do
        local j = math.random(i)
        indices[i], indices[j] = indices[j], indices[i]
    end
    local half = math.ceil(count / 2)
    for i = 1, count do
        local player = players[indices[i]]
        local character = player:GetControlledCharacter()
        if character then
            if i <= half then
                character:SetTeam(Team.TeamA)
            else
                character:SetTeam(Team.TeamB)
            end
        end
    end
end

Player.Subscribe("Destroy", function(player)
	local character = player:GetControlledCharacter()
	if character then
        local vehicle = character:GetVehicle()
        if vehicle then
            vehicle:Destroy()
        end
		character:Destroy()
	end
end)
