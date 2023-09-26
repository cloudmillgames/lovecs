---------------- Love2D-PICO8 adaptor
function add(t, v)
	table.insert(t, v)
end


---------------- Main

function _init()
end

function _update60()
	UpdateECS()
end

function _draw() 
	DrawECS()
end

--------------------- ECS
-- ecsEntity: eid = {comps = comps_list, entity = comps_data}
-- ecsComponent: { name = { data }, .. }
-- ecsSystem: { {proc, ent_bucket}, .. }
-- ecsBucketsList: { bucket_id = comps_list, .. }
-- ecsBucket: { bucket_id = {ent0id, ent1id, ..}, bucket_id = {ent2id, ent5id, ..}, .. }
ecsEntityId = 1
ecsBucketId = 1
ecsEntities = {}
ecsComponents = {}
ecsUSystems = {}
ecsDSystems = {}
ecsBucketsList = {}
ecsBuckets = {} 

function ecsNextEntityId()
	ecsEntityId = ecsEntityId + 1
	return ecsEntityId - 1
end

function ecsNextBucketId()
	ecsBucketId = ecsBucketId + 1
	return ecsBucketId - 1
end 

-- Returns existing bucket or new one
function ecsGetBucket(comps_list)
	local i, bl, found 
	local buckid = nil
	for i, c in ipairs(ecsBucketsList) do 
		if ecsCompEq(comps_list, c) then 
			buckid = i
			break
		end 
	end 
	if buckid == nil then 
		buckid = ecsNextBucketId()
		ecsBuckets[buckid] = {}
		ecsBucketsList[buckid] = comps_list
	end
	return ecsBuckets[buckid]
end 

-- Get all compatible buckets to passed components list
function ecsGetCompatBuckets(comps_list)
	local buckids = {}
	for i, c in ipairs(ecsBucketsList) do 
		if ecsCompIn(c, comps_list) then 
			add(buckids, i) 
		end
	end 
	return buckids
end 

-- Compare two component lists for exact match (non-sorted)
function ecsCompEq(comp1, comp2)
	if #comp1 ~= #comp2 then return false end 
	for i = 1, #comp1 do
		if comp1[i] ~= comp2[i] then 
			return false 
		end 
	end 
	return true
end 

function ecsCreateComp(comp)
	local newcomp = {}
	for i, v in pairs(comp) do 
		newcomp[i] = v 
	end
	return newcomp
end 

-- Return true if subset is in set
function ecsCompIn(subset, set)
	if #subset > #set then return false end
	local i, j, found
	found = 0
	for i = 1, #subset do 
		for j = 1, #set do 
			if subset[i] == set[j] then
				found = found + 1
				break
			end 
		end
	end
	return found == #subset
end 

function ecsExecSystem(system)
	local i, e
	for i, e in ipairs(system.ent_bucket) do
		system.proc(e)
	end
end

function ecsExecSystems(systems)
	local i, s
	for i, s in ipairs(systems) do 
		ecsExecSystem(s)
	end
end

function UpdateECS()
	ecsExecSystems(ecsUSystems) 
end 

function DrawECS()
	ecsExecSystems(ecsDSystems)
end

function DefineComponent(name, comp_data) 
	ecsComponents[name] = comp_data
end 

function DefineUpdateSystem(comps_list, system_proc)
	local bucket = ecsGetBucket(comps_list)
	add(ecsUSystems, {proc = system_proc, ent_bucket = bucket})
end 

function DefineDrawSystem(comps_list, system_proc)
	local bucket = ecsGetBucket(comps_list)
	add(ecsDSystems, {proc = system_proc, ent_bucket = bucket})
end

function SpawnEntity(comps_list)
	local eid = ecsNextEntityId()
	local entity_data = {} 
	-- Todo: create actual components in entity_data 
	local i
	for i = 1, #comps_list do
		add(entity_data, ecsCreateComp(ecsComponents[comps_list[i]]))
	end 
	ecsEntities[eid] = {
		comps = comps_list,
		entity = entity_data
	}
	local cbucks = ecsGetCompatBuckets(comps_list)
	for i = 1, #cbucks do
		add(ecsBuckets[cbucks[i]], eid)
	end 
	return eid
end 

function KillEntity(eid)
	local cbucks = ecsGetCompatBuckets(ecsEntities[eid].comps)
	local i, j, b
	for i = 1, #cbucks do
		-- Removal is index based, so eid as index is incorrect
		--table.remove(ecsBuckets[cbucks[i]], eid)
		
	end 
	table.remove(ecsEntities, eid)
	return #cbucks
end 

function KillAllEntities()
	-- Todo: reset all entity buckets, and entities 
end 

----------------- Define components

CPos = {
	x = 0,
	y = 0
}

CSprite = {
	frame = 1,
	flip_x = false,
	flip_y = false,
}

CPlayer = {
	mode = "play",
}

DefineComponent("pos", CPos)
DefineComponent("sprite", CSprite)
DefineComponent("player", CPlayer)

----------------- Define systems

USPlayerController = function(ent)
	if btn(1) then ent.pos.x = ent.pos.x + 1 end 
	if btn(0) then ent.pos.x = ent.pos.x - 1 end 
end 

DSSpriteDrawer = function(ent)
	spr(ent.sprite.frame, ent.pos.x, ent.pos.y, 1, 1, ent.sprite.flip_x, ent.sprite.flip_y)
end 

DefineUpdateSystem({"player", "pos"}, USPlayerController)
DefineDrawSystem({"sprite"}, DSSpriteDrawer)

----------------- Create entities

eid = SpawnEntity({"pos", "sprite", "player"})

----------------- Clearing entities 

KillEntity(eid)
KillAllEntities()


------------------------------------------ Love2D stuffs
LoveSprites = {}
function CompEqual(comp1, comp2)
	if #comp1 ~= #comp2 then return false end 
	for i = 1, #comp1 do
		if comp1[i] ~= comp2[i] then 
			return false 
		end 
	end 
	return true
end 
function CompEqualSorted(comp1, comp2)
	table.sort(comp1)
	table.sort(comp2)
	return CompEqual(comp1,comp2)
end 
function test() 
	print("Testing whether dictionary equality works")
	local val = {"pos", "player"}
	local dicts = {
		{"pos", "player"},
		{"player", "pos"},
		{"pos", "control"}
	}
	local i, d
	print("Direct comparison using ==:")
	for i, d in ipairs(dicts) do 
		local result = false 
		if val == d then result = true end
		print("  CASE " .. i .. ": " ..tostring(result))
	end 
	print("Using simple compare function:")
	for i, d in ipairs(dicts) do 
		local result = false 
		if CompEqual(val, d) then result = true end
		print("  CASE " .. i .. ": " ..tostring(result))
	end  
	print("Using sorted compare function:")
	for i, d in ipairs(dicts) do 
		local result = false 
		if CompEqualSorted(val, d) then result = true end
		print("  CASE " .. i .. ": " ..tostring(result))
	end 
end
function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest")
	_init()
	table.insert(LoveSprites, love.graphics.newImage("santa.png"))
	test()
end 

function love.keyreleased(key)
   if key == "escape" then
      love.event.quit()
   end
end

function love.update(dt)
	_update60()
end

function love.draw()
	love.graphics.print("Hello World!", 400, 300)
	love.graphics.draw(LoveSprites[1],500,200,0,4,4)
end

function btn(key)
	return false 
end 