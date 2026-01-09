function SpawnThruster(vehicle)
    local thrusters = {
        {
            offset = Vector(-150,  40, 45),
        },
        {
            offset = Vector(-150, -40, 45),
        }
    }

    for _, cfg in ipairs(thrusters) do
        local thruster = Prop(
            Vector(0, 0, 100),
            Rotator(),
            "nanos-world::SM_Jet_Thruster",
            CollisionType.NoCollision,
            false,
            GrabMode.Disabled
        )

        thruster:AttachTo(vehicle, AttachmentRule.SnapToTarget, "", 1)
        thruster:SetRelativeLocation(cfg.offset)

        local particle = Particle(Vector(), Rotator(), "nanos-world::P_Fire", false, true)
        particle:AttachTo(thruster, AttachmentRule.SnapToTarget, "", 0)
        particle:SetRelativeLocation(Vector(-40, 0, 0))
        particle:Deactivate()
    end
end