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
DefineComponent("collshape", Collision.Shape)

Collision.ID = {
    ent = 0,        -- reference to owner entity
    dynamic = true, -- static vs dynamic shapes, static doesn't get events
    sensor = false, -- sensing collidor, means other non-sensor collider doesn't get event
                    -- an object both static and sensor is invalid
                    -- sensor doesn't sense sensors, only non-sensor colliders
    layer = 0,      -- collision only calculated between different layers
    events = {},    -- events queue for current frame
    custom = nil    -- custom data that can be set to anything
}
DefineComponent("collid", Collision.ID)

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
    local ents = CollectEntitiesWith({"pos", "collid", "collshape"})
    local e1 = 0
    local e2 = 0
    local e1c = nil
    local e2c = nil
    local col = false

    -- Clear prev events
    for i=1,#ents do
        local c = GetEntComps(ents[i])
        c.collid.events = {}
    end

    -- Run collision detection
    for i=1,#ents do
        for j=i,#ents do
            e1 = ents[i]
            e2 = ents[j]
            e1c = GetEntComps(e1)
            e2c = GetEntComps(e2)
            if e1c.collid.layer ~= e2c.collid.layer then
                col = Collision.collideShape[e1c.collshape.type][e2c.collshape.type](e1c.pos, e2c.pos, e1c.collshape, e2c.collshape)
                if col then
                    local ev = {e1, e2}
                    local sensor_mode = false
                    if e1c.collid.sensor == true or e2c.collid.sensor == true then
                        -- sensors don't care about dynamic static state
                        -- two sensor colliders won't produce any events
                        if e1c.collid.sensor ~= e2c.collid.sensor then
                            if e1c.collid.sensor == true then
                                add(e1c.collid.events, ev)
                            end
                            if e2c.collid.sensor == true then
                                add(e2c.collid.events, ev)
                            end
                        end
                    else
                        -- non-sensor respects dynamic/static
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
end

Collision.draw = function()
    if Collision.DEBUG then
        local prev_color = {love.graphics.getColor()}
        local ents = CollectEntitiesWith({"pos", "collshape", "collid"})
        for i=1,#ents do
            local ent = ents[i]
            local c = GetEntComps(ent)
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