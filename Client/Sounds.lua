local SoundsDir = "package://" .. Package.GetName() .. "/Client/Sounds/"

local ScoreSounds = {
    SoundsDir .. "GoalBuzzer_1.ogg",
    SoundsDir .. "GoalBuzzer_2.ogg",
    SoundsDir .. "GoalBuzzer_3.ogg",
    SoundsDir .. "GoalBuzzer_4.ogg",
}

local soundtrack
local goalSoundTime
local soundTrackVolume = 0.25
local buzzerVolume = 0.3

function StartSoundtrack()
    soundtrack = Sound(Vector(), SoundsDir .. "Soundtrack_1.mp3", true, false, SoundType.Music, 1, 1, 400, 3600, AttenuationFunction.Linear, false, SoundLoopMode.Forever, true)
    soundtrack:SetVolume(soundTrackVolume)
end

function PlayRandomScoreSound()
    if goalSoundTime then
        Timer.ClearTimeout(goalSoundTime)
    end
    soundtrack:SetVolume(0.01)
    local buzzerSound = Sound(Vector(), ScoreSounds[math.random(#ScoreSounds)], true)
    buzzerSound:SetVolume(buzzerVolume)
    buzzerSound:FadeOut(20, 0.0, true)

    goalSoundTime = Timer.SetTimeout(function()
        soundtrack:SetVolume(soundTrackVolume)
    end, 20000)
end

function PlayEndSound()
    Sound(Vector(), SoundsDir .. "EndBuzzer.wav", true)
end