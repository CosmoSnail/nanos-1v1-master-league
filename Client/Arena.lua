-- The arena dressed for Halloween, spawned on each client: no collision, nothing sent over the network.
-- Outside the glass dome: dark ground all round, a graveyard along both sides (tombstones and crosses, a crypt,
-- dead trees, scarecrows, jack-o'-lanterns lined up at the foot of the walls), the witches' coven behind their
-- goal (hut, cauldron, standing stones round a glowing pentagram), the pumpkin patch behind the Pumpkins' goal
-- with the Pumpkin King (a jack-o'-lantern 22 m wide), dead trees on the horizon, mist and will-o'-wisps.
-- Inside: a turning magic circle on the centre spot and one in each goal in its team's color, fallen leaves
-- on the pitch, and the arena's own rings and glass lit in Halloween colors.
--
-- The arena (measured from its mesh): floor at Z 145, walls at X ±12000 and Y ±8000, goals Y ±2300 wide,
-- up to Z 1800 and 2200 deep (to X ±14200), ceiling at about Z 4000-4400.
-- Meshes from burn-the-witch-assets (the Burn the Witch! village) and burn-the-witch-vfx

local BTW = "burn-the-witch-assets::"
local VFX = "burn-the-witch-vfx::"
local IMAGES = "package://" .. Package.GetName() .. "/Client/Images/"
local GROUND_Z = 120
local FLOOR_Z = 145
local RENDER_CULL_DISTANCE = 1000000

local PUMPKIN_GLOW = Color(1.0, 0.42, 0.08)
local WITCH_GLOW = Color(0.55, 0.15, 1.0)
local CAULDRON_GLOW = Color(0.3, 1.0, 0.15)

-- The arena mesh's material slots (from its cooked mesh) and what they are lit with; "EmissiveColor" is a
-- parameter of the arena's materials
local ARENA_GLOW = {
    { slot = 0, color = Color(0.03, 0.0, 0.06) },   -- the glass dome: a faint purple haze
    { slot = 1, color = Color(0.9, 0.2, 2.2) },     -- the rims along the top of the ramps: purple
    { slot = 5, color = Color(0.6, 2.2, 0.15) },    -- the goal frames: slime green
    { slot = 9, color = Color(2.4, 0.7, 0.05) },    -- the ring: pumpkin orange
}

-- A fixed sequence of random numbers, so every player gets the same graveyard (and the game's own
-- math.random isn't reseeded)
local seed = 1031
local function Random(a, b)
    seed = (seed * 1103515245 + 12345) % 2147483648
    local r = seed / 2147483648
    if not a then return r end
    return a + (b - a) * r
end

local function Pick(list)
    return list[math.floor(Random() * #list) + 1]
end

local function Mesh(asset, location, rotation, scale)
    local mesh = StaticMesh(location, rotation or Rotator(), asset, CollisionType.NoCollision)
    if scale then
        mesh:SetScale(type(scale) == "number" and Vector(scale) or scale)
    end
    mesh:SetCastShadow(false)
    mesh:SetRenderCullDistance(RENDER_CULL_DISTANCE)
    return mesh
end

local function Glow(location, color, intensity, radius)
    local light = Light(location, Rotator(), color, LightType.Point, intensity, radius, 44, 0, 60000, true, false, true)
    light:SetRenderCullDistance(RENDER_CULL_DISTANCE)
    return light
end

-- A magic circle on the ground (M_FX_Sigil, additive, turning on its own)
local function Sigil(location, size, color, intensity, points)
    local quad = Mesh(VFX .. "SM_FX_Quad", location, Rotator(), Vector(size, size, 1))
    quad:SetMaterial(VFX .. "M_FX_Sigil")
    quad:SetMaterialColorParameter("Color", color)
    quad:SetMaterialScalarParameter("Intensity", intensity)
    quad:SetMaterialScalarParameter("Points", points)
    quad:SetMaterialScalarParameter("Spin", 0.03)
    quad:SetMaterialScalarParameter("Reveal", 1)
    quad:SetMaterialScalarParameter("Pulse", 0)
    quad:SetMaterialScalarParameter("Fill", 0.2)
    quad:SetMaterialScalarParameter("Fade", 1)
    return quad
end

-- A low bank of mist (M_FX_Smoke on a flattened puff)
local function Mist(location, size, color, opacity)
    local puff = Mesh(VFX .. "SM_FX_Smoke", location, Rotator(0, Random(0, 360), 0), Vector(size, size, size * 0.22))
    puff:SetMaterial(VFX .. "M_FX_Smoke")
    puff:SetMaterialColorParameter("Color", color)
    puff:SetMaterialColorParameter("GlowColor", color)
    puff:SetMaterialScalarParameter("Glow", 0.3)
    puff:SetMaterialScalarParameter("Opacity", opacity)
    puff:SetMaterialScalarParameter("Seed", Random(0, 100))
    puff:SetMaterialScalarParameter("Fade", 1)
    return puff
end

-- Glowing motes rising in a column: will-o'-wisps (M_FX_Motes, looping on its own)
local function Wisps(location, size, height, color)
    local motes = Mesh(VFX .. "SM_FX_Motes", location, Rotator(), Vector(size, size, height))
    motes:SetMaterial(VFX .. "M_FX_Motes")
    motes:SetMaterialColorParameter("Color", color)
    motes:SetMaterialScalarParameter("Intensity", 4)
    motes:SetMaterialScalarParameter("Rate", 0.25)
    motes:SetMaterialScalarParameter("Fade", 1)
    return motes
end

local function Ground()
    local ground = Mesh("nanos-world::SM_Plane", Vector(0, 0, GROUND_Z), Rotator(), Vector(2400, 2400, 1))
    ground:SetMaterial("nanos-world::M_Default_Masked_Lit_WorldAligned")
    ground:SetMaterialTextureParameter("Texture", IMAGES .. "ground.png")
    ground:SetMaterialScalarParameter("TextureSize", 1600)
    ground:SetMaterialScalarParameter("Roughness", 1)
    ground:SetMaterialScalarParameter("Specular", 0.15)
    ground:SetMaterialScalarParameter("Opacity", 1)
end

-- side: 1 along +Y, -1 along -Y
local function Graveyard(side)
    local facing = side > 0 and 0 or 180
    -- rows of graves, leaning a little, the middle left free for the crypt
    for row = 0, 3 do
        local y = side * (10200 + row * 1900)
        for x = -10500, 10500, 1600 do
            if row < 2 or math.abs(x) > 2600 then
                local stone = Pick({ "Tombstone1", "Tombstone2", "Tombstone3", "Tombstone1", "Tombstone3", "GraveCross" })
                Mesh(BTW .. stone, Vector(x + Random(-350, 350), y + Random(-300, 300), GROUND_Z),
                    Rotator(Random(-4, 4), facing + Random(-14, 14), Random(-5, 5)), Random(2.4, 3.2))
            end
        end
    end

    -- the crypt, between two torches
    Mesh(BTW .. "Crypt", Vector(0, side * 15600, GROUND_Z), Rotator(0, facing, 0), 2.6)
    for _, x in ipairs({ -1900, 1900 }) do
        Mesh(BTW .. "TorchPost", Vector(x, side * 13600, GROUND_Z), Rotator(0, Random(0, 360), 0), 2.2)
        Glow(Vector(x, side * 13600, GROUND_Z + 640), PUMPKIN_GLOW, 260, 3200)
    end

    -- dead trees behind the graves, scarecrows in front of them
    for _, x in ipairs({ -11500, -6500, -1800, 3600, 8000, 12000 }) do
        local tree = Pick({ "DeadTreeBig", "DeadTreeGnarled", "DeadTreeSnag", "DeadTreeTall" })
        Mesh(BTW .. tree, Vector(x + Random(-800, 800), side * Random(18000, 21000), GROUND_Z),
            Rotator(0, Random(0, 360), 0), Random(2.2, 3.0))
    end
    for _, x in ipairs({ -7600, 5200 }) do
        Mesh(BTW .. "Scarecrow", Vector(x, side * 9500, GROUND_Z), Rotator(0, facing + 180 + Random(-20, 20), 0), 2.3)
    end

    -- jack-o'-lanterns lined up at the foot of the wall, every fourth one casting its light
    local k = 0
    for x = -11000, 11000, 1000 do
        local lantern = Pick({ "JackOLantern", "JackOLantern2", "JackOLantern3" })
        Mesh(BTW .. lantern, Vector(x + Random(-150, 150), side * (8700 + Random(-100, 200)), GROUND_Z),
            Rotator(0, Random(0, 360), 0), Random(3, 4.2))
        if k % 4 == 0 then
            Glow(Vector(x, side * 8900, GROUND_Z + 250), PUMPKIN_GLOW, 140, 2400)
        end
        k = k + 1
    end

    -- mist among the graves, wisps rising here and there
    for _ = 1, 4 do
        Mist(Vector(Random(-10000, 10000), side * Random(10500, 17000), GROUND_Z + 60), Random(18, 26), Color(0.55, 0.5, 0.7), 0.35)
    end
    for _ = 1, 3 do
        Wisps(Vector(Random(-9000, 9000), side * Random(11000, 16000), GROUND_Z), 7, 9, Theme.Slime)
    end
end

-- Behind the Witches' goal (-X): their hut, a cauldron bubbling green over a glowing pentagram ringed by
-- standing stones, totems, an effigy, a gibbet and a pile of coffins
local function Coven()
    local center = Vector(-21000, 0, GROUND_Z)
    Sigil(center + Vector(0, 0, 4), 55, WITCH_GLOW, 2, 5)
    Mesh(BTW .. "Cauldron", center, Rotator(0, 90, 0), 3.5)
    Glow(center + Vector(0, 0, 650), CAULDRON_GLOW, 600, 5000)
    local steam = Mist(center + Vector(0, 0, 700), 7, Theme.Slime, 0.4)
    steam:SetScale(Vector(7, 7, 12))
    Wisps(center + Vector(0, 0, 300), 5, 12, Theme.Slime)

    for k = 0, 8 do
        local angle = k / 9 * math.pi * 2
        Mesh(BTW .. "StandingStoneRune", center + Vector(math.cos(angle) * 3300, math.sin(angle) * 3300, 0),
            Rotator(0, math.deg(angle) + 90 + Random(-10, 10), Random(-4, 4)), Random(2.2, 2.7))
    end
    for k = 0, 5 do
        local angle = (k + 0.5) / 6 * math.pi * 2
        Mesh(BTW .. Pick({ "SkullPile", "SkullPile2" }), center + Vector(math.cos(angle) * 2000, math.sin(angle) * 2000, 0),
            Rotator(0, Random(0, 360), 0), 3)
    end

    Mesh(BTW .. "WitchHut", Vector(-31500, 5500, GROUND_Z), Rotator(0, 200, 0), 2.2)
    for _, y in ipairs({ -4600, 4600 }) do
        Mesh(BTW .. "WitchTotem", Vector(-16800, y, GROUND_Z), Rotator(0, 90, 0), 2.6)
        Mesh(BTW .. "WitchLantern", Vector(-17600, y * 0.7, GROUND_Z), Rotator(0, Random(0, 360), 0), 2.2)
        Glow(Vector(-17600, y * 0.7, GROUND_Z + 560), WITCH_GLOW, 220, 3000)
    end
    Mesh(BTW .. "WitchEffigy", Vector(-25500, -7500, GROUND_Z), Rotator(0, 60, 0), 2.6)
    Mesh(BTW .. "Gibbet", Vector(-27500, 8800, GROUND_Z), Rotator(0, -30, 0), 2.4)
    Mesh(BTW .. "CoffinPile", Vector(-24000, 10500, GROUND_Z), Rotator(0, 15, 0), 2.6)
    for k = 1, 5 do
        local tree = Pick({ "DeadTreeBig", "DeadTreeGnarled", "DeadTreeSnag", "DeadTreeTall" })
        Mesh(BTW .. tree, Vector(Random(-36000, -26000), Random(9000, 15000) * (k % 2 == 0 and 1 or -1), GROUND_Z),
            Rotator(0, Random(0, 360), 0), Random(2.4, 3.2))
    end
    for _ = 1, 3 do
        Mist(Vector(Random(-30000, -17000), Random(-9000, 9000), GROUND_Z + 60), Random(20, 28), Color(0.5, 0.42, 0.7), 0.3)
    end
end

-- Behind the Pumpkins' goal (+X): the Pumpkin King, a giant jack-o'-lantern staring at the arena, in a patch
-- of pumpkins with scarecrows and haystacks
local function PumpkinPatch()
    local king = Vector(27500, 0, GROUND_Z)
    Mesh(VFX .. "SM_FX_Pumpkin", king + Vector(0, 0, 37 * 22), Rotator(0, 180, 0), 22)
    Glow(king + Vector(-1800, 0, 900), PUMPKIN_GLOW, 3500, 14000)
    Sigil(king + Vector(0, 0, 4), 36, PUMPKIN_GLOW, 1.6, 7)

    local placed = 0
    while placed < 44 do
        local spot = Vector(Random(16500, 34000), Random(-11000, 11000), GROUND_Z)
        if (spot - king):Size() > 2400 then
            local lit = Random() < 0.5
            local asset = lit and Pick({ "JackOLantern", "JackOLantern2", "JackOLantern3" }) or "Pumpkin"
            local giant = Random() < 0.12
            Mesh(BTW .. asset, spot, Rotator(0, Random(0, 360), 0), giant and Random(7, 10) or Random(2.5, 5.5))
            placed = placed + 1
        end
    end
    for _, spot in ipairs({ { 19500, -6500 }, { 19500, 6500 }, { 31500, -8500 }, { 31500, 8500 } }) do
        Mesh(BTW .. "Scarecrow", Vector(spot[1], spot[2], GROUND_Z), Rotator(0, 90 + Random(-25, 25), 0), 2.4)
    end
    for _, spot in ipairs({ { 22000, -10500 }, { 33500, 4000 }, { 24500, 10500 } }) do
        Mesh(BTW .. Pick({ "Haystack", "HayPile" }), Vector(spot[1], spot[2], GROUND_Z), Rotator(0, Random(0, 360), 0), 2.2)
    end
    for k = 1, 5 do
        local tree = Pick({ "DeadTreeBig", "DeadTreeGnarled", "DeadTreeSnag", "DeadTreeTall" })
        Mesh(BTW .. tree, Vector(Random(28000, 38000), Random(12000, 17000) * (k % 2 == 0 and 1 or -1), GROUND_Z),
            Rotator(0, Random(0, 360), 0), Random(2.4, 3.2))
    end
    for _ = 1, 3 do
        Wisps(Vector(Random(17000, 33000), Random(-10000, 10000), GROUND_Z), 6, 8, PUMPKIN_GLOW)
    end
end

-- Dead trees and a few autumn ones all round the horizon
local function Horizon()
    for k = 0, 35 do
        local angle = (k + Random(-0.3, 0.3)) / 36 * math.pi * 2
        local distance = Random(48000, 66000)
        local tree = Random() < 0.75 and Pick({ "FarTreeDead1", "FarTreeDead2" }) or Pick({ "FarTreeAutumn1", "FarTreeAutumn2" })
        Mesh(BTW .. tree, Vector(math.cos(angle) * distance, math.sin(angle) * distance, GROUND_Z),
            Rotator(0, Random(0, 360), 0), Random(3, 5))
    end
end

-- Inside: the magic circles on the pitch and fallen leaves blown about
local function Pitch()
    Sigil(Vector(0, 0, FLOOR_Z + 8), 26, Theme.Slime, 0.8, 7)
    Sigil(Vector(-13200, 0, FLOOR_Z + 8), 17, Theme.Teams[1].color, 1.2, 5)
    Sigil(Vector(13200, 0, FLOOR_Z + 8), 17, Theme.Teams[2].color, 1.2, 7)

    local placed = 0
    while placed < 26 do
        local spot = Vector(Random(-11000, 11000), Random(-7200, 7200), FLOOR_Z)
        if Vector(spot.X, spot.Y, 0):Size() > 2000 then
            local half = Random(300, 480)
            local leaves = Decal(spot, Rotator(-90, Random(0, 360), 0), "nanos-world::M_NanosDecal", Vector(60, half, half), -1)
            leaves:SetMaterialTextureParameter("Texture", IMAGES .. (Random() < 0.5 and "leaves_1.png" or "leaves_2.png"))
            leaves:SetMaterialScalarParameter("Opacity", 1)
            placed = placed + 1
        end
    end
end

-- The arena's own glass and rings in Halloween colors (it is a level mesh: load_level_entities in Package.toml)
local function LightArena(attempt)
    for _, mesh in pairs(StaticMesh.GetAll()) do
        if mesh:IsValid() and mesh:IsFromLevel() then
            for _, glow in ipairs(ARENA_GLOW) do
                mesh:SetMaterialColorParameter("EmissiveColor", glow.color, glow.slot)
            end
            return
        end
    end
    -- the level's meshes may show up a moment after the package loads
    if attempt < 10 then
        Timer.SetTimeout(function() LightArena(attempt + 1) end, 1000)
    end
end

Ground()
Graveyard(1)
Graveyard(-1)
Coven()
PumpkinPatch()
Horizon()
Pitch()
LightArena(1)
