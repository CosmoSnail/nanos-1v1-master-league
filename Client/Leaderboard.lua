-- Leaderboard of both teams while Tab is held (the end of game screen shows it on its own)

RegisterKey("CarLeaderboard", "Tab", "Show the leaderboard")

BindKey("CarLeaderboard", InputEvent.Pressed, function()
    Events.Call("ToggleLeaderboard", true)
end)

BindKey("CarLeaderboard", InputEvent.Released, function()
    Events.Call("ToggleLeaderboard", false)
end)
