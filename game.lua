-- ** GAME **
----------------- Constants
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

LAYER_BG = 1
LAYER_MAP = 2
LAYER_TANKS = 3
LAYER_PLAYER = 4
LAYER_EFFECTS = 5
LAYER_UI = 6

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
	-- Specifies range of frames in spritesheet
	frame_start=1,	-- what's first frame in spritesheet
	frame_end=-1	-- < 1 means last frame
}
DefineComponent("animspr", CAnimSpr)

-- an animator for the animated sprite that cycles all frames
CAnimSpr_Cycle = {
	frametime=1,
	_framecount=0	-- used to count frame time
}
DefineComponent("animspr_cycle", CAnimSpr_Cycle)

-- Battlecity arena
CArenaBG = {}
DefineComponent("arena_bg", CArenaBG)

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
	local def_tank = function()
		local se = SpawnEntity({"pos", "animspr", "animspr_cycle", "player"})
		local pc = GetEntComp(se, "pos")
		local ac = GetEntComp(se, "animspr")
		local acc = GetEntComp(se, "animspr_cycle")
		pc.x = 100
		pc.y = 150
		ac.spritesheet="tanks"
		ac.scalex = SCALE_X
		ac.scaley = SCALE_Y
		acc.frametime = 4
	end
	local def_bg = function()
		local se = SpawnEntity({"arena_bg"})
	end
	load_resources()
	def_text()
	def_spr()
	def_bg()
	def_tank()
	-- init only runs once
	KillEntity(ent)
end
DefineUpdateSystem({"init"}, USInit)

USPlayerUpdate = function(ent)
	local comps = GetEntComps(ent)
	if btn.up then comps.pos.y = comps.pos.y - 1 end
	if btn.down then comps.pos.y = comps.pos.y + 1 end
	if btn.left then comps.pos.x = comps.pos.x - 1 end
	if btn.right then comps.pos.x = comps.pos.x + 1 end
end
DefineUpdateSystem({"player", "pos"}, USPlayerUpdate)

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
	Draw.drawQuad(LAYER_PLAYER, img, ss.quads[comps.animspr.curr_frame], comps.pos.x, comps.pos.y, comps.animspr.orient, comps.animspr.scalex, comps.animspr.scaley)
end
DefineDrawSystem({"pos", "animspr"}, DSAnimSpriteDrawer)

DSArenaBGDrawer = function(ent)
	Draw.setColor({0, 0, 0, 1})
	Draw.rectangle(LAYER_BG, "fill", SC_MAP_RECT[1], SC_MAP_RECT[2], MAP_TILES_COLUMNS * SC_TILE_WIDTH, MAP_TILES_ROWS * SC_TILE_HEIGHT)
end
DefineDrawSystem({"arena_bg"}, DSArenaBGDrawer)

----------------- Define singleton update systems

----------------- Define singleton draw systems

----------------- Create entities
ents = {
	e_init=SpawnEntity({"init"}),
}
