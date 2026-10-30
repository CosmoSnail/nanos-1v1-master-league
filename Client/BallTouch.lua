-- Touches of the ball as the driver sees them, told to the server (Server/Ball.lua checks and counts them). The
-- server's Hit events alone miss some: the ball is simulated on one client only, and a light touch (a push, a
-- dribble) doesn't always make one, so a goal could go to nobody ("nil")
local BALL_RADIUS = 352
-- the Offroad's box round its origin (its mesh, with the wheels and the cage), and how near to it still counts
local CAR_MIN = Vector(-175, -150, 0)
local CAR_MAX = Vector(205, 150, 180)
local TOUCH_MARGIN = 40
local REPORT_EVERY = 0.15       -- seconds between two reports while it keeps touching

local ball = nil
local last_report = 0

local function FindBall()
    if ball and ball:IsValid() then return ball end
    ball = nil
    for _, prop in pairs(Prop.GetAll()) do
        if prop:IsValid() and prop:GetValue("IsBall") then
            ball = prop
            break
        end
    end
    return ball
end

-- How far the ball's surface is from the car's box (below 0: into it)
local function Gap(vehicle, location)
    local p = vehicle:GetRotation():UnrotateVector(location - vehicle:GetLocation())
    local dx = math.max(CAR_MIN.X - p.X, 0, p.X - CAR_MAX.X)
    local dy = math.max(CAR_MIN.Y - p.Y, 0, p.Y - CAR_MAX.Y)
    local dz = math.max(CAR_MIN.Z - p.Z, 0, p.Z - CAR_MAX.Z)
    return math.sqrt(dx * dx + dy * dy + dz * dz) - BALL_RADIUS
end

Client.Subscribe("Tick", function()
    local player = Client.GetLocalPlayer()
    local character = player and player:GetControlledCharacter()
    local vehicle = character and character:GetVehicle()
    local current = FindBall()
    if not vehicle or not vehicle:IsValid() or not current then return end

    local now = Client.GetTime() / 1000
    if now - last_report >= REPORT_EVERY and Gap(vehicle, current:GetLocation()) < TOUCH_MARGIN then
        last_report = now
        Events.CallRemote("BallTouch", Reliability.Reliable, current:GetLocation())
    end
end)
