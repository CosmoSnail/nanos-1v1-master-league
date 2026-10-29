-- The Halloween night over the arena: a night sky instead of space, a huge harvest moon with a witch flying
-- across it, purple clouds and a thin mist. Lightning strikes round the graveyard when the server says so
-- (Server/Weather.lua, more and more often as a game goes on).
-- The night deepens through each game, little by little and without a word: from a third of the way in, the
-- moon turns from orange to blood red (Client/Images/moon_0 to moon_4), the clouds redden, the mist thickens
-- and the colors warm towards red. It is only the mood rising to the end of the game, nothing changes in the
-- rules
local IMAGES = "package://" .. Package.GetName() .. "/Client/Images/"
local RENDER_CULL_DISTANCE = 1000000

-- The night, to tune the look and how bright the pitch is
local NIGHT = {
    hours = 23, minutes = 40,
    moon_scale = 6,
    moon_yaw = 60, moon_pitch = 28,     -- low over the side of the pitch, seen through the dome
    moon_glow = 4,
    moon_light = 40,                    -- the moon lights the pitch (the space sky had 250)
    night_brightness = 1.6,
    clouds = 3.5,                       -- 0 (clear) to 10 (overcast)
    cloud_color = Color(0.55, 0.42, 0.8),
    fog = 8,                            -- 0 to 100: the arena is 280 m long, a little goes a long way (/fog to try)
}
-- Where the night ends up when time runs out
local LATE = {
    cloud_color = Color(0.75, 0.25, 0.22),
    fog = 10,
    saturation = Color(1.15, 0.75, 0.75, 1),
    gain = Color(1.12, 0.85, 0.82, 1),
    contrast = Color(1.08, 1.08, 1.08, 1),
}
local DEEPEN_FROM = 0.3         -- of the game played when the night starts to deepen
local MOONS = 5                 -- moon_0.png (harvest) to moon_4.png (blood)
local LIGHTNING_BOLTS = {
    "nanos-world::P_FXVariety_Lightning_01",
    "nanos-world::P_FXVariety_Lightning_02",
    "nanos-world::P_FXVariety_Lightning_03",
}

local depth = 0                 -- how deep the night is: 0 (a game starts) to 1 (time is up)
local moon = 0                  -- the moon picture on show

-- Runs fn, logging (instead of hiding) any error from the sky / post-process API
local function Try(what, fn)
    local ok, err = pcall(fn)
    if not ok then
        Console.Warn("[Monster League] " .. what .. " failed: " .. tostring(err))
    end
end

function InitSky()
    -- Always a fresh sky actor: reusing the one left by a package reload (find_existing) brought back
    -- the default sky
    Try("sky setup", function()
        Sky.Spawn(false, false)
        Sky.SetSkyMode(SkyMode.VolumetricClouds)
        Sky.SetAnimateTimeOfDay(false)
        -- a transition of 0 is ignored by the sky: a jump blends over a single frame instead
        Sky.SetTimeOfDay(NIGHT.hours, NIGHT.minutes, 0.01)
        Sky.SetMoonTexture(IMAGES .. "moon_0.png")
        Sky.SetMoonPhase(15)
        Sky.SetMoonScale(NIGHT.moon_scale)
        Sky.SetMoonAngle(NIGHT.moon_yaw, NIGHT.moon_pitch)
        Sky.SetMoonGlowIntensity(NIGHT.moon_glow)
        Sky.SetMoonLightIntensity(NIGHT.moon_light)
        Sky.SetNightBrightness(NIGHT.night_brightness)
        Sky.SetCloudCoverage(NIGHT.clouds)
        Sky.SetVolumetricCloudColor(NIGHT.cloud_color)
        Sky.SetFog(NIGHT.fog)
        Sky.Reconstruct()
    end)
end

local function Lerp(a, b, k)
    return a + (b - a) * k
end

local function LerpColor(a, b, k)
    return Color(Lerp(a.R, b.R, k), Lerp(a.G, b.G, k), Lerp(a.B, b.B, k), Lerp(a.A, b.A, k))
end

local WHITE = Color(1, 1, 1, 1)

-- The sky and the colors for a night `k` deep (0 to 1)
local function SetDepth(k)
    depth = k
    Try("night sky", function()
        Sky.SetVolumetricCloudColor(LerpColor(NIGHT.cloud_color, LATE.cloud_color, k))
        Sky.SetFog(Lerp(NIGHT.fog, LATE.fog, k))
        local index = math.floor(k * (MOONS - 1) + 0.5)
        if index ~= moon then
            moon = index
            Sky.SetMoonTexture(IMAGES .. "moon_" .. index .. ".png")
        end
    end)
    Try("night grading", function()
        PostProcess.SetGlobalSaturation(LerpColor(WHITE, LATE.saturation, k))
        PostProcess.SetGlobalGain(LerpColor(WHITE, LATE.gain, k))
        PostProcess.SetGlobalContrast(LerpColor(WHITE, LATE.contrast, k))
    end)
end

-- From the game timer, every second: the night deepens smoothly from DEEPEN_FROM of the game to its end, and
-- stays so through the end screen
function UpdateNight(time)
    local played = 1 - time / math.max(Theme.GameLength, time, 1)
    local k = math.max(0, math.min(1, (played - DEEPEN_FROM) / (1 - DEEPEN_FROM)))
    SetDepth(k * k * (3 - 2 * k))
end

-- A lightning strike: the bolt far out over the graveyard, the pitch and the sky flashing twice, and the
-- thunder a moment later (the farther, the later)
Events.SubscribeRemote("Lightning", function(location, seed)
    if type(seed) ~= "number" then return end

    local bolt = Particle(location, Rotator(0, seed % 360, 0), LIGHTNING_BOLTS[seed % #LIGHTNING_BOLTS + 1], true, true)
    bolt:SetScale(Vector(45))
    bolt:SetRenderCullDistance(RENDER_CULL_DISTANCE)

    -- the flash comes from above the dome, on the strike's side
    local side = Vector(location.X, location.Y, 0):GetSafeNormal()
    local flash = Light(side * 15000 + Vector(0, 0, 9000), Rotator(), Color(0.72, 0.78, 1.0), LightType.Point,
        0, 45000, 44, 0, 200000, true, false, true)
    local steps = { { 0, 1.0 }, { 70, 0.15 }, { 140, 0.8 }, { 260, 0 } }
    for _, step in ipairs(steps) do
        Timer.SetTimeout(function()
            if flash:IsValid() then flash:SetIntensity(60000 * step[2]) end
            Try("sky flash", function() Sky.SetOverallIntensity(1 + 1.5 * step[2]) end)
        end, step[1])
    end
    Timer.SetTimeout(function()
        if flash:IsValid() then flash:Destroy() end
    end, 400)

    local player = Client.GetLocalPlayer()
    local distance = player and (player:GetCameraLocation() - location):Size() or 40000
    PlayThunder(seed, distance)
end)

-- /fog (dev): try another density of mist live; late in the game it stays as much thicker as before
Events.SubscribeRemote("DevFog", function(value)
    if type(value) ~= "number" then return end
    LATE.fog = value + (LATE.fog - NIGHT.fog)
    NIGHT.fog = value
    SetDepth(depth)
end)

-- A new game: the night starts over
Events.SubscribeRemote("NewGame", function()
    SetDepth(0)
end)

Package.Subscribe("Unload", function()
    SetDepth(0)
end)

InitSky()
