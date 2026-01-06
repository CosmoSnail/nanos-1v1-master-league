function TogglePlayersInput(enabled)
    for _, player in pairs(Player.GetAll()) do
        local character = player:GetControlledCharacter()
        if character then
            character:SetInputEnabled(enabled)
        end
    end
end

function Filter(list, predicate)
    local result = {}
    for _, v in ipairs(list) do
        if predicate(v) then
            table.insert(result, v)
        end
    end
    return result
end

function Ternary(condition, ifTrue, ifFalse)
    if condition then
        return ifTrue
    else
        return ifFalse
    end
end

function GetAttachedEntitiesByClass(entity, class)
    local attachedEntities = entity:GetAttachedEntities()
    local filteredEntities = Filter(
        attachedEntities,
        function(attachedEntity)
            return attachedEntity:IsA(class)
        end
    )
    return filteredEntities
end