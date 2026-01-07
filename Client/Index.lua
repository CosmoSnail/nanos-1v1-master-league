Package.Require("Sky.lua")
Package.Require("Inputs.lua")
Package.Require("Sounds.lua")

main_hud = WebUI("Main HUD", "file://UI/index.html")

InitSky()
StartSoundtrack()

Events.SubscribeRemote("UpdateTime", function(time)
  main_hud:CallEvent("UpdateTime", time)
end)

Events.SubscribeRemote("UpdateCountDownTime", function(time)
  main_hud:CallEvent("UpdateCountDownTime", time)
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