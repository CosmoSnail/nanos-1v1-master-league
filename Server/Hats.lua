Hats = {
    {
        name = "polygon-hats::CulturalHat",
        rotation = Rotator(0, 0, 0),
        location = Vector(-20, 0, 156),
        scale = 2
    },
    {
        name = "polygon-hats::SM_PenguinBaseMesh",
        rotation = Rotator(0, -90, 0),
        location = Vector(9, 0, 70),
        scale = 3
    },
    {
        name = "polygon-hats::SM_PirateHat",
        rotation = Rotator(2, 0, 0),
        location = Vector(-10, 0, 152),
        scale = 3.2
    },
    {
        name = "polygon-hats::SM_PropellerHat",
        rotation = Rotator(0, -90, 0),
        location = Vector(-30, 0, 154),
        scale = 4
    },
    {
        name = "polygon-hats::SM_QueenCrown",
        rotation = Rotator(2, 0, 0),
        location = Vector(-7, 0, 154),
        scale = 4
    },
    {
        name = "polygon-hats::SM_TopHat",
        rotation = Rotator(2, 0, 0),
        location = Vector(-10, 0, 152),
        scale = 3
    },
    {
        name = "polygon-hats::SM_VikingHat",
        rotation = Rotator(0, 80, 0),
        location = Vector(-8, 0, 152),
        scale = 3.4
    },
    {
        name = "polygon-hats::SM_WorkerHat",
        rotation = Rotator(1, 0, 0),
        location = Vector(-8, 0, 152),
        scale = 3.4
    },
    {
        name = "polygon-hats::SM_queencrown_hat",
        rotation = Rotator(1, 0, 0),
        location = Vector(-6, 0, 152),
        scale = 3.6
    },
    {
        name = "polygon-hats::SM_top_hat2",
        rotation = Rotator(2, 0, 0),
        location = Vector(-10, 0, 152),
        scale = 3
    },
    {
        name = "polygon-hats::Sheriffs_Hat",
        rotation = Rotator(0, -90, 0),
        location = Vector(-10, 0, 156),
        scale = 3
    },
    {
        name = "polygon-hats::WitchHat",
        rotation = Rotator(0, -90, 0),
        location = Vector(-20, 0, 153),
        scale = 3
    },
}

function GetRandomHat()
    return Hats[math.random(#Hats)]
end