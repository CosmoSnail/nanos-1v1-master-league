-- Sounds of the Halloween edition: Client/Sounds, made by tools/make_sounds.py (bell, ghost_boo and ghost_wail
-- come from burn-the-witch); outside, an owl or a wolf now and then. The music is the regular season's soundtrack
local SoundsDir = "package://" .. Package.GetName() .. "/Client/Sounds/"

local MUSIC_VOLUME = 0.25
local MUSIC_DUCKED = 0.03
local GOAL_SOUNDS = { "goal_toccata.ogg", "goal_bells.ogg", "goal_theremin.ogg", "goal_danse.ogg" }
local GOAL_VOLUME = 0.6
local GOAL_DUCK_TIME = 7000     -- ms the music stays low after a goal
-- After a goal, now and then: the mannequin's laughs pitched down into an evil one for the Skeletons, a cackle
-- for the Witches
local LAUGHS = {
    "nanos-world::A_Male_01_Laugh", "nanos-world::A_Male_02_Laugh", "nanos-world::A_Male_03_Laugh",
    "nanos-world::A_Male_04_Laugh", "nanos-world::A_Male_05_Laugh", "nanos-world::A_Male_06_Laugh",
}
local CACKLES = { "nanos-world::A_Female_01_Laugh", "nanos-world::A_Female_02_Laugh" }

local music = nil
local duck_timer = nil

function PlaySound2D(file, volume, pitch)
    return Sound(Vector(), SoundsDir .. file, true, true, SoundType.SFX, volume or 1, pitch or 1)
end

-- Heard from far: the arena is 280 m long
function PlaySound3D(file, location, volume, pitch, falloff)
    return Sound(location, SoundsDir .. file, false, true, SoundType.SFX, volume or 1, pitch or 1, 2000, falloff or 25000,
        AttenuationFunction.NaturalSound)
end

function StartSoundtrack()
    music = Sound(Vector(), SoundsDir .. "Soundtrack_1.ogg", true, false, SoundType.Music, MUSIC_VOLUME, 1, 400, 3600,
        AttenuationFunction.Linear, false, SoundLoopMode.Forever, true)
end

-- team: who scored (1 Witches, 2 Skeletons)
function PlayGoalSound(team)
    if duck_timer then
        Timer.ClearTimeout(duck_timer)
    end
    if music and music:IsValid() then music:SetVolume(MUSIC_DUCKED) end

    PlaySound2D(GOAL_SOUNDS[math.random(#GOAL_SOUNDS)], GOAL_VOLUME)
    if math.random() < 0.6 then
        Timer.SetTimeout(function()
            if team == 1 then
                Sound(Vector(), CACKLES[math.random(#CACKLES)], true, true, SoundType.SFX, 0.7, 1.05 + math.random() * 0.1)
            else
                Sound(Vector(), LAUGHS[math.random(#LAUGHS)], true, true, SoundType.SFX, 0.8, 0.55 + math.random() * 0.12)
            end
        end, 1300)
    end

    duck_timer = Timer.SetTimeout(function()
        duck_timer = nil
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

-- The pumpkin hit (Client/PumpkinBall.lua): strength 0 to 1
function PlayBonk(location, strength)
    PlaySound3D("bonk_" .. math.random(1, 3) .. ".ogg", location, 0.35 + 0.65 * strength, 0.9 + math.random() * 0.25, 9000)
end

-- An owl or a distant wolf now and then
local function StartAmbience()
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
