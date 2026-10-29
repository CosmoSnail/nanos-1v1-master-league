Package.Require("Tables.lua")

-- Lightning over the graveyard round the arena, silent. The server picks when and where, so every player sees
-- the same bolt (Client/Atmosphere.lua draws it); more and more often as a game goes on, like the night
-- deepening on the clients

-- How much of the game has been played: 0 when it starts, 1 when time is up (and on the end screen)
local function Played()
    if Game.State == State.Ended then return 1 end
    return math.max(0, math.min(1, 1 - Game.Timer / Config.GameDuration))
end

-- Where it hits the ground outside the dome, all round it (the bolt rises from there up to the clouds); seed
-- picks the bolt on the clients
local GROUND_Z = 120    -- the ground round the dome (Client/Arena.lua)

function StrikeLightning()
    local angle = math.random() * math.pi * 2
    local distance = math.random(45000, 110000)
    local location = Vector(math.cos(angle) * distance, math.sin(angle) * distance, GROUND_Z)
    Events.BroadcastRemote("Lightning", Reliability.Unreliable, location, math.random(1, 1000))
end

local function ScheduleLightning()
    local k = Played() ^ 2
    local first, last = Config.LightningInterval, Config.FinalLightningInterval
    local low = first[1] + (last[1] - first[1]) * k
    local high = first[2] + (last[2] - first[2]) * k
    Timer.SetTimeout(function()
        StrikeLightning()
        ScheduleLightning()
    end, math.floor((low + (high - low) * math.random()) * 1000))
end

ScheduleLightning()
