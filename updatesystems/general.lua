-- ** General Update Systems **
local easing = require 'easing'

-- Link entity's lifetime to a parent, it dies if parent dies
USChild = function(ent)
	local c = ECS:GetEntComp(ent, "child")
	if c.parent > 0 and ECS:IsDeadEntity(c.parent) then
		ECS:KillEntity(ent)
	end
end
ECS:DefineUpdateSystem({"child"}, USChild)

-- Dispatches message when monitored entity dies, kills self after
USKillMsg = function(ent)
	local c = ECS:GetEntComps(ent)
	if ECS:IsDeadEntity(c.killmsg.entity) then
		Msging.dispatchEntity(c.killmsg.channel, c.killmsg.msg)
		ECS:KillEntity(ent)
	end
end
ECS:DefineUpdateSystem({"killmsg"}, USKillMsg)

-- Call function when entity dies, self kill after
USKillFunc = function(ent)
	local c = ECS:GetEntComps(ent)
	if ECS:IsDeadEntity(c.killfunc.entity) then
		callFunc(c.killfunc.funcbind)
		ECS:KillEntity(ent)
	end
end
ECS:DefineUpdateSystem({"killfunc"}, USKillFunc)

-- Entity position linked to a parent position with an offset
USPosLink = function(ent)
	local comps = ECS:GetEntComps(ent)
	if ECS:IsDeadEntity(comps.poslink.parent) == false then
		local parent_pos = ECS:GetEntComp(comps.poslink.parent, "pos")
		comps.pos.x = parent_pos.x + comps.poslink.offsetx
		comps.pos.y = parent_pos.y + comps.poslink.offsety
	end
end
ECS:DefineUpdateSystem({"poslink", "pos"}, USPosLink)

-- 2D Linear movement of position from origin to destination in duration
USMove4 = function(ent)
	local c = ECS:GetEntComps(ent)
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
ECS:DefineUpdateSystem({"move4", "pos"}, USMove4)

-- Dispatches given message on set button press (1) and kills self entity once message dispatched
USMsgOnButton = function(ent)
	local c = ECS:GetEntComps(ent)
	if btn[c.msg_on_button.btn_name] == 1 then
		Msging.dispatch(c.msg_dispatcher, c.msg_on_button.channel, c.msg_on_button.msg)
		c.msg_dispatcher.kill_after_dispatch = true
	end
end
ECS:DefineUpdateSystem({"msg_on_button", "msg_dispatcher"}, USMsgOnButton)

-- Plays animated sprite once then kills self entity
USAnimSpr_OneCycle = function(ent)
	local c = ECS:GetEntComps(ent)
	c.animspr_onecycle._timer = c.animspr_onecycle._timer + DeltaTime
	if c.animspr_onecycle._timer >= c.animspr_onecycle.frametime then
		c.animspr_onecycle._timer = c.animspr_onecycle._timer - c.animspr_onecycle.frametime
		if c.animspr.curr_frame >= Res.GetSpriteFramecount(c.animspr.spritesheet) then
			ECS:KillEntity(ent)
		else
			c.animspr.curr_frame = c.animspr.curr_frame + 1
		end
	end
end
ECS:DefineUpdateSystem({"animspr", "animspr_onecycle"}, USAnimSpr_OneCycle)

-- animate sprite pingpong number of cycles then dispatch msg and kill self
USAnimSpr_PingPong = function(ent)
	local c = ECS:GetEntComps(ent)
	c.animspr_pingpong._timer = c.animspr_pingpong._timer + DeltaTime
	if c.animspr_pingpong._timer >= c.animspr_pingpong.frametime then
		c.animspr_pingpong._timer = c.animspr_pingpong._timer - c.animspr_pingpong.frametime
		if c.animspr_pingpong._direction == 1 and c.animspr.curr_frame >= Res.GetSpriteFramecount(c.animspr.spritesheet) then
			c.animspr_pingpong._direction = -1
		elseif c.animspr_pingpong._direction == -1 and c.animspr.curr_frame <= 1 then
			c.animspr_pingpong._direction = 1
			if c.animspr_pingpong.cycles > 0 then
				c.animspr_pingpong.cycles = c.animspr_pingpong.cycles - 1
			end
		end
		c.animspr.curr_frame = c.animspr.curr_frame + c.animspr_pingpong._direction
	end

	if c.animspr_pingpong.cycles == 0 then
		ECS:KillEntity(ent)
	end
end
ECS:DefineUpdateSystem({"animspr", "animspr_pingpong"}, USAnimSpr_PingPong)

-- Cycles all sprite frames, counts in frames so not useful for actual game but maybe debugging and UI
USAnimSpr_Cycle = function(ent)
	local c = ECS:GetEntComps(ent)
	c.animspr_cycle._timer = c.animspr_cycle._timer + DeltaTime
	if c.animspr_cycle._timer >= c.animspr_cycle.frametime then
		c.animspr_cycle._timer = c.animspr_cycle._timer - c.animspr_cycle.frametime
		if c.animspr.curr_frame >= Res.GetSpriteFramecount(c.animspr.spritesheet) then
			c.animspr.curr_frame = 1
		else
			c.animspr.curr_frame = c.animspr.curr_frame + 1
		end
	end
end
ECS:DefineUpdateSystem({"animspr", "animspr_cycle"}, USAnimSpr_Cycle)

-- Calls a function after the specified delay, kills self when function is called
USDelayedFunc = function(ent)
	local df = ECS:GetEntComp(ent, "delayedfunc")
	df.delay = df.delay - DeltaTime
	if df.delay <= 0 then
		df.func(ent)
		ECS:KillEntity(ent)
	end
end
ECS:DefineUpdateSystem({"delayedfunc"}, USDelayedFunc)

USDelayedKill = function(ent)
	local c = ECS:GetEntComp(ent, "delayedkill")
	c.delay = c.delay - DeltaTime
	if c.delay <= 0 then
		ECS:KillEntity(ent)
	end
end
ECS:DefineUpdateSystem({"delayedkill"}, USDelayedKill)

-- Calls given function when button is pressed (==1), auto kills if kill_after > 0
USButtonFunc = function(ent)
	local c = ECS:GetEntComps(ent)
	if btn[c.buttonfunc.btn_name] == 1 then
		c.buttonfunc.func(ent)
		if c.buttonfunc.kill_after > 0 then
			c.buttonfunc.kill_after = c.buttonfunc.kill_after - 1
			if c.buttonfunc.kill_after == 0 then
				ECS:KillEntity(ent)
			end
		end
	end
end
ECS:DefineUpdateSystem({"buttonfunc"}, USButtonFunc)

USTimedown = function(ent)
	local t = ECS:GetEntComp(ent, "timedown")
	if t.time > 0 then
		t.time = math.max(t.time - DeltaTime, 0.0)
	end
end
ECS:DefineUpdateSystem({"timedown"}, USTimedown)

-- System to update UI enemy tank icons on the right by deleting entities based on keep value
-- If keep value is 0, deletes all entities and self
USEntArrKeep = function(ent)
	local c = ECS:GetEntComp(ent, "entarrkeep")
	if c.keep < #c.ent_array then
		local new_arr = {}
		local counter = 0
		for i=1,#c.ent_array do
			counter = counter + 1
			if counter <= c.keep then
				add(new_arr, c.ent_array[i])
			else
				if ECS:IsAliveEntity(c.ent_array[i]) then
					ECS:KillEntity(c.ent_array[i])
				end
			end
		end
		c.ent_array = new_arr
	end
	if #c.ent_array == 0 then
		ECS:KillEntity(ent)
	end
end
ECS:DefineUpdateSystem({"entarrkeep"}, USEntArrKeep)

-- Operates map clock used to animate water
USMapClock = function(ent)
	local c = ECS:GetEntComps(ent)
	if c.mapclock._timer > 0 then
		c.mapclock._timer = math.max(c.mapclock._timer - DeltaTime, 0)
	else
		c.mapclock.clock = 1 - c.mapclock.clock
		c.mapclock._timer = c.mapclock.period
	end
end
ECS:DefineUpdateSystem({"mapclock"}, USMapClock)

--------------------------------------------------------------------------------------------
------------------------------------- DEPRECTAED (Implemented but no longer used)
--------------------------------------------------------------------------------------------
USMove4Skipper = function(ent)
	local c = ECS:GetEntComps(ent)
	if c.move4.finished == false then
		if type(c.move4_skipper.skip_on) == "string" and Msging.received_msg(c.msg_receiver, c.move4_skipper.skip_on) then
			c.move4._timer = c.move4.duration
		end
	end
end
ECS:DefineUpdateSystem({"move4_skipper", "msg_receiver", "move4"}, USMove4Skipper)

USDelayedFuncSkipper = function(ent)
	local c = ECS:GetEntComps(ent)
	if c.delayedfunc.delay > 0 then
		if type(c.delayedfunc_skipper.skip_on) == "string" and Msging.received_msg(c.msg_receiver, c.delayedfunc_skipper.skip_on) then
			c.delayedfunc.delay = 0
		end
	end
end
ECS:DefineUpdateSystem({"delayedfunc_skipper", "msg_receiver", "delayedfunc"}, USDelayedFuncSkipper)