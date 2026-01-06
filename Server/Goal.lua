Package.Require("Ball.lua")
Package.Require("Tables.lua")

local triggerA = Trigger(Vector(14000, 0, 900), Rotator(), Vector(950, 4500, 800), TriggerType.Box, true, Color(1, 0, 0), {"Prop"})
triggerA:Subscribe("BeginOverlap", function(self, other)
    if other:IsA(Ball) then
        HandleGoal(other, Team.TeamA)
    end
end)

local triggerB = Trigger(Vector(-14000, 0, 900), Rotator(), Vector(950, 4500, 800), TriggerType.Box, true, Color(0, 0, 1), {"Prop"})
triggerB:Subscribe("BeginOverlap", function(self, other)
    if other:IsA(Ball) then
        HandleGoal(other, Team.TeamB)
    end
end)

function HandleGoal(ball, team)
    if team == Team.TeamA then
        Chat.BroadcastMessage("Team A scored! " .. "(" .. Game.LastPlayerHitBall:GetName() .. ")")
        Game.ScoreA = Game.ScoreA + 1
        Events.BroadcastRemote("UpdateScoreA", Game.ScoreA)
    else
        Chat.BroadcastMessage("Team B scored! " .. "(" .. Game.LastPlayerHitBall:GetName() .. ")")
        Game.ScoreB = Game.ScoreB + 1
        Events.BroadcastRemote("UpdateScoreB", Game.ScoreB)
    end
    local particle = Particle(
        ball:GetLocation(),
        Rotator(0, 0, 0),
        "nanos-world::P_Explosion",
        true,
        true
    )
    particle:SetScale(50)
    ImpulseAllVehicles(ball:GetLocation())
    ResetBall()
end

function ImpulseAllVehicles(fromLocation)
    for _, player in pairs(Player.GetAll()) do
        local character = player:GetControlledCharacter()
        if character then
            local vehicle = character:GetVehicle()
            local direction = (vehicle:GetLocation() - fromLocation)
            direction:Normalize()
            direction = direction + Vector(0, 0, 0.3)
            vehicle:AddImpulse(direction * 40000000)
        end
    end
end