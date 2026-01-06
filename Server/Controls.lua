Events.SubscribeRemote("Jump", function(player)
  if Game.State ~= State.Running and Game.State ~= State.Scored then
    return
  end
  local vehicle = player:GetControlledCharacter():GetVehicle()
  vehicle:AddImpulse(Vector(0, 0, 1000000))
end)

Events.SubscribeRemote("StartNitro", function(player)
  if Game.State ~= State.Running and Game.State ~= State.Scored then
    return
  end
--   print('Start Nitro')
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
  if Game.State ~= State.Running and Game.State ~= State.Scored then
    return
  end
--   print('Stop Nitro')
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
