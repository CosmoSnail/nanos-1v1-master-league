Package.Require("Sounds.lua")
Package.Require("Atmosphere.lua")
Package.Require("Keys.lua")
Package.Require("Car.lua")
Package.Require("BoostFX.lua")
Package.Require("BallCam.lua")
Package.Require("Help.lua")
Package.Require("Leaderboard.lua")
Package.Require("PumpkinBall.lua")
Package.Require("Arena.lua")
Package.Require("Spooks.lua")

local main_hud = WebUI("Main HUD", "file://UI/index.html")
main_hud:Subscribe("Ready", SendControls)

-- With the dev_commands setting on, script errors also go to the server log (once each, so a broken Tick
-- doesn't flood it); the ones before the server answers wait in pending_errors
local dev_mode = nil
local pending_errors = {}
local reported_errors = {}
Console.Subscribe("LogEntry", function(text, log_type)
  if dev_mode == false then return end
  if log_type ~= LogType.Error and log_type ~= LogType.ScriptingError then return end
  if type(text) ~= "string" or reported_errors[text] then return end
  reported_errors[text] = true
  if dev_mode then
    Events.CallRemote("ClientError", Reliability.Reliable, text)
  else
    table.insert(pending_errors, text)
  end
end)

Events.SubscribeRemote("DevMode", function(on)
  dev_mode = on == true
  if dev_mode then
    for _, text in ipairs(pending_errors) do
      Events.CallRemote("ClientError", Reliability.Reliable, text)
    end
  end
  pending_errors = {}
end)
-- Asked again until the server answers: on joining, the package loads before the server has our player
-- ("Player not found for Remote Event") and the first question is lost
local function AskDevMode()
  if dev_mode ~= nil then return end
  Events.CallRemote("AskDevMode", Reliability.Reliable)
  Timer.SetTimeout(AskDevMode, 3000)
end
AskDevMode()

Events.SubscribeRemote("UpdateCountDownTime", function(time)
  PlayCountdownSound(time)
  main_hud:CallEvent("UpdateCountDownTime", time)
end)

Events.SubscribeRemote("UpdateTime", function(time)
  if (time == 0) then
    PlayEndSound()
  end
  UpdateNight(time)
  main_hud:CallEvent("UpdateTime", time)
end)

Events.SubscribeRemote("UpdateScoreA", function(score)
  main_hud:CallEvent("UpdateScoreA", score)
end)

Events.SubscribeRemote("UpdateScoreB", function(score)
  main_hud:CallEvent("UpdateScoreB", score)
end)

Events.SubscribeRemote("GoalScored", function(info)
  main_hud:CallEvent("GoalScored", info)

  PlayGoalSound(type(info) == "table" and info.team or nil)
end)

Events.Subscribe("UpdateBoost", function(boost)
  main_hud:CallEvent("UpdateBoost", boost)
end)

Events.Subscribe("UpdateBallCam", function(enabled)
  main_hud:CallEvent("UpdateBallCam", enabled)
end)

Events.Subscribe("UpdateControls", function(rows, help_key)
  main_hud:CallEvent("UpdateControls", rows, help_key)
end)

Events.Subscribe("ToggleHelp", function(open)
  main_hud:CallEvent("ToggleHelp", open)
end)

-- Leaderboard and end of game screen. The last ones are kept to send again once the HUD has loaded:
-- a player joining during the end screen gets them before that
local last_leaderboard = nil
local last_game_over = nil

Events.SubscribeRemote("UpdateLeaderboard", function(rows)
  local local_player = Client.GetLocalPlayer()
  local my_id = local_player and local_player:GetID()
  for _, row in ipairs(rows) do
    row.me = row.id == my_id
  end
  last_leaderboard = rows
  main_hud:CallEvent("UpdateLeaderboard", rows)
end)

Events.SubscribeRemote("GameOver", function(info)
  last_game_over = info
  main_hud:CallEvent("GameOver", info)
end)

Events.SubscribeRemote("UpdateNextGameTime", function(seconds)
  if last_game_over then last_game_over.nextGameIn = seconds end
  main_hud:CallEvent("UpdateNextGameTime", seconds)
end)

Events.SubscribeRemote("NewGame", function()
  last_game_over = nil
  main_hud:CallEvent("NewGame")
end)

Events.Subscribe("ToggleLeaderboard", function(open)
  main_hud:CallEvent("ToggleLeaderboard", open)
end)

main_hud:Subscribe("Ready", function()
  if last_leaderboard then main_hud:CallEvent("UpdateLeaderboard", last_leaderboard) end
  if last_game_over then main_hud:CallEvent("GameOver", last_game_over) end
end)
