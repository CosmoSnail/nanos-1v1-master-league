Ball = Prop.Inherit("Ball")

local scale = 5
local massScale = 0.0001

local ball
local ribbon

-- How far the server may see a car from the ball when its driver says they touched it: the two positions reach
-- it late, each by its own client's ping (a car at full speed covers 5 m in a tenth of a second)
local TOUCH_CHECK_DISTANCE = 1500

-- A touch of the ball by this player, from a Hit event or told by their own client (Client/BallTouch.lua); one
-- told just after a goal still counts until its scorer is decided (Goal.lua)
local function RegisterBallTouch(player)
    if IsNewTouch(player) then
        LogBallTouch(player)
        if Game.State == State.Running or GoalPending() then
            AddBallTouch(player)
        end
        if ball and ball:IsValid() then
            ToggleRibbon(player:GetControlledCharacter():GetTeam())
        end
    end
    Game.LastPlayerHitBall = player
end

-- ball_location: where the driver saw the ball when they touched it
Events.SubscribeRemote("BallTouch", function(player, ball_location)
    local character = player:GetControlledCharacter()
    local vehicle = character and character:GetVehicle()
    if not vehicle or not vehicle:IsValid() then return end
    -- already past the goal line: a touch after the goal (a keeper chasing it into the net), not before it
    local ok, in_goal = pcall(InGoal, ball_location)
    if ok and in_goal then return end
    local where
    if ball and ball:IsValid() then
        where = ball:GetLocation()
    elseif GoalPending() then
        where = Game.PendingGoal.location
    else
        return
    end
    if (vehicle:GetLocation() - where):Size() > TOUCH_CHECK_DISTANCE then return end
    RegisterBallTouch(player)
end)

function InitBall()
    ball = Ball(Config.BallSpawnPoint, Rotator(), "nanos-world::SM_Ball_VR")
    ball:SetScale(scale)
    ball:SetMassScale(massScale)
    ball:SetPhysicalMaterial('nanos-world::PM_Rubber')
    KeepVisible(ball)
    -- lets the clients find the ball (Client/BallCam.lua)
    ball:SetValue("IsBall", true, true)
    -- always sync the ball at full rate, even from the other end of the arena
    ball:SetDistanceOptimizationMultiplier(0)

    -- local trigger = Trigger(Config.BallSpawnPoint, Rotator(), 665, TriggerType.Sphere, Config.ShowTriggers, Color(0, 1, 0), {"Vehicle"})
    -- trigger:AttachTo(ball, AttachmentRule.SnapToTarget, nil, 0, false)
    -- trigger:SetRelativeLocation(Vector(0, 0, 0))

    -- trigger:Subscribe("BeginOverlap", function(trigger, vehicle)
    --     local player = vehicle:GetPassenger(0):GetPlayer()
    --     print(player:GetName() .. " hit the ball!")
    --     Game.LastPlayerHitBall = player
    --     ToggleRibbon(player:GetControlledCharacter():GetTeam())
    -- end)

    ball:Subscribe("Hit", function(self, impact_force, normal_impulse, impact_location, velocity, other)
        if other and other:IsA(Offroad) then
            local driver = other:GetPassenger(0)
            local player = driver and driver:GetPlayer()
            if not player then return end
            RegisterBallTouch(player)
        end
    end)
end

-- One touch keeps firing Hit for a few frames: a new touch is a new player, or the same one again after a pause
local lastTouchPlayer
local lastTouchTime = 0

function IsNewTouch(player)
    local now = Server.GetTime()
    local new = player ~= lastTouchPlayer or now - lastTouchTime >= 500
    lastTouchPlayer = player
    lastTouchTime = now
    return new
end

function LogBallTouch(player)
    if not Config.LogBallTouches then return end

    local team = TeamName(player:GetControlledCharacter():GetTeam())
    local message = player:GetName() .. " (" .. team .. ") touched the pumpkin"
    print(message)
    -- in dev mode it also goes to the chat
    if Config.EnableCommands and Config.LogLevel ~= LogLevel.GameChat then
        Chat.BroadcastMessage(message)
    end
end

function ToggleRibbon(team)
    if ribbon and ribbon:IsValid() then
        ribbon:Destroy()
    end

    ribbon = Particle(
        ball:GetLocation(),
        Rotator(0, 0, 0),
        "nanos-world::P_Ribbon",
        false,
        true
    )
    ribbon:SetParameterColor("Color", Ternary(team == Team.TeamA, Config.ColorA, Config.ColorB))
    ribbon:SetParameterFloat("SpawnRate", 50.0)
    ribbon:SetParameterFloat("LifeTime", 0.3)
    ribbon:SetParameterFloat("RibbonWidth", 30.0)
    ribbon:AttachTo(ball, AttachmentRule.SnapToTarget, "", 0)
    KeepVisible(ribbon)
end

function DestroyBall()
    if ball and ball:IsValid() then
        ball:Destroy()
    end
end

function ResetBall()
    DestroyBall()
    ClearBallTouches()
    -- a goal before anyone touches the new ball has no scorer (not whoever touched the last one)
    Game.LastPlayerHitBall = nil
    InitBall()
end

function UpdateBallRibbon()
    if ribbon and ribbon:IsValid() and ball and ball:IsValid() then
        -- the hit velocity may reach the server a few ticks after the Hit event, so the ribbon
        -- has to come back on once the ball speeds up (only toggle on change: each call is replicated)
        local fast = ball:GetVelocity():Size() >= 2300
        if fast ~= ribbon:IsActive() then
            if fast then
                ribbon:Activate()
            else
                ribbon:Deactivate()
            end
        end
    end
end

function TeleportBall(location)
    if ball and ball:IsValid() then
        ball:SetLocation(location)
    end
end

function GetLastPlayerHitBall()
    if Game.LastPlayerHitBall and Game.LastPlayerHitBall:IsValid() then
        return Game.LastPlayerHitBall
    end
    return {
        GetName = function() return "nil" end,
        GetAccountIconURL = function() return "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/Atheism_symbol_syreeni.svg/1280px-Atheism_symbol_syreeni.svg.png" end
    }
end

function CheckBallOutOfBounds()
    if ball and ball:IsValid() then
        if ball:GetLocation().Z < -500 then
            print("Ball out of bounds! Resetting position.")
            ResetBall()
        end
    end
end
