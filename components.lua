-- ** GAME: COMPONENTS **

-- Start game screen
CInitStart = {}
DefineComponent("initstart", CInitStart)

-- Used to init game, should remove itself when run
CInitGame = {}
DefineComponent("initgame", CInitGame)

-- a direction of 4: 1 (up), 2 (right), 3(down), 4 (left)
CDir = {
	dir = 1
}
DefineComponent("dir", CDir)

-- a string
CText = {
	text = ""
}
DefineComponent("text", CText)

-- an image that gets drawn
CImg = {
	name="",
	orient=0.0,
	scalex=1,
	scaley=1
}
DefineComponent("img", CImg)

-- identify entity as player
CPlayer = {
}
DefineComponent("player", CPlayer)

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
DefineComponent("spr", CSpr)

-- an animated sprite
CAnimSpr = {
	spritesheet="",
	curr_frame=1,
	orient=0.0,
	scalex=1,
	scaley=1,
	color=nil,
	-- Specifies range of frames in spritesheet
	frame_start=1,	-- what's first frame in spritesheet
	frame_end=-1	-- < 1 means last frame
}
DefineComponent("animspr", CAnimSpr)

-- an animator for the animated sprite that cycles all frames
-- Deprecated: this counts in frames not DeltaTime
CAnimSpr_Cycle = {
	frametime=1,
	_framecount=0	-- used to count frame time
}
DefineComponent("animspr_cycle", CAnimSpr_Cycle)

-- Battlecity arena
CArenaBG = {}
DefineComponent("arena_bg", CArenaBG)

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
DefineComponent("tank", CTank)

CMapTile = {
	type = 1
}
DefineComponent("maptile", CMapTile)

CFPSCounter = {
	frame_timer = 0,
	frame_count = 0,
}
DefineComponent("fpscounter", CFPSCounter)

-- Follow position of another entity with offset
CPosLink = {
	parent = 0,
	offsetx = 0,
	offsety = 0
}
DefineComponent("poslink", CPosLink)

-- Identifies entity as a collision sensor shape (used for MotionSensor)
CCollSensor = {
	collision = false
}
DefineComponent("collsensor", CCollSensor)

-- References 4 sensors each in the 4 cartesian directions (no diagonals)
-- Use to check whether you can move in that direction. UP RIGHT DOWN LEFT
CMotionSensor4 = {
	sensors = {}
}
DefineComponent("motionsensor4", CMotionSensor4)

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
DefineComponent("move4", CMove4)

CBmpText = {
    text = "",
    color = nil
}
DefineComponent("bmptext", CBmpText)

CMenuCursor = {
    places = {},    -- each pair of {x,y} is a menu item, index starts at 1
    current = 1,    -- default to first place
    funcs = {},     -- What to call when Z is pressed on menu cursor
}
DefineComponent("menucursor", CMenuCursor)

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
DefineComponent("uianimspr", CUIAnimSprite)

-- Set 'func' to function you want, it will be called once after delay
CDelayedFunc = {
    delay = 0,
    func = nil
}
DefineComponent("delayedfunc", CDelayedFunc)

-- Calls function when button is pressed (==1)
CButtonFunc = {
	btn_name = "z",
	func = nil,
	kill_after = -1,	-- how many runs to kill self entity after? -1 means do not kill, 1 is once
}
DefineComponent("buttonfunc", CButtonFunc)

CScreenEffect_Door = {
    duration = 1,   -- duration of door effect
    stay = 1,       -- how long does it stay after effect is over, til delete
    rect_color = nil,
    opening = false,
    _timer_duration = 0,
    _timer_stay = 0
}
DefineComponent("screeneffect_door", CScreenEffect_Door)

CTankTurret = {
	cooldown = 1,
	bullet_type = 1,
	_timer_cooldown =0,
	fire_point = {x=0, y=0}	-- offset for spawning UP, directionally aware
}
DefineComponent("tankturret", CTankTurret)

CProjectile = {
	speed=30,
	shooter_entity=0
}
DefineComponent("projectile", CProjectile)

COutOfBoundsKill = {
}
DefineComponent("outofbounds_kill", COutOfBoundsKill)

-- Dispatch a message (via msg_dispatcher) when given button is pressed
CMsgOnButton = {
	btn_name="z",	-- button that dispatches message
	msg="button-msg",		-- message name to dispatch
	channel=Msging.CHANNEL	-- on which channel to dispatch
}
DefineComponent("msg_on_button", CMsgOnButton)

-- Counts down time, stops if zero
CTimedown = {
	time = 0.0
}
DefineComponent("timedown", CTimedown)

----------------------------------------------------- Deprecated Components

-- Skips delayed func on a specific message by calling func immediately, needs a msg_receiver comp
CDelayedFuncSkipper = {
	skip_on = nil,	-- msg name to skip on
}
DefineComponent("delayedfunc_skipper", CDelayedFuncSkipper)

-- Calls function when message is received, requires a msg_receiver to work
-- TO IMPLEMENT
CMsgFunc = {
	msg = "func-msg",
	channel = Msging.CHANNEL,
	func = nil
}
DefineComponent("msgfunc", CMsgFunc)

-- Skips move4 component by finishing it immediately, needs a msg_receiver to work
CMove4Skipper = {
	skip_on = nil,	-- message name to skip on
}
DefineComponent("move4_skipper", CMove4Skipper)
