-- ** GAME **
----------------- Resource manager
Res = {}
Res.Images = {}
Res.Spritesheets = {}
Res.Init = function()
end
Res.LoadImage = function(name, path)
	local info = love.filesystem.getInfo(path)
	if info == nil then
		error("Res.LoadImage() path not found: "..path.."("..name..")")
	else
		local ni = love.graphics.newImage(path)
		Res.Images[name] = ni
	end
end
Res.LoadImagesPack = function(pack)
	for k, v in pairs(pack) do
		Res.LoadImage(k, v)
	end
end
Res.GetImage = function(name)
	if Res.Images[name] == nil then
		error("Res.GetImage called on undefined image: "..name)
	end
	return Res.Images[name]
end
Res.LoadSpritesheet = function(name, data)
	-- tanks = {"ss", {0, 112}, {128, 128}, {16, 16}}
	local img = Res.GetImage(data[1])
	local startx = tonumber(data[2][1])
	local starty = tonumber(data[2][2])
	local qw = tonumber(data[4][1])
	local qh = tonumber(data[4][2])
	local fc = tonumber(data[3][1])/qw
	local fr = tonumber(data[3][2])/qh
	local frames = fc * fr
	local ss = {
		image=data[1],
		framecount=frames,
		quads={}
	}
	for r=1,fr do
		for c=1,fc do
			local zc = c - 1
			local zr = r - 1
			table.insert(ss.quads, love.graphics.newQuad(
				startx + (zc * qw), starty + (zr * qh),
				qw, qh, img:getWidth(), img:getHeight()))
		end
	end
	Res.Spritesheets[name] = ss
end
Res.LoadSpritesheetsPack = function(pack)
	for k, v in pairs(pack) do
		Res.LoadSpritesheet(k, v)
	end
end
-- Returns: {image="img_name", framecount=N, quads={Quad,..}}
Res.GetSpritesheet = function(name)
	if Res.Spritesheets[name] == nil then
		error("Res.GetSpritesheet called on undefined: "..name)
	end
	return Res.Spritesheets[name]
end
require('resources')

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
	scaley=1
}
DefineComponent("animspr", CAnimSpr)

-- an animator for the animated sprite that cycles all frames
CAnimSpr_Cycle = {
	frametime=1,
	_framecount=0	-- used to count frame time
}
DefineComponent("animspr_cycle", CAnimSpr_Cycle)

----------------- Define update systems
USInit = function(ent)
	local load_resources = function()
		Res.Init()
		Res.LoadImagesPack(RES_IMAGES)
		Res.LoadSpritesheetsPack(RES_SPRITESHEETS)
	end
	local def_text = function()
		local te = SpawnEntity({"pos", "text"})
		local pc = GetEntComp(te, "pos")
		pc.x = 100
		pc.y = 100
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
		ac.scalex = 2
		ac.scaley = 2
		acc.frametime = 4
	end
	load_resources()
	def_text()
	def_spr()
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
		if comps.animspr.curr_frame > ss.framecount then
			comps.animspr.curr_frame = 1
		end
	end
end
DefineUpdateSystem({"animspr", "animspr_cycle"}, USAnimSpr_Cycle)

----------------- Define draw systems
DSTextDrawer = function(ent)
	local comps = GetEntComps(ent)
	love.graphics.print(comps.text.text, comps.pos.x, comps.pos.y)
end
DefineDrawSystem({"pos", "text"}, DSTextDrawer)

DSSpriteDrawer = function(ent)
	local comps = GetEntComps(ent)
	love.graphics.draw(Res.GetImage(comps.img.name), comps.pos.x, comps.pos.y, comps.img.orient, comps.img.scalex, comps.img.scaley)
end
DefineDrawSystem({"pos", "img"}, DSSpriteDrawer)

DSAnimSpriteDrawer = function(ent)
	local comps = GetEntComps(ent)
	local ss = Res.GetSpritesheet(comps.animspr.spritesheet)
	local img = Res.GetImage(ss.image)
	love.graphics.draw(img, ss.quads[comps.animspr.curr_frame], comps.pos.x, comps.pos.y, comps.animspr.orient, comps.animspr.scalex, comps.animspr.scaley)
end
DefineDrawSystem({"pos", "animspr"}, DSAnimSpriteDrawer)

----------------- Define singleton update systems

----------------- Define singleton draw systems

----------------- Create entities
ents = {
	e_init=SpawnEntity({"init"}),
}

----------------------------------------------

-- CSprite = {
	-- frame = 1,
	-- flip_x = false,
	-- flip_y = false,
-- }

-- CPlayer = {
	-- mode = "play",
-- }

-- DefineComponent("pos", CPos)
-- DefineComponent("sprite", CSprite)
-- DefineComponent("player", CPlayer)

----------------- Define systems

-- USPlayerController = function(ent)
	-- if btn(1) then ent.pos.x = ent.pos.x + 1 end 
	-- if btn(0) then ent.pos.x = ent.pos.x - 1 end 
-- end 

-- DSSpriteDrawer = function(ent)
	-- spr(ent.sprite.frame, ent.pos.x, ent.pos.y, 1, 1, ent.sprite.flip_x, ent.sprite.flip_y)
-- end 

-- DefineUpdateSystem({"player", "pos"}, USPlayerController)
-- DefineDrawSystem({"sprite"}, DSSpriteDrawer)

----------------- Create entities

-- eid = SpawnEntity({"pos", "sprite", "player"})

----------------- Clearing entities 

-- KillEntity(eid)
-- KillAllEntities()