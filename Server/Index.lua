Server.LoadPackage("default-vehicles")

-- Balll
local ball = Prop(Vector(3000, 0, 100), Rotator(), "nanos-world::SM_Ball_VR")
ball:SetScale(4)
ball:SetMassScale(0.000001)
ball:SetPhysicalMaterial('nanos-world::PM_RubberBouncy')

-- Vehicle
local vehicleSpawnPoint = Vector(0, 0, 100)
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

  -- vehicle:SetDoor(0, Vector(25, -95, 100), Vector(40, -42, 55), Rotator(0, 0, -10), 75, -150)
  -- vehicle:SetDoor(1, Vector(25,  95, 100), Vector(35,  42, 60), Rotator(0, 0, -15), 75,  150)

  vehicle:RecreatePhysics()

  character:EnterVehicle(vehicle)
  character:SetVisibility(false)
end

-- Player
function SpawnPlayer(player)
  local character = Character(Vector(1000, 0, 100), Rotator(0, 0, 0), "nanos-world::SK_Mannequin")
  character:SetTeam(1)
  player:Possess(character)
  
  SpawnVehicle(character)
end
for _, player in pairs(Player.GetAll()) do
  SpawnPlayer(player)
end
Player.Subscribe("Spawn", SpawnPlayer)

-- Jump
Events.SubscribeRemote("Jump", function(player)
	local vehicle = player:GetControlledCharacter():GetVehicle()
  vehicle:AddImpulse(Vector(0, 0, 1000000))
end)

-- Nitro
Events.SubscribeRemote("StartNitro", function(player)
  print('Start Nitro')
	local vehicle = player:GetControlledCharacter():GetVehicle()
  vehicle:SetEngineSetup(4500, 10000, 1000, 0.02, 5, 600)
end)
Events.SubscribeRemote("StopNitro", function(player)
  print('Stop Nitro')
	local vehicle = player:GetControlledCharacter():GetVehicle()
  vehicle:SetEngineSetup(1000, 8000, 1000, 0.02, 5, 600)
end)