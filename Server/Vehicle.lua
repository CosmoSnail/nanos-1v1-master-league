Package.Require("Thruster.lua")

local vehicleSpawnPoint = Vector(-11000, 0, 100)

function SpawnVehicle(character)
  vehicleSpawnPoint = vehicleSpawnPoint + Vector(0, 1000, 0)

  local vehicle = Offroad(vehicleSpawnPoint, Rotator())
  vehicle:SetEngineSetup(1000, 8000, 1000, 0.02, 5, 600)
  vehicle:SetAerodynamicsSetup(2000, 0.4, 180, 160, 2, Vector(0, 0, 5))
  vehicle:SetTransmissionSetup(4.4, 6700, 3200, 0.03, 1.0)
  vehicle:SetSteeringWheelSetup(Vector(60, -42, 83), 19, Rotator())
  vehicle:SetExplosionSettings(Vector(), {}, { 1 })

  vehicle:SetWheel(0, "PhysWheel_FL", 50, 35, 50, Vector(), true, true, false, false, true, 6500, 0, 50000, 1000, 50, 50, 28, 70, 10, 6, 6, 0, 0.5, 0.7)
  vehicle:SetWheel(1, "PhysWheel_FR", 50, 35, 50, Vector(), true, true, false, false, true, 6500, 0, 50000, 1000, 50, 50, 28, 70, 10, 6, 6, 0, 0.5, 0.7)
  vehicle:SetWheel(2, "PhysWheel_BL", 50, 42, 0, Vector(), false, true, true, false, true, 6500, 15000, 50000, 1000, 50, 50, 28, 70, 10, 6, 6, 0, 0.5, 0.63)
  vehicle:SetWheel(3, "PhysWheel_BR", 50, 42, 0, Vector(), false, true, true, false, true, 6500, 15000, 50000, 1000, 50, 50, 28, 70, 10, 6, 6, 0, 0.5, 0.63)

  vehicle:RecreatePhysics()

  SpawnThruster(vehicle)

  character:EnterVehicle(vehicle)
  character:SetVisibility(false)
  
end
