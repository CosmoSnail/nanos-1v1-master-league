-- Boost flames drawn on every client: solid flame cones attached to the thrusters, a rocket exhaust
-- particle on each nozzle and a flickering light behind the car.
-- The driver's own car reacts to its local boost state right away; the other cars follow the
-- "Boosting" value the server replicates.

-- Nozzles in vehicle space: thruster offsets of Server/Thruster.lua + 40 cm to the back of the thruster
local NOZZLES = {
    Vector(-190, 40, 45),
    Vector(-190, -40, 45),
}

local FLAME_LENGTH = 1.9        -- outer cone length (x100 cm)
local FLAME_WIDTH = 0.49        -- outer cone base diameter (x100 cm)
local CORE_LENGTH = 1.0
local CORE_WIDTH = 0.28
local IGNITE_SPEED = 12         -- how fast the flames grow when boosting starts (1/s)
local FADE_SPEED = 8            -- and shrink when it stops
local LIGHT_INTENSITY = 9
-- Any of the default pack's P_RocketExhaust_* (Afterburn, Afterburn_Jet, Realistic, Crackling, Plume_01...)
local EXHAUST_PARTICLE = "nanos-world::P_RocketExhaust_Afterburn"
local EXHAUST_SCALE = 0.4
local RENDER_CULL_DISTANCE = 1000000  -- whole arena, like Config.RenderCullDistance on the server

local OUTER_EMISSIVE = Color(2, 0.4, 0.05)
local CORE_EMISSIVE = Color(3.5, 2.5, 1.1)

-- vehicle -> { cones = { { mesh, nozzle, length, width } }, exhausts = {}, light, power, burning }
local effects = {}

-- SM_Cone points +Z with the pivot at its center: pitch 90 makes it point backwards (-X)
local function SpawnCone(vehicle, nozzle, emissive, opacity)
    local cone = StaticMesh(Vector(), Rotator(), "nanos-world::SM_Cone", CollisionType.NoCollision)
    cone:SetMaterial("nanos-world::M_Default_Translucent_Lit")
    cone:SetMaterialColorParameter("Tint", Color(0, 0, 0))
    cone:SetMaterialColorParameter("Emissive", emissive)
    cone:SetMaterialScalarParameter("Opacity", opacity)
    cone:AttachTo(vehicle, AttachmentRule.SnapToTarget, "", 0)
    cone:SetRelativeLocation(nozzle)
    cone:SetRelativeRotation(Rotator(90, 0, 0))
    cone:SetVisibility(false)
    cone:SetRenderCullDistance(RENDER_CULL_DISTANCE)
    return cone
end

local function CreateEffect(vehicle)
    local fx = { cones = {}, exhausts = {}, power = 0, burning = false }

    for _, nozzle in ipairs(NOZZLES) do
        table.insert(fx.cones, { mesh = SpawnCone(vehicle, nozzle, OUTER_EMISSIVE, 0.55), nozzle = nozzle, length = FLAME_LENGTH, width = FLAME_WIDTH })
        table.insert(fx.cones, { mesh = SpawnCone(vehicle, nozzle, CORE_EMISSIVE, 0.9), nozzle = nozzle, length = CORE_LENGTH, width = CORE_WIDTH })

        -- the exhaust blows along +X: pitch 180 turns it backwards (like the sandbox thrusters)
        local exhaust = Particle(Vector(), Rotator(), EXHAUST_PARTICLE, false, false)
        exhaust:AttachTo(vehicle, AttachmentRule.SnapToTarget, "", 0)
        exhaust:SetRelativeLocation(nozzle)
        exhaust:SetRelativeRotation(Rotator(180, 0, 0))
        exhaust:SetScale(Vector(EXHAUST_SCALE))
        exhaust:SetRenderCullDistance(RENDER_CULL_DISTANCE)
        table.insert(fx.exhausts, exhaust)
    end

    fx.light = Light(Vector(), Rotator(), Color(1, 0.45, 0.1), LightType.Point, 0, 600, 44, 0, 8000, true, false, true)
    fx.light:AttachTo(vehicle, AttachmentRule.SnapToTarget, "", 0)
    fx.light:SetRelativeLocation(Vector(-260, 0, 50))
    fx.light:SetRenderCullDistance(RENDER_CULL_DISTANCE)

    effects[vehicle] = fx
    return fx
end

local function DestroyEffect(vehicle)
    local fx = effects[vehicle]
    if not fx then return end
    for _, cone in ipairs(fx.cones) do
        if cone.mesh:IsValid() then cone.mesh:Destroy() end
    end
    for _, exhaust in ipairs(fx.exhausts) do
        if exhaust:IsValid() then exhaust:Destroy() end
    end
    if fx.light:IsValid() then fx.light:Destroy() end
    effects[vehicle] = nil
end

local function SetExhausts(fx, boosting)
    if fx.burning == boosting then return end
    fx.burning = boosting
    for _, exhaust in ipairs(fx.exhausts) do
        if boosting then exhaust:Activate(true) else exhaust:Deactivate() end
    end
end

local function UpdateEffect(vehicle, fx, boosting, dt)
    SetExhausts(fx, boosting)

    local target = boosting and 1 or 0
    local speed = boosting and IGNITE_SPEED or FADE_SPEED
    fx.power = fx.power + (target - fx.power) * math.min(1, speed * dt)
    if not boosting and fx.power < 0.02 then fx.power = 0 end

    local visible = fx.power > 0
    for _, cone in ipairs(fx.cones) do
        cone.mesh:SetVisibility(visible)
        if visible then
            -- flicker: every cone gets its own length and width each frame
            local length = cone.length * fx.power * (0.8 + math.random() * 0.4)
            local width = cone.width * (0.6 + 0.4 * fx.power) * (0.9 + math.random() * 0.2)
            cone.mesh:SetScale(Vector(width, width, length))
            -- keep the wide base of the cone on the nozzle
            cone.mesh:SetRelativeLocation(cone.nozzle + Vector(-50 * length, 0, 0))
        end
    end
    fx.light:SetIntensity(LIGHT_INTENSITY * fx.power * (0.75 + math.random() * 0.5))
end

Client.Subscribe("Tick", function(dt)
    local localVehicle, localBoosting = GetLocalBoost()

    for _, vehicle in pairs(Vehicle.GetAll()) do
        if vehicle:IsValid() then
            local boosting
            if vehicle == localVehicle then
                boosting = localBoosting
            else
                boosting = vehicle:GetValue("Boosting") == true
            end
            local fx = effects[vehicle]
            if boosting or (fx and fx.power > 0) then
                UpdateEffect(vehicle, fx or CreateEffect(vehicle), boosting, dt)
            end
        end
    end

    for vehicle in pairs(effects) do
        if not vehicle:IsValid() then
            DestroyEffect(vehicle)
        end
    end
end)

Vehicle.Subscribe("Destroy", DestroyEffect)
