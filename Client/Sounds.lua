local ScoreSounds = {
    "package://nanos-1v1-master-league/Client/Sounds/GoalBuzzer_1.ogg",
    "package://nanos-1v1-master-league/Client/Sounds/GoalBuzzer_2.ogg",
    "package://nanos-1v1-master-league/Client/Sounds/GoalBuzzer_3.ogg",
    "package://nanos-1v1-master-league/Client/Sounds/GoalBuzzer_4.ogg",
}

local soundtrack
local goalSoundTime
local soundTrackVolume = 0.25
local buzzerVolume = 0.3

function StartSoundtrack()
    soundtrack = Sound(Vector(), "package://nanos-1v1-master-league/Client/Sounds/Soundtrack_1.mp3", true, false, true, SoundType.Music)
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