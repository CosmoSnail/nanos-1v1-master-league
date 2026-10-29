Package.Require("Tables.lua")

Config = {
    LogLevel = LogLevel.Console,
    ShowTriggers = false,
    EnableCommands = false,
    LogBallTouches = false,     -- "<player> touched the ball" in the log (and in the chat in dev mode)
    ShowHats = true,
    ShowNamesOnVehicles = true,
    ShowCharactersOnVehicles = false,
    GameDuration = 5 * 60,
    CountDownDuration = 4,
    ScoredDuration = 7,
    EndedDuration = 20,
    -- spawn heights measured where they come to rest on the arena floor (car ~142, ball ~497):
    -- spawning lower pushes them out of the floor with a bump
    SpawnPointA = Vector(-8000, 0, 145),
    SpawnPointB = Vector(8000, 0, 145),
    BallSpawnPoint = Vector(0, 0, 500),
    GoalPointA = Vector(-13700, 0, 900),
    GoalPointB = Vector(13700, 0, 900),
    -- Witches and Pumpkins (Shared/Theme.lua)
    ColorA = Theme.Teams[1].color,
    ColorB = Theme.Teams[2].color,
    PaintCars = true,           -- tint the car bodies in their team's color
    -- render distance of the ball, cars and everything attached to them (whole arena)
    RenderCullDistance = 1000000,
    -- seconds between two lightning strikes over the graveyard (Weather.lua), and in the last minute
    LightningInterval = { 14, 32 },
    WitchingLightningInterval = { 4, 10 },
    WitchingHour = Theme.WitchingHour,
}

local settings = Server.GetCustomSettings() or {}
if settings.dev_commands ~= nil then Config.EnableCommands = settings.dev_commands == true or settings.dev_commands == "true" end
