Server.LoadPackage("default-vehicles")

-- Balll
local ball = Prop(Vector(3000, 0, 100), Rotator(), "nanos-world::SM_Ball_VR")
ball:SetScale(4)
ball:SetMassScale(0.000001)
ball:SetPhysicalMaterial('nanos-world::PM_RubberBouncy')

-- Thruster
function SpawnThruster(vehicle)
  local thruster1 = Prop(Vector(0, 0, 0), Rotator(), "nanos-world::SM_Jet_Thruster", CollisionType.StaticOnly, true, GrabMode.Disabled)
  local thruster2 = Prop(Vector(0, 0, 0), Rotator(), "nanos-world::SM_Jet_Thruster", CollisionType.StaticOnly, true, GrabMode.Disabled)
  thruster1:AttachTo(vehicle, AttachmentRule.SnapToTarget, "", 1)
  thruster2:AttachTo(vehicle, AttachmentRule.SnapToTarget, "", 1)
  thruster1:SetRelativeLocation(Vector(-150, 40, 45))
  thruster2:SetRelativeLocation(Vector(-150, -40, 45))

  local particle1 = Particle(Vector(), Rotator(), "nanos-world::P_Fire", false, true)
  particle1:AttachTo(thruster1, AttachmentRule.SnapToTarget, "", 0)
  particle1:SetRelativeLocation(Vector(-40, 0, 0))
  particle1:Deactivate()

  local particle2 = Particle(Vector(), Rotator(), "nanos-world::P_Fire", false, true)
  particle2:AttachTo(thruster2, AttachmentRule.SnapToTarget, "", 0)
  particle2:SetRelativeLocation(Vector(-40, 0, 0))
  particle2:Deactivate()
end

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

  SpawnThruster(vehicle)

  character:EnterVehicle(vehicle)
  character:SetVisibility(false)

  Timer.SetInterval(function()
    print(vehicle:GetVelocity())
  end, 500)
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
  -- vehicle:SetEngineSetup(4500, 10000, 1000, 0.02, 5, 600)
  vehicle:SetForce(Vector(5000000, 0, 0))
  
  local thrusters = vehicle:GetAttachedEntities()
  for _, thruster in pairs(thrusters) do
    local particles = thruster:GetAttachedEntities()
    for _, particle in pairs(particles) do
      particle:Activate()
    end
  end

end)
Events.SubscribeRemote("StopNitro", function(player)
  print('Stop Nitro')
	local vehicle = player:GetControlledCharacter():GetVehicle()
  -- vehicle:SetEngineSetup(1000, 8000, 1000, 0.02, 5, 600)

  local thrusters = vehicle:GetAttachedEntities()
  for _, thruster in pairs(thrusters) do
    local particles = thruster:GetAttachedEntities()
    for _, particle in pairs(particles) do
      particle:Deactivate()
    end
  end

  vehicle:SetForce(Vector(0, 0, 0))
end)

