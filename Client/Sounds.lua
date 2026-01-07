local ScoreSounds = {
    "package://nanos-1v1-master-league/Client/Sounds/GoalBuzzer_1.ogg",
    "package://nanos-1v1-master-league/Client/Sounds/GoalBuzzer_2.ogg"
}

local soundtrack

function StartSoundtrack()
    soundtrack = Sound(Vector(), "package://nanos-1v1-master-league/Client/Sounds/Soundtrack_1.mp3", true, false, true, SoundType.Music)
    soundtrack:SetVolume(0.25)
end

function PlayRandomScoreSound()
    soundtrack:SetVolume(0.01)
    local BuzzerSound = Sound(Vector(), ScoreSounds[math.random(#ScoreSounds)], true)
    BuzzerSound:SetVolume(0.5)
    BuzzerSound:FadeOut(20, 0.0, true)

    Timer.SetTimeout(function()
        soundtrack:SetVolume(0.25)
    end, 20000)
end