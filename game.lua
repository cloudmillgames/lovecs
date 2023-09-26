-- ** GAME **
----------------- Libraries
local easing = require 'easing'
local text = require 'text'

----------------- Constants
UP = 1
RIGHT = 2
DOWN = 3
LEFT = 4

ORG_WIDTH = 256.0
ORG_HEIGHT = 224.0
SCALE = 3.0
MAP_START_X = 16.0
MAP_START_Y = 16.0
MAP_TILES_COLUMNS = 23
MAP_TILES_ROWS = 13
MAP_TILE_WIDTH = 16
MAP_TILE_HEIGHT = 16
ARENA_BG_COLOR = {.4, .4, .4, 1}
SC_TILE_WIDTH = MAP_TILE_WIDTH * SCALE
SC_TILE_HEIGHT = MAP_TILE_HEIGHT * SCALE
SC_MAP_RECT = {MAP_START_X * SCALE, MAP_START_Y * SCALE, MAP_TILES_COLUMNS * MAP_TILE_WIDTH * SCALE, MAP_TILES_ROWS * MAP_TILE_HEIGHT * SCALE}
PLAYER_COLOR = {0.89, 0.894, 0.578, 1}
TANK_STEP = 4.0

LAYER_BG = 1
LAYER_MAP = 2
LAYER_TANKS = 3
LAYER_PLAYER = 4
LAYER_EFFECTS = 5
LAYER_UI = 6
LAYER_SCREEN = 7
LAYER_DEBUG = 100

----------------- Functions
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
	Res.SoundEffects["tank_idle"]:setLooping(true)
	Res.SoundEffects["tank_moving"]:setLooping(true)
end

Construct_StartMenu = function()
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
	mc.menucursor.funcs = {nil, nil, nil}
	mc.uianimspr.spritesheet = "icons"
	mc.uianimspr.scalex = SCALE
	mc.uianimspr.scaley = SCALE
	mc.uianimspr.frames = {1, 2}
	mc.uianimspr.curr_frame = 1
	mc.uianimspr.frametime = 0.1
end

----------------- Define Components
require 'components'

----------------- Define update systems
USInitStart = function(ent)
	KillAllEntities()
	local def_title = function()
		local se = SpawnEntity({"pos", "animspr", "move4"})
		local c = GetEntComps(se)
		c.pos.x = (1280 - 188 * SCALE) / 2
		c.pos.y = SC_MAP_RECT[2] + SC_MAP_RECT[4] + 10 * SCALE
		c.animspr.spritesheet = "title"
		c.animspr.scalex = SCALE
		c.animspr.scaley = SCALE
		c.move4.destx = c.pos.x
		c.move4.desty = 140
		c.move4.duration = 3
	end
	local menumaker = SpawnEntity({"delayedfunc"})
	local mmc = GetEntComp(menumaker, "delayedfunc")
	mmc.delay = 3
	mmc.func = Construct_StartMenu
	LoadResources()
	def_title()
end
DefineUpdateSystem({"initstart"}, USInitStart)

USInitGame = function(ent)
	love.graphics.setBackgroundColor(ARENA_BG_COLOR)

	local def_fps = function()
		local te = SpawnEntity({"pos", "text", "fpscounter"})
		local pc = GetEntComp(te, "pos")
		pc.x = 1230
		pc.y = 2
		local tc = GetEntComp(te, "text")
		tc.text = "<FPS>"
	end
	local def_goal = function()
		local se = SpawnEntity({"pos", "animspr"})
		local pc = GetEntComp(se, "pos")
		local sc = GetEntComp(se, "animspr")
		pc.x = MAP_TO_COORD_X(12)
		pc.y = MAP_TO_COORD_Y(13)
		sc.spritesheet = "icons"
		sc.curr_frame = 3
		sc.scalex = SCALE
		sc.scaley = SCALE
	end
	-- entity: to sense, must have motionsensor4, pos, collshape, collid
	-- step: how far is the rect collider shifted in the 4 directions?
	local def_vehicle_motion_sensor = function(entity, step)
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
	local def_player = function()
		local se = SpawnEntity({"dbgname", "pos", "animspr", "player", "dir", "tank", "collshape", "collid", "motionsensor4"})
		local comps = GetEntComps(se)

		comps.dbgname.name = "Player_"..tostring(se)

		comps.pos.x = MAP_TO_COORD_X(10)
		comps.pos.y = MAP_TO_COORD_Y(13)

		comps.animspr.spritesheet="tanks"
		comps.animspr.scalex = SCALE
		comps.animspr.scaley = SCALE
		comps.animspr.color = PLAYER_COLOR

		comps.collshape.type = SHAPE_RECT
		comps.collshape.w = 16 * SCALE
		comps.collshape.h = 16 * SCALE

		comps.collid.ent = se
		comps.collid.layer = LAYER_PLAYER

		def_vehicle_motion_sensor(se, TANK_STEP * SCALE)
	end
	local def_bg = function()
		-- Arena background
		local se = SpawnEntity({"arena_bg"})
		-- Arena boundaries
		local bounds = {}
		for i=1,4 do
			local be = SpawnEntity({"dbgname", "pos", "collshape", "collid"})
			local comps = GetEntComps(be)
			comps.dbgname.name = "Bound_"
			comps.collshape.type = SHAPE_RECT
			comps.collid.ent = be
			comps.collid.dynamic = false
			comps.collid.layer = LAYER_BG
			add(bounds, be)
		end
		local bound_rect = {
			x=SC_MAP_RECT[1] - SC_TILE_WIDTH,
			y=SC_MAP_RECT[2] - SC_TILE_HEIGHT,
			w=SC_MAP_RECT[3] + SC_TILE_WIDTH * 2,
			h=SC_MAP_RECT[4] + SC_TILE_HEIGHT * 2}
		local up_shape = GetEntComp(bounds[UP], "collshape")
		up_shape.x = bound_rect.x
		up_shape.y = bound_rect.y
		up_shape.w = bound_rect.w
		up_shape.h = SC_TILE_HEIGHT

		local right_shape = GetEntComp(bounds[RIGHT], "collshape")
		right_shape.x = bound_rect.x + bound_rect.w - SC_TILE_WIDTH
		right_shape.y = bound_rect.y + SC_TILE_HEIGHT
		right_shape.w = SC_TILE_WIDTH
		right_shape.h = bound_rect.h - SC_TILE_HEIGHT * 2

		local down_shape = GetEntComp(bounds[DOWN], "collshape")
		down_shape.x = bound_rect.x
		down_shape.y = bound_rect.y + bound_rect.h - SC_TILE_HEIGHT
		down_shape.w = bound_rect.w
		down_shape.h = SC_TILE_HEIGHT

		local left_shape = GetEntComp(bounds[LEFT], "collshape")
		left_shape.x = bound_rect.x
		left_shape.y = bound_rect.y + SC_TILE_HEIGHT
		left_shape.w = SC_TILE_WIDTH
		left_shape.h = bound_rect.h - SC_TILE_HEIGHT * 2
	end
	local def_map = function(mapnum)
		-- Load map tiles
		local m = RES_MAPS[mapnum]
		local tl = ""
		for j=1,MAP_TILES_ROWS * 2 do
			for i=1,MAP_TILES_COLUMNS * 2 do
				local idx = ((j - 1) * MAP_TILES_COLUMNS * 2) + i
				if m[idx] ~= 0 then
					local se = SpawnEntity({"dbgname", "maptile", "pos", "collshape", "collid"})
					local comps = GetEntComps(se)
					comps.dbgname.name = "MTile"..tostring(idx).."_"..tostring(se)
					comps.maptile.type = m[idx]
					comps.pos.x = SC_MAP_RECT[1] + ((i - 1) * SC_TILE_WIDTH / 2)
					comps.pos.y = SC_MAP_RECT[2] + ((j - 1) * SC_TILE_HEIGHT / 2)
					comps.collshape.type = SHAPE_RECT
					comps.collshape.w = 8 * SCALE
					comps.collshape.h = 8 * SCALE
					comps.collid.ent = se
					comps.collid.layer = LAYER_MAP
				end
				if m[idx] > 0 then
					tl = tl..tostring(m[idx]).." "
				else
					tl = tl..". "
				end
			end
			tl = tl.."\n"
		end
		print(tl)
	end
	LoadResources()
	def_fps()
	def_goal()
	def_bg()
	def_player()
	def_map(1)
	-- init only runs once
	KillEntity(ent)
end
DefineUpdateSystem({"initgame"}, USInitGame)

USPlayerUpdate = function(ent)
	local comps = GetEntComps(ent)
	if comps.tank.moving == 0 then
		if btn.up > 0 then comps.dir.dir = UP end
		if btn.down > 0 then comps.dir.dir = DOWN end
		if btn.left > 0 then comps.dir.dir = LEFT end
		if btn.right > 0 then comps.dir.dir = RIGHT end
	end

	-- Tank engine
	if comps.tank.moving == 0 then
		if Res.SoundEffects["tank_moving"]:isPlaying() then
			Res.SoundEffects["tank_moving"]:pause()
		end
		Res.SoundEffects["tank_idle"]:play()
	else
		if Res.SoundEffects["tank_idle"]:isPlaying() then
			Res.SoundEffects["tank_idle"]:pause()
		end
		Res.SoundEffects["tank_moving"]:play()
	end
end
DefineUpdateSystem({"player", "dir", "tank"}, USPlayerUpdate)

USTankThrottle = function(ent)
	local comps = GetEntComps(ent)
	if comps.tank.moving == 0 then
		-- Check for input throttle
		comps.tank.throttle = (btn.up > 0 and comps.dir.dir == UP) or (btn.right > 0 and comps.dir.dir == RIGHT) or (btn.down > 0 and comps.dir.dir == DOWN) or (btn.left > 0 and comps.dir.dir == LEFT)

		if comps.tank.throttle then
			-- Check motion sensor for clear movement
			local sensor = comps.motionsensor4.sensors[comps.dir.dir]
			local sensor_comps = GetEntComps(sensor)
			if #sensor_comps.collid.events == 0 then
				comps.tank.moving = TANK_STEP
			end
		end
	end
end
DefineUpdateSystem({"player", "dir", "tank", "motionsensor4"}, USTankThrottle)

USTankUpdate = function(ent)
	local comps = GetEntComps(ent)
	-- Update frame to match direction and chain tick
	local tt = comps.tank.type
	local td = comps.dir.dir
	comps.animspr.curr_frame = (tt * 8) + 1 + (td - 1) * 2 + comps.tank.chain_tick
	if comps.tank.moving > 0 then
		local movedelta = comps.tank.speed * DeltaTime
		if movedelta > comps.tank.moving then
			movedelta = comps.tank.moving
			comps.tank.moving = 0
		else
			comps.tank.moving = comps.tank.moving - movedelta
		end
		-- Update chain tick
		comps.tank.chain_timer = comps.tank.chain_timer + DeltaTime
		if comps.tank.chain_timer >= comps.tank.chain_period then
			comps.tank.chain_timer = comps.tank.chain_timer - comps.tank.chain_period
			comps.tank.chain_tick = 1 - comps.tank.chain_tick
		end
		-- Move
		if comps.dir.dir == UP then
			comps.pos.y = comps.pos.y - movedelta * SCALE
		elseif comps.dir.dir == RIGHT then
			comps.pos.x = comps.pos.x + movedelta * SCALE
		elseif comps.dir.dir == LEFT then
			comps.pos.x = comps.pos.x - movedelta * SCALE
		elseif comps.dir.dir == DOWN then
			comps.pos.y = comps.pos.y + movedelta * SCALE
		end
		-- Round tank position to eliminate fractional error
		if comps.tank.moving == 0 then
			comps.pos.x = fround(comps.pos.x)
			comps.pos.y = fround(comps.pos.y)
		end
	end
end
DefineUpdateSystem({"tank", "animspr", "dir", "pos"}, USTankUpdate)

USFPSCounter = function(ent)
	local comps = GetEntComps(ent)
	comps.fpscounter.frame_count = comps.fpscounter.frame_count + 1
	comps.fpscounter.frame_timer = comps.fpscounter.frame_timer + DeltaTime
	if comps.fpscounter.frame_timer >= 1.0 then
		comps.text.text = tostring(comps.fpscounter.frame_count)
		comps.fpscounter.frame_count = 0
		comps.fpscounter.frame_timer = comps.fpscounter.frame_timer - 1.0
	end
end
DefineUpdateSystem({"fpscounter", "text"}, USFPSCounter)

USCollisionDebug = function(ent)
	if Collision.DEBUG then
		local c = GetEntComps(ent)
		for i=1,#c.collid.events do
			local other = c.collid.events[i][1] == ent and 2 or 1
			other = c.collid.events[i][other]
			local cc = GetEntComps(other)
			if not IsDeadEntity(other) and HasEntComp(ent, "dbgname") and HasEntComp(other, "dbgname") then
				print("COLLISION between "..c.dbgname.name.." and "..cc.dbgname.name)
			end
		end
	end
end
DefineUpdateSystem({"dbgname", "collshape", "collid", "pos"}, USCollisionDebug)

USPosLink = function(ent)
	local comps = GetEntComps(ent)
	local parent_pos = GetEntComp(comps.poslink.parent, "pos")
	comps.pos.x = parent_pos.x + comps.poslink.offsetx
	comps.pos.y = parent_pos.y + comps.poslink.offsety
end
DefineUpdateSystem({"poslink", "pos"}, USPosLink)

USMove4 = function(ent)
	local c = GetEntComps(ent)
	if c.move4.finished == false then
		if c.move4._timer == 0 then
			c.move4._originx = c.pos.x
			c.move4._originy = c.pos.y
		end
		c.move4._timer = incr(c.move4._timer, DeltaTime)
		if c.move4._timer >= c.move4.duration then
			c.move4.finished = true
			c.pos.x = c.move4.destx
			c.pos.y = c.move4.desty
		else
			if c.pos.x ~= c.move4.destx then
				c.pos.x = easing.linear(c.move4._timer, c.move4._originx, c.move4.destx - c.move4._originx, c.move4.duration)
			end
			if c.pos.y ~= c.move4.desty then
				c.pos.y = easing.linear(c.move4._timer, c.move4._originy, c.move4.desty - c.move4._originy, c.move4.duration)
			end
		end
	end
end
DefineUpdateSystem({"move4", "pos"}, USMove4)

-- Deprecated: this counts in frames not DeltaTime
USAnimSpr_Cycle = function(ent)
	local comps = GetEntComps(ent)
	comps.animspr_cycle._framecount = comps.animspr_cycle._framecount + 1
	if comps.animspr_cycle._framecount == comps.animspr_cycle.frametime then
		comps.animspr_cycle._framecount = 0
		local ss = Res.GetSpritesheet(comps.animspr.spritesheet)
		comps.animspr.curr_frame = comps.animspr.curr_frame + 1
		if comps.animspr.frame_end < 1 then
			if comps.animspr.curr_frame > ss.framecount then
				comps.animspr.curr_frame = comps.animspr.frame_start
			end
		elseif comps.animspr.curr_frame > comps.animspr.frame_end then
			comps.animspr.curr_frame = comps.animspr.frame_start
		end
	end
end
DefineUpdateSystem({"animspr", "animspr_cycle"}, USAnimSpr_Cycle)

USMenuCursor = function(ent)
	local comps = GetEntComps(ent)
	-- Input
	if btn.up == 1 then
		comps.menucursor.current = math.max(comps.menucursor.current - 1, 1)
	end
	if btn.down == 1 then
		comps.menucursor.current = math.min(comps.menucursor.current + 1, #comps.menucursor.places)
	end
	-- Animated sprite
	comps.uianimspr._timer = comps.uianimspr._timer + DeltaTime
	if comps.uianimspr._timer >= comps.uianimspr.frametime then
		comps.uianimspr._timer = comps.uianimspr._timer - comps.uianimspr.frametime
		comps.uianimspr.curr_frame = comps.uianimspr.curr_frame + 1
		if comps.uianimspr.curr_frame > #comps.uianimspr.frames then
			comps.uianimspr.curr_frame = 1
		end
	end
end
DefineUpdateSystem({"menucursor", "uianimspr"}, USMenuCursor)

USDelayedFunc = function(ent)
	local df = GetEntComp(ent, "delayedfunc")
	df.delay = df.delay - DeltaTime
	if df.delay <= 0 then
		df.func()
		KillEntity(ent)
	end
end
DefineUpdateSystem({"delayedfunc"}, USDelayedFunc)

USScreenEffect_CloseDoor = function(ent)
	local secd = GetEntComp(ent, "screeneffect_closedoor")
	if secd._timer_duration < secd.duration then
		secd._timer_duration = math.min(secd._timer_duration + DeltaTime, secd.duration)
	elseif secd._timer_stay < secd.stay then
		secd._timer_stay = math.min(secd._timer_stay + DeltaTime, secd.stay)
		if secd._timer_stay >= secd.stay then
			KillEntity(ent)
		end
	end
end

----------------- Define draw systems
DSTextDrawer = function(ent)
	local comps = GetEntComps(ent)
	Draw.print(LAYER_UI, comps.text.text, comps.pos.x, comps.pos.y)
end
DefineDrawSystem({"pos", "text"}, DSTextDrawer)

DSSpriteDrawer = function(ent)
	local comps = GetEntComps(ent)
	Draw.drawImage(LAYER_EFFECTS, Res.GetImage(comps.img.name), comps.pos.x, comps.pos.y, comps.img.orient, comps.img.scalex, comps.img.scaley)
end
DefineDrawSystem({"pos", "img"}, DSSpriteDrawer)

DSAnimSpriteDrawer = function(ent)
	local comps = GetEntComps(ent)
	local ss = Res.GetSpritesheet(comps.animspr.spritesheet)
	local img = Res.GetImage(ss.image)
	if comps.animspr.color then
		Draw.setColor(comps.animspr.color)
	end
	Draw.drawQuad(LAYER_PLAYER, img, ss.quads[comps.animspr.curr_frame], comps.pos.x, comps.pos.y, comps.animspr.orient, comps.animspr.scalex, comps.animspr.scaley)
end
DefineDrawSystem({"pos", "animspr"}, DSAnimSpriteDrawer)

DSArenaBGDrawer = function(ent)
	Draw.setColor({0, 0, 0, 1})
	Draw.rectangle(LAYER_BG, "fill", SC_MAP_RECT[1], SC_MAP_RECT[2], MAP_TILES_COLUMNS * SC_TILE_WIDTH, MAP_TILES_ROWS * SC_TILE_HEIGHT)
end
DefineDrawSystem({"arena_bg"}, DSArenaBGDrawer)

DSMapTilesDrawer = function(ent)
	local comps = GetEntComps(ent)
	local img = Res.GetImage("ss")
	local ss = Res.GetSpritesheet("tiles")
	Draw.drawQuad(LAYER_MAP, img, ss.quads[comps.maptile.type + 1], comps.pos.x, comps.pos.y, 0, SCALE, SCALE)
end
DefineDrawSystem({"maptile", "pos"}, DSMapTilesDrawer)

DSBmpTextDrawer = function(ent)
	local comps = GetEntComps(ent)
	local fontss = Res.GetSpritesheet("font")
	local fontimg = Res.GetImage(fontss.image)
	for i=1,comps.bmptext.text:len() do
		local chi = comps.bmptext.text:byte(i)
		local chr = string.char(chi)
		local si = text.charset[chr]
		if si == nil then si = text.Charset["g"] end
		assert(type(si) == "number")
		assert(fontss.quads[si + 1])
		Draw.drawQuad(LAYER_UI, fontimg, fontss.quads[si + 1], comps.pos.x + i * 8 * SCALE, comps.pos.y, 0, SCALE, SCALE)
	end
end
DefineDrawSystem({"pos", "bmptext"}, DSBmpTextDrawer)

DSMenuCursor = function(ent)
	local comps = GetEntComps(ent)
	local ss = Res.GetSpritesheet(comps.uianimspr.spritesheet)
	local img = Res.GetImage(ss.image)
	local place = comps.menucursor.places[comps.menucursor.current]
	Draw.drawQuad(LAYER_UI, img, ss.quads[comps.uianimspr.frames[comps.uianimspr.curr_frame]], place.x, place.y, 0, comps.uianimspr.scalex, comps.uianimspr.scaley)
end
DefineDrawSystem({"menucursor", "uianimspr"}, DSMenuCursor)

DSScreenEffect_CloseDoor = function(ent)
	local secd = GetEntComp(ent, "screeneffect_closedoor")
	local perc = secd._timer_duration / secd.duration
	local fact = (720 / 2) * perc
	Draw.rectagnle(LAYER_SCREEN, "fill", 0, 0, 1280, fact)
	local nhei = perc * 720 / 2
	local rvrs = 720 - nhei
	Draw.rectangle(LAYER_SCREEN, "fill", 0, rvrs, 1280, nhei)
end

----------------- Create entities
ents = {
	e_init=SpawnEntity({"initstart"})
	--e_init=SpawnEntity({"initgame"}),
}
