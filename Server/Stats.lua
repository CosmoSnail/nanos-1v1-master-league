Package.Require("Tables.lua")

-- Stats of each player in the current game, shown in the leaderboard (held with Tab, and in the end of
-- game screen). Points like in Rocket League: a goal is worth more than an assist, which is worth more than a hit

local POINTS_GOAL = 100
local POINTS_ASSIST = 50
local POINTS_HIT = 2
-- a teammate's touch up to this long before the goal is an assist, if no opponent touched the ball in between
local ASSIST_WINDOW = 10000 -- ms

local stats = {}      -- player -> { score, goals, assists, hits }
local touches = {}    -- ball touches since the last kickoff, oldest first: { player, team, time }
local dirty = true    -- the leaderboard changed since it was last sent

local function GetStats(player)
    local s = stats[player]
    if not s then
        s = { score = 0, goals = 0, assists = 0, hits = 0 }
        stats[player] = s
    end
    return s
end

local function GetPlayerTeam(player)
    local character = player:GetControlledCharacter()
    return character and character:GetTeam() or 0
end

function ResetStats()
    stats = {}
    touches = {}
    dirty = true
end

-- A new ball: the touches before it no longer make goals or assists
function ClearBallTouches()
    touches = {}
end

function AddBallTouch(player)
    local s = GetStats(player)
    s.hits = s.hits + 1
    s.score = s.score + POINTS_HIT
    table.insert(touches, { player = player, team = GetPlayerTeam(player), time = Server.GetTime() })
    dirty = true
end

-- The goal goes to the last player of the scoring team who touched the ball (even if an opponent touched it
-- last and put it in their own goal), the assist to the teammate who touched it before them.
-- Returns the scorer and the assister, either may be nil
function CreditGoal(team)
    local scorer, scorer_index
    for i = #touches, 1, -1 do
        local touch = touches[i]
        if touch.team == team and touch.player:IsValid() then
            scorer, scorer_index = touch.player, i
            break
        end
    end
    if not scorer then return nil, nil end

    local assister
    local now = Server.GetTime()
    for i = scorer_index - 1, 1, -1 do
        local touch = touches[i]
        if touch.team ~= team or now - touch.time > ASSIST_WINDOW then break end
        if touch.player ~= scorer and touch.player:IsValid() then
            assister = touch.player
            break
        end
    end

    local s = GetStats(scorer)
    s.goals = s.goals + 1
    s.score = s.score + POINTS_GOAL
    if assister then
        s = GetStats(assister)
        s.assists = s.assists + 1
        s.score = s.score + POINTS_ASSIST
    end
    dirty = true
    return scorer, assister
end

-- Best player of the winning team (of everyone on a draw), nil if nobody scored a point
local function GetMVP(winner)
    local best, best_stats
    for _, player in pairs(Player.GetAll()) do
        local s = stats[player]
        if s and s.score > 0 and (winner == 0 or GetPlayerTeam(player) == winner) then
            if not best or s.score > best_stats.score or (s.score == best_stats.score and s.goals > best_stats.goals) then
                best, best_stats = player, s
            end
        end
    end
    return best
end

-- What the end of game screen shows, kept for the players who join before the next game
function BuildGameOverInfo()
    local winner = 0
    if Game.ScoreA > Game.ScoreB then
        winner = Team.TeamA
    elseif Game.ScoreB > Game.ScoreA then
        winner = Team.TeamB
    end

    local info = { winner = winner, scoreA = Game.ScoreA, scoreB = Game.ScoreB, nextGameIn = Game.EndedTimer }
    local mvp = GetMVP(winner)
    if mvp then
        info.mvp = { id = mvp:GetID(), name = mvp:GetName(), avatar = mvp:GetAccountIconURL(), team = GetPlayerTeam(mvp) }
    end
    return info
end

local function BuildLeaderboard()
    local rows = {}
    for _, player in pairs(Player.GetAll()) do
        local s = stats[player] or { score = 0, goals = 0, assists = 0, hits = 0 }
        table.insert(rows, {
            id = player:GetID(),
            name = player:GetName(),
            avatar = player:GetAccountIconURL(),
            team = GetPlayerTeam(player),
            score = s.score,
            goals = s.goals,
            assists = s.assists,
            hits = s.hits,
            ping = player:GetPing(),
        })
    end
    return rows
end

-- To one player, or to everyone without one
function SendLeaderboard(player)
    dirty = false
    if player then
        Events.CallRemote("UpdateLeaderboard", player, Reliability.Reliable, BuildLeaderboard())
    else
        Events.BroadcastRemote("UpdateLeaderboard", Reliability.Reliable, BuildLeaderboard())
    end
end

-- Sent as soon as it changes, and every few seconds anyway for the pings and team changes
local ticks = 0
Timer.SetInterval(function()
    ticks = ticks + 1
    if dirty or ticks % 6 == 0 then
        SendLeaderboard()
    end
end, 500)

Player.Subscribe("Ready", function(player)
    SendLeaderboard(player)
    if Game.State == State.Ended and Game.GameOverInfo then
        Game.GameOverInfo.nextGameIn = Game.EndedTimer
        Events.CallRemote("GameOver", player, Reliability.Reliable, Game.GameOverInfo)
    end
end)

Player.Subscribe("Spawn", function()
    dirty = true
end)

Player.Subscribe("Destroy", function(player)
    stats[player] = nil
    dirty = true
end)
