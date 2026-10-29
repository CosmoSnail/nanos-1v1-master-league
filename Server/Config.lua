Package.Require("Tables.lua")

Config = {
    LogLevel = LogLevel.Console,
    ShowTriggers = false,
    EnableCommands = false,
    ShowHats = true,
    ShowNamesOnVehicles = true,
    ShowCharactersOnVehicles = false,
    GameDuration = 5 * 60,
    CountDownDuration = 4,
    ScoredDuration = 7,
    EndedDuration = 20,
    SpawnPointA = Vector(-8000, 0, 100),
    SpawnPointB = Vector(8000, 0, 100),
    BallSpawnPoint = Vector(0, 0, 150),
    GoalPointA = Vector(-13700, 0, 900),
    GoalPointB = Vector(13700, 0, 900),
    ColorA = Color(0, 0, 1),
    ColorB = Color(1, 0, 0),
    -- render distance of the ball, cars and everything attached to them (whole arena)
    RenderCullDistance = 1000000,
}

local settings = Server.GetCustomSettings() or {}
if settings.dev_commands ~= nil then Config.EnableCommands = settings.dev_commands == true or settings.dev_commands == "true" end
