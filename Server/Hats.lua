-- What the cars wear on their roof. Each game the Witches get the witch hat and the Pumpkins a glowing
-- jack-o'-lantern head (`team`); /hat (dev) goes through all of them.
-- burn-the-witch-vfx meshes are centred on their origin and look along +X, like the car
Hats = {
    {
        label = "Witch Hat",
        name = "polygon-hats::WitchHat",
        rotation = Rotator(0, -90, 0),
        location = Vector(-20, 0, 153),
        scale = 3,
        team = 1,
    },
    {
        label = "Jack-o'-Lantern",
        name = "burn-the-witch-vfx::SM_FX_Pumpkin",
        rotation = Rotator(0, 0, 0),
        location = Vector(-15, 0, 200),
        scale = 1.35,
        team = 2,
    },
    {
        label = "Skull",
        name = "burn-the-witch-vfx::SM_FX_Skull",
        rotation = Rotator(0, 0, 0),
        location = Vector(-15, 0, 210),
        scale = 1.5,
    },
    {
        label = "Vampire Top Hat",
        name = "polygon-hats::SM_TopHat",
        rotation = Rotator(2, 0, 0),
        location = Vector(-10, 0, 152),
        scale = 3,
    },
    {
        label = "Undertaker Hat",
        name = "polygon-hats::SM_top_hat2",
        rotation = Rotator(2, 0, 0),
        location = Vector(-10, 0, 152),
        scale = 3,
    },
    {
        label = "Ghost Pirate Hat",
        name = "polygon-hats::SM_PirateHat",
        rotation = Rotator(2, 0, 0),
        location = Vector(-10, 0, 152),
        scale = 3.2,
    },
}

-- The hat a team wears at the start of every game
function GetTeamHat(team)
    for _, hat in ipairs(Hats) do
        if hat.team == team then return hat end
    end
    return Hats[1]
end
