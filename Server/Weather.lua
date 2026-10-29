Package.Require("Tables.lua")

-- Lightning over the graveyard round the arena. The server picks when and where, so every player sees
-- the same bolt and hears the same thunder (Client/Atmosphere.lua draws it); more often in the last minute

local function InWitchingHour()
    return Game.State == State.Running and Game.Timer <= Config.WitchingHour
end

-- A spot in the sky outside the dome, all round it; seed picks the bolt and the thunder on the clients
function StrikeLightning()
    local angle = math.random() * math.pi * 2
    local distance = math.random(26000, 60000)
    local location = Vector(math.cos(angle) * distance, math.sin(angle) * distance, math.random(9000, 16000))
    Events.BroadcastRemote("Lightning", Reliability.Unreliable, location, math.random(1, 1000))
end

local function ScheduleLightning()
    local range = InWitchingHour() and Config.WitchingLightningInterval or Config.LightningInterval
    Timer.SetTimeout(function()
        StrikeLightning()
        ScheduleLightning()
    end, math.random(range[1] * 1000, range[2] * 1000))
end

ScheduleLightning()
