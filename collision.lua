-- ** Collision ECS **
--
-- Defined components:
-- 1. Collision.Shape "collshape": shape of collider, point/rect/circle
-- 2. Collision.ID "collid": ref for entity, layer, and collision events list
--
-- Required components:
-- 1. "pos" component: 2D position with {x=N, y=N} structure
--
-- Collision._thresholdPointPoint: how close two points are to collide (default=1.0)
--
-- Collision.run(): using ECS runs collision detection on all entities with collshape + collid + position

Collision = {}

Collision._thresholdPointPoint = 1.0
Collision._debugColor = {1, 0, 0, 0.35}
Collision._debugSensorColor = {0, 0, 1, 0.35}
Collision.DEBUG = true

-- Point = {x=N, y=N}
function Collision.pointPoint(p1, p2)
        return abs(p1.x - p2.x) < Collision._thresholdPointPoint and abs(p1.y - p2.y) < Collision._thresholdPointPoint
end

-- Point = {x=N, y=N}, Rect = {x=N, y=N, w=N, h=N}
function Collision.pointRect(p, r)
    return not(p.x <= r.x or p.x >= r.x + r.w or p.y <= r.y or p.y >= r.y + r.h)
end
function Collision.rectPoint(r, p)
    return Collision.pointRect(p, r)
end

-- Point = {x=N, y=N}, Circle = {x=N, y=N, r=N}
function Collision.pointCircle(p, c)
	return pointDistSqrd(p, c) < c.r * c.r
end
function Collision.circlePoint(c, p)
    return Collision.pointCircle(p, c)
end

-- Rect = {x=N, y=N, w=N, h=N}
function Collision.rectRect(r1, r2)
    return not(r1.x + r1.w <= r2.x or r1.x >= r2.x + r2.w or r1.y + r1.h <= r2.y or r1.y >= r2.y + r2.h)
end

-- Rect = {x=N, y=N, w=N, h=N}, Circle = {x=N, y=N, r=N}
function Collision.rectCircle(r, c)
    -- Find the closest point to the circle within the rectangle
    local closestx = clamp(c.x, r.x, r.x + r.w)
    local closesty = clamp(c.y, r.y, r.y + r.h)

    -- Calculate the distance between the circle's center and this closest point
    local distx = c.x - closestx
    local disty = c.y - closesty

    -- If the distance is less than the circle's radius, an intersection occurs
    local distsqrd = (distx * distx) + (disty * disty)
    return distsqrd < (c.r * c.r)
end
function Collision.circleRect(c, r)
    return Collision.rectCircle(r, c)
end

-- Circle = {x=N, y=N, r=N}
function Collision.circleCircle(c1, c2)
    local dist = pointDist(c1, c2)
    return dist < c1.r + c2.r
end

-- Collision shape components
SHAPE_POINT = 1
SHAPE_RECT = 2
SHAPE_CIRCLE = 3

Collision.Shape = {
    type = SHAPE_POINT,
    x = 0, y = 0, w = 1, h = 1
}
ECS:DefineComponent("collshape", Collision.Shape)

Collision.ID = {
    ent = 0,        -- reference to self entity
    dynamic = true, -- static vs dynamic shapes, static doesn't get events
    layer = 0,      -- collision only calculated between different layers
    events = {},    -- events queue for current frame

    sensor = false, -- sensing collid, other non-sensor collid doesn't get event
                    -- an object both static and sensor is invalid
                    -- sensor doesn't sense sensors, only non-sensor colliders
    owner = -1,     -- ent owns this collid, used so sensor ignores owning ent
                    -- no need to set this if collid is not a sensor
    sense_own_layer = false,-- sensor senses its own layer collids as well

    custom = nil    -- custom data that can be set to anything
}
ECS:DefineComponent("collid", Collision.ID)

Collision.Map = {
    matrix = {},    -- 2D matrix of map tiles, 0 means no tile there
    ent_matrix = {},-- 2D matrix of map tile entities, nil for no-tile there
    tile_size = {8, 8}, -- SCALED size
    columns = 16,   -- how many columns?
    rows = 16,      -- how many rows?
    map_rect = {}   -- {x=, y=, w=, h=} SCALED
}
ECS:DefineComponent("collmap", Collision.Map)

-- Collision system checks/events
-- p1, p2: positions ("pos")
-- s1, s2: collision shape ("collshape")
Collision.check_pointPoint = function(p1, p2, s1, s2)
    return Collision.pointPoint(p1, p2)
end
Collision.check_pointRect = function(p1, p2, s1, s2)
    local r2 = {x=p2.x + s2.x, y=p2.y + s2.y, w=s2.w, h=s2.h}
    return Collision.pointRect(p1, r2)
end
Collision.check_pointCircle = function(p1, p2, s1, s2)
    local c2 = {x = p2.x + s2.x, y = p2.y + s2.y, r = s2.w}
    return Collision.pointCircle(p1, c2)
end
Collision.check_rectPoint = function(p1, p2, s1, s2)
    local r1 = {x=p1.x + s1.x, y=p1.y + s1.y, w=s1.w, h=s1.h}
    return Collision.rectPoint(r1, p2)
end
Collision.check_rectRect = function(p1, p2, s1, s2)
    local r1 = {x=p1.x + s1.x, y=p1.y + s1.y, w=s1.w, h=s1.h}
    local r2 = {x=p2.x + s2.x, y=p2.y + s2.y, w=s2.w, h=s2.h}
    return Collision.rectRect(r1, r2)
end
Collision.check_rectCircle = function(p1, p2, s1, s2)
    local r1 = {x=p1.x + s1.x, y=p1.y + s1.y, w=s1.w, h=s1.h}
    local c2 = {x = p2.x + s2.x, y = p2.y + s2.y, r = s2.w}
    return Collision.rectCircle(r1, c2)
end
Collision.check_circlePoint = function(p1, p2, s1, s2)
    local c1 = {x = p1.x + s1.x, y = p1.y + s1.y, r = s1.w}
    return Collision.circlePoint(c1, p2)
end
Collision.check_circleRect = function(p1, p2, s1, s2)
    local c1 = {x = p1.x + s1.x, y = p1.y + s1.y, r = s1.w}
    local r2 = {x=p2.x + s2.x, y=p2.y + s2.y, w=s2.w, h=s2.h}
    return Collision.circleRect(c1, r2)
end
Collision.check_circleCircle = function(p1, p2, s1, s2)
    local c1 = {x = p1.x + s1.x, y = p1.y + s1.y, r = s1.w}
    local c2 = {x = p2.x + s2.x, y = p2.y + s2.y, r = s2.w}
    return Collision.circleCircle(c1, c2)
end

-- Collision shape to function adapter
Collision.collideShape = {
    {       -- Point
        Collision.check_pointPoint,
        Collision.check_pointRect,
        Collision.check_pointCircle
    }, {    -- Rect
        Collision.check_rectPoint,
        Collision.check_rectRect,
        Collision.check_rectCircle
    }, {    -- Circle
        Collision.check_circlePoint,
        Collision.check_circleRect,
        Collision.check_circleCircle
    }
}

-- Expensive call, once per frame
Collision.run = function()
    local ents = ECS:CollectEntitiesWith({"pos", "collid", "collshape"})
    local e1 = 0
    local e2 = 0
    local e1c = nil
    local e2c = nil
    local col = false

    -- Clear prev events
    for i=1,#ents do
        local c = ECS:GetEntComps(ents[i])
        c.collid.events = {}
    end

    -- Collision detection between map colliders and geometric colliders
    local collmap_ents = ECS:CollectEntitiesWith({"collmap"})
    local collmap = nil
    local idx = -1
    local number_to_map = function(n, tw)
        return math.floor(n / tw) + 1
    end

    local point_to_map_coords = function(x, y, tw, th)
        return math.floor(x / tw) + 1, math.floor(y / th) + 1
    end

    -- checks a tile for collision and returns maptile entity there
    local check_tile_collision = function(cm, column, row)
        local ix = ((row - 1) * cm.columns) + column
        if cm.matrix[ix] > 0 then
            assert(cm.ent_matrix[ix] ~= nil, "maptile entity not defined at: "..tostring(row)..", "..tostring(column).." ["..tostring(ix).."]")
            return cm.ent_matrix[ix]
        end
        return 0
    end

    -- If collision, returns map tile entity (>0), if not returns 0
    local point_collides_map = function(cm, x, y, tw, th)
        local column, row = point_to_map_coords(x, y, tw, th)
        if column > 0 and column <= cm.columns and row > 0 and row <= cm.rows then
            return check_tile_collision(cm, column, row)
        end
        return 0
    end

    -- Ideally, there should be one map collider only
    for _,cment in pairs(collmap_ents) do
        collmap = ECS:GetEntComp(cment, "collmap")
        for i=1,#ents do
            e1 = ents[i]
            e1c = ECS:GetEntComps(e1)
            e2 = 0

            if e1c.collid.dynamic == true then
                if e1c.collshape.type == SHAPE_POINT then
                    -- point to maptile collision
                    e2 = point_collides_map(collmap, e1c.collshape.x - collmap.map_rect.x, e1c.collshape.y - collmap.map_rect.y, collmap.tile_.tile_size[1], collmap.tile_size[2])
                    add(e1c.collid.events, {e2, e1})
                elseif e1c.collshape.type == SHAPE_RECT then
                    -- scan all vert/horiz maptiles that intersect rect
                    local x1 = number_to_map(e1c.pos.x + e1c.collshape.x - collmap.map_rect.x + 1, collmap.tile_size[1])
                    local x2 = number_to_map(e1c.pos.x + e1c.collshape.x - collmap.map_rect.x + e1c.collshape.w - 1, collmap.tile_size[1])
                    local y1 = number_to_map(e1c.pos.y + e1c.collshape.y - collmap.map_rect.y + 1, collmap.tile_size[2])
                    local y2 = number_to_map(e1c.pos.y + e1c.collshape.y - collmap.map_rect.y + e1c.collshape.h - 1, collmap.tile_size[2])
                    e2 = 0
                    for y=y1,y2 do
                        for x=x1,x2 do
                            if is_between(x, 1, collmap.columns) and is_between(y, 1, collmap.rows) then
                                e2 = check_tile_collision(collmap, x, y)
                                if e2 > 0 then
                                    add(e1c.collid.events, {e2, e1})
                                    e2 = 0
                                end
                            end
                        end
                    end
                elseif e1c.collshape.type == SHAPE_CIRCLE then
                    error("Map collider against circles is unimplemented")
                end
            end
        end
    end

    -- Run collision detection between geometric colliders
    for i=1,#ents-1 do
        for j=i+1,#ents do
            e1 = ents[i]
            e2 = ents[j]
            e1c = ECS:GetEntComps(e1)
            e2c = ECS:GetEntComps(e2)

            if e1c.collid.sensor == true or e2c.collid.sensor == true then
                -- sensors don't care about dynamic static state
                -- two sensor colliders won't produce any events
                if e1c.collid.sensor ~= e2c.collid.sensor then
                    local sensor
                    local other
                    if e1c.collid.sensor then
                        sensor = e1c.collid
                        other = e2
                    else
                        sensor = e2c.collid
                        other = e1
                    end
                    -- sensor ignores its own entity
                    if sensor.owner ~= other then
                        -- Sensors sense against other layers
                        -- But can sense own layer in which case they sense against all layers
                        if e1c.collid.layer ~= e2c.collid.layer or sensor.sense_own_layer then
                            col = Collision.collideShape[e1c.collshape.type][e2c.collshape.type](e1c.pos, e2c.pos, e1c.collshape, e2c.collshape)
                            if col then
                                local ev = {e1, e2}
                                if e1c.collid.sensor == true then
                                    add(e1c.collid.events, ev)
                                end
                                if e2c.collid.sensor == true then
                                    add(e2c.collid.events, ev)
                                end
                            end
                        end
                    end
                end
            elseif e1c.collid.layer ~= e2c.collid.layer then
                col = Collision.collideShape[e1c.collshape.type][e2c.collshape.type](e1c.pos, e2c.pos, e1c.collshape, e2c.collshape)
                if col then
                    local ev = {e1, e2}
                    if e1c.collid.dynamic == true then
                        add(e1c.collid.events, ev)
                    end
                    if e2c.collid.dynamic == true then
                        add(e2c.collid.events, ev)
                    end
                end
            end
        end
    end
end

Collision.draw = function()
    if Collision.DEBUG then
        local prev_color = {love.graphics.getColor()}
        local ents = ECS:CollectEntitiesWith({"pos", "collshape", "collid"})
        for i=1,#ents do
            local ent = ents[i]
            local c = ECS:GetEntComps(ent)
            local ps = {}
            local rs = {}
            local cs = {}

            if c.collid.sensor == false then
                love.graphics.setColor(Collision._debugColor)
            else
                love.graphics.setColor(Collision._debugSensorColor)
            end

            if c.collshape.type == SHAPE_POINT then
                add(ps, c.pos.x)
                add(ps, c.pos.y)
            elseif c.collshape.type == SHAPE_RECT then
                add(rs, {c.pos.x + c.collshape.x, c.pos.y + c.collshape.y, c.collshape.w, c.collshape.h})
            elseif c.collshape.type == SHAPE_CIRCLE then
                add(cs, {c.pos.x + c.collshape.x, c.pos.y + c.collshape.y, c.collshape.w})
            end

            if #ps > 1 then
                love.graphics.points(ps)
            end
            for j=1,#rs do
                love.graphics.rectangle("line", rs[j][1], rs[j][2], rs[j][3], rs[j][4])
            end
            for j=1,#cs do
                love.graphics.circle("line", cs[j][1], cs[j][2], cs[j][3])
            end
        end
        love.graphics.setColor(prev_color)
    end
end