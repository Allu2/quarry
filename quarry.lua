os.loadAPI("inv")
os.loadAPI("t")

local x = 0
local y = 0
local z = 0
local max = 16
local deep = 64
local facingfw = true
local turning = false
local digs = 0

local OK = 0
local ERROR = 1
local LAYERCOMPLETE = 2
local OUTOFFUEL = 3
local FULLINV = 4
local BLOCKEDMOV = 5
local USRINTERRUPT = 6

local CHARCOALONLY = false
local USEMODEM = false


-- Arguments
local tArgs = {...}
for i=1,#tArgs do
	local arg = tArgs[i]
	if string.find(arg, "-") == 1 then
		for c=2,string.len(arg) do
			local ch = string.sub(arg,c,c)
			if ch == 'c' then
				CHARCOALONLY = true
			elseif ch == 'm' then
				USEMODEM = true
			else
				write("Invalid flag '")
				write(ch)
				print("'")
			end
		end
	end
end


function out(s)

	s2 = s .. " @ [" .. x .. ", " .. y .. ", " .. z .. "]"

	print(s2)
	if USEMODEM then
		rednet.broadcast(s2, "miningTurtle")
	end
end

function dropInChest()
	local dropped = false
	for i=1, 4 do
		turtle.turnLeft()

		if not dropped then
			local success, data = turtle.inspect()

			if success and data.name == "minecraft:chest" then
				out("Dropping items in chest")
				dropped = true
				for i=1, 16 do
					turtle.select(i)

					data = turtle.getItemDetail()

					if data ~= nil and
							(data.name == "minecraft:coal" and CHARCOALONLY == false) == false and
							(data.damage == nil or data.name .. data.damage ~= "minecraft:coal1") then

						turtle.drop()
					end
				end
			end
		end
	end
end

function goDown()
	while true do
		if turtle.getFuelLevel() <= fuelNeededToGoBack() then
			if not refuel() then
				return OUTOFFUEL
			end
		end

		if not turtle.down() then
			turtle.up()
			z = z+1
			return
		end
		z = z-1
	end
end

function fuelNeededToGoBack()
	return -z + x + y + 2
end

function refuel()
	for i=1, 16 do
		-- Only run on Charcoal
		turtle.select(i)

		item = turtle.getItemDetail()
		if item and
				item.name == "minecraft:coal" and
				(CHARCOALONLY == false or item.damage == 1) and
				turtle.refuel(1) then
			return true
		end
	end

	return false
end

function tryEmptyInventory()
	if inv.isInventoryFull() then
		out("Dropping thrash")
		inv.dropThrash()

		if inv.isInventoryFull() then
			out ("Stacking items")
			inv.stackItems()
		end

		if inv.isInventoryFull() then
			out("Full inventory!")
			return false
		end
	end
	return true
end

function moveH()
	if not tryEmptyInventory() then
		return FULLINV
	end
	if turtle.getFuelLevel() <= fuelNeededToGoBack() then
		if not refuel() then
			out("Out of fuel!")
			return OUTOFFUEL
		end
	end

	digs = digs+1

	if facingfw and y<max-1 then
		-- Going one way
		if digs == 0 then
			if not t.dig() then
				out("Hit bedrock, can't keep going")
				return BLOCKEDMOV
			else return OK end
		elseif digs == 1 then
			t.digUp()
			return OK
		elseif digs == 2 then
			t.digDown()
			return OK
		end
		y = y+1
	elseif not facingfw and y>0 then
		-- Going the other way.
		if digs == 0 then
			if not t.dig() then
				out("Hit bedrock, can't keep going")
				return BLOCKEDMOV
			else return OK end
		elseif digs == 1 then
			t.digUp()
			return OK
		elseif digs == 2 then
			t.digDown()
			return OK
		end
		y = y-1
	else
		if x+1 >= max then
			if digs == 0 then
				t.digUp()
				return OK
			elseif digs == 1 then
				t.digDown()
				return OK
			end

			digs = 0
			return LAYERCOMPLETE -- Done with this Y level
		end

		if digs == 0 then
			if facingfw then
				turtle.turnRight()
			else
				turtle.turnLeft()
			end
			turning = true
			t.dig()
			return OK
		elseif digs == 1 then
			t.digUp()
			return OK
		elseif digs == 2 then
			t.digDown()
			return OK
		end
		x = x+1
	end

	if not t.fw() then
		return BLOCKEDMOV
	end
	digs = 0
	if turning then
		if facingfw then
			turtle.turnRight()
		else
			turtle.turnLeft()
		end

		turning = false
		facingfw = not facingfw
	end
	
	return OK
end

function digLayer()

	local errorcode = OK

	while errorcode == OK do
		if USEMODEM then
			local msg = rednet.receive(1)
			if msg ~= nil and string.find(msg, "return") ~= nil then
				return USRINTERRUPT
			end
		end
		errorcode = moveH()
	end

	if errorcode == LAYERCOMPLETE then
		return OK
	end

	return errorcode
end

function goToOrigin()

	if turning then
		if facingfw then
			turtle.turnRight()
		else
			turtle.turnLeft()
		end
	end

	if facingfw then

		turtle.turnLeft()

		t.fw(x)

		turtle.turnLeft()

		t.fw(y)

		turtle.turnRight()
		turtle.turnRight()

	else

		turtle.turnRight()

		t.fw(x)

		turtle.turnLeft()

		t.fw(y)

		turtle.turnRight()
		turtle.turnRight()

	end

	x = 0
	y = 0
	facingfw = true
	turning = false
end

function goUp()

	while z < 0 do

		t.up()

		z = z+1

	end

	goToOrigin()

end

function mainloop()

	while true do

		local errorcode = digLayer()

		if errorcode ~= OK then
			goUp()
			return errorcode
		end

		goToOrigin()

		for i=1, 3 do
			t.digDown()
			success = t.down()

			if not success then
				goUp()
				return BLOCKEDMOV
			end

			z = z-1
			out("Z: " .. z)

		end
	end
end

if USEMODEM then
	rednet.open("right")
end

out("\n\n\n-- WELCOME TO THE MINING TURTLE --\n\n")

while true do

	goDown()

	local errorcode = mainloop()
	dropInChest()

	if errorcode ~= FULLINV then
		break
	end
end

if USEMODEM then
	rednet.close("right")
end
