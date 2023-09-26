-- ** Effects Update Systems **

-- Fullscreen door transition effect
USScreenEffect_Door = function(ent)
	local secd = GetEntComp(ent, "screeneffect_door")
	if secd._timer_duration < secd.duration then
		secd._timer_duration = math.min(secd._timer_duration + DeltaTime, secd.duration)
	elseif secd._timer_stay < secd.stay then
		secd._timer_stay = math.min(secd._timer_stay + DeltaTime, secd.stay)
		if secd._timer_stay >= secd.stay then
			KillEntity(ent)
		end
	end
end
DefineUpdateSystem({"screeneffect_door"}, USScreenEffect_Door)