Package.Require("Thruster.lua")
Package.Require("Tables.lua")

local rotationA = Rotator(0, 0, 0)
local rotationB = Rotator(0, 180, 0)

function SpawnVehicle(character)
    local vehicleSpawnPoint
    local rotation
    if character:GetTeam() == Team.TeamA then
        vehicleSpawnPoint = Game.CurrentSpawnPointA
        IncrementCurrentSpawnPoint(Team.TeamA)
        rotation = rotationA
    end
    if character:GetTeam() == Team.TeamB then
        vehicleSpawnPoint = Game.CurrentSpawnPointB
        IncrementCurrentSpawnPoint(Team.TeamB)
        rotation = rotationB
    end

    local vehicle = Offroad(vehicleSpawnPoint, rotation)
    vehicle:SetEngineSetup(1000, 8000, 1000, 0.02, 5, 600)
    vehicle:SetAerodynamicsSetup(3200, 0.4, 180, 160, 2, Vector(0, 0, 5))
    vehicle:SetTransmissionSetup(4.4, 6700, 3200, 0.03, 1.0)
    vehicle:SetSteeringWheelSetup(Vector(60, -42, 83), 19, Rotator())
    vehicle:SetExplosionSettings(Vector(), {}, { 1 })

    vehicle:SetWheel(0, "PhysWheel_FL", 50, 35, 50, Vector(), true, true, false, false, true, 6500, 0, 50000, 1000, 50, 50, 28, 70, 10, 6, 6, 0, 0.5, 0.7)
    vehicle:SetWheel(1, "PhysWheel_FR", 50, 35, 50, Vector(), true, true, false, false, true, 6500, 0, 50000, 1000, 50, 50, 28, 70, 10, 6, 6, 0, 0.5, 0.7)
    vehicle:SetWheel(2, "PhysWheel_BL", 50, 42, 0, Vector(), false, true, true, false, true, 6500, 15000, 50000, 1000, 50, 50, 28, 70, 10, 6, 6, 0, 0.5, 0.63)
    vehicle:SetWheel(3, "PhysWheel_BR", 50, 42, 0, Vector(), false, true, true, false, true, 6500, 15000, 50000, 1000, 50, 50, 28, 70, 10, 6, 6, 0, 0.5, 0.63)

    vehicle:RecreatePhysics()

    vehicle:Subscribe("CharacterAttemptLeave", function(self, _)
        return false
    end)

    SpawnThruster(vehicle)
    AttachVehicleLights(vehicle, character:GetTeam())
    AttachVehiclePlayerName(vehicle, character:GetPlayer():GetName())
    AttachVehicleHat(vehicle, character:GetTeam())

    character:EnterVehicle(vehicle)
    character:SetVisibility(false)

end

function AttachVehicleHat(vehicle, team)
    if not Config.ShowHats then
        return
    end
    local hatConfig = Ternary(team == Team.TeamA, Game.HatA, Game.HatB)
    local hat = StaticMesh(Vector(), Rotator(), hatConfig.name, CollisionType.NoCollision)
    hat:SetScale(Vector(hatConfig.scale))
    hat:AttachTo(vehicle, AttachmentRule.SnapToTarget, "", 0)
    hat:SetRelativeLocation(hatConfig.location)
    hat:SetRelativeRotation(hatConfig.rotation)
end

function ResetVehicles() 
    Game.CurrentSpawnPointA = Config.SpawnPointA
    Game.CurrentSpawnPointB = Config.SpawnPointB
    for _, player in pairs(Player.GetAll()) do
        local character = player:GetControlledCharacter()
        if character then
            local vehicle = character:GetVehicle()
            if vehicle then
                vehicle:Destroy()
                SpawnVehicle(character)
            end
        end

        if character:GetTeam() == Team.TeamA then
            player:SetCameraRotation(Rotator(0, 0, 0))
        else
            player:SetCameraRotation(Rotator(0, 180, 0))
        end
    end
end

function IncrementCurrentSpawnPoint(team)
    local step = 600

    local function MirrorAroundCenter(current, center)
        local offset = current.Y - center.Y
        return center + Vector(0, -offset, 0)
    end

    if team == Team.TeamA then
        local center = Config.SpawnPointA
        local current = Game.CurrentSpawnPointA

        if current.Y == center.Y then
            Game.CurrentSpawnPointA = current + Vector(0, step, 0)
            return
        elseif current.Y > center.Y then
            Game.CurrentSpawnPointA = MirrorAroundCenter(current, center)
        else
            Game.CurrentSpawnPointA = MirrorAroundCenter(current, center) + Vector(0, step, 0)
        end

    elseif team == Team.TeamB then
        local center = Config.SpawnPointB
        local current = Game.CurrentSpawnPointB

        if current.Y == center.Y then
            Game.CurrentSpawnPointB = current + Vector(0, step, 0)
            return
        elseif current.Y > center.Y then
            Game.CurrentSpawnPointB = MirrorAroundCenter(current, center)
        else
            Game.CurrentSpawnPointB = MirrorAroundCenter(current, center) + Vector(0, step, 0)
        end
    end
end

function AttachVehicleLights(vehicle, team)
    local showPositions = false
    local light_data = {
        { pos = Vector(40, 0, 130), intensity = 4 },
        -- { pos = Vector(150, 0, 150), intensity = 1 },
        -- { pos = Vector(-130, 0, 150), intensity = 5 },
        -- { pos = Vector(0, 140, 80), intensity = 1 },
        -- { pos = Vector(0, -140, 80), intensity = 1 },
    }
    for _, data in ipairs(light_data) do
        local light = Light(
            Vector(),
            Rotator(), -- Relevant only for Rect and Spot light types
            Ternary(team == Team.TeamA, Config.ColorA, Config.ColorB), -- Color
            LightType.Point, -- Point Light type
            data.intensity, -- Per-light intensity
            140, -- Attenuation Radius
            44, -- Cone Angle
            0, -- Inner Cone Angle Percent
            5000, -- Max Draw Distance
            true, -- Inverse squared falloff
            false, -- Cast Shadows?
            true -- Enabled?
        )

        light:AttachTo(vehicle, AttachmentRule.SnapToTarget, "", 1)
        light:SetRelativeLocation(data.pos)

        if showPositions then
            local trigger = Trigger(
                light:GetLocation(),
                Rotator(),
                Vector(10),
                TriggerType.Sphere,
                true,
                Color(0, 1, 0),
                { "Vehicle" }
            )

            trigger:AttachTo(light, AttachmentRule.SnapToTarget, "", 1)
            trigger:SetRelativeLocation(Vector())
        end
    end
end

function AttachVehiclePlayerName(vehicle, name)
    if not Config.ShowNamesOnVehicles then
        return
    end

    local text = TextRender(
        Vector(),
        Rotator(),
        name,
        Vector(0.6),
        Color(1, 1, 1),
        FontType.OpenSans,
        TextRenderAlignCamera.FaceCamera
    )

    text:AttachTo(vehicle, AttachmentRule.SnapToTarget, "", 1)
    -- -10 * (#name / 2)
    text:SetRelativeLocation(Vector(0, 0, 280))
end