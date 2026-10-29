Package.Require("Sky.lua")
Package.Require("Car.lua")
Package.Require("Sounds.lua")

local main_hud = WebUI("Main HUD", "file://UI/index.html")

-- Script errors also go to the server log (once each, so a broken Tick doesn't flood it)
local reported_errors = {}
Console.Subscribe("LogEntry", function(text, log_type)
  if log_type ~= LogType.Error and log_type ~= LogType.ScriptingError then return end
  if type(text) ~= "string" or reported_errors[text] then return end
  reported_errors[text] = true
  Events.CallRemote("ClientError", Reliability.Reliable, text)
end)

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
