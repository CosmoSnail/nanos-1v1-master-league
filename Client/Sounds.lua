local ScoreSounds = {
    "package://nanos-1v1-master-league/Client/Sounds/GoalBuzzer_1.ogg",
    "package://nanos-1v1-master-league/Client/Sounds/GoalBuzzer_2.ogg",
    "package://nanos-1v1-master-league/Client/Sounds/GoalBuzzer_3.ogg"
}

local soundtrack

function PlayRandomScoreSound()
    local randomSound = ScoreSounds[math.random(#ScoreSounds)]
    randomSound:SetVolume(0.6)
    randomSound:Play()
end

function StartSoundtrack()
    soundtrack = Sound(Vector(), "package://nanos-1v1-master-league/Client/Sounds/Soundtrack_1.mp3", true, false, true, SoundType.Music)
    soundtrack:SetVolume(0.25)
end

function PlayRandomScoreSound()
    soundtrack:SetVolume(0.01)
    local BuzzerSound = Sound(Vector(), ScoreSounds[math.random(#ScoreSounds)], true)
    BuzzerSound:FadeOut(20, 0.0, true)

end