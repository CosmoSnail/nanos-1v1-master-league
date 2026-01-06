Ball = Prop.Inherit("Ball")

local scale = 5
local massScale = 0.0001

local ball

function InitBall()
    ball = Ball(Config.BallSpawnPoint, Rotator(), "nanos-world::SM_Ball_VR")
    ball:SetScale(scale)
    ball:SetMassScale(massScale)
    ball:SetPhysicalMaterial('nanos-world::PM_Rubber')

    local trigger = Trigger(Config.BallSpawnPoint, Rotator(), Vector(660), TriggerType.Sphere, Config.ShowTriggers, Color(0, 1, 0), {"Vehicle"})
    trigger:AttachTo(ball, AttachmentRule.SnapToTarget, nil, 0, false)
    trigger:SetRelativeLocation(Vector(0, 0, 0))

    trigger:Subscribe("BeginOverlap", function(trigger, vehicle)
        local player = vehicle:GetPassenger(0):GetPlayer()
        print(player:GetName() .. " hit the ball!")
        Game.LastPlayerHitBall = player
    end)
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

