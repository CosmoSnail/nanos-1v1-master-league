# Intergalactic Champions Monster League (Halloween edition)

Rocket League in nanos world, dressed up for Halloween (branch `halloween-2026`; `main` keeps the regular
season). Same game and controls: cars driven by `Client/Car.lua`, a ball, two goals, five-minute games.

## What Halloween changes

- **Teams**: the **Witches** (team 1, purple) against the **Pumpkins** (team 2, orange), in
  `Shared/Theme.lua`. Their colors light the cars, the goals, the boost flames, the ball's trail and the
  fireworks; the HUD uses the same ones (`Client/UI/style.css`).
- **The ball** is a giant jack-o'-lantern with a carved face glowing from inside and a candle flickering in
  it, and it bonks when hit (`Client/PumpkinBall.lua`). Only its look changes: same size and physics.
- **Cars**: body tinted in the team's color, the Witches wear witch hats and drive with a witch's staff for an
  antenna, the Pumpkins wear jack-o'-lantern heads (`Server/Hats.lua`, `DecorateVehicle` in
  `Server/Vehicle.lua`). Boost flames burn purple with a slime green core for the Witches, orange for the
  Pumpkins (`Client/BoostFX.lua`).
- **The night**: a night sky instead of space, a huge harvest moon with a witch flying across it, purple clouds
  and mist (`Client/Atmosphere.lua`). Lightning strikes round the arena every half minute or so, the same bolt
  for everyone (`Server/Weather.lua`), with the thunder arriving later the farther it fell.
- **The arena** (`Client/Arena.lua`, all spawned on the clients, no collision): dark ground round the glass
  dome, a graveyard along both sides (tombstones, a crypt, dead trees, scarecrows, jack-o'-lanterns lined up at
  the foot of the walls), the witches' coven behind their goal (hut, bubbling cauldron, standing stones round a
  glowing pentagram), the pumpkin patch behind the Pumpkins' goal with the **Pumpkin King** (a jack-o'-lantern
  22 m wide staring at the pitch), dead trees on the horizon, mist and will-o'-wisps. Inside: magic circles on
  the centre spot and in each goal, fallen leaves on the pitch, and the arena's own rims and glass lit in
  Halloween colors (the arena is a level mesh: `load_level_entities = true`).
- **What moves** (`Client/Spooks.lua`): bats circling over the dome, the witch crossing the sky on her broom
  (cackling), ghosts drifting under the ceiling. A goal bursts the pumpkin into a shower of little pumpkins and
  ghosts spiral up out of the goal, wailing.
- **The Witching Hour**: the last minute of a game. Blood moon, red grading, the midnight bell, much faster
  music, lightning more often, the HUD's timer bleeding.
- **HUD** (`Client/UI`): "GHOUL!" on a goal, "OWN GHOUL", "WITCHES WIN!" / "PUMPKINS WIN!" / "DEAD EVEN",
  the MVP is the *Most Valuable Phantom*, souls and ghouls in the leaderboard, "PUMPKIN CAM" for ball cam,
  cobwebs and bats. Open `Client/UI/index.html` in a browser and call `emit('GoalScored', {...})`,
  `emit('WitchingHour', true, true)`... from the console to work on it without the game.
- **Music and sounds** (`Client/Sounds.lua`): "In the Hall of the Mountain King" as a spooky march (organ,
  bone xylophone, ghostly choir, theremin), much faster in the Witching Hour; goal stingers (Bach's Toccata in
  D minor among them) and an evil laugh; a clock bell counting down the kickoff and a wolf answering now and
  then; the Toccata on the organ when time runs out; wind, owls and distant wolves outside.

## Tuning

- How bright the pitch is at night, the moon, clouds and fog: the `NIGHT` table at the top of
  `Client/Atmosphere.lua` (the Witching Hour's look in `WITCHING`).
- The colors the arena's own materials glow in: `ARENA_GLOW` in `Client/Arena.lua` (slots of the arena mesh:
  0 glass dome, 1 ramp rims, 5 goal frames, 9 ring).
- Lightning frequency, car paint on or off: `Server/Config.lua`. Team names and colors: `Shared/Theme.lua`.

## Dev commands

With the `dev_commands` setting (`--custom_settings "dev_commands = true"`), in the chat: `/help`,
`/goal [witches|pumpkins]`, `/hat [number|name]`, `/swap`, `/fireworks [end]`, `/end`, `/reload`, and for
Halloween `/witching` (skip to the last minute), `/lightning` (a strike now) and `/fog <0-100>` (try a density of
mist live, until a reload).

## Assets and credits

- Asset packs: `polygon-hats`, `ts-fireworks`, and from Burn the Witch! `burn-the-witch-vfx` (the pumpkin,
  skull, staff, magic circles, mist, wisps, ghost material) and `burn-the-witch-assets` (tombstones, crypt,
  dead trees, scarecrows, jack-o'-lanterns, cauldron, witch hut...). All on the Vault.
- Music and sounds in `Client/Sounds` are synthesized by `tools/make_sounds.py` (numpy, scipy, ffmpeg), no
  samples. The music arranges public domain works: Grieg's "In the Hall of the Mountain King" (1875) and the
  opening of Bach's Toccata and Fugue in D minor. `bell.ogg`, `ghost_boo.ogg` and `ghost_wail.ogg` come from
  burn-the-witch (the bell from a CC0 recording, BigSoundBank #3445).
- Images in `Client/Images` (the moons, bats, witch, leaves, ground) are drawn by `tools/make_textures.py`.
- Fonts: Creepster (Font Diner) and Grenze (Omnibus-Type), SIL Open Font License (`Client/UI/fonts`).
