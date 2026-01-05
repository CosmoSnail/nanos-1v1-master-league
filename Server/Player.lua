Package.Require('Vehicle.lua')

function SpawnPlayer(player)
  local character = Character(Vector(0, 0, 100), Rotator(0, 0, 0), "nanos-world::SK_Mannequin")
  character:SetTeam(1)
  player:Possess(character)

  SpawnVehicle(character)
end

function InitPlayers()
    Player.Subscribe("Spawn", SpawnPlayer)

    for _, player in pairs(Player.GetAll()) do
        SpawnPlayer(player)
    end
end