Server.LoadPackage("default-vehicles")

Package.Require("Log.lua")

print("Server Started")

Package.Require("Config.lua")
Package.Require("Utils.lua")
Package.Require("Player.lua")
Package.Require("Ball.lua")
Package.Require("Controls.lua")
Package.Require("Goal.lua")
Package.Require("Tables.lua")

function InitGame()
    Game.State = State.CountDown
    Game.CountDownTimer = Config.CountDownDuration
    Game.Timer = Config.GameDuration
    Game.ScoreA = 0
    Game.ScoreB = 0
    Game.CurrentSpawnPointA = Config.SpawnPointA
    Game.CurrentSpawnPointB = Config.SpawnPointB
    Game.LastPlayerHitBall = nil
    Events.BroadcastRemote("UpdateTime", Game.Timer)
    Events.BroadcastRemote("UpdateScoreA", Game.ScoreA)
    Events.BroadcastRemote("UpdateScoreB", Game.ScoreB)
end

InitGame()
InitPlayers()
InitBall()
TogglePlayersInput(false)

Timer.SetInterval(function()
    if Game.State == State.CountDown then
        Game.CountDownTimer = Game.CountDownTimer - 1
        Events.BroadcastRemote("UpdateCountDownTime", Game.Timer)
        if (Game.CountDownTimer <= 0) then
            Game.State = State.Running
            print("Game Resumed!")
            TogglePlayersInput(true)
            return
        end
        print("State: CountDown. Timer: " .. tostring(Game.CountDownTimer))
        return
    elseif Game.State == State.Scored then
        Game.ScoredTimer = Game.ScoredTimer - 1
        if (Game.ScoredTimer <= 0) then
            Game.State = State.CountDown
            Game.CountDownTimer = Config.CountDownDuration
            print("Starting countdown!")
            TogglePlayersInput(false)
            ResetVehicles()
            ResetBall()
            return
        end
        print("State: Scored. Timer: " .. tostring(Game.ScoredTimer))
        return
    elseif Game.State == State.Running then
        Game.Timer = Game.Timer - 1
        Events.BroadcastRemote("UpdateTime", Game.Timer)
        if (Game.Timer <= 0) then
            Game.State = State.Ended
            Game.EndedTimer = Config.EndedDuration
            print("Game Over! Final Score - Team A: " .. tostring(Game.ScoreA) .. " | Team B: " .. tostring(Game.ScoreB))
            TogglePlayersInput(false)
            return
        end
        print("State: Running. Timer: " .. tostring(Game.Timer))
        return
    elseif Game.State == State.Ended then
        Game.EndedTimer = Game.EndedTimer - 1
        if (Game.EndedTimer <= 0) then
            print("Starting new game!")
            InitGame()
            ResetVehicles()
            ResetBall()
            TogglePlayersInput(false)
            return
        end
        print("State: Ended. Timer: " .. tostring(Game.EndedTimer))
        return
    end
end, 1000)

Server.Subscribe("Tick", function(delta_time)
  UpdateBallRibbon()
end)