-----------------------------------------------------------------------------------------
--	Returns sorted array of stored items from game state. If makefilters is true, then
--	it will also return additional array with filtered items
-----------------------------------------------------------------------------------------
CF["GetStorageArray"] = function(gs, makefilters)
	local arr = {}

	-- Copy items
	for i = 1, CF["MaxStorageItems"] do
		if gs["ItemStorage" .. i .. "Preset"] ~= nil then
			arr[i] = {}
			arr[i]["Preset"] = gs["ItemStorage" .. i .. "Preset"]
			arr[i]["Class"] = gs["ItemStorage" .. i .. "Class"]
			arr[i]["Module"] = gs["ItemStorage" .. i .. "Module"]
			arr[i]["Count"] = tonumber(gs["ItemStorage" .. i .. "Count"])
		else
			break
		end
	end

	-- Sort items
	for i = 1, #arr do
		for j = 1, #arr - 1 do
			if arr[j]["Preset"] > arr[j + 1]["Preset"] then
				local c = arr[j + 1]
				arr[j + 1] = arr[j]
				arr[j] = c
			end
		end
	end

	local arr2
	if makefilters then
		arr2 = {}

		-- Array for all items
		arr2[-1] = {}
		-- Array for unknown items
		arr2[-2] = {}
		-- Array for sell items
		arr2[-3] = {}
		-- Arrays for items by types
		arr2[CF["WeaponTypes"].PISTOL] = {}
		arr2[CF["WeaponTypes"].RIFLE] = {}
		arr2[CF["WeaponTypes"].SHOTGUN] = {}
		arr2[CF["WeaponTypes"].SNIPER] = {}
		arr2[CF["WeaponTypes"].HEAVY] = {}
		arr2[CF["WeaponTypes"].SHIELD] = {}
		arr2[CF["WeaponTypes"].DIGGER] = {}
		arr2[CF["WeaponTypes"].GRENADE] = {}
		arr2[CF["WeaponTypes"].TOOL] = {}
		arr2[CF["WeaponTypes"].BOMB] = {}

		for itm = 1, #arr do
			local f, i = CF["FindItemInFactions"](arr[itm]["Preset"], arr[itm]["Class"], arr[itm]["Module"])

			-- Add item to 'all' list
			local indx = #arr2[-1] + 1
			arr2[-1][indx] = itm

			-- Add item to 'sell' list
			local indx = #arr2[-3] + 1
			arr2[-3][indx] = itm

			if f and i then
				-- Add item to specific list
				local indx = #arr2[CF["ItmTypes"][f][i]] + 1
				arr2[CF["ItmTypes"][f][i]][indx] = itm
			else
				-- Add item to unknown list
				local indx = #arr2[-2] + 1
				arr2[-2][indx] = itm
			end
		end
	end

	--for i = 1, #arr do
	--	print (arr[i]["Preset"])
	--end

	return arr, arr2
end
-----------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------
CF["GetItemShopArray"] = function(gs, makefilters)
	local arr = {}

	for i = 1, tonumber(gs["ActiveCPUs"]) do
		local f = CF["GetPlayerFaction"](gs, i)

		-- Add generic items
		for itm = 1, #CF["ItmNames"][f] do
			local applicable = false

			if
				tonumber(gs["Player" .. i .. "Reputation"]) > 0
				and tonumber(gs["Player" .. i .. "Reputation"]) >= CF["ItmUnlockData"][f][itm]
			then
				applicable = true
			end

			if not applicable then
				if gs["UnlockedItmBlueprint_" .. CF["ItmPresets"][f][itm]] then
					applicable = true
				end
			end

			for j = 1, #arr do
				if
					CF["ItmDescriptions"][f][itm] == arr[j]["Description"]
					and CF["ItmPresets"][f][itm] == arr[j]["Preset"]
				then
					applicable = false
					break
				end
			end

			if applicable then
				local ii = #arr + 1
				arr[ii] = {}
				arr[ii]["Preset"] = CF["ItmPresets"][f][itm]
				arr[ii]["Module"] = CF["ItmModules"][f][itm]
				if CF["ItmClasses"][f][itm] ~= nil then
					arr[ii]["Class"] = CF["ItmClasses"][f][itm]
				else
					arr[ii]["Class"] = "HDFirearm"
				end
				arr[ii]["Faction"] = f
				arr[ii]["Index"] = itm
				arr[ii]["Description"] = CF["ItmDescriptions"][f][itm]
				local price = math.floor(
					CF["ItmPrices"][f][itm]
							* (tonumber(gs["Player" .. i .. "Reputation"]) >= CF["ItmUnlockData"][f][itm] and 1 or CF["TechPriceMultiplier"])
						+ 0.5
				)
				--[[
				local repRatio = math.max((CF["ItmUnlockData"][f][itm] * CF["TechPriceMultiplier"])/tonumber(gs["Player"..i.."Reputation"]), 1)
				if repRatio == 1 then
					price = CF["ItmPrices"][f][itm]
				else
					price = CF["ItmPrices"][f][itm] * repRatio + 4
					price = price - (price % 5)
				end
				]]
				--
				if price >= 1000 then
					if price >= 10000 then
						price = math.floor(price * 0.001) * 1000
					else
						price = math.floor(price * 0.01) * 100
					end
				end

				arr[ii]["Price"] = math.floor(price)
				arr[ii]["Type"] = CF["ItmTypes"][f][itm]

				--print(arr[ii]["Preset"])
				--print(arr[ii]["Class"])
			end
		end

		-- Add bombs
		for itm = 1, #CF["BombNames"] do
			local allowed = true
			local owner = ""

			if #CF["BombOwnerFactions"][itm] > 0 then
				allowed = false
				for of = 1, #CF["BombOwnerFactions"][itm] do
					--print(CF["BombOwnerFactions"][itm][of])
					if CF["BombOwnerFactions"][itm][of] == f then
						--print ("OK")
						--print (tonumber(gs["Player"..i.."Reputation"]))
						--print (CF["BombUnlockData"][itm])
						if tonumber(gs["Player" .. i .. "Reputation"]) >= CF["BombUnlockData"][itm] then
							allowed = true
							owner = f
						end
					end
				end
			end

			local isduplicate = false

			for j = 1, #arr do
				if CF["BombDescriptions"][itm] == arr[j]["Description"] and CF["BombPresets"][itm] == arr[j]["Preset"] then
					isduplicate = true
				end
			end

			if allowed and not isduplicate then
				local ii = #arr + 1
				arr[ii] = {}
				arr[ii]["Preset"] = CF["BombPresets"][itm]
				arr[ii]["Module"] = CF["BombModules"][itm]
				if CF["BombClasses"][itm] ~= nil then
					arr[ii]["Class"] = CF["BombClasses"][itm]
				else
					arr[ii]["Class"] = "TDExplosive"
				end
				arr[ii]["Faction"] = owner
				arr[ii]["Index"] = itm
				arr[ii]["Description"] = CF["BombDescriptions"][itm]
				local price = CF["BombPrices"][itm]
				if price >= 1000 then
					if price >= 10000 then
						price = math.floor(price * 0.001) * 1000
					else
						price = math.floor(price * 0.01) * 100
					end
				end
				arr[ii]["Price"] = price
				arr[ii]["Type"] = CF["WeaponTypes"].BOMB
			end
		end
	end

	-- Sort items
	for i = 1, #arr do
		for j = 1, #arr - 1 do
			if arr[j]["Preset"] > arr[j + 1]["Preset"] then
				local a = arr[j]
				arr[j] = arr[j + 1]
				arr[j + 1] = a
			end
		end
	end

	--for i = 1, #arr do
	--	print(arr[i]["Preset"])
	--	print(arr[i]["Class"])
	--end

	local arr2
	if makefilters then
		arr2 = {}

		-- Array for all items
		arr2[-1] = {}
		-- Arrays for items by types
		arr2[CF["WeaponTypes"].PISTOL] = {}
		arr2[CF["WeaponTypes"].RIFLE] = {}
		arr2[CF["WeaponTypes"].SHOTGUN] = {}
		arr2[CF["WeaponTypes"].SNIPER] = {}
		arr2[CF["WeaponTypes"].HEAVY] = {}
		arr2[CF["WeaponTypes"].SHIELD] = {}
		arr2[CF["WeaponTypes"].DIGGER] = {}
		arr2[CF["WeaponTypes"].GRENADE] = {}
		arr2[CF["WeaponTypes"].TOOL] = {}
		arr2[CF["WeaponTypes"].BOMB] = {} -- Bombs

		for itm = 1, #arr do
			-- Add item to 'all' list
			local indx = #arr2[-1] + 1
			arr2[-1][indx] = itm

			-- Add item to specific list
			local tp = arr[itm]["Type"]
			local indx = #arr2[tp] + 1
			arr2[tp][indx] = itm
		end
	end

	return arr, arr2
end
-----------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------
local function clearBlackMarketStock(gs, prefix, count)
	for i = 1, tonumber(count) or 0 do
		gs[prefix .. i .. "Class"] = nil
		gs[prefix .. i .. "Preset"] = nil
		gs[prefix .. i .. "Module"] = nil
		gs[prefix .. i .. "Faction"] = nil
		gs[prefix .. i .. "Index"] = nil
	end
end

local function getStockKey(class, preset, module)
	return class .. "_" .. preset .. "_" .. module
end

local function restockBlackMarketItems(gs, loc)
	local prefix = "BlackMarket" .. loc .. "Item"
	local listed = {}
	local count = 0

	clearBlackMarketStock(gs, prefix, gs["BlackMarket" .. loc .. "ItemCount"])

	-- Exclusives are stored by index alone
	if #CF["BlackMarketItmPresets"] > 0 then
		for i = 1, math.random(math.floor(math.sqrt(#CF["BlackMarketItmPresets"]))) do
			local index = math.random(#CF["BlackMarketItmPresets"])
			local key = getStockKey(
				CF["BlackMarketItmClasses"][index],
				CF["BlackMarketItmPresets"][index],
				CF["BlackMarketItmModules"][index]
			)

			if math.random() < (1 / i) and not listed[key] then
				count = count + 1
				gs[prefix .. count .. "Index"] = index
				listed[key] = true
			end
		end
	end

	-- Artifacts are stored by name, since their indices change along with the installed mods
	local function addArtifact(index)
		local class = CF["ArtItmClasses"][index] or "HDFirearm"
		local preset = CF["ArtItmPresets"][index]
		local module = CF["ArtItmModules"][index]
		local key = getStockKey(class, preset, module)

		if not listed[key] then
			count = count + 1
			gs[prefix .. count .. "Class"] = class
			gs[prefix .. count .. "Preset"] = preset
			gs[prefix .. count .. "Module"] = module
			listed[key] = true
		end
	end

	if #CF["ArtItmPresets"] > 0 then
		for index = 1, #CF["ArtItmPresets"] do
			if gs["UnlockedItmBlackprint_" .. CF["ArtItmPresets"][index]] then
				addArtifact(index)
			end
		end

		for i = 1, math.random(math.floor(math.sqrt(#CF["ArtItmPresets"]))) do
			local index = math.random(#CF["ArtItmPresets"])

			if math.random() < (1 / i) then
				addArtifact(index)
			end
		end
	end

	-- Items of participating factions are stored by faction and index
	for i = 1, tonumber(gs["ActiveCPUs"]) do
		local f = CF["GetPlayerFaction"](gs, i)

		for index = 1, #CF["ItmNames"][f] do
			local preset = CF["ItmPresets"][f][index]

			if preset and (CF["ItmPowers"][f][index] == 0 or CF["ItmPowers"][f][index] > math.random(4, 6)) then
				local key = getStockKey(CF["ItmClasses"][f][index] or "HDFirearm", preset, CF["ItmModules"][f][index])

				if math.random() < (CF["BlackMarketItemVariety"] / (count + 1)) and not listed[key] then
					count = count + 1
					gs[prefix .. count .. "Faction"] = f
					gs[prefix .. count .. "Index"] = index
					listed[key] = true
				end
			end
		end
	end

	gs["BlackMarket" .. loc .. "ItemCount"] = count
	gs["BlackMarket" .. loc .. "ItemsLastRefresh"] = gs["Time"]
end

local function getBlackMarketPrice(value, fundFactor, minimum)
	return math.max(CF["TruncateNumber"](value * CF["BlackMarketPriceMultiplier"] + fundFactor, 1), minimum)
end

-- Artifacts aren't typed by hand, so go by the same groups that faction items are typed by.
local function getArtifactType(entity, class)
	if class == "TDExplosive" then
		return CF["WeaponTypes"].GRENADE
	end

	local itemType = entity:IsInGroup("Weapons") and CF["WeaponTypes"].RIFLE or nil
	for _, group in ipairs(CF["WeaponGroups"]) do
		if entity:IsInGroup(group[1]) then
			itemType = group[2]
		end
	end
	return itemType
end

CF["GetItemBlackMarketArray"] = function(gs, makefilters)
	local loc = gs["Location"]
	local prefix = "BlackMarket" .. loc .. "Item"
	local count = tonumber(gs["BlackMarket" .. loc .. "ItemCount"]) or 0
	local lastRefresh = tonumber(gs["BlackMarket" .. loc .. "ItemsLastRefresh"])
	local tocreate = lastRefresh == nil or lastRefresh + CF["BlackMarketRefreshInterval"] < tonumber(gs["Time"])

	-- Stock from older saves names exclusives as a faction, and its indices point into a longer list
	for i = 1, count do
		if gs[prefix .. i .. "Faction"] == "Black Market" then
			tocreate = true
			break
		end
	end

	if tocreate then
		restockBlackMarketItems(gs, loc)
		count = tonumber(gs["BlackMarket" .. loc .. "ItemCount"])
	end

	-- Fill array
	local arr = {}

	for i = 1, count do
		local item = nil
		local f = gs[prefix .. i .. "Faction"]
		local index = tonumber(gs[prefix .. i .. "Index"])
		local fundFactor = math.sqrt(CF["GetPlayerGold"](gs, 0)) * RangeRand(0.5, 0.75) * CF["BlackMarketPriceMultiplier"]

		if f then
			if CF["ItmPresets"][f] and CF["ItmPresets"][f][index] then
				item = {}
				item["Faction"] = f
				item["Preset"] = CF["ItmPresets"][f][index]
				item["Module"] = CF["ItmModules"][f][index]
				item["Class"] = CF["ItmClasses"][f][index] or "HDFirearm"
				item["Description"] = CF["ItmDescriptions"][f][index] or "DESCRIPTION UNAVAILABLE"
				item["Price"] = getBlackMarketPrice(CF["ItmPrices"][f][index], fundFactor, CF["UnknownItemPrice"])
				item["Type"] = CF["ItmTypes"][f][index]
			end
		elseif index then
			if CF["BlackMarketItmPresets"][index] then
				item = {}
				item["Faction"] = "Black Market"
				item["Preset"] = CF["BlackMarketItmPresets"][index]
				item["Module"] = CF["BlackMarketItmModules"][index]
				item["Class"] = CF["BlackMarketItmClasses"][index]
				item["Description"] = CF["BlackMarketItmDescriptions"][index] or "DESCRIPTION UNAVAILABLE"
				item["Price"] = getBlackMarketPrice(CF["BlackMarketItmPrices"][index], fundFactor, CF["UnknownItemPrice"])
				item["Type"] = CF["BlackMarketItmTypes"][index]
			end
		else
			local class = gs[prefix .. i .. "Class"] or ""
			local preset = gs[prefix .. i .. "Preset"] or ""
			local module = gs[prefix .. i .. "Module"] or ""
			local entity = PresetMan:GetPreset(class, preset, module)

			if entity and IsSceneObject(entity) then
				entity = ToSceneObject(entity)
				local multiplier = gs["UnlockedItmBlackprint_" .. preset] and 0.5 or 1
				local price = getBlackMarketPrice(entity:GetGoldValue(0, 1, 1), fundFactor, CF["UnknownItemPrice"])

				item = {}
				item["Preset"] = preset
				item["Module"] = module
				item["Class"] = class
				item["Description"] = entity.Description or "DESCRIPTION UNAVAILABLE"
				item["Price"] = math.floor(price * multiplier)
				item["Type"] = getArtifactType(entity, class)
			end
		end

		if item then
			arr[#arr + 1] = item
		end
	end

	-- Sort items
	for i = 1, #arr do
		for j = 1, #arr - 1 do
			if arr[j]["Preset"] and arr[j + 1]["Preset"] and arr[j]["Preset"] > arr[j + 1]["Preset"] then
				local a = arr[j]
				arr[j] = arr[j + 1]
				arr[j + 1] = a
			end
		end
	end

	local arr2
	if makefilters then
		arr2 = {}

		-- Array for all items
		arr2[-1] = {}
		-- Arrays for items by types
		arr2[CF["WeaponTypes"].PISTOL] = {}
		arr2[CF["WeaponTypes"].RIFLE] = {}
		arr2[CF["WeaponTypes"].SHOTGUN] = {}
		arr2[CF["WeaponTypes"].SNIPER] = {}
		arr2[CF["WeaponTypes"].HEAVY] = {}
		arr2[CF["WeaponTypes"].SHIELD] = {}
		arr2[CF["WeaponTypes"].DIGGER] = {}
		arr2[CF["WeaponTypes"].GRENADE] = {}
		arr2[CF["WeaponTypes"].TOOL] = {}

		for itm = 1, #arr do
			-- Add item to 'all' list
			local indx = #arr2[-1] + 1
			arr2[-1][indx] = itm

			-- Add item to specific list
			if arr[itm]["Type"] then
				local tp = arr[itm]["Type"]
				local indx = #arr2[tp] + 1
				arr2[tp][indx] = itm
			end
		end
	end

	return arr, arr2
end
-----------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------
CF["GetCloneShopArray"] = function(gs, makefilters)
	local arr = {}

	for i = 1, tonumber(gs["ActiveCPUs"]) do
		local f = CF["GetPlayerFaction"](gs, i)

		for itm = 1, #CF["ActNames"][f] do
			local applicable = false

			if not applicable then
				if
					tonumber(gs["Player" .. i .. "Reputation"]) > 0
					and tonumber(gs["Player" .. i .. "Reputation"]) >= CF["ActUnlockData"][f][itm]
				then
					applicable = true
				end
			end

			if not applicable then
				if gs["UnlockedActBlueprint_" .. CF["ActPresets"][f][itm]] then
					applicable = true
				end
			end

			for j = 1, #arr do
				if
					CF["ActDescriptions"][f][itm] == arr[j]["Description"]
					and CF["ActPresets"][f][itm] == arr[j]["Preset"]
				then
					applicable = false
					break
				end
			end

			if applicable then
				local ii = #arr + 1
				arr[ii] = {}
				arr[ii]["Preset"] = CF["ActPresets"][f][itm]
				arr[ii]["Class"] = CF["ActClasses"][f][itm] or "AHuman"

				arr[ii]["Faction"] = f
				arr[ii]["Index"] = itm
				arr[ii]["Description"] = CF["ActDescriptions"][f][itm]
				local price = math.floor(
					CF["ActPrices"][f][itm]
							* (tonumber(gs["Player" .. i .. "Reputation"]) >= CF["ActUnlockData"][f][itm] and 1 or CF["TechPriceMultiplier"])
						+ 0.5
				)
				if price >= 100 then
					if price >= 1000 then
						if price >= 10000 then
							price = math.floor(price * 0.001) * 1000
						else
							price = math.floor(price * 0.01) * 100
						end
					else
						price = math.floor(price * 0.1) * 10
					end
				end
				arr[ii]["Price"] = math.floor(price)
				arr[ii]["Type"] = CF["ActTypes"][f][itm]
			end
		end
	end

	-- Sort items
	for i = 1, #arr do
		for j = 1, #arr - 1 do
			if arr[j]["Preset"] > arr[j + 1]["Preset"] then
				local a = arr[j]
				arr[j] = arr[j + 1]
				arr[j + 1] = a
			end
		end
	end

	local arr2
	if makefilters then
		arr2 = {}

		-- Array for all items
		arr2[-1] = {}
		-- Arrays for items by types
		arr2[CF["ActorTypes"].LIGHT] = {}
		arr2[CF["ActorTypes"].HEAVY] = {}
		arr2[CF["ActorTypes"].ARMOR] = {}
		arr2[CF["ActorTypes"].TURRET] = {}

		for itm = 1, #arr do
			-- Add item to 'all' list
			local indx = #arr2[-1] + 1
			arr2[-1][indx] = itm

			-- Add item to specific list
			local tp = arr[itm]["Type"]
			local indx = #arr2[tp] + 1
			arr2[tp][indx] = itm
		end
	end

	return arr, arr2
end
-----------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------
local function restockBlackMarketActors(gs, loc)
	local prefix = "BlackMarket" .. loc .. "Actor"
	local listed = {}
	local count = 0

	clearBlackMarketStock(gs, prefix, gs["BlackMarket" .. loc .. "ActorsCount"])

	-- Artifacts are stored by name, since their indices change along with the installed mods
	local function addArtifact(index)
		local class = CF["ArtActClasses"][index] or "AHuman"
		local preset = CF["ArtActPresets"][index]
		local module = CF["ArtActModules"][index]
		local key = getStockKey(class, preset, module)

		if not listed[key] then
			count = count + 1
			gs[prefix .. count .. "Class"] = class
			gs[prefix .. count .. "Preset"] = preset
			gs[prefix .. count .. "Module"] = module
			listed[key] = true
		end
	end

	if #CF["ArtActPresets"] > 0 then
		for index = 1, #CF["ArtActPresets"] do
			if gs["UnlockedActBlackprint_" .. CF["ArtActPresets"][index]] then
				addArtifact(index)
			end
		end

		for i = 1, math.random(math.floor(math.sqrt(#CF["ArtActPresets"]))) do
			local index = math.random(#CF["ArtActPresets"])

			if math.random() < (CF["BlackMarketCloneVariety"] / (count + 1)) then
				addArtifact(index)
			end
		end
	end

	-- Actors of participating factions are stored by faction and index
	for i = 1, tonumber(gs["ActiveCPUs"]) do
		local f = CF["GetPlayerFaction"](gs, i)

		for index = 1, #CF["ActNames"][f] do
			local preset = CF["ActPresets"][f][index]

			if preset and CF["ActPowers"][f][index] > math.random(4, 6) and CF["ActTypes"][f][index] ~= CF["ActorTypes"].TURRET then
				local key = getStockKey(CF["ActClasses"][f][index] or "AHuman", preset, CF["ActModules"][f][index])

				if math.random() < (CF["BlackMarketCloneVariety"] / (count + 1)) and not listed[key] then
					count = count + 1
					gs[prefix .. count .. "Faction"] = f
					gs[prefix .. count .. "Index"] = index
					listed[key] = true
				end
			end
		end
	end

	gs["BlackMarket" .. loc .. "ActorsCount"] = count
	gs["BlackMarket" .. loc .. "ActorsLastRefresh"] = gs["Time"]
end

CF["GetCloneBlackMarketArray"] = function(gs, makefilters)
	local loc = gs["Location"]
	local prefix = "BlackMarket" .. loc .. "Actor"
	local count = tonumber(gs["BlackMarket" .. loc .. "ActorsCount"]) or 0
	local lastRefresh = tonumber(gs["BlackMarket" .. loc .. "ActorsLastRefresh"])
	local tocreate = lastRefresh == nil or lastRefresh + CF["BlackMarketRefreshInterval"] < tonumber(gs["Time"])

	-- Stock from older saves stores artifacts by index, and those indices change with the installed mods
	for i = 1, count do
		if gs[prefix .. i .. "Index"] and not gs[prefix .. i .. "Faction"] then
			tocreate = true
			break
		end
	end

	if tocreate then
		restockBlackMarketActors(gs, loc)
		count = tonumber(gs["BlackMarket" .. loc .. "ActorsCount"])
	end

	-- Fill array
	local arr = {}

	for i = 1, count do
		local actor = nil
		local f = gs[prefix .. i .. "Faction"]
		local index = tonumber(gs[prefix .. i .. "Index"])
		local fundFactor = math.sqrt(CF["GetPlayerGold"](gs, 0)) * RangeRand(0.75, 1.0) * CF["BlackMarketPriceMultiplier"]

		if f then
			if CF["ActPresets"][f] and CF["ActPresets"][f][index] then
				actor = {}
				actor["Faction"] = f
				actor["Preset"] = CF["ActPresets"][f][index]
				actor["Module"] = CF["ActModules"][f][index]
				actor["Class"] = CF["ActClasses"][f][index] or "AHuman"
				actor["Description"] = CF["ActDescriptions"][f][index] or "DESCRIPTION UNAVAILABLE"
				actor["Price"] = getBlackMarketPrice(CF["ActPrices"][f][index], fundFactor, CF["UnknownActorPrice"])
				actor["Type"] = CF["ActTypes"][f][index]
			end
		else
			local class = gs[prefix .. i .. "Class"] or ""
			local preset = gs[prefix .. i .. "Preset"] or ""
			local module = gs[prefix .. i .. "Module"] or ""
			local entity = PresetMan:GetPreset(class, preset, module)

			if entity and IsSceneObject(entity) then
				entity = ToSceneObject(entity)
				local multiplier = gs["UnlockedActBlackprint_" .. preset] and 0.5 or 1
				local price = getBlackMarketPrice(entity:GetGoldValue(0, 1, 1), fundFactor, CF["UnknownActorPrice"])

				actor = {}
				actor["Preset"] = preset
				actor["Module"] = module
				actor["Class"] = class
				actor["Description"] = entity.Description or "DESCRIPTION UNAVAILABLE"
				actor["Price"] = math.floor(price * multiplier)
			end
		end

		if actor then
			arr[#arr + 1] = actor
		end
	end

	-- Sort items
	for i = 1, #arr do
		for j = 1, #arr - 1 do
			if arr[j]["Preset"] > arr[j + 1]["Preset"] then
				local a = arr[j]
				arr[j] = arr[j + 1]
				arr[j + 1] = a
			end
		end
	end

	local arr2
	if makefilters then
		arr2 = {}

		-- Array for all items
		arr2[-1] = {}
		-- Arrays for items by types
		arr2[CF["ActorTypes"].LIGHT] = {}
		arr2[CF["ActorTypes"].HEAVY] = {}
		arr2[CF["ActorTypes"].ARMOR] = {}
		arr2[CF["ActorTypes"].TURRET] = {}

		for itm = 1, #arr do
			-- Add item to 'all' list
			local indx = #arr2[-1] + 1
			arr2[-1][indx] = itm

			-- Add item to specific list
			if arr[itm]["Type"] then
				local tp = arr[itm]["Type"]
				local indx = #arr2[tp] + 1
				arr2[tp][indx] = itm
			end
		end
	end

	return arr, arr2
end
-----------------------------------------------------------------------------------------
--	Saves array of stored items to game state
-----------------------------------------------------------------------------------------
CF["SetStorageArray"] = function(gs, arr)
	-- Clear stored array data
	for i = 1, CF["MaxStorageItems"] do
		gs["ItemStorage" .. i .. "Preset"] = nil
		gs["ItemStorage" .. i .. "Module"] = nil
		gs["ItemStorage" .. i .. "Class"] = nil
		gs["ItemStorage" .. i .. "Count"] = nil
	end

	-- Copy items
	local itm = 1

	for i = 1, #arr do
		if arr[i]["Count"] > 0 then
			gs["ItemStorage" .. itm .. "Preset"] = arr[i]["Preset"]
			gs["ItemStorage" .. itm .. "Module"] = arr[i]["Module"]
			gs["ItemStorage" .. itm .. "Class"] = arr[i]["Class"]
			gs["ItemStorage" .. itm .. "Count"] = arr[i]["Count"]
			itm = itm + 1
		end
	end
end
-----------------------------------------------------------------------------------------
--	Counts used storage units in storage array
-----------------------------------------------------------------------------------------
CF["CountUsedStorageInArray"] = function(arr)
	local count = 0

	for i = 1, #arr do
		if arr[i]["Class"] ~= "TDExplosive" then
			count = count + arr[i]["Count"]
		else
			count = count + math.floor(arr[i]["Count"] / 10)
		end
	end

	return count
end
-----------------------------------------------------------------------------------------
--	Searches for given item in all faction files and returns it's factions and index if found
-----------------------------------------------------------------------------------------
CF["FindItemInFactions"] = function(preset, class, module)
	for fact = 1, #CF["Factions"] do
		local f = CF["Factions"][fact]

		for i = 1, #CF["ItmNames"][f] do
			if preset == CF["ItmPresets"][f][i] then
				if class == CF["ItmClasses"][f][i] or (class == "HDFirearm" and CF["ItmClasses"][f][i] == nil) then
					if module ~= nil then
						if module:lower() == CF["ItmModules"][f][i]:lower() then
							return f, i
						end
					else
						return f, i
					end
				end
			end
		end
	end

	return nil, nil
end
-----------------------------------------------------------------------------------------
--	Put item to storage array. You still need to update filters array if this is a new item.
--	Returns true if added item is new item and you need to sort and update filters
-----------------------------------------------------------------------------------------
CF["PutItemToStorageArray"] = function(arr, preset, class, module)
	-- Find item in storage array
	local found = 0
	local isnew = false

	--print (preset)
	--print (class)

	for j = 1, #arr do
		if arr[j]["Preset"] == preset and arr[j]["Module"] == module then
			found = j
		end
	end

	if found == 0 then
		found = #arr + 1
		arr[found] = {}
		arr[found]["Count"] = 1
		arr[found]["Preset"] = preset
		arr[found]["Module"] = module
		arr[found]["Class"] = class or "HDFirearm"

		isnew = true
	else
		arr[found]["Count"] = arr[found]["Count"] + 1
	end

	return isnew
end
-----------------------------------------------------------------------------------------
--	Searches for given actor in all faction files and returns it's factions and index if found
-----------------------------------------------------------------------------------------
CF["FindActorInFactions"] = function(preset, class, module)
	for fact = 1, #CF["Factions"] do
		local f = CF["Factions"][fact]

		for i = 1, #CF["ActNames"][f] do
			if preset == CF["ActPresets"][f][i] then
				if class == CF["ActClasses"][f][i] or (class == "AHuman" and CF["ActClasses"][f][i] == nil) then
					if module ~= nil then
						if module == CF["ActModules"][f][i] then
							return f, i
						end
					else
						return f, i
					end
				end
			end
		end
	end

	return nil, nil
end
-----------------------------------------------------------------------------------------
--	Returns sorted array of stored items from game state. If makefilters is true, then
--	it will also return additional array with filtered items
-----------------------------------------------------------------------------------------
CF["GetClonesArray"] = function(gs)
	local arr = {}

	-- Copy clones
	for i = 1, CF["MaxClones"] do
		if gs["ClonesStorage" .. i .. "Preset"] ~= nil then
			arr[i] = {}
			arr[i]["Preset"] = gs["ClonesStorage" .. i .. "Preset"]
			arr[i]["Class"] = gs["ClonesStorage" .. i .. "Class"]
			arr[i]["Module"] = gs["ClonesStorage" .. i .. "Module"]
			arr[i]["Module"] = gs["ClonesStorage" .. i .. "Module"]
			arr[i]["XP"] = gs["ClonesStorage" .. i .. "XP"]
			arr[i]["Identity"] = gs["ClonesStorage" .. i .. "Identity"]
			arr[i]["Player"] = gs["ClonesStorage" .. i .. "Player"]
			arr[i]["Prestige"] = gs["ClonesStorage" .. i .. "Prestige"]
			arr[i]["Name"] = gs["ClonesStorage" .. i .. "Name"]
			for j = 1, #CF["LimbID"] do
				arr[i][CF["LimbID"][j]] = gs["ClonesStorage" .. i .. CF["LimbID"][j]]
			end

			arr[i]["Items"] = {}
			for itm = 1, CF["MaxItems"] do
				if gs["ClonesStorage" .. i .. "Item" .. itm .. "Preset"] ~= nil then
					arr[i]["Items"][itm] = {}
					arr[i]["Items"][itm]["Preset"] = gs["ClonesStorage" .. i .. "Item" .. itm .. "Preset"]
					arr[i]["Items"][itm]["Class"] = gs["ClonesStorage" .. i .. "Item" .. itm .. "Class"]
					arr[i]["Items"][itm]["Module"] = gs["ClonesStorage" .. i .. "Item" .. itm .. "Module"]
				else
					break
				end
			end
		else
			break
		end
	end

	-- Sort clones
	for i = 1, #arr do
		for j = 1, #arr - 1 do
			if arr[j]["Preset"] > arr[j + 1]["Preset"] then
				local c = arr[j]
				arr[j] = arr[j + 1]
				arr[j + 1] = c
			end
		end
	end

	return arr
end

-----------------------------------------------------------------------------------------
--	Counts used clones in clone array
-----------------------------------------------------------------------------------------
CF["CountUsedClonesInArray"] = function(arr)
	return #arr
end
-----------------------------------------------------------------------------------------
--	Saves array of stored items to game state
-----------------------------------------------------------------------------------------
CF["SetClonesArray"] = function(gs, arr)
	-- Clean clones
	for i = 1, CF["MaxClones"] do
		gs["ClonesStorage" .. i .. "Preset"] = nil
		gs["ClonesStorage" .. i .. "Class"] = nil
		gs["ClonesStorage" .. i .. "Module"] = nil
		gs["ClonesStorage" .. i .. "XP"] = nil
		gs["ClonesStorage" .. i .. "Identity"] = nil
		gs["ClonesStorage" .. i .. "Player"] = nil
		gs["ClonesStorage" .. i .. "Prestige"] = nil
		gs["ClonesStorage" .. i .. "Name"] = nil
		for j = 1, #CF["LimbID"] do
			gs["ClonesStorage" .. i .. CF["LimbID"][j]] = nil
		end

		for itm = 1, CF["MaxItems"] do
			gs["ClonesStorage" .. i .. "Item" .. itm .. "Preset"] = nil
			gs["ClonesStorage" .. i .. "Item" .. itm .. "Class"] = nil
			gs["ClonesStorage" .. i .. "Item" .. itm .. "Module"] = nil
		end
	end

	-- Save clones
	for i = 1, #arr do
		gs["ClonesStorage" .. i .. "Preset"] = arr[i]["Preset"]
		gs["ClonesStorage" .. i .. "Class"] = arr[i]["Class"]
		gs["ClonesStorage" .. i .. "Module"] = arr[i]["Module"]
		gs["ClonesStorage" .. i .. "XP"] = arr[i]["XP"]
		gs["ClonesStorage" .. i .. "Identity"] = arr[i]["Identity"]
		gs["ClonesStorage" .. i .. "Player"] = arr[i]["Player"]
		gs["ClonesStorage" .. i .. "Prestige"] = arr[i]["Prestige"]
		gs["ClonesStorage" .. i .. "Name"] = arr[i]["Name"]
		for j = 1, #CF["LimbID"] do
			gs["ClonesStorage" .. i .. CF["LimbID"][j]] = arr[i][CF["LimbID"][j]]
		end

		--print (tostring(i).." "..arr[i]["Preset"])
		--print (tostring(i).." "..arr[i]["Class"])

		for itm = 1, #arr[i]["Items"] do
			gs["ClonesStorage" .. i .. "Item" .. itm .. "Preset"] = arr[i]["Items"][itm]["Preset"]
			gs["ClonesStorage" .. i .. "Item" .. itm .. "Class"] = arr[i]["Items"][itm]["Class"]
			gs["ClonesStorage" .. i .. "Item" .. itm .. "Module"] = arr[i]["Items"][itm]["Module"]

			--print (tostring(i).." "..itm.." "..arr[i]["Items"][itm]["Preset"])
			--print (tostring(i).." "..itm.." "..arr[i]["Items"][itm]["Class"])
		end
	end
end
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
CF["PutTurretToStorageArray"] = function(arr, preset, class, module)
	-- Find item in storage array
	local found = 0
	local isnew = false

	--print (preset)
	--print (class)

	for j = 1, #arr do
		if arr[j]["Preset"] == preset then
			found = j
		end
	end

	if found == 0 then
		found = #arr + 1
		arr[found] = {}
		arr[found]["Count"] = 1
		arr[found]["Preset"] = preset
		arr[found]["Class"] = class or "AHuman"
		arr[found]["Module"] = module
		isnew = true
	else
		arr[found]["Count"] = arr[found]["Count"] + 1
	end

	return isnew
end
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
CF["GetTurretsArray"] = function(gs)
	local arr = {}

	-- Copy
	for i = 1, CF["MaxTurrets"] do
		if gs["TurretsStorage" .. i .. "Preset"] ~= nil then
			arr[i] = {}
			arr[i]["Preset"] = gs["TurretsStorage" .. i .. "Preset"]
			arr[i]["Class"] = gs["TurretsStorage" .. i .. "Class"]
			arr[i]["Module"] = gs["TurretsStorage" .. i .. "Module"]
			arr[i]["Count"] = tonumber(gs["TurretsStorage" .. i .. "Count"])
		else
			break
		end
	end

	-- Sort
	for i = 1, #arr do
		for j = 1, #arr - 1 do
			if arr[j]["Preset"] > arr[j + 1]["Preset"] then
				local c = arr[j]
				arr[j] = arr[j + 1]
				arr[j + 1] = c
			end
		end
	end

	return arr
end

-----------------------------------------------------------------------------------------
--	Counts used clones in clone array
-----------------------------------------------------------------------------------------
CF["CountUsedTurretsInArray"] = function(arr)
	local count = 0

	for i = 1, #arr do
		count = count + arr[i]["Count"]
	end

	return count
end
-----------------------------------------------------------------------------------------
--	Saves array of stored items to game state
-----------------------------------------------------------------------------------------
CF["SetTurretsArray"] = function(gs, arr)
	-- Clean clones
	for i = 1, CF["MaxTurrets"] do
		gs["TurretsStorage" .. i .. "Preset"] = nil
		gs["TurretsStorage" .. i .. "Class"] = nil
		gs["TurretsStorage" .. i .. "Module"] = nil
		gs["TurretsStorage" .. i .. "Count"] = nil
	end

	-- Save
	for i = 1, #arr do
		if gs["TurretsStorage" .. i .. "Preset"] == "Remove turret" then
			break
		else
			gs["TurretsStorage" .. i .. "Preset"] = arr[i]["Preset"]
			gs["TurretsStorage" .. i .. "Class"] = arr[i]["Class"]
			gs["TurretsStorage" .. i .. "Module"] = arr[i]["Module"]
			gs["TurretsStorage" .. i .. "Count"] = arr[i]["Count"]
		end

		--print (tostring(i).." "..arr[i]["Preset"])
		--print (tostring(i).." "..arr[i]["Class"])
	end
end
-----------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
CF["PutBombToStorageArray"] = function(arr, preset, class, module)
	-- Find item in storage array
	local found = 0
	local isnew = false

	--print (preset)
	--print (class)

	for j = 1, #arr do
		if arr[j]["Preset"] == preset then
			found = j
		end
	end

	if found == 0 then
		found = #arr + 1
		arr[found] = {}
		arr[found]["Count"] = 1
		arr[found]["Preset"] = preset
		arr[found]["Class"] = class or "AHuman"

		arr[found]["Module"] = module
		isnew = true
	else
		arr[found]["Count"] = arr[found]["Count"] + 1
	end

	return isnew
end
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
CF["GetBombsArray"] = function(gs)
	local arr = {}

	-- Copy
	for i = 1, CF["MaxBombs"] do
		if gs["BombsStorage" .. i .. "Preset"] ~= nil then
			arr[i] = {}
			arr[i]["Preset"] = gs["BombsStorage" .. i .. "Preset"]
			arr[i]["Class"] = gs["BombsStorage" .. i .. "Class"]
			arr[i]["Module"] = gs["BombsStorage" .. i .. "Module"]
			arr[i]["Count"] = tonumber(gs["BombsStorage" .. i .. "Count"])
		else
			break
		end
	end

	-- Sort
	for i = 1, #arr do
		for j = 1, #arr - 1 do
			if arr[j]["Preset"] > arr[j + 1]["Preset"] then
				local c = arr[j]
				arr[j] = arr[j + 1]
				arr[j + 1] = c
			end
		end
	end

	return arr
end

-----------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------
CF["CountUsedBombsInArray"] = function(arr)
	local count = 0

	for i = 1, #arr do
		count = count + arr[i]["Count"]
	end

	return count
end
-----------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------
CF["SetBombsArray"] = function(gs, arr)
	-- Clean clones
	for i = 1, CF["MaxBombs"] do
		gs["BombsStorage" .. i .. "Preset"] = nil
		gs["BombsStorage" .. i .. "Class"] = nil
		gs["BombsStorage" .. i .. "Module"] = nil
		gs["BombsStorage" .. i .. "Count"] = nil
	end

	-- Save
	for i = 1, #arr do
		if gs["BombsStorage" .. i .. "Preset"] == "Remove Bomb" then
			break
		else
			gs["BombsStorage" .. i .. "Preset"] = arr[i]["Preset"]
			gs["BombsStorage" .. i .. "Class"] = arr[i]["Class"]
			gs["BombsStorage" .. i .. "Module"] = arr[i]["Module"]
			gs["BombsStorage" .. i .. "Count"] = arr[i]["Count"]
		end

		--print (tostring(i).." "..arr[i]["Preset"])
		--print (tostring(i).." "..arr[i]["Class"])
	end
end
-----------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------
