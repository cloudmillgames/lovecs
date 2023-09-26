#!/usr/bin/love

require 'strict'
require 'ecs'

---------------- Love2D-PICO8 adaptor
function add(t, v)
	table.insert(t, v)
end

-- '+=' not really but more readable
function incr(value, amount)
	return value + amount
end

-- '-=' not really but more readable
function decr(value, amount)
	return value - amount
end

---------------- Predefined components
-- a 2D position
CompPos = {
	x = 0,
	y = 0
}
DefineComponent("pos", CompPos)
-- a name for debugging
CompName = {
	name = "unnamed"
}
DefineComponent("dbgname", CompName)

---------------- Utility stuffs
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

function fround(x)
  return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

function clamp(v, min, max)
	if v < min then
		return min
	elseif v > max then
		return max
	else
		return v
	end
end

function pointDistSqrd(p1, p2)
	local dx = p1.x - p2.x
	local dy = p1.y - p2.y
	return dx * dx + dy * dy
end


function pointDist(p1, p2)
	return math.sqrt(pointDistSqrd(p1, p2))
end

function makeRect(_x, _y, _w, _h)
	return {
		x = _x,
		y = _y,
		w = _w,
		h = _h}
end

----------------- Resource system
Res = {}
Res.Images = {}
Res.Spritesheets = {}
Res.SoundEffects = {}
Res.Music = {}

Res.Init = function()
end
Res.LoadImage = function(name, path)
	if Res.Images[name] ~= nil then
		print("Image "..tostring(name).." already loaded")
		return
	end
	local info = love.filesystem.getInfo(path)
	if info == nil then
		error("Res.LoadImage() path not found: "..path.."("..name..")")
	else
		local ni = love.graphics.newImage(path)
		Res.Images[name] = ni
	end
end
Res.LoadImagesPack = function(pack)
	for k, v in pairs(pack) do
		Res.LoadImage(k, v)
	end
end
Res.GetImage = function(name)
	if Res.Images[name] == nil then
		error("Res.GetImage called on undefined image: "..name)
	end
	return Res.Images[name]
end
Res.LoadSpritesheet = function(name, data)
	if Res.Spritesheets[name] ~= nil then
		print("Spritesheet "..tostring(name).." already loaded")
		return
	end
	-- tanks = {"ss", {0, 112}, {128, 128}, {16, 16}}
	local img = Res.GetImage(data[1])
	local startx = tonumber(data[2][1])
	local starty = tonumber(data[2][2])
	local qw = tonumber(data[4][1])
	local qh = tonumber(data[4][2])
	local fc = tonumber(data[3][1])/qw
	local fr = tonumber(data[3][2])/qh
	local frames = fc * fr
	local ss = {
		image=data[1],
		framecount=frames,
		quads={},
		quadwidth=qw,
		quadheight=qh
	}
	for r=1,fr do
		for c=1,fc do
			local zc = c - 1
			local zr = r - 1
			table.insert(ss.quads, love.graphics.newQuad(
				startx + (zc * qw), starty + (zr * qh),
				qw, qh, img:getWidth(), img:getHeight()))
		end
	end
	Res.Spritesheets[name] = ss
end
Res.LoadSpritesheetsPack = function(pack)
	for k, v in pairs(pack) do
		Res.LoadSpritesheet(k, v)
	end
end
Res.LoadSoundEffect = function(name, file)
	if Res.SoundEffects[name] ~= nil then
		print("SoundEffect "..tostring(name).." already loaded")
		return
	end
	Res.SoundEffects[name] = love.audio.newSource(file, "static")
end
Res.LoadSoundEffectsPack = function(pack)
	for k, v in pairs(pack) do
		Res.LoadSoundEffect(k, v)
	end
end
Res.GetMusic = function(name)
	return Res.Music[name]
end
Res.LoadMusic = function(name, file)
	if Res.Music[name] ~= nil then
		print("Music "..tostring(name).." already loaded")
		return
	end
	Res.Music[name] = love.audio.newSource(file, "stream")
end
Res.LoadMusicPack = function(pack)
	for k, v in pairs(pack) do
		Res.LoadMusic(k, v)
	end
end

-- Returns: {image="img_name", framecount=N, quads={Quad,..}, quadwidth=N, quadheight=N}
Res.GetSpritesheet = function(name)
	if Res.Spritesheets[name] == nil then
		error("Res.GetSpritesheet called on undefined: "..name)
	end
	return Res.Spritesheets[name]
end

-- Returns sprite width as defined in given spritesheet name (unscaled)
Res.GetSpriteWidth = function(ss_name)
	assert(Res.Spritesheets[ss_name] ~= nil)
	return Res.Spritesheets[ss_name].quadwidth
end

-- Returns sprite height as defined in given spritesheet name (unscaled)
Res.GetSpriteHeight = function(ss_name)
	assert(Res.Spritesheets[ss_name] ~= nil)
	return Res.Spritesheets[ss_name].quadheight
end

-- Returns sprite framecount as defined in given spritesheet
Res.GetSpriteFramecount = function(ss_name)
	assert(Res.Spritesheets[ss_name] ~= nil)
	return Res.Spritesheets[ss_name].framecount
end

----------------

require('resources')
require('maps')

---------------- DrawList System
Draw = {}
Draw._list = {}
Draw._types = {"rect", "img", "quad", "txt"}
-- More Z is more front
Draw._sortComp = function(a, b)
	return a[2][1] < b[2][1]
end
Draw._color = nil

Draw.setColor = function(rgba)
	Draw._color = rgba
end
Draw.rectangle = function(z, mode, x, y, width, height, rx, ry, segments)
	table.insert(Draw._list, {"rect", {z, Draw._color}, mode, x, y, width, height, rx, ry, segments})
	Draw._color = nil
end
Draw.drawImage = function(z, drawable, x, y, r, sx, sy, ox, oy, kx, ky)
	table.insert(Draw._list, {"img", {z, Draw._color}, drawable, x, y, r, sx, sy, ox, oy, kx, ky})
	Draw._color = nil
end
Draw.drawQuad = function(z, image, quad, x, y, r, sx, sy, ox, oy, kx, ky )
	table.insert(Draw._list, {"quad", {z, Draw._color}, image, quad, x, y, r, sx, sy, ox, oy, kx, ky})
	Draw._color = nil
end
Draw.print = function(z, text, x, y, r, sx, sy, ox, oy, kx, ky )
	table.insert(Draw._list, {"txt", {z, Draw._color}, text, x, y, r, sx, sy, ox, oy, kx, ky})
	Draw._color = nil
end

Draw.exec = function()
	if #Draw._list > 0 then
		table.sort(Draw._list, Draw._sortComp)
		for i=1,#Draw._list do
			local d = Draw._list[i]
			local t = d[1]
			local color_set = false
			if type(d[2][2]) == "table" then
				color_set = true
				love.graphics.setColor(d[2][2])
			end
			if t == "quad" then
				love.graphics.draw(d[3], d[4], d[5], d[6], d[7], d[8], d[9], d[10], d[11], d[12], d[13])
			elseif t == "img" then
				love.graphics.draw(d[3], d[4], d[5], d[6], d[7], d[8], d[9], d[10], d[11], d[12])
			elseif t == "rect" then
				love.graphics.rectangle(d[3], d[4], d[5], d[6], d[7], d[8], d[9], d[10])
			elseif t == "txt" then
				love.graphics.print(d[3], d[4], d[5], d[6], d[7], d[8], d[9], d[10], d[11], d[12])
			else
				error("Unknown DrawList type/command: "..t)
			end
			if color_set then
				love.graphics.setColor({1, 1, 1, 1})
			end
		end
		Draw._list = {}
		Draw._color = nil
	end
end

---------------- Music system
-- Logic behind creating this is the need to have music survive a KillAllEntities
-- call which takes place between different parts of the games.
-- Only one music track can be played at a time, all music non-looping by default.
-- Can replay when music stops using isPlaying call. Or set looping via Love.
Music = {}
Music._currentSource = nil

Music.play = function(name)
	if Music._currentSource ~= nil then
		print("Music: stop current music playback.")
		Music._currentSource:stop()
		Music._currentSource = nil
	end
	Music._currentSource = Res.GetMusic(name)
	if Music._currentSource ~= nil then
		print("Music: set current music to: "..tostring(name))
		Music._currentSource:play()
	else
		print("Music: music wasn't defined: "..tostring(name))
	end
end

Music.stop = function()
	if Music._currentSource ~= nil then
		print("Music: stop current music playback..")
		Music._currentSource:stop()
	end
end

Music.pause = function()
	if Music._currentSource ~= nil then
		print("Music: pausing music")
		Music._currentSource:pause()
	else
		print("Music: pause called but no current music is playing")
	end
end

Music.resume = function()
	if Music._currentSource ~= nil then
		print("Music: resuming music playback")
		Music._currentSource:resume()
	else
		print("Music: resume called but no current music is paused")
	end
end

Music.isPlaying = function()
	if Music._currentSource ~= nil then
		return Music._currentSource:isPlaying()
	end
	return false
end

---------------- Msging system
require 'msging'

---------------- Collision System
require 'collision'

---------------- Main
btn = {
	up = 0,
	down = 0,
	left = 0,
	right = 0,
	z = 0,
	x = 0,
	a = 0,
	s = 0
}

function _init()
end

function _update()
	btn.up = love.keyboard.isDown("up") and btn.up + 1 or 0
	btn.down = love.keyboard.isDown("down") and btn.down + 1 or 0
	btn.left = love.keyboard.isDown("left") and btn.left + 1 or 0
	btn.right = love.keyboard.isDown("right") and btn.right + 1 or 0
	btn.z = love.keyboard.isDown("z") and btn.z + 1 or 0
	btn.x = love.keyboard.isDown("x") and btn.x + 1 or 0
	btn.a = love.keyboard.isDown("a") and btn.a + 1 or 0
	btn.s = love.keyboard.isDown("s") and btn.s + 1 or 0
	
	Msging.run()
	Collision.run()
	UpdateECS()
end

function _draw() 
	DrawECS()
	Draw.exec()
	Collision.draw()
end

---------------- Game
require 'game'


------------------------------------------ Love2D stuffs
LoveSprites = {}
DeltaTime = 0.0
GameTimeMultiplier = 1.0	-- Factor multiplied by time, must be changed back manually to 1.0
GameTimeWarp = 0.0			-- A single time step added to deltatime once, auto resets to 0.0

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

-- testshader = nil

function love.load()
	if type(jit) == 'table' then
	   print(jit.version)  --LuaJIT 2.0.2
	end
	love.graphics.setDefaultFilter("nearest", "nearest")
	_init()
	--test()
	
	-- pixel shader only
	-- testshader = love.graphics.newShader([[
		-- uniform float time;
		-- vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
			-- return vec4((1.0+sin(time))/2.0, abs(cos(time)), abs(sin(time)), 1.0);
		-- }]])
end

function love.keyreleased(key)
   if key == "escape" then
      love.event.quit()
   end
end

local t = 0
function love.update(dt)
	DeltaTime = dt * GameTimeMultiplier
	if GameTimeWarp > 0.0 then
		DeltaTime = DeltaTime + GameTimeWarp
		GameTimeWarp = 0.0
	end
	_update()
	--t = t + dt
    --testshader:send("time", t)
end

function love.draw()
	_draw()
	
	-- boring white
    --love.graphics.rectangle('fill', 10,10,790,285)

    -- LOOK AT THE PRETTY COLORS!
    --love.graphics.setShader(testshader)
    --love.graphics.rectangle('fill', 10,305,790,285)
	
    --love.graphics.setShader()
end
