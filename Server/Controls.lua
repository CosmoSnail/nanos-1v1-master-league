Events.SubscribeRemote("Jump", function(player)
	local vehicle = player:GetControlledCharacter():GetVehicle()
  vehicle:AddImpulse(Vector(0, 0, 1000000))
end)

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
