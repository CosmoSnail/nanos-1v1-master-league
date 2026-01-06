Ball = Prop.Inherit("Ball")

local spawnPosition = Vector(0, 0, 0)
local scale = 5
local massScale = 0.0001

local ball

function InitBall()
    ball = Ball(spawnPosition, Rotator(), "nanos-world::SM_Ball_VR")
    ball:SetScale(scale)
    ball:SetMassScale(massScale)
    ball:SetPhysicalMaterial('nanos-world::PM_Rubber')
end

function ResetBall()
    ball:Destroy()
    InitBall()
end