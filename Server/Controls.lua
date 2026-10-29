Package.Require("Utils.lua")

-- Driving, jumping and boosting run on the driver's client (Client/Car.lua);
-- the server only tells the other clients who is boosting, to draw the flames (Client/BoostFX.lua).
Events.SubscribeRemote("CarBoost", function(player, boosting)
    if type(boosting) ~= "boolean" then
        return
    end
    local character = player:GetControlledCharacter()
    local vehicle = character and character:GetVehicle()
    if not vehicle or not vehicle:IsValid() then
        return
    end

    vehicle:SetValue("Boosting", boosting, true)
end)
