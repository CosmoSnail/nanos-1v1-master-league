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
        -- the boost flames are drawn on the clients (Client/BoostFX.lua)
    end
end