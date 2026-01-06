function SpawnThruster(vehicle)
  local thruster1 = Prop(Vector(0, 0, 100), Rotator(), "nanos-world::SM_Jet_Thruster", CollisionType.NoCollision, false, GrabMode.Disabled)
  local thruster2 = Prop(Vector(0, 0, 100), Rotator(), "nanos-world::SM_Jet_Thruster", CollisionType.NoCollision, false, GrabMode.Disabled)
  thruster1:AttachTo(vehicle, AttachmentRule.SnapToTarget, "", 1)
  thruster2:AttachTo(vehicle, AttachmentRule.SnapToTarget, "", 1)
  thruster1:SetRelativeLocation(Vector(-150, 40, 45))
  thruster2:SetRelativeLocation(Vector(-150, -40, 45))

  local particle1 = Particle(Vector(), Rotator(), "nanos-world::P_Fire", false, true)
  particle1:AttachTo(thruster1, AttachmentRule.SnapToTarget, "", 0)
  particle1:SetRelativeLocation(Vector(-40, 0, 0))
  particle1:Deactivate()

  local particle2 = Particle(Vector(), Rotator(), "nanos-world::P_Fire", false, true)
  particle2:AttachTo(thruster2, AttachmentRule.SnapToTarget, "", 0)
  particle2:SetRelativeLocation(Vector(-40, 0, 0))
  particle2:Deactivate()

end