Package.Require("Ball.lua")
Package.Require("Tables.lua")

local triggerA = Trigger(Config.GoalPointA, Rotator(), Vector(950, 4500, 800), TriggerType.Box, Config.ShowTriggers, Config.ColorA, {"Prop"})
triggerA:Subscribe("BeginOverlap", function(self, other)
    if other:IsA(Ball) then
        HandleGoal(other, Team.TeamB)
    end
end)

local triggerB = Trigger(Config.GoalPointB, Rotator(), Vector(950, 4500, 800), TriggerType.Box, Config.ShowTriggers, Config.ColorB, {"Prop"})
triggerB:Subscribe("BeginOverlap", function(self, other)
    if other:IsA(Ball) then
        HandleGoal(other, Team.TeamA)
    end
end)

function HandleGoal(ball, teamScored)
    if Game.State ~= State.Running then
        return
    end

    if teamScored == Team.TeamA then
        print("Team A scored! " .. "(" .. Game.LastPlayerHitBall:GetName() .. ")")
        Game.ScoreA = Game.ScoreA + 1
        Events.BroadcastRemote("UpdateScoreA", Game.ScoreA)
        Events.BroadcastRemote("PlayScoreSound")
    else
        print("Team B scored! " .. "(" .. Game.LastPlayerHitBall:GetName() .. ")")
        Game.ScoreB = Game.ScoreB + 1
        Events.BroadcastRemote("UpdateScoreB", Game.ScoreB)
        Events.BroadcastRemote("PlayScoreSound")
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
    Game.State = State.Scored
    Game.ScoredTimer = Config.ScoredDuration
    DestroyBall()
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

function AttachGoalLights(team)
    local showPositions = false
    local light = Light(
        Ternary(team == Team.TeamA, Config.GoalPointA, Config.GoalPointB),
        Ternary(team == Team.TeamA, Rotator(90, 180, 0), Rotator(90, 0, 0)), -- Relevant only for Rect and Spot light types
        Ternary(team == Team.TeamA, Config.ColorA, Config.ColorB), -- Color
        LightType.Point, -- Light type
        3000, -- Per-light intensity
        10000, -- Attenuation Radius
        44, -- Cone Angle
        100, -- Inner Cone Angle Percent
        50000, -- Max Draw Distance
        true, -- Inverse squared falloff
        false, -- Cast Shadows?
        true -- Enabled?
    )

    if showPositions then
        local trigger = Trigger(
            light:GetLocation(),
            Rotator(),
            Vector(5000),
            TriggerType.Sphere,
            true,
            Color(0, 1, 0),
            { "Vehicle" }
        )

        trigger:AttachTo(light, AttachmentRule.SnapToTarget, "", 1)
        trigger:SetRelativeLocation(Vector())
    end
end

AttachGoalLights(Team.TeamA)
AttachGoalLights(Team.TeamB)