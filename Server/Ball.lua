Ball = Prop.Inherit("Ball")

local scale = 5
local massScale = 0.0001

local ball
local ribbon

function InitBall()
    ball = Ball(Config.BallSpawnPoint, Rotator(), "nanos-world::SM_Ball_VR")
    ball:SetScale(scale)
    ball:SetMassScale(massScale)
    ball:SetPhysicalMaterial('nanos-world::PM_Rubber')

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
            local player = other:GetPassenger(0):GetPlayer()
            print(player:GetName() .. " hit the ball!")
            Game.LastPlayerHitBall = player
            ToggleRibbon(player:GetControlledCharacter():GetTeam())
        else 
            print("Ball hit the ground: " .. tostring(other))
        end
    end)
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
end

function DestroyBall()
    if ball and ball:IsValid() then
        ball:Destroy()
    end
end

function ResetBall()
    DestroyBall()
    InitBall()
end

function UpdateBallRibbon()
    if ribbon and ribbon:IsValid() and ball and ball:IsValid() then
        local velocity = ball:GetVelocity():Size()
        if velocity < 2300 then
            ribbon:Deactivate()
            return
        elseif ribbon and ribbon:IsActive() then
            ribbon:Activate()
        end
        return
    end
end

function TeleportBall(location)
    if ball and ball:IsValid() then
        ball:SetLocation(location)
    end
end

function GetLastPlayerHitBall()
    if Game.LastPlayerHitBall then
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
