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
TANK_COLORS = {
	{0.8, 0.8, 0.8, 1.0},	-- Level 1
	{0.0, 0.8, 0.0, 1.0},	-- Level 2
	{0.0, 0.0, 0.8, 1.0},	-- Level 3
	{0.8, 0.0, 0.0, 1.0},	-- Level 4
}

TANK_STEP = 4.0
SHELL_SPEED = 100.0
TURRET_COOLDOWN = 0.3

LAYER_BG = 10
LAYER_MAP = 20
LAYER_OBJECTS = 25
LAYER_TANKS = 30
LAYER_PLAYER = 40
LAYER_EFFECTS = 50
LAYER_PROJECTILES = 60
LAYER_PLAYER_PROJECTILES = 61
LAYER_UI = 70
LAYER_SCREEN = 80
LAYER_DEBUG = 100

TILE_NOTHING = 0
TILE_BRICK = 1
TILE_STONE = 2
TILE_GRASS = 3
TILE_ICE = 4
TILE_WATER = 5

BLACK = {0, 0, 0, 1}
WHITE = {1, 1, 1, 1}
RED = {1, 0, 0, 1}
GREEN = {0, 1, 0, 1}
BLUE = {0, 0, 1, 1}
CYAN = {0, 1, 1, 1}
MAGENTA = {1, 0, 1, 1}
YELLOW = {1, 1, 0, 1}

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

StopSound = function(name)
	Res.SoundEffects[name]:stop()
end

StopAllSounds = function()
	for i in pairs(Res.SoundEffects) do
		if Res.SoundEffects[i]:isPlaying() then
			Res.SoundEffects[i]:stop()
		end
	end
end

-- Start menu sequence
Restart_Game = function(ent)
	ECS:KillAllEntities()
	local start = ECS:SpawnEntity({"initstart"})
end

Construct_StartMenu = function(ent)
	local txt = {"1 PLAYER", "2 PLAYER", "CONSTRUCTION"}
	local places = {}
	for i=1,3 do
		local se = ECS:SpawnEntity({"pos", "bmptext"})
		local c = ECS:GetEntComps(se)
		c.pos.x = (1280 - 250) / 2
		c.pos.y = i * 18 * SCALE + (720 / 2)
		c.bmptext.text = txt[i]
		add(places, {x = c.pos.x - 48, y = c.pos.y - 14})
	end
	local menu = ECS:SpawnEntity({"menucursor", "uianimspr"})
	local mc = ECS:GetEntComps(menu)
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
	ECS:KillAllEntities()
	local def_text = function()
		local se = ECS:SpawnEntity({"pos", "bmptext", "delayedfunc"})
		local c = ECS:GetEntComps(se)
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
	local se = ECS:SpawnEntity({"initgame"})
end

Construct_GameOver = function(ent)
	love.graphics.setBackgroundColor(START_BG_COLOR)
	ECS:KillAllEntities()
	StopAllSounds()

	local gameover = ECS:SpawnEntity({"pos", "spr", "delayedfunc"})
	local gc = ECS:GetEntComps(gameover)

	gc.spr.spritesheet = "gameover"
	gc.spr.scalex = SCALE
	gc.spr.scaley = SCALE
	gc.spr.layer = LAYER_UI

	gc.pos.x = (SC_WIDTH / 2) - (Res.GetSpriteWidth("gameover") * SCALE / 2)
	gc.pos.y = (SC_HEIGHT / 2) - (Res.GetSpriteHeight("gameover") * SCALE / 2)

	gc.delayedfunc.delay = 5
	gc.delayedfunc.func = Restart_Game

	PlaySound("game_over")
end

-- Fires shell, returns shell entity
Fire_Shell = function(ent, is_player)
	local ec = ECS:GetEntComps(ent)
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

	local layer = LAYER_PROJECTILES
	if is_player then
		layer = LAYER_PLAYER_PROJECTILES
	end

	local be = ECS:SpawnEntity({"projectile", "spr", "pos", "dir", "outofbounds_kill", "collshape", "collid"})
	local c = ECS:GetEntComps(be)
	-- projectile
	c.projectile.speed = SHELL_SPEED * SCALE
	c.projectile.shooter_entity = ent
	-- sprite
	c.spr.spritesheet = "bullets"
	c.spr.spriteid = 1
	c.spr.scalex = SCALE
	c.spr.scaley = SCALE
	c.spr.layer = layer
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
	c.collid.layer = layer

	-- Specific to player
	if is_player == true then
		ECS:EntAddComp(be, "playershell")
		PlaySound("tank_fire")
	end

	return be
end

-- pos = {x=N, y=N}
Small_Explosion = function(pos)
	local se = ECS:SpawnEntity({"animspr", "pos", "animspr_onecycle"})
	local c = ECS:GetEntComps(se)

	local sw = Res.GetSpriteWidth("small_explosion") * SCALE
	local sh = Res.GetSpriteHeight("small_explosion") * SCALE

	c.pos.x = pos.x - fround(sw / 2) + (1 * SCALE)	-- 1 * SCALE is shell width/height
	c.pos.y = pos.y - fround(sh / 2) + (1 * SCALE)

	c.animspr.spritesheet = "small_explosion"
	c.animspr.scalex = SCALE
	c.animspr.scaley = SCALE

	c.animspr_onecycle.frametime = 0.05
end

-- pos = {x=N, y=N}
Big_Explosion = function(pos)
	local se = ECS:SpawnEntity({"animspr", "pos", "animspr_onecycle"})
	local c = ECS:GetEntComps(se)

	local sw = Res.GetSpriteWidth("explosion") * SCALE
	local sh = Res.GetSpriteHeight("explosion") * SCALE

	c.pos.x = pos.x - fround(sw / 2)
	c.pos.y = pos.y - fround(sh / 2)

	c.animspr.spritesheet = "explosion"
	c.animspr.scalex = SCALE
	c.animspr.scaley = SCALE

	c.animspr_onecycle.frametime = 0.2

	PlaySound("big_explosion")
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
	local c = ECS:GetEntComps(ent)
	if c.timedown.time > 0 then
		GameTimeWarp = c.timedown.time
	end
end

-- Returns spawndirector entity
Construct_SpawnDirector = function()
	local se = ECS:SpawnEntity({"spawndirector"})
	local c = ECS:GetEntComp(se, "spawndirector")

	c.active = true
	c.spawns = 20
	c.cooldown = 2.0

	local zones = {
		makeRect(SC_MAP_RECT[1], SC_MAP_RECT[2], 16 * SCALE, 16 * SCALE),
		makeRect(MAP_TO_COORD_X(12), MAP_TO_COORD_Y(1), 16 * SCALE, 16 * SCALE),
		makeRect(MAP_TO_COORD_X(23), MAP_TO_COORD_Y(1), 16 * SCALE, 16 * SCALE)
	}

	local sensors = {}
	for i=1,#zones do
		local s = ECS:SpawnEntity({"collsensor", "pos", "collshape", "collid", "child"})
		local cc = ECS:GetEntComps(s)

		cc.child.parent = se

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

	c.zones = zones
	c.sensors = sensors

	return se
end

Construct_PlayerSpawner = function()
	local se = ECS:SpawnEntity({"playerspawner"})
	local c = ECS:GetEntComp(se, "playerspawner")

	local zones = {
		makeRect(MAP_TO_COORD_X(10), MAP_TO_COORD_Y(13), 16 * SCALE, 16 * SCALE),
		makeRect(MAP_TO_COORD_X(14), MAP_TO_COORD_Y(13), 16 * SCALE, 16 * SCALE)
	}

	local sensors = {}
	for i=1,#zones do
		local s = ECS:SpawnEntity({"collsensor", "pos", "collshape", "collid", "child"})
		local cc = ECS:GetEntComps(s)

		cc.child.parent = se

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

	c.zones = zones
	c.sensors = sensors

	return se
end

-- entity: to sense, must have motionsensor4, pos, collshape, collid
Construct_TankMotionSensors = function(entity, step)
	assert(step ~= nil)
	assert(ECS:HasEntComp(entity, "pos"))
	assert(ECS:HasEntComp(entity, "collshape"))
	assert(ECS:HasEntComp(entity, "collid"))
	assert(ECS:HasEntComp(entity, "motionsensor4"))
	local comps = ECS:GetEntComps(entity)
	local sensors = {}
	for i=1,4 do
		local s = ECS:SpawnEntity({"collsensor", "pos", "poslink", "collshape", "collid", "child"})
		local c = ECS:GetEntComps(s)
		--c.dbgname.name = comps.dbgname.name.."_sensor_"..tostring(s)

		c.child.parent = entity

		c.poslink.parent = entity

		c.collshape.type = SHAPE_RECT
		c.collshape.x = comps.collshape.x
		c.collshape.y = comps.collshape.y
		c.collshape.w = comps.collshape.w
		c.collshape.h = comps.collshape.h

		c.collid.ent = s
		c.collid.layer = comps.collid.layer
		c.collid.sensor = true
		c.collid.owner = entity
		c.collid.sense_own_layer = true

		add(sensors, s)
	end
	local up_shape = ECS:GetEntComp(sensors[UP], "collshape")
	up_shape.y = decr(up_shape.y, step)
	local right_shape = ECS:GetEntComp(sensors[RIGHT], "collshape")
	right_shape.x = incr(right_shape.x, step)
	local down_shape = ECS:GetEntComp(sensors[DOWN], "collshape")
	down_shape.y = incr(down_shape.y, step)
	local left_shape = ECS:GetEntComp(sensors[LEFT], "collshape")
	left_shape.x = decr(left_shape.x, step)
	comps.motionsensor4.sensors = sensors
end

Construct_Tank = function(data)
	local zone = data[1]
	local tank_color = data[2]
	local tank_layer = data[3]
	local dir = data[4]

	local se = ECS:SpawnEntity({"dbgname", "pos", "animspr", "dir", "tank", "collshape", "collid", "motionsensor4", "tankturret"})
	local comps = ECS:GetEntComps(se)

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

	if tank_layer == LAYER_PLAYER then
		ECS:EntAddComp(se, "player")
	else
		ECS:EntAddComps(se, {"enemy", "enemycontrol"})
	end
	comps.pos.x = zone.x
	comps.pos.y = zone.y
	comps.dir.dir = dir

	return se
end

-- Enemy or player doesn't care
Spawn_ATank = function(zone, tank_color, tank_layer, dir)
	local seffect = ECS:SpawnEntity({"animspr", "animspr_pingpong", "pos", "killfunc", "collshape", "collid"})
	local c = ECS:GetEntComps(seffect)

	c.animspr.spritesheet = "spawn_effect"
	c.animspr.scalex = SCALE
	c.animspr.scaley = SCALE

	c.animspr_pingpong.cycles = 2
	c.animspr_pingpong.frametime = 0.07

	c.pos.x = zone.x
	c.pos.y = zone.y

	c.collshape.type = SHAPE_RECT
	c.collshape.x = 0
	c.collshape.y = 0
	c.collshape.w = zone.w
	c.collshape.h = zone.h

	c.collid.ent = seffect
	c.collid.dynamic = false
	c.collid.layer = LAYER_BG

	local kfunc = ECS:SpawnEntity({"killfunc"})
	local cc = ECS:GetEntComps(kfunc)

	cc.killfunc.entity = seffect
	cc.killfunc.funcbind = makeFunc(Construct_Tank, {zone, tank_color, tank_layer, dir})
end

Spawn_EnemyTank = function(zone)
	Spawn_ATank(zone, TANK_COLORS[1], LAYER_TANKS, DOWN)
end

Spawn_PlayerTank = function(zone)
	Spawn_ATank(zone, PLAYER_COLOR, LAYER_PLAYER, UP)
end

Trigger_GameOver = function()
		-- Remove player components to disable control
		local plrs = ECS:CollectEntitiesWith({"player"})
		for i=1,#plrs do
			ECS:EntRemComp(plrs[i], "player")
		end
		StopSound("tank_idle")
		StopSound("tank_moving")
		local gameover = ECS:SpawnEntity({"gameover"})
end

Construct_UIEnemyCount = function(sc_pos, count)
	local column = 0
	local row = 1
	for i=1,count do
		local x = sc_pos.x + column * 8 * SCALE
		local y = sc_pos.y + row * 8 * SCALE
		local e = ECS:SpawnEntity({"pos", "spr"})
		local c = ECS:GetEntComps(e)
		c.pos.x = x
		c.pos.y = y
		c.spr.spritesheet = "tiles"
		c.spr.spriteid = 8
		c.spr.scalex = SCALE
		c.spr.scaley = SCALE
		c.spr.layer = LAYER_UI

		column = column + 1
		if column > 1 then
			column = 0
			row = row + 1
		end
	end
end

Construct_UILivesCount = function(sc_pos, count)
	local iptext = ECS:SpawnEntity({"pos", "bmptext"})
	local ipcomps = ECS:GetEntComps(iptext)
	ipcomps.pos.x = sc_pos.x
	ipcomps.pos.y = sc_pos.y
	ipcomps.bmptext.text = "IP"
	ipcomps.bmptext.color = BLACK

	local icon = ECS:SpawnEntity({"pos", "spr"})
	local iccomps = ECS:GetEntComps(icon)
	iccomps.pos.x = sc_pos.x
	iccomps.pos.y = sc_pos.y + 8 * SCALE
	iccomps.spr.spritesheet = "tiles"
	iccomps.spr.spriteid = 9
	iccomps.spr.scalex = SCALE
	iccomps.spr.scaley = SCALE
	iccomps.spr.layer = LAYER_UI

	local lives = ECS:SpawnEntity({"pos", "bmptext"})
	local licomps = ECS:GetEntComps(lives)
	licomps.pos.x = sc_pos.x + 8 * SCALE
	licomps.pos.y = sc_pos.y + 8 * SCALE
	licomps.bmptext.text = tostring(count)
	licomps.bmptext.color = BLACK
end

Construct_UIStageNumber = function(sc_pos, num)
	local flag = ECS:SpawnEntity({"pos", "spr"})
	local fcomps = ECS:GetEntComps(flag)
	fcomps.pos.x = sc_pos.x
	fcomps.pos.y = sc_pos.y
	fcomps.spr.spritesheet = "icons"
	fcomps.spr.spriteid = 4
	fcomps.spr.scalex = SCALE
	fcomps.spr.scaley = SCALE
	fcomps.spr.layer = LAYER_UI

	local stage = ECS:SpawnEntity({"pos", "bmptext"})
	local sc = ECS:GetEntComps(stage)
	sc.pos.x = sc_pos.x + 8 * SCALE
	sc.pos.y = sc_pos.y + 8 * SCALE
	sc.bmptext.text = tostring(num)
	sc.bmptext.color = BLACK
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
require 'drawsystems.general'
require 'drawsystems.utility'

--------------------------------------------------------------------------------------------
----------------- Create entities
--------------------------------------------------------------------------------------------
ents = {
	e_init=ECS:SpawnEntity({"initstart"})
}
