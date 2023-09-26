-- ** Intro Sequence Systems **

-- Initializes start screen sequence
USInitStart = function(ent)
	love.graphics.setBackgroundColor(START_BG_COLOR)
	KillAllEntities()
	
	local def_fps = function()
		local te = SpawnEntity({"pos", "text", "fpscounter"})
		local pc = GetEntComp(te, "pos")
		pc.x = 1230
		pc.y = 2
		local tc = GetEntComp(te, "text")
		tc.text = "<FPS>"
	end
	local def_skipper = function()
		local se = SpawnEntity({"timedown", "buttonfunc"})
		local c = GetEntComps(se)
		c.timedown.time = 3.0
		c.buttonfunc.func = Time_Skip
		c.buttonfunc.kill_after = 1
	end
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
	def_skipper()
	def_title()
	def_fps()
end
DefineUpdateSystem({"initstart"}, USInitStart)

-- Handles movement input and selection of Battlecity menu cursor, applies fullscreen door effect on selection
USMenuCursor = function(ent)
	local comps = GetEntComps(ent)
	-- Input
	if btn.up == 1 then
		comps.menucursor.current = math.max(comps.menucursor.current - 1, 1)
	end
	if btn.down == 1 then
		comps.menucursor.current = math.min(comps.menucursor.current + 1, #comps.menucursor.places)
	end
	if btn.z == 1 then
		local f = comps.menucursor.funcs[comps.menucursor.current]
		if f ~= nil then
			local se = SpawnEntity({"screeneffect_door", "delayedfunc"})
			local secd = GetEntComp(se, "screeneffect_door")
			local delf = GetEntComp(se, "delayedfunc")
			secd.duration = 0.35
			secd.rect_color = ARENA_BG_COLOR
			delf.delay = 1.1
			delf.func = f
			KillEntity(ent)
		end
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