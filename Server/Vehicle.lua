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
    -- the clients color the boost exhaust by team (Client/BoostFX.lua)
    vehicle:SetValue("Team", character:GetTeam(), true)
    -- The car is driven by Client/Car.lua through velocity changes. The engine only makes sound
    -- and the wheels are just suspension: not powered, no brakes and little grip, so they don't
    -- fight the controller.
    vehicle:SetEngineSetup(600, 7000, 1000, 0, 2, 1000)
    vehicle:SetAerodynamicsSetup(3200, 0, 180, 160, 0, Vector(0, 0, 5))
    vehicle:SetSteeringWheelSetup(Vector(60, -42, 83), 19, Rotator())
    vehicle:SetExplosionSettings(Vector(), {}, { 1 })

    vehicle:SetWheel(0, "PhysWheel_FL", 50, 35, 30, Vector(), false, false, false, false, false, 0, 0, 500, 1, 0.5, 20, 20, 300, 100, 8, 8, 0, 0.6, 0, Vector(0, 0, -1), Vector(), SuspensionSweepShape.Shapecast)
    vehicle:SetWheel(1, "PhysWheel_FR", 50, 35, 30, Vector(), false, false, false, false, false, 0, 0, 500, 1, 0.5, 20, 20, 300, 100, 8, 8, 0, 0.6, 0, Vector(0, 0, -1), Vector(), SuspensionSweepShape.Shapecast)
    vehicle:SetWheel(2, "PhysWheel_BL", 50, 42, 0, Vector(), false, false, false, false, false, 0, 0, 500, 1, 0.5, 20, 20, 300, 100, 8, 8, 0, 0.6, 0, Vector(0, 0, -1), Vector(), SuspensionSweepShape.Shapecast)
    vehicle:SetWheel(3, "PhysWheel_BR", 50, 42, 0, Vector(), false, false, false, false, false, 0, 0, 500, 1, 0.5, 20, 20, 300, 100, 8, 8, 0, 0.6, 0, Vector(0, 0, -1), Vector(), SuspensionSweepShape.Shapecast)

    vehicle:Subscribe("CharacterAttemptLeave", function(self, _)
        return false
    end)

    SpawnThruster(vehicle)
    AttachVehicleLights(vehicle, character:GetTeam())
    AttachVehiclePlayerName(vehicle, character:GetPlayer(), character:GetTeam())
    AttachVehicleHat(vehicle, character:GetTeam())
    DecorateVehicle(vehicle, character:GetTeam())
    KeepVisible(vehicle)
    -- always sync cars at full rate, even from the other end of the arena
    vehicle:SetDistanceOptimizationMultiplier(0)

    character:EnterVehicle(vehicle)
    character:SetVisibility(Config.ShowCharactersOnVehicles)

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
    for parameter, value in pairs(hatConfig.parameters or {}) do
        hat:SetMaterialScalarParameter(parameter, value)
    end
    vehicle:SetValue("Hat", hat)
end

-- Halloween paint: the body tinted in the team's color
function DecorateVehicle(vehicle, team)
    if Config.PaintCars then
        vehicle:SetMaterialColorParameter("Tint", Theme.Teams[team].paint, -1, "body")
    end
end

-- changes a team's hat and swaps it on that team's cars already on the field
function SetTeamHat(team, hatConfig)
    if team == Team.TeamA then
        Game.HatA = hatConfig
    else
        Game.HatB = hatConfig
    end
    for _, vehicle in pairs(VehicleWheeled.GetAll()) do
        if vehicle:GetValue("Team") == team then
            local hat = vehicle:GetValue("Hat")
            if hat and hat:IsValid() then
                hat:Destroy()
            end
            AttachVehicleHat(vehicle, team)
        end
    end
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

function AttachVehiclePlayerName(vehicle, player, team)
    if not Config.ShowNamesOnVehicles then
        return
    end

    -- the team's color, washed out towards white so it reads at night
    local color = TeamColor(team)
    local text = Text3D(
        Vector(),
        Rotator(),
        player:GetName(),
        Vector(0.6),
        Color(0.45 + color.R * 0.55, 0.45 + color.G * 0.55, 0.45 + color.B * 0.55),
        FontType.OpenSans,
        Text3DAlignCamera.FaceCamera
    )

    text:AttachTo(vehicle, AttachmentRule.SnapToTarget, "", 1)
    -- -10 * (#name / 2)
    text:SetRelativeLocation(Vector(0, 0, 280))
    -- the driver doesn't see their own name over their car, but in the HUD (Client/NameTag.lua)
    text:SetValue("Driver", player:GetID(), true)
end

function CheckVehiclesOutOfBounds()
    for _, player in pairs(Player.GetAll()) do
        local character = player:GetControlledCharacter()
        if character then
            local vehicle = character:GetVehicle()
            if vehicle then
                local location = vehicle:GetLocation()
                if location.Z < -500 or location.Z > 6000 then
                    vehicle:SetLocation(Ternary(character:GetTeam() == Team.TeamA, Config.SpawnPointA, Config.SpawnPointB))
                end
            end
        end
    end
end