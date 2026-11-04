-- Works around two v6.2.2 inventory behaviours on player AHumans. Both are handled
-- differently by newer engines, so this can go once a release includes those changes.
--
-- Inventory order: scrolling back puts the offhand on the wrong end of the inventory, and
-- the Equip* functions pull items out of the middle of it. We remember the order as a ring,
-- and after any change to what's held, restore the order that scrolling there would give.
--
-- Offhand return: an offhand holstered for climbing or crawling can miss its only chance to
-- come back, so we return it once the actor is upright and no longer climbing.

local OFFHAND_RETURN_DELAY_MS = 250

local function returnOffhand(self)
	if
		self.Status ~= Actor.STABLE
		or not self.BGArm
		or not self.EquippedItem
		or self.EquippedBGItem
		or self.IsClimbing
		or self.ProneState ~= AHuman.NOTPRONE
	then
		self.offhandReturnTimer:Reset()
	elseif self.offhandReturnTimer:IsPastSimMS(OFFHAND_RETURN_DELAY_MS) then
		-- The delay stops the offhand bouncing in and out when climbing keeps stopping and starting.
		self:EquipShieldInBGArm()
		self.offhandReturnTimer:Reset()
	end
end

local function getDesiredOrder(ring, heldID, offhandID, actualOrder)
	local start = nil
	if heldID ~= 0 and ring then
		for i = 1, #ring do
			if ring[i] == heldID then
				start = i
				break
			end
		end
	end
	-- Nothing held or something new in hand, so there's no position to restore from.
	if not start then
		return actualOrder
	end

	local inInventory = {}
	for _, id in ipairs(actualOrder) do
		inInventory[id] = true
	end

	local desiredOrder = {}
	for offset = 1, #ring - 1 do
		local id = ring[(start + offset - 1) % #ring + 1]
		if inInventory[id] and id ~= offhandID then
			desiredOrder[#desiredOrder + 1] = id
			inInventory[id] = nil
		end
	end
	-- Anything the ring hasn't seen yet goes at the back, where it was added.
	for _, id in ipairs(actualOrder) do
		if inInventory[id] then
			desiredOrder[#desiredOrder + 1] = id
		end
	end
	return desiredOrder
end

local function rebuildInventory(self, desiredOrder)
	local items = {}
	for _ = 1, #desiredOrder do
		local item = self:RemoveInventoryItemAtIndex(0)
		items[item.UniqueID] = item
	end
	for _, id in ipairs(desiredOrder) do
		self:AddInventoryItem(items[id])
	end
end

local function maintainInventoryOrder(self)
	local heldID = self.EquippedItem and self.EquippedItem.UniqueID or 0
	local offhandID = self.EquippedBGItem and self.EquippedBGItem.UniqueID or 0
	local size = self.InventorySize

	-- Every swap changes one of these, so most frames can stop here.
	if
		self.inventoryRing
		and heldID == self.inventoryHeldID
		and offhandID == self.inventoryOffhandID
		and size == self.inventorySize
	then
		return
	end

	local actualOrder = {}
	for item in self.Inventory do
		actualOrder[#actualOrder + 1] = item.UniqueID
	end

	local desiredOrder = getDesiredOrder(self.inventoryRing, heldID, offhandID, actualOrder)
	for i = 1, #desiredOrder do
		if desiredOrder[i] ~= actualOrder[i] then
			rebuildInventory(self, desiredOrder)
			break
		end
	end

	-- The offhand sits right after the held item, so it's the first thing scrolled to when put away.
	local ring = {}
	if heldID ~= 0 then
		ring[#ring + 1] = heldID
	end
	if offhandID ~= 0 then
		ring[#ring + 1] = offhandID
	end
	for _, id in ipairs(desiredOrder) do
		ring[#ring + 1] = id
	end

	-- These are from before any rebuild. Adding items can make the engine equip an offhand,
	-- and if it does, that shows up as a change next frame.
	self.inventoryRing = ring
	self.inventoryHeldID = heldID
	self.inventoryOffhandID = offhandID
	self.inventorySize = size
end

function Create(self)
	self.offhandReturnTimer = Timer()
end

function Update(self)
	returnOffhand(self)
	maintainInventoryOrder(self)
end
