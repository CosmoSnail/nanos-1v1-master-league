-- Ball cam, as in Rocket League: while on, the camera stays behind the car on the line from the ball,
-- so the ball is always in front. Toggled with F (rebindable); the HUD shows "BALL CAM" while on.

RegisterKey("CarBallCam", "F", "Toggle ball cam (pumpkin cam)")

local PITCH_OFFSET = -10        -- degrees: looks a bit down on the car so it doesn't hide the ball
local MIN_PITCH = -40
local MAX_PITCH = 10            -- looking up more would drop the camera under the car
local FOLLOW_SPEED = 10         -- how fast the camera turns to the target (1/s)

local enabled = false
local ball = nil

-- The ball is the Prop the server marks with the "IsBall" value (Server/Ball.lua)
local function FindBall()
    if ball and ball:IsValid() then return ball end
    ball = nil
    for _, prop in pairs(Prop.GetAll()) do
        if prop:GetValue("IsBall") then
            ball = prop
            break
        end
    end
    return ball
end

local function GetDrivenVehicle()
    local player = Client.GetLocalPlayer()
    local character = player and player:GetControlledCharacter()
    local vehicle = character and character:IsValid() and character:GetVehicle()
    if vehicle and vehicle:IsValid() then
        return vehicle
    end
end

-- Shortest signed difference between two angles, in degrees
local function AngleDelta(from, to)
    return (to - from + 180) % 360 - 180
end

BindKey("CarBallCam", InputEvent.Pressed, function()
    enabled = not enabled
    Events.Call("UpdateBallCam", enabled)
end)

-- The mouse doesn't turn the camera while ball cam drives it
Input.Subscribe("MouseMove", function()
    if enabled and not Input.IsMouseEnabled() and GetDrivenVehicle() then
        return false
    end
end)

Client.Subscribe("Tick", function(dt)
    if not enabled or dt <= 0 then return end

    local vehicle = GetDrivenVehicle()
    local target = vehicle and FindBall()
    if not target then return end

    local look = (target:GetLocation() - vehicle:GetLocation()):ToOrientationRotator()
    local pitch = math.max(MIN_PITCH, math.min(MAX_PITCH, look.Pitch + PITCH_OFFSET))

    local player = Client.GetLocalPlayer()
    local current = player:GetCameraRotation()
    local t = math.min(1, FOLLOW_SPEED * dt)
    player:SetCameraRotation(Rotator(
        current.Pitch + AngleDelta(current.Pitch, pitch) * t,
        current.Yaw + AngleDelta(current.Yaw, look.Yaw) * t,
        0
    ))
end)
