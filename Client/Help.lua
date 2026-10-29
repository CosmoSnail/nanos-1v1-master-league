-- Controls panel: a small "H Controls" hint in the HUD's bottom left corner, H opens the list of controls
-- with the keys each player has bound (they follow the keyboard layout and the settings)

RegisterKey("CarHelp", "H", "Show controls")

-- { action, bindings shown together }
local CONTROLS = {
    { "Throttle / reverse", { "CarForward", "CarBackward" } },
    { "Steer", { "CarLeft", "CarRight" } },
    { "Jump, double jump, flip", { "CarJump", "CarJump2" } },
    { "Boost", { "CarBoost", "CarBoost2" } },
    { "Powerslide / air roll", { "CarSlide" } },
    { "Air roll left / right", { "CarRollLeft", "CarRollRight" } },
    { "Pumpkin cam", { "CarBallCam" } },
    { "Leaderboard (hold)", { "CarLeaderboard" } },
    { "Controls", { "CarHelp" } },
}

function SendControls()
    local rows = {}
    for _, control in ipairs(CONTROLS) do
        local keys = {}
        for _, binding in ipairs(control[2]) do
            table.insert(keys, KeyLabel(binding))
        end
        table.insert(rows, { action = control[1], keys = keys })
    end
    Events.Call("UpdateControls", rows, KeyLabel("CarHelp"))
end

local open = false

BindKey("CarHelp", InputEvent.Pressed, function()
    open = not open
    Events.Call("ToggleHelp", open)
end)

-- The player changed a key in the settings
Input.Subscribe("KeyBindingChange", function()
    SendControls()
end)
