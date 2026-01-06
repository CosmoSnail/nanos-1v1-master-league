Server.LoadPackage("default-vehicles")

Package.Require("Player.lua")
Package.Require("Ball.lua")
Package.Require("Controls.lua")
Package.Require("Goal.lua")

local InitialGameTime = 5 * 60

Game.Time = InitialGameTime
Game.CurrentSpawnPointA = Vector(-8000, 0, 100)
Game.CurrentSpawnPointB = Vector(8000, 0, 100)

InitPlayers()
InitBall()

Timer.SetInterval(function()
    Game.Time = Game.Time - 1
    print(Game.Time)
    Events.BroadcastRemote("UpdateTime", Game.Time)
    if Game.Time <= 0 then
        Chat.BroadcastMessage("Game Over! Final Score - Team A: " .. tostring(Game.ScoreA) .. " | Team B: " .. tostring(Game.ScoreB))
        Game.Time = InitialGameTime
        Game.ScoreA = 0
        Game.ScoreB = 0
        ResetBall()
        Events.BroadcastRemote("UpdateTime", Game.Time)
        Events.BroadcastRemote("UpdateScoreA", Game.ScoreA)
        Events.BroadcastRemote("UpdateScoreB", Game.ScoreB)
    end
end, 1000)