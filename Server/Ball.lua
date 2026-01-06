Ball = Prop.Inherit("Ball")

local scale = 5
local massScale = 0.0001

local ball
local ribbon

function InitBall()
    ball = Ball(Config.BallSpawnPoint, Rotator(), "nanos-world::SM_Ball_VR")
    ball:SetScale(scale)
    ball:SetMassScale(massScale)
    ball:SetPhysicalMaterial('nanos-world::PM_Rubber')

    local trigger = Trigger(Config.BallSpawnPoint, Rotator(), Vector(665), TriggerType.Sphere, Config.ShowTriggers, Color(0, 1, 0), {"Vehicle"})
    trigger:AttachTo(ball, AttachmentRule.SnapToTarget, nil, 0, false)
    trigger:SetRelativeLocation(Vector(0, 0, 0))

    trigger:Subscribe("BeginOverlap", function(trigger, vehicle)
        local player = vehicle:GetPassenger(0):GetPlayer()
        print(player:GetName() .. " hit the ball!")
        Game.LastPlayerHitBall = player
        ToggleRibbon(player:GetControlledCharacter():GetTeam())
    end)
end

function ToggleRibbon(team)
    if ribbon and ribbon:IsValid() then
        ribbon:Destroy()
    end

    ribbon = Particle(
        ball:GetLocation(),
        Rotator(0, 0, 0),
        "nanos-world::P_Ribbon",
        false,
        true
    )
    ribbon:SetParameterColor("Color", Ternary(team == Team.TeamA, Config.ColorA, Config.ColorB))
    ribbon:SetParameterFloat("SpawnRate", 50.0)
    ribbon:SetParameterFloat("LifeTime", 0.3)
    ribbon:SetParameterFloat("RibbonWidth", 20.0)
    ribbon:AttachTo(ball, AttachmentRule.SnapToTarget, "", 0)
end

function DestroyBall()
    if ball and ball:IsValid() then
        ball:Destroy()
    end
end

function ResetBall()
    DestroyBall()
    InitBall()
end

function UpdateBallRibbon()
    if ribbon and ribbon:IsValid() and ball and ball:IsValid() then
        local velocity = ball:GetVelocity():Size()
        if velocity < 2300 then
            ribbon:Deactivate()
            return
        elseif ribbon and ribbon:IsActive() then
            ribbon:Activate()
        end
        return
    end
end