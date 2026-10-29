function InitSky()
    -- Always a fresh sky actor: reusing the one left by a package reload (find_existing) showed
    -- the default cloudy sky instead of the space one
    Sky.Spawn(false, false)
    Sky.SetSkyMode(SkyMode.Space)
    Sky.SetMoonScale(50)
    Sky.SetMoonGlowIntensity(25)
    Sky.SetMoonLightIntensity(250)
    Sky.Reconstruct()
end