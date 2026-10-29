-- The name over each car (AttachVehiclePlayerName in Server/Vehicle.lua) is for the others: hidden on its
-- driver's own screen. Its "Driver" value may come with the text or a moment after it
local function HideOwnName(text)
    local player = Client.GetLocalPlayer()
    if player and text:IsValid() and text:GetValue("Driver") == player:GetID() then
        text:SetVisibility(false)
    end
end

Text3D.Subscribe("Spawn", HideOwnName)
Text3D.Subscribe("ValueChange", function(text, key)
    if key == "Driver" then
        HideOwnName(text)
    end
end)

for _, text in pairs(Text3D.GetAll()) do
    HideOwnName(text)
end
