-- Halloween edition: team 1 (Team.TeamA on the server) are the Witches, team 2 (Team.TeamB) the Skeletons (the
-- ball is the pumpkin). Their colors light the cars, the goals and the fireworks; the HUD uses the same ones
-- (Client/UI/style.css)

Theme = {
    Teams = {
        [1] = {
            name = "Witches",
            color = Color(0.5, 0.1, 1.0),        -- lights, ribbon, fireworks
            paint = Color(0.28, 0.12, 0.42),     -- tint of the car body
        },
        [2] = {
            name = "Skeletons",
            color = Color(0.95, 0.88, 0.7),      -- old bone
            paint = Color(0.86, 0.8, 0.64),
            goal_light = Color(1, 1, 1),         -- their goal's frame lit white (Server/Goal.lua)
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

-- The team a player means in a chat command: "witches", "skeletons" (or the old "blue"/"red", "1"/"2")
function ParseTeam(text)
    text = (text or ""):lower()
    if text:find("^witch") or text == "blue" or text == "1" or text == "a" then return 1 end
    if text:find("^skel") or text == "red" or text == "2" or text == "b" then return 2 end
end
