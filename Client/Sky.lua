function InitSky()
    Sky.Spawn()
    Sky.SetSkyMode(SkyMode.Space)
    Sky.SetMoonScale(50)
    Sky.SetMoonGlowIntensity(25)
    Sky.SetMoonLightIntensity(250)
    Sky.Reconstruct()
end