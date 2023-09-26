-- ** Utility Update Systems **

-- Counts frames per second and updates text component to show fps
USFPSCounter = function(ent)
	local comps = GetEntComps(ent)
	comps.fpscounter.frame_count = comps.fpscounter.frame_count + 1
	comps.fpscounter.frame_timer = comps.fpscounter.frame_timer + DeltaTime
	if comps.fpscounter.frame_timer >= 1.0 then
		comps.text.text = tostring(comps.fpscounter.frame_count)
		comps.fpscounter.frame_count = 0
		comps.fpscounter.frame_timer = comps.fpscounter.frame_timer - 1.0
	end
end
DefineUpdateSystem({"fpscounter", "text"}, USFPSCounter)

-- Show collisions debug traces
USCollisionDebug = function(ent)
	if Collision.DEBUG then
		local c = GetEntComps(ent)
		for i=1,#c.collid.events do
			local other = c.collid.events[i][1] == ent and 2 or 1
			other = c.collid.events[i][other]
			if not IsDeadEntity(other) and HasEntComp(ent, "dbgname") and HasEntComp(other, "dbgname") then
				local cc = GetEntComps(other)
				print("COLLISION between "..c.dbgname.name.." and "..cc.dbgname.name)
			end
		end
	end
end
DefineUpdateSystem({"dbgname", "collshape", "collid", "pos"}, USCollisionDebug)