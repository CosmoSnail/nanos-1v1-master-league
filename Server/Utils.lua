function TogglePlayersInput(enabled)
    for _, player in pairs(Player.GetAll()) do
        local character = player:GetControlledCharacter()
        if character then
            character:SetInputEnabled(enabled)
        end
    end
end