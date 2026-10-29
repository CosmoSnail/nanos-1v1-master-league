-- The pitch's floor in one of the default pack's surfaces (Shared/Materials.lua; /floor tries the others), on
-- the arena mesh's floor slot. The arena is a level mesh, which Lua only sees with load_level_entities in
-- Package.toml. Its ramps and the goals' floor keep their own material, made matte: glossy, they shone every
-- light in the arena back. Their roughness range ("Rough Min", "Rough Max") pushed up does it (a material
-- without them ignores it)
local FLOOR_SLOT = 4                -- of the arena mesh
local MATTE_SLOTS = { 3, 7 }        -- the ramps, the goals' floor
local MATTE_ROUGHNESS = { 0.85, 1 }

local floor = { material = DefaultFloorMaterial, size = DefaultFloorSize, aspect = DefaultFloorAspect }
local arena = nil

local function ApplyFloor()
    if not arena or not arena:IsValid() then return end
    arena:SetMaterial("nanos-world::" .. FloorMaterials[floor.material], FLOOR_SLOT)
    arena:SetMaterialScalarParameter("TextureSize", floor.size, FLOOR_SLOT)
    arena:SetMaterialScalarParameter("TextureAspect", floor.aspect, FLOOR_SLOT)
end

local function FindArena(attempt)
    for _, mesh in pairs(StaticMesh.GetAll()) do
        if mesh:IsValid() and mesh:IsFromLevel() then
            arena = mesh
            for _, slot in ipairs(MATTE_SLOTS) do
                mesh:SetMaterialScalarParameter("Rough Min", MATTE_ROUGHNESS[1], slot)
                mesh:SetMaterialScalarParameter("Rough Max", MATTE_ROUGHNESS[2], slot)
            end
            ApplyFloor()
            return
        end
    end
    -- the level's meshes may show up a moment after the package loads
    if attempt < 10 then
        Timer.SetTimeout(function() FindArena(attempt + 1) end, 1000)
    end
end

FindArena(1)

-- /floor (dev): another floor until a reload; size and aspect are kept from the last one when not given
Events.SubscribeRemote("DevFloor", function(index, size, aspect)
    if not FloorMaterials[index] then return end
    floor.material = index
    if type(size) == "number" then floor.size = size end
    if type(aspect) == "number" then floor.aspect = aspect end
    ApplyFloor()
end)
