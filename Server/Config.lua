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
    ColorA = Color(0, 0, 1),
    ColorB = Color(1, 0, 0),
    -- the car bodies' paint, a little deeper than the team colors (PaintVehicle in Vehicle.lua)
    PaintA = Color(0.02, 0.16, 0.9),
    PaintB = Color(0.9, 0.05, 0.03),
    -- render distance of the ball, cars and everything attached to them (whole arena)
    RenderCullDistance = 1000000,
}

local settings = Server.GetCustomSettings() or {}
if settings.dev_commands ~= nil then Config.EnableCommands = settings.dev_commands == true or settings.dev_commands == "true" end
