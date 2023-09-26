-- ** MAIN Draw Systems **

local text = require 'text'

-- For MAIN ECS rather than game ECS

DSBmpTextDrawer = function(ent)
	local comps = MAIN:GetEntComps(ent)
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
		Draw.drawQuad(comps.bmptext.layer, fontimg, fontss.quads[si + 1], comps.pos.x + (i - 1) * 8 * SCALE, comps.pos.y, 0, SCALE, SCALE)
	end
end
MAIN:DefineDrawSystem({"pos", "bmptext"}, DSBmpTextDrawer)

DSScreenEffect_Door = function(ent)
	local secd = MAIN:GetEntComp(ent, "screeneffect_door")
	local perc = secd._timer_duration / secd.duration
	if secd.opening == true then
		perc = 1 - perc
	end
	local fact = (720 / 2) * perc
	if secd.rect_color ~= nil then
		Draw.setColor(secd.rect_color)
	end
	Draw.rectangle(secd.layer, "fill", 0, 0, 1280, fact)
	local nhei = perc * 720 / 2
	local rvrs = 720 - nhei
	if secd.rect_color ~= nil then
		Draw.setColor(secd.rect_color)
	end
	Draw.rectangle(secd.layer, "fill", 0, rvrs, 1280, nhei)
end
MAIN:DefineDrawSystem({"screeneffect_door"}, DSScreenEffect_Door)