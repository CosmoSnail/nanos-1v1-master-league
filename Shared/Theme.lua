-- Halloween edition: team 1 (Team.TeamA on the server) are the Witches, team 2 (Team.TeamB) the Pumpkins.
-- Their colors light the cars, the goals, the boost flames and the fireworks; the HUD uses the same ones
-- (Client/UI/style.css)

Theme = {
    Teams = {
        [1] = {
            name = "Witches",
            color = Color(0.5, 0.1, 1.0),        -- lights, ribbon, fireworks
            paint = Color(0.28, 0.12, 0.42),     -- tint of the car body
        },
        [2] = {
            name = "Pumpkins",
            color = Color(1.0, 0.35, 0.0),
            paint = Color(1.0, 0.45, 0.1),
        },
    },
    Slime = Color(0.35, 1.0, 0.12),
    Bone = Color(0.96, 0.93, 0.85),
    -- seconds in a game (Server/Config.lua); the night deepens over it (Client/Atmosphere.lua, Server/Weather.lua)
    GameLength = 5 * 60,
}

function TeamName(team)
    local t = Theme.Teams[team]
    return t and t.name or "Nobody"
end

function TeamColor(team)
    local t = Theme.Teams[team]
    return t and t.color or Theme.Slime
end

-- The team a player means in a chat command: "witches", "pumpkins" (or the old "blue"/"red", "1"/"2")
function ParseTeam(text)
    text = (text or ""):lower()
    if text:find("^witch") or text == "blue" or text == "1" or text == "a" then return 1 end
    if text:find("^pump") or text == "red" or text == "2" or text == "b" then return 2 end
end
