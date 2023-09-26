-- ** GAME **
----------------- Constants
UP = 1
RIGHT = 2
DOWN = 3
LEFT = 4

ORG_WIDTH = 256.0
ORG_HEIGHT = 224.0
SCALE_X = 3.0
SCALE_Y = 3.0
MAP_START_X = 16.0
MAP_START_Y = 16.0
MAP_TILES_COLUMNS = 23
MAP_TILES_ROWS = 13
MAP_TILE_WIDTH = 16
MAP_TILE_HEIGHT = 16
ARENA_BG_COLOR = {.4, .4, .4, 1}
SC_TILE_WIDTH = MAP_TILE_WIDTH * SCALE_X
SC_TILE_HEIGHT = MAP_TILE_HEIGHT * SCALE_Y
SC_MAP_RECT = {MAP_START_X * SCALE_X, MAP_START_Y * SCALE_Y, MAP_TILES_COLUMNS * MAP_TILE_WIDTH * SCALE_X, MAP_TILES_ROWS * MAP_TILE_HEIGHT * SCALE_Y}
PLAYER_COLOR = {0.89, 0.894, 0.578, 1}

LAYER_BG = 1
LAYER_MAP = 2
LAYER_TANKS = 3
LAYER_PLAYER = 4
LAYER_EFFECTS = 5
LAYER_UI = 6

function MAP_TO_COORD_X(column)
	if column > MAP_TILES_COLUMNS or column < 1 then
		error("Invalid Map column: "..column)
	end
	return column * MAP_TILE_WIDTH * SCALE_X
end
function MAP_TO_COORD_Y(row)
	if row > MAP_TILES_ROWS or row < 1 then
		error("Invalid Map row: "..row)
	end
	return row * MAP_TILE_HEIGHT * SCALE_Y
end

----------------- Define components
-- Used to init game, should remove itself when run
CInit = {}
DefineComponent("init", CInit)

-- a 2D position
CPos = {
	x = 0,
	y = 0
}
DefineComponent("pos", CPos)

-- a direction of 4: 1 (up), 2 (right), 3(down), 4 (left)
CDir = {
	dir = 1
}
DefineComponent("dir", CDir)

-- a string
CText = {
	text = ""
}
DefineComponent("text", CText)

-- an image that gets drawn
CImg = {
	name="",
	orient=0.0,
	scalex=1,
	scaley=1
}
DefineComponent("img", CImg)

-- identify entity as player
CPlayer = {
}
DefineComponent("player", CPlayer)

-- an animated sprite
CAnimSpr = {
	spritesheet="",
	curr_frame=1,
	orient=0.0,
	scalex=1,
	scaley=1,
	color=nil,
	-- Specifies range of frames in spritesheet
	frame_start=1,	-- what's first frame in spritesheet
	frame_end=-1	-- < 1 means last frame
}
DefineComponent("animspr", CAnimSpr)

-- an animator for the animated sprite that cycles all frames
-- Deprecated: this counts in frames not DeltaTime
CAnimSpr_Cycle = {
	frametime=1,
	_framecount=0	-- used to count frame time
}
DefineComponent("animspr_cycle", CAnimSpr_Cycle)

-- Battlecity arena
CArenaBG = {}
DefineComponent("arena_bg", CArenaBG)

-- All tanks have this comp
CTank = {
	type = 0,			-- refers to row in tanks spritesheet
	chain_tick = 0		-- ticks 0,1 to move chain
}
DefineComponent("tank", CTank)


----------------- Define update systems
USInit = function(ent)
	love.graphics.setBackgroundColor(ARENA_BG_COLOR)

	local load_resources = function()
		Res.Init()
		Res.LoadImagesPack(RES_IMAGES)
		Res.LoadSpritesheetsPack(RES_SPRITESHEETS)
	end
	local def_text = function()
		local te = SpawnEntity({"pos", "text"})
		local pc = GetEntComp(te, "pos")
		pc.x = 100
		pc.y = 40
		local tc = GetEntComp(te, "text")
		tc.text = "Hello Universe!"
	end
	local def_spr = function()
		local se = SpawnEntity({"pos", "img"})
		local pc = GetEntComp(se, "pos")
		local sc = GetEntComp(se, "img")
		pc.x = 500
		pc.y = 200
		sc.name = "santa"
		sc.scalex = 4
		sc.scaley = 4
	end
	local def_player = function()
		local se = SpawnEntity({"pos", "animspr", "player", "dir", "tank"})
		local pc = GetEntComp(se, "pos")
		local ac = GetEntComp(se, "animspr")
		local tc = GetEntComp(se, "tank")
		pc.x = MAP_TO_COORD_X(12)
		pc.y = MAP_TO_COORD_Y(13)
		ac.spritesheet="tanks"
		ac.scalex = SCALE_X
		ac.scaley = SCALE_Y
		ac.color = PLAYER_COLOR
	end
	local def_bg = function()
		local se = SpawnEntity({"arena_bg"})
	end
	load_resources()
	--def_text()
	--def_spr()
	def_bg()
	def_player()
	-- init only runs once
	KillEntity(ent)
end
DefineUpdateSystem({"init"}, USInit)

USPlayerUpdate = function(ent)
	local comps = GetEntComps(ent)
	if btn.up then comps.dir.dir = UP end
	if btn.down then comps.dir.dir = DOWN end
	if btn.left then comps.dir.dir = LEFT end
	if btn.right then comps.dir.dir = RIGHT end
end
DefineUpdateSystem({"player", "dir"}, USPlayerUpdate)

USTankUpdate = function(ent)
	local comps = GetEntComps(ent)
	-- Update frame to match direction and chain tick
	local tt = comps.tank.type
	local td = comps.dir.dir
	comps.animspr.curr_frame = (tt * 8) + 1 + (td - 1) * 2 + comps.tank.chain_tick
	-- Update chain tick
	comps.tank.chain_tick = 1 - comps.tank.chain_tick
end
DefineUpdateSystem({"tank", "animspr", "dir"}, USTankUpdate)

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

----------------- Create entities
ents = {
	e_init=SpawnEntity({"init"}),
}
