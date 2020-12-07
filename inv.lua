local trash = {
	["minecraft:cobblestone"] = true,
	["minecraft:granite"] = true,
	["minecraft:andesite"] = true,
	["minecraft:diorite"] = true,
	["minecraft:gravel"] = true,
	["minecraft:stone"] = true,
	["minecraft:dirt"] = true,

	// AOF Modpack trash
	["wild_explorer:carbonite"] = true,
	["wild_explorer:blunite"] = true,
	["blockus:limestone"] = true,
	["blockus:bluestone"] = true,
	["blockus:marble"] = true,
	["byg:rocky_stone"] = true
}

function isInventoryFull()
	for i=1, 16 do
		if turtle.getItemCount(i) == 0 then
			return false
		end
	end

	return true
end

-- Fixes inventory scattering.
function stackItems()
	-- Remember seen items
	m = {}

	for i=1, 16 do
		local this = turtle.getItemDetail(i)
		local damage = this.damage or ""
		if this ~= nil then
			-- Slot is not empty

			local saved = m[this.name .. damage]

			if saved ~= nil then
				-- We've seen this item before in the inventory

				local ammount = this.count

				turtle.select(i)
				turtle.transferTo(saved.slot)

				if ammount > saved.space then
					-- We have leftovers, and now the
					-- saved slot is full, so we replace
					-- it by the current one

					saved.slot = i
					saved.count = ammount - saved.space
					-- Update on table.
					m[this.name .. damage] = saved

				elseif ammount == saved.space then
					-- Just delete the entry

					m[this.name .. damage] = nil

				end

			else
				-- There isn't another slot with this
				-- item so far, so sign this one up.

			this.slot = i
			this.space = turtle.getItemSpace(i)

			m[this.name .. damage] = this

			end
		end
	end
end

function selectItem(name)
	for i=1, 16 do
		local data = turtle.getItemDetail(i)
		if data and data.name == name then
			turtle.select(i)
			return true
		end
	end
	return false
end

function getItemCount(name)
	local count = 0
	for i=1, 16 do
		local data = turtle.getItemDetail(i)
		if data and data.name == name then
			count = count + data.count
		end
	end
	return count
end

function dropThrash()
	for i=1, 16 do

		details = turtle.getItemDetail(i)

		if details then
			if trash[details.name] then
				turtle.select(i)
				turtle.drop()
			end
		end
	end
end
