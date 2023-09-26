-- ** Gameplay Systems **
-- Initializes actual gameplay start
USInitGame = function(ent)
	love.graphics.setBackgroundColor(ARENA_BG_COLOR)
	-- No need to kill all entities as level screen transition does it

	local def_fps = function()
		local te = ECS:SpawnEntity({"pos", "text", "fpscounter"})
		local pc = ECS:GetEntComp(te, "pos")
		pc.x = 1230
		pc.y = 2
		local tc = ECS:GetEntComp(te, "text")
		tc.text = "<FPS>"
	end
	local def_goal = function()
		local se = ECS:SpawnEntity({"pos", "animspr", "collid", "collshape", "criticaltarget"})
		local c = ECS:GetEntComps(se)
		
		c.pos.x = MAP_TO_COORD_X(12)
		c.pos.y = MAP_TO_COORD_Y(13)

		c.animspr.spritesheet = "icons"
		c.animspr.curr_frame = 3
		c.animspr.scalex = SCALE
		c.animspr.scaley = SCALE

		c.collid.ent = se
		c.collid.dynamic = false
		c.collid.layer = LAYER_OBJECTS

		c.collshape.type = SHAPE_RECT
		c.collshape.x = 0
		c.collshape.y = 0
		c.collshape.w = 16 * SCALE
		c.collshape.h = 16 * SCALE
	end
	local def_bg = function()
		-- Arena background
		local se = ECS:SpawnEntity({"arena_bg"})
		-- Arena boundaries
		local bounds = {}
		for i=1,4 do
			local be = ECS:SpawnEntity({"dbgname", "pos", "collshape", "collid"})
			local comps = ECS:GetEntComps(be)

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

		local up_shape = ECS:GetEntComp(bounds[UP], "collshape")
		up_shape.x = bound_rect.x
		up_shape.y = bound_rect.y
		up_shape.w = bound_rect.w
		up_shape.h = SC_TILE_HEIGHT

		local right_shape = ECS:GetEntComp(bounds[RIGHT], "collshape")
		right_shape.x = bound_rect.x + bound_rect.w - SC_TILE_WIDTH
		right_shape.y = bound_rect.y + SC_TILE_HEIGHT
		right_shape.w = SC_TILE_WIDTH
		right_shape.h = bound_rect.h - SC_TILE_HEIGHT * 2

		local down_shape = ECS:GetEntComp(bounds[DOWN], "collshape")
		down_shape.x = bound_rect.x
		down_shape.y = bound_rect.y + bound_rect.h - SC_TILE_HEIGHT
		down_shape.w = bound_rect.w
		down_shape.h = SC_TILE_HEIGHT

		local left_shape = ECS:GetEntComp(bounds[LEFT], "collshape")
		left_shape.x = bound_rect.x
		left_shape.y = bound_rect.y + SC_TILE_HEIGHT
		left_shape.w = SC_TILE_WIDTH
		left_shape.h = bound_rect.h - SC_TILE_HEIGHT * 2
	end
	local def_map = function(mapnum)
		-- Map collider
		local collmap_ent = ECS:SpawnEntity({"collmap"})
		local collmap = ECS:GetEntComp(collmap_ent, "collmap")
		collmap.tile_size = {8 * SCALE, 8 * SCALE}
		collmap.map_rect = makeRect(SC_MAP_RECT[1], SC_MAP_RECT[2], SC_MAP_RECT[3], SC_MAP_RECT[4])
		collmap.columns = MAP_TILES_COLUMNS * 2
		collmap.rows = MAP_TILES_ROWS * 2

		-- Load map tiles
		local m = RES_MAPS[mapnum]
		local tl = ""
		for j=1,MAP_TILES_ROWS * 2 do
			for i=1,MAP_TILES_COLUMNS * 2 do
				local idx = ((j - 1) * MAP_TILES_COLUMNS * 2) + i
				-- collmap
				add(collmap.matrix, m[idx])
				-- tile
				if m[idx] ~= 0 then
					local se = ECS:SpawnEntity({"dbgname", "maptile", "collid", "pos"})
					collmap.ent_matrix[idx] = se

					local comps = ECS:GetEntComps(se)

					comps.dbgname.name = "MTile"..tostring(idx).."_"..tostring(se)

					comps.maptile.type = m[idx]
					comps.maptile.collmap = collmap_ent
					comps.maptile.column = i
					comps.maptile.row = j

					comps.pos.x = SC_MAP_RECT[1] + ((i - 1) * SC_TILE_WIDTH / 2)
					comps.pos.y = SC_MAP_RECT[2] + ((j - 1) * SC_TILE_HEIGHT / 2)

					comps.collid.ent = se
					comps.collid.dynamic = false
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
		local se = ECS:SpawnEntity({"screeneffect_door"})
		local c = ECS:GetEntComp(se, "screeneffect_door")
		c.duration = 0.35
		c.stay = 0
		c.rect_color = ARENA_BG_COLOR
		c.opening = true
	end
	LoadResources()
	def_fps()
	def_goal()
	def_bg()
	Construct_PlayerSpawner()
	def_map(STAGE)
	def_screen_effect()
	Construct_SpawnDirector()
	-- init only runs once
	ECS:KillEntity(ent)
end
ECS:DefineUpdateSystem({"initgame"}, USInitGame)

-- Reads player movement input and plays tank engine sounds
USPlayerUpdate = function(ent)
	local comps = ECS:GetEntComps(ent)
	if comps.tank.moving == 0 then
		-- a direct input check leads to left/right overwriting up/down in control
		-- we solve this by favoring newest cursor control and using that as our new direction
		-- So if we hold up then left/right, or hold left then up/down, it works correctly
		local keys = {btn.up, btn.right, btn.down, btn.left}
		local newest_input = 0
		local lowest = 0
		for i,v in pairs(keys) do
			if v > 0 then
				if lowest == 0 or v < lowest then
					lowest = v
					newest_input = i
				end
			end
		end
		if newest_input > 0 then
			comps.dir.dir = newest_input
		end
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
ECS:DefineUpdateSystem({"player", "dir", "tank"}, USPlayerUpdate)

USTankTurret = function(ent)
	local c = ECS:GetEntComps(ent)
	if c.tankturret.trigger then
		if c.tankturret._timer_cooldown == 0 then
			if #c.tankturret._live_shells < c.tankturret.max_live_shells then
				local is_player = ECS:HasEntComp(ent, "player")
				local shell = Fire_Shell(ent, is_player)
				if ECS:IsDeadEntity(shell) == false then
					table.insert(c.tankturret._live_shells, shell)
				end
				c.tankturret._timer_cooldown = c.tankturret.cooldown
			end
		end
	end
	c.tankturret._timer_cooldown = math.max(0, c.tankturret._timer_cooldown - DeltaTime)
	c.tankturret.trigger = false
end
ECS:DefineUpdateSystem({"tankturret", "dir", "pos"}, USTankTurret)

-- Reads player fire input and applies turret cooldown, fires shell
USPlayerTankTurret = function(ent)
	local c = ECS:GetEntComps(ent)
	if btn.z >= 1 then
		c.tankturret.trigger = true
	end
end
ECS:DefineUpdateSystem({"player", "tankturret"}, USPlayerTankTurret)

-- Tracks live shells and updates counters
USTurretUpdate = function(ent)
	local tt = ECS:GetEntComp(ent, "tankturret")
	local new_live_shells = {}
	for i=1,#tt._live_shells do
		if ECS:IsDeadEntity(tt._live_shells[i]) == false then
			table.insert(new_live_shells, tt._live_shells[i])
		end
	end
	tt._live_shells = new_live_shells
end
ECS:DefineUpdateSystem({"tankturret"}, USTurretUpdate)

-- Moves tank shell
USTankShell = function(ent)
	local c = ECS:GetEntComps(ent)
	local mov = GetMovementFromDir(c.dir.dir)
	-- Assumes speed to be SCALEd already
	c.pos.x = c.pos.x + (mov.x * c.projectile.speed * DeltaTime)
	c.pos.y = c.pos.y + (mov.y * c.projectile.speed * DeltaTime)
end
ECS:DefineUpdateSystem({"projectile", "pos", "dir"}, USTankShell)

-- Tank shell collision handler
USShellCollision = function(ent)
	local c = ECS:GetEntComps(ent)
	local player_shell = ECS:HasEntComp(ent, "playershell")
	local events = c.collid.events
	for i=1,#events do
		local other = events[i][1]
		if other == ent then
			other = events[i][2]
		end
		if ECS:IsDeadEntity(other) == false then
			local other_collid = ECS:GetEntComp(other, "collid")
			local other_layer = other_collid.layer
			if other_layer == LAYER_MAP then -- map tiles
				local tile_type = other_collid.custom
				-- All other types of tiles we ignore collision: grass, ice, water
				if tile_type == TILE_BRICK then
					Small_Explosion(c.pos)
					PlaySound("brick_destroy")

					local maptile = ECS:GetEntComp(other_collid.ent, "maptile")
					local clearer = ECS:SpawnEntity({"maptile_clear"})
					local cmc = ECS:GetEntComp(clearer, "maptile_clear")
					cmc.collmap = maptile.collmap
					cmc.column = maptile.column
					cmc.row = maptile.row

					ECS:KillEntity(other)
					ECS:KillEntity(ent)
				elseif tile_type == TILE_STONE then
					Small_Explosion(c.pos)
					PlaySound("solid_impact")
					ECS:KillEntity(ent)
				end
			elseif other_layer == LAYER_BG then	-- map boundaries
				Small_Explosion(c.pos)
				if player_shell then
					PlaySound("solid_impact")
				end
				ECS:KillEntity(ent)
			elseif other_layer == LAYER_OBJECTS then
				if ECS:HasEntComp(other, "criticaltarget") then
					-- Insta-death
					local critdeath = ECS:SpawnEntity({"criticaldeath"})
					local cdc = ECS:GetEntComps(critdeath)
					cdc.criticaldeath.critical_target = other
					Small_Explosion(c.pos)
					ECS:KillEntity(ent)
				end
			elseif player_shell == true and other_layer == LAYER_PROJECTILES then -- player shell vs enemy shell
				-- Silently annihilate both
				ECS:KillEntity(other)
				ECS:KillEntity(ent)
			elseif player_shell == true and other_layer == LAYER_TANKS then
				-- enemy tank impact
				Small_Explosion(c.pos)
				PlaySound("big_explosion")
				local othercomps = ECS:GetEntComps(other)
				Big_Explosion({x=othercomps.pos.x + 8 * SCALE, y=othercomps.pos.y + 8 * SCALE})
				ECS:KillEntity(other)
				ECS:KillEntity(ent)
				-- TODO scoring
			elseif player_shell == false and other_layer == LAYER_PLAYER then
				Small_Explosion(c.pos)
				if ECS:HasEntComp(other, "player") then
					-- player tank impact
					PlaySound("big_explosion")
					local othercomps = ECS:GetEntComps(other)
					Big_Explosion({x=othercomps.pos.x + 8 * SCALE, y=othercomps.pos.y + 8 * SCALE})
					ECS:KillEntity(ent)
					ECS:KillEntity(other)
					-- Lose a live or gameover
					local playerdeath = ECS:SpawnEntity({"playerdeath"})
				else
					error("There shouldn't be another entity in player layer that is not player at the moment")
				end
			end
		end
	end
end
ECS:DefineUpdateSystem({"projectile", "pos", "dir", "collshape", "collid"}, USShellCollision)

-- Handles tank throttle preprocessing for direction and motion sensing to detect movement blockers
USTankThrottle = function(ent)
	local comps = ECS:GetEntComps(ent)
	local is_player = ECS:HasEntComp(ent, "player")
	local is_enemy = ECS:HasEntComp(ent, "enemycontrol")

	if is_player or is_enemy then
		if comps.tank.moving == 0 then
			-- Check for input throttle
			if is_player == true then
				comps.tank.throttle = (btn.up > 0 and comps.dir.dir == UP) or (btn.right > 0 and comps.dir.dir == RIGHT) or (btn.down > 0 and comps.dir.dir == DOWN) or (btn.left > 0 and comps.dir.dir == LEFT)
			else
				comps.tank.throttle = comps.enemycontrol.move_dir > 0 and comps.dir.dir == comps.enemycontrol.move_dir
			end

			if comps.tank.throttle then
				-- Check motion sensor for clear movement
				local sensor = comps.motionsensor4.sensors[comps.dir.dir]
				local sensor_comps = ECS:GetEntComps(sensor)
				if #sensor_comps.collid.events == 0 then
					comps.tank.moving = TANK_STEP
				end
			end
		end
	end
end
ECS:DefineUpdateSystem({"dir", "tank", "motionsensor4"}, USTankThrottle)

-- Updates tank sprite animation and applies actual throttle movement with stepping and rounding
USTankUpdate = function(ent)
	local comps = ECS:GetEntComps(ent)
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
ECS:DefineUpdateSystem({"tank", "animspr", "dir", "pos"}, USTankUpdate)

-- Kills entity if it leaves predefined out of bounds area 1000 pixels out of screen bounds
USOutOfBoundsKill = function(ent)
	local c = ECS:GetEntComps(ent)
	if c.pos.x > SC_WIDTH + 1000 or c.pos.x < -1000 or c.pos.y > SC_HEIGHT + 1000 or c.pos.y < -1000 then
		ECS:KillEntity(ent)
	end
end
ECS:DefineUpdateSystem({"outofbounds_kill", "pos"}, USOutOfBoundsKill)

USSpawnDirector = function(ent)
	local c = ECS:GetEntComps(ent)
	if c.spawndirector.active then
		local sd = c.spawndirector

		-- Update alive units tally
		local alive_count = 0
		local enemy_tanks = ECS:CollectEntitiesWith({"tank", "enemy"})
		for i=1,#enemy_tanks do
			if ECS:IsDeadEntity(enemy_tanks[i]) == false then
				alive_count = alive_count + 1
			end
		end

		-- Spawn timer
		if sd._timer > 0 then
			sd._timer = math.max(sd._timer - DeltaTime, 0)
		else
			if sd.spawns > 0 then
				if alive_count < sd.max_alive then
					local sensor_ent = sd.sensors[sd._current_zone]
					local sensor = ECS:GetEntComp(sensor_ent, "collid")
					if #sensor.events == 0 then
						-- no units in spawn zone -> we spawn
						sd.spawns = sd.spawns - 1
						sd._timer = sd.cooldown
						local zone = sd.zones[sd._current_zone]
						Spawn_EnemyTank(zone)
					end
					-- Regardless of overlap state, move to next zone.
					-- * if we spawned, its next zone time
					-- * if zone overlaps something, other zones maybe free
					sd._current_zone = sd._current_zone + 1
					if sd._current_zone > #sd.zones then
						sd._current_zone = 1
					end
				end
			else
				if alive_count == 0 then
					Msging.dispatchEntity(sd.msg_channel, sd.msg_on_finish)
					ECS:KillEntity(ent)
				end
			end
		end
	end
end
ECS:DefineUpdateSystem({"spawndirector"}, USSpawnDirector)

USPlayerSpawner = function(ent)
	local c = ECS:GetEntComps(ent)
	local ps = c.playerspawner

	for i=1,#ps.zones do
		local sensor_ent = ps.sensors[i]
		local sensor = ECS:GetEntComp(sensor_ent, "collid")
		if #sensor.events == 0 then
			-- no units in spawn zone -> we spawn
			Spawn_PlayerTank(ps.zones[i])
			ECS:KillEntity(ent)
			break
		end
	end
end
ECS:DefineUpdateSystem({"playerspawner"}, USPlayerSpawner)

USEnemyControl = function(ent)
	local c = ECS:GetEntComps(ent)
	-- movement
	if c.enemycontrol._move_timer <= 0.0 then
		-- time to change movement
		local r = love.math.random() -- [0, 1)
		local v = 0.0
		local d = 0	-- 0/UP/RIGHT/DOWN/LEFT
		for i=1,#c.enemycontrol.dir_percent do
			v = v + c.enemycontrol.dir_percent[i]
			if r <= v then
				break
			else
				d = math.min(4, d + 1)
			end
		end
		c.enemycontrol.move_dir = d
		c.enemycontrol._move_timer = love.math.random(c.enemycontrol.change_move[1], c.enemycontrol.change_move[2])
	end
	if c.tank.moving == 0 and c.enemycontrol.move_dir > 0 then
		c.dir.dir = c.enemycontrol.move_dir
	end
	c.enemycontrol._move_timer = math.max(c.enemycontrol._move_timer - DeltaTime, 0)

	-- fire shell
	local should_fire = love.math.random()
	if should_fire >= c.enemycontrol.fire_percent[1] and should_fire < c.enemycontrol.fire_percent[2] then
		c.tankturret.trigger = true
	end
end
ECS:DefineUpdateSystem({"enemycontrol", "tank", "tankturret", "dir"}, USEnemyControl)

USCollisionMap_TileClear = function(ent)
	local cmc = ECS:GetEntComp(ent, "maptile_clear")
	if ECS:IsAliveEntity(cmc.collmap) then
		local collmap = ECS:GetEntComp(cmc.collmap, "collmap")
		local ix = ((cmc.row - 1) * collmap.columns) + cmc.column
		collmap.matrix[ix] = 0
	end
	ECS:KillEntity(ent)
end
ECS:DefineUpdateSystem({"maptile_clear"}, USCollisionMap_TileClear)

USCriticalDeath = function(ent)
	-- Critical death procedure
	local c = ECS:GetEntComps(ent)
	if ECS:IsAliveEntity(c.criticaldeath.critical_target) then
		local cde = c.criticaldeath.critical_target
		local cdc = ECS:GetEntComps(cde)

		PlaySound("base_explosion")
		local explode = Big_Explosion({x=cdc.pos.x + 8 * SCALE, y=cdc.pos.y + 8 * SCALE})

		-- Critical target frame to destroyed
		cdc.animspr.curr_frame = 6
		-- Remove critical target collider
		ECS:EntRemComp(cde, "collid")
		ECS:EntRemComp(cde, "collshape")
		Trigger_GameOver()
	end
	ECS:KillEntity(ent)
end
ECS:DefineUpdateSystem({"criticaldeath"}, USCriticalDeath)

USGameOver = function(ent)
	local popup = ECS:SpawnEntity({"spr", "pos", "move4", "delayedfunc"})
	local pc = ECS:GetEntComps(popup)
	
	pc.spr.spritesheet = "small_gameover"
	pc.spr.scalex = SCALE
	pc.spr.scaley = SCALE
	pc.spr.layer = LAYER_UI

	pc.pos.x = (SC_WIDTH / 2) - (Res.GetSpriteWidth("small_gameover") * SCALE)
	pc.pos.y = SC_HEIGHT

	pc.move4.destx = pc.pos.x
	pc.move4.desty = (SC_HEIGHT / 2) - (Res.GetSpriteHeight("small_gameover") * SCALE)
	pc.move4.duration = 2

	pc.delayedfunc.delay = 4
	pc.delayedfunc.func = Construct_GameOver

	ECS:KillEntity(ent)
end
ECS:DefineUpdateSystem({"gameover"}, USGameOver)

USPlayerDeath = function(ent)
	local c = ECS:GetEntComps(ent)

	StopSound("tank_idle")
	StopSound("tank_moving")

	local session = MAIN:GetFirstEntityWith({"plrsession"})
	assert(session ~= nil and MAIN:IsAliveEntity(session))
	local sc = MAIN:GetEntComps(session)

	if sc.plrsession.lives > 0 then
		sc.plrsession.lives = sc.plrsession.lives - 1
		local spawner = ECS:SpawnEntity({"delayedfunc"})
		local dfunc = ECS:GetEntComp(spawner, "delayedfunc")
		dfunc.delay = c.playerdeath.cooldown
		dfunc.func = Construct_PlayerSpawner
	else
		Trigger_GameOver()
	end

	ECS:KillEntity(ent)
end
ECS:DefineUpdateSystem({"playerdeath"}, USPlayerDeath)