Package.Require("Ball.lua")
Package.Require("Tables.lua")

local GOAL_EXTENT = Vector(950, 4500, 800)

-- Who scored is decided this long after the ball goes in: the scorer's own client tells the server about their touch
-- (Client/BallTouch.lua), and with their ping that can arrive just after the goal (Ball.lua still takes it)
local GOAL_CREDIT_DELAY = 300 -- ms

local triggerA = Trigger(Config.GoalPointA, Rotator(), GOAL_EXTENT, TriggerType.Box, Config.ShowTriggers, Config.ColorA, {"Prop"})
triggerA:Subscribe("BeginOverlap", function(self, other)
    if other:IsA(Ball) then
        HandleGoal(other, Team.TeamB)
    end
end)

local triggerB = Trigger(Config.GoalPointB, Rotator(), GOAL_EXTENT, TriggerType.Box, Config.ShowTriggers, Config.ColorB, {"Prop"})
triggerB:Subscribe("BeginOverlap", function(self, other)
    if other:IsA(Ball) then
        HandleGoal(other, Team.TeamA)
    end
end)

-- Whether a location is inside one of the goals (past the goal line)
function InGoal(location)
    for _, point in ipairs({ Config.GoalPointA, Config.GoalPointB }) do
        local d = location - point
        if math.abs(d.X) <= GOAL_EXTENT.X and math.abs(d.Y) <= GOAL_EXTENT.Y and math.abs(d.Z) <= GOAL_EXTENT.Z then
            return true
        end
    end
    return false
end

-- Whether a goal was just scored and its scorer not decided yet (Ball.lua still counts touches told until then)
function GoalPending()
    return Game.PendingGoal ~= nil
end

function HandleGoal(ball, teamScored)
    if Game.State ~= State.Running then
        return
    end

    SpawnFireworksGoal(teamScored)

    if teamScored == Team.TeamA then
        Game.ScoreA = Game.ScoreA + 1
        Events.BroadcastRemote("UpdateScoreA", Reliability.Reliable, Game.ScoreA)
    else
        Game.ScoreB = Game.ScoreB + 1
        Events.BroadcastRemote("UpdateScoreB", Reliability.Reliable, Game.ScoreB)
    end

    local location = ball:GetLocation()
    Game.PendingGoal = { team = teamScored, location = location }
    Timer.SetTimeout(function() AnnounceGoal(teamScored, location) end, GOAL_CREDIT_DELAY)

    local particle = Particle(
        location,
        Rotator(0, 0, 0),
        "nanos-world::P_Explosion",
        true,
        true
    )
    particle:SetScale(50)
    KeepVisible(particle)
    ImpulseAllVehicles(location)
    Game.State = State.Scored
    Game.ScoredTimer = Config.ScoredDuration
    DestroyBall()
end

-- The scorer, once the late touches are in: the card shows them (Stats.lua), or whoever put it in their own goal
function AnnounceGoal(teamScored, location)
    Game.PendingGoal = nil
    local scorer, assister = CreditGoal(teamScored)
    local lastHitter = GetLastPlayerHitBall()
    local shown = scorer or lastHitter
    local lastCharacter = Game.LastPlayerHitBall and Game.LastPlayerHitBall:IsValid() and Game.LastPlayerHitBall:GetControlledCharacter()
    local ownGoal = not scorer and lastCharacter and lastCharacter:GetTeam() ~= teamScored

    print("The " .. (teamScored == Team.TeamA and "Witches" or "Skeletons") .. " scored! (" .. shown:GetName() .. ")")

    -- x, y, z: where the pumpkin burst, for the clients' celebration (Client/Spooks.lua)
    Events.BroadcastRemote("GoalScored", Reliability.Reliable, {
        playerName = shown:GetName(),
        playerImageUrl = shown:GetAccountIconURL(),
        team = teamScored,
        assistName = assister and assister:GetName() or nil,
        ownGoal = ownGoal and true or false,
        x = location.X,
        y = location.Y,
        z = location.Z,
    })
end

function ImpulseAllVehicles(fromLocation)
    for _, player in pairs(Player.GetAll()) do
        local character = player:GetControlledCharacter()
        if character then
            local vehicle = character:GetVehicle()
            local direction = (vehicle:GetLocation() - fromLocation)
            direction:Normalize()
            direction = direction + Vector(0, 0, 0.5)
            vehicle:AddImpulse(direction * 55000000)
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
        250, -- Per-light intensity
        10000, -- Attenuation Radius
        60, -- Cone Angle
        0, -- Inner Cone Angle Percent
        80000, -- Max Draw Distance
        true, -- Inverse squared falloff
        false, -- Cast Shadows?
        true, -- Enabled?
        10000
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