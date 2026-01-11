function SpawnFireworksGoal(team)
    SpawnRandomFireworks(20000, 20000, 7000, 12000, 50, team, 2000)
end

function SpawnFireworksEndGame()
    local team
    if Game.ScoreA > Game.ScoreB then
        team = Team.TeamA
    elseif Game.ScoreB > Game.ScoreA then
        team = Team.TeamB
    end
    SpawnRandomFireworks(20000, 20000, 7000, 12000, 80, team, 12000)
end

function SpawnRandomFireworks(range_x, range_y, range_z_0, range_z_1, count, team, max_delay)
    for i = 1, count do
        local delay = math.random(0, max_delay)
        Timer.SetTimeout(function()
            local location = Vector(
            math.random(-range_x, range_x),
            math.random(-range_y, range_y),
            math.random(range_z_0, range_z_1)
        )

        local firework = Particle(
            location,
            Rotator(),
            "ts-fireworks::PS_TS_Fireworks_Burst_Palm",
            false,
            true
        )

        local color
        if team == Team.TeamA then
            color = Config.ColorA
        elseif team == Team.TeamB then
            color = Config.ColorB
        else
            color = Ternary(math.random() < 0.5 , Config.ColorA, Config.ColorB)
        end

        firework:SetParameterColor("BlastColor", color)
        firework:SetParameterColor("BurstColor", color)
        firework:SetParameterColor("SparkleColor", color)
        firework:SetParameterColor("FlareColor", color)
        firework:SetParameterColor("TailColor", color)

        firework:SetParameterBool("BlastSmoke", false)
        firework:SetParameterBool("TrailSmoke", false)

        firework:SetParameterFloat("BurstMulti", 1.0)
        firework:SetParameterFloat("SparkleMulti", 1.0)

         --  Color: 'BurstColor', 'SparkleColor', 'FlareColor', 'TailColor'
        --  bool: 'BlastSmoke', 'TailSmoke'
        --  float: 'BurstMulti', 'SparkleMulti'
        end, delay)
    end
end