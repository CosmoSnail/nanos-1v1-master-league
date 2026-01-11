Package.Require("Utils.lua")

Events.SubscribeRemote("Jump", function(player)
  if Game.State ~= State.Running and Game.State ~= State.Scored then
    return
  end
  local vehicle = player:GetControlledCharacter():GetVehicle()
  local baseJumpForce = 1000000
  local velocityMultiplier = vehicle:GetVelocity():Size() * 300

  vehicle:AddImpulse(Vector(0, 0, baseJumpForce + velocityMultiplier))
end)

Events.SubscribeRemote("StartNitro", function(player)
  if Game.State ~= State.Running and Game.State ~= State.Scored then
    return
  end
--   print('Start Nitro')
  local vehicle = player:GetControlledCharacter():GetVehicle()

  vehicle:SetForce(Vector(5000000, 0, 0))

  local thrusters = GetVehicleThrusters(vehicle)
  for _, thruster in pairs(thrusters) do
    local particles = GetAttachedParticles(thruster)
    for _, particle in pairs(particles) do
      particle:Activate()
    end
  end

end)

Events.SubscribeRemote("StopNitro", function(player)
  if Game.State ~= State.Running and Game.State ~= State.Scored then
    return
  end
--   print('Stop Nitro')
  local vehicle = player:GetControlledCharacter():GetVehicle()

  local thrusters = GetVehicleThrusters(vehicle)
  for _, thruster in pairs(thrusters) do
    local particles = GetAttachedParticles(thruster)
    for _, particle in pairs(particles) do
      particle:Deactivate()
    end
  end

  vehicle:SetForce(Vector(0, 0, 0))
end)

function GetVehicleThrusters(vehicle)
  local thrusters = Filter(
    vehicle:GetAttachedEntities(),
    function(entity)
      return entity:IsA(Prop)
    end
  )
  return thrusters
end

function GetAttachedParticles(thruster)
  local particles = Filter(
    thruster:GetAttachedEntities(),
    function(entity)
      return entity:IsA(Particle)
    end
  )
  return particles
end

function CheckInAirRotation()

end