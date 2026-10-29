-- What moves in the Halloween night, on each client (nothing on the network): bats circling over the dome,
-- a witch on her broom crossing the sky now and then, ghosts drifting under the arena's ceiling, and a goal's
-- celebration: a flash in the scorers' color, the pumpkin bursts into a shower of little pumpkins (and bones
-- for the Skeletons, a swarm of bats for the Witches) and ghosts fly up out of the goal, wailing

local IMAGES = "package://" .. Package.GetName() .. "/Client/Images/"
local VFX = "burn-the-witch-vfx::"
local GHOST = "nanos-world::SM_Ghost"
local SPRITE_MATERIAL = "nanos-world::M_Default_Translucent_Unlit"
local RENDER_CULL_DISTANCE = 1000000

local BAT_FRAMES = { IMAGES .. "bat_1.png", IMAGES .. "bat_2.png" }
local BAT_FLAP = 0.11                       -- seconds per wing beat frame
local WITCH_EVERY = { 45000, 100000 }       -- ms between two flights of the witch
local WITCH_FLIGHT = 15                     -- seconds to cross the sky
local WITCH_CACKLES = { "nanos-world::A_Female_01_Laugh", "nanos-world::A_Female_02_Laugh" }
local GHOST_COLOR = Color(0.6, 1.0, 0.8)
local BURST_PUMPKINS = 24
local BURST_BONES = 22
local BURST_BATS = 28
local BAT_FLEE_TIME = 3.5                   -- seconds the bats of a goal fly before they are gone
-- the flash in the goal, by the team that scored: witch purple, the Skeletons' soul fire (Client/BoostFX.lua)
local GOAL_FLASH = { [1] = Color(0.6, 0.2, 1.0), [2] = Color(0.45, 0.8, 1.0) }
local GOAL_FLASH_INTENSITY = 4000
local GOAL_FLASH_TIME = 1.4                 -- seconds
-- the default pack's skeleton, in pieces
local BONES = {
    "nanos-world::SM_HumanSkeleton_Head_Full", "nanos-world::SM_HumanSkeleton_Femur",
    "nanos-world::SM_HumanSkeleton_RibCage", "nanos-world::SM_HumanSkeleton_Pelvis",
    "nanos-world::SM_HumanSkeleton_Humerus", "nanos-world::SM_HumanSkeleton_Tibia",
}
local RISING_GHOSTS = 9
local RISE_TIME = 4                         -- seconds

local bats = {}
local fleeing = {}      -- the bats of a goal
local drifting = {}     -- the ghosts in the arena
local rising = {}       -- the ghosts of a goal
local witch = nil

local function Rand(a, b)
    return a + (b - a) * math.random()
end

local function Ghost(location, scale)
    local mesh = StaticMesh(location, Rotator(0, Rand(0, 360), 0), GHOST, CollisionType.NoCollision)
    mesh:SetMaterial(VFX .. "M_FX_Ghost")
    mesh:SetMaterialColorParameter("Color", GHOST_COLOR)
    mesh:SetMaterialScalarParameter("Intensity", 1.5)
    mesh:SetMaterialScalarParameter("Opacity", 0.55)
    mesh:SetMaterialScalarParameter("Wisps", 1)
    mesh:SetMaterialScalarParameter("Fade", 1)
    mesh:SetScale(Vector(scale))
    mesh:SetCastShadow(false)
    mesh:SetRenderCullDistance(RENDER_CULL_DISTANCE)
    return mesh
end

local function Sprite(location, texture, width, height)
    local sprite = Billboard(location, SPRITE_MATERIAL, Vector2D(width, height), false)
    sprite:SetMaterialTextureParameter("Texture", texture)
    sprite:SetMaterialScalarParameter("Opacity", 1)
    sprite:SetRenderCullDistance(RENDER_CULL_DISTANCE)
    return sprite
end

-- Three flocks of bats circling over the dome at different heights, one of them the other way round
for flock = 1, 3 do
    local center = Vector(({ -6000, 3000, 9000 })[flock], ({ 2000, -3000, 1000 })[flock], 0)
    local speed = (flock == 2 and -1 or 1) * (0.1 + flock * 0.02)  -- radians per second
    for k = 1, 8 do
        local size = Rand(380, 620)
        table.insert(bats, {
            sprite = Sprite(center, BAT_FRAMES[1], size, size * 0.5),
            center = center,
            radius = 7000 + flock * 2500 + Rand(-1500, 1500),
            height = 5200 + flock * 900 + Rand(-500, 500),
            speed = speed * Rand(0.85, 1.15),
            angle = k * 0.2 + flock * 2,
            frame = 1,
            flap = Rand(0, BAT_FLAP),
            wobble = Rand(0, 10),
        })
    end
end

-- Ghosts drifting round under the ceiling, each on its own slow loop
for k = 1, 6 do
    table.insert(drifting, {
        mesh = Ghost(Vector(0, 0, 3000), Rand(2.6, 3.4)),
        ax = Rand(5000, 10000), ay = Rand(3000, 6000),
        fx = Rand(0.03, 0.06), fy = Rand(0.04, 0.07),
        phase = k * 1.7,
        z = Rand(2500, 3400),
        last = nil,
    })
end

-- The witch crosses the sky on a straight line high over the arena, cackling as she passes
local function WitchFlight()
    local angle = Rand(0, math.pi * 2)
    local direction = Vector(math.cos(angle), math.sin(angle), 0)
    local offset = Vector(-direction.Y, direction.X, 0) * Rand(-9000, 9000)
    local height = Rand(7500, 10000)
    witch = {
        sprite = Sprite(direction * -42000 + offset + Vector(0, 0, height), IMAGES .. "witch.png", 2000, 1000),
        from = direction * -42000 + offset + Vector(0, 0, height),
        to = direction * 42000 + offset + Vector(0, 0, height + Rand(-1500, 1500)),
        direction = direction,
        time = 0,
        left = false,
        cackled = false,
    }
end

local function ScheduleWitch()
    Timer.SetTimeout(function()
        if not witch then WitchFlight() end
        ScheduleWitch()
    end, math.random(WITCH_EVERY[1], WITCH_EVERY[2]))
end
ScheduleWitch()

local function UpdateBats(dt, now)
    for _, bat in ipairs(bats) do
        bat.angle = bat.angle + bat.speed * dt
        local bob = math.sin(now * 1.7 + bat.wobble) * 300
        bat.sprite:SetLocation(bat.center + Vector(math.cos(bat.angle) * bat.radius, math.sin(bat.angle) * bat.radius, bat.height + bob))
        bat.flap = bat.flap - dt
        if bat.flap <= 0 then
            bat.flap = BAT_FLAP
            bat.frame = 3 - bat.frame
            bat.sprite:SetMaterialTextureParameter("Texture", BAT_FRAMES[bat.frame])
        end
    end
end

-- The bats of a goal fly out of it, climbing as they go, and fade away
local function UpdateFleeingBats(dt)
    for i = #fleeing, 1, -1 do
        local bat = fleeing[i]
        bat.time = bat.time + dt
        if bat.time >= BAT_FLEE_TIME or not bat.sprite:IsValid() then
            if bat.sprite:IsValid() then bat.sprite:Destroy() end
            table.remove(fleeing, i)
        else
            bat.velocity = bat.velocity + Vector(0, 0, 1200 * dt)
            bat.location = bat.location + bat.velocity * dt
            bat.sprite:SetLocation(bat.location + Vector(0, 0, math.sin(bat.time * 9 + bat.wobble) * 120))
            bat.sprite:SetMaterialScalarParameter("Opacity", math.min(1, (BAT_FLEE_TIME - bat.time) * 2))
            bat.flap = bat.flap - dt
            if bat.flap <= 0 then
                bat.flap = BAT_FLAP * 0.6
                bat.frame = 3 - bat.frame
                bat.sprite:SetMaterialTextureParameter("Texture", BAT_FRAMES[bat.frame])
            end
        end
    end
end

local function UpdateWitch(dt)
    if not witch then return end
    witch.time = witch.time + dt
    local k = witch.time / WITCH_FLIGHT
    if k >= 1 or not witch.sprite:IsValid() then
        if witch.sprite:IsValid() then witch.sprite:Destroy() end
        witch = nil
        return
    end
    witch.sprite:SetLocation(witch.from + (witch.to - witch.from) * k + Vector(0, 0, math.sin(k * 9) * 250))

    -- she looks the way she flies on the screen: the picture faces right, its mirror left
    local player = Client.GetLocalPlayer()
    if player then
        local left = witch.direction:Dot(player:GetCameraRotation():GetRightVector()) < 0
        if left ~= witch.left then
            witch.left = left
            witch.sprite:SetMaterialTextureParameter("Texture", IMAGES .. (left and "witch_left.png" or "witch.png"))
        end
    end
    if not witch.cackled and k > 0.4 then
        witch.cackled = true
        Sound(Vector(), WITCH_CACKLES[math.random(#WITCH_CACKLES)], true, true, SoundType.SFX, 0.35, 1.35)
    end
end

local function UpdateGhosts(dt, now)
    for _, ghost in ipairs(drifting) do
        local location = Vector(
            math.sin(now * ghost.fx + ghost.phase) * ghost.ax,
            math.cos(now * ghost.fy + ghost.phase * 1.3) * ghost.ay,
            ghost.z + math.sin(now * 0.8 + ghost.phase) * 160
        )
        if ghost.last then
            local heading = location - ghost.last
            ghost.mesh:SetRotation(Rotator(0, math.deg(math.atan(heading.Y, heading.X)), 0))
        end
        ghost.mesh:SetLocation(location)
        ghost.last = location
    end

    for i = #rising, 1, -1 do
        local ghost = rising[i]
        ghost.time = ghost.time + dt
        local k = math.max(0, ghost.time) / RISE_TIME    -- each starts a little after the one before
        if k >= 1 or not ghost.mesh:IsValid() then
            if ghost.mesh:IsValid() then ghost.mesh:Destroy() end
            table.remove(rising, i)
        else
            local spin = ghost.angle + k * 5
            ghost.mesh:SetLocation(ghost.from + Vector(math.cos(spin) * ghost.radius * k, math.sin(spin) * ghost.radius * k, k * 3200))
            ghost.mesh:SetRotation(Rotator(0, math.deg(spin) + 90, 0))
            ghost.mesh:SetMaterialScalarParameter("Fade", math.min(1, (1 - k) * 3))
        end
    end
end

Client.Subscribe("Tick", function(dt)
    if dt <= 0 then return end
    local now = Client.GetTime() / 1000
    UpdateBats(dt, now)
    UpdateFleeingBats(dt)
    UpdateWitch(dt)
    UpdateGhosts(dt, now)
end)

-- Something flung out of the goal, bouncing round it (local physics). It only collides with the arena: the
-- ball is so light that a pumpkin still rolling on the pitch would shove the next one off the centre spot, and
-- it is gone before the next kickoff anyway (Config.ScoredDuration is 7 s, the ball comes back after 6 to 7)
local function Fling(location, asset, scale)
    local towards_pitch = location.X > 0 and -1 or 1
    local prop = Prop(location + Vector(Rand(-250, 250), Rand(-250, 250), Rand(0, 300)), Rotator(Rand(0, 360), Rand(0, 360), 0),
        asset, CollisionType.StaticOnly, true, GrabMode.Disabled, CCDMode.Auto)
    prop:SetScale(Vector(scale))
    prop:SetMassScale(0.1)
    prop:SetLifeSpan(5.5)
    prop:SetRenderCullDistance(RENDER_CULL_DISTANCE)
    local direction = Vector(towards_pitch * Rand(0.2, 1), Rand(-1, 1), Rand(0.6, 1.4)):GetSafeNormal()
    prop:AddImpulse(direction * Rand(2200, 4200), true)
end

-- A swarm of bats bursting out of the goal towards the pitch
local function BatBurst(location)
    local towards_pitch = location.X > 0 and -1 or 1
    for _ = 1, BURST_BATS do
        local size = Rand(300, 520)
        local direction = Vector(towards_pitch * Rand(0.3, 1.2), Rand(-1, 1), Rand(0.4, 1.2)):GetSafeNormal()
        local from = location + Vector(Rand(-200, 200), Rand(-200, 200), Rand(0, 300))
        table.insert(fleeing, {
            sprite = Sprite(from, BAT_FRAMES[1], size, size * 0.5),
            location = from,
            velocity = direction * Rand(2500, 4500),
            time = 0,
            frame = 1,
            flap = Rand(0, BAT_FLAP),
            wobble = Rand(0, 10),
        })
    end
end

-- A flash in the goal in the scorers' color, fading out
local function GoalFlash(location, team)
    local light = Light(location + Vector(0, 0, 600), Rotator(), GOAL_FLASH[team] or GHOST_COLOR, LightType.Point,
        GOAL_FLASH_INTENSITY, 9000, 44, 0, 200000, true, false, true)
    local steps = 14
    for k = 1, steps do
        Timer.SetTimeout(function()
            if light:IsValid() then light:SetIntensity(GOAL_FLASH_INTENSITY * (1 - k / steps) ^ 2) end
        end, math.floor(k / steps * GOAL_FLASH_TIME * 1000))
    end
    Timer.SetTimeout(function()
        if light:IsValid() then light:Destroy() end
    end, math.floor(GOAL_FLASH_TIME * 1000) + 100)
end

-- A goal: a flash, little pumpkins burst out of the big one, bones too when the Skeletons (team 2) scored,
-- rattling, bats when the Witches (team 1) did, and ghosts spiral up out of it
local function Celebrate(location, team)
    GoalFlash(location, team)
    for _ = 1, BURST_PUMPKINS do
        Fling(location, "nanos-world::SM_Fruit_Pumpkin_01", Rand(2.5, 5))
    end
    if team == 2 then
        for _ = 1, BURST_BONES do
            Fling(location, BONES[math.random(#BONES)], Rand(3.5, 5.5))
        end
        Sound(location, "nanos-world::A_Skeleton_Falling", false, true, SoundType.SFX, 1, Rand(0.8, 0.95), 2000, 40000,
            AttenuationFunction.NaturalSound)
    elseif team == 1 then
        BatBurst(location)
    end

    for k = 1, RISING_GHOSTS do
        table.insert(rising, {
            mesh = Ghost(location, Rand(2.2, 3.2)),
            from = location,
            angle = k / RISING_GHOSTS * math.pi * 2,
            radius = Rand(900, 2000),
            time = -k * 0.1,
        })
    end
    PlaySound3D("ghost_wail.ogg", location, 1, Rand(0.9, 1.1), 40000)
end

Events.SubscribeRemote("GoalScored", function(info)
    local location = (type(info) == "table" and info.x) and Vector(info.x, info.y, info.z) or GetPumpkinLocation()
    if location then
        Celebrate(location, type(info) == "table" and info.team or nil)
    end
end)
