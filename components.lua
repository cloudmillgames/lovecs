-- ** COMPONENTS **

-- Start game screen
CInitStart = {}
ECS:DefineComponent("initstart", CInitStart)

-- Used to init game, should remove itself when run
CInitGame = {}
ECS:DefineComponent("initgame", CInitGame)

-- a direction of 4: 1 (up), 2 (right), 3(down), 4 (left)
CDir = {
	dir = 1
}
ECS:DefineComponent("dir", CDir)

-- a string
CText = {
	text = "",
	scale = 1
}
ECS:DefineComponent("text", CText)

-- an image that gets drawn
CImg = {
	name="",
	orient=0.0,
	scalex=1,
	scaley=1
}
ECS:DefineComponent("img", CImg)

-- identify entity as player
CPlayer = {}
ECS:DefineComponent("player", CPlayer)

-- indicates a player death event
CPlayerDeath = {
	cooldown = 2.0	-- Respawn cooldown time
}
ECS:DefineComponent("playerdeath", CPlayerDeath)

-- identify entity as enemy
CEnemy = {
}
ECS:DefineComponent("enemy", CEnemy)

-- identify shell as players
CPlayerShell = {
}
ECS:DefineComponent("playershell", CPlayerShell)

-- A single frame sprite
CSpr = {
	spritesheet="",
	spriteid=1,
	orient = 0.0,
	scalex = 1,
	scaley = 1,
	color = nil,
	layer = 0,
}
ECS:DefineComponent("spr", CSpr)

-- an animated sprite
CAnimSpr = {
	spritesheet="",
	curr_frame=1,
	orient=0.0,
	scalex=1,
	scaley=1,
	color=nil,
	-- Specifies range of frames in spritesheet
	frame_start = 1,-- what's first frame in spritesheet
	frame_end = -1	-- < 1 means last frame
}
ECS:DefineComponent("animspr", CAnimSpr)

-- animate sprite from first to last frame once then kills self entity
CAnimSpr_OneCycle = {
	frametime = 0.25,	-- time each frame lasts in seconds
	_timer = 0.0
}
ECS:DefineComponent("animspr_onecycle", CAnimSpr_OneCycle)

-- animate sprite pingpong number of cycles then kills self if cycles == 0
CAnimSpr_PingPong = {
	frametime = 0.25,
	_timer = 0.0,
	_direction = 1,		-- 1 or -1
	cycles = 5,			-- pingpong count, -1 forever
}
ECS:DefineComponent("animspr_pingpong", CAnimSpr_PingPong)

-- an animator for the animated sprite that cycles all frames
-- Deprecated: this counts in frames not DeltaTime
CAnimSpr_Cycle = {
	frametime=1,
	_framecount=0	-- used to count frame time
}
ECS:DefineComponent("animspr_cycle", CAnimSpr_Cycle)

-- Battlecity arena
CArenaBG = {}
ECS:DefineComponent("arena_bg", CArenaBG)

-- All tanks have this comp
CTank = {
	type = 0,			-- refers to row in tanks spritesheet
	chain_tick = 0,		-- ticks 0,1 to move chain
	chain_timer = 0,	-- counts time for chain tick
	chain_period = 0.06,-- time between chain ticks
	throttle = false,	-- true means tank should move
	speed = 30,
	moving = 0,			-- used to lock movement for TANK_STEP distance
	move_delta_x = 0,	-- used to fix tank movement to TANK_STEPs
	move_delta_y = 0,
}
ECS:DefineComponent("tank", CTank)

CMapTile = {
	type = 1,
	collmap = -1,	-- which collision map does this maptil belong to
	column = 0,		-- Where in map matrix
	row = 0
}
ECS:DefineComponent("maptile", CMapTile)

-- Clear a tile from collision map associated with a maptile via column, row
CCollisionMap_TileClear = {
	collmap = -1,
	column = 0,
	row = 0
}
ECS:DefineComponent("maptile_clear", CCollisionMap_TileClear)

CFPSCounter = {
	frame_timer = 0,
	frame_count = 0,
}
ECS:DefineComponent("fpscounter", CFPSCounter)

-- Links this entity's lifetime to a parent, it dies when parent dies
CChild = {
	parent = -1
}
ECS:DefineComponent("child", CChild)

-- Follow position of another entity with offset
CPosLink = {
	parent = 0,
	offsetx = 0,
	offsety = 0
}
ECS:DefineComponent("poslink", CPosLink)

-- Identifies entity as a collision sensor shape (used for MotionSensor)
CCollSensor = {
}
ECS:DefineComponent("collsensor", CCollSensor)

-- References 4 sensors each in the 4 cartesian directions (no diagonals)
-- Use to check whether you can move in that direction. UP RIGHT DOWN LEFT
CMotionSensor4 = {
	sensors = {}
}
ECS:DefineComponent("motionsensor4", CMotionSensor4)

-- Move an entity with position towards a specific position in given duration
CMove4 = {
	destx = 0,
	desty = 0,
	duration = 1,
    finished = false,
	_timer = 0,
	_originx = 0,
	_originy = 0
}
ECS:DefineComponent("move4", CMove4)

CBmpText = {
    text = "",
    color = nil
}
ECS:DefineComponent("bmptext", CBmpText)

CMenuCursor = {
    places = {},    -- each pair of {x,y} is a menu item, index starts at 1
    current = 1,    -- default to first place
    funcs = {},     -- What to call when Z is pressed on menu cursor
}
ECS:DefineComponent("menucursor", CMenuCursor)

-- Draws a cycling animated sprite to be used as UI cursor
CUIAnimSprite = {
    spritesheet="",
	scalex=1,
	scaley=1,
	color=nil,
	-- Specifies range of frames in spritesheet
	frames = {},
	curr_frame=1, -- Index into frames
    frametime = 0,
    _timer = 0
}
ECS:DefineComponent("uianimspr", CUIAnimSprite)

-- Set 'func' to function you want, it will be called once after delay
CDelayedFunc = {
    delay = 0,
    func = nil
}
ECS:DefineComponent("delayedfunc", CDelayedFunc)

-- Calls function when button is pressed (==1)
CButtonFunc = {
	btn_name = "z",
	func = nil,
	kill_after = -1,	-- how many runs to kill self entity after? -1 means do not kill, 1 is once
}
ECS:DefineComponent("buttonfunc", CButtonFunc)

CScreenEffect_Door = {
    duration = 1,   -- duration of door effect
    stay = 1,       -- how long does it stay after effect is over, til delete
    rect_color = nil,
    opening = false,
    _timer_duration = 0,
    _timer_stay = 0
}
ECS:DefineComponent("screeneffect_door", CScreenEffect_Door)

CTankTurret = {
	trigger = false,		-- if true turret attempts fire, reset after check to false
	cooldown = 1,
	_timer_cooldown =0,
	fire_point = {x=0, y=0},-- offset for spawning UP, directionally aware
	max_live_shells = 1,	-- how many shells allowed to be alive
	_live_shells = {}		-- shells that are alive and active
}
ECS:DefineComponent("tankturret", CTankTurret)

CProjectile = {
	speed=250,
	shooter_entity=0
}
ECS:DefineComponent("projectile", CProjectile)

COutOfBoundsKill = {
}
ECS:DefineComponent("outofbounds_kill", COutOfBoundsKill)

-- Dispatch a message (via msg_dispatcher) when given button is pressed
CMsgOnButton = {
	btn_name="z",	-- button that dispatches message
	msg="button-msg",		-- message name to dispatch
	channel=Msging.CHANNEL	-- on which channel to dispatch
}
ECS:DefineComponent("msg_on_button", CMsgOnButton)

-- Counts down time, stops if zero
CTimedown = {
	time = 0.0
}
ECS:DefineComponent("timedown", CTimedown)

-- Dispatch message when entity dies, self kill after
CKillMsg = {
	entity = 0,			-- entity to watch
	channel = Msging.CHANNEL,
	msg = "entity-died"
}
ECS:DefineComponent("killmsg", CKillMsg)

-- Call function when entity dies, self kill after
CKillFunc = {
	entity = -1,		-- entity to watch
	funcbind = nil,		-- {func=, data=}
}
ECS:DefineComponent("killfunc", CKillFunc)

-- Spawns swarm of tanks across multiple spawn zones
-- Monitors spawn zones to make sure they are clear when spawn is triggered
-- Tracks which tanks are alive and spawns more when necessary
-- Dispatches message when spawns are exhausted then kills self
CSpawnDirector = {
	active = true,		-- Spawner operates when active = true
	spawns = 20,		-- How many tanks in total the director has
	max_alive = 4,		-- How many alive units at one time from this spawner
	zones = {},			-- Each zone is 16x16 rect {x=,y=,w=,h=} guaranteed to be free of tiles
	sensors = {},		-- Zone sensors to make sure no objects are in the area when spawning
	cooldown = 2.0,		-- Minimum time between spawns
	msg_on_finish = "spawns-finished",
	msg_channel = Msging.CHANNEL,
	_timer = 0,
	_current_zone = 1,	-- Used to alternate between spawn zones
}
ECS:DefineComponent("spawndirector", CSpawnDirector)

CPlayerSpawner = {
	zones = {},			-- Each zone is 16x16 rect {x=,y=,w=,h=} guaranteed to be free of tiles
	sensors = {},		-- Zone sensors to make sure no objects are in the area when spawning
}
ECS:DefineComponent("playerspawner", CPlayerSpawner)

-- Acts as the tank controller, must be add to a tank entity
CEnemyControl = {
	change_move = {0.1, 1.0},	-- min and max time for change movement action
	move_dir = 0,				-- 0 means stationary, UP DOWN LEFT RIGHT for directions
	fire_percent = {0.8, 0.85},	-- percentage range of fire event
	dir_percent = {.05, .15, .2, .4, .2},-- percentage of 0/UP/RIGHT/DOWN/LEFT (must total 1.0)
	_move_timer = 0.0,
}
ECS:DefineComponent("enemycontrol", CEnemyControl)

-- Tags critical target
CCriticalTarget = {}
ECS:DefineComponent("criticaltarget", CCriticalTarget)

-- Critical target was destroyed
CCriticalDeath = {
	critical_target = -1	-- entity of critical target
}
ECS:DefineComponent("criticaldeath", CCriticalDeath)

CGameOver = {}
ECS:DefineComponent("gameover", CGameOver)

-- Links a data property from an entity/component to a data property in current entity/comp
CDataLink = {
	src_ecs = "ECS",-- which global ECS is source? default is game (ECS) but can be MAIN
	src_ent = -1,	-- source entity to fetch data from
	src_comp = "",	-- source component name
	src_prop = "",	-- source property that carries source value
	dest_type = "string",	-- what type to convert src_prop to?
	dest_comp = "",	-- destination comp to target
	dest_prop = "",	-- destination property where value is updated
}
ECS:DefineComponent("datalink", CDataLink)

-- Maintains an array of entities that is a given start size, when "keep" value drops it
-- deletes entities from the end of the array to reflect. Used for enemy tank count UI sprites
CEntArrKeep = {
	ent_array = {},	-- start entity array
	keep = 20		-- how many entities to keep
}
ECS:DefineComponent("entarrkeep", CEntArrKeep)

-- Used to identify enemy tanks UI so it can be fetched
CEnemyTanksUI = {}
ECS:DefineComponent("enemytanksui", CEnemyTanksUI)

----------------------------------------------------- Deprecated Components

-- Skips delayed func on a specific message by calling func immediately, needs a msg_receiver comp
CDelayedFuncSkipper = {
	skip_on = nil,	-- msg name to skip on
}
ECS:DefineComponent("delayedfunc_skipper", CDelayedFuncSkipper)

-- Calls function when message is received, requires a msg_receiver to work
-- TO IMPLEMENT
CMsgFunc = {
	msg = "func-msg",
	channel = Msging.CHANNEL,
	func = nil
}
ECS:DefineComponent("msgfunc", CMsgFunc)

-- Skips move4 component by finishing it immediately, needs a msg_receiver to work
CMove4Skipper = {
	skip_on = nil,	-- message name to skip on
}
ECS:DefineComponent("move4_skipper", CMove4Skipper)
