-- ** General Draw Systems **

local text = require 'text'

DSTextDrawer = function(ent)
	local comps = ECS:GetEntComps(ent)
	Draw.print(LAYER_UI, comps.text.text, comps.pos.x, comps.pos.y, 0, comps.text.scale, comps.text.scale)
end
ECS:DefineDrawSystem({"pos", "text"}, DSTextDrawer)

DSImageDrawer = function(ent)
	local comps = ECS:GetEntComps(ent)
	Draw.drawImage(comps.img.layer, Res.GetImage(comps.img.name), comps.pos.x, comps.pos.y, comps.img.orient, comps.img.scalex, comps.img.scaley)
end
ECS:DefineDrawSystem({"pos", "img"}, DSImageDrawer)

DSSpriteDrawer = function(ent)
	local comps = ECS:GetEntComps(ent)
	local ss = Res.GetSpritesheet(comps.spr.spritesheet)
	local img = Res.GetImage(ss.image)
	if comps.spr.color then
		Draw.setColor(comps.spr.color)
	end
	Draw.drawQuad(comps.spr.layer, img, ss.quads[comps.spr.spriteid], comps.pos.x, comps.pos.y, comps.spr.orient, comps.spr.scalex, comps.spr.scaley)
end
ECS:DefineDrawSystem({"pos", "spr"}, DSSpriteDrawer)

DSAnimSpriteDrawer = function(ent)
	local comps = ECS:GetEntComps(ent)
	local ss = Res.GetSpritesheet(comps.animspr.spritesheet)
	local img = Res.GetImage(ss.image)
	if comps.animspr.color then
		Draw.setColor(comps.animspr.color)
	end
	Draw.drawQuad(comps.animspr.layer, img, ss.quads[comps.animspr.curr_frame], comps.pos.x, comps.pos.y, comps.animspr.orient, comps.animspr.scalex, comps.animspr.scaley)
end
ECS:DefineDrawSystem({"pos", "animspr"}, DSAnimSpriteDrawer)

DSGfxRectDrawer = function(ent)
	local c = ECS:GetEntComps(ent)
	if c.gfxrect.color ~= nil then
		Draw.setColor(c.gfxrect.color)
	end
	Draw.rectangle(c.gfxrect.layer, "fill", c.gfxrect.rect.x, c.gfxrect.rect.y, c.gfxrect.rect.w, c.gfxrect.rect.h)
end
ECS:DefineDrawSystem({"gfxrect"}, DSGfxRectDrawer)

DSArenaBGDrawer = function(ent)
	Draw.setColor({0, 0, 0, 1})
	Draw.rectangle(LAYER_BG, "fill", SC_MAP_RECT[1], SC_MAP_RECT[2], MAP_TILES_COLUMNS * SC_TILE_WIDTH, MAP_TILES_ROWS * SC_TILE_HEIGHT)
end
ECS:DefineDrawSystem({"arena_bg"}, DSArenaBGDrawer)

DSMapTilesDrawer = function(ent)
	local comps = ECS:GetEntComps(ent)
	local img = Res.GetImage("ss")
	local ss = Res.GetSpritesheet("tiles")
	local layer = LAYER_MAP
	local anim = 0
	if comps.maptile.type == TILE_GRASS then
		layer = LAYER_OVERMAP
	elseif comps.maptile.type == TILE_WATER then
		local mapclock = ECS:GetTaggedEntComp("mapclock", "mapclock")
		assert(mapclock, "Must be non-nil at this point")
		anim = mapclock.clock
	end
	Draw.drawQuad(layer, img, ss.quads[comps.maptile.type + 1 + anim], comps.pos.x, comps.pos.y, 0, SCALE, SCALE)
end
ECS:DefineDrawSystem({"maptile", "pos"}, DSMapTilesDrawer)

DSBmpTextDrawer = function(ent)
	local comps = ECS:GetEntComps(ent)
	local fontss = Res.GetSpritesheet("font")
	local fontimg = Res.GetImage(fontss.image)
	for i=1,comps.bmptext.text:len() do
		local chi = comps.bmptext.text:byte(i)
		local chr = string.char(chi)
		local si = text.charset[chr]
		if si == nil then
			-- to support symbols and arabic glyphs just use the code given
			if chi < 35 * 6 then
				si = chi
			else
				-- unknowns are dominos
				si = 184
			end
		end
		assert(type(si) == "number")
		assert(fontss.quads[si + 1])
		if comps.bmptext.color ~= nil then
			Draw.setColor(comps.bmptext.color)
		end
		Draw.drawQuad(LAYER_UI, fontimg, fontss.quads[si + 1], comps.pos.x + (i - 1) * 8 * SCALE, comps.pos.y, 0, SCALE, SCALE)
	end
end
ECS:DefineDrawSystem({"pos", "bmptext"}, DSBmpTextDrawer)

DSMenuCursor = function(ent)
	local comps = ECS:GetEntComps(ent)
	local ss = Res.GetSpritesheet(comps.uianimspr.spritesheet)
	local img = Res.GetImage(ss.image)
	local place = comps.menucursor.places[comps.menucursor.current]
	Draw.drawQuad(LAYER_UI, img, ss.quads[comps.uianimspr.frames[comps.uianimspr.curr_frame]], place.x, place.y, 0, comps.uianimspr.scalex, comps.uianimspr.scaley)
end
ECS:DefineDrawSystem({"menucursor", "uianimspr"}, DSMenuCursor)

DSScreenEffect_Door = function(ent)
	local secd = ECS:GetEntComp(ent, "screeneffect_door")
	local perc = secd._timer_duration / secd.duration
	if secd.opening == true then
		perc = 1 - perc
	end
	local fact = (720 / 2) * perc
	if secd.rect_color ~= nil then
		Draw.setColor(secd.rect_color)
	end
	Draw.rectangle(LAYER_SCREEN, "fill", 0, 0, 1280, fact)
	local nhei = perc * 720 / 2
	local rvrs = 720 - nhei
	if secd.rect_color ~= nil then
		Draw.setColor(secd.rect_color)
	end
	Draw.rectangle(LAYER_SCREEN, "fill", 0, rvrs, 1280, nhei)
end
ECS:DefineDrawSystem({"screeneffect_door"}, DSScreenEffect_Door)
