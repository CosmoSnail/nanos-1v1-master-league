Input.Register("Jump", "SpaceBar")
Input.Register("Nitro", "LeftShift")
Input.Register("Nitro2", "LeftMouseButton")
Input.Register("Test", "Q")

Input.Bind("Jump", InputEvent.Pressed, function()
	Events.CallRemote("Jump", Reliability.Reliable)
end)

Input.Bind("Nitro", InputEvent.Pressed, function()
	Events.CallRemote("StartNitro", Reliability.Reliable)
end)
Input.Bind("Nitro2", InputEvent.Pressed, function()
	Events.CallRemote("StartNitro", Reliability.Reliable)
end)

Input.Bind("Nitro", InputEvent.Released, function()
	Events.CallRemote("StopNitro", Reliability.Reliable)
end)
Input.Bind("Nitro2", InputEvent.Released, function()
	Events.CallRemote("StopNitro", Reliability.Reliable)
end)

Input.Bind("Nitro", InputEvent.Released, function()
	Events.CallRemote("StopNitro", Reliability.Reliable)
end)


