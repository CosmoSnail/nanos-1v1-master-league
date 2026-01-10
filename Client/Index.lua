Package.Require("Sky.lua")
Package.Require("Inputs.lua")
Package.Require("Sounds.lua")

local main_hud = WebUI("Main HUD", "file://UI/index.html")

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
