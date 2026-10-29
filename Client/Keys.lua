-- Default keys for the player's keyboard layout (same idea as burn-the-witch's Client/Keys.lua).
-- nanos names a letter key by the character it types, not by where it sits: on an AZERTY keyboard the
-- QWERTY W, A and Q places type Z, Q and A. Bindings are registered with the keys at the same places as
-- on QWERTY, so ZQSD drives there; players can still change any of them (Settings -> Controls)
local IsAzerty = Input.GetKeyboardLayout() == KeyboardLayout.AZERTY

local AZERTY_KEYS = { W = "Z", A = "Q", Q = "A" }

-- binding -> the name it is registered with. nanos saves a binding's key the first time it is registered
-- and keeps it from then on, whatever the default: one moved for the layout is registered under a name of
-- its own ("CarForward_Z"), so a key saved on QWERTY doesn't stay, and each layout keeps its own choices
local names = {}

-- Input.Register with `key` (QWERTY) moved to the player's layout
function RegisterKey(binding, key, description)
    local default = IsAzerty and AZERTY_KEYS[key] or key
    local name = default == key and binding or binding .. "_" .. default
    names[binding] = name
    Input.Register(name, default, description)
end

-- Input.Bind for a binding registered with RegisterKey
function BindKey(binding, input_event, callback)
    Input.Bind(names[binding] or binding, input_event, callback)
end

-- Input.IsBindingDown for a binding registered with RegisterKey
function IsKeyDown(binding)
    return Input.IsBindingDown(names[binding] or binding)
end

local KEY_LABELS = {
    SpaceBar = "Space", LeftShift = "Shift", RightShift = "Shift", LeftControl = "Ctrl", RightControl = "Ctrl",
    LeftAlt = "Alt", RightAlt = "Alt", Escape = "Esc", Tab = "Tab", CapsLock = "Caps",
    LeftMouseButton = "LMB", RightMouseButton = "RMB", MiddleMouseButton = "MMB",
    ThumbMouseButton = "Mouse 4", ThumbMouseButton2 = "Mouse 5",
}

-- The key a binding registered with RegisterKey is bound to, as the HUD writes it ("-" when none)
function KeyLabel(binding)
    local key = (Input.GetMappedKeys(names[binding] or binding) or {})[1]
    if not key or key == "" then return "-" end
    return KEY_LABELS[key] or key
end
