-- The ball is a giant jack-o'-lantern. Each client hides the ball's own sphere (a masked material cut out
-- completely) and puts round it a pumpkin with a carved face glowing from inside (burn-the-witch-vfx
-- SM_FX_Pumpkin), a candle light flickering in it, and a hollow bonk whenever something hits it.
-- The server's ball is untouched: same size, physics and "IsBall" value (Server/Ball.lua)

local PUMPKIN = "burn-the-witch-vfx::SM_FX_Pumpkin"
local PUMPKIN_SIZE = Vector(100, 100, 79)   -- the mesh at scale 1, centred on its origin (cm)
local PUMPKIN_FIT = Vector(1.06, 1.06, 0.94) -- of the ball's diameter: a little wider and flatter than it
local BALL_RADIUS = 352                     -- if the bounds can't be read: the rest height 497 - the floor 145
local CANDLE_COLOR = Color(1.0, 0.45, 0.08)
local CANDLE_INTENSITY = 90
local BONK_SPEED_CHANGE = 1500              -- cm/s lost or gained in a frame that sounds like a hit
local BONK_COOLDOWN = 0.15                  -- seconds
local RENDER_CULL_DISTANCE = 1000000

local dressed = nil     -- the ball we dressed: { ball, pumpkin, light, velocity, last_bonk }

local function FindBall()
    for _, prop in pairs(Prop.GetAll()) do
        if prop:IsValid() and prop:GetValue("IsBall") then
            return prop
        end
    end
end

-- The pumpkin's scale for the ball's diameter
local function PumpkinScale(diameter)
    return Vector(
        diameter * PUMPKIN_FIT.X / PUMPKIN_SIZE.X,
        diameter * PUMPKIN_FIT.Y / PUMPKIN_SIZE.Y,
        diameter * PUMPKIN_FIT.Z / PUMPKIN_SIZE.Z
    )
end

local function Dress(ball)
    -- its size as it is in the world; a reading far off (bounds swollen by the trail attached to it) is ignored
    local bounds = ball:GetBounds()
    local radius = bounds and bounds.SphereRadius
    if not radius or radius < BALL_RADIUS * 0.5 or radius > BALL_RADIUS * 2 then radius = BALL_RADIUS end
    local scale = PumpkinScale(radius * 2)

    ball:SetMaterial("nanos-world::M_Default_Masked_Lit")
    ball:SetMaterialScalarParameter("Opacity", 0)
    ball:SetCastShadow(false)

    local pumpkin = StaticMesh(ball:GetLocation(), ball:GetRotation(), PUMPKIN, CollisionType.NoCollision)
    pumpkin:AttachTo(ball, AttachmentRule.SnapToTarget, "", 0)
    pumpkin:SetRelativeLocation(Vector())
    pumpkin:SetScale(scale)
    pumpkin:SetRenderCullDistance(RENDER_CULL_DISTANCE)

    -- If the scale turned out relative to the ball's own (5), the pumpkin is that much too big: measure it
    -- once it has been placed and bring it back
    Timer.SetTimeout(function()
        if not pumpkin:IsValid() or not ball:IsValid() then return end
        local measured = pumpkin:GetBounds()
        local expected = 0.5 * Vector(PUMPKIN_SIZE.X * scale.X, PUMPKIN_SIZE.Y * scale.Y, PUMPKIN_SIZE.Z * scale.Z):Size()
        local parent_scale = ball:GetScale().X
        if measured and measured.SphereRadius and parent_scale > 1.5 and measured.SphereRadius > expected * (parent_scale * 0.6) then
            pumpkin:SetScale(scale * (1 / parent_scale))
        end
    end, 100)

    local light = Light(Vector(), Rotator(), CANDLE_COLOR, LightType.Point, CANDLE_INTENSITY, radius * 5, 44, 0,
        30000, true, false, true)
    light:AttachTo(ball, AttachmentRule.SnapToTarget, "", 0)
    light:SetRelativeLocation(Vector())

    dressed = { ball = ball, pumpkin = pumpkin, light = light, velocity = nil, last_bonk = 0 }
end

Client.Subscribe("Tick", function(dt)
    if not dressed or not dressed.ball:IsValid() then
        dressed = nil
        local ball = FindBall()
        if ball then Dress(ball) end
        return
    end

    local ball = dressed.ball
    local now = Client.GetTime() / 1000

    -- the candle flickers
    if dressed.light:IsValid() then
        dressed.light:SetIntensity(CANDLE_INTENSITY * (0.75 + 0.35 * math.random()))
    end

    -- a sudden change of speed is a hit: a car, a wall, the floor
    local velocity = ball:GetVelocity()
    if dressed.velocity then
        local change = (velocity - dressed.velocity):Size()
        if change > BONK_SPEED_CHANGE and now - dressed.last_bonk > BONK_COOLDOWN then
            dressed.last_bonk = now
            PlayBonk(ball:GetLocation(), math.min(1, change / 6000))
        end
    end
    dressed.velocity = velocity
end)

-- Where the pumpkin is now, for the goal celebration (Client/Spooks.lua); nil if there is none
function GetPumpkinLocation()
    if dressed and dressed.ball:IsValid() then
        return dressed.ball:GetLocation()
    end
end
