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
    text = ""
}
DefineComponent("bmptext", CBmpText)