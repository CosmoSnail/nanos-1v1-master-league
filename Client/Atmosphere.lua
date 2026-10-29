-- The Halloween night over the arena: a night sky instead of space, a huge harvest moon with a witch flying
-- across it (Client/Images/moon.png), purple clouds and a thin mist. Lightning strikes round the graveyard
-- when the server says so (Server/Weather.lua). In the Witching Hour, the last minute, the moon turns to
-- blood, the colors go red, the music speeds up and the midnight bell tolls
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
    fog = 5,                            -- 0 to 100: the arena is 280 m long, a little goes a long way (/fog to try)
}
local WITCHING = {
    cloud_color = Color(0.75, 0.25, 0.22),
    fog = 7,
    saturation = Color(1.15, 0.75, 0.75, 1),
    gain = Color(1.12, 0.85, 0.82, 1),
    contrast = Color(1.08, 1.08, 1.08, 1),
}
local LIGHTNING_BOLTS = {
    "nanos-world::P_FXVariety_Lightning_01",
    "nanos-world::P_FXVariety_Lightning_02",
    "nanos-world::P_FXVariety_Lightning_03",
}

local witching = false

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
        Sky.SetMoonTexture(IMAGES .. "moon.png")
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

local function SetGrading(on)
    Try("witching hour grading", function()
        PostProcess.SetGlobalSaturation(on and WITCHING.saturation or Color(1, 1, 1, 1))
        PostProcess.SetGlobalGain(on and WITCHING.gain or Color(1, 1, 1, 1))
        PostProcess.SetGlobalContrast(on and WITCHING.contrast or Color(1, 1, 1, 1))
    end)
end

-- announce: it is starting now (the bell and the HUD banner), not a player joining in the middle of it
function SetWitchingHour(on, announce)
    if on == witching then return end
    witching = on
    Try("blood moon", function()
        Sky.SetMoonTexture(IMAGES .. (on and "moon_blood.png" or "moon.png"))
        Sky.SetVolumetricCloudColor(on and WITCHING.cloud_color or NIGHT.cloud_color)
        Sky.SetFog(on and WITCHING.fog or NIGHT.fog)
    end)
    SetGrading(on)
    SetWitchingMusic(on)
    if on and announce then
        PlayMidnightBell()
    end
    Events.Call("WitchingHour", on, on and announce)
end

-- From the game timer: on for the last minute and through the end screen, off when a new game starts
function UpdateWitchingHour(time)
    local on = time <= Theme.WitchingHour
    SetWitchingHour(on, time >= Theme.WitchingHour - 2)
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

-- /fog (dev): try another density of mist live; the Witching Hour keeps its own a little thicker
Events.SubscribeRemote("DevFog", function(value)
    if type(value) ~= "number" then return end
    WITCHING.fog = value + (WITCHING.fog - NIGHT.fog)
    NIGHT.fog = value
    Try("Sky.SetFog", function() Sky.SetFog(witching and WITCHING.fog or NIGHT.fog) end)
end)

Events.SubscribeRemote("NewGame", function()
    SetWitchingHour(false, false)
end)

Package.Subscribe("Unload", function()
    SetGrading(false)
end)

InitSky()
