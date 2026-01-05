Ball = Prop.Inherit("Ball")

function SpawnBall()
    local ball = Ball(Vector(3000, 0, 100), Rotator(), "nanos-world::SM_Ball_VR")

    ball:SetScale(5)
    ball:SetMassScale(0.0001)
    ball:SetPhysicalMaterial('nanos-world::PM_Rubber')
end