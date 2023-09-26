-- ** Score Update Systems **

USInitScore = function(ent)
	love.graphics.setBackgroundColor(BLACK)

    local spawn_bmptext = function(x, y, text, color)
        local e = ECS:SpawnEntity({"pos", "bmptext"})
        local c = ECS:GetEntComps(e)
        c.pos.x = x
        c.pos.y = y
        c.bmptext.text = text
        c.bmptext.color = color
    end

    -- HI-SCORE text
    spawn_bmptext( MAP_TO_COORD_X(10),  MAP_TO_COORD_X(2), "HI-SCORE", RED)
    -- TODO HI-SCORE value
    spawn_bmptext( MAP_TO_COORD_X(16),  MAP_TO_COORD_X(2), "20000", ORANGE)
    -- I-PLAYER
    spawn_bmptext(MAP_TO_COORD_X(7), MAP_TO_COORD_Y(4), "I-PLAYER", RED)
    -- TODO Player 1 score
    spawn_bmptext(MAP_TO_COORD_X(9), MAP_TO_COORD_Y(5), "2900", ORANGE)

    for i=1,4 do
        -- PTS
        spawn_bmptext(MAP_TO_COORD_X(10), MAP_TO_COORD_Y(5) + (i * 24 * SCALE), "PTS", WHITE)
    end

    -- TOTAL
    spawn_bmptext(MAP_TO_COORD_X(8), MAP_TO_COORD_Y(12) + 12 * SCALE, "TOTAL", WHITE)

    ECS:KillEntity(ent)

end
ECS:DefineUpdateSystem({"initscore"}, USInitScore)