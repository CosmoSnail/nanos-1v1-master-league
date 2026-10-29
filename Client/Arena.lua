-- The arena dressed for Halloween, spawned on each client: no collision, nothing sent over the network.
-- Outside the glass dome: dark ground all round, a graveyard along both sides (tombstones and crosses, a crypt,
-- dead trees, scarecrows, jack-o'-lanterns lined up at the foot of the walls), the witches' coven behind their
-- goal (hut, cauldron, standing stones round a glowing pentagram), the pumpkin patch behind the Skeletons' goal
-- with the Pumpkin King (a jack-o'-lantern 60 m wide), dead trees on the horizon, mist and will-o'-wisps.
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
local SIDE_WALL = 8000      -- Y of the side walls
local GOAL_BACK = 14200     -- X of the back of the goals
local RENDER_CULL_DISTANCE = 1000000

-- The world outside is built bigger than life, like the arena itself (about 2.2 times Rocket League's, cars
-- included): at life size a tombstone seen from the pitch, a hundred metres away, is a speck. The layout
-- below is written at life size (cm out from the walls, or from the middle of each place), and BIG scales
-- the meshes, the distances between them and the lights' reach together
local BIG = 2.7

local PUMPKIN_GLOW = Color(1.0, 0.42, 0.08)
local WITCH_GLOW = Color(0.55, 0.15, 1.0)
local CAULDRON_GLOW = Color(0.3, 1.0, 0.15)

-- The arena mesh's material slots (from its cooked mesh) and what they are lit with; "EmissiveColor" is a
-- parameter of the arena's materials
local ARENA_GLOW = {
    { slot = 0, color = Color(0.03, 0.0, 0.06) },   -- the glass dome: a faint purple haze
    { slot = 1, color = Color(0.55, 0.08, 1.3) },   -- the rims along the top of the ramps: purple
    { slot = 5, color = Color(0.35, 1.3, 0.06) },   -- the goal frames: slime green
    { slot = 9, color = Color(1.4, 0.38, 0.02) },   -- the ring: pumpkin orange
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
    local light = Light(location, Rotator(), color, LightType.Point, intensity, radius, 44, 0, 250000, true, false, true)
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
    local ground = Mesh("nanos-world::SM_Plane", Vector(0, 0, GROUND_Z), Rotator(), Vector(3400, 3400, 1))
    ground:SetMaterial("nanos-world::M_Default_Masked_Lit_WorldAligned")
    ground:SetMaterialTextureParameter("Texture", IMAGES .. "ground.png")
    ground:SetMaterialScalarParameter("TextureSize", 3000)
    ground:SetMaterialScalarParameter("Roughness", 1)
    ground:SetMaterialScalarParameter("Specular", 0.15)
    ground:SetMaterialScalarParameter("Opacity", 1)
end

-- Outside, a mesh at `scale` life size times BIG, and a light whose reach grows with it
local function Big(asset, location, rotation, scale)
    return Mesh(asset, location, rotation, scale * BIG)
end

local function BigGlow(location, color, intensity, radius)
    return Glow(location, color, intensity * BIG * BIG, radius * BIG)
end

local function Up(life_cm)
    return Vector(0, 0, life_cm * BIG)
end

-- side: 1 along +Y, -1 along -Y. x: along the wall, d: out from the wall (life size, cm)
local function Graveyard(side)
    local facing = side > 0 and 0 or 180
    local function At(x, d)
        return Vector(x, side * (SIDE_WALL + d * BIG), GROUND_Z)
    end

    -- rows of graves, leaning a little, the middle of the last one left free for the torches
    for row = 0, 2 do
        for x = -15000, 15000, 1600 * BIG do
            if row < 2 or math.abs(x) > 2600 * BIG then
                local stone = Pick({ "Tombstone1", "Tombstone2", "Tombstone3", "Tombstone1", "Tombstone3", "GraveCross" })
                Big(BTW .. stone, At(x + Random(-350, 350) * BIG, 2200 + row * 1900 + Random(-300, 300)),
                    Rotator(Random(-4, 4), facing + Random(-14, 14), Random(-5, 5)), Random(2.4, 3.2))
            end
        end
    end

    -- the crypt, between two torches
    Big(BTW .. "Crypt", At(0, 7800), Rotator(0, facing, 0), 2.6)
    for _, x in ipairs({ -1900 * BIG, 1900 * BIG }) do
        Big(BTW .. "TorchPost", At(x, 5800), Rotator(0, Random(0, 360), 0), 2.2)
        BigGlow(At(x, 5800) + Up(640), PUMPKIN_GLOW, 260, 3200)
    end

    -- dead trees behind the graves, scarecrows in front of them
    for _, x in ipairs({ -16000, -9000, -2500, 5000, 11000, 17000 }) do
        local tree = Pick({ "DeadTreeBig", "DeadTreeGnarled", "DeadTreeSnag", "DeadTreeTall" })
        Big(BTW .. tree, At(x + Random(-1500, 1500), Random(10000, 13000)), Rotator(0, Random(0, 360), 0), Random(2.2, 3.0))
    end
    for _, x in ipairs({ -9000, 6500 }) do
        Big(BTW .. "Scarecrow", At(x, 1400), Rotator(0, facing + 180 + Random(-20, 20), 0), 2.3)
    end

    -- jack-o'-lanterns lined up at the foot of the wall, every other one casting its light
    local k = 0
    for x = -12000, 12000, 1000 * BIG do
        local lantern = Pick({ "JackOLantern", "JackOLantern2", "JackOLantern3" })
        Big(BTW .. lantern, At(x + Random(-150, 150) * BIG, 700 + Random(-50, 100)), Rotator(0, Random(0, 360), 0), Random(3, 4.2))
        if k % 2 == 0 then
            BigGlow(At(x, 900) + Up(250), PUMPKIN_GLOW, 140, 2400)
        end
        k = k + 1
    end

    -- mist among the graves, wisps rising here and there
    for _ = 1, 4 do
        Mist(At(Random(-14000, 14000), Random(2500, 9000)) + Up(60), Random(18, 26) * BIG, Color(0.55, 0.5, 0.7), 0.3)
    end
    for _ = 1, 3 do
        Wisps(At(Random(-12000, 12000), Random(3000, 8000)), 7 * BIG, 9 * BIG, Theme.Slime)
    end
end

-- Behind the Witches' goal (-X): their hut, a cauldron bubbling green over a glowing pentagram ringed by
-- standing stones, totems, an effigy, a gibbet and a pile of coffins
local function Coven()
    local center = Vector(-(GOAL_BACK + 6800 * BIG), 0, GROUND_Z)
    local function At(x, y)
        return center + Vector(x * BIG, y * BIG, 0)
    end

    Sigil(center + Vector(0, 0, 6), 55 * BIG, WITCH_GLOW, 2, 5)
    Big(BTW .. "Cauldron", center, Rotator(0, 90, 0), 3.5)
    BigGlow(center + Up(650), CAULDRON_GLOW, 600, 5000)
    local steam = Mist(center + Up(700), 7 * BIG, Theme.Slime, 0.4)
    steam:SetScale(Vector(7, 7, 12) * BIG)
    Wisps(center + Up(300), 5 * BIG, 12 * BIG, Theme.Slime)

    for k = 0, 8 do
        local angle = k / 9 * math.pi * 2
        Big(BTW .. "StandingStoneRune", At(math.cos(angle) * 3300, math.sin(angle) * 3300),
            Rotator(0, math.deg(angle) + 90 + Random(-10, 10), Random(-4, 4)), Random(2.2, 2.7))
    end
    for k = 0, 5 do
        local angle = (k + 0.5) / 6 * math.pi * 2
        Big(BTW .. Pick({ "SkullPile", "SkullPile2" }), At(math.cos(angle) * 2000, math.sin(angle) * 2000),
            Rotator(0, Random(0, 360), 0), 3)
    end

    Big(BTW .. "WitchHut", At(-10500, 5500), Rotator(0, 200, 0), 2.2)
    for _, y in ipairs({ -4600, 4600 }) do
        Big(BTW .. "WitchTotem", At(4200, y), Rotator(0, 90, 0), 2.6)
        Big(BTW .. "WitchLantern", At(3400, y * 0.7), Rotator(0, Random(0, 360), 0), 2.2)
        BigGlow(At(3400, y * 0.7) + Up(560), WITCH_GLOW, 220, 3000)
    end
    Big(BTW .. "WitchEffigy", At(-4500, -7500), Rotator(0, 60, 0), 2.6)
    Big(BTW .. "Gibbet", At(-6500, 8800), Rotator(0, -30, 0), 2.4)
    Big(BTW .. "CoffinPile", At(-3000, 10500), Rotator(0, 15, 0), 2.6)
    for k = 1, 5 do
        local tree = Pick({ "DeadTreeBig", "DeadTreeGnarled", "DeadTreeSnag", "DeadTreeTall" })
        Big(BTW .. tree, At(Random(-15000, -5000), Random(9000, 15000) * (k % 2 == 0 and 1 or -1)),
            Rotator(0, Random(0, 360), 0), Random(2.4, 3.2))
    end
    for _ = 1, 3 do
        Mist(At(Random(-9000, 4000), Random(-9000, 9000)) + Up(60), Random(20, 28) * BIG, Color(0.5, 0.42, 0.7), 0.25)
    end
end

-- Behind the Skeletons' goal (+X): the Pumpkin King, a giant jack-o'-lantern staring at the arena, in a patch
-- of pumpkins with scarecrows and haystacks
local function PumpkinPatch()
    local king = Vector(GOAL_BACK + 13300 * BIG, 0, GROUND_Z)
    local function At(x, y)
        return king + Vector(x * BIG, y * BIG, 0)
    end

    Big(VFX .. "SM_FX_Pumpkin", king + Up(37 * 22), Rotator(0, 180, 0), 22)
    BigGlow(At(-1800, 0) + Up(900), PUMPKIN_GLOW, 3500, 14000)
    Sigil(king + Vector(0, 0, 6), 36 * BIG, PUMPKIN_GLOW, 1.6, 7)

    local placed = 0
    while placed < 44 do
        local x, y = Random(-11000, 6500), Random(-11000, 11000)
        if math.sqrt(x * x + y * y) > 2400 then
            local lit = Random() < 0.5
            local asset = lit and Pick({ "JackOLantern", "JackOLantern2", "JackOLantern3" }) or "Pumpkin"
            local giant = Random() < 0.12
            Big(BTW .. asset, At(x, y), Rotator(0, Random(0, 360), 0), giant and Random(7, 10) or Random(2.5, 5.5))
            placed = placed + 1
        end
    end
    for _, spot in ipairs({ { -8000, -6500 }, { -8000, 6500 }, { 4000, -8500 }, { 4000, 8500 } }) do
        Big(BTW .. "Scarecrow", At(spot[1], spot[2]), Rotator(0, 90 + Random(-25, 25), 0), 2.4)
    end
    for _, spot in ipairs({ { -5500, -10500 }, { 6000, 4000 }, { -3000, 10500 } }) do
        Big(BTW .. Pick({ "Haystack", "HayPile" }), At(spot[1], spot[2]), Rotator(0, Random(0, 360), 0), 2.2)
    end
    for k = 1, 5 do
        local tree = Pick({ "DeadTreeBig", "DeadTreeGnarled", "DeadTreeSnag", "DeadTreeTall" })
        Big(BTW .. tree, At(Random(500, 10500), Random(12000, 17000) * (k % 2 == 0 and 1 or -1)),
            Rotator(0, Random(0, 360), 0), Random(2.4, 3.2))
    end
    for _ = 1, 3 do
        Wisps(At(Random(-10000, 5500), Random(-10000, 10000)), 6 * BIG, 8 * BIG, PUMPKIN_GLOW)
    end
end

-- Dead trees and a few autumn ones all round the horizon, beyond everything else
local function Horizon()
    for k = 0, 35 do
        local angle = (k + Random(-0.3, 0.3)) / 36 * math.pi * 2
        local distance = Random(100000, 140000)
        local tree = Random() < 0.75 and Pick({ "FarTreeDead1", "FarTreeDead2" }) or Pick({ "FarTreeAutumn1", "FarTreeAutumn2" })
        Big(BTW .. tree, Vector(math.cos(angle) * distance, math.sin(angle) * distance, GROUND_Z),
            Rotator(0, Random(0, 360), 0), Random(4, 6.5))
    end
end

-- Inside: the magic circles on the pitch and fallen leaves blown about
local function Pitch()
    Sigil(Vector(0, 0, FLOOR_Z + 8), 26, Theme.Slime, 0.8, 7)
    -- the goals' floor is flat from their mouth (X 12050) to about 13780, where it curves up into the back wall
    Sigil(Vector(-12900, 0, FLOOR_Z + 8), 15, Theme.Teams[1].color, 1.2, 5)
    Sigil(Vector(12900, 0, FLOOR_Z + 8), 15, Theme.Teams[2].color, 1.2, 7)

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
