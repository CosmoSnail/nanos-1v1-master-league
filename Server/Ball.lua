Ball = Prop.Inherit("Ball")

local spawnPosition = Vector(0, 0, 100)
local scale = 5
local massScale = 0.0001

local ball

function InitBall()
    ball = Ball(spawnPosition, Rotator(), "nanos-world::SM_Ball_VR")
    ball:SetScale(scale)
    ball:SetMassScale(massScale)
    ball:SetPhysicalMaterial('nanos-world::PM_Rubber')

    local trigger = Trigger(spawnPosition, Rotator(), Vector(650), TriggerType.Sphere, true, Color(1, 0, 0), {"Vehicle"})
    trigger:AttachTo(ball, AttachmentRule.SnapToTarget, nil, 0, false)
    trigger:SetRelativeLocation(Vector(0, 0, 0))

    trigger:Subscribe("BeginOverlap", function(trigger, vehicle)
        local player = vehicle:GetPassenger(0):GetPlayer()
        Chat.BroadcastMessage(player:GetName() .. " hit the ball!")
        Game.LastPlayerHitBall = player
    end)
end

function ResetBall()
    ball:Destroy()
    InitBall()
end

