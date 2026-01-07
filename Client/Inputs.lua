Input.Register("Jump", "SpaceBar")
Input.Register("Nitro", "LeftShift")

Input.Bind("Jump", InputEvent.Pressed, function()
	Events.CallRemote("Jump")
end)

Input.Bind("Nitro", InputEvent.Pressed, function()
	Events.CallRemote("StartNitro")
end)
Input.Bind("Nitro", InputEvent.Released, function()
	Events.CallRemote("StopNitro")
end)