-- ** GAME **
----------------- Resource manager
Res = {}
Res.Images = {}
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

----------------- Define components
CInit = {}
DefineComponent("init", CInit)

CPos = {
	x = 0,
	y = 0
}
DefineComponent("pos", CPos)

CText = {
	text = ""
}
DefineComponent("text", CText)

CSpr = {
	name="",
	orient=0.0,
	scalex=1,
	scaley=1
}
DefineComponent("spr", CSpr)

CPlayer = {
}
DefineComponent("player", CPlayer)

----------------- Define update systems
USInit = function(ent)
	local load_resources = function()
		Res.Init()
		Res.LoadImagesPack({
			santa = "santa.png"
		})
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
		local se = SpawnEntity({"pos", "spr"})
		local pc = GetEntComp(se, "pos")
		local sc = GetEntComp(se, "spr")
		pc.x = 500
		pc.y = 200
		sc.name = "santa"
		sc.scalex = 4
		sc.scaley = 4
	end
	load_resources()
	def_text()
	def_spr()
	-- init only runs once
	KillEntity(ent)
end
DefineUpdateSystem({"init"}, USInit)

USPlayerUpdate = function(ent)
	local comps = GetEntComps(ent)
end
DefineUpdateSystem({"player", "pos"}, USPlayerUpdate)

----------------- Define draw systems
DSTextDrawer = function(ent)
	local comps = GetEntComps(ent)
	love.graphics.print(comps.text.text, comps.pos.x, comps.pos.y)
end
DefineDrawSystem({"pos", "text"}, DSTextDrawer)

DSSpriteDrawer = function(ent)
	local comps = GetEntComps(ent)
	love.graphics.draw(Res.GetImage(comps.spr.name), comps.pos.x, comps.pos.y, comps.spr.orient, comps.spr.scalex, comps.spr.scaley)
end
DefineDrawSystem({"pos", "spr"}, DSSpriteDrawer)

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