Package.Require("Utils.lua")

-- Driving, jumping and boosting run on the driver's client (Client/Car.lua);
-- the server only shows the thruster flames to everyone while a player boosts.
Events.SubscribeRemote("CarBoost", function(player, boosting)
    if type(boosting) ~= "boolean" then
        return
    end
    local character = player:GetControlledCharacter()
    local vehicle = character and character:GetVehicle()
    if not vehicle or not vehicle:IsValid() then
        return
    end

    for _, thruster in pairs(GetVehicleThrusters(vehicle)) do
        for _, particle in pairs(GetAttachedParticles(thruster)) do
            if boosting then
                particle:Activate()
            else
                particle:Deactivate()
            end
        end
    end
end)

function GetVehicleThrusters(vehicle)
    return Filter(
        vehicle:GetAttachedEntities(),
        function(entity)
            return entity:IsA(Prop)
        end
    )
end

function GetAttachedParticles(thruster)
    return Filter(
        thruster:GetAttachedEntities(),
        function(entity)
            return entity:IsA(Particle)
        end
    )
end
