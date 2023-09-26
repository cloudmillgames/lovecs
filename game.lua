-- ** GAME **

--------------------------------------------------------------------------------------------
----------------- Libraries
--------------------------------------------------------------------------------------------
local easing = require 'easing'
local text = require 'text'

--------------------------------------------------------------------------------------------
----------------- Constants
--------------------------------------------------------------------------------------------
UP = 1
RIGHT = 2
DOWN = 3
LEFT = 4

STAGE = 1

SC_WIDTH = 1280.0
SC_HEIGHT = 720.0
ORG_WIDTH = 256.0
ORG_HEIGHT = 224.0
SCALE = 3.0
MAP_START_X = 16.0
MAP_START_Y = 16.0
MAP_TILES_COLUMNS = 23
MAP_TILES_ROWS = 13
MAP_TILE_WIDTH = 16
MAP_TILE_HEIGHT = 16
START_BG_COLOR = {0, 0, 0, 1}
ARENA_BG_COLOR = {.4, .4, .4, 1}
SC_TILE_WIDTH = MAP_TILE_WIDTH * SCALE
SC_TILE_HEIGHT = MAP_TILE_HEIGHT * SCALE
SC_MAP_RECT = {MAP_START_X * SCALE, MAP_START_Y * SCALE, MAP_TILES_COLUMNS * MAP_TILE_WIDTH * SCALE, MAP_TILES_ROWS * MAP_TILE_HEIGHT * SCALE}

PLAYER_COLOR = {0.89, 0.894, 0.578, 1}

TANK_STEP = 4.0
SHELL_SPEED = 1.0
TURRET_COOLDOWN = 0.3

LAYER_BG = 10
LAYER_MAP = 20
LAYER_TANKS = 30
LAYER_PLAYER = 40
LAYER_EFFECTS = 50
LAYER_PROJECTILES = 60
LAYER_UI = 70
LAYER_SCREEN = 80
LAYER_DEBUG = 100

TILE_NOTHING = 0
TILE_BRICK = 1
TILE_STONE = 2
TILE_GRASS = 3
TILE_ICE = 4
TILE_WATER = 5

--------------------------------------------------------------------------------------------
----------------- Functions
--------------------------------------------------------------------------------------------
function MAP_TO_COORD_X(column)
	if column > MAP_TILES_COLUMNS or column < 1 then
		error("Invalid Map column: "..column)
	end
	return column * MAP_TILE_WIDTH * SCALE
end

function MAP_TO_COORD_Y(row)
	if row > MAP_TILES_ROWS or row < 1 then
		error("Invalid Map row: "..row)
	end
	return row * MAP_TILE_HEIGHT * SCALE
end

LoadResources = function()
	Res.Init()
	Res.LoadImagesPack(RES_IMAGES)
	Res.LoadSpritesheetsPack(RES_SPRITESHEETS)
	Res.LoadSoundEffectsPack(RES_SOUNDEFFECTS)
	Res.LoadMusicPack(RES_MUSIC)
	Res.SoundEffects["tank_idle"]:setLooping(true)
	Res.SoundEffects["tank_moving"]:setLooping(true)
end

PlaySound = function(name)
	Res.SoundEffects[name]:play()
end

Construct_StartMenu = function(ent)
	local txt = {"1 PLAYER", "2 PLAYER", "CONSTRUCTION"}
	local places = {}
	for i=1,3 do
		local se = SpawnEntity({"pos", "bmptext"})
		local c = GetEntComps(se)
		c.pos.x = (1280 - 250) / 2
		c.pos.y = i * 18 * SCALE + (720 / 2)
		c.bmptext.text = txt[i]
		add(places, {x = c.pos.x - 48, y = c.pos.y - 14})
	end
	local menu = SpawnEntity({"menucursor", "uianimspr"})
	local mc = GetEntComps(menu)
	mc.menucursor.places = places
	-- 1 PLAYER, 2 PLAYER, CONSTRUCTION function calls
	mc.menucursor.funcs = {Construct_LevelScreen, Construct_LevelScreen, Construct_LevelScreen}
	mc.uianimspr.spritesheet = "icons"
	mc.uianimspr.scalex = SCALE
	mc.uianimspr.scaley = SCALE
	mc.uianimspr.frames = {1, 2}
	mc.uianimspr.curr_frame = 1
	mc.uianimspr.frametime = 0.1
end

Construct_LevelScreen = function(ent)
	love.graphics.setBackgroundColor(ARENA_BG_COLOR)
	KillAllEntities()
	local def_text = function()
		local se = SpawnEntity({"pos", "bmptext", "delayedfunc"})
		local c = GetEntComps(se)
		c.pos.x = (1280 / 2) - (8 * 5 * SCALE)
		c.pos.y = (720 / 2) - 4
		c.bmptext.text = "STAGE   "..tostring(STAGE)
		c.bmptext.color = {0, 0, 0, 1}
		c.delayedfunc.delay = 2
		c.delayedfunc.func = Construct_Gameplay
		Music.play("level_start")
	end
	def_text()
end

Construct_Gameplay = function()
	local se = SpawnEntity({"initgame"})
end

-- Fires shell, returns shell entity
Fire_Shell = function(ent, is_player)
	local ec = GetEntComps(ent)
	local rel_offset = {x=ec.tankturret.fire_point.x, y=ec.tankturret.fire_point.y}
	local bul_center = {x=2, y=2}
	if ec.dir.dir == RIGHT then
		rel_offset.x = ec.collshape.x + ec.collshape.w - ec.tankturret.fire_point.y - bul_center.y
		rel_offset.y = ec.tankturret.fire_point.x - bul_center.x
	elseif ec.dir.dir == DOWN then
		rel_offset.x = rel_offset.x - bul_center.x
		rel_offset.y = ec.collshape.y + ec.collshape.h - rel_offset.y - bul_center.y
	elseif ec.dir.dir == LEFT then
		rel_offset.x = ec.tankturret.fire_point.y - bul_center.y
		rel_offset.y = ec.tankturret.fire_point.x - bul_center.x
	elseif ec.dir.dir == UP then
		rel_offset.x = rel_offset.x - bul_center.x
		rel_offset.y = rel_offset.y - bul_center.y
	end

	local be = SpawnEntity({"projectile", "spr", "pos", "dir", "outofbounds_kill", "collshape", "collid"})
	local c = GetEntComps(be)
	-- projectile
	c.projectile.speed = SHELL_SPEED * SCALE
	c.projectile.shooter_entity = ent
	-- sprite
	c.spr.spritesheet = "bullets"
	c.spr.spriteid = 1
	c.spr.scalex = SCALE
	c.spr.scaley = SCALE
	c.spr.layer = LAYER_PROJECTILES
	c.spr.spriteid = ec.dir.dir
	-- position
	c.pos.x = ec.pos.x + rel_offset.x
	c.pos.y = ec.pos.y + rel_offset.y
	-- direction
	c.dir.dir = ec.dir.dir
	-- collision
	c.collshape.type = SHAPE_RECT
	c.collshape.w = 3 * SCALE
	c.collshape.h = 3 * SCALE
	c.collid.ent = be
	c.collid.layer = LAYER_PROJECTILES

	-- Specific to player
	if is_player == true then
		EntAddComp(be, "playershell")
		PlaySound("tank_fire")
	end

	return be
end

-- pos = {x=N, y=N}
Small_Explosion = function(pos)
	local se = SpawnEntity({"animspr", "pos", "animspr_onecycle"})
	local c = GetEntComps(se)

	local sw = Res.GetSpriteWidth("small_explosion") * SCALE
	local sh = Res.GetSpriteHeight("small_explosion") * SCALE

	c.pos.x = pos.x - fround(sw / 2) + (1 * SCALE)	-- 1 * SCALE is shell width/height
	c.pos.y = pos.y - fround(sh / 2) + (1 * SCALE)

	c.animspr.spritesheet = "small_explosion"
	c.animspr.scalex = SCALE
	c.animspr.scaley = SCALE

	c.animspr_onecycle.frametime = 0.05
end

GetMovementFromDir = function(dir)
	if dir == UP then
		return {x=0, y=-1}
	elseif dir == RIGHT then
		return {x=1, y=0}
	elseif dir == DOWN then
		return {x=0, y=1}
	else
		return {x=-1, y=0}
	end
end

Time_Skip = function(ent)
	local c = GetEntComps(ent)
	if c.timedown.time > 0 then
		GameTimeWarp = c.timedown.time
	end
end

-- Returns spawndirector entity
Construct_SpawnDirector = function()
	local se = SpawnEntity({"spawndirector"})
	local c = GetEntComps(se)

	c.active = true
	c.total_spawns = 20
	c.cooldown = 2.0

	local zones = {
		makeRect(SC_MAP_RECT[1], SC_MAP_RECT[2], 16 * SCALE, 16 * SCALE),
		makeRect(MAP_TO_COORD_X(12), MAP_TO_COORD_Y(1), 16 * SCALE, 16 * SCALE),
		makeRect(MAP_TO_COORD_X(23), MAP_TO_COORD_Y(1), 16 * SCALE, 16 * SCALE)
	}

	local sensors = {}
	for i=1,#zones do
		local s = SpawnEntity({"collsensor", "pos", "collshape", "collid"})
		local cc = GetEntComps(s)
		cc.collshape.type = SHAPE_RECT
		cc.collshape.x = zones[i].x
		cc.collshape.y = zones[i].y
		cc.collshape.w = zones[i].w
		cc.collshape.h = zones[i].h

		cc.collid.ent = s
		cc.collid.layer = LAYER_MAP
		cc.collid.sensor = true

		add(sensors, s)
	end

	return se
end

-- entity: to sense, must have motionsensor4, pos, collshape, collid
Construct_TankMotionSensors = function(entity, step)
	assert(step ~= nil)
	assert(HasEntComp(entity, "pos"))
	assert(HasEntComp(entity, "collshape"))
	assert(HasEntComp(entity, "collid"))
	assert(HasEntComp(entity, "motionsensor4"))
	local comps = GetEntComps(entity)
	local sensors = {}
	for i=1,4 do
		local s = SpawnEntity({"collsensor", "pos", "poslink", "collshape", "collid"})
		local c = GetEntComps(s)
		--c.dbgname.name = comps.dbgname.name.."_sensor_"..tostring(s)

		c.poslink.parent = entity

		c.collshape.type = SHAPE_RECT
		c.collshape.x = comps.collshape.x
		c.collshape.y = comps.collshape.y
		c.collshape.w = comps.collshape.w
		c.collshape.h = comps.collshape.h

		c.collid.ent = s
		c.collid.layer = comps.collid.layer

		add(sensors, s)
	end
	local up_shape = GetEntComp(sensors[UP], "collshape")
	up_shape.y = decr(up_shape.y, step)
	local right_shape = GetEntComp(sensors[RIGHT], "collshape")
	right_shape.x = incr(right_shape.x, step)
	local down_shape = GetEntComp(sensors[DOWN], "collshape")
	down_shape.y = incr(down_shape.y, step)
	local left_shape = GetEntComp(sensors[LEFT], "collshape")
	left_shape.x = decr(left_shape.x, step)
	comps.motionsensor4.sensors = sensors
end

Construct_Tank = function(tank_color, tank_layer)
	local se = SpawnEntity({"dbgname", "pos", "animspr", "dir", "tank", "collshape", "collid", "motionsensor4", "tankturret"})
	local comps = GetEntComps(se)

	comps.dbgname.name = "Tank_"..tostring(se)

	comps.animspr.spritesheet="tanks"
	comps.animspr.scalex = SCALE
	comps.animspr.scaley = SCALE
	comps.animspr.color = tank_color

	comps.collshape.type = SHAPE_RECT
	comps.collshape.w = 16 * SCALE
	comps.collshape.h = 16 * SCALE

	comps.collid.ent = se
	comps.collid.layer = tank_layer

	comps.tankturret.fire_point = {x = 7 * SCALE, y = 0}
	comps.tankturret.cooldown = TURRET_COOLDOWN

	Construct_TankMotionSensors(se, TANK_STEP * SCALE)

	return se
end

Construct_EnemyTank = function()
	-- TODO create an enemy tank
end

Spawn_EnemyTank = function()
	-- TODO spawn enemy tank
end

--------------------------------------------------------------------------------------------
----------------- Define Components
--------------------------------------------------------------------------------------------
require 'components'

--------------------------------------------------------------------------------------------
----------------- Define update systems
--------------------------------------------------------------------------------------------

require 'updatesystems.utility'
require 'updatesystems.general'
require 'updatesystems.effects'
require 'updatesystems.intro'
require 'updatesystems.gameplay'

--------------------------------------------------------------------------------------------
----------------- Define draw systems
--------------------------------------------------------------------------------------------
require 'drawsystems'

--------------------------------------------------------------------------------------------
----------------- Create entities
--------------------------------------------------------------------------------------------
ents = {
	e_init=SpawnEntity({"initstart"})
	--e_init=SpawnEntity({"initgame"}),
}
