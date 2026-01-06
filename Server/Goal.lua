Package.Require("Ball.lua")

local triggerA = Trigger(Vector(12400, 0, 700), Rotator(), Vector(950, 4500, 800), TriggerType.Box, true, Color(1, 0, 0), {"Prop"})
triggerA:Subscribe("BeginOverlap", function(self, other)
    if other:IsA(Ball) then
        Chat.BroadcastMessage("Team A scored!")
        ResetBall()
    end
end)

local triggerB = Trigger(Vector(-15400, 0, 700), Rotator(), Vector(950, 4500, 800), TriggerType.Box, true, Color(0, 0, 1), {"Prop"})
triggerB:Subscribe("BeginOverlap", function(self, other)
    if other:IsA(Ball) then
        Chat.BroadcastMessage("Team B scored!")
        ResetBall()
    end
end)