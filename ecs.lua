-- ** ECS **
-- ecsEntity: eid = {comps = comps_list, cdata = comps_data}
-- ecsComponent: { name = { data }, .. }
-- ecsSystem: { {proc, ent_bucket}, .. }
-- ecsBucketsList: { bucket_id = comps_list, .. }
-- ecsBucket: { bucket_id = {ent0id, ent1id, ..}, bucket_id = {ent2id, ent5id, ..}, .. }

ecsEntityId = 1
ecsBucketId = 1
ecsEntities = {}
ecsDeadEntities = {}
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

function ecsCompEqSort(comp1, comp2)
	table.sort(comp1)
	table.sort(comp2)
	return ecsCompEqual(comp1,comp2)
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

function ecsCloneTable(t)
	local tt = {}
	for i, v in pairs(t) do tt[i] = v end
	return tt
end

function ecsRemEntFromBuckets(eid)
	local i, j
	for i=1,#ecsBuckets do
		local cb = ecsBuckets[i]
		for j=1,#cb do
			if cb[j] == eid then
				table.remove(cb, j)
				break
			end
		end
	end
end

function ecsAddEntToBuckets(eid, comps_list)
	local cbucks = ecsGetCompatBuckets(comps_list)
	for i=1,#cbucks do
		table.insert(ecsBuckets[cbucks[i]], eid)
	end
end

function ecsRebucketEnt(eid, oldcomps, newcomps)
	ecsRemEntFromBuckets(eid)
	ecsAddEntToBuckets(eid, newcomps)
end

function UpdateECS()
	ecsExecSystems(ecsUSystems) 
end 

function DrawECS()
	ecsExecSystems(ecsDSystems)
end

function DefineComponent(name, comp_data) 
	assert(name, comp_data)
	ecsComponents[name] = comp_data
end 

function DefineUpdateSystem(comps_list, system_proc)
	assert(comps_list and system_proc)
	table.sort(comps_list)
	local bucket = ecsGetBucket(comps_list)
	add(ecsUSystems, {proc = system_proc, ent_bucket = bucket})
end 

function DefineDrawSystem(comps_list, system_proc)
	assert(comps_list and system_proc)
	table.sort(comps_list)
	local bucket = ecsGetBucket(comps_list)
	add(ecsDSystems, {proc = system_proc, ent_bucket = bucket})
end

function SpawnEntity(comps_list)
	local eid = ecsNextEntityId()
	local comps_data = {} 
	table.sort(comps_list)
	local i
	for i = 1, #comps_list do
		comps_data[comps_list[i]] = ecsCreateComp(ecsComponents[comps_list[i]])
	end 
	ecsEntities[eid] = {
		comps = comps_list,
		cdata = comps_data
	}
	local cbucks = ecsGetCompatBuckets(comps_list)
	for i = 1, #cbucks do
		add(ecsBuckets[cbucks[i]], eid)
	end 
	return eid
end

-- returns a dict of comp->data
function GetEntComps(eid)
	assert(eid)
	return ecsEntities[eid].cdata
end

-- returns dict of component data
function GetEntComp(eid, comp_name)
	assert(eid and comp_name)
	return ecsEntities[eid].cdata[comp_name]
end

-- Adds new comp to entity, 1 comp/name
function EntAddComp(eid, comp_name)
	assert(not ecsEntities[eid].cdata[comp_name] and ecsComponents[comp_name])
	oldcomps = GetEntComps(eid)
	newcomps = ecsCloneTable(oldcomps)
	table.insert(newcomps, comp_name)
	table.sort(newcomps)
	ecsEntities[eid].comps = newcomps
	ecsEntities[eid].cdata[comp_name] = ecsCreateComp(ecsComponents[comp_name])
	ecsRebucketEnt(eid, oldcomps, newcomps)
end

-- Removes component from entity
function EntRemComp(eid, comp_name)
	assert(ecsEntities[eid].cdata[comp_name])
	oldcomps = GetEntComps(eid)
	newcomps = ecsCloneTable(oldcomps)
	for i=1,#newcomps do
		if newcomps[i] == comp_name then
			table.remove(newcomps, i)
			break
		end
	end
	ecsEntities[eid].comps = newcomps
	ecsEntities[eid].cdata[comp_name] = nil
	ecsRebucketEnt(eid, oldcomps, newcomps)
end

function KillEntity(eid)
	ecsRemEntFromBuckets(eid)
	ecsEntities[eid] = nil
	table.insert(ecsDeadEntities, eid)
end 

function KillAllEntities()
	local i, j
	for i=1,#ecsBuckets do
		ecsBuckets[i] = {}
	end
	for i=1,#ecsEntities do
		table.insert(ecsDeadEntities, ecsEntities[i])
	end
	ecsEntities = {}
end

function IsDeadEntity(eid)
	for i=1,#ecsDeadEntities do
		if ecsDeadEntities[i] == eid then
			return true
		end
	end
	return false
end
