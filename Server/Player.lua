Package.Require('Vehicle.lua')
Package.Require('Tables.lua')

function SpawnPlayer(player)
  local character = Character(Vector(0, 0, 100), Rotator(0, 0, 0), "nanos-world::SK_Mannequin")
  character:SetTeam(GetTeamToJoin())
  player:Possess(character)

  SpawnVehicle(character)
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

function InitPlayers()
    Player.Subscribe("Spawn", SpawnPlayer)

    for _, player in pairs(Player.GetAll()) do
        SpawnPlayer(player)
    end
end