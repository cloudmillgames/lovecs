-- ** MAIN Update Systems **

-- Meant for MAIN ECS rather than game ECS

USPauser = function(ent)
    local c = MAIN:GetEntComps(ent)
    if c.pauser.pausable and btn.pause == 1 then
        if not c.pauser.paused then
            print("GAME PAUSE")
            -- Pause game by pausing TimeDelta
            GameTimePause = true
            PlaySound("game_pause")
            c.pauser.paused = true

            local bg_ent = MAIN:SpawnEntity({"screeneffect_door"}, "pauser_ents")
            local pc = MAIN:GetEntComps(bg_ent)
            pc.screeneffect_door.duration = 0.5
            pc.screeneffect_door.stay = -1
            pc.screeneffect_door.rect_color = {0, 0, 0, 0.5}
            pc.screeneffect_door.opening = false
            pc.screeneffect_door.layer = LAYER_SCREEN

            local text_ent = MAIN:SpawnEntity({"bmptext", "pos"}, "pauser_ents")
            local tc = MAIN:GetEntComps(text_ent)
            tc.pos.x = MAP_TO_COORD_X(11)
            tc.pos.y = MAP_TO_COORD_Y(7)
            tc.bmptext.text = "PAUSED"
            tc.bmptext.color = ORANGE
            tc.bmptext.layer = LAYER_SCREEN + 1
        else
            print("GAME RESUME")
            local ents = MAIN:GetTaggedEnts("pauser_ents")
            assert(ents)
            for i in ipairs(ents) do
                MAIN:KillEntity(ents[i])
            end
            GameTimePause = false
            PlaySound("game_pause")
            c.pauser.paused = false
        end
    end
end
MAIN:DefineUpdateSystem({"pauser"}, USPauser)

-- Fullscreen door transition effect, this is MAIN version with some differences
USScreenEffect_Door = function(ent)
	local secd = MAIN:GetEntComp(ent, "screeneffect_door")
	if secd._timer_duration < secd.duration then
		secd._timer_duration = math.min(secd._timer_duration + MainDeltaTime, secd.duration)
	elseif secd.stay > 0 and secd._timer_stay < secd.stay then
		secd._timer_stay = math.min(secd._timer_stay + MainDeltaTime, secd.stay)
		if secd._timer_stay >= secd.stay then
			MAIN:KillEntity(ent)
		end
	end
end
MAIN:DefineUpdateSystem({"screeneffect_door"}, USScreenEffect_Door)