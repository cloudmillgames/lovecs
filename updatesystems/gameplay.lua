-- ** Gameplay Systems **
-- Initializes actual gameplay start
USInitGame = function(ent)
	love.graphics.setBackgroundColor(ARENA_BG_COLOR)
	KillAllEntities()

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
	local def_player = function()
		local tank = Construct_Tank(PLAYER_COLOR, LAYER_PLAYER)
		EntAddComp(tank, "player")
		local comps = GetEntComps(tank)
		comps.pos.x = MAP_TO_COORD_X(10)
		comps.pos.y = MAP_TO_COORD_Y(13)
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
					comps.collid.custom = m[idx]
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
	local def_screen_effect = function()
		local se = SpawnEntity({"screeneffect_door"})
		local c = GetEntComp(se, "screeneffect_door")
		c.duration = 0.35
		c.stay = 0
		c.rect_color = ARENA_BG_COLOR
		c.opening = true
	end
	LoadResources()
	def_fps()
	def_goal()
	def_bg()
	def_player()
	def_map(STAGE)
	def_screen_effect()
	Construct_SpawnDirector()
	-- init only runs once
	KillEntity(ent)
end
DefineUpdateSystem({"initgame"}, USInitGame)

-- Reads player movement input and plays tank engine sounds
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

-- Reads player fire input and applies turret cooldown, fires shell
USPlayerTankTurret = function(ent)
	local c = GetEntComps(ent)
	if btn.z >= 1 then
		if c.tankturret._timer_cooldown == 0 then
			if #c.tankturret._live_shells < c.tankturret.max_live_shells then
				local shell = Fire_Shell(ent, true)
				if IsDeadEntity(shell) == false then
					table.insert(c.tankturret._live_shells, shell)
				end
				c.tankturret._timer_cooldown = c.tankturret.cooldown
			end
		end
	end
	c.tankturret._timer_cooldown = math.max(0, c.tankturret._timer_cooldown - DeltaTime)
end
DefineUpdateSystem({"player", "tankturret", "dir", "pos", "collshape"}, USPlayerTankTurret)

-- Tracks live shells and updates counters
USTurretUpdate = function(ent)
	local tt = GetEntComp(ent, "tankturret")
	local new_live_shells = {}
	for i=1,#tt._live_shells do
		if IsDeadEntity(tt._live_shells[i]) == false then
			table.insert(new_live_shells, tt._live_shells[i])
		end
	end
	tt._live_shells = new_live_shells
end
DefineUpdateSystem({"tankturret"}, USTurretUpdate)

-- Moves tank shell
USTankShell = function(ent)
	local c = GetEntComps(ent)
	local mov = GetMovementFromDir(c.dir.dir)
	c.pos.x = c.pos.x + (mov.x * c.projectile.speed)
	c.pos.y = c.pos.y + (mov.y * c.projectile.speed)
end
DefineUpdateSystem({"projectile", "pos", "dir"}, USTankShell)

-- Tank shell collision handler
USShellCollision = function(ent)
	local c = GetEntComps(ent)
	local player_shell = HasEntComp(ent, "playershell")
	local events = c.collid.events
	for i=1,#events do
		local other = events[i][1]
		if other == ent then
			other = events[i][2]
		end
		local other_collid = GetEntComp(other, "collid")
		local other_layer = other_collid.layer
		if other_layer == LAYER_MAP then -- map tiles
			local tile_type = other_collid.custom
			-- All other types of tiles we ignore collision: grass, ice, water
			if tile_type == TILE_BRICK then
				Small_Explosion(c.pos)
				PlaySound("brick_destroy")
				KillEntity(other)
				KillEntity(ent)
			elseif tile_type == TILE_STONE then
				Small_Explosion(c.pos)
				PlaySound("solid_impact")
				KillEntity(ent)
			end
		elseif other_layer == LAYER_BG then	-- map boundaries
			Small_Explosion(c.pos)
			if player_shell then
				PlaySound("solid_impact")
			end
			KillEntity(ent)
		end
	end
end
DefineUpdateSystem({"projectile", "pos", "dir", "collshape", "collid"}, USShellCollision)

-- Handles tank throttle preprocessing for direction and motion sensing to detect movement blockers
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

-- Updates tank sprite animation and applies actual throttle movement with stepping and rounding
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

-- Kills entity if it leaves predefined out of bounds area 1000 pixels out of screen bounds
USOutOfBoundsKill = function(ent)
	local c = GetEntComps(ent)
	if c.pos.x > SC_WIDTH + 1000 or c.pos.x < -1000 or c.pos.y > SC_HEIGHT + 1000 or c.pos.y < -1000 then
		KillEntity(ent)
	end
end
DefineUpdateSystem({"outofbounds_kill", "pos"}, USOutOfBoundsKill)

USSpawnDirector = function(ent)
	local c = GetEntComps(ent)
	if c.spawndirector.active then
		local sd = c.spawndirector

		-- Update alive units tally
		local alive = {}
		for i=1,#sd._spawns do
			if IsDeadEntity(sd._spawns[i]) == false then
				add(alive, sd._spawns[i])
			end
		end
		sd._spawns = alive

		-- Spawn timer
		if sd._timer > 0 then
			sd._timer = math.max(sd._timer - DeltaTime, 0)
		else
			local alive_count = #sd._spawns
			if sd.total_spawns > 0 then
				if alive_count < sd.max_alive then
					sd.total_spawns = sd.total_spawns - 1
					sd._timer = sd.cooldown
					Spawn_EnemyTank()
				end
			else
				if alive_count == 0 then
					Msging.dispatchEntity(sd.msg_channel, sd.msg_on_finish)
					KillEntity(ent)
				end
			end
		end
	end
end
DefineUpdateSystem({"spawndirector"}, USSpawnDirector)