-- ** Utility Update Systems **

-- Counts frames per second and updates text component to show fps
USFPSCounter = function(ent)
	local comps = ECS:GetEntComps(ent)
	comps.fpscounter.frame_count = comps.fpscounter.frame_count + 1
	comps.fpscounter.frame_timer = comps.fpscounter.frame_timer + DeltaTime
	if comps.fpscounter.frame_timer >= 1.0 then
		comps.text.text = tostring(comps.fpscounter.frame_count)
		comps.fpscounter.frame_count = 0
		comps.fpscounter.frame_timer = comps.fpscounter.frame_timer - 1.0
	end
end
ECS:DefineUpdateSystem({"fpscounter", "text"}, USFPSCounter)

-- Show collisions debug traces
USCollisionDebug = function(ent)
	if Collision.DEBUG then
		local c = ECS:GetEntComps(ent)
		for i=1,#c.collid.events do
			local other = c.collid.events[i][1] == ent and 2 or 1
			other = c.collid.events[i][other]
			if not ECS:IsDeadEntity(other) and ECS:HasEntComp(ent, "dbgname") and ECS:HasEntComp(other, "dbgname") then
				local cc = ECS:GetEntComps(other)
				print("COLLISION between "..c.dbgname.name.." and "..cc.dbgname.name)
			end
		end
	end
end
ECS:DefineUpdateSystem({"dbgname", "collshape", "collid", "pos"}, USCollisionDebug)

-- Links a data property from an entity/component to a data property in current entity
-- Doesn't do anything if source entity is dead or src/dest component doesn't exist
-- If datalink source is a non-existing property, will throw an error (does not support nil)
-- Conversion supports string and number, any other type name is directly assigned (ie table, bool)
USDataLinker = function(ent)
	local l = ECS:GetEntComp(ent, "datalink")
	local SRCECS = _G[l.src_ecs]
	if SRCECS:IsAliveEntity(l.src_ent) then
		-- If lua throws attempt to index nil value here, check SRCECS to make sure its the right one
		if SRCECS:HasEntComp(l.src_ent, l.src_comp) and ECS:HasEntComp(ent, l.dest_comp) then
			local src_comp = SRCECS:GetEntComp(l.src_ent, l.src_comp)
			assert(src_comp[l.src_prop] ~= nil, "DataLink source property is nil which is not supported, property name: "..tostring(l.src_prop))
			local dest_comp = ECS:GetEntComp(ent, l.dest_comp)
			if l.dest_type == "string" then
				dest_comp[l.dest_prop] = tostring(src_comp[l.src_prop])
			elseif l.dest_type == "number" then
				dest_comp[l.dest_prop] = tonumber(src_comp[l.src_prop])
			else
				dest_comp[l.dest_prop] = src_comp[l.src_prop]
			end
		end
	end
end
ECS:DefineUpdateSystem({"datalink"}, USDataLinker)
