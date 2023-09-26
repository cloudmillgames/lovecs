-- ** General Update Systems **
local easing = require 'easing'

-- Entity position linked to a parent position with an offset
USPosLink = function(ent)
	local comps = GetEntComps(ent)
	local parent_pos = GetEntComp(comps.poslink.parent, "pos")
	comps.pos.x = parent_pos.x + comps.poslink.offsetx
	comps.pos.y = parent_pos.y + comps.poslink.offsety
end
DefineUpdateSystem({"poslink", "pos"}, USPosLink)

-- 2D Linear movement of position from origin to destination in duration
USMove4 = function(ent)
	local c = GetEntComps(ent)
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
DefineUpdateSystem({"move4", "pos"}, USMove4)

-- Dispatches given message on set button press (1) and kills self entity once message dispatched
USMsgOnButton = function(ent)
	local c = GetEntComps(ent)
	if btn[c.msg_on_button.btn_name] == 1 then
		Msging.dispatch(c.msg_dispatcher, c.msg_on_button.channel, c.msg_on_button.msg)
		c.msg_dispatcher.kill_after_dispatch = true
	end
end
DefineUpdateSystem({"msg_on_button", "msg_dispatcher"}, USMsgOnButton)

-- Cycles all sprite frames, counts in frames so not useful for actual game but maybe debugging and UI
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

-- Calls a function after the specified delay, kills self when function is called
USDelayedFunc = function(ent)
	local df = GetEntComp(ent, "delayedfunc")
	df.delay = df.delay - DeltaTime
	if df.delay <= 0 then
		df.func(ent)
		KillEntity(ent)
	end
end
DefineUpdateSystem({"delayedfunc"}, USDelayedFunc)

-- Calls given function when button is pressed (==1), auto kills if kill_after > 0
USButtonFunc = function(ent)
	local c = GetEntComps(ent)
	if btn[c.buttonfunc.btn_name] == 1 then
		c.buttonfunc.func(ent)
		if c.buttonfunc.kill_after > 0 then
			c.buttonfunc.kill_after = c.buttonfunc.kill_after - 1
			if c.buttonfunc.kill_after == 0 then
				KillEntity(ent)
			end
		end
	end
end
DefineUpdateSystem({"buttonfunc"}, USButtonFunc)

USTimedown = function(ent)
	local t = GetEntComp(ent, "timedown")
	if t.time > 0 then
		t.time = math.max(t.time - DeltaTime, 0.0)
	end
end
DefineUpdateSystem({"timedown"}, USTimedown)

--------------------------------------------------------------------------------------------
------------------------------------- DEPRECTAED (Implemented but no longer used)
--------------------------------------------------------------------------------------------
USMove4Skipper = function(ent)
	local c = GetEntComps(ent)
	if c.move4.finished == false then
		if type(c.move4_skipper.skip_on) == "string" and Msging.received_msg(c.msg_receiver, c.move4_skipper.skip_on) then
			c.move4._timer = c.move4.duration
		end
	end
end
DefineUpdateSystem({"move4_skipper", "msg_receiver", "move4"}, USMove4Skipper)

USDelayedFuncSkipper = function(ent)
	local c = GetEntComps(ent)
	if c.delayedfunc.delay > 0 then
		if type(c.delayedfunc_skipper.skip_on) == "string" and Msging.received_msg(c.msg_receiver, c.delayedfunc_skipper.skip_on) then
			c.delayedfunc.delay = 0
		end
	end
end
DefineUpdateSystem({"delayedfunc_skipper", "msg_receiver", "delayedfunc"}, USDelayedFuncSkipper)