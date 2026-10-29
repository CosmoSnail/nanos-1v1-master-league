-- Your own name: not over your own car (AttachVehiclePlayerName in Server/Vehicle.lua marks each name with its
-- driver; the "Driver" value may come with the text or a moment after it), but fixed at the bottom of the HUD in
-- your team's color (Client/UI, "UpdateMyName")
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

-- The HUD's name, sent again whenever the name or the team changes (/swap, a new game)
local shown_name = nil
local shown_team = nil
Timer.SetInterval(function()
    local player = Client.GetLocalPlayer()
    if not player then return end
    local character = player:GetControlledCharacter()
    local name, team = player:GetName(), character and character:GetTeam() or 0
    if name ~= shown_name or team ~= shown_team then
        shown_name, shown_team = name, team
        Events.Call("UpdateMyName", name, team)
    end
end, 1000)
