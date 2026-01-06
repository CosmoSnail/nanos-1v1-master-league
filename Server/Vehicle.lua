Package.Require("Thruster.lua")
Package.Require("Tables.lua")

local rotationA = Rotator(0, 0, 0)
local rotationB = Rotator(0, 180, 0)

function SpawnVehicle(character)
    local vehicleSpawnPoint
    local rotation
    if character:GetTeam() == Team.TeamA then
        vehicleSpawnPoint = Game.CurrentSpawnPointA
        Game.CurrentSpawnPointA = Game.CurrentSpawnPointA + Vector(0, 700, 0)
        rotation = rotationA
    end
    if character:GetTeam() == Team.TeamB then
        vehicleSpawnPoint = Game.CurrentSpawnPointB
        Game.CurrentSpawnPointB = Game.CurrentSpawnPointB + Vector(0, 700, 0)
        rotation = rotationB
    end

    local vehicle = Offroad(vehicleSpawnPoint, rotation)
    vehicle:SetEngineSetup(1000, 8000, 1000, 0.02, 5, 600)
    vehicle:SetAerodynamicsSetup(3200, 0.4, 180, 160, 2, Vector(0, 0, 5))
    vehicle:SetTransmissionSetup(4.4, 6700, 3200, 0.03, 1.0)
    vehicle:SetSteeringWheelSetup(Vector(60, -42, 83), 19, Rotator())
    vehicle:SetExplosionSettings(Vector(), {}, { 1 })

    vehicle:SetWheel(0, "PhysWheel_FL", 50, 35, 50, Vector(), true, true, false, false, true, 6500, 0, 50000, 1000, 50, 50, 28, 70, 10, 6, 6, 0, 0.5, 0.7)
    vehicle:SetWheel(1, "PhysWheel_FR", 50, 35, 50, Vector(), true, true, false, false, true, 6500, 0, 50000, 1000, 50, 50, 28, 70, 10, 6, 6, 0, 0.5, 0.7)
    vehicle:SetWheel(2, "PhysWheel_BL", 50, 42, 0, Vector(), false, true, true, false, true, 6500, 15000, 50000, 1000, 50, 50, 28, 70, 10, 6, 6, 0, 0.5, 0.63)
    vehicle:SetWheel(3, "PhysWheel_BR", 50, 42, 0, Vector(), false, true, true, false, true, 6500, 15000, 50000, 1000, 50, 50, 28, 70, 10, 6, 6, 0, 0.5, 0.63)

    vehicle:RecreatePhysics()

    vehicle:Subscribe("CharacterAttemptLeave", function(self, _)
        return false
    end)

    SpawnThruster(vehicle)

    character:EnterVehicle(vehicle)
    character:SetVisibility(false)

end
