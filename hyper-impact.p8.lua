-- utils
table={}
function table.insert (list, pos, value)
  assert(type(list) == 'table', "bad argument #1 to 'insert' "
    .."(table expected, got "..type(list)..")")
  if pos and not value then
    value = pos
    pos = #list + 1
  else
    assert(type(pos) == 'number', "bad argument #2 to 'insert' "
      .."(number expected, got "..type(pos)..")")
  end
  if pos <= #list then
    for i = #list, pos, -1 do
      list[i + 1] = list[i]
    end
  end
  list[pos] = value
end

function table.remove(list, pos)
  assert(type(list) == 'table', "bad argument #1 to 'remove' "
    .."(table expected, got "..type(list)..")")
  if not pos then
    pos = #list
  else
    assert(type(pos) == 'number', "bad argument #2 to 'remove' "
      .."(number expected, got "..type(tbl)..")")
  end
  for i = pos, #list do
    list[i] = list[i + 1]
  end
end

function table.sort (arr, comp)
  if not comp then
    comp = function (a, b)
      return a < b
    end
  end
  local function partition (a, lo, hi)
      pivot = a[hi]
      i = lo - 1
      for j = lo, hi - 1 do
        if comp(a[j], pivot) then
          i = i + 1
          a[i], a[j] = a[j], a[i]
        end
      end
      a[i + 1], a[hi] = a[hi], a[i + 1]
      return i + 1
    end
  local function quicksort (a, lo, hi)
    if lo < hi then
      p = partition(a, lo, hi)
      quicksort(a, lo, p - 1)
      return quicksort(a, p + 1, hi)
    end
  end
  return quicksort(arr, 1, #arr)
end

--- caps v to be between mn,mx
function cap(v,mn,mx)
	if v<mn then v=mn end
	if v>mx then v=mx end
	return v
end

-- caps to within abs max -+
function cap_abs(v,abs_max)
	return cap(v,-abs_max,abs_max)
end

-- inc's v,back to mn if >mx
function cycle(v,mn,mx)
 v+=1
 if v>mx then v=mn end
 return v
end

-- vec2: {x,y}
v2mag=function(v)
	return sqrt(v[1]*v[1]+v[2]*
		v[2])
end
v2norm=function(v)
	local m=v2mag(v)
	return {v[1]/m,v[2]/m}
end
v2rand=function(v)
	return v2norm({rnd(2)-1,
		rnd(2)-1})
end
v2add=function(a,b)
	return {a[1]+b[1],a[2]+b[2]}
end
v2sub=function(a,b)
	return {a[1]-b[1],a[2]-b[2]}
end
v2muln=function(v,n)
	return {v[1]*n,v[2]*n}
end
v2dist=function(a,b)
	return v2mag(v2sub(a,b))
end

-- vec3: {x,y,z}
v3mag=function(v)
	return sqrt(v[1]*v[1]+v[2]*v[2]
		+v[3]*v[3])
end
v3norm=function(v)
	local m=v3mag(v)
	return {v[1]/m,v[2]/m,v[3]/m}
end
v3muln=function(v,n)
	return {v[1]*n,v[2]*n,v[3]*n}
end
v3divn=function(v,n)
	return {v[1]/n,v[2]/n,v[3]/n}
end
v3add=function(a,b)
	return {a[1]+b[1],a[2]+b[2],
		a[3]+b[3]}
end
v3sub=function(a,b)
	return {a[1]-b[1],a[2]-b[2],
		a[3]-b[3]}
end

-->8
-- ** ecs **
-- ecsentities: {eid = {comps = comps_list, cdata = comps_data}, ..}
-- ecsdeadentities: {eid1, .. }
-- ecscomponent: { name = { data }, .. }
-- ecssystem: { {proc, ent_buckid}, .. }
-- ecsbucketslist: { bucket_id = comps_list, .. }
-- ecsbuckets: { bucket_id = {ent0id, ent1id, ..}, bucket_id = {ent2id, ent5id, ..}, .. }

ecsentityid = 1
ecsbucketid = 1
ecsentities = {}
ecsdeadentities = {}
ecscomponents = {}
ecsusystems = {}
ecsdsystems = {}
ecsbucketslist = {}
ecsbuckets = {} 

function ecsnextentityid()
	ecsentityid = ecsentityid + 1
	return ecsentityid - 1
end

function ecsnextbucketid()
	ecsbucketid = ecsbucketid + 1
	return ecsbucketid - 1
end 

-- returns existing bucket id or new one
function ecsgetbucket(comps_list)
	local i, bl, found 
	local buckid = nil
	for i, c in ipairs(ecsbucketslist) do 
		if ecscompeq(comps_list, c) then 
			buckid = i
			break
		end 
	end 
	if buckid == nil then 
		buckid = ecsnextbucketid()
		ecsbuckets[buckid] = {}
		ecsbucketslist[buckid] = comps_list
	end
	return buckid
end 

-- get all compatible buckets to passed components list
function ecsgetcompatbuckets(comps_list)
	-- bucket(subset) in comps_list(set)
	local buckids = {}
	for i, c in ipairs(ecsbucketslist) do 
		if ecscompin(c, comps_list) then 
			add(buckids, i) 
		end
	end 
	return buckids
end

-- compare two component lists for exact match (non-sorted)
function ecscompeq(comp1, comp2)
	if #comp1 ~= #comp2 then return false end 
	for i = 1, #comp1 do
		if comp1[i] ~= comp2[i] then 
			return false 
		end 
	end 
	return true
end 

function ecscompeqsort(comp1, comp2)
	table.sort(comp1)
	table.sort(comp2)
	return ecscompequal(comp1,comp2)
end

function ecscreatecomp(comp)
	local newcomp = {}
	for i, v in pairs(comp) do 
		newcomp[i] = v 
	end
	return newcomp
end 

-- return true if subset is in set
function ecscompin(subset, set)
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

function ecsexecsystem(system)
	local i, e
	for i, e in ipairs(ecsbuckets[system.ent_buckid]) do
		system.proc(e)
	end
end

function ecsexecsystems(systems)
	local i, s
	for i, s in ipairs(systems) do 
		ecsexecsystem(s)
	end
end

function ecsclonetable(t)
	local tt = {}
	for i, v in pairs(t) do tt[i] = v end
	return tt
end

function ecsrementfrombuckets(eid)
	local i, j
	for i=1,#ecsbuckets do
		local cb = ecsbuckets[i]
		for j=1,#cb do
			if cb[j] == eid then
				table.remove(cb, j)
				break
			end
		end
	end
end

function ecsaddenttobuckets(eid, comps_list)
	local cbucks = ecsgetcompatbuckets(comps_list)
	for i=1,#cbucks do
		table.insert(ecsbuckets[cbucks[i]], eid)
	end
end

function ecsrebucketent(eid, oldcomps, newcomps)
	ecsrementfrombuckets(eid)
	ecsaddenttobuckets(eid, newcomps)
end

function updateecs()
	ecsexecsystems(ecsusystems) 
end 

function drawecs()
	ecsexecsystems(ecsdsystems)
end

function definecomponent(name, comp_data) 
	assert(name, comp_data)
	ecscomponents[name] = comp_data
end 

function defineupdatesystem(comps_list, system_proc)
	assert(comps_list)
	assert(system_proc)
	table.sort(comps_list)
	local buckid = ecsgetbucket(comps_list)
	add(ecsusystems, {proc = system_proc, ent_buckid = buckid})
end 

function definedrawsystem(comps_list, system_proc)
	assert(comps_list)
	assert(system_proc)
	table.sort(comps_list)
	local buckid = ecsgetbucket(comps_list)
	add(ecsdsystems, {proc = system_proc, ent_buckid = buckid})
end

function spawnentity(comps_list)
	local eid = ecsnextentityid()
	local comps_data = {} 
	table.sort(comps_list)
	local i
	for i = 1, #comps_list do
		comps_data[comps_list[i]] = ecscreatecomp(ecscomponents[comps_list[i]])
	end 
	ecsentities[eid] = {
		comps = comps_list,
		cdata = comps_data
	}
	local cbucks = ecsgetcompatbuckets(comps_list)
	for i = 1, #cbucks do
		add(ecsbuckets[cbucks[i]], eid)
	end 
	return eid
end

-- returns a dict of comp->data
function getentcomps(eid)
	assert(eid)
	return ecsentities[eid].cdata
end

-- returns dict of component data
function getentcomp(eid, comp_name)
	assert(eid)
	assert(comp_name)
	return ecsentities[eid].cdata[comp_name]
end

-- adds new comp to entity, 1 comp/name
function entaddcomp(eid, comp_name)
	assert(not ecsentities[eid].cdata[comp_name] and ecscomponents[comp_name])
	oldcomps = getentcomps(eid)
	newcomps = ecsclonetable(oldcomps)
	table.insert(newcomps, comp_name)
	table.sort(newcomps)
	ecsentities[eid].comps = newcomps
	ecsentities[eid].cdata[comp_name] = ecscreatecomp(ecscomponents[comp_name])
	ecsrebucketent(eid, oldcomps, newcomps)
end

-- removes component from entity
function entremcomp(eid, comp_name)
	assert(ecsentities[eid].cdata[comp_name])
	oldcomps = getentcomps(eid)
	newcomps = ecsclonetable(oldcomps)
	for i=1,#newcomps do
		if newcomps[i] == comp_name then
			table.remove(newcomps, i)
			break
		end
	end
	ecsentities[eid].comps = newcomps
	ecsentities[eid].cdata[comp_name] = nil
	ecsrebucketent(eid, oldcomps, newcomps)
end

function killentity(eid)
	ecsrementfrombuckets(eid)
	ecsentities[eid] = nil
	table.insert(ecsdeadentities, eid)
end 

function killallentities()
	local i, j
	for i=1,#ecsbuckets do
		ecsbuckets[i] = {}
	end
	for i in pairs(ecsentities) do
		table.insert(ecsdeadentities, ecsentities[i])
	end
	ecsentities = {}
end

function isdeadentity(eid)
	for i=1,#ecsdeadentities do
		if ecsdeadentities[i] == eid then
			return true
		end
	end
	return false
end

-- create a comp as data
function createcomp(comp_name)
	for cn in pairs(ecscomponents) do
		if cn == comp_name then
			return ecscreatecomp(ecscomponents[cn])
		end
	end
	assert(false) -- bad comp name
end

-- expensive, only use for singleton systems
function collectentswith(comps)
	local ents={}
	for i in pairs(ecsentities) do
		if ecscompin(comps,ecsentities[i].comps) then
			add(ents, i)
		end
	end
	return ents
end

-- count how many entities are alive
function countliveents()
	local c=0
	for i in pairs(ecsentities) do
		c=c+1
	end
	return c
end

-->8
-- components

--- init: init once at start
cinit={}
definecomponent("init",cinit)

--- map: map drawing and spawn
cmap={
	bg_col=3
}
definecomponent("map",cmap)

--- pos: world pos
cpos={
	x=0,y=0,z=0
}
definecomponent("pos",cpos)

--- spr: static sprite draw
cspr={
	id=1,w=1,h=1,fx=false,fy=false
}
definecomponent("spr",cspr)

--- obj: game object
cobj={
 active=true, -- update?
 visible=true,-- draw?
 fulhp=1,
 hp=1         -- dead if zero
}
definecomponent("obj",cobj)

--- aspr: animated sprite draw
caspr={
 anim="cycle",
 w=1,h=1,
 frames={1},
 cur_frame=1,
 ticks_per_frame=15,
 ticks=0,
 fx=false,fy=false
}
definecomponent("aspr",caspr)

--- plink: link to parent
cplink={
	parent=nil,
	x=0,y=0,z=0
}
definecomponent("plink",cplink)

--- dir: a direction
cdir={
	d=1,x=0,y=1,z=0
}
definecomponent("dir",cdir)

--- isospr: isometric spr
cisospr={ sprs={} }
definecomponent("isospr",
	cisospr)

--- isoplink: isometric parent
---  only active if dir match
cisoplink={
	parent=nil,
	x=0,y=0,z=0,
	dir=1
}
definecomponent("isoplink",
	cisoplink)

--- player: player control
cplayer={}
definecomponent("player",cplayer
	)

--- shadow: spr shadow
cshadow={
	f=0,sid=1,w=1,h=1,fx=1,fy=1
}
definecomponent("shadow",cshadow
	)

--- isoshadow: isospr shadow
cisoshadow={
	f=0,sprs={}
}
definecomponent("isoshadow",
	cisoshadow)

--- hover: hoverable entity
chover={
	acc=2,
	vel={0,0,0},
	spd=25
}
definecomponent("hover",chover)

--- sfx: sound with bool flag
csfx={id=0,flag=false}
definecomponent("sfx",csfx)

--- colrct: collision rect
ccolrct={x=0,y=0,h=8,w=8}
definecomponent("colrct",
	ccolrct)

-- gatling: projectiles weapon
--  specific for hovers
cgatling={
	trig=false,
 projtype="exp",
 projsnd=1,
 angle=0, -- angle of attack
	cooldown=15,
	ticks=0,
	lyr=0, -- bullets layer
	hx=8,hy=8 -- hotspot
}
definecomponent("gatling",
	cgatling)

-- machgun:projectiles weapon
--  fires towards "dir"
cmachgun={
	trig=false,
 projtype="exp",
 projsnd=1,
	cooldown=15,
	ticks=0,
	lyr=0, -- owner layer
	hx=8,hy=8 -- hotspot
}
definecomponent("machgun",
	cmachgun)

-- bullet: kinetic projectile
cbullet={
	speed=30,
	type="exp",
	damage=2,
	aoe=2,
	vel={0,1,0},
	acc={0,0,-15}
}
definecomponent("bullet",
	cbullet)


-- particles: pixel particles
cparticles={
	emit=3,
	life=5,
	spd=10,
	col=15,
	pars={}
}
definecomponent("particles",
	cparticles)

-- circpars:circle particles
ccircpars={
	emit=5,
	timer=0,
	len=12,
	life=4,
	cols={8,9,10},
	circs={}
}
definecomponent("circpars",
	ccircpars)

-- enemy: a mark of an enemy
cenemy={
	name="soldier"
}
definecomponent("enemy",cenemy)

-- collid: a collidable entity
ccollid={
	ent=0, --used to events
	dyn=0, --static or dynamic
	lyr=0, --layer id
	evt={} --collision evnts queue
}
definecomponent("collid",
	ccollid)

-- collshp: shape of collision
shp_point=1
shp_rect=2
shp_circ=3

ccollshp={
	typ=shp_point,
	x=0,y=0,w=1,h=1
}
definecomponent("collshp",
	ccollshp)

-- cdamage: cause damage
cdamage={dmg=1}
definecomponent("damage",
	cdamage)

-- soldier
csoldier={
 st="idle",
	chgidle=50+rnd(80),
	tgt=0,
	range=50,
	aiming=0
}
definecomponent("soldier",
	csoldier)
	
-- hrtbeat:game conditions check
chrtbeat={}
definecomponent("hrtbeat",
	chrtbeat)

-- endscr: ending screen
cendscr={
	msg="ok",
	col=7,
	init=false
}
definecomponent("endscr",
	cendscr)

-- lzyspwn:spawn ent after time
clzyspwn={
	comps_list={},
	comps_data={},
	ticks=95
}
definecomponent("lzyspwn",
	clzyspwn)
-->8
-- system funcs

--- frametime, float limit 30hz
local dt30=1/30
--- converts 1..8 dir to 2d-vec
local dir_2_vec={
	{0,-1},{1,-1},{1,0},{1,1},
	{0,1},{-1,1},{-1,0},{-1,-1}
}
--- collision layers
local lyr_plr=0
local lyr_enm=1

--- spawns entity with obj comp
function spawngent(comps)
 add(comps,"obj")
	return spawnentity(comps)
end

-- spawns spr shadow entity
function spawnshadow(parent,
		sid,sz,fx,fy)
	local sh=spawnentity({"plink",
		"shadow"})
	local c=getentcomps(sh)
	c.plink.parent=parent
	c.shadow.sid=sid
	c.shadow.w=sz or 1
	c.shadow.h=sz or 1
	c.shadow.fx=fx or false
	c.shadow.fy=fy or false
end

function spawnisoshadow(parent,
		sprs)
	assert(#sprs==8)
	local sh=spawnentity({"plink",
		"isoshadow"})
	local c=getentcomps(sh)
	c.plink.parent=parent
	c.isoshadow.sprs=sprs
end

--- spawns player hover
function spawnplayer(x,y,z)
	-- hover
	local plr=spawngent({"isospr",
		"dir","pos","player","hover",
		"sfx","gatling","collid",
		"collshp"})
	print("plr:"..plr)
	local po=getentcomp(plr,"obj")
	po.fulhp=20
	po.hp=20
	local gat=getentcomp(plr,
		"gatling")
	gat.projtype="exp"
	gat.projsnd=1
	gat.cooldown=5
	gat.lyr=lyr_plr
	local p=getentcomp(plr,"pos")
	local ias=getentcomp(plr,
		"isospr")
	p.x=x
	p.y=y
	p.z=z
	local col=getentcomp(plr,
		"collid")
	col.ent=plr
	col.dyn=1
	col.lyr=lyr_plr
	local shp=getentcomp(plr,
		"collshp")
	shp.typ=shp_rect
	shp.x=4
	shp.y=4
	shp.w=8
	shp.h=9
	-- sprid,shadid,lrotpos,
 --  rrotpos,crotpos,flipx
	local init_fan = function(
	 pos,dir,frames,sz)
	  sz=sz or 1
	  local f=spawngent({"isoplink"
	  	,"aspr"})
	  local fc=getentcomps(f)
	  fc.isoplink.parent=plr
	  fc.isoplink.x=pos[1]
	  fc.isoplink.y=pos[2]
	  fc.isoplink.dir=dir
	  fc.aspr.frames=frames
	  fc.aspr.ticks_per_frame=0
	  fc.aspr.w=sz
	  fc.aspr.h=sz
	  return fc
	 end
 local init_dir=function(dir,d)
 	-- base sprite
 	local sd=createcomp("spr")
 	sd.id=d[1]
 	sd.w=2
 	sd.h=2
 	sd.fx=d[6]==1
 	sd.fy=false
 	ias.sprs[dir]=sd
 	-- rotors
 	init_fan(d[3],dir,{9,10,11})
		init_fan(d[4],dir,{25,26,27})
		init_fan(d[5],dir,{41,42,43})
 	-- shadow todo
 	spawnisoshadow(plr,{
			{id=128,w=2,h=2,fx=false,fy=false},
			{id=130,w=2,h=2,fx=false,fy=false},
			{id=132,w=2,h=2,fx=false,fy=false},
			{id=162,w=2,h=2,fx=false,fy=false},
			{id=160,w=2,h=2,fx=false,fy=false},
			{id=162,w=2,h=2,fx=true,fy=false},
			{id=132,w=2,h=2,fx=true,fy=false},
			{id=130,w=2,h=2,fx=true,fy=false}})
 end
	local data={ -- 1..8 direction
		{1,128,{1,7},{12,7},{6,10},0},
	 {3,130,{4,5},{12,11},{1,9},0},
  {5,132,{9,4},{9,12},{1,5},0},
  {35,162,{12,6},{3,12},{1,2},0},
  {33,160,{1,8},{12,8},{6,2},0},
  {35,162,{16-3-12,6},{16-3-3,12},
  	{16-4-1,2},1},
  {5,132,{16-3-9,4},{16-3-9,12},
  	{16-4-1,5},1},
  {3,130,{16-3-4,5},{16-3-12,11},
  	{16-4-1,9},1}
	}
	for i=1,#data do
		init_dir(i,data[i])
	end
	return plr
end

function spawnsoldier(x,y)
	-- soldier
	local s=spawngent({"pos",
		"aspr","enemy","collid",
		"collshp","soldier",
		"machgun","dir"})
	local po=getentcomp(s,"obj")
	po.fulhp=2
	po.hp=2
	local p=getentcomp(s,"pos")
	p.x=x*8
	p.y=y*8
	local r=getentcomp(s,"aspr")
	r.frames={72,73}
	local cl=getentcomp(s,
		"collid")
	cl.ent=s
	cl.dyn=1
	cl.lyr=lyr_enm
	local cs=getentcomp(s,
		"collshp")
	cs.typ=shp_rect
	cs.x=1
	cs.y=0
	cs.w=5
	cs.h=7
	local cg=getentcomp(s,
		"machgun")
	cg.projsnd=4
	cg.cooldown=15
	cg.lyr=lyr_enm
	cg.hx=4
	cg.hy=4
	local cd=getentcomp(s,"dir")
end

-- drawlist singleton system
draw={}
draw.t_spr=1
draw.t_pnts=2
draw.t_rect=3
draw.t_circ=4
draw.list={}

-- sorting comparator
draw.sortcomp=function(a,b)
	if a[3].z~=b[3].z then
		return a[3].z<b[3].z
	else
		return a[3].y<b[3].y
	end
end

draw.spr=function(n,x,y,z,w,h,
		flip_x,flip_y)
	add(draw.list,{draw.t_spr,
		{n=n,w=w,h=h,fx=flip_x,
		fy=flip_y},{x=x,y=y,z=z}})
end
-- expects {{x,y,z,col},..}
draw.pnts=function(pnts,z)
	local ps={x=pnts[1][1],
		y=pnts[1][2],z=pnts[1][3]}
	add(draw.list,{draw.t_pnts,
		pnts,ps})
end
-- expects {x,y,z},rad,col
draw.circ=function(pos,rad,col)
	local d={x=pos[1],y=pos[2],
		z=pos[3],rad=rad,col=col}
	local p={x=pos[1],y=pos[2],
		z=pos[3]}
	add(draw.list,{draw.t_circ,
		d,p})
end

--- draws all and clears list
draw.exec=function()
	table.sort(draw.list,
		draw.sortcomp)
	for i=1,#draw.list do
		local t=draw.list[i][1]
		local d=draw.list[i][2]
		local p=draw.list[i][3]
		if t==draw.t_spr then
			spr(d.n,p.x,p.y,d.w,d.h,d.fx,
				d.fy)
		elseif t==draw.t_pnts then
			local pnts=d
			for i=1,#pnts do
				local p=pnts[i]
				pset(p[1],p[2]+p[3],p[4])
			end
		elseif t==draw.t_circ then
			circfill(p.x,p.y,d.rad,d.col)
		end
	end
	draw.list={}
end
function drawlist()
	return draw.exec()
end

-- draws aspr child (has plink)
function draw_child_aspr(obj,
		link,aspr)
	if obj.visible then
		local p=link
		local r=aspr
		if p.parent and not
		  isdeadentity(p.parent) then
			local po=getentcomp(p.parent,
			 "obj")
			local pp=getentcomp(p.parent,
			 "pos")
			if po.visible then
			 draw.spr(
			 	r.frames[r.cur_frame],
			 	pp.x+p.x,pp.y+p.y,pp.z,
			 	r.w,r.h,
			  r.fx,r.fy)
			end
		end
	end
end

-- emit 1 particle: pos,par comp
function particles_emit(pos,par)
 local p={pos.x,pos.y,0}
 local v=v2muln(v2rand(),
 	par.spd)
	return {p,v,par.life,par.col}
end

-- emit 1 circ particle:pos,circ
-- {{x,y,z},rad,col,st,life}
function circpars_emit(pos,cir)
	local co=cir.cols[flr(rnd(
		#cir.cols+1)+1)]
	return {{pos.x,pos.y,pos.z},
		flr(cir.life+rnd(5)),co,
		1,cir.life}
end
					
-- collision system:exec 1/frame
csys={}
function csys.point_point(p1,p2,
		t1,t2)
 return 
 	abs(p1.x+t1.x-(p2.x+t2.x))<1
 	and abs(p1.y+t1.y-
 		(p2.y+y2.y))<1
end
function csys.point_rect(p1,p2,
		p,r)
	return not(p1.x<p2.x or
		p1.x>p2.x+r.x+r.w or
		p1.y<p2.y or
		p1.y>p2.y+r.y+r.h)
end
function csys.point_circ(p1,p2,
		p,c)
	assert(false)--notimpl
end
function csys.rect_point(p1,p2,
		r,p)
	return csys.point_rect(p1,p2,p,
		r)
end
function csys.rect_rect(p1,p2,
		r1,r2)
 return not(p1.x+r1.x>p2.x+r2.x+r2.w or
			p1.x+r1.x+r1.w<p2.x+r2.x or
			p1.y+r1.y>p2.y+r2.y+r2.h or
			p1.y+r1.y+r1.h<p2.y+r2.y)
end
function csys.rect_circ(p1,p2,
		r,c)
	assert(false)--notimpl
end
function csys.circ_point(p1,p2,
		c,p)
	return point_circ(p1,p2,p,c)
end
function csys.circ_rect(p1,p2,
		c,r)
	return rect_circ(p1,p2,r,c)
end
function csys.circ_circ(p1,p2,
		c1,c2)
	assert(false)--notimpl
end

-- index into collision check
-- point=1,rect=2,circ=3
csys.shapes_2_check={
	{ -- point
		csys.point_point,
		csys.point_rect,
		csys.point_circ
	},
	{ -- rect
		csys.rect_point,
		csys.rect_rect,
		csys.rect_circ
	},
	{ -- circ
		csys.circ_point,
		csys.circ_rect,
		csys.circ_circ
	}
}

function csys.exec()
 --expensive without spatials
	local ents=collectentswith({
		"pos","collid","collshp"})
	--terrible o((n-1)!)
	local e1=0
	local e2=0
	local e1c=nil
	local e2c=nil
	local col=false
	-- clear all prev events
	for i=1,#ents do
		local c=getentcomp(ents[i],
			"collid")
		c.evt={}
	end
	for i=1,#ents do
		for j=i,#ents do
			e1=ents[i]
			e2=ents[j]
			e1c=getentcomps(e1)
			e2c=getentcomps(e2)
			if e1c.collid.lyr ~=
					e2c.collid.lyr then
				col=csys.shapes_2_check[
					e1c.collshp.typ][
					e2c.collshp.typ](
						e1c.pos,e2c.pos,
						e1c.collshp,e2c.collshp)
				-- height check
				if col then
					col=not(
					 e1c.pos.z>
					 e2c.pos.z+e2c.collshp.h or
						e1c.pos.z+e1c.collshp.h<
						e2c.pos.z)
				end
				if col then
					local ev={e1,e2}
					add(e1c.collid.evt,ev)
					add(e2c.collid.evt,ev)
				end
			end
		end
	end
end

function updatecollisions()
	csys.exec()
end

-->8
-- update systems
--- init demo
usinit = function(ent)
 -- map spawner
	for y=0,15 do
		for x=0,15 do
			local v=mget(x,y+16)
			if v==72 then
				local s=spawnsoldier(x,y)
			elseif v==70 then
				-- building
				local s=spawngent({"pos","spr"})
				local p=getentcomp(s,"pos")
				p.x=x*8
				p.y=y*8
				local r=getentcomp(s,"spr")
				r.id=v
				r.w=2
				r.h=2
			end
		end
	end
	spawnplayer(56,90,12)
	spawnentity({"hrtbeat"})
	-- init runs once
	killentity(ent)
end
defineupdatesystem({"init"},usinit)

usanimspr=function(ent)
	local c=getentcomps(ent)
	if c.obj.active then
	 c.aspr.ticks+=1
	 if c.aspr.ticks>c.aspr.ticks_per_frame then
	  if c.aspr.anim=="cycle" then
	   c.aspr.cur_frame=cycle(
	    c.aspr.cur_frame,1,
	    #c.aspr.frames)
	  end
	  c.aspr.ticks=0
	 end
	end
end
defineupdatesystem({"obj","aspr"
 },usanimspr)

usplrcontrol=function(ent)
	local c=getentcomps(ent)
	
	if not c.sfx.flag then
		sfx(c.sfx.id)
		c.sfx.flag=true
	end
	
	if c.obj.hp<=0 then
		sfx(5)
		local cp=spawngent({"circpars"
			,"pos"})
		local cc=getentcomps(cp)
		cc.pos.x=c.pos.x+8
		cc.pos.y=c.pos.y+8
		cc.pos.z=c.pos.z
		local rp=spawngent({"particles"
			,"pos"})
		local rc=getentcomps(rp)
		rc.pos.x=c.pos.x+8
		rc.pos.y=c.pos.y+8
		rc.pos.z=c.pos.z+0.1
		rc.particles.emit=10
		rc.particles.life=15
		rc.particles.spd=30
		sfx(0,-2)
		killentity(ent)
		return
	end

	local mvx=0
 local mvy=0
 local strf=false
 local moved=true
 local prevdir=c.dir.d

	if btn(⬆️) then
		if btn(➡️) then c.dir.d=2
		elseif btn(⬅️) then c.dir.d=8
		else c.dir.d=1 end	
	elseif btn(⬇️) then
		if btn(⬅️) then c.dir.d=6
		elseif btn(➡️) then c.dir.d=4
		else c.dir.d=5 end
	elseif btn(➡️) then c.dir.d=3
	elseif btn(⬅️) then c.dir.d=7
	else
		moved=false
	end
	if btn(🅾️) then strf=true end
	c.gatling.trig=btn(❎)
	
	if moved then
		mvx=dir_2_vec[c.dir.d][1]
		mvy=dir_2_vec[c.dir.d][2]
	end
	if strf then
		c.dir.d=prevdir
	end

	local h=c.hover
	if mvx~=0 then
		h.vel[1]+=mvx*h.acc*dt30
		h.vel[1]=cap_abs(h.vel[1],
			h.acc)
	else
	 h.vel[1]-=h.acc*h.vel[1]*dt30
	end
	if mvy~=0 then
		h.vel[2]+=mvy*h.acc*dt30
		h.vel[2]=cap_abs(h.vel[2],
			h.acc)
	else
	 h.vel[2]-=h.acc*h.vel[2]*dt30
	end
	if h.vel[1]~=0 and
			abs(h.vel[1])<0.05 then
		h.vel[1]=0.0 end
	if h.vel[2]~=0 and
			abs(h.vel[2])<0.05 then
		h.vel[2]=0.0 end
	local p=c.pos
	p.x+=h.spd*h.vel[1]*dt30
	p.y+=h.spd*h.vel[2]*dt30
	if p.x<0 or p.x>128-16 then
		h.vel[1]=0
	end
	if p.y<0 or p.y>128-16 then
		h.vel[2]=0
	end
	p.x=cap(p.x,0,128-16)
	p.y=cap(p.y,0,128-16)
end
defineupdatesystem({"player",
 "dir","hover"},usplrcontrol)

usisoplink=function(ent)
	local c=getentcomps(ent)
	if isdeadentity(
			c.isoplink.parent) then
		killentity(ent)
		return
	end
	local cp=getentcomps(
		c.isoplink.parent)
	if c.isoplink.dir==cp.dir.d
			then
		c.obj.active=true
		c.obj.visible=true
	else
		c.obj.active=false
		c.obj.visible=false
	end
end
defineupdatesystem({"isoplink",
	"obj"},usisoplink)

usgatlingfire=function(ent)
	local c=getentcomps(ent)
	if c.gatling.ticks>0 then
		c.gatling.ticks-=1
	elseif c.gatling.trig then
		local g=c.gatling
		local p=c.pos
		g.ticks=g.cooldown
		local m=dir_2_vec[c.dir.d]
		m={m[1],m[2],0}
		m=v3norm(m)
		local b=spawngent({"bullet",
			"pos","aspr","dir","collid",
			"collshp","damage"})
		local cb=getentcomps(b)
		cb.bullet.speed=100+rnd(10)
		cb.bullet.type=g.projtype
		cb.bullet.damage=2
		cb.bullet.aoe=2
		cb.bullet.vel=v3muln(
				m,cb.bullet.speed+v2mag(
				c.hover.vel))
		cb.aspr.frames={16,32}
		cb.aspr.ticks_per_frame=0
		cb.pos.x=c.pos.x+g.hx
		cb.pos.y=c.pos.y+g.hy
		cb.pos.z=c.pos.z-0.1
		cb.dir.d=c.dir.d
		sfx(g.projsnd)
		cb.collid.ent=b
		cb.collid.dyn=1
		cb.collid.lyr=g.lyr
		cb.collshp.typ=shp_rect
		cb.collshp.w=2
		cb.collshp.h=2
	end
end
defineupdatesystem({"gatling",
	"pos","dir","hover"},
	usgatlingfire)

usmachgun=function(ent)
	local c=getentcomps(ent)
	if c.machgun.ticks>0 then
		c.machgun.ticks-=1
	elseif c.machgun.trig then
		local g=c.machgun
		local p=c.pos
		local d=v3norm(c.dir)
		g.ticks=g.cooldown
		local b=spawngent({"bullet",
			"pos","aspr","dir","collid",
			"collshp","damage"})
		local cb=getentcomps(b)
		cb.bullet.speed=70+rnd(10)
		cb.bullet.type=g.projtype
		cb.bullet.damage=1
		cb.bullet.vel=v3muln(
				d,cb.bullet.speed)
		cb.aspr.frames={48}
		cb.aspr.ticks_per_frame=0
		cb.pos.x=c.pos.x+g.hx
		cb.pos.y=c.pos.y+g.hy
		cb.pos.z=c.pos.z+0.1
		cb.dir.d=0
		cb.dir.x=c.dir.x
		cb.dir.y=c.dir.y
		cb.dir.z=c.dir.z
		sfx(g.projsnd)
		cb.collid.ent=b
		cb.collid.dyn=1
		cb.collid.lyr=g.lyr
		cb.collshp.typ=shp_rect
		cb.collshp.w=2
		cb.collshp.h=2
	end
end
defineupdatesystem({"machgun",
	"pos","dir"},usmachgun)

usbullet=function(ent)
	local c=getentcomps(ent)
	if not c.obj.active then
		return
	end 
	if c.pos.z<0 or c.pos.z>25 then
		local e=spawngent({"pos",
			"particles"})
		local ep=getentcomp(e,"pos")
		ep.x=c.pos.x+1
		ep.y=c.pos.y+1
		killentity(ent)
	end
	local vel=c.bullet.vel
	local acc=c.bullet.acc
	vel=v3muln(
		v3norm(
			v3add(vel,acc)),
		c.bullet.speed)
	local dz=c.pos.z
	c.pos.z+=vel[3]*dt30
	dz=c.pos.z-dz
	c.pos.x+=vel[1]*dt30
	c.pos.y+=vel[2]*dt30-dz
	if c.pos.x<0 or c.pos.x>127 or
			c.pos.y<0 or c.pos.y>127 then
		killentity(ent)
	end
end
defineupdatesystem({"bullet",
	"pos","dir"},usbullet)

usparticles=function(ent)
	local c=getentcomps(ent)
	if c.obj.active then
		local p=c.particles
		if p.emit>0 then
			-- emit
			for i=1,p.emit do
				add(p.pars,particles_emit(
					c.pos,p))
			end
			p.emit=0
		else
			local rmn=0
			-- {p,v,par.life,par.col}
			for i=1,#p.pars do
				if p.pars[i][3]>0 then
					rmn+=1
					p.pars[i][3]-=1
					local pp=p.pars[i][1]
					local pv=p.pars[i][2]
					p.pars[i][1]=v2add(pp,
						v2muln(pv,dt30))
					p.pars[i][1][3]=0
				end
			end
			if rmn==0 then
				killentity(ent)
			end
		end
	end
end
defineupdatesystem({"particles",
	"pos","obj"},usparticles)

uscircpars=function(ent)
	local c=getentcomps(ent)
	if c.obj.active then
		local p=c.circpars
		if p.emit>0 then
			-- emit
			p.timer+=1
			if p.timer>=c.circpars.len/
					c.circpars.emit then
				p.timer=0
				add(p.circs,circpars_emit(
					c.pos,p))
				p.emit-=1
			end
		end
		-- {{x,y,z},rad,col,st,life}
		local cou=0
		for i in pairs(p.circs) do
			cou=1
			p.circs[i][2]-=0.5
			if p.circs[i][2]<=0 then
				p.circs[i]=nil
			end
		end
		if cou==0 then
			--killentity(ent)
		end
	end
end
defineupdatesystem({"circpars",
	"pos","obj"},uscircpars)

usenemycollision=function(ent)
	-- enemy hit something
	local c=getentcomps(ent)
	for i=1,#c.collid.evt do
	 local oe=c.collid.evt[i][1]==
	 	ent and	2 or 1
	 oe=c.collid.evt[i][oe]
	 if not isdeadentity(oe) then
			local ot=getentcomps(oe)
			if ot.damage then
				local e=spawngent({"pos",
						"particles"})
				local ep=getentcomp(e,"pos")
				ep.x=ot.pos.x+ot.collshp.x+
					ot.collshp.w/2
				ep.y=ot.pos.y+ot.collshp.y+
					ot.collshp.h/2
				ep.z=ot.pos.z
				local et=getentcomp(e,
					"particles")
				et.col=8
				sfx(2)
			end
		end
	end
end
defineupdatesystem({"enemy",
	"collid","collshp","pos"},
	usenemycollision)

usbulletcollision=function(ent)
	local c=getentcomps(ent)
	for i=1,#c.collid.evt do
		local oe=c.collid.evt[i][1]==
	 	ent and	2 or 1
	 oe=c.collid.evt[i][oe]
	 if not isdeadentity(oe) then
	 	local oc=getentcomps(oe)
	 	oc.obj.hp-=c.damage.dmg
	 	killentity(ent)
	 end
	end
end
defineupdatesystem({"bullet",
	"collid","collshp","damage"},
	usbulletcollision)

ussoldierupdate=function(ent)
	local c=getentcomps(ent)
	c.machgun.trig=false
	if c.obj.hp<=0 then
		-- spawn dead soldier
		local de=spawngent({"spr",
			"pos"})
		local dc=getentcomps(de)
		dc.pos=c.pos
		dc.spr.id=88
		dc.spr.fx=rnd(1)>0.5
		dc.spr.fy=rnd(1)>0.5
		sfx(3)
		killentity(ent)
		return
	end
	if c.soldier.st=="idle" then
		c.soldier.chgidle-=1
		if c.soldier.chgidle<=0 then
			c.soldier.chgidle=70+rnd(200)
			c.aspr.ticks=0
			local w=flr(rnd(2))+1
			if w==1 then -- idle
				c.aspr.frames={72,73}
				c.aspr.fx=false
				c.aspr.fy=false
			else -- alert
				c.aspr.cur_frame=1
				if rnd(1)>0.5 then
					c.aspr.frames={74}
				else
					c.aspr.frames={75}
				end
				c.aspr.fx=rnd(1)>0.5
				c.aspr.fy=false
			end
		end
		local plrs=collectentswith(
			{"player"})
		if #plrs>0 then
			local pc=getentcomps(plrs[1])
			if v2dist({pc.pos.x,pc.pos.y},
					{c.pos.x,c.pos.y})<
					c.soldier.range then
				c.soldier.st="atk"
				c.soldier.tgt=plrs[1]
				c.soldier.aiming=0
				c.aspr.frames=pc.pos.y<
					c.pos.y and {74} or {75}
				c.aspr.cur_frame=1
				c.aspr.fx=pc.pos.x<c.pos.x
			end
		end
	elseif c.soldier.st=="atk" then
		if c.soldier.tgt>0 and not
				isdeadentity(c.soldier.tgt)
				then
			local pc=getentcomps(
					c.soldier.tgt)
			if v2dist({pc.pos.x,pc.pos.y}
					,{c.pos.x,c.pos.y})>
					c.soldier.range then
				c.soldier.st="idle"
				c.soldier.chgidle=0
		 else
				if c.soldier.aiming<30+rnd(10)
						then
					c.soldier.aiming+=1
				else
				 local co=pc.collshp
					c.dir=v3norm({
						pc.pos.x+(co.w/2)-
						c.pos.x,
						pc.pos.y+(co.y+co.h)-
						c.pos.y,
						pc.pos.z+(co.h)-c.pos.z})
					c.machgun.trig=true
				end
			end
		else
			c.soldier.st="idle"
			c.soldier.chgidle=0
		end
	end
end
defineupdatesystem({"soldier",
	"obj"},ussoldierupdate)

ushrtbeat=function(ent)
	local ps=collectentswith({
		"player"})
	local es=collectentswith({
		"enemy"})
	local msg=nil
	local col=0
	if #es==0 then
		msg=
			"all enemies were destroyed"
		col=11
	elseif #ps==0 then
		msg=
			"all allies were killed in action"
		col=8
	end
	if msg then
		local s=spawnentity(
			{"lzyspwn"})
		local l=getentcomp(s,
			"lzyspwn")
		local en=createcomp("endscr")
		en.msg=msg
		en.col=col
		l.comps_list={"endscr"}
		l.comps_data={
			endscr=en
		}
		-- stop hover sound
		sfx(0,-2)
		killentity(ent)
	end
end
defineupdatesystem({"hrtbeat"},
	ushrtbeat)

uslzyspwn=function(ent)
	local c=getentcomp(ent,
		"lzyspwn")
	if c.ticks>0 then
		c.ticks-=1
	else
		local e=spawnentity(
			c.comps_list)
		local ec=getentcomps(e)
		for i in pairs(c.comps_data)
				do
			ec[i]=c.comps_data[i]
		end
		killentity(ent)
	end
end
defineupdatesystem({"lzyspwn"},
	uslzyspwn)

usendscr=function(ent)
	local c=getentcomp(ent,
		"endscr")
	if not c.once then
		c.once=true
		killallentities()
		local e=spawnentity({
			"endscr"})
		local ec=getentcomp(e,
			"endscr")
		ec.msg=c.msg
		ec.col=c.col
		ec.once=true
	end
end
defineupdatesystem({"endscr"},
	usendscr)

-->8
-- draw systems
dsmap = function(ent)
	local mdat=getentcomp(ent,
		"map")
 cls(mdat.bg_col)
 -- ground
 map(0,0,0,0,16,16,0)
end
definedrawsystem({"map"},dsmap)

dsspr = function(ent)
 local d=getentcomps(ent)
	local p=d.pos
	local r=d.spr
	if d.obj.visible then
	 draw.spr(r.id,p.x,p.y,p.z,r.w,
	 	r.h,r.fx,r.fy)
	end
end
definedrawsystem({"obj","pos",
 "spr"},dsspr)

dsaspr=function(ent)
 local d=getentcomps(ent)
 if d.obj.visible then
  local p=d.pos
  local s=d.aspr
  draw.spr(s.frames[s.cur_frame]
  	,p.x,p.y,p.z,s.w,s.h,s.fx,
  	s.fy)
 end
end
definedrawsystem({"obj","pos",
 "aspr"},dsaspr)

dsrspr = function(ent)
 local d=getentcomps(ent)
	local p=d.plink
 if isdeadentity(p.parent) then
 	killentity(ent)
 	return
 end
	local r=d.spr
	if p.parent and not
	  isdeadentity(p.parent) then
		local po=getentcomp(p.parent,"obj")
		local pp=getentcomp(p.parent,"pos")
		if po.visible then
		 draw.spr(r.id,pp.x+p.x,
		 	pp.y+p.y,pp.z,r.w,r.h,r.fx,
		 	r.fy)
		end
	end
end
definedrawsystem({"plink","spr"}
 ,dsrspr)

dsraspr = function(ent)
 local d=getentcomps(ent)
 if isdeadentity(d.plink.parent)
 		then
 	killentity(ent)
 	return
 end
 draw_child_aspr(d.obj,d.plink,
 	d.aspr)
end
definedrawsystem({"plink","aspr"
 ,"obj"},dsraspr)
 
dsisochildaspr = function(ent)
 local d=getentcomps(ent)
 if isdeadentity(
 		d.isoplink.parent) then
 	killentity(ent)
 	return
 end
 draw_child_aspr(d.obj,
 	d.isoplink,d.aspr)
end
definedrawsystem({"isoplink",
	"obj","aspr"},dsisochildaspr)

dsisospr=function(ent)
	local c=getentcomps(ent)
	local p=c.pos
	local r=c.isospr.sprs[c.dir.d]
	if c.obj.visible then
	 draw.spr(r.id,p.x,p.y,p.z,r.w,
	 	r.h,r.fx,r.fy)
	end
end
definedrawsystem({"isospr","pos"
	,"obj","dir"},dsisospr)

dsshadow=function(ent)
	local c=getentcomps(ent)
	local p=c.plink
	if isdeadentity(p.parent) then
		killentity(ent)
		return
	end
	local r=c.shadow
	r.f=1-r.f
	if r.f==1 then
		if p.parent and not
		  isdeadentity(p.parent) then
			local po=getentcomp(p.parent,
				"obj")
			local pp=getentcomp(p.parent,
				"pos")
			if po.visible then
			 draw.spr(r.sid,pp.x,
			 	pp.y+pp.z,pp.z-0.1,r.w,r.h,
			 	r.fx,r.fy)
			end
		end
	end
end
definedrawsystem({"plink",
	"shadow"},dsshadow)

dsisoshadow=function(ent)
	local c=getentcomps(ent)
	local p=c.plink
	if isdeadentity(p.parent) then
		killentity(ent)
		return
	end
	local pac=getentcomp(p.parent,
		"dir")
	local r=c.isoshadow.sprs[pac.d]
	c.isoshadow.f=1-c.isoshadow.f
	if c.isoshadow.f==1 then
		if p.parent and not
		  isdeadentity(p.parent) then
			local po=getentcomp(p.parent,
				"obj")
			local pp=getentcomp(p.parent,
				"pos")
			if po.visible then
			 draw.spr(r.id,pp.x,pp.y+pp.z
			 	,pp.z-0.1,r.w,r.h,r.fx,
			 	r.fy)
			end
		end
	end
end
definedrawsystem({"plink",
	"isoshadow"},dsisoshadow)

dsparticles=function(ent)
	local c=getentcomps(ent)
	if c.obj.visible then
		local p=c.particles
		local ps={}
		for i=1,#p.pars do
			if p.pars[i][3]>0 then
				local pp=p.pars[i][1]
				add(ps,{pp[1],pp[2],pp[3],
						p.pars[i][4]})
			end
		end
		if #ps>0 then
			draw.pnts(ps,c.pos.z)
		end
	end
end
definedrawsystem({"particles",
	"pos","obj"},dsparticles)

dscircpars=function(ent)
	local c=getentcomps(ent)
	local p=c.circpars
	-- {{x,y,z},rad,col,st,life}
	for i in pairs(p.circs) do
		draw.circ(
			{c.pos.x+rnd(4)-2,
			 c.pos.y+rnd(4)-2,c.pos.z},
			p.circs[i][2],
			p.circs[i][3])
	end
end
definedrawsystem({"circpars",
	"pos","obj"},dscircpars)

dsendscr=function(ent)
	local c=getentcomp(ent,
		"endscr")
	cls(1)
	local px=64-(#c.msg*2)
	print(c.msg,px,50,c.col)
end
definedrawsystem({"endscr"},
	dsendscr)

-->8
-- main

-- entities
ents={
 e_init=spawnentity({"init"}),
 e_map=spawnentity({"map"})
}

enable_dbg=false
enable_dbg_id=false

function debugdraw_collisions()
	local ents=collectentswith({
		"pos","collid","collshp"})
	local c=nil
	local p=nil
	local s=nil
	local col=7
	local h=0
	for i=1,#ents do
		c=getentcomps(ents[i])
		p=c.pos
		s=c.collshp
		if c.collid.lyr==lyr_plr then
			col=12
		else col=8 end
		if s.typ==shp_point then
			pset(p.x,p.y-p.z,col)
		elseif s.typ==shp_rect then
			rect(p.x+s.x,p.y+s.y,
				p.x+s.x+s.w,p.y+s.y+s.h,col)
		elseif s.typ==shp_circ then
			circ(p.x+s.w/2,
			 p.y-p.z+s.w/2,s.w/2,col)
		end
		-- health
		if c.obj then
			h=flr(4*max(c.obj.hp,0)/
				c.obj.fulhp)
			line(p.x-1,p.y-1,p.x-1+4,
				p.y-1,8)
			if h>0 then
				line(p.x-1,p.y-1,p.x-1+h,
					p.y-1,7)
			end
		end
		if c.pos then
			-- id
			if enable_dbg_id then
				print(ents[i],p.x-4,p.y)
			end
		end
	end
end

function _init()
 -- enable kb in
	poke(0x5f2d,0x1)
end

function _update()
	updatecollisions()
	updateecs()
	if stat(30) then
		local c=stat(31)
		if c=="d"
			then enable_dbg=not enable_dbg
		elseif c=="e"
		 then enable_dbg_id=not
		 	enable_dbg_id
		end
	end
end

function _draw()
	drawecs()
	drawlist()
	if enable_dbg then
		debugdraw_collisions()
		print(countliveents(),121,0)
	end
end
-- utils
table={}
function table.insert (list, pos, value)
  assert(type(list) == 'table', "bad argument #1 to 'insert' "
    .."(table expected, got "..type(list)..")")
  if pos and not value then
    value = pos
    pos = #list + 1
  else
    assert(type(pos) == 'number', "bad argument #2 to 'insert' "
      .."(number expected, got "..type(pos)..")")
  end
  if pos <= #list then
    for i = #list, pos, -1 do
      list[i + 1] = list[i]
    end
  end
  list[pos] = value
end

function table.remove(list, pos)
  assert(type(list) == 'table', "bad argument #1 to 'remove' "
    .."(table expected, got "..type(list)..")")
  if not pos then
    pos = #list
  else
    assert(type(pos) == 'number', "bad argument #2 to 'remove' "
      .."(number expected, got "..type(tbl)..")")
  end
  for i = pos, #list do
    list[i] = list[i + 1]
  end
end

function table.sort (arr, comp)
  if not comp then
    comp = function (a, b)
      return a < b
    end
  end
  local function partition (a, lo, hi)
      pivot = a[hi]
      i = lo - 1
      for j = lo, hi - 1 do
        if comp(a[j], pivot) then
          i = i + 1
          a[i], a[j] = a[j], a[i]
        end
      end
      a[i + 1], a[hi] = a[hi], a[i + 1]
      return i + 1
    end
  local function quicksort (a, lo, hi)
    if lo < hi then
      p = partition(a, lo, hi)
      quicksort(a, lo, p - 1)
      return quicksort(a, p + 1, hi)
    end
  end
  return quicksort(arr, 1, #arr)
end

--- caps v to be between mn,mx
function cap(v,mn,mx)
	if v<mn then v=mn end
	if v>mx then v=mx end
	return v
end

-- inc's v,back to mn if >mx
function cycle(v,mn,mx)
 v+=1
 if v>mx then v=mn end
 return v
end

-- easings
ease={}
ease["in"]={
	expo=function(x)
		if x<=0.01 then
			return 0
		else
			return 2^(10*x-10) 
		end
	end
}
ease["out"]={}
-->8
-- ** ecs **
-- ecsentity: eid = {comps = comps_list, cdata = comps_data}
-- ecsdeadentities: {eid1, .. }
-- ecscomponent: { name = { data }, .. }
-- ecssystem: { {proc, ent_bucket}, .. }
-- ecsbucketslist: { bucket_id = comps_list, .. }
-- ecsbucket: { bucket_id = {ent0id, ent1id, ..}, bucket_id = {ent2id, ent5id, ..}, .. }

ecsentityid = 1
ecsbucketid = 1
ecsentities = {}
ecsdeadentities = {}
ecscomponents = {}
ecsusystems = {}
ecsdsystems = {}
ecsbucketslist = {}
ecsbuckets = {} 

function ecsnextentityid()
	ecsentityid = ecsentityid + 1
	return ecsentityid - 1
end

function ecsnextbucketid()
	ecsbucketid = ecsbucketid + 1
	return ecsbucketid - 1
end 

-- returns existing bucket or new one
function ecsgetbucket(comps_list)
	local i, bl, found 
	local buckid = nil
	for i, c in ipairs(ecsbucketslist) do 
		if ecscompeq(comps_list, c) then 
			buckid = i
			break
		end 
	end 
	if buckid == nil then 
		buckid = ecsnextbucketid()
		ecsbuckets[buckid] = {}
		ecsbucketslist[buckid] = comps_list
	end
	return ecsbuckets[buckid]
end 

-- get all compatible buckets to passed components list
function ecsgetcompatbuckets(comps_list)
	local buckids = {}
	for i, c in ipairs(ecsbucketslist) do 
		if ecscompin(c, comps_list) then 
			add(buckids, i) 
		end
	end 
	return buckids
end 

-- compare two component lists for exact match (non-sorted)
function ecscompeq(comp1, comp2)
	if #comp1 ~= #comp2 then return false end 
	for i = 1, #comp1 do
		if comp1[i] ~= comp2[i] then 
			return false 
		end 
	end 
	return true
end 

function ecscompeqsort(comp1, comp2)
	table.sort(comp1)
	table.sort(comp2)
	return ecscompequal(comp1,comp2)
end

function ecscreatecomp(comp)
	local newcomp = {}
	for i, v in pairs(comp) do 
		newcomp[i] = v 
	end
	return newcomp
end 

-- return true if subset is in set
function ecscompin(subset, set)
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

function ecsexecsystem(system)
	local i, e
	for i, e in ipairs(system.ent_bucket) do
		system.proc(e)
	end
end

function ecsexecsystems(systems)
	local i, s
	for i, s in ipairs(systems) do 
		ecsexecsystem(s)
	end
end

function ecsclonetable(t)
	local tt = {}
	for i, v in pairs(t) do tt[i] = v end
	return tt
end

function ecsrementfrombuckets(eid)
	local i, j
	for i=1,#ecsbuckets do
		local cb = ecsbuckets[i]
		for j=1,#cb do
			if cb[j] == eid then
				table.remove(cb, j)
				break
			end
		end
	end
end

function ecsaddenttobuckets(eid, comps_list)
	local cbucks = ecsgetcompatbuckets(comps_list)
	for i=1,#cbucks do
		table.insert(ecsbuckets[cbucks[i]], eid)
	end
end

function ecsrebucketent(eid, oldcomps, newcomps)
	ecsrementfrombuckets(eid)
	ecsaddenttobuckets(eid, newcomps)
end

function updateecs()
	ecsexecsystems(ecsusystems) 
end 

function drawecs()
	ecsexecsystems(ecsdsystems)
end

function definecomponent(name, comp_data) 
	assert(name, comp_data)
	ecscomponents[name] = comp_data
end 

function defineupdatesystem(comps_list, system_proc)
	assert(comps_list)
	assert(system_proc)
	table.sort(comps_list)
	local bucket = ecsgetbucket(comps_list)
	add(ecsusystems, {proc = system_proc, ent_bucket = bucket})
end 

function definedrawsystem(comps_list, system_proc)
	assert(comps_list)
	assert(system_proc)
	table.sort(comps_list)
	local bucket = ecsgetbucket(comps_list)
	add(ecsdsystems, {proc = system_proc, ent_bucket = bucket})
end

function spawnentity(comps_list)
	local eid = ecsnextentityid()
	local comps_data = {} 
	table.sort(comps_list)
	local i
	for i = 1, #comps_list do
		comps_data[comps_list[i]] = ecscreatecomp(ecscomponents[comps_list[i]])
	end 
	ecsentities[eid] = {
		comps = comps_list,
		cdata = comps_data
	}
	local cbucks = ecsgetcompatbuckets(comps_list)
	for i = 1, #cbucks do
		add(ecsbuckets[cbucks[i]], eid)
	end 
	return eid
end

-- returns a dict of comp->data
function getentcomps(eid)
	assert(eid)
	return ecsentities[eid].cdata
end

-- returns dict of component data
function getentcomp(eid, comp_name)
	assert(eid)
	assert(comp_name)
	return ecsentities[eid].cdata[comp_name]
end

-- adds new comp to entity, 1 comp/name
function entaddcomp(eid, comp_name)
	assert(not ecsentities[eid].cdata[comp_name] and ecscomponents[comp_name])
	oldcomps = getentcomps(eid)
	newcomps = ecsclonetable(oldcomps)
	table.insert(newcomps, comp_name)
	table.sort(newcomps)
	ecsentities[eid].comps = newcomps
	ecsentities[eid].cdata[comp_name] = ecscreatecomp(ecscomponents[comp_name])
	ecsrebucketent(eid, oldcomps, newcomps)
end

-- removes component from entity
function entremcomp(eid, comp_name)
	assert(ecsentities[eid].cdata[comp_name])
	oldcomps = getentcomps(eid)
	newcomps = ecsclonetable(oldcomps)
	for i=1,#newcomps do
		if newcomps[i] == comp_name then
			table.remove(newcomps, i)
			break
		end
	end
	ecsentities[eid].comps = newcomps
	ecsentities[eid].cdata[comp_name] = nil
	ecsrebucketent(eid, oldcomps, newcomps)
end

function killentity(eid)
	ecsrementfrombuckets(eid)
	ecsentities[eid] = nil
	table.insert(ecsdeadentities, eid)
end 

function killallentities()
	local i, j
	for i=1,#ecsbuckets do
		ecsbuckets[i] = {}
	end
	for i=1,#ecsentities do
		table.insert(ecsdeadentities, ecsentities[i])
	end
	ecsentities = {}
end

function isdeadentity(eid)
	for i=1,#ecsdeadentities do
		if ecsdeadentities[i] == eid then
			return true
		end
	end
	return false
end

-- create a comp as data
function createcomp(comp_name)
	for cn in pairs(ecscomponents) do
		if cn == comp_name then
			return ecscreatecomp(ecscomponents[cn])
		end
	end
	assert(false) -- bad comp name
end

-->8
-- components

--- init: init once at start
cinit={}
definecomponent("init",cinit)

--- map: map drawing and spawn
cmap={
	bg_col=3
}
definecomponent("map",cmap)

--- pos: world pos
cpos={
	x=0,y=0,z=0
}
definecomponent("pos",cpos)

--- spr: static sprite draw
cspr={
	id=1,w=1,h=1,fx=false,fy=false
}
definecomponent("spr",cspr)

--- obj: game object
cobj={
 active=true, -- update?
 visible=true,-- draw?
 hp=1         -- dead if zero
}
definecomponent("obj",cobj)

--- aspr: animated sprite draw
caspr={
 anim="cycle",
 w=1,h=1,
 frames={1},
 cur_frame=1,
 ticks_per_frame=15,
 ticks=0,
 fx=false,fy=false
}
definecomponent("aspr",caspr)

--- plink: link to parent
cplink={
	parent=nil,
	x=0,y=0,z=0
}
definecomponent("plink",cplink)

--- dir: a direction from 1..8
cdir={ d=1 }
definecomponent("dir",cdir)

--- isospr: isometric spr
cisospr={ sprs={} }
definecomponent("isospr",
	cisospr)

--- isoplink: isometric parent
---  only active if dir match
cisoplink={
	parent=nil,
	x=0,y=0,z=0,
	dir=1
}
definecomponent("isoplink",
	cisoplink)

--- player: player control
cplayer={}
definecomponent("player",cplayer
	)

--- shadow: spr shadow
cshadow={
	f=0,sid=1,w=1,h=1,fx=1,fy=1
}
definecomponent("shadow",cshadow
	)

--- isoshadow: isospr shadow
cisoshadow={
	f=0,sprs={}
}
definecomponent("isoshadow",
	cisoshadow)

--- hover: hoverable entity
chover={
	acc=2,
	vel={0,0},
	spd=25,
	drg=0.9
}
definecomponent("hover",chover)

--- sfx: sound with bool flag
csfx={id=0,flag=false}
definecomponent("sfx",csfx)

--- colrct: collision rect
ccolrct={x=0,y=0,h=8,w=8}
definecomponent("colrct",
	ccolrct)

-- gatling: projectiles weapon
cgatling={
	trig=false,
 projtype="exp",
 projsnd=1,
	cooldown=15,
	ticks=0,
	hx=8,hy=8 -- hotspot
}
definecomponent("gatling",
	cgatling)

-- bullet: kinetic projectile
cbullet={
	speed=30,
	zacc=-9,
	type="exp",
	damage=2,
	aoe=2
}
definecomponent("bullet",
	cbullet)

-->8
-- system funcs

--- frametime for 30hz
local dt30=1/30
--- converts 1..8 dir to 2d-vec
local dir_2_vec={
	{0,-1},{1,-1},{1,0},{1,1},
	{0,1},{-1,1},{-1,0},{-1,-1}
}

--- spawns entity with obj comp
function spawngent(comps)
 add(comps,"obj")
	return spawnentity(comps)
end

-- spawns spr shadow entity
function spawnshadow(parent,
		sid,sz,fx,fy)
	local sh=spawnentity({"plink",
		"shadow"})
	local c=getentcomps(sh)
	c.plink.parent=parent
	c.shadow.sid=sid
	c.shadow.w=sz or 1
	c.shadow.h=sz or 1
	c.shadow.fx=fx or false
	c.shadow.fy=fy or false
end

function spawnisoshadow(parent,
		sprs)
	assert(#sprs==8)
	local sh=spawnentity({"plink",
		"isoshadow"})
	local c=getentcomps(sh)
	c.plink.parent=parent
	c.isoshadow.sprs=sprs
end

--- spawns player hover
function spawnplayer(x,y,z)
	-- hover
	local plr=spawngent({"isospr",
		"dir","pos","player","hover",
		"sfx","gatling"})
	local gat=getentcomp(plr,
		"gatling")
	gat.projtype="exp"
	gat.projsnd=1
	gat.cooldown=5
	local p=getentcomp(plr,"pos")
	local ias=getentcomp(plr,
		"isospr")
	local idr=getentcomp(plr,"dir")
	p.x=x
	p.y=y
	p.z=z
	idr.d=1
	-- sprid,shadid,lrotpos,
 --  rrotpos,crotpos,flipx
	local init_fan = function(
	 pos,dir,frames,sz)
	  sz=sz or 1
	  local f=spawngent({"isoplink"
	  	,"aspr"})
	  local fc=getentcomps(f)
	  fc.isoplink.parent=plr
	  fc.isoplink.x=pos[1]
	  fc.isoplink.y=pos[2]
	  fc.isoplink.dir=dir
	  fc.aspr.frames=frames
	  fc.aspr.ticks_per_frame=0
	  fc.aspr.w=sz
	  fc.aspr.h=sz
	  return fc
	 end
 local init_dir=function(dir,d)
 	-- base sprite
 	local sd=createcomp("spr")
 	sd.id=d[1]
 	sd.w=2
 	sd.h=2
 	sd.fx=d[6]==1
 	sd.fy=false
 	ias.sprs[dir]=sd
 	-- rotors
 	init_fan(d[3],dir,{9,10,11})
		init_fan(d[4],dir,{25,26,27})
		init_fan(d[5],dir,{41,42,43})
 	-- shadow todo
 	spawnisoshadow(plr,{
			{id=128,w=2,h=2,fx=false,fy=false},
			{id=130,w=2,h=2,fx=false,fy=false},
			{id=132,w=2,h=2,fx=false,fy=false},
			{id=162,w=2,h=2,fx=false,fy=false},
			{id=160,w=2,h=2,fx=false,fy=false},
			{id=162,w=2,h=2,fx=true,fy=false},
			{id=132,w=2,h=2,fx=true,fy=false},
			{id=130,w=2,h=2,fx=true,fy=false}})
 end
	local data={ -- 1..8 direction
		{1,128,{1,7},{12,7},{6,10},0},
	 {3,130,{4,5},{12,11},{1,9},0},
  {5,132,{9,4},{9,12},{1,5},0},
  {35,162,{12,6},{3,12},{1,2},0},
  {33,160,{1,8},{12,8},{6,2},0},
  {35,162,{16-3-12,6},{16-3-3,12},
  	{16-4-1,2},1},
  {5,132,{16-3-9,4},{16-3-9,12},
  	{16-4-1,5},1},
  {3,130,{16-3-4,5},{16-3-12,11},
  	{16-4-1,9},1}
	}
	for i=1,#data do
		init_dir(i,data[i])
	end
	return plr
end

-- drawlist singleton system
draw={}
draw.t_spr=1
draw.list={}

-- sorting comparator
draw.sortcomp=function(a,b)
	if a[3].z~=b[3].z then
		return a[3].z<b[3].z
	else
		return a[3].y<b[3].y
	end
end

draw.spr=function(n,x,y,z,w,h,
		flip_x,flip_y)
	add(draw.list,{draw.t_spr,
		{n=n,w=w,h=h,fx=flip_x,
		fy=flip_y},{x=x,y=y,z=z}})
end

--- draws all and clears list
draw.exec=function()
	table.sort(draw.list,
		draw.sortcomp)
	for i=1,#draw.list do
		local t=draw.list[i][1]
		local d=draw.list[i][2]
		local p=draw.list[i][3]
		if t==draw.t_spr then
			spr(d.n,p.x,p.y,d.w,d.h,d.fx,
				d.fy)
		end
	end
	draw.list={}
end
function drawlist()
	return draw.exec()
end

-- draws aspr child (has plink)
function draw_child_aspr(obj,
		link,aspr)
	if obj.visible then
		local p=link
		local r=aspr
		if p.parent and not
		  isdeadentity(p.parent) then
			local po=getentcomp(p.parent,
			 "obj")
			local pp=getentcomp(p.parent,
			 "pos")
			if po.visible then
			 draw.spr(
			 	r.frames[r.cur_frame],
			 	pp.x+p.x,pp.y+p.y,pp.z,
			 	r.w,r.h,
			  r.fx,r.fy)
			end
		end
	end
end
-->8
-- update systems
--- init demo
usinit = function(ent)
 -- map spawner
	for y=0,15 do
		for x=0,15 do
			local v=mget(x,y+16)
			if v==72 then
				-- soldier
				local s=spawngent({"pos","aspr"})
				local p=getentcomp(s,"pos")
				p.x=x*8
				p.y=y*8
				local r=getentcomp(s,"aspr")
				r.frames={72,73}
			elseif v==70 then
				-- building
				local s=spawngent({"pos","spr"})
				local p=getentcomp(s,"pos")
				p.x=x*8
				p.y=y*8
				local r=getentcomp(s,"spr")
				r.id=v
				r.w=2
				r.h=2
			end
		end
	end
	spawnplayer(56,90,10)
	-- init runs once
	killentity(ent)
end
defineupdatesystem({"init"},usinit)

usanimspr=function(ent)
	local c=getentcomps(ent)
	if c.obj.active then
	 c.aspr.ticks+=1
	 if c.aspr.ticks>c.aspr.ticks_per_frame then
	  if c.aspr.anim=="cycle" then
	   c.aspr.cur_frame=cycle(
	    c.aspr.cur_frame,1,
	    #c.aspr.frames)
	  end
	  c.aspr.ticks=0
	 end
	end
end
defineupdatesystem({"obj","aspr"
 },usanimspr)

usplrcontrol=function(ent)
	local c=getentcomps(ent)
	
	if not c.sfx.flag then
		sfx(c.sfx.id)
	end

	local mvx=0
 local mvy=0
 local strf=false
 local moved=true
 local prevdir=c.dir.d

	if btn(⬆️) then
		if btn(➡️) then c.dir.d=2
		elseif btn(⬅️) then c.dir.d=8
		else c.dir.d=1 end	
	elseif btn(⬇️) then
		if btn(⬅️) then c.dir.d=6
		elseif btn(➡️) then c.dir.d=4
		else c.dir.d=5 end
	elseif btn(➡️) then c.dir.d=3
	elseif btn(⬅️) then c.dir.d=7
	else
		moved=false
	end
	if btn(🅾️) then strf=true end
	c.gatling.trig=btn(❎)
	
	if moved then
		mvx=dir_2_vec[c.dir.d][1]
		mvy=dir_2_vec[c.dir.d][2]
	end
	if strf then
		c.dir.d=prevdir
	end

	local h=c.hover
	if mvx~=0 then
		h.vel[1]=mvx*h.acc
	else
	 h.vel[1]=h.drg*h.vel[1]
	end
	if mvy~=0 then
		h.vel[2]=mvy*h.acc
	else
	 h.vel[2]=h.drg*h.vel[2]
	end
	if h.vel[1]~=0 and
			abs(h.vel[1])<0.05 then
		h.vel[1]=0.0 end
	if h.vel[2]~=0 and
			abs(h.vel[2])<0.05 then
		h.vel[2]=0.0 end
	local p=c.pos
	p.x+=h.spd*h.vel[1]*dt30
	p.y+=h.spd*h.vel[2]*dt30
	p.x=cap(p.x,0,128-16)
	p.y=cap(p.y,0,128-16)
end
defineupdatesystem({"player",
 "dir","hover"},usplrcontrol)

usisoplink=function(ent)
	local c=getentcomps(ent)
	local cp=getentcomps(
		c.isoplink.parent)
	if c.isoplink.dir==cp.dir.d
			then
		c.obj.active=true
		c.obj.visible=true
	else
		c.obj.active=false
		c.obj.visible=false
	end
end
defineupdatesystem({"isoplink",
	"obj"},usisoplink)

usgatlingfire=function(ent)
	local c=getentcomps(ent)
	if c.gatling.ticks>0 then
		c.gatling.ticks-=1
	elseif c.gatling.trig then
		local g=c.gatling
		local p=c.pos
		g.ticks=g.cooldown
		local b=spawngent({"bullet",
			"pos","aspr","dir"})
		local cb=getentcomps(b)
		cb.bullet.speed=68+rnd(10)
		cb.bullet.zacc=-15+rnd(5)
		cb.bullet.type=g.projtype
		cb.bullet.damage=2
		cb.bullet.aoe=2
		cb.aspr.frames={16,32}
		cb.aspr.ticks_per_frame=0
		cb.pos.x=c.pos.x+g.hx
		cb.pos.y=c.pos.y+g.hy
		cb.pos.z=c.pos.z-0.1
		cb.dir.d=c.dir.d
		sfx(g.projsnd)
	end
end
defineupdatesystem({"gatling",
	"pos","dir"},usgatlingfire)

usbullet=function(ent)
	local c=getentcomps(ent)
	local m=dir_2_vec[c.dir.d]
	local mag=sqrt(m[1]*m[1]+m[2]*
		m[2])
	local newz=c.pos.z+(
		c.bullet.zacc*dt30)
	local dz=abs(c.pos.z-newz)
	c.pos.x=c.pos.x+m[1]*
		c.bullet.speed*dt30/mag
	c.pos.y=c.pos.y+dz+m[2]*
		c.bullet.speed*dt30/mag
	c.pos.z=newz
	if c.pos.x<0 or c.pos.x>127 or
			c.pos.y<0 or c.pos.y>127 then
		killentity(ent)
	end
	if c.pos.z<=0 then
		-- todo explosion area damage
		killentity(ent)
	end
end
defineupdatesystem({"bullet",
	"pos","dir"},usbullet)

-->8
-- draw systems
dsmap = function(ent)
	local mdat=getentcomp(ent,"map")
 cls(mdat.bg_col)
 -- ground
 map(0,0,0,0,16,16,0)
 -- static objects
	--map(0,17,0,0,16,16,1)
end
definedrawsystem({"map"},dsmap)

dsspr = function(ent)
 local d=getentcomps(ent)
	local p=d.pos
	local r=d.spr
	if d.obj.visible then
	 draw.spr(r.id,p.x,p.y,p.z,r.w,
	 	r.h,r.fx,r.fy)
	end
end
definedrawsystem({"obj","pos",
 "spr"},dsspr)

dsaspr=function(ent)
 local d=getentcomps(ent)
 if d.obj.visible then
  local p=d.pos
  local s=d.aspr
  draw.spr(s.frames[s.cur_frame]
  	,p.x,p.y,p.z,s.w,s.h,s.fx,
  	s.fy)
 end
end
definedrawsystem({"obj","pos",
 "aspr"},dsaspr)

dsrspr = function(ent)
 local d=getentcomps(ent)
	local p=d.plink
	local r=d.spr
	if p.parent and not
	  isdeadentity(p.parent) then
		local po=getentcomp(p.parent,"obj")
		local pp=getentcomp(p.parent,"pos")
		if po.visible then
		 draw.spr(r.id,pp.x+p.x,
		 	pp.y+p.y,pp.z,r.w,r.h,r.fx,
		 	r.fy)
		end
	end
end
definedrawsystem({"plink","spr"}
 ,dsrspr)

dsraspr = function(ent)
 local d=getentcomps(ent)
 draw_child_aspr(d.obj,d.plink,
 	d.aspr)
end
definedrawsystem({"plink","aspr"
 ,"obj"},dsraspr)
 
dsisochildaspr = function(ent)
 local d=getentcomps(ent)
 draw_child_aspr(d.obj,
 	d.isoplink,d.aspr)
end
definedrawsystem({"isoplink",
	"obj","aspr"},dsisochildaspr)

dsisospr=function(ent)
	local c=getentcomps(ent)
	local p=c.pos
	local r=c.isospr.sprs[c.dir.d]
	if c.obj.visible then
	 draw.spr(r.id,p.x,p.y,p.z,r.w,
	 	r.h,r.fx,r.fy)
	end
end
definedrawsystem({"isospr","pos"
	,"obj","dir"},dsisospr)

dsshadow=function(ent)
	local c=getentcomps(ent)
	local p=c.plink
	local r=c.shadow
	r.f=1-r.f
	if r.f==1 then
		if p.parent and not
		  isdeadentity(p.parent) then
			local po=getentcomp(p.parent,
				"obj")
			local pp=getentcomp(p.parent,
				"pos")
			if po.visible then
			 draw.spr(r.sid,pp.x,
			 	pp.y+pp.z,pp.z-0.1,r.w,r.h,
			 	r.fx,r.fy)
			end
		end
	end
end
definedrawsystem({"plink",
	"shadow"},dsshadow)

dsisoshadow=function(ent)
	local c=getentcomps(ent)
	local p=c.plink
	local pac=getentcomp(p.parent,
		"dir")
	local r=c.isoshadow.sprs[pac.d]
	c.isoshadow.f=1-c.isoshadow.f
	if c.isoshadow.f==1 then
		if p.parent and not
		  isdeadentity(p.parent) then
			local po=getentcomp(p.parent,
				"obj")
			local pp=getentcomp(p.parent,
				"pos")
			if po.visible then
			 draw.spr(r.id,pp.x,pp.y+pp.z
			 	,pp.z-0.1,r.w,r.h,r.fx,
			 	r.fy)
			end
		end
	end
end
definedrawsystem({"plink",
	"isoshadow"},dsisoshadow)

-->8
-- main

-- entities
ents={
 e_init=spawnentity({"init"}),
 e_map=spawnentity({"map"})
}

function _init()
end

function _update()
	updateecs()
end

function _draw()
	cls(3)
	drawecs()
	drawlist()
end