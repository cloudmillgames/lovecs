-- ** ECS **
-- ecsEntity: eid = {comps = comps_list, cdata = comps_data}
-- ecsDeadEntities: {eid1, .. }
-- ecsComponent: { name = { data }, .. }
-- ecsSystem: { {proc, ent_bucket}, .. }
-- ecsBucketsList: { bucket_id = comps_list, .. }
-- ecsBucket: { bucket_id = {ent0id, ent1id, ..}, bucket_id = {ent2id, ent5id, ..}, .. }
-- ecsTaggedEnts: { name1 = {ent0id, ent1id, ..}, name2 = ..}

local ECS = {}
ECS.__index = ECS

function ECS.new()
	local ecs = setmetatable({}, ECS)

	ecs._EntityId = 1
	ecs._BucketId = 1
	ecs._Entities = {}
	ecs._DeadEntities = {}
	ecs._Components = {}
	ecs._USystems = {}
	ecs._DSystems = {}
	ecs._BucketsList = {}
	ecs._Buckets = {}
	ecs._TaggedEnts = {}

	return ecs
end

function ECS:_NextEntityId()
	self._EntityId = self._EntityId + 1
	return self._EntityId - 1
end

function ECS:_NextBucketId()
	self._BucketId = self._BucketId + 1
	return self._BucketId - 1
end 

-- Returns existing bucket id or new one
function ECS:_GetBucket(comps_list)
	local bl, found 
	local buckid = nil
	for i, c in ipairs(self._BucketsList) do 
		if self:_CompEq(comps_list, c) then 
			buckid = i
			break
		end
	end
	if buckid == nil then
		buckid = self:_NextBucketId()
		self._Buckets[buckid] = {}
		self._BucketsList[buckid] = comps_list
	end
	return buckid
end 

-- Get all compatible buckets to passed components list
function ECS:_GetCompatBuckets(comps_list)
	-- bucket(subset) in comps_list(set)
	local buckids = {}
	for i, c in ipairs(self._BucketsList) do
		if self:_CompIn(c, comps_list) then
			add(buckids, i)
		end
	end
	return buckids
end

-- Compare two component lists for exact match (non-sorted)
function ECS:_CompEq(comp1, comp2)
	if #comp1 ~= #comp2 then return false end
	for i = 1, #comp1 do
		if comp1[i] ~= comp2[i] then
			return false
		end
	end
	return true
end 

function ECS:_CompEqSort(comp1, comp2)
	table.sort(comp1)
	table.sort(comp2)
	return self:_CompEq(comp1,comp2)
end

function ECS:_CreateComp(comp)
	if comp == nil then error("_CreateComp() nil component, probably wrong name") end
	return self:_DeepCloneTable(comp)
end

-- Return true if subset is in set
function ECS:_CompIn(subset, set)
	if #subset > #set then return false end
	local found
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

function ECS:_ExecSystem(system)
	for i, e in ipairs(self._Buckets[system.ent_buckid]) do
		system.proc(e)
	end
end

function ECS:_ExecSystems(systems)
	for i, s in ipairs(systems) do
		self:_ExecSystem(s)
	end
end

-- Dives into table and clones internal tables recursively
function ECS:_DeepCloneTable(t)
	local tt = {}
	for i, v in pairs(t) do
		if type(v) == "table" then
			tt[i] = self:_DeepCloneTable(v)
		else
			tt[i] = v
		end
	end
	return tt
end

function ECS:_RemEntFromBuckets(eid)
	for i=1,#self._Buckets do
		local cb = self._Buckets[i]
		for j=1,#cb do
			if cb[j] == eid then
				table.remove(cb, j)
				break
			end
		end
	end
end

function ECS:_AddEntToBuckets(eid, comps_list)
	local cbucks = self:_GetCompatBuckets(comps_list)
	for i=1,#cbucks do
		table.insert(self._Buckets[cbucks[i]], eid)
	end
end

function ECS:_RebucketEnt(eid, oldcomps, newcomps)
	self:_RemEntFromBuckets(eid)
	self:_AddEntToBuckets(eid, newcomps)
end

-- Get rid of all named dead entities, be as lazy as possible
-- returns true if some ents found in that name, false if none found
function ECS:_RefreshTaggedEnts(tag)
	local curr_ents = self._TaggedEnts[tag]
	-- If no ents tagged, skip
	if curr_ents == nil then
		return false
	end

	-- How many tagged ents are alive?
	local count = 0
	for _,e in pairs(curr_ents) do
		if self._Entities[e] ~= nil then
			count = count + 1
		end
	end

	-- all tagged ents are dead, easy cleanup
	if count == 0 then
		self._TaggedEnts[tag] = nil
		return false
	end

	-- tagged live ents changed, need to update tag then
	if count < #curr_ents then
		local new_ents = {}
		for _,e in pairs(curr_ents) do
			add(new_ents, e)
		end
		self._TaggedEnts[tag] = new_ents
	end

	return true
end

-----------------------------------------------------------
-- public interface

function ECS:UpdateECS()
	self:_ExecSystems(self._USystems) 
end 

function ECS:DrawECS()
	self:_ExecSystems(self._DSystems)
end

function ECS:DefineComponent(name, comp_data)
	assert(name, "Name invalid: "..tostring(name))
	assert(comp_data, "Component data invalid: "..tostring(comp_data))
	assert(type(name) == "string", "Name not string: "..type(name))
	self._Components[name] = comp_data
end 

function ECS:DefineUpdateSystem(comps_list, system_proc)
	assert(comps_list, "Invalid comps list: "..tostring(comps_list))
	assert(system_proc, "Invalid system proc: "..tostring(system_proc))
	table.sort(comps_list)
	local buckid = self:_GetBucket(comps_list)
	add(self._USystems, {proc = system_proc, ent_buckid = buckid})
end 

function ECS:DefineDrawSystem(comps_list, system_proc)
	assert(comps_list, "Invalid comps list: "..tostring(comps_list))
	assert(system_proc, "Invalid system proc: "..tostring(system_proc))
	table.sort(comps_list)
	local buckid = self:_GetBucket(comps_list)
	add(self._DSystems, {proc = system_proc, ent_buckid = buckid})
end

-- tag_name: optional name to register this entity under
function ECS:SpawnEntity(comps_list, tag_name)
	local eid = self:_NextEntityId()
	local comps_data = {} 
	table.sort(comps_list)
	for i = 1, #comps_list do
		comps_data[comps_list[i]] = self:_CreateComp(self._Components[comps_list[i]])
	end
	self._Entities[eid] = {
		comps = comps_list,
		cdata = comps_data
	}
	local cbucks = self:_GetCompatBuckets(comps_list)
	for i = 1, #cbucks do
		add(self._Buckets[cbucks[i]], eid)
	end

	if type(tag_name) == "string" and #tag_name > 0 then
		self:SetEntTag(eid, tag_name)
	end

	return eid
end

-- returns a dict of comp->data
function ECS:GetEntComps(eid)
	assert(eid, "Invalid entity given: "..tostring(eid))
	return self._Entities[eid].cdata
end

-- returns dict of component data
function ECS:GetEntComp(eid, comp_name)
	assert(eid, "Invalid entity given: "..tostring(eid))
	assert(comp_name, "Invalid component name given: "..tostring(comp_name))
	return self._Entities[eid].cdata[comp_name]
end

-- returns bool to check whether entity has component
function ECS:HasEntComp(eid, comp_name)
	assert(eid, "Invalid entity given (nil)")
	assert(self._Entities[eid], "Invalid entity id, no entity defined: "..tostring(eid))
	--assert(comp_name, "Invalid component name given (nil)")
	return self._Entities[eid].cdata[comp_name] ~= nil
end

-- Adds new comp to entity, 1 comp/name, must be recalled after add/remove comp
function ECS:EntAddComp(eid, comp_name)
	assert(not self._Entities[eid].cdata[comp_name], "Ent has comp: "..tostring(comp_name))
	assert(self._Components[comp_name], "Comp not defined: "..tostring(comp_name))
	local oldcomps = self:_DeepCloneTable(self._Entities[eid].comps)
	table.insert(self._Entities[eid].comps, comp_name)
	table.sort(self._Entities[eid].comps)
	self._Entities[eid].cdata[comp_name] = self:_CreateComp(self._Components[comp_name])
	self:_RebucketEnt(eid, oldcomps, self._Entities[eid].comps)
end

-- Adds a list of new components to entity: comp_names = {"comp1", "comp2", ..}
-- must be recalled after add/remove comps
function ECS:EntAddComps(eid, comp_names)
	assert(type(comp_names) == "table", "comp_names not a table: "..type(comp_names))

	local oldcomps = self:_DeepCloneTable(self._Entities[eid].comps)
	for _, new_comp in pairs(comp_names) do
		assert(self._Entities[eid].cdata[new_comp] == nil, "Ent has comp: "..tostring(new_comp))
		assert(self._Components[new_comp], "Comp not defined: "..tostring(new_comp))
		table.insert(self._Entities[eid].comps, new_comp)
	end

	table.sort(self._Entities[eid].comps)

	for _, new_comp in pairs(comp_names) do
		self._Entities[eid].cdata[new_comp] = self:_CreateComp(self._Components[new_comp])
	end
	self:_RebucketEnt(eid, oldcomps, self._Entities[eid].comps)
end

-- Removes component from entity
function ECS:EntRemComp(eid, comp_name)
	assert(self._Entities[eid].cdata[comp_name], "Ent doesn't have comp: "..tostring(comp_name))
	local oldcomps = self:_DeepCloneTable(self._Entities[eid].comps)
	local newcomps = {}
	for i=1,#oldcomps do
		if oldcomps[i] ~= comp_name then
			table.insert(newcomps, oldcomps[i])
		end
	end
	-- no need to resort newcomps as its the same as oldcomps sans comp_name
	self._Entities[eid].comps = newcomps
	self._Entities[eid].cdata[comp_name] = nil
	self:_RebucketEnt(eid, oldcomps, newcomps)
end

function ECS:KillEntity(eid)
	self:_RemEntFromBuckets(eid)
	self._Entities[eid] = nil
	table.insert(self._DeadEntities, eid)
end 

function ECS:KillAllEntities()
	for i=1,#self._Buckets do
		self._Buckets[i] = {}
	end
	for i in pairs(self._Entities) do
		table.insert(self._DeadEntities, self._Entities[i])
	end
	self._Entities = {}
	self._TaggedEnts = {}
	--ecsEntityId = 1 this breaks collision and other stuff somehow
end

function ECS:IsDeadEntity(eid)
	for i=1,#self._DeadEntities do
		if self._DeadEntities[i] == eid then
			return true
		end
	end
	return false
end

function ECS:IsAliveEntity(eid)
	return not self:IsDeadEntity(eid)
end

-- Create a comp as data
function ECS:CreateComp(comp_name)
	for cn in pairs(self._Components) do
		if cn == comp_name then
			return self:_CreateComp(self._Components[cn])
		end
	end
	assert(false) -- bad comp name
end

-- expensive, only use for singleton systems
function ECS:CollectEntitiesWith(comps)
	local ents={}
	for i in pairs(self._Entities) do
		if self:_CompIn(comps, self._Entities[i].comps) then
			add(ents, i)
		end
	end
	return ents
end

-- expensive, returns first entity found that has comps list
function ECS:GetFirstEntityWith(comps)
	for i in pairs(self._Entities) do
		if self:_CompIn(comps, self._Entities[i].comps) then
			return i
		end
	end
	return nil
end

-- count how many entities are alive
function ECS:CountLiveEntities()
	local c=0
	for i in pairs(self._Entities) do
		c=c+1
	end
	return c
end

-- Get first ent that matches name, nil if no match
function ECS:GetTaggedEnt(tag)
	if self:_RefreshTaggedEnts(tag) then
		local ents = self._TaggedEnts[tag]
		for _, e in pairs(ents) do
			return e
		end
	end
	return nil
end

-- Get comp of first ent that matches tag name, nil if no match or no comp
function ECS:GetTaggedEntComp(tag, comp)
	local ent = self:GetTaggedEnt(tag)
	if ent ~= nil and self:HasEntComp(ent, comp) then
		return self:GetEntComp(ent, comp)
	end
	return nil
end

-- Get all entities tagged name
function ECS:GetTaggedEnts(tag)
	if self:_RefreshTaggedEnts(tag) then
		return self._TaggedEnts[tag]
	end
	return nil
end

-- Count all entities tagged name
function ECS:CountTaggedEnts(tag)
	if self:_RefreshTaggedEnts(tag) then
		return #self._TaggedEnts[tag]
	else
		return 0
	end
end

function ECS:HasTaggedEnt(tag)
	return self:CountTaggedEnts(tag) > 0
end

-- Set entitiy tag
function ECS:SetEntTag(ent, tag)
	if self._TaggedEnts[tag] == nil then
		self._TaggedEnts[tag] = {}
	end
	add(self._TaggedEnts[tag], ent)
end

return ECS