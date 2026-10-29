-- Default pack materials for the ball (Server/Ball.lua) and the pitch's floor (Client/Floor.lua); /ball
-- and /floor in the chat try the others (Server/Chat.lua)

BallMaterials = {
    "MI_PG_BouncyBall",
    "MI_PG_MissingProp",
    "MI_PG_Ball_Soccer",
    "MI_PG_Ball_Basketball",
    "MI_PG_Ball_Volleyball",
    "MI_PG_Ball_Beach",
    "MI_PG_Ball_Tennis",
}
DefaultBallMaterial = 3     -- soccer

-- All on M_NanosSurface_Triplanar: projected in world space, so they tile the arena's floor whatever its UVs.
-- "TextureSize" is how big their texture is (cm, 150 by default: small next to cars over twice life size),
-- "TextureAspect" how much wider than long (1 by default)
FloorMaterials = {
    "MI_Surface_MetalDark",
    "MI_Surface_WoodPlanks",
    "MI_Surface_WoodFloor",
    "MI_Surface_WoodDark",
    "MI_Surface_WoodSiding",
    "MI_Surface_Brick",
    "MI_Surface_Concrete",
    "MI_Surface_ConcreteTiles",
    "MI_Surface_Stone",
    "MI_Surface_Marble",
    "MI_Surface_Gravel",
    "MI_Surface_Dirt",
    "MI_Surface_RoofTiles",
    "MI_Surface_MetalPainted",
    "MI_Surface_MetalCorrugated",
    "MI_Surface_Wallpaper",
    "MI_Surface_Plastic",
    "MI_Surface_Rubber",
    "MI_Surface_Chrome",
    "MI_Surface_Gold",
    "MI_Surface_Copper",
    "MI_Surface_Neon",
}
DefaultFloorMaterial = 8    -- concrete tiles: matte, and the tiles show how fast you go
DefaultFloorSize = 500
DefaultFloorAspect = 1
