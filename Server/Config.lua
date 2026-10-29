Package.Require("Tables.lua")

Config = {
    LogLevel = LogLevel.Console,
    ShowTriggers = false,
    EnableCommands = false,
    LogBallTouches = false,     -- "<player> touched the ball" in the log (and in the chat in dev mode)
    ShowHats = true,
    ShowNamesOnVehicles = true,
    ShowCharactersOnVehicles = false,
    GameDuration = Theme.GameLength,
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
    -- Witches and Skeletons (Shared/Theme.lua)
    ColorA = Theme.Teams[1].color,
    ColorB = Theme.Teams[2].color,
    PaintCars = true,           -- tint the car bodies in their team's color
    -- render distance of the ball, cars and everything attached to them (whole arena)
    RenderCullDistance = 1000000,
    -- seconds between two lightning strikes over the graveyard (Weather.lua) when a game starts, closing in
    -- on the second range as it ends
    LightningInterval = { 6, 14 },
    FinalLightningInterval = { 2, 6 },
}

local settings = Server.GetCustomSettings() or {}
if settings.dev_commands ~= nil then Config.EnableCommands = settings.dev_commands == true or settings.dev_commands == "true" end
