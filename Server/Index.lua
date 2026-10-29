Package.Require("Log.lua")

print("Server Started")
if Config.EnableCommands then print("Dev mode on: chat commands (/help) and client errors in this log") end

Package.Require("Config.lua")
Package.Require("Hats.lua")
Package.Require("Utils.lua")
Package.Require("Player.lua")
Package.Require("Ball.lua")
Package.Require("Controls.lua")
Package.Require("Goal.lua")
Package.Require("Tables.lua")
Package.Require("Stats.lua")
Package.Require("Chat.lua")
Package.Require("Fireworks.lua")
Package.Require("Weather.lua")

function InitGame()
    Game.State = State.CountDown
    Game.CountDownTimer = Config.CountDownDuration
    Game.Timer = Config.GameDuration
    Game.ScoreA = 0
    Game.ScoreB = 0
    Game.CurrentSpawnPointA = Config.SpawnPointA
    Game.CurrentSpawnPointB = Config.SpawnPointB
    Game.LastPlayerHitBall = nil
    Game.HatA = GetTeamHat(Team.TeamA)
    Game.HatB = GetTeamHat(Team.TeamB)
    Game.GameOverInfo = nil
    ShuffleTeams()
    ResetStats()
    Events.BroadcastRemote("NewGame", Reliability.Reliable)
    Events.BroadcastRemote("UpdateTime", Reliability.Reliable, Game.Timer)
    Events.BroadcastRemote("UpdateScoreA", Reliability.Reliable, Game.ScoreA)
    Events.BroadcastRemote("UpdateScoreB", Reliability.Reliable, Game.ScoreB)
end

function EndGame()
    Game.State = State.Ended
    Game.EndedTimer = Config.EndedDuration
    local result = "The night is over! Witches " .. tostring(Game.ScoreA) .. " x " .. tostring(Game.ScoreB) .. " Skeletons"
    if Game.ScoreA ~= Game.ScoreB then
        result = result .. " - the " .. TeamName(Ternary(Game.ScoreA > Game.ScoreB, Team.TeamA, Team.TeamB)) .. " rule the graveyard!"
    end
    print(result)
    Chat.BroadcastMessage(result)
    TogglePlayersInput(false)
    SpawnFireworksEndGame()
    -- end of game screen with the leaderboard and the time to the next game (Client/UI)
    Game.GameOverInfo = BuildGameOverInfo()
    SendLeaderboard()
    Events.BroadcastRemote("GameOver", Reliability.Reliable, Game.GameOverInfo)
end

function StartNewGame()
    print("Starting new game!")
    InitGame()
    ResetVehicles()
    ResetBall()
    TogglePlayersInput(false)
end

InitGame()
InitPlayers()
InitBall()
TogglePlayersInput(false)

Timer.SetInterval(function()
    if Game.State == State.CountDown then
        Game.CountDownTimer = Game.CountDownTimer - 1
        Events.BroadcastRemote("UpdateCountDownTime", Reliability.Reliable, Game.CountDownTimer)
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
        Events.BroadcastRemote("UpdateTime", Reliability.Reliable, Game.Timer)
        CheckBallOutOfBounds()
        CheckVehiclesOutOfBounds()
        if (Game.Timer <= 0) then
            EndGame()
            return
        end
        print("State: Running. Timer: " .. tostring(Game.Timer))
        return
    elseif Game.State == State.Ended then
        Game.EndedTimer = Game.EndedTimer - 1
        Events.BroadcastRemote("UpdateNextGameTime", Reliability.Reliable, math.max(Game.EndedTimer, 0))
        if (Game.EndedTimer <= 0) then
            StartNewGame()
            return
        end
        print("State: Ended. Timer: " .. tostring(Game.EndedTimer))
        return
    end
end, 1000)

Server.Subscribe("Tick", function(delta_time)
  UpdateBallRibbon()
end)