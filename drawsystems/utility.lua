-- ** Utility Draw Systems **

-- DSCollEntDebug = function(ent)
-- 	local c = ECS:GetEntComps(ent)
-- 	Draw.print(LAYER_DEBUG, tostring(ent), c.pos.x + c.collshape.x, c.pos.y + c.collshape.y, 0, 0.9, 0.9)
-- end
-- ECS:DefineDrawSystem({"collid", "collshape", "pos"}, DSCollEntDebug)

-- DSCollMapDebug = function(ent)
-- 	local c = ECS:GetEntComps(ent)
-- 	Draw.print(LAYER_DEBUG, tostring(ent), c.pos.x, c.pos.y, 0, 0.9, 0.9)
-- end
-- ECS:DefineDrawSystem({"maptile", "pos"}, DSCollMapDebug)