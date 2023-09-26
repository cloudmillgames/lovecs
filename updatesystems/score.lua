-- ** Score Update Systems **

-- Score screen after gameover or level complete
USInitScore = function(ent)
	love.graphics.setBackgroundColor(BLACK)

    local spawn_bmptext = function(x, y, text, color)
        local e = ECS:SpawnEntity({"pos", "bmptext"})
        local c = ECS:GetEntComps(e)
        c.pos.x = x
        c.pos.y = y
        c.bmptext.text = text
        c.bmptext.color = color
        return e
    end

    local plrsession_ent = MAIN:GetTaggedEnt("plrsession")
    local plrsession = MAIN:GetEntComp(plrsession_ent, "plrsession")

    -- HI-SCORE text
    spawn_bmptext( MAP_TO_COORD_X(10),  MAP_TO_COORD_X(2), "HI-SCORE", RED)
    -- STAGE text
    local stage = spawn_bmptext(MAP_TO_COORD_X(12), MAP_TO_COORD_X(3), "STAGE "..tostring(plrsession.stage), WHITE)
    -- TODO HI-SCORE value
    local hiscore = spawn_bmptext( MAP_TO_COORD_X(16),  MAP_TO_COORD_X(2), "20000", ORANGE)
    -- I-PLAYER
    spawn_bmptext(MAP_TO_COORD_X(8), MAP_TO_COORD_Y(4), "I-PLAYER", RED)
    -- Player 1 score
    local score = spawn_bmptext(MAP_TO_COORD_X(8), MAP_TO_COORD_Y(5), spaceText(tostring(plrsession.score), 8), ORANGE)

    for i=1,4 do
        local yy = MAP_TO_COORD_Y(5) + (i * 24 * SCALE)
        -- points
        spawn_bmptext(MAP_TO_COORD_X(7), yy, "   0", WHITE)
        -- PTS
        spawn_bmptext(MAP_TO_COORD_X(10), yy, "PTS", WHITE)
        -- count
        spawn_bmptext(MAP_TO_COORD_X(13), yy, " 0"..string.char(186), WHITE)

        local te = ECS:SpawnEntity({"spr", "pos"})
        local tec = ECS:GetEntComps(te)
        tec.spr.spritesheet = "tanks"
        tec.spr.spriteid = ((i + 3) * 8) + 1
        tec.spr.scalex = SCALE
        tec.spr.scaley = SCALE
        tec.pos.x = MAP_TO_COORD_X(14) + 8 * SCALE
        tec.pos.y = yy - 4 * SCALE
    end

    -- Rect
    local hr = ECS:SpawnEntity({"gfxrect"})
    local hrc = ECS:GetEntComps(hr)
    hrc.gfxrect.rect = makeRect(MAP_TO_COORD_X(13), MAP_TO_COORD_Y(12) + 4 * SCALE, 5 * SC_TILE_WIDTH, 2 * SCALE)
    hrc.gfxrect.color = WHITE

    -- TOTAL
    spawn_bmptext(MAP_TO_COORD_X(8), MAP_TO_COORD_Y(12) + 12 * SCALE, "TOTAL", WHITE)
    spawn_bmptext(MAP_TO_COORD_X(13), MAP_TO_COORD_Y(12) + 12 * SCALE, " 0", WHITE)

    ECS:KillEntity(ent)

end
ECS:DefineUpdateSystem({"initscore"}, USInitScore)

-- Player gained score (during gameplay)
USScoreGained = function(ent)
    local c = ECS:GetEntComps(ent)
    local plrsession_ent = MAIN:GetTaggedEnt("plrsession")
    assert(MAIN:IsAliveEntity(plrsession_ent), "At this point plrsession must be defined, but appears not to be?")
    local plrsession = MAIN:GetEntComp(plrsession_ent, "plrsession")
    print("SCOREGAIN SCORE = "..tostring(c.scoregain.score))
    -- Add score and optionally tank_type to player session
    plrsession.score = plrsession.score + c.scoregain.score
    if c.scoregain.tank_type > 0 then
        if plrsession.kills[c.scoregain.tank_type] == nil then
            plrsession.kills[c.scoregain.tank_type] = 1
        else
            plrsession.kills[c.scoregain.tank_type] = plrsession.kills[c.scoregain.tank_type] + 1
        end
    end

    -- Spawn score sprite
    if c.scoregain.score >= 100 and c.scoregain.score <= 500 and math.fmod(c.scoregain.score, 100) == 0 then
        local idx = math.floor(c.scoregain.score / 100)
        local score_ent = ECS:SpawnEntity({"spr", "pos", "delayedkill"})
        local sc = ECS:GetEntComps(score_ent)

        sc.pos.x = c.pos.x
        sc.pos.y = c.pos.y

        sc.spr.spritesheet = "score_popups"
        sc.spr.spriteid = idx
        sc.spr.scalex = SCALE
        sc.spr.scaley = SCALE
        sc.spr.layer = LAYER_UI

        sc.delayedkill.delay = 1.5
    end
    ECS:KillEntity(ent)
end
ECS:DefineUpdateSystem({"scoregain", "pos"}, USScoreGained)
