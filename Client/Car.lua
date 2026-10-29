-- Arcade car controller in the spirit of Rocket League.
-- Runs on the driver's client (the vehicle's network authority) and moves the car through
-- direct velocity changes every frame; the vehicle's engine, brakes and tire grip don't drive it.
-- Values are Rocket League's, scaled to this arena (~2.2x bigger, gravity 980 instead of 650).

CarTuning = {
    -- Ground (cm/s, cm/s²)
    MaxDriveSpeed = 3100,       -- top speed with throttle only
    MaxSpeed = 5000,            -- absolute cap, reached with boost
    ThrottleAccel = 3500,       -- at standstill, fades to 0 at MaxDriveSpeed
    BrakeAccel = 7700,          -- throttle against the direction of travel
    CoastDecel = 1150,          -- no throttle
    StickyAccel = 500,          -- pushes the car into the surface it is driving on

    -- Ground steering: yaw rate (rad/s) by forward speed (cm/s)
    TurnRate = {
        { 0, 0 },
        { 220, 0.65 },
        { 1100, 2.0 },
        { 2200, 2.35 },
        { 3300, 2.05 },
        { 5000, 2.0 },
    },
    TurnResponse = 20,          -- how fast the yaw rate reaches the target (1/s)
    LateralGrip = 14,           -- how fast sideways sliding is cancelled (1/s)
    PowerslideGrip = 1.5,
    PowerslideTurnMultiplier = 1.35,

    -- Boost
    BoostAccel = 2200,
    BoostDrain = 0,             -- per second, meter goes 0-100 (0 = infinite boost; Rocket League: 33.3)
    BoostRegen = 10,            -- per second while not boosting
    KickoffBoost = 100,

    -- Air (rad/s², rad/s)
    AirThrottleAccel = 150,
    AirPitchAccel = 12.5,
    AirYawAccel = 9.1,
    AirRollAccel = 36,
    AirPitchDamping = 2.8,      -- only while not pitching
    AirYawDamping = 1.9,        -- only while not yawing
    AirRollDamping = 4.75,
    AirMaxRotation = 5.5,

    -- Jump, double jump and dodge (flip)
    JumpSpeed = 530,
    JumpHoldAccel = 2650,       -- extra upward accel while holding jump right after jumping
    JumpHoldTime = 0.2,
    DoubleJumpWindow = 1.25,    -- seconds after the first jump to double jump or dodge
    DodgeSpeed = 1100,
    DodgeTime = 0.65,           -- duration of the flip (one full rotation)
    DodgeDeadzone = 0.5,
}

Input.Register("CarForward", "W", "Throttle / pitch down")
Input.Register("CarBackward", "S", "Reverse / pitch up")
Input.Register("CarLeft", "A", "Steer / yaw left")
Input.Register("CarRight", "D", "Steer / yaw right")
Input.Register("CarJump", "SpaceBar", "Jump, double jump, flip")
Input.Register("CarJump2", "RightMouseButton", "Jump, double jump, flip")
Input.Register("CarBoost", "LeftMouseButton", "Boost")
Input.Register("CarBoost2", "LeftShift", "Boost")
Input.Register("CarSlide", "LeftControl", "Powerslide / air roll with A and D")
Input.Register("CarRollLeft", "Q", "Air roll left")
Input.Register("CarRollRight", "E", "Air roll right")

local car = {
    vehicle = nil,
    grounded = false,
    groundIgnoreUntil = 0,      -- right after jumping the wheels still touch the ground for a few frames
    jumpTime = -100,
    jumpHolding = false,
    hasJumped = false,
    canDodge = false,
    dodgeUntil = 0,
    dodgeAxis = nil,            -- { forward, side } inputs of the current dodge
    boost = CarTuning.KickoffBoost,
    boosting = false,
    lastSentBoost = -1,
    prevAxes = nil,
    -- Throttle keys held when leaving the ground don't pitch the car until pressed again
    latched = {},
}

local PITCH_BINDINGS = { "CarForward", "CarBackward" }

local function LatchPitchInputs()
    for _, binding in ipairs(PITCH_BINDINGS) do
        car.latched[binding] = Input.IsBindingDown(binding)
    end
end

local function Axis(positive, negative)
    local value = 0
    if Input.IsBindingDown(positive) then value = value + 1 end
    if negative and Input.IsBindingDown(negative) then value = value - 1 end
    return value
end

-- Like Axis, but ignores keys still held since takeoff
local function AirAxis(positive, negative)
    for _, binding in ipairs(PITCH_BINDINGS) do
        if car.latched[binding] and not Input.IsBindingDown(binding) then
            car.latched[binding] = false
        end
    end
    local value = 0
    if Input.IsBindingDown(positive) and not car.latched[positive] then value = value + 1 end
    if Input.IsBindingDown(negative) and not car.latched[negative] then value = value - 1 end
    return value
end

local function Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function Sign(value)
    if value < 0 then return -1 end
    return 1
end

local function SampleCurve(curve, x)
    if x <= curve[1][1] then return curve[1][2] end
    for i = 2, #curve do
        local a, b = curve[i - 1], curve[i]
        if x <= b[1] then
            return a[2] + (b[2] - a[2]) * (x - a[1]) / (b[1] - a[1])
        end
    end
    return curve[#curve][2]
end

local function ThrottleAccelAt(speed)
    return CarTuning.ThrottleAccel * Clamp(1 - speed / CarTuning.MaxDriveSpeed, 0, 1)
end

local function GetLocalVehicle()
    local player = Client.GetLocalPlayer()
    local character = player and player:GetControlledCharacter()
    if not character or not character:IsValid() or not character:IsInputEnabled() then
        return nil
    end
    local vehicle = character:GetVehicle()
    if not vehicle or not vehicle:IsValid() or not vehicle:HasNetworkAuthority() then
        return nil
    end
    return vehicle
end

-- Angular velocity (rad/s, world space) from how the car's axes moved since last frame.
-- For a small rotation, the sum of old_axis x new_axis over the three axes is 2 * w * dt.
local function MeasureAngularVelocity(f, r, u, dt)
    local prev = car.prevAxes
    car.prevAxes = { f, r, u }
    if not prev or dt <= 0 then
        return Vector()
    end
    return (prev[1]:Cross(f) + prev[2]:Cross(r) + prev[3]:Cross(u)) * (1 / (2 * dt))
end

local function SetBoosting(boosting)
    if car.boosting == boosting then return end
    car.boosting = boosting
    Events.CallRemote("CarBoost", Reliability.Reliable, boosting)
end

-- Vehicle being driven here and whether it is boosting (Client/BoostFX.lua)
function GetLocalBoost()
    return car.vehicle, car.boosting
end

local function UpdateBoostMeter()
    local rounded = math.floor(car.boost + 0.5)
    if rounded ~= car.lastSentBoost then
        car.lastSentBoost = rounded
        Events.Call("UpdateBoost", rounded)
    end
end

local function Jump(vehicle)
    local now = Client.GetTime() / 1000
    local rotation = vehicle:GetRotation()

    if car.grounded then
        vehicle:AddImpulse(rotation:GetUpVector() * CarTuning.JumpSpeed, true)
        car.jumpTime = now
        car.jumpHolding = true
        car.hasJumped = true
        car.canDodge = true
        car.grounded = false
        car.groundIgnoreUntil = now + 0.15
        LatchPitchInputs()
        return
    end

    if not car.canDodge or now < car.dodgeUntil then return end
    if car.hasJumped and now - car.jumpTime > CarTuning.DoubleJumpWindow then return end
    car.canDodge = false
    car.jumpHolding = false

    local forwardInput = Axis("CarForward", "CarBackward")
    local sideInput = Axis("CarRight", "CarLeft")

    if math.abs(forwardInput) + math.abs(sideInput) < CarTuning.DodgeDeadzone then
        -- Double jump
        vehicle:AddImpulse(rotation:GetUpVector() * CarTuning.JumpSpeed, true)
        return
    end

    -- Dodge: horizontal burst towards the input, cancels falling and flips the car once
    local forward = rotation:GetForwardVector()
    local right = rotation:GetRightVector()
    local flatForward = Vector(forward.X, forward.Y, 0):GetSafeNormal()
    local flatRight = Vector(right.X, right.Y, 0):GetSafeNormal()
    local direction = (flatForward * forwardInput + flatRight * sideInput):GetSafeNormal()

    local impulse = direction * CarTuning.DodgeSpeed
    local velocity = vehicle:GetVelocity()
    if velocity.Z < 0 then
        impulse = impulse + Vector(0, 0, -velocity.Z)
    end
    vehicle:AddImpulse(impulse, true)

    car.dodgeAxis = { forwardInput, sideInput }
    car.dodgeUntil = now + CarTuning.DodgeTime
end

-- Body-frame helpers. With Unreal's axes, rotating around +right pitches the nose down,
-- around +up yaws to the right and around +forward rolls to the left.
local function DriveOnGround(vehicle, dt, f, r, u, velocity, w)
    local throttle = Axis("CarForward", "CarBackward")
    local steer = Axis("CarRight", "CarLeft")
    local sliding = Input.IsBindingDown("CarSlide")

    local forwardSpeed = velocity:Dot(f)
    local sideSpeed = velocity:Dot(r)
    local accel = 0

    if car.boosting then
        throttle = 1
        accel = CarTuning.BoostAccel
    end

    if throttle ~= 0 then
        if forwardSpeed * throttle < 0 and math.abs(forwardSpeed) > 50 then
            accel = accel + throttle * CarTuning.BrakeAccel
        else
            accel = accel + throttle * ThrottleAccelAt(math.abs(forwardSpeed))
        end
    else
        accel = -Sign(forwardSpeed) * math.min(CarTuning.CoastDecel, math.abs(forwardSpeed) / dt)
    end

    local grip = sliding and CarTuning.PowerslideGrip or CarTuning.LateralGrip
    local deltaV = f * (accel * dt)
        - r * (sideSpeed * math.min(1, grip * dt))
        - u * (CarTuning.StickyAccel * dt)

    -- Yaw: turn at a fixed rate for the current speed, reversing flips the direction
    local turnRate = SampleCurve(CarTuning.TurnRate, math.abs(forwardSpeed))
    if sliding then
        turnRate = turnRate * CarTuning.PowerslideTurnMultiplier
    end
    local targetYaw = steer * turnRate * Sign(forwardSpeed)
    local yaw = w:Dot(u)
    vehicle:AddAngularImpulse(u * ((targetYaw - yaw) * math.min(1, CarTuning.TurnResponse * dt)), true)

    return deltaV
end

local function ControlInAir(vehicle, dt, f, r, u, w, now)
    local deltaV = f * (Axis("CarForward") * CarTuning.AirThrottleAccel * dt)
    if car.boosting then
        deltaV = deltaV + f * (CarTuning.BoostAccel * dt)
    end

    -- Dodge in progress: spin a full turn around the dodge axis, no air control
    if now < car.dodgeUntil then
        local rate = 2 * math.pi / CarTuning.DodgeTime
        local target = r * (car.dodgeAxis[1] * rate) - f * (car.dodgeAxis[2] * rate)
        target = target:GetSafeNormal() * rate
        vehicle:AddAngularImpulse(target - w, true)
        return deltaV
    elseif car.dodgeAxis then
        car.dodgeAxis = nil
        vehicle:AddAngularImpulse(-w, true)
        return deltaV
    end

    local pitchInput = AirAxis("CarForward", "CarBackward")
    local yawInput = Axis("CarRight", "CarLeft")
    local rollInput = Axis("CarRollRight", "CarRollLeft")
    if Input.IsBindingDown("CarSlide") then
        rollInput = Clamp(rollInput + yawInput, -1, 1)
        yawInput = 0
    end

    -- Current rates: pitch (nose down +), yaw (right +), roll (right +)
    local pitch = w:Dot(r)
    local yaw = w:Dot(u)
    local roll = -w:Dot(f)

    pitch = pitch + (pitchInput * CarTuning.AirPitchAccel - (1 - math.abs(pitchInput)) * CarTuning.AirPitchDamping * pitch) * dt
    yaw = yaw + (yawInput * CarTuning.AirYawAccel - (1 - math.abs(yawInput)) * CarTuning.AirYawDamping * yaw) * dt
    roll = roll + (rollInput * CarTuning.AirRollAccel - CarTuning.AirRollDamping * roll) * dt

    local target = r * pitch + u * yaw - f * roll
    if target:Size() > CarTuning.AirMaxRotation then
        target = target:GetSafeNormal() * CarTuning.AirMaxRotation
    end
    vehicle:AddAngularImpulse(target - w, true)

    return deltaV
end

local function OnJumpPressed()
    local vehicle = GetLocalVehicle()
    if vehicle then
        Jump(vehicle)
    end
end
Input.Bind("CarJump", InputEvent.Pressed, OnJumpPressed)
Input.Bind("CarJump2", InputEvent.Pressed, OnJumpPressed)

Client.Subscribe("Tick", function(dt)
    local vehicle = GetLocalVehicle()
    if vehicle ~= car.vehicle then
        car.vehicle = vehicle
        car.prevAxes = nil
        car.dodgeAxis = nil
        car.dodgeUntil = 0
        SetBoosting(false)
    end
    if not vehicle or dt <= 0 then
        return
    end

    local now = Client.GetTime() / 1000
    local rotation = vehicle:GetRotation()
    local f, r, u = rotation:GetForwardVector(), rotation:GetRightVector(), rotation:GetUpVector()
    local velocity = vehicle:GetVelocity()
    local w = MeasureAngularVelocity(f, r, u, dt)

    local wasGrounded = car.grounded
    car.grounded = now >= car.groundIgnoreUntil and not vehicle:IsInAir()
    if wasGrounded and not car.grounded then
        LatchPitchInputs()
    elseif car.grounded and not wasGrounded then
        car.hasJumped = false
        car.canDodge = true
        car.dodgeAxis = nil
        car.dodgeUntil = 0
    end

    -- Boost meter
    local wantsBoost = Input.IsBindingDown("CarBoost") or Input.IsBindingDown("CarBoost2")
    SetBoosting(wantsBoost and car.boost > 0)
    if car.boosting then
        car.boost = math.max(0, car.boost - CarTuning.BoostDrain * dt)
    elseif not wantsBoost then
        -- no regen while the button is held on an empty meter, or boost would flicker on and off every frame
        car.boost = math.min(100, car.boost + CarTuning.BoostRegen * dt)
    end
    -- infinite boost: the meter stays hidden in the HUD
    if CarTuning.BoostDrain > 0 then
        UpdateBoostMeter()
    end

    local deltaV
    if car.grounded then
        deltaV = DriveOnGround(vehicle, dt, f, r, u, velocity, w)
    else
        deltaV = ControlInAir(vehicle, dt, f, r, u, w, now)
    end

    -- Holding jump right after the first jump makes it higher
    if car.jumpHolding then
        local holding = Input.IsBindingDown("CarJump") or Input.IsBindingDown("CarJump2")
        if holding and now - car.jumpTime < CarTuning.JumpHoldTime then
            deltaV = deltaV + u * (CarTuning.JumpHoldAccel * dt)
        else
            car.jumpHolding = false
        end
    end

    -- Speed cap
    local newVelocity = velocity + deltaV
    local speed = newVelocity:Size()
    if speed > CarTuning.MaxSpeed then
        deltaV = newVelocity * (CarTuning.MaxSpeed / speed) - velocity
    end

    vehicle:AddImpulse(deltaV, true)
end)

-- Every kickoff starts with the same boost
Events.SubscribeRemote("UpdateCountDownTime", function()
    car.boost = CarTuning.KickoffBoost
end)
