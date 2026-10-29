-- Music and sounds of the Halloween edition: Client/Sounds, made by tools/make_sounds.py (bell, ghost_boo and
-- ghost_wail come from burn-the-witch). The music is "In the Hall of the Mountain King", building up into a
-- much faster version for the last minute; the night outside has wind, owls and a wolf now and then
local SoundsDir = "package://" .. Package.GetName() .. "/Client/Sounds/"

local MUSIC_VOLUME = 0.3
local MUSIC_DUCKED = 0.04
local GOAL_SOUNDS = { "goal_toccata.ogg", "goal_bells.ogg", "goal_theremin.ogg", "goal_danse.ogg" }
local GOAL_VOLUME = 0.6
local GOAL_DUCK_TIME = 7000     -- ms the music stays low after a goal
-- the mannequin's laughs, pitched down into an evil one
local LAUGHS = {
    "nanos-world::A_Male_01_Laugh", "nanos-world::A_Male_02_Laugh", "nanos-world::A_Male_03_Laugh",
    "nanos-world::A_Male_04_Laugh", "nanos-world::A_Male_05_Laugh", "nanos-world::A_Male_06_Laugh",
}
local AMBIENT_VOLUME = 0.22

local music = nil
local music_file = nil
local ducked = false
local duck_timer = nil

function PlaySound2D(file, volume, pitch)
    return Sound(Vector(), SoundsDir .. file, true, true, SoundType.SFX, volume or 1, pitch or 1)
end

-- Heard from far: the arena is 280 m long
function PlaySound3D(file, location, volume, pitch, falloff)
    return Sound(location, SoundsDir .. file, false, true, SoundType.SFX, volume or 1, pitch or 1, 2000, falloff or 25000,
        AttenuationFunction.NaturalSound)
end

local function MusicVolume()
    return ducked and MUSIC_DUCKED or MUSIC_VOLUME
end

-- Swaps the looping track, fading the old one out and the new one in over `fade` seconds
local function StartMusic(file, fade)
    if music_file == file then return end
    fade = fade or 1.5
    if music and music:IsValid() then
        music:FadeOut(fade, 0, true)
    end
    music_file = file
    music = Sound(Vector(), SoundsDir .. file, true, false, SoundType.Music, MusicVolume(), 1, 400, 3600,
        AttenuationFunction.Linear, false, SoundLoopMode.Forever, false)
    music:FadeIn(fade, MusicVolume())
end

function StartSoundtrack()
    StartMusic("music_main.ogg")
end

-- The last minute of a game (Client/Atmosphere.lua): the faster version swells in slowly, no announcement
function SetFinaleMusic(on)
    StartMusic(on and "music_finale.ogg" or "music_main.ogg", on and 8 or 1.5)
end

function PlayGoalSound()
    if duck_timer then
        Timer.ClearTimeout(duck_timer)
    end
    ducked = true
    if music and music:IsValid() then music:SetVolume(MUSIC_DUCKED) end

    PlaySound2D(GOAL_SOUNDS[math.random(#GOAL_SOUNDS)], GOAL_VOLUME)
    if math.random() < 0.6 then
        Timer.SetTimeout(function()
            Sound(Vector(), LAUGHS[math.random(#LAUGHS)], true, true, SoundType.SFX, 0.8, 0.55 + math.random() * 0.12)
        end, 1300)
    end

    duck_timer = Timer.SetTimeout(function()
        duck_timer = nil
        ducked = false
        if music and music:IsValid() then music:SetVolume(MUSIC_VOLUME) end
    end, GOAL_DUCK_TIME)
end

function PlayEndSound()
    PlaySound2D("end_organ.ogg", 0.7)
    PlaySound2D("bell.ogg", 0.5, 0.85)
end

-- 3, 2, 1: a clock bell rising in pitch; 0: the big bell, and a wolf answers sometimes
function PlayCountdownSound(seconds)
    if seconds > 0 then
        PlaySound2D("countdown_tick.ogg", 0.45, 1.12 - seconds * 0.06)
    else
        PlaySound2D("countdown_go.ogg", 0.5)
        if math.random() < 0.35 then
            Timer.SetTimeout(function() PlaySound2D("wolf_howl.ogg", 0.3, 0.9 + math.random() * 0.2) end, 700)
        end
    end
end

-- Thunder after a lightning strike `distance` cm away: sound is slower than light
function PlayThunder(seed, distance)
    local delay = math.floor(distance / 34300 * 1000)
    local volume = math.max(0.35, math.min(0.9, 1.3 - distance / 60000))
    Timer.SetTimeout(function()
        PlaySound2D("thunder_" .. (seed % 3 + 1) .. ".ogg", volume, 0.85 + (seed % 7) * 0.04)
    end, delay)
end

-- The pumpkin hit (Client/PumpkinBall.lua): strength 0 to 1
function PlayBonk(location, strength)
    PlaySound3D("bonk_" .. math.random(1, 3) .. ".ogg", location, 0.35 + 0.65 * strength, 0.9 + math.random() * 0.25, 9000)
end

-- Wind round the dome all the time, an owl or a distant wolf now and then
local function StartAmbience()
    Sound(Vector(), SoundsDir .. "wind_loop.ogg", true, false, SoundType.Ambient, AMBIENT_VOLUME, 1, 400, 3600,
        AttenuationFunction.Linear, false, SoundLoopMode.Forever, true)

    local function Owl()
        Timer.SetTimeout(function()
            if math.random() < 0.7 then
                PlaySound2D("owl.ogg", 0.18, 0.92 + math.random() * 0.16)
            else
                PlaySound2D("wolf_howl.ogg", 0.12, 0.85 + math.random() * 0.2)
            end
            Owl()
        end, math.random(25000, 60000))
    end
    Owl()
end

StartSoundtrack()
StartAmbience()
