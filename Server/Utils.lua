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

function FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

function TableToJson(value, indent)
    indent = indent or 0
    local spacing = string.rep("  ", indent)

    if type(value) == "table" then
        local isArray = true
        local maxIndex = 0

        for k, _ in pairs(value) do
            if type(k) ~= "number" then
                isArray = false
                break
            end
            if k > maxIndex then
                maxIndex = k
            end
        end

        local result = {}
        if isArray then
            table.insert(result, "[")
            for i = 1, maxIndex do
                table.insert(result,
                    spacing .. "  " .. TableToJson(value[i], indent + 1) .. (i < maxIndex and "," or "")
                )
            end
            table.insert(result, spacing .. "]")
        else
            table.insert(result, "{")
            local first = true
            for k, v in pairs(value) do
                if not first then
                    table.insert(result, ",")
                end
                first = false
                table.insert(result,
                    spacing .. '  "' .. tostring(k) .. '": ' .. TableToJson(v, indent + 1)
                )
            end
            table.insert(result, spacing .. "}")
        end

        return table.concat(result, "\n")

    elseif type(value) == "string" then
        return '"' .. value:gsub('"', '\\"') .. '"'

    elseif type(value) == "number" or type(value) == "boolean" then
        return tostring(value)

    elseif value == nil then
        return "null"

    else
        return '"<' .. type(value) .. '>"'
    end
end

function PrintTable(tbl)
    print(TableToJson(tbl))
end
