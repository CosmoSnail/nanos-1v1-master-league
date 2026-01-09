Game = {
    State = 0,
    Timer = 0,
    ScoreA = 0,
    ScoreB = 0,
    CurrentSpawnPointA = Vector(),
    CurrentSpawnPointB = Vector(),
    LastPlayerHitBall = {},
    CountDownTimer = 0,
    ScoredTimer = 0,
    EndedTimer = 0,
    HatA = {},
    HatB = {},
}

Team = {
    TeamA = 1,
    TeamB = 2,
}

State = {
    CountDown = 1,
    Running = 2,
    Scored = 3,
    Ended = 4,
}

LogLevel = {
    Silent = 1,
    Console = 2,
    GameChat = 3,
}