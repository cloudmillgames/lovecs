#!/usr/bin/love

require 'strict'
require 'ecs'

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

---------------- Game
require 'game'


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

function btn(key)
	return false 
end 
