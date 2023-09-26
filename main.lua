#!/usr/bin/love

require 'strict'
require 'ecs'

---------------- Love2D-PICO8 adaptor
function add(t, v)
	table.insert(t, v)
end

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

----------------- Resource system
Res = {}
Res.Images = {}
Res.Spritesheets = {}
Res.Init = function()
end
Res.LoadImage = function(name, path)
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
		quads={}
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
-- Returns: {image="img_name", framecount=N, quads={Quad,..}}
Res.GetSpritesheet = function(name)
	if Res.Spritesheets[name] == nil then
		error("Res.GetSpritesheet called on undefined: "..name)
	end
	return Res.Spritesheets[name]
end
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

---------------- Main
btn = {
	up = false,
	down = false,
	left = false,
	right = false,
	z = false,
	x = false,
	a = false,
	s = false
}

function _init()
end

function _update60()
	btn.up = love.keyboard.isDown("up")
	btn.down = love.keyboard.isDown("down")
	btn.left = love.keyboard.isDown("left")
	btn.right = love.keyboard.isDown("right")
	btn.z = love.keyboard.isDown("z")
	btn.x = love.keyboard.isDown("x")
	btn.a = love.keyboard.isDown("a")
	btn.s = love.keyboard.isDown("s")
	
	UpdateECS()
end

function _draw() 
	DrawECS()
	Draw.exec()
end

---------------- Game
require 'game'


------------------------------------------ Love2D stuffs
LoveSprites = {} 

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
	--test()
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
	_draw()
end
