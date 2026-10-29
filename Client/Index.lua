Package.Require("Sky.lua")
Package.Require("Keys.lua")
Package.Require("Car.lua")
Package.Require("BoostFX.lua")
Package.Require("BallCam.lua")
Package.Require("Sounds.lua")

local main_hud = WebUI("Main HUD", "file://UI/index.html")

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
Events.CallRemote("AskDevMode", Reliability.Reliable)

InitSky()
StartSoundtrack()

Events.SubscribeRemote("UpdateCountDownTime", function(time)
  main_hud:CallEvent("UpdateCountDownTime", time)
end)

Events.SubscribeRemote("UpdateTime", function(time)
  if (time == 0) then
    PlayEndSound()
  end
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
  
  PlayRandomScoreSound()
end)

Events.Subscribe("UpdateBoost", function(boost)
  main_hud:CallEvent("UpdateBoost", boost)
end)

Events.Subscribe("UpdateBallCam", function(enabled)
  main_hud:CallEvent("UpdateBallCam", enabled)
end)
