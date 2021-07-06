if AlphaAPI then
	print("API Already loaded, ignoring file")
else
	local json = require("json")
	
	-- RNG object for when we need to set seeds.
	local rng = RNG()
	local VECTOR_ZERO = Vector(0,0)
	rng:SetSeed(Random(), 1)
	
	local function random(min, max) -- Re-implements math.random()
		if min ~= nil and max ~= nil then -- Min and max passed, integer [min,max]
			return math.floor(rng:RandomFloat() * (max - min + 1) + min)
		elseif min ~= nil then -- Only min passed, integer [0,min]
			return math.floor(rng:RandomFloat() * (min + 1))
		end
		return rng:RandomFloat() -- float [0,1)
	end
	
	local CONFIG = {
		UNLOCKS_ENABLED = true
	}
	
	-- Global object
	AlphaAPI = {
		version = "2.00"
	}
	
	local last_base_item = 729 -- Used in obtaining ItemConfig data.
	
	-- Local object
	-- For data that should be restricted to the API
	local LocalAPI = {
		registeredMods = {},
		unlockQueue = {},
		entityFlags = {0, 1 << 1},
		registeredItems = {},
		registeredCharacters = {},
		registeredTransformations = {},
		ref = RegisterMod("AlphaAPI", 1),
		entityVariants = {},
		sidebarLog = {},
		gridLog = {},
		debugEnabled = true,
		evaluatedRoomIDx = nil
	}
	
	----------------------------------------
	-- Core
	----------------------------------------
	
	do
		local StatObject = {}
		function StatObject:_init(flag, value, modifier, respect_limit, limit)
			if flag == CacheFlag.CACHE_FLYING then
				modifier = "="
			else
				modifier = modifier or "+"
			end
	
			self.flag = flag
			self.value = value
			self.modifier = modifier
	
			if respect_limit == nil then
				if flag == CacheFlag.CACHE_FIREDELAY then
					respect_limit = true
				else
					respect_limit = false
				end
			end
	
			self.limit = limit or 4
			self.respect_limit = respect_limit
		end
	
		function AlphaAPI.createStat(flag, value, modifier, respect_limit, limit)
			local inst = {}
			setmetatable(inst, { __index = StatObject })
			inst:_init(flag, value, modifier, respect_limit, limit)
			return inst
		end
	
		local ItemObject = {}
		function ItemObject:_init(mod, id, name, costume, flags, is_trinket)
			self.mod = mod
			self.id = id
			self.name = name
			self.charge_params = nil
			self.costume = costume
			self.flags = flags
			self.lock = nil
			self.is_trinket = is_trinket
	
			if self.costume or self.flags then
				local enuma = AlphaAPI.Callbacks.ITEM_PICKUP
				local enumb = AlphaAPI.Callbacks.ITEM_REMOVE
				if self.is_trinket then
					enuma = AlphaAPI.Callbacks.TRINKET_PICKUP
					enumb = AlphaAPI.Callbacks.TRINKET_REMOVE
				end
	
				self:addCallback(enuma, function()
					local player = AlphaAPI.GAME_STATE.PLAYERS[1]
					if self.costume then
						player:AddNullCostume(self.costume)
					end
	
					if self.flags then
						for _, flag in ipairs(self.flags) do
							player:AddCacheFlags(flag)
						end
	
						player:EvaluateItems()
					end
				end, true)
	
				self:addCallback(enumb, function()
					local player = AlphaAPI.GAME_STATE.PLAYERS[1]
					if self.costume then
						player:TryRemoveNullCostume(self.costume)
					end
	
					if self.flags then
						for _, flag in ipairs(self.flags) do
							player:AddCacheFlags(flag)
						end
	
						player:EvaluateItems()
					end
				end, true)
			end
		end
	
		function ItemObject:addCallback(enum, fn, singleactivate, h, i, j, k, l, m, n)
			if enum == AlphaAPI.Callbacks.ITEM_UPDATE or
			enum == AlphaAPI.Callbacks.ITEM_USE or
			enum == AlphaAPI.Callbacks.ITEM_PICKUP or
			enum == AlphaAPI.Callbacks.ITEM_REMOVE or
			enum == AlphaAPI.Callbacks.ITEM_CACHE or
			enum == AlphaAPI.Callbacks.TRINKET_UPDATE or
			enum == AlphaAPI.Callbacks.TRINKET_PICKUP or
			enum == AlphaAPI.Callbacks.TRINKET_REMOVE or
			enum == AlphaAPI.Callbacks.TRINKET_CACHE or
			enum == AlphaAPI.Callbacks.CHARGE_SHOOT or
			enum == AlphaAPI.Callbacks.CHARGING or
			enum == AlphaAPI.Callbacks.CHARGE_FAIL then
				self.mod:addCallback(enum, fn, self.id, singleactivate, h, i, j, k, l, m, n)
			else
				self.mod:addCallback(enum, function(a, b, c, d, e, f, g)
					if self.is_trinket then
						if AlphaAPI.GAME_STATE.PLAYERS[1]:HasTrinket(self.id) then
							return fn(a, b, c, d, e, f, g)
						end
					else
						if AlphaAPI.GAME_STATE.PLAYERS[1]:HasCollectible(self.id) then
							return fn(a, b, c, d, e, f, g)
						end
					end
				end, singleactivate, h, i, j, k, l, m, n)
			end
		end
	
		function ItemObject:setChargeParams(priority, tear_modifier, base_delay)
			base_delay = base_delay or 0
			self.charge_params = {priority = priority, tear_modifier = tear_modifier, base_delay = base_delay}
		end
	
		function ItemObject:addLock(lock)
			self.lock = lock
			local variant = PickupVariant.PICKUP_COLLECTIBLE
			if self.is_trinket then
				variant = PickupVariant.PICKUP_TRINKET
			end
	
			self.mod:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, function(entity)
				if not self.lock:isUnlocked() then
					entity:ToPickup():Morph(
						entity.Type,
						entity.Variant,
						0,
						true
					)
				end
			end, EntityType.ENTITY_PICKUP, variant, self.id)
		end
	
		function ItemObject:getEntityConfig()
			local variant = PickupVariant.PICKUP_COLLECTIBLE
			if self.is_trinket then
				variant = PickupVariant.PICKUP_TRINKET
			end
	
			return self.mod:getEntityConfig(EntityType.ENTITY_PICKUP, variant, self.id)
		end
	
		local UnlockObject = {}
		function UnlockObject:_init(mod, unlocked, name)
			self.name = name
			self.mod = mod
			self.unlocked = unlocked
		end
	
		function UnlockObject:setUnlocked(lock)
			if lock ~= self.unlocked and (lock == true or lock == false) then
				self.unlocked = lock
				self.mod.data.unlockValues[self.name] = lock
				self.mod:saveData()
			end
		end
	
		function UnlockObject:isUnlocked()
			if CONFIG.UNLOCKS_ENABLED then
				  return self.unlocked
			else
				return true
			end
		end
	
		local ModObject = {}
		LocalAPI.ModObject = ModObject
		function ModObject:_init(ref)
			self.ref = ref
			self.callbacks = {}
			self.items = {}
			self.unlocks = {}
			self.curseConfigs = {}
			self.entityConfigs = {}
			self.entityVariants = {}
			self.pickupConfigs = {}
			self.cardConfigs = {}
		end
	
		function ModObject:addCallback(a, b, c, d, e, f, g)
			if b == nil then
				error("Callback is nil")
				return
			end
			AlphaAPI.addCallback(self, a, b, c, d, e, f, g)
		end
	
		function ModObject:saveData()
			LocalAPI.saveModData(self)
		end
	
		function ModObject:loadData()
			LocalAPI.loadModData(self)
		end
	
		function ModObject:registerItem(name, costume, flags)
			local inst = {}
			setmetatable(inst, { __index = ItemObject })
			local item_id = Isaac.GetItemIdByName(name)
			if item_id == -1 then
				error("ITEM ID IS -1. This would crash the game. You probably gave the wrong item name!", 2)
				return
			end
	
			if type(costume) == "string" then
				costume = Isaac.GetCostumeIdByPath(costume)
			end
	
			if costume == -1 then
				costume = nil
			end
	
			inst:_init(self, item_id, name, costume, flags)
			LocalAPI.registeredItems[name] = inst
			return inst
		end
	
		function ModObject:registerTrinket(name, costume, flags)
			local inst = {}
			setmetatable(inst, { __index = ItemObject })
			local item_id = Isaac.GetTrinketIdByName(name)
			if item_id == -1 then
				error("TRINKET ID IS -1. This would crash the game. You probably gave the wrong item name!", 2)
				return
			end
	
			if type(costume) == "string" then
				costume = Isaac.GetCostumeIdByPath(costume)
			end
	
			if costume == -1 then
				costume = nil
			end
	
			inst:_init(self, item_id, name, costume, flags, true)
			LocalAPI.registeredItems[name] = inst
			return inst
		end
	
		local TransformationObject = {}
		function TransformationObject:_init(mod, id, name, pool, amount_required)
			self.name = name
			self.pool = pool
			self.amount_required = amount_required
			self.id = id
			self.mod = mod
		end
	
		function TransformationObject:addCallback(enum, fn, c, d, e, f, g)
			if enum == AlphaAPI.Callbacks.TRANSFORMATION_TRIGGER or
			enum == AlphaAPI.Callbacks.TRANSFORMATION_CACHE or
			enum == AlphaAPI.Callbacks.TRANSFORMATION_UPDATE then
				self.mod:addCallback(enum, fn, self.id, d, e, f, g)
			else
				self.mod:addCallback(enum, fn, c, d, e, f, g)
			end
		end
	
		function ModObject:registerTransformation(name, pool, amount_required)
			if not name or not pool then
				error("Transformations require a name and a pool!", 2)
				return
			end
	
			amount_required = amount_required or 3
			local transformation_id
	
			for index, transformation_data in ipairs(LocalAPI.registeredTransformations) do
				if transformation_data.name == name then
					transformation_id = index
				end
			end
	
			if not transformation_id then
				transformation_id = #LocalAPI.registeredTransformations + 1
			end
	
			LocalAPI.registeredTransformations[transformation_id] = {name = name, pool = pool, amount_required = amount_required}
			return transformation_id
		end
	
		function ModObject:createUnlock(name)
			if not name then
				error("Unlocks require a name! For instance, EndorNowHoldsSpiritEye.", 2)
				return
			end
	
			local inst = {}
			setmetatable(inst, { __index = UnlockObject })
			inst:_init(self, false, name)
	
			LocalAPI.unlockQueue[#LocalAPI.unlockQueue + 1] = inst
			return inst
		end
	
		-- A "ref" is what you get from Isaac.RegisterMod()
		function AlphaAPI.registerMod(newModRef)
			-- If a mod is reloaded, overwrite it with a new instance
			-- Otherwise the callbacks would be duplicated
			-- Assumes that no two mods have the same name
			local registerIndex = #LocalAPI.registeredMods + 1
			for i, modObject in pairs(LocalAPI.registeredMods) do
				if newModRef.Name == modObject.ref.Name then
					registerIndex = i
					break
				end
			end
	
			local inst = {}
			setmetatable(inst, { __index = ModObject })
			inst:_init(newModRef)
			LocalAPI.registeredMods[registerIndex] = inst
			return inst
		end
	end
	
	----------------------------------------
	-- Persistent Data Handling
	----------------------------------------
	
	do
		function LocalAPI.saveModData(mod)
			Isaac.SaveModData(mod.ref, json.encode(mod.data))
		end
	
		function LocalAPI.loadModData(mod)
			if Isaac.HasModData(mod.ref) then
				mod.data = json.decode(Isaac.LoadModData(mod.ref))
				if not mod.data then
					mod.data = { run = {}, unlockValues = {} }
					mod:saveData()
				end
			else
				mod.data = { run = {}, unlockValues = {} }
				mod:saveData()
			end
		end
	
		function LocalAPI.saveAPI()
			Isaac.SaveModData(LocalAPI.ref, json.encode(LocalAPI.data))
		end
	
		function LocalAPI.loadAPI()
			if Isaac.HasModData(LocalAPI.ref) then
				LocalAPI.data = json.decode(Isaac.LoadModData(LocalAPI.ref))
			else
				LocalAPI.data = {
					run = {
						inventory = {},
						trinket_inventory = {},
						transformedEntities = {},
						temp_stats = {},
						perm_stats = {},
						transformations = {}
					}
				}
			end
		end
	
		if not LocalAPI.data then
			LocalAPI.loadAPI()
		end
	end
	
	-- to be able to use LocalAPI.dummyMod:addCallback(AlphaAPI.Callbacks, ...
	LocalAPI.dummyMod = AlphaAPI.registerMod(RegisterMod("__AlphAPI Dummy Mod", 1))
	
	----------------------------------------
	-- AlphaAPI State
	----------------------------------------
	do
		AlphaAPI.GAME_STATE = {
			GAME = Game(),
			PLAYERS = {},
			ROOM = nil,
			LEVEL = nil
		}
		setmetatable(AlphaAPI.GAME_STATE,
		{
			__index = function(table,key)
				if key == "ROOM" then
					return table.GAME:GetRoom()
				elseif key == "LEVEL" then
					return table.GAME:GetLevel()
				end
			end
		})
		setmetatable(AlphaAPI.GAME_STATE.PLAYERS,
		{
			__index = function(table,key)
				if tonumber(key) > 0 and tonumber(key) < 5 then
					return Isaac.GetPlayer(tonumber(key))
				end
			end
		})
	end
	
	----------------------------------------
	-- Event Handling
	----------------------------------------
	local function triggerEvent(evtName, a, b, c, d, e)
		AlphaAPI.event[evtName] = true
		AlphaAPI.callDelayed(function()
			AlphaAPI.event[evtName] = false
		end, 2)
	
		local enum = AlphaAPI.Callbacks[evtName]
		for _, mod in pairs(LocalAPI.registeredMods) do
			if mod.callbacks[enum] then
				for _, fn in pairs(mod.callbacks[enum]) do
					fn(a, b, c, d, e)
				end
			end
		end
	end
	
	do
		AlphaAPI.event = {}
	
		local roomCleared = false
		local collectibleNum = -1
		local previous_player = nil
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
			local game = AlphaAPI.GAME_STATE.GAME
			local level = AlphaAPI.GAME_STATE.LEVEL
			local room = AlphaAPI.GAME_STATE.ROOM
			local player = AlphaAPI.GAME_STATE.PLAYERS[1]
			local player_type = player:GetPlayerType()
	
			if previous_player == nil or AlphaAPI.event.RUN_STARTED then
				previous_player = player_type
			elseif previous_player ~= player_type then
				triggerEvent("PLAYER_CHANGED", player, previous_player)
				previous_player = player_type
			end
	
			if room:IsClear() and not roomCleared then
				triggerEvent("ROOM_CLEARED", room)
				roomCleared = true
			end
	
			local collectible_count = player:GetCollectibleCount()
			if collectible_count ~= collectibleNum then
				if collectible_count < collectibleNum then
					triggerEvent("COLLECTIBLES_LOST", collectible_count)
				else
					triggerEvent("COLLECTIBLES_GAINED", collectible_count)
				end
	
				collectibleNum = collectible_count
				triggerEvent("COLLECTIBLES_CHANGED", collectibleNum)
			end
	
			--Update room entities for the 'entities' table
			LocalAPI.evaluateEntities()
		end)
	
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
			if player.Variant == 0 then -- Main player being loaded
				for _, mod in pairs(LocalAPI.registeredMods) do
					mod:loadData()
				end
				LocalAPI.loadAPI()
	
				for _, unlock in pairs(LocalAPI.unlockQueue) do
					local unlocked = false
					if unlock.mod.data.unlockValues then
						if unlock.mod.data.unlockValues[unlock.name] then
							unlocked = unlock.mod.data.unlockValues[unlock.name]
						else
							unlock.mod.data.unlockValues[unlock.name] = false
						end
					else
						unlock.mod.data.unlockValues = {[unlock.name] = false}
					end
	
					unlock.unlocked = unlocked
				end
	
				if AlphaAPI.GAME_STATE.GAME:GetFrameCount() < 1 then
					for i, mod in pairs(LocalAPI.registeredMods) do
						mod.data.run = {}
						mod:saveData()
					end
	
					LocalAPI.data.run = {
						inventory = {},
						trinket_inventory = {},
						transformedEntities = {},
						temp_stats = {},
						perm_stats = {},
						transformations = {}
					}
					collectibleNum = -1
					previous_player = nil
					LocalAPI.saveAPI()
				end
			end
	
			AlphaAPI.GAME_STATE.PLAYERS[1] = Isaac.GetPlayer(0)
			AlphaAPI.GAME_STATE.PLAYERS[2] = Isaac.GetPlayer(1)
			AlphaAPI.GAME_STATE.PLAYERS[3] = Isaac.GetPlayer(2)
			AlphaAPI.GAME_STATE.PLAYERS[4] = Isaac.GetPlayer(3)
		end)
	
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
			AlphaAPI.GAME_STATE.ROOM = AlphaAPI.GAME_STATE.GAME:GetRoom()
			AlphaAPI.GAME_STATE.LEVEL = AlphaAPI.GAME_STATE.GAME:GetLevel()
			LocalAPI.gridLog = {}
			LocalAPI.evaluateEntities()
			if LocalAPI.data.run.temp_stats and #LocalAPI.data.run.temp_stats > 0 then
				for _, stat_data in ipairs(LocalAPI.data.run.temp_stats) do
					player:AddCacheFlags(stat_data.flag)
				end
	
				LocalAPI.data.run.temp_stats = {}
				player:EvaluateItems()
			end
	
			triggerEvent("ROOM_CHANGED", AlphaAPI.GAME_STATE.ROOM)
			if AlphaAPI.GAME_STATE.ROOM:IsFirstVisit() then
				triggerEvent("ROOM_NEW", AlphaAPI.GAME_STATE.ROOM)
			end
	
			for _, stat_data in ipairs(LocalAPI.data.run.temp_stats) do
				player:AddCacheFlags(stat_data.flag)
			end
	
			for _, stat_data in ipairs(LocalAPI.data.run.perm_stats) do
				player:AddCacheFlags(stat_data.flag)
			end
	
			roomCleared = AlphaAPI.GAME_STATE.ROOM:IsClear()
		end)
	
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
			for i, mod in pairs(LocalAPI.registeredMods) do
				mod:saveData()
			end
			LocalAPI.saveAPI()
	
			AlphaAPI.GAME_STATE.LEVEL = AlphaAPI.GAME_STATE.GAME:GetLevel()
			LocalAPI.evaluateEntities()
			triggerEvent("FLOOR_CHANGED", AlphaAPI.GAME_STATE.LEVEL)
		end)
	
		LocalAPI.ref:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function(_, save)
			if save then
				for i, mod in pairs(LocalAPI.registeredMods) do
					mod:saveData()
				end
				LocalAPI.saveAPI()
			end
		end)
	
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
			LocalAPI.evaluateEntities()
			if not continued then
				triggerEvent("RUN_STARTED")
			else
				triggerEvent("RUN_CONTINUED")
			end
		end)
	end
	
	----------------------------------------
	-- Customized Callbacks
	----------------------------------------
	
	do
		local enum = function(d, bitwise, add)
			local _d = {}
			if not add then add = 0 end
			if bitwise then
				local p = 1
				for _, v in pairs(d) do
					_d[v] = p
					p = p*2
				end
			else
				local i = 1
				for _, v in pairs(d) do
					_d[v] = i + add
					i = i+1
				end
			end
			return _d
		end
	
		AlphaAPI.Callbacks = enum({
			-- Global Events
			"RUN_STARTED",
			"RUN_CONTINUED",
			"FLOOR_CHANGED",
			"ROOM_CHANGED",
			"ROOM_CLEARED",
			"ROOM_NEW",
			"PLAYER_CHANGED",
			"COLLECTIBLES_CHANGED",
			"COLLECTIBLES_LOST",
			"COLLECTIBLES_GAINED",
			"CHALLENGE_COMPLETED",
			"PLAYER_DIED",
			-- Entity Callbacks
			"ENTITY_APPEAR",
			"ENTITY_UPDATE",
			"ENTITY_DEATH",
			"ENTITY_DAMAGE",
			"ENTITY_RENDER",
	
			-- Familiar Callbacks
			"FAMILIAR_INIT",
			"FAMILIAR_UPDATE",
	
			-- Transformation Callbacks
			"TRANSFORMATION_TRIGGER",
			"TRANSFORMATION_UPDATE",
			"TRANSFORMATION_CACHE",
			-- Item Callbacks
			"ITEM_PICKUP",
			"ITEM_REMOVE",
			"ITEM_UPDATE",
			"ITEM_CACHE",
			"ITEM_USE", -- Shorthand for MC_USE_ITEM that works w/ ItemObject
			-- Trinket Callbacks
			"TRINKET_PICKUP",
			"TRINKET_REMOVE",
			"TRINKET_UPDATE",
			"TRINKET_CACHE",
			-- Charge Item Callbacks
			"CHARGING",
			"CHARGE_FAIL",
			"CHARGE_SHOOT",
			--- Pickup callbacks
			"CARD_USE",
			"PICKUP_PICKUP",
			-- Curse Callbacks
			"CURSE_TRIGGER",
			"CURSE_UPDATE"
		}, false, 100)
	
		AlphaAPI.OverlayType = enum{
			"STREAK",
			"UNLOCK",
			"GIANT_BOOK"
		}
	
		AlphaAPI.CustomFlags = {
			ALL = 1,
			NO_TRANSFORM = 2
		}
	
		local function triggerEntityCallbacks(data, entity, keys, enum)
			for _, key in pairs(keys) do
				for _, mod in pairs(LocalAPI.registeredMods) do
					if mod.callbacks[enum] and mod.callbacks[enum][key] then
						for _, fn in pairs(mod.callbacks[enum][key]) do
							fn(entity, data, entity:GetSprite())
						end
					end
				end
			end
		end
	
		function LocalAPI.generateEntityKeys(entity)
			local keys = {}
			local key = "e"
			keys[1] = key
			key = key..entity.Type
			keys[#keys+1] = key
			key = key.."."..entity.Variant
			keys[#keys+1] = key
			if entity.SubType then
				key = key.."."..entity.SubType
				keys[#keys+1] = key
			end
			return keys
		end
	
		-- Entity callback loop
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
			for _, entity in pairs(AlphaAPI.entities.all) do
				local data = entity:GetData()
				if type(data) ~= "table" then
					data = {}
				end
	
				-- Generate keys based on the
				-- entity's id/variant/subtype
				local keys = LocalAPI.generateEntityKeys(entity)
				local passin = entity:ToNPC() or entity:ToEffect() or entity:ToTear() or entity:ToPickup() or entity:ToFamiliar() or entity:ToLaser() or entity:ToBomb() or entity:ToKnife() or entity:ToPlayer() or entity
	
				if not data.__alphaInit then
					data.__alphaInit = true
					triggerEntityCallbacks(data, passin, keys, AlphaAPI.Callbacks.ENTITY_APPEAR)
				end
	
				triggerEntityCallbacks(data, passin, keys, AlphaAPI.Callbacks.ENTITY_UPDATE)
				if entity:IsDead() then
					if not data.__alphaDied then
						data.__alphaDied = true
						triggerEntityCallbacks(data, passin, keys, AlphaAPI.Callbacks.ENTITY_DEATH)
					end
				else
					data.__alphaDied = false
				end
			end
		end)
	
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_RENDER, function()
			for _, entity in pairs(AlphaAPI.entities.all) do
				local data = entity:GetData()
				if type(data) ~= "table" then
					data = {}
				end
	
				if data.__alphaHeightData then
					AlphaAPI.updateHeightData(data.__alphaHeightData)
					entity.PositionOffset = Vector(0, data.__alphaHeightData.Height)
				end
	
				-- Generate keys based on the
				-- entity's id/variant/subtype
				local keys = LocalAPI.generateEntityKeys(entity)
				local passin = entity:ToNPC() or entity:ToEffect() or entity:ToTear() or entity:ToPickup() or entity:ToFamiliar() or entity:ToLaser() or entity:ToBomb() or entity:ToKnife() or entity:ToPlayer() or entity
	
				triggerEntityCallbacks(data, passin, keys, AlphaAPI.Callbacks.ENTITY_RENDER)
			end
		end)
	
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
			for _, entity in pairs(AlphaAPI.entities.all) do
				local data = entity:GetData()
				if type(data) ~= "table" then
					data = {}
				end
				-- Generate keys based on the
				-- entity's id/variant/subtype
				local keys = LocalAPI.generateEntityKeys(entity)
				local passin = entity:ToNPC() or entity:ToEffect() or entity:ToTear() or entity:ToPickup() or entity:ToFamiliar() or entity:ToLaser() or entity:ToBomb() or entity:ToKnife() or entity:ToPlayer() or entity
	
				if not data.__alphaInit then
					data.__alphaInit = true
					triggerEntityCallbacks(data, passin, keys, AlphaAPI.Callbacks.ENTITY_APPEAR)
				end
			end
		end)
	
		-- Curse Updates
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
			if AlphaAPI.GAME_STATE.LEVEL:GetCurses() > 0 then
				for _, mod in ipairs(LocalAPI.registeredMods) do
					if mod.callbacks[AlphaAPI.Callbacks.CURSE_UPDATE] then
						for _, callback in ipairs(mod.callbacks[AlphaAPI.Callbacks.CURSE_UPDATE]) do
							if AlphaAPI.GAME_STATE.LEVEL:GetCurses() & callback.CURSE.id == callback.CURSE.id then
								callback.FUNCTION()
							end
						end
					end
				end
			end
		end)
	
		-- Curse Evaluation
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_CURSE_EVAL, function(_, curse_flags)
			if curse_flags > 0 then
				local player = AlphaAPI.GAME_STATE.PLAYERS[1]
				local potential_curses = {}
				local curse_select
				local room = AlphaAPI.GAME_STATE.ROOM
				local seed = player.InitSeed + 1
				for _, mod in ipairs(LocalAPI.registeredMods) do
					for _, curse in ipairs(mod.curseConfigs) do
						if seed % (curse.chance) == 0 and (not curse.lock or curse.lock:isUnlocked()) then
							potential_curses[#potential_curses + 1] = curse
						end
					end
				end
	
				if #potential_curses > 1 then
					rng:SetSeed(seed, 0)
					curse_select = potential_curses[random(1, #potential_curses)]
				elseif #potential_curses == 1 then
					curse_select = potential_curses[1]
				end
	
				if curse_select then
					local apply_curse
					for _, mod in pairs(LocalAPI.registeredMods) do
						if mod.callbacks[AlphaAPI.Callbacks.CURSE_TRIGGER] then
							for _, callback in pairs(mod.callbacks[AlphaAPI.Callbacks.CURSE_TRIGGER]) do
								if curse_select.name == callback.CURSE.name then
									apply_curse = callback.FUNCTION()
								end
							end
						end
					end
	
					if apply_curse == false then
						return
					end
	
					return curse_select.id
				end
			end
		end)
	
		-- ITEM CALLBACK HANDLING
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
			for _, mod in ipairs(LocalAPI.registeredMods) do
				if mod.callbacks[AlphaAPI.Callbacks.ITEM_UPDATE] then
					for _, callback in ipairs(mod.callbacks[AlphaAPI.Callbacks.ITEM_UPDATE]) do
						if player:HasCollectible(callback.ITEM) then
							if callback.SINGLEACTIVATE then
								callback.FUNCTION(player)
							else
								for i = 1, player:GetCollectibleNum(callback.ITEM) do
									callback.FUNCTION(player)
								end
							end
						end
					end
				end
	
				if mod.callbacks[AlphaAPI.Callbacks.TRINKET_UPDATE] then
					for _, callback in ipairs(mod.callbacks[AlphaAPI.Callbacks.TRINKET_UPDATE]) do
						if player:HasTrinket(callback.ITEM) then
							callback.FUNCTION(player)
						end
					end
				end
	
				if mod.callbacks[AlphaAPI.Callbacks.TRINKET_PICKUP] then
					for _, callback in ipairs(mod.callbacks[AlphaAPI.Callbacks.TRINKET_PICKUP]) do
						local itemidstring = tostring(callback.ITEM)
						if not LocalAPI.data.run.trinket_inventory[itemidstring] then
							LocalAPI.data.run.trinket_inventory[itemidstring] = false
						end
	
						if player:HasTrinket(callback.ITEM) and not LocalAPI.data.run.trinket_inventory[itemidstring] then
							callback.FUNCTION(player)
							LocalAPI.data.run.trinket_inventory[itemidstring] = true
						end
					end
				end
	
				if mod.callbacks[AlphaAPI.Callbacks.TRINKET_REMOVE] then
					for _, callback in ipairs(mod.callbacks[AlphaAPI.Callbacks.TRINKET_REMOVE]) do
						local itemidstring = tostring(callback.ITEM)
						if not LocalAPI.data.run.trinket_inventory[itemidstring] then
							LocalAPI.data.run.trinket_inventory[itemidstring] = false
						end
	
						if not player:HasTrinket(callback.ITEM) and LocalAPI.data.run.trinket_inventory[itemidstring] then
							callback.FUNCTION(player)
							LocalAPI.data.run.trinket_inventory[itemidstring] = false
						end
					end
				end
	
				-- Collectible Pickup/Removal.
				if AlphaAPI.event.COLLECTIBLES_GAINED then
					if mod.callbacks[AlphaAPI.Callbacks.ITEM_PICKUP] then
						for _, callback in ipairs(mod.callbacks[AlphaAPI.Callbacks.ITEM_PICKUP]) do
							local player_item_count = player:GetCollectibleNum(callback.ITEM)
							local itemidstring = tostring(callback.ITEM)
							if not LocalAPI.data.run.inventory[itemidstring] then
								LocalAPI.data.run.inventory[itemidstring] = 0
							end
	
							if player_item_count > LocalAPI.data.run.inventory[itemidstring] then
								if callback.SINGLEACTIVATE then
									if player_item_count == 1 then
										callback.FUNCTION(player)
									end
								else
									for i = 1, player_item_count - LocalAPI.data.run.inventory[itemidstring] do
										callback.FUNCTION(player)
									end
								end
							end
						end
					end
				end
	
				if AlphaAPI.event.COLLECTIBLES_LOST then
					if mod.callbacks[AlphaAPI.Callbacks.ITEM_REMOVE] then
						for _, callback in ipairs(mod.callbacks[AlphaAPI.Callbacks.ITEM_REMOVE]) do
							local player_item_count = player:GetCollectibleNum(callback.ITEM)
							local itemidstring = tostring(callback.ITEM)
							if not LocalAPI.data.run.inventory[itemidstring] then
								LocalAPI.data.run.inventory[itemidstring] = 0
							end
	
							if player_item_count < LocalAPI.data.run.inventory[itemidstring] then
								if callback.SINGLEACTIVATE then
									if player_item_count == 0 then
										callback.FUNCTION(player)
									end
								else
									for i = 1, LocalAPI.data.run.inventory[itemidstring] - player_item_count do
										callback.FUNCTION(player)
									end
								end
							end
						end
					end
				end
			end
	
			if AlphaAPI.event.COLLECTIBLES_CHANGED then
				for key, value in pairs(LocalAPI.data.run.inventory) do
					LocalAPI.data.run.inventory[key] = player:GetCollectibleNum(tonumber(key))
				end
			end
		end)
	
		-- Easy Stats
		LocalAPI.ref:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, cache_flag)
			local stat_adjustments = {}
	
			for _, character in ipairs(LocalAPI.registeredCharacters) do
				if player:GetPlayerType() == character.player_type then
					if character.stats then
						for _, stat in ipairs(character.stats) do
							stat_adjustments[#stat_adjustments + 1] = stat
						end
					end
				end
			end
	
			for _, mod in ipairs(LocalAPI.registeredMods) do
				if mod.callbacks[AlphaAPI.Callbacks.ITEM_CACHE] then
					for _, callback in ipairs(mod.callbacks[AlphaAPI.Callbacks.ITEM_CACHE]) do
						if player:HasCollectible(callback.ITEM) then
							if callback.SINGLEACTIVATE then
								callback.FUNCTION(player, cache_flag)
							else
								for i = 1, player:GetCollectibleNum(callback.ITEM) do
									callback.FUNCTION(player, cache_flag)
								end
							end
						end
					end
				end
	
				if mod.callbacks[AlphaAPI.Callbacks.TRINKET_CACHE] then
					for _, callback in ipairs(mod.callbacks[AlphaAPI.Callbacks.TRINKET_CACHE]) do
						if player:HasTrinket(callback.ITEM) then
							callback.FUNCTION(player, cache_flag)
						end
					end
				end
			end
	
			if LocalAPI.data.run.temp_stats and #LocalAPI.data.run.temp_stats > 0 then
				for _, stat_data in ipairs(LocalAPI.data.run.temp_stats) do
					stat_adjustments[#stat_adjustments + 1] = stat_data
				end
			end
	
			if LocalAPI.data.run.perm_stats and #LocalAPI.data.run.perm_stats > 0 then
				for _, stat_data in ipairs(LocalAPI.data.run.perm_stats) do
					stat_adjustments[#stat_adjustments + 1] = stat_data
				end
			end
	
			for _, stat_data in ipairs(stat_adjustments) do
				if stat_data.flag == cache_flag then
					if cache_flag == CacheFlag.CACHE_DAMAGE then
						if stat_data.modifier == "+" then
							player.Damage = player.Damage + stat_data.value
						elseif stat_data.modifier == "-" then
							player.Damage = player.Damage - stat_data.value
						elseif stat_data.modifier == "*" then
							player.Damage = player.Damage * stat_data.value
						elseif stat_data.modifier == "/" then
							player.Damage = player.Damage / stat_data.value
						elseif stat_data.modifier == "=" then
							player.Damage = stat_data.value
						else
							error("Invalid Operator: "..tostring(stat_data.modifier), 2)
						end
					elseif cache_flag == CacheFlag.CACHE_FIREDELAY then
						if not stat_data.respect_tears_limit then
							if stat_data.modifier == "+" then
								player.MaxFireDelay = math.floor(player.MaxFireDelay + stat_data.value)
							elseif stat_data.modifier == "-" then
								player.MaxFireDelay = math.floor(player.MaxFireDelay - stat_data.value)
							elseif stat_data.modifier == "*" then
								player.MaxFireDelay = math.floor(player.MaxFireDelay * stat_data.value)
							elseif stat_data.modifier == "/" then
								player.MaxFireDelay = math.floor(player.MaxFireDelay / stat_data.value)
							elseif stat_data.modifier == "=" then
								player.MaxFireDelay = stat_data.value
							else
								error("Invalid Operator: "..tostring(stat_data.modifier), 2)
							end
						else
							if stat_data.modifier == "+" then
								if player.MaxFireDelay < stat_data.limit and player.MaxFireDelay + stat_data.value < stat_data.limit then
								elseif player.MaxFireDelay + stat_data.value < stat_data.limit then
									player.MaxFireDelay = stat_data.limit
								else
									player.MaxFireDelay = math.floor(player.MaxFireDelay + stat_data.value)
								end
							elseif stat_data.modifier == "-" then
								if player.MaxFireDelay < stat_data.limit and player.MaxFireDelay - stat_data.value < stat_data.limit then
								elseif player.MaxFireDelay - stat_data.value < stat_data.limit then
									player.MaxFireDelay = stat_data.limit
								else
									player.MaxFireDelay = math.floor(player.MaxFireDelay - stat_data.value)
								end
							elseif stat_data.modifier == "*" then
								if player.MaxFireDelay < stat_data.limit and player.MaxFireDelay * stat_data.value < stat_data.limit then
								elseif player.MaxFireDelay * stat_data.value < stat_data.limit then
									player.MaxFireDelay = stat_data.limit
								else
									player.MaxFireDelay = math.floor(player.MaxFireDelay * stat_data.value)
								end
							elseif stat_data.modifier == "/" then
								if player.MaxFireDelay < stat_data.limit and player.MaxFireDelay / stat_data.value < stat_data.limit then
								elseif player.MaxFireDelay / stat_data.value < stat_data.limit then
									player.MaxFireDelay = stat_data.limit
								else
									player.MaxFireDelay = math.floor(player.MaxFireDelay / stat_data.value)
								end
							else
								error("Invalid Operator: "..tostring(stat_data.modifier), 2)
							end
						end
					elseif cache_flag == CacheFlag.CACHE_LUCK then
						if stat_data.modifier == "+" then
							player.Luck = player.Luck + stat_data.value
						elseif stat_data.modifier == "-" then
							player.Luck = player.Luck - stat_data.value
						elseif stat_data.modifier == "*" then
							player.Luck = player.Luck * stat_data.value
						elseif stat_data.modifier == "/" then
							player.Luck = player.Luck / stat_data.value
						elseif stat_data.modifier == "=" then
							player.Luck = stat_data.value
						else
							error("Invalid Operator: "..tostring(stat_data.modifier), 2)
						end
					elseif cache_flag == CacheFlag.CACHE_SHOTSPEED then
						if stat_data.modifier == "+" then
							player.ShotSpeed = player.ShotSpeed + stat_data.value
						elseif stat_data.modifier == "-" then
							player.ShotSpeed = player.ShotSpeed - stat_data.value
						elseif stat_data.modifier == "*" then
							player.ShotSpeed = player.ShotSpeed * stat_data.value
						elseif stat_data.modifier == "/" then
							player.ShotSpeed = player.ShotSpeed / stat_data.value
						elseif stat_data.modifier == "=" then
							player.ShotSpeed = stat_data.value
						else
							error("Invalid Operator: "..tostring(stat_data.modifier), 2)
						end
					elseif cache_flag == CacheFlag.CACHE_SPEED then
						if stat_data.modifier == "+" then
							player.MoveSpeed = player.MoveSpeed + stat_data.value
						elseif stat_data.modifier == "-" then
							player.MoveSpeed = player.MoveSpeed - stat_data.value
						elseif stat_data.modifier == "*" then
							player.MoveSpeed = player.MoveSpeed * stat_data.value
						elseif stat_data.modifier == "/" then
							player.MoveSpeed = player.MoveSpeed / stat_data.value
						elseif stat_data.modifier == "=" then
							player.MoveSpeed = stat_data.value
						else
							error("Invalid Operator: "..tostring(stat_data.modifier), 2)
						end
					elseif cache_flag == CacheFlag.CACHE_RANGE then
						if stat_data.modifier == "+" then
							player.TearHeight = player.TearHeight + stat_data.value
						elseif stat_data.modifier == "-" then
							player.TearHeight = player.TearHeight - stat_data.value
						elseif stat_data.modifier == "*" then
							player.TearHeight = player.TearHeight * stat_data.value
						elseif stat_data.modifier == "/" then
							player.TearHeight = player.TearHeight / stat_data.value
						elseif stat_data.modifier == "=" then
							player.TearHeight = stat_data.value
						else
							error("Invalid Operator: "..tostring(stat_data.modifier), 2)
						end
					elseif cache_flag == CacheFlag.CACHE_FLYING then
						if stat_data.modifier == "=" then
							player.CanFly = stat_data.value
						else
							error("Invalid Operator: "..tostring(stat_data.modifier), 2)
						end
					elseif cache_flag == CacheFlag.CACHE_TEARFLAG then
						if stat_data.modifier == "+" then
							player.TearFlags = player.TearFlags | stat_data.value
						elseif stat_data.modifier == "=" then
							player.TearFlags = stat_data.value
						else
							error("Invalid Operator: "..tostring(stat_data.modifier), 2)
						end
					elseif cache_flag == CacheFlag.CACHE_TEARCOLOR then
						if stat_data.modifier == "=" then
							player.TearColor = stat_data.value
						else
							error("Invalid Operator: "..tostring(stat_data.modifier), 2)
						end
					else
						error("No support for given flag!", 2)
					end
				end
			end
		end)
	
		-- CHARGE ITEM HANDLING
		-- input stopping
		LocalAPI.ref:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, cache_flag)
			if LocalAPI.data.run.has_charge_item and cache_flag == CacheFlag.CACHE_FIREDELAY then
				player.MaxFireDelay = player.MaxFireDelay + 999999
			end
		end)
	
		-- actual callback handling
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
			local player = AlphaAPI.GAME_STATE.PLAYERS[1]
			local charge_item
			for _, mod in ipairs(LocalAPI.registeredMods) do
				for name, item in pairs(LocalAPI.registeredItems) do
					if player:HasCollectible(item.id) and item.charge_params then
						if charge_item then
							if item.charge_params.priority > charge_item.charge_params.priority then
								charge_item = item
							end
						else
							charge_item = item
						end
					end
				end
			end
	
			if charge_item and not LocalAPI.data.run.has_charge_item then
				LocalAPI.data.run.has_charge_item = true
				player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
				player:EvaluateItems()
			end
	
			if not charge_item and LocalAPI.data.run.has_charge_item then
				LocalAPI.data.run.has_charge_item = false
				player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
				player:EvaluateItems()
				player.FireDelay = 1
			end
	
			if charge_item then
				local charge_max = charge_item.charge_params.base_delay + AlphaAPI.getChargeFireDelay() * charge_item.charge_params.tear_modifier
				local index = charge_item.id.."Charge"
				if not player:GetData()[index] then
					player:GetData()[index] = 0
				end
	
				if not player:GetData().last_shot_dir then
					player:GetData().last_shot_dir = Vector(0,0)
				end
	
				if (Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, 0) or
						Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, 0) or
						Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, 0) or
						Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, 0)) then
					player:GetData().last_shot_dir = player:GetShootingJoystick()
					for _, mod in ipairs(LocalAPI.registeredMods) do
						if mod.callbacks[AlphaAPI.Callbacks.CHARGING] then
							for _, callback in ipairs(mod.callbacks[AlphaAPI.Callbacks.CHARGING]) do
								if callback.ITEM == charge_item.id then
									callback.FUNCTION(player:GetData().last_shot_dir, player:GetData()[index], charge_max)
								end
							end
						end
					end
	
					player:GetData()[index] = player:GetData()[index] + 1
				elseif player:GetData()[index] >= charge_max then -- Fully charged when released
					for _, mod in ipairs(LocalAPI.registeredMods) do
						if mod.callbacks[AlphaAPI.Callbacks.CHARGE_SHOOT] then
							for _, callback in ipairs(mod.callbacks[AlphaAPI.Callbacks.CHARGE_SHOOT]) do
								if callback.ITEM == charge_item.id then
									callback.FUNCTION(player:GetData().last_shot_dir, player:GetData()[index], charge_max)
								end
							end
						end
					end
	
					player:GetData()[index] = 0
				elseif player:GetData()[index] ~= 0 then
					for _, mod in ipairs(LocalAPI.registeredMods) do
						if mod.callbacks[AlphaAPI.Callbacks.CHARGE_FAIL] then
							for _, callback in ipairs(mod.callbacks[AlphaAPI.Callbacks.CHARGE_FAIL]) do
								if callback.ITEM == charge_item.id then
									callback.FUNCTION(player:GetData().last_shot_dir, player:GetData()[index], charge_max)
								end
							end
						end
					end
	
					player:GetData()[index] = 0
				end
			end
		end)
	
		----------------------------------------
		-- Transformation Handling (TRN)
		----------------------------------------
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
			for id, transformation in ipairs(LocalAPI.registeredTransformations) do
				if not LocalAPI.data.run.transformations[id] then
					LocalAPI.data.run.transformations[id] = {obtained = false, progress = {}}
				end
	
				if not LocalAPI.data.run.transformations[id].obtained then
					for _, item in ipairs(transformation.pool) do
						if type(item) == "table" then
							if item.id then item = item.id end
						end
	
						if not AlphaAPI.tableContains(LocalAPI.data.run.transformations[id].progress, item) and player:HasCollectible(item) then
							LocalAPI.data.run.transformations[id].progress[#LocalAPI.data.run.transformations[id].progress + 1] = item
						end
					end
	
					if #LocalAPI.data.run.transformations[id].progress >= transformation.amount_required then
						LocalAPI.data.run.transformations[id].obtained = true
						for _, mod in ipairs(LocalAPI.registeredMods) do
							if mod.callbacks[AlphaAPI.Callbacks.TRANSFORMATION_TRIGGER] and mod.callbacks[AlphaAPI.Callbacks.TRANSFORMATION_TRIGGER][id] then
								mod.callbacks[AlphaAPI.Callbacks.TRANSFORMATION_TRIGGER][id].FUNCTION()
							end
						end
					end
				elseif LocalAPI.data.run.transformations[id].obtained then
					for _, mod in ipairs(LocalAPI.registeredMods) do
						if mod.callbacks[AlphaAPI.Callbacks.TRANSFORMATION_UPDATE] and mod.callbacks[AlphaAPI.Callbacks.TRANSFORMATION_UPDATE][id] then
							mod.callbacks[AlphaAPI.Callbacks.TRANSFORMATION_UPDATE][id].FUNCTION()
						end
					end
				end
			end
		end)
	
		LocalAPI.ref:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, cache_flag)
			for id, transformation in ipairs(LocalAPI.registeredTransformations) do
				if not LocalAPI.data.run.transformations[id] then
					LocalAPI.data.run.transformations[id] = {obtained = false, progress = {}}
				end
	
				if LocalAPI.data.run.transformations[id].obtained then
					for _, mod in ipairs(LocalAPI.registeredMods) do
						if mod.callbacks[AlphaAPI.Callbacks.TRANSFORMATION_CACHE] and mod.callbacks[AlphaAPI.Callbacks.TRANSFORMATION_CACHE][id] then
							mod.callbacks[AlphaAPI.Callbacks.TRANSFORMATION_CACHE][id].FUNCTION(player, cache_flag)
						end
					end
				end
			end
		end)
	
		--[[
			@param mod 		ModObject instance
			@param enum 	from AlphaAPI.Callbacks
			@param fn 		function callback
			@param ...		variable number of arguments, depending of the enum
		--]]
		function AlphaAPI.addCallback(mod, enum, fn, a, b, c, d, e)
			if not fn then
				error("Nil function passed into callback", 2)
			end
	
			if enum < 100 then
				mod.ref:AddCallback(enum, fn, a, b, c, d, e)
				return
			end
	
			if not mod.callbacks[enum] then
				mod.callbacks[enum] = {}
			end
	
			-- Global events
			if enum == AlphaAPI.Callbacks.RUN_STARTED or
			enum == AlphaAPI.Callbacks.RUN_CONTINUED or
			enum == AlphaAPI.Callbacks.FLOOR_CHANGED or
			enum == AlphaAPI.Callbacks.ROOM_CHANGED or
			enum == AlphaAPI.Callbacks.ROOM_CLEARED or
			enum == AlphaAPI.Callbacks.ROOM_NEW or
			enum == AlphaAPI.Callbacks.PLAYER_CHANGED or
			enum == AlphaAPI.Callbacks.PLAYER_DIED or
			enum == AlphaAPI.Callbacks.CHALLENGE_COMPLETED or
			enum == AlphaAPI.Callbacks.COLLECTIBLES_LOST or
			enum == AlphaAPI.Callbacks.COLLECTIBLES_GAINED or
			enum == AlphaAPI.Callbacks.COLLECTIBLES_CHANGED then
				mod.callbacks[enum][#mod.callbacks[enum]+1] = fn
			end
	
			-- Entity callbacks
			if enum == AlphaAPI.Callbacks.ENTITY_APPEAR or
			enum == AlphaAPI.Callbacks.ENTITY_UPDATE or
			enum == AlphaAPI.Callbacks.ENTITY_RENDER or
			enum == AlphaAPI.Callbacks.ENTITY_DEATH then
				local id, variant, subtype = a, b, c
				-- Generate the unique key for this callback
				local key = "e"
				if id then
					key = key..id
					if variant then
						key = key.."."..variant
						if subtype then
							key = key.."."..subtype
						end
					end
				end
				if not mod.callbacks[enum][key] then
					mod.callbacks[enum][key] = {}
				end
				-- Register the function in the
				-- corresponding key/enum table
				mod.callbacks[enum][key][fn] = fn
			end
	
			-- Pickup callbacks
			if enum == AlphaAPI.Callbacks.PICKUP_PICKUP then
				local pickupConfig = a
				pickupConfig:addCallback(enum, fn)
			end
	
			if enum == AlphaAPI.Callbacks.CARD_USE then
				local cardId = a
				if type(a) == "string" then
					cardId = Isaac.GetCardIdByName(a)
					if cardId == -1 then
						error("CARD ID IS -1. This probably means you gave the wrong name. Reminder: Cards take the hud = '' attribute in the XML as name for some reason!", 2)
						return
					end
				end
				mod.ref:AddCallback(ModCallbacks.MC_USE_CARD, fn, cardId)
			end
	
			-- Transformation callbacks
			if enum == AlphaAPI.Callbacks.TRANSFORMATION_TRIGGER or
			enum == AlphaAPI.Callbacks.TRANSFORMATION_UPDATE or
			enum == AlphaAPI.Callbacks.TRANSFORMATION_CACHE then
				local transformation_id = a
				if type(transformation_id) == "table" then
					transformation_id = transformation_id.id
				end
	
				mod.callbacks[enum][transformation_id] = {
					FUNCTION = fn
				}
			end
	
			-- Item handling callbacks
			if enum == AlphaAPI.Callbacks.ITEM_UPDATE or
			enum == AlphaAPI.Callbacks.ITEM_PICKUP or
			enum == AlphaAPI.Callbacks.ITEM_REMOVE or
			enum == AlphaAPI.Callbacks.ITEM_CACHE or
			enum == AlphaAPI.Callbacks.TRINKET_UPDATE or
			enum == AlphaAPI.Callbacks.TRINKET_PICKUP or
			enum == AlphaAPI.Callbacks.TRINKET_REMOVE or
			enum == AlphaAPI.Callbacks.TRINKET_CACHE then
				local item, singleactivate = a, b
				if type(item) == "table" then
					item = item.id
				end
	
				if type(singleactivate) ~= "boolean" then
					if enum == AlphaAPI.Callbacks.ITEM_UPDATE or enum == AlphaAPI.Callbacks.TRINKET_UPDATE then
						singleactivate = true
					else
						singleactivate = false
					end
				end
	
				mod.callbacks[enum][#mod.callbacks[enum] + 1] = {
					ITEM = item,
					FUNCTION = fn,
					SINGLEACTIVATE = singleactivate
				}
			end
	
			if enum == AlphaAPI.Callbacks.ITEM_USE then
				local item = a
				if type(item) == "table" then
					item = item.id
				end
	
				if item and item > last_base_item then
					mod.ref:AddCallback(ModCallbacks.MC_USE_ITEM, fn, item)
				else
					mod.callbacks[enum][#mod.callbacks[enum] + 1] = {
						ITEM = item,
						FUNCTION = fn
					}
				end
			end
	
			if enum == AlphaAPI.Callbacks.ENTITY_DAMAGE then
				local id, variant, subtype = a, b, c
	
				mod.ref:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, damage_amount, damage_flag, damage_source, invincibility_frames)
					if (not variant or entity.Variant == variant) and (not subtype or entity.SubType == subtype) and (not id or entity.Type == id) then
						return fn(entity, damage_amount, damage_flag, damage_source, invincibility_frames)
					end
				end)
			end
	
			if enum == AlphaAPI.Callbacks.FAMILIAR_UPDATE or
			enum == AlphaAPI.Callbacks.FAMILIAR_INIT then
				local variant, subtype = a, b
				mod.callbacks[enum][#mod.callbacks[enum] + 1] = {
					FUNCTION = fn,
					VARIANT = variant,
					SUBTYPE = subtype
				}
	
	
			end
	
			-- Charge Item Callbacks
			if enum == AlphaAPI.Callbacks.CHARGE_SHOOT or
			enum == AlphaAPI.Callbacks.CHARGING or
			enum == AlphaAPI.Callbacks.CHARGE_FAIL then
				local item = a
				if type(item) == "table" then
					item = item.id
				end
	
				mod.callbacks[enum][#mod.callbacks[enum] + 1] = {
					ITEM = item,
					FUNCTION = fn
				}
			end
	
			-- Curse Callbacks
			if enum == AlphaAPI.Callbacks.CURSE_TRIGGER or
			enum == AlphaAPI.Callbacks.CURSE_UPDATE then
				local curse = a
				mod.callbacks[enum][#mod.callbacks[enum] + 1] = {
					CURSE = curse,
					FUNCTION = fn
				}
			end
		end
	end
	
	LocalAPI.ref:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, familiar)
		for _, mod in ipairs(LocalAPI.registeredMods) do
			if mod.callbacks[AlphaAPI.Callbacks.FAMILIAR_INIT] then
				for _, callback in pairs(mod.callbacks[AlphaAPI.Callbacks.FAMILIAR_INIT]) do
					if (not callback.SUBTYPE or familiar.SubType == callback.SUBTYPE) and (not callback.VARIANT or familiar.Variant == callback.VARIANT) then
						callback.FUNCTION(familiar)
					end
				end
			end
		end
	end)
	
	LocalAPI.ref:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, familiar)
		for _, mod in ipairs(LocalAPI.registeredMods) do
			if mod.callbacks[AlphaAPI.Callbacks.FAMILIAR_UPDATE] then
				for _, callback in pairs(mod.callbacks[AlphaAPI.Callbacks.FAMILIAR_UPDATE]) do
					if (not callback.SUBTYPE or familiar.SubType == callback.SUBTYPE) and (not callback.VARIANT or familiar.Variant == callback.VARIANT) then
						callback.FUNCTION(familiar)
					end
				end
			end
		end
	end)
	
	LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_RENDER, function()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if player:GetLastActionTriggers() & ActionTriggers.ACTIONTRIGGER_ITEMACTIVATED == ActionTriggers.ACTIONTRIGGER_ITEMACTIVATED then
			for _, mod in ipairs(LocalAPI.registeredMods) do
				if mod.callbacks[AlphaAPI.Callbacks.ITEM_USE] then
					for _, callback in pairs(mod.callbacks[AlphaAPI.Callbacks.ITEM_USE]) do
						if callback.ITEM then
							if player:HasCollectible(callback.ITEM) then
								callback.FUNCTION(player, callback.ITEM)
							end
						else
							callback.FUNCTION(player, player:GetActiveItem())
						end
					end
				end
			end
		end
	end)
	
	LocalAPI.dummyMod:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, function()
		triggerEvent("CHALLENGE_COMPLETED", Isaac.GetChallenge())
	end, EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TROPHY)
	
	LocalAPI.dummyMod:addCallback(AlphaAPI.Callbacks.ENTITY_DEATH, function(player, data)
		triggerEvent("PLAYER_DIED", player:ToPlayer(), data)
	end, EntityType.ENTITY_PLAYER)
	
	--------------------------------
	--- Familiar Utility
	--------------------------------
	do
		local function heuristicWeight(room, start, target)
			return (room:GetGridPosition(start) - room:GetGridPosition(target)):LengthSquared()
		end
	
		local GridTileType = {
			FREE = 0,
			OBSTACLE = 1,
			INVALID = 2
		}
	
		local function getPathToTarget(start, target)
			local game = AlphaAPI.GAME_STATE.GAME
			local level = AlphaAPI.GAME_STATE.LEVEL
			local room = AlphaAPI.GAME_STATE.ROOM
			local startIdx = room:GetGridIndex(start)
			local targetIdx = room:GetGridIndex(target)
			local grid = {}
			for i=1, room:GetGridSize() do
				local col = room:GetGridCollision(i)
				if col == 0 then
					grid[i] = GridTileType.FREE
				else
					grid[i] = GridTileType.OBSTACLE
				end
			end
			local w = room:GetGridWidth()
			local success = false
			local closedSet = {}
			local openSet = {}
			openSet[1] = startIdx
			local cameFrom = {}
			local gScore = {}
			for i=1, #grid do
				gScore[i] = 99999999
			end
			gScore[startIdx] = 0
			local fScore = {}
			for i=1, #grid do
				fScore[i] = 99999999
			end
			fScore[startIdx] = heuristicWeight(room, startIdx, targetIdx)
			while #openSet > 0 do
				local current
				local current_openSetIndex
				local best_fScore = 99999999
				for i=1, #openSet do
					if fScore[openSet[i]] < best_fScore then
						current = openSet[i]
						current_openSetIndex = i
						best_fScore = fScore[openSet[i]]
					end
				end
				if current == targetIdx then
					success = true
					break
				end
				table.remove(openSet, current_openSetIndex)
				closedSet[current] = true
				local neighbors = {
					{idx=current-1, cost=1},
					{idx=current+1, cost=1},
					{idx=current-w, cost=1},
					{idx=current+w, cost=1},
				}
				for _,neigh in pairs(neighbors) do
					local n = neigh.idx
					if (grid[n] == GridTileType.FREE or n == targetIdx) and (closedSet[n] ~= true) then
						local tentative_gScore = gScore[current] + 1
						local in_openSet = false
						for i=1, #openSet do
							if openSet[i] == n then
								in_openSet = true
								break
							end
						end
						if (not in_openSet) or tentative_gScore < gScore[n] then
							openSet[#openSet+1] = n
							cameFrom[n] = current
							gScore[n] = tentative_gScore
							fScore[n] = gScore[n] + heuristicWeight(room, n, targetIdx)
						end
					end
				end
			end
			if success then
				local path = {}
				local count = 1
				local current = targetIdx
				while cameFrom[current] do
					current = cameFrom[current]
					count = count + 1
				end
				local current = targetIdx
				if grid[targetIdx] ~= GridTileType.FREE then
					count = count - 1
					current = cameFrom[targetIdx]
				end
				while current do
					path[count] = current
					count = count - 1
					current = cameFrom[current]
				end
				return path
			else
				return nil
			end
		end
	
		local Pathfinder = {}
	
		function Pathfinder:aStarPathing(target, path_update_frame_interval, on_target_collision_fn)
			self.target = target
			if target:Distance(self.entity.Position) <= self.collision_distance and on_target_collision_fn then
				on_target_collision_fn()
			end
	
			if self.entity.FrameCount % path_update_frame_interval == 0 then
				self.path = nil
			end
	
			if not self.path then
				self.path = getPathToTarget(self.entity.Position, target)
				self.entity:GetData().pathidx = 1
			else
				local velocity = AlphaAPI.GAME_STATE.ROOM:GetGridPosition(self.path[self.entity:GetData().pathidx]) - self.entity.Position
				if velocity:Length() < 32 then
					self.entity:GetData().pathidx = self.entity:GetData().pathidx + 1
					if not self.path[self.entity:GetData().pathidx] then
						self.entity:GetData().target_velocity = Vector(0,0)
						self.path = nil
					end
				end
				self.entity:GetData().target_velocity = velocity:Normalized() * 2
			end
			self.entity.Velocity = self.entity.Velocity * 0.9 + self.entity:GetData().target_velocity * self.speed
		end
	
		function Pathfinder:directPathing(target, on_target_collision_fn)
			self.target = target
			if self.target:Distance(self.entity.Position) <= self.collision_distance and on_target_collision_fn then
				on_target_collision_fn()
			end
			self.entity.Velocity = (self.entity.Velocity * 0.9) + ((target - self.entity.Position):Normalized() * 2) * self.speed
		end
	
		function Pathfinder:__init(entity, speed, collision_distance)
			--User defined variables
			self.entity = entity
			self.speed = speed or 10
			self.collision_distance = collision_distance or 25
			--Self contained variables
			self.target = nil
			self.path = nil
		end
	
		function AlphaAPI.getEntityPathfinder(entity, speed, collision_distance)
			local inst = {}
			setmetatable(inst, {__index = Pathfinder})
			inst:__init(entity, speed, collision_distance)
			return inst
		end
	
		function AlphaAPI.animateEntityCardinals(entity, up, down, right, left, idle, forceanim, idle_velocity_threshold)
			if not entity or not up or not down or not right or not left or not idle then
				return nil
			end
			forceanim = forceanim or false
			local velocity = entity.Velocity
			local sprite = entity:GetSprite()
			if velocity:Length() < idle_velocity_threshold then
				sprite:Play(idle, forceanim)
			elseif math.abs(velocity.X) > math.abs(velocity.Y) then
				if velocity.X < 0 and not sprite:IsPlaying(left) then
					sprite:Play(left, forceanim)
				elseif velocity.X >= 0 and not sprite:IsPlaying(right) then
					sprite:Play(right, forceanim)
				end
			else
				if velocity.Y < 0 and not sprite:IsPlaying(up) then
					sprite:Play(up, forceanim)
				elseif velocity.Y >= 0 and not sprite:IsPlaying(down) then
					sprite:Play(down, forceanim)
				end
			end
		end
	
		function AlphaAPI.realignFamiliars()
			local furthest_entity = nil
			for _,entity in ipairs(AlphaAPI.getRoomEntitiesByType(EntityType.ENTITY_FAMILIAR)) do
				if not entity.Child then
					if not furthest_entity then
						furthest_entity = entity
					else
						if furthest_entity.FrameCount < entity.FrameCount then
							furthest_entity.Parent = entity
							entity.Child = furthest_entity
						else
							furthest_entity.Child = entity
							entity.Parent = furthest_entity
						end
					end
				end
			end
		end
	
	end
	
	--------------------------------
	--- Overlays
	--------------------------------
	
	do
	
		local playingOverlays = {}
		local queuedOverlays = {}
		local queuedOverlay
		local overlayVector = Vector(0,0)
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
			for index, overlay in ipairs(playingOverlays) do
				overlay.sprite:Update()
				if overlay.sprite:IsFinished(overlay.anim) then
					--remove the object from the table and move others to close space for ipairs to still work
					table.remove(playingOverlays,index)
				end
			end
			if queuedOverlay then --if there's an overlay in the queue, update it
				queuedOverlay.sprite:Update()
			end
			if queuedOverlay == nil or queuedOverlay.sprite:IsFinished(queuedOverlay.anim) then
				--if the current overlay is finished, get a new one from the queue (table.remove returns the removed object)
				queuedOverlay = table.remove(queuedOverlays,1)
			end
		end)
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_RENDER, function()
			local pos = AlphaAPI.getScreenCenterPosition()
			for index, overlay in ipairs(playingOverlays) do
				--kind of a mess with the vectors, i'm doing this to save some ram
				overlayVector.X = pos.X
				if overlay.type == AlphaAPI.OverlayType.STREAK then
					overlayVector.Y = 48
				else
					overlayVector.Y = pos.Y
				end
	
				overlay.sprite:Render(overlayVector, VECTOR_ZERO, VECTOR_ZERO)
			end
			if queuedOverlay then
				--same mess with vectors here too
				overlayVector.X = pos.X
				if queuedOverlay.type == AlphaAPI.OverlayType.STREAK then
					overlayVector.Y = 48
				else
					overlayVector.Y = pos.Y
				end
	
				queuedOverlay.sprite:Render(overlayVector, VECTOR_ZERO, VECTOR_ZERO)
			end
		end)
	
		local overlayTypes = {
			[AlphaAPI.OverlayType.STREAK] = {
				Anm2Path = "gfx/alpha/ui/overlays/streak.anm2",
				SpritesheetID = 2,
				Anim = "Text",
			},
			[AlphaAPI.OverlayType.UNLOCK] = {
				Anm2Path = "gfx/alpha/ui/overlays/unlock.anm2",
				SpritesheetID = 2,
				Anim = "Appear",
			},
			[AlphaAPI.OverlayType.GIANT_BOOK] = {
				Anm2Path = "gfx/alpha/ui/overlays/giantbook.anm2",
				SpritesheetID = 0,
				Anim = "Appear",
			},
		}
	
		function AlphaAPI.playOverlay(overlayType, pngFilename, queue)
			local overlay = {
				type = overlayType or AlphaAPI.OverlayType.STREAK
			}
	
			print(AlphaAPI.OverlayType.STREAK)
			local overlayTable = overlayTypes[overlay.type]
			for k, v in ipairs(overlayTypes) do
				print(k, v.Anim)
			end
	
			if not overlayTable then
				error("[AlphaAPI] playOverlay() - Overlay type not found!")
				return
			end
			if type(pngFilename) ~= "string" then
				error("[AlphaAPI] playOverlay() - Image path must be a string!")
				return
			end
	
			overlay.sprite = Sprite()
			overlay.sprite:Load(overlayTable.Anm2Path,false)
			overlay.sprite:ReplaceSpritesheet(overlayTable.SpritesheetID, pngFilename)
			overlay.anim = overlayTable.Anim
			overlay.sprite:LoadGraphics()
			overlay.sprite:Play(overlay.anim, true)
	
			if queue then
				--add the sprite to the last position in the queue (to render last)
				table.insert(queuedOverlays,overlay)
			else
				--add the sprite to the last position in the table (to render on top of the previous ones)
				table.insert(playingOverlays,overlay)
			end
			return overlay.sprite
		end
	
		function AlphaAPI.getScreenCenterPosition()
			local room = AlphaAPI.GAME_STATE.ROOM
			local centerOffset = (room:GetCenterPos()) - room:GetTopLeftPos()
			local pos = room:GetCenterPos()
			if centerOffset.X > 260 then
			  pos.X = pos.X - 260
			end
			if centerOffset.Y > 140 then
				pos.Y = pos.Y - 140
			end
			return Isaac.WorldToRenderPosition(pos, false)
		end
	end
	
	--------------------------------
	-- Debug Features
	--------------------------------
	local console_log = {""}
	do
		local console_open = false
		local console_text = ""
		local console_shown = ""
		local console_index = 0
		local code_index = 2
		local press_delay = 0
		local last_pressed_key
	
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_RENDER, function()
			if LocalAPI.debugEnabled then
				if console_open then
					local usable_index = 0
					for _, text in ipairs(console_log) do
						if string.len(text) > 0 then
							usable_index = usable_index + 1
							if usable_index > 15 then
								break
							end
	
							Isaac.RenderText(text, 50, 30 + (usable_index * 12), 255, 255, 255, 1)
						end
					end
	
					Isaac.RenderText("> " .. console_shown .. "|", 12, 230, 255, 255, 255, 1)
				else
					for index, text in ipairs(LocalAPI.sidebarLog) do
						if index > 18 then
							break
						end
						Isaac.RenderText(text, 400 - (6 * string.len(text)), 40 + (index * 12), 255, 255, 255, 1)
					end
				end
	
				local room = AlphaAPI.GAME_STATE.ROOM
				for _, entity in ipairs(AlphaAPI.entities.all) do
					local data = entity:GetData()
					if data.__alphaLog then
						local entity_screen_pos = room:WorldToScreenPosition(entity.Position)
						Isaac.RenderText(data.__alphaLog, entity_screen_pos.X - string.len(data.__alphaLog) * 2, entity_screen_pos.Y, 255, 255, 255, 1)
					end
				end
	
				for i = 0, AlphaAPI.GAME_STATE.ROOM:GetGridSize() do
					if LocalAPI.gridLog[i] then
						local pos = AlphaAPI.GAME_STATE.ROOM:WorldToScreenPosition(AlphaAPI.GAME_STATE.ROOM:GetGridPosition(i))
						Isaac.RenderText(LocalAPI.gridLog[i], pos.X - string.len(LocalAPI.gridLog[i]) * 2, pos.Y, 255, 255, 255, 1)
					end
				end
			end
		end)
	
		local possible_combos = {
			{Keyboard.KEY_A, nil, "a", 1},
			{Keyboard.KEY_A, Keyboard.KEY_LEFT_SHIFT, "A", 2},
			{Keyboard.KEY_A, Keyboard.KEY_RIGHT_SHIFT, "A", 3},
			{Keyboard.KEY_B, nil, "b", 1},
			{Keyboard.KEY_B, Keyboard.KEY_LEFT_SHIFT, "B", 2},
			{Keyboard.KEY_B, Keyboard.KEY_RIGHT_SHIFT, "B", 3},
			{Keyboard.KEY_C, nil, "c", 1},
			{Keyboard.KEY_C, Keyboard.KEY_LEFT_SHIFT, "C", 2},
			{Keyboard.KEY_C, Keyboard.KEY_RIGHT_SHIFT, "C", 3},
			{Keyboard.KEY_D, nil, "d", 1},
			{Keyboard.KEY_D, Keyboard.KEY_LEFT_SHIFT, "D", 2},
			{Keyboard.KEY_D, Keyboard.KEY_RIGHT_SHIFT, "D", 3},
			{Keyboard.KEY_E, nil, "e", 1},
			{Keyboard.KEY_E, Keyboard.KEY_LEFT_SHIFT, "E", 2},
			{Keyboard.KEY_E, Keyboard.KEY_RIGHT_SHIFT, "E", 3},
			{Keyboard.KEY_F, nil, "f", 1},
			{Keyboard.KEY_F, Keyboard.KEY_LEFT_SHIFT, "F", 2},
			{Keyboard.KEY_F, Keyboard.KEY_RIGHT_SHIFT, "F", 3},
			{Keyboard.KEY_G, nil, "g", 1},
			{Keyboard.KEY_G, Keyboard.KEY_LEFT_SHIFT, "G", 2},
			{Keyboard.KEY_G, Keyboard.KEY_RIGHT_SHIFT, "G", 3},
			{Keyboard.KEY_H, nil, "h", 1},
			{Keyboard.KEY_H, Keyboard.KEY_LEFT_SHIFT, "H", 2},
			{Keyboard.KEY_H, Keyboard.KEY_RIGHT_SHIFT, "H", 3},
			{Keyboard.KEY_I, nil, "i", 1},
			{Keyboard.KEY_I, Keyboard.KEY_LEFT_SHIFT, "I", 2},
			{Keyboard.KEY_I, Keyboard.KEY_RIGHT_SHIFT, "I", 3},
			{Keyboard.KEY_J, nil, "j", 1},
			{Keyboard.KEY_J, Keyboard.KEY_LEFT_SHIFT, "J", 2},
			{Keyboard.KEY_J, Keyboard.KEY_RIGHT_SHIFT, "J", 3},
			{Keyboard.KEY_K, nil, "k", 1},
			{Keyboard.KEY_K, Keyboard.KEY_LEFT_SHIFT, "K", 2},
			{Keyboard.KEY_K, Keyboard.KEY_RIGHT_SHIFT, "K", 3},
			{Keyboard.KEY_L, nil, "l", 1},
			{Keyboard.KEY_L, Keyboard.KEY_LEFT_SHIFT, "L", 2},
			{Keyboard.KEY_L, Keyboard.KEY_RIGHT_SHIFT, "L", 3},
			{Keyboard.KEY_M, nil, "m", 1},
			{Keyboard.KEY_M, Keyboard.KEY_LEFT_SHIFT, "M", 2},
			{Keyboard.KEY_M, Keyboard.KEY_RIGHT_SHIFT, "M", 3},
			{Keyboard.KEY_N, nil, "n", 1},
			{Keyboard.KEY_N, Keyboard.KEY_LEFT_SHIFT, "N", 2},
			{Keyboard.KEY_N, Keyboard.KEY_RIGHT_SHIFT, "N", 3},
			{Keyboard.KEY_O, nil, "o", 1},
			{Keyboard.KEY_O, Keyboard.KEY_LEFT_SHIFT, "O", 2},
			{Keyboard.KEY_O, Keyboard.KEY_RIGHT_SHIFT, "O", 3},
			{Keyboard.KEY_P, nil, "p", 1},
			{Keyboard.KEY_P, Keyboard.KEY_LEFT_SHIFT, "P", 2},
			{Keyboard.KEY_P, Keyboard.KEY_RIGHT_SHIFT, "P", 3},
			{Keyboard.KEY_Q, nil, "q", 1},
			{Keyboard.KEY_Q, Keyboard.KEY_LEFT_SHIFT, "Q", 2},
			{Keyboard.KEY_Q, Keyboard.KEY_RIGHT_SHIFT, "Q", 3},
			{Keyboard.KEY_R, nil, "r", 1},
			{Keyboard.KEY_R, Keyboard.KEY_LEFT_SHIFT, "R", 2},
			{Keyboard.KEY_R, Keyboard.KEY_RIGHT_SHIFT, "R", 3},
			{Keyboard.KEY_S, nil, "s", 1},
			{Keyboard.KEY_S, Keyboard.KEY_LEFT_SHIFT, "S", 2},
			{Keyboard.KEY_S, Keyboard.KEY_RIGHT_SHIFT, "S", 3},
			{Keyboard.KEY_T, nil, "t", 1},
			{Keyboard.KEY_T, Keyboard.KEY_LEFT_SHIFT, "T", 2},
			{Keyboard.KEY_T, Keyboard.KEY_RIGHT_SHIFT, "T", 3},
			{Keyboard.KEY_U, nil, "u", 1},
			{Keyboard.KEY_U, Keyboard.KEY_LEFT_SHIFT, "U", 2},
			{Keyboard.KEY_U, Keyboard.KEY_RIGHT_SHIFT, "U", 3},
			{Keyboard.KEY_V, nil, "v", 1},
			{Keyboard.KEY_V, Keyboard.KEY_LEFT_SHIFT, "V", 2},
			{Keyboard.KEY_V, Keyboard.KEY_RIGHT_SHIFT, "V", 3},
			{Keyboard.KEY_W, nil, "w", 1},
			{Keyboard.KEY_W, Keyboard.KEY_LEFT_SHIFT, "W", 2},
			{Keyboard.KEY_W, Keyboard.KEY_RIGHT_SHIFT, "W", 3},
			{Keyboard.KEY_X, nil, "x", 1},
			{Keyboard.KEY_X, Keyboard.KEY_LEFT_SHIFT, "X", 2},
			{Keyboard.KEY_X, Keyboard.KEY_RIGHT_SHIFT, "X", 3},
			{Keyboard.KEY_Y, nil, "y", 1},
			{Keyboard.KEY_Y, Keyboard.KEY_LEFT_SHIFT, "Y", 2},
			{Keyboard.KEY_Y, Keyboard.KEY_RIGHT_SHIFT, "Y", 3},
			{Keyboard.KEY_Z, nil, "z", 1},
			{Keyboard.KEY_Z, Keyboard.KEY_LEFT_SHIFT, "Z", 2},
			{Keyboard.KEY_Z, Keyboard.KEY_RIGHT_SHIFT, "Z", 3},
			{Keyboard.KEY_0, nil, "0", 1},
			{Keyboard.KEY_0, Keyboard.KEY_LEFT_SHIFT, ")", 2},
			{Keyboard.KEY_0, Keyboard.KEY_RIGHT_SHIFT, ")", 3},
			{Keyboard.KEY_1, nil, "1", 1},
			{Keyboard.KEY_1, Keyboard.KEY_LEFT_SHIFT, "!", 2},
			{Keyboard.KEY_1, Keyboard.KEY_RIGHT_SHIFT, "!", 3},
			{Keyboard.KEY_2, nil, "2", 1},
			{Keyboard.KEY_2, Keyboard.KEY_LEFT_SHIFT, "@", 2},
			{Keyboard.KEY_2, Keyboard.KEY_RIGHT_SHIFT, "@", 3},
			{Keyboard.KEY_3, nil, "3", 1},
			{Keyboard.KEY_3, Keyboard.KEY_LEFT_SHIFT, "#", 2},
			{Keyboard.KEY_3, Keyboard.KEY_RIGHT_SHIFT, "#", 3},
			{Keyboard.KEY_4, nil, "4", 1},
			{Keyboard.KEY_4, Keyboard.KEY_LEFT_SHIFT, "$", 2},
			{Keyboard.KEY_4, Keyboard.KEY_RIGHT_SHIFT, "$", 3},
			{Keyboard.KEY_5, nil, "5", 1},
			{Keyboard.KEY_5, Keyboard.KEY_LEFT_SHIFT, "%", 2},
			{Keyboard.KEY_5, Keyboard.KEY_RIGHT_SHIFT, "%", 3},
			{Keyboard.KEY_6, nil, "6", 1},
			{Keyboard.KEY_6, Keyboard.KEY_LEFT_SHIFT, "^", 2},
			{Keyboard.KEY_6, Keyboard.KEY_RIGHT_SHIFT, "^", 3},
			{Keyboard.KEY_7, nil, "7", 1},
			{Keyboard.KEY_7, Keyboard.KEY_LEFT_SHIFT, "&", 2},
			{Keyboard.KEY_7, Keyboard.KEY_RIGHT_SHIFT, "&", 3},
			{Keyboard.KEY_8, nil, "8", 1},
			{Keyboard.KEY_8, Keyboard.KEY_LEFT_SHIFT, "*", 2},
			{Keyboard.KEY_8, Keyboard.KEY_RIGHT_SHIFT, "*", 3},
			{Keyboard.KEY_9, nil, "9", 1},
			{Keyboard.KEY_9, Keyboard.KEY_LEFT_SHIFT, "(", 2},
			{Keyboard.KEY_9, Keyboard.KEY_RIGHT_SHIFT, "(", 3},
			{Keyboard.KEY_MINUS, nil, "-", 1},
			{Keyboard.KEY_MINUS, Keyboard.KEY_LEFT_SHIFT, "_", 2},
			{Keyboard.KEY_MINUS, Keyboard.KEY_RIGHT_SHIFT, "_", 3},
			{Keyboard.KEY_EQUAL, nil, "=", 1},
			{Keyboard.KEY_EQUAL, Keyboard.KEY_LEFT_SHIFT, "+", 2},
			{Keyboard.KEY_EQUAL, Keyboard.KEY_RIGHT_SHIFT, "+", 3},
			{Keyboard.KEY_BACKSLASH, nil, "\\", 1},
			{Keyboard.KEY_BACKSLASH, Keyboard.KEY_LEFT_SHIFT, "|", 2},
			{Keyboard.KEY_BACKSLASH, Keyboard.KEY_RIGHT_SHIFT, "|", 3},
			{Keyboard.KEY_LEFT_BRACKET, nil, "[", 1},
			{Keyboard.KEY_LEFT_BRACKET, Keyboard.KEY_LEFT_SHIFT, "{", 2},
			{Keyboard.KEY_LEFT_BRACKET, Keyboard.KEY_RIGHT_SHIFT, "{", 3},
			{Keyboard.KEY_RIGHT_BRACKET, nil, "]", 1},
			{Keyboard.KEY_RIGHT_BRACKET, Keyboard.KEY_LEFT_SHIFT, "}", 2},
			{Keyboard.KEY_RIGHT_BRACKET, Keyboard.KEY_RIGHT_SHIFT, "}", 3},
			{Keyboard.KEY_SEMICOLON, nil, ";", 1},
			{Keyboard.KEY_SEMICOLON, Keyboard.KEY_LEFT_SHIFT, ":", 2},
			{Keyboard.KEY_SEMICOLON, Keyboard.KEY_RIGHT_SHIFT, ":", 3},
			{Keyboard.KEY_APOSTROPHE, nil, "'", 1},
			{Keyboard.KEY_APOSTROPHE, Keyboard.KEY_LEFT_SHIFT, '"', 2},
			{Keyboard.KEY_APOSTROPHE, Keyboard.KEY_RIGHT_SHIFT, '"', 3},
			{Keyboard.KEY_COMMA, nil, ",", 1},
			{Keyboard.KEY_COMMA, Keyboard.KEY_LEFT_SHIFT, "<", 2},
			{Keyboard.KEY_COMMA, Keyboard.KEY_RIGHT_SHIFT, "<", 3},
			{Keyboard.KEY_PERIOD, nil, ".", 1},
			{Keyboard.KEY_PERIOD, Keyboard.KEY_LEFT_SHIFT, ">", 2},
			{Keyboard.KEY_PERIOD, Keyboard.KEY_RIGHT_SHIFT, ">", 3},
			{Keyboard.KEY_SLASH, nil, "/", 1},
			{Keyboard.KEY_SLASH, Keyboard.KEY_LEFT_SHIFT, "?", 2},
			{Keyboard.KEY_SLASH, Keyboard.KEY_RIGHT_SHIFT, "?", 3},
			{Keyboard.KEY_Q, Keyboard.KEY_LEFT_CONTROL, "~", 4},
			{Keyboard.KEY_Q, Keyboard.KEY_RIGHT_CONTROL, "~", 5},
			{Keyboard.KEY_W, Keyboard.KEY_LEFT_CONTROL, "`", 4},
			{Keyboard.KEY_W, Keyboard.KEY_RIGHT_CONTROL, "`", 5},
			{Keyboard.KEY_ENTER, nil, "ENTER", 97},
			{Keyboard.KEY_ENTER, Keyboard.KEY_LEFT_SHIFT, "ENTERSHIFT", 98},
			{Keyboard.KEY_ENTER, Keyboard.KEY_RIGHT_SHIFT, "ENTERSHIFT", 99},
			{Keyboard.KEY_TAB, nil, "    ", 1},
			{Keyboard.KEY_BACKSPACE, nil, "BACKSPACE", 1},
			{Keyboard.KEY_UP, nil, "UPARROW", 1},
			{Keyboard.KEY_DOWN, nil, "DOWNARROW", 1},
			{Keyboard.KEY_SPACE, nil, " ", 1}
		}
	
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_RENDER, function()
			local player = AlphaAPI.GAME_STATE.PLAYERS[1]
			local controller_id = player.ControllerIndex
			if Input.IsButtonPressed(Keyboard.KEY_LEFT_SHIFT, controller_id) or Input.IsButtonPressed(Keyboard.KEY_RIGHT_SHIFT, controller_id) then
				if Input.IsButtonTriggered(Keyboard.KEY_F3, controller_id) then
					if AlphaAPI.isDebugMode() then
						AlphaAPI.setDebugMode(false)
						AlphaAPI.log("Debug Mode disabled")
					else
						AlphaAPI.setDebugMode(true)
						AlphaAPI.log("Debug Mode enabled")
					end
				end
	
				if AlphaAPI.isDebugMode() then
					if Input.IsButtonTriggered(Keyboard.KEY_1, controller_id) then
						if not console_open then
							console_open = true
							console_text = ""
							console_shown = ""
							console_log = {""}
							console_index = 0
							player.ControlsEnabled = false
							AlphaAPI.log("Console opened!")
							last_pressed_key = Keyboard.KEY_1
							press_delay = 60
						end
					end
				elseif console_open then
					console_open = false
					console_text = ""
					console_shown = ""
					console_log = {""}
					console_index = 0
					player.ControlsEnabled = true
					AlphaAPI.log("Console closed!")
				end
			end
	
			if AlphaAPI.isDebugMode() and console_open then
				local output = LocalAPI.getButtonOutput(possible_combos, controller_id)
				if output then
					if last_pressed_key ~= output.button then
						press_delay = 0
						last_pressed_key = output.button
					end
	
					if press_delay == 0 then
						press_delay = 15
						if output.output == "ENTER" then
							if string.len(console_text) > 0 then
								local custom_func = load(console_text)
								if not pcall(custom_func) then
									table.insert(console_log, 2, "Code Errored")
								end
	
								code_index = 2
								console_text = ""
								table.insert(console_log, 2, console_shown)
								console_shown = ""
								press_delay = 60
							else
								console_open = false
								console_text = ""
								console_shown = ""
								console_log = {""}
								console_index = 0
								player.ControlsEnabled = true
								AlphaAPI.log("Console closed!")
							end
						elseif output.output == "ENTERSHIFT" then
							if string.len(console_shown) > 0 then
								table.insert(console_log, code_index, console_shown)
								code_index = code_index + 1
								console_text = console_text .. " "
								console_shown = ""
								press_delay = 60
							end
						elseif output.output == "BACKSPACE" then
							if string.len(console_shown) > 0 then
								console_text = console_text:sub(1, -2)
								console_shown = console_shown:sub(1, -2)
							end
						elseif output.output == "UPARROW" then
							local new_console_index = console_index + 1
							if console_log[new_console_index] then
								console_text = console_log[new_console_index]
								console_shown = console_log[new_console_index]
								console_index = new_console_index
							end
						elseif output.output == "DOWNARROW" then
							local new_console_index = console_index - 1
							if console_log[new_console_index] then
								console_text = console_log[new_console_index]
								console_shown = console_log[new_console_index]
								console_index = new_console_index
							end
						else
							console_text = console_text .. output.output
							console_shown = console_shown .. output.output
						end
					end
				end
	
	
				if press_delay > 0 then
					press_delay = press_delay - 1
	
					if not Input.IsButtonPressed(last_pressed_key, controller_id) then
						press_delay = 0
					end
				end
			end
		end)
	end
	
	
	--------------------------------
	--- Functions
	--------------------------------
	
	do
		function AlphaAPI.updateHeightData(heightData)
			heightData.Height = heightData.Height + heightData.FallingSpeed
			heightData.FallingSpeed = heightData.FallingSpeed + heightData.FallingAcceleration
			if heightData.Height >= 0 then
				heightData.FallingSpeed = 0
				heightData.Height = 0
				heightData.InAir = false
			else
				heightData.InAir = true
			end
		end
	
		function AlphaAPI.getHeightData(entity)
			entity = AlphaAPI.getEntityFromRef(entity)
			local data = entity:GetData()
			if not data.__alphaHeightData then
				data.__alphaHeightData = {
					FallingSpeed = 0,
					Height = 0,
					FallingAcceleration = 0,
					InAir = false
				}
			end
	
			return data.__alphaHeightData
		end
	
		local tear_sprite_interval = 1 / 4
		local tear_scales = {tear_sprite_interval, tear_sprite_interval * 2, tear_sprite_interval * 3, tear_sprite_interval * 4, tear_sprite_interval * 5, tear_sprite_interval * 6, tear_sprite_interval * 7, tear_sprite_interval * 8, tear_sprite_interval * 9, tear_sprite_interval * 10, tear_sprite_interval * 11, tear_sprite_interval * 12}
		function AlphaAPI.resetSpriteScale(tear, animPrefix)
			tear = tear:ToTear()
			if not animPrefix then animPrefix = "RegularTear" end
			if not tear or not tear:Exists() then error("AlphaAPI.resetSpriteScale called on nil tear!", 2) end
			local end_frame = 13
			for frame, scale in ipairs(tear_scales) do
				if tear.Scale < scale then
					end_frame = frame
					break
				end
			end
	
			tear:GetSprite():Play(animPrefix..tostring(end_frame))
		end
	
		function AlphaAPI.getLastBaseItem()
			return last_base_item
		end
	
		local delayed_functions = {}
		local delayed_functions_sixtyfps = {}
		function AlphaAPI.callDelayed(fn, delay, sixtyfps, a, b, c, d, e)
			if not sixtyfps then
				delayed_functions[#delayed_functions + 1] = {FUNCTION = fn, DELAY = delay, ARGS = {a, b, c, d, e}}
			else
				delayed_functions_sixtyfps[#delayed_functions_sixtyfps + 1] = {FUNCTION = fn, DELAY = delay, ARGS = {a, b, c, d, e}}
			end
		end
	
		local function updateDelayedFunctions()
			for index, fndata in ipairs(delayed_functions) do
				fndata.DELAY = fndata.DELAY - 1
				if fndata.DELAY <= 0 then
					fndata.FUNCTION(fndata.ARGS[1],fndata.ARGS[2],fndata.ARGS[3],fndata.ARGS[4],fndata.ARGS[5])
					table.remove(delayed_functions, index)
				end
			end
		end
	
		local function updateDelayedFunctionsSixtyFPS()
			for index, fndata in ipairs(delayed_functions_sixtyfps) do
				fndata.DELAY = fndata.DELAY - 1
				if fndata.DELAY <= 0 then
					fndata.FUNCTION(fndata.ARGS[1],fndata.ARGS[2],fndata.ARGS[3],fndata.ARGS[4],fndata.ARGS[5])
					delayed_functions_sixtyfps[index] = nil
					table.remove(delayed_functions_sixtyfps, index)
				end
			end
		end
	
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_UPDATE, updateDelayedFunctions)
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_RENDER, updateDelayedFunctionsSixtyFPS)
	
		--table contains one value
		function AlphaAPI.tableContains(tbl, a)
			for _,a_ in ipairs(tbl) do if a_==a then return true end end
		end
	
		function AlphaAPI.matchConfig(entity, entconfig)
			if entity then
				if entconfig.subtype and entity.Entity then
					entity = entity.Entity
				end
	
				if (not entconfig.subtype or entity.SubType == entconfig.subtype) and (not entconfig.variant or entity.Variant == entconfig.variant) and (not entconfig.id or entity.Type == entconfig.id) then
					return true
				end
			else
				error("AlphaAPI.matchConfig(entity, EntityConfig) entity was nil.", 2)
			end
		end
	
		function AlphaAPI.getEntityFromRef(entityref)
			if entityref == nil then return end
			if not entityref.GetData then
				if entityref.Entity then entityref = entityref.Entity end
				if entityref.SubType and not entityref.GetData then
					local entityLookUp = AlphaAPI.entities.keyed[entityref.Type][entityref.Index]
					if entityLookUp then
						return entityLookUp
					end
				elseif entityref.GetData then
					return entityref
				end
			else
				return entityref
			end
	
			return nil
		end
	
		function AlphaAPI.createFlag(name)
			local index = #LocalAPI.entityFlags + 1
			local value = 1 << index
			if name then
				AlphaAPI.CustomFlags[name] = index
			end
			LocalAPI.entityFlags[index] = value
			LocalAPI.entityFlags[AlphaAPI.CustomFlags.ALL] = LocalAPI.entityFlags[AlphaAPI.CustomFlags.ALL] | value
			return index
		end
	
		function AlphaAPI.addFlag(entity, flagid)
			entity = AlphaAPI.getEntityFromRef(entity)
	
			if entity then
				local data = entity:GetData()
				if data.__alphaFlags then
					data.__alphaFlags = data.__alphaFlags | LocalAPI.entityFlags[flagid]
				else
					data.__alphaFlags = LocalAPI.entityFlags[flagid]
				end
			end
		end
	
		function AlphaAPI.hasFlag(entity, flagid)
			entity = AlphaAPI.getEntityFromRef(entity)
	
			if entity then
				local data = entity:GetData()
				if data.__alphaFlags and (data.__alphaFlags & LocalAPI.entityFlags[flagid] == LocalAPI.entityFlags[flagid]) then return true end
			end
		end
	
		function AlphaAPI.clearFlag(entity, flagid)
			entity = AlphaAPI.getEntityFromRef(entity)
	
			if entity then
				local data = entity:GetData()
				if data.__alphaFlags then data.__alphaFlags = data.__alphaFlags & ~LocalAPI.entityFlags[flagid] end
			end
		end
	
		--[[
		AlphaAPI.getWeightedRNG{
			{
				name = "Choice1",
				weight = 1
			},
	
			{
				name = "Choice2",
				weight = 3
			}
		}
		]]
	
		function AlphaAPI.getWeightedRNG(args)
			if type(args) == "table" then
				local weight_value = 0
				local iterated_weight = 0
				for _, attribs in ipairs(args) do
					weight_value = weight_value + attribs.weight
				end
	
				local random_chance = random(weight_value)
				for _, attribs in pairs(args) do
					iterated_weight = iterated_weight + attribs.weight
					if iterated_weight > random_chance then
						return attribs.name
					end
				end
			else
				error("AlphaAPI.getWeightedRNG{} takes a table for its arguments.", 2)
			end
		end
	
		--table intersection
		function AlphaAPI.tableIntersection(a, b)
			local ret = {}
			for _,b_ in ipairs(b) do
				if AlphaAPI.tableContains(a, b_) then table.insert(ret, b_) end
			end
	
			return ret
		end
	
		function LocalAPI.getButtonOutput(possible_buttons, controller)
			local output_data = {nil, nil, nil, 0}
			for _, button_data in ipairs(possible_buttons) do
				if button_data[4] > output_data[4] then
					if Input.IsButtonPressed(button_data[1], controller) then
						if button_data[2] then
							if Input.IsButtonPressed(button_data[2], controller) then
								output_data = button_data
							end
						else
							output_data = button_data
						end
					end
				end
			end
	
			if output_data[1] ~= nil then
				return {output = output_data[3], button = output_data[1]}
			else
				return nil
			end
		end
	
		function AlphaAPI.gridLog(index, text)
			if type(index) ~= "number" then
				if index.GetGridIndex then
					index = index:GetGridIndex()
				end
			end
	
			LocalAPI.gridLog[index] = text
		end
	
		function AlphaAPI.log(text, index)
			if not index then
				table.insert(LocalAPI.sidebarLog, 1, tostring(text))
			else
				LocalAPI.sidebarLog[index] = tostring(text)
			end
		end
	
		function AlphaAPI.consoleLog(text)
			table.insert(console_log, 2, tostring(text))
		end
	
		function AlphaAPI.entityLog(entity, text)
			entity:GetData().__alphaLog = tostring(text)
		end
	
		function AlphaAPI.isDebugMode()
			return LocalAPI.debugEnabled
		end
	
		function AlphaAPI.setDebugMode(boolean)
			if type(boolean) == "boolean" then
				LocalAPI.debugEnabled = boolean
			else error("setDebugMode() requires a boolean, true or false.", 2) end
		end
	
		LocalAPI.entities = {
			all = {},		-- All normal entities
			grid = {},		-- All grid entities
			active = {},	-- Non-effect entities
			effects = {},	-- All Type 1000 entities
			enemies = {},	-- All vulnerable and active enemies.
			friendly = {},	-- Non-effect entities that don't fit into enemies
			keyed = {}      -- Entities stored by key [tostring(entity.Index) .. "." .. tostring(entity.InitSeed)]
		}
	
		function LocalAPI.evaluateEntities()
			LocalAPI.entities.all = Isaac.GetRoomEntities()
			LocalAPI.entities.active = {}
			LocalAPI.entities.friendly = {}
			LocalAPI.entities.enemies = {}
			LocalAPI.entities.effects = {}
			LocalAPI.entities.grid = {}
			LocalAPI.entities.keyed = {}
	
			local active_index = 1
			local friendly_index = 1
			local enemy_index = 1
			local effect_index = 1
			local grid_index = 1
			for _, entity in ipairs(LocalAPI.entities.all) do
				if not LocalAPI.entities.keyed[entity.Type] then LocalAPI.entities.keyed[entity.Type] = {} end
				LocalAPI.entities.keyed[entity.Type][entity.Index] = entity
				if entity.Type == EntityType.ENTITY_EFFECT then
					LocalAPI.entities.effects[effect_index] = entity
					effect_index = effect_index + 1
				else
					if entity:IsVulnerableEnemy() and entity:IsActiveEnemy() then
						LocalAPI.entities.enemies[enemy_index] = entity
						enemy_index = enemy_index + 1
					else
						LocalAPI.entities.friendly[friendly_index] = entity
						friendly_index = friendly_index + 1
					end
					LocalAPI.entities.active[active_index] = entity
					active_index = active_index + 1
				end
			end
			local room = AlphaAPI.GAME_STATE.ROOM
			for i = 0, room:GetGridSize() do
				local entity = room:GetGridEntity(i)
				if entity then
					LocalAPI.entities.grid[grid_index] = entity
					grid_index = grid_index + 1
				end
			end
	
			LocalAPI.evaluatedRoomIDx = AlphaAPI.GAME_STATE.LEVEL:GetCurrentRoomIndex()
		end
	
		AlphaAPI.entities = {
		}
	
		setmetatable(AlphaAPI.entities,
		{
			__index = function(table, key)
				if LocalAPI.entities[key] then
					if AlphaAPI.GAME_STATE.LEVEL:GetCurrentRoomIndex() ~= LocalAPI.evaluatedRoomIDx then
						LocalAPI.evaluateEntities()
					end
	
					return LocalAPI.entities[key]
				end
			end
		})
	
		function AlphaAPI.getRoomEntitiesByType(entity_type, entity_variant, entity_subtype)
			local entities = {}
			if type(entity_type) == "table" and entity_type.id then
				entity_subtype = entity_type.subtype
				entity_variant = entity_type.variant
				entity_type = entity_type.id
			end
	
			if AlphaAPI.entities.keyed[entity_type] then
				for _, entity in pairs(AlphaAPI.entities.keyed[entity_type]) do
					if (not entity_variant or entity.Variant == entity_variant)
					and (not entity_subtype or entity.SubType == entity_subtype) then
						table.insert(entities, entity)
					end
				end
			end
			return entities
		end
	
		function AlphaAPI.findNearestEntity(entity1, entity_table, entity_type, entity_variant, entity_subtype, max_distance, from_position)
			if type(entity_type) == "table" and entity_type.id then
				entity_subtype = entity_type.subtype
				entity_variant = entity_type.variant
				entity_type = entity_type.id
			end
	
			search_pos = entity1.Position
			if from_position then
				search_pos = from_position
			end
	
			if not entity_table then
				entity_table = AlphaAPI.entities.all
			end
	
			local maxDistance = max_distance or 99999999
			local closestEntity
			for _, entity2 in ipairs(entity_table) do
				if (not entity_type or entity2.Type == entity_type) and (not entity_variant or entity2.Variant == entity_variant) and (not entity_subtype or entity2.SubType == entity_subtype) and not AlphaAPI.compareEntities(entity1, entity2) then
					local distance = search_pos:Distance(entity2.Position)
					if distance < maxDistance then
						closestEntity = entity2
						maxDistance = distance
					end
				end
			end
	
			return closestEntity
		end
	
		function AlphaAPI.hasTransformation(transformation_id)
			if not LocalAPI.data.run.transformations[transformation_id] then
				LocalAPI.data.run.transformations[transformation_id] = {obtained = false, progress = {}}
			end
	
			return LocalAPI.data.run.transformations[transformation_id].obtained
		end
	
		function AlphaAPI.addStats(stats, permanent)
			local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	
			if not permanent then
				LocalAPI.data.run.temp_stats[#LocalAPI.data.run.temp_stats + 1] = stats
			else
				LocalAPI.data.run.perm_stats[#LocalAPI.data.run.perm_stats + 1] = stats
			end
	
			player:AddCacheFlags(stats.flag)
			player:EvaluateItems()
		end
	
		-- Find all parents/children of an entity
		local find_all_relatives_blacklist = {
			EntityType.ENTITY_RING_OF_FLIES
		}
	
		function AlphaAPI.findAllRelatives(entity)
			local relative_list = {}
			if not AlphaAPI.tableContains(find_all_relatives_blacklist, entity.Type) then
				local farthest_child = entity:GetLastChild()
				local highest_parent = farthest_child
				while highest_parent.Parent do
					highest_parent = highest_parent.Parent
					relative_list[#relative_list + 1] = highest_parent
				end
			else
				relative_list[#relative_list + 1] = entity
			end
	
			if #relative_list == 0 then
				relative_list[#relative_list + 1] = entity
			end
	
			return relative_list
		end
	
		-- Get Unmodified FireDelay (for charge items)
		function AlphaAPI.getChargeFireDelay()
			local player = AlphaAPI.GAME_STATE.PLAYERS[1]
			return player.MaxFireDelay - 999999
		end
	
		-- Check if two entities are the same.
		function AlphaAPI.compareEntities(entity1, entity2)
			return entity1.Index == entity2.Index, entity1.InitSeed == entity2.InitSeed
		end
	
		-- Shoot Stuff
		function AlphaAPI.fireSpread(spread_degrees, num_projectiles, fire_pos, target_pos, shot_speed, shooting_ent, shot_variant, shot_subtype, shot_type)
			shot_type, shot_subtype, shot_variant, shooting_ent, shot_speed =
					shot_type or EntityType.ENTITY_PROJECTILE,
					shot_subtype or 0,
					shot_variant or 0,
					shooting_ent or nil,
					shot_speed or 6
			local base_direction = (target_pos - fire_pos):Normalized()
			local base_degrees = base_direction:GetAngleDegrees()
			local projectiles = {}
			if num_projectiles % 2 ~= 0 then
				local current_degree_offset = base_degrees + ((num_projectiles / 2) - 1) * spread_degrees
				for i = 1, num_projectiles do
					local shot_motion = Vector.FromAngle(current_degree_offset) * shot_speed
					projectiles[i] = Isaac.Spawn(shot_type,
						shot_variant,
						shot_subtype,
						fire_pos,
						shot_motion,
						shooting_ent)
					projectiles[i]:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
					current_degree_offset = current_degree_offset - spread_degrees
				end
			else
				local clockwise_degree_offset = base_degrees - spread_degrees
				local counterclockwise_degree_offset = base_degrees + spread_degrees
				for i =1, num_projectiles do
					local shot_motion
					if i % 2 == 0 then
						shot_motion = Vector.FromAngle(clockwise_degree_offset) * shot_speed
						clockwise_degree_offset = clockwise_degree_offset - spread_degrees
					else
						shot_motion = Vector.FromAngle(counterclockwise_degree_offset) * shot_speed
						counterclockwise_degree_offset = counterclockwise_degree_offset + spread_degrees
					end
	
					projectiles[i] = Isaac.Spawn(shot_type,
						shot_variant,
						shot_subtype,
						fire_pos,
						shot_motion,
						shooting_ent)
					projectiles[i]:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				end
			end
	
			return projectiles
		end
	
		function AlphaAPI.getLuckRNG(chance, luckfactor)
			local player = AlphaAPI.GAME_STATE.PLAYERS[1]
			return rng:RandomInt(100)  + (player.Luck * luckfactor) + chance >= 100
		end
	end
	
	--------------------------------
	--- EntityConfig
	--------------------------------
	
	do
		local function class(parent)
			parent = parent or {}
			local newClass = {}
			setmetatable(newClass, {__index=parent})
			newClass.super = parent
			function newClass.instantiate(a, b, c, d, e, f, g, h)
				local inst = o or {}
				setmetatable(inst, {__index = newClass})
				if newClass.constructor then
					newClass.constructor(inst, a, b, c, d, e, f, g, h)
				end
				return inst
			end
			return newClass
		end
	
		local Config = class()
		function Config:constructor(mod)
			self.mod = mod
			self.lock = nil
		end
	
		function Config:addLock(lock)
			self.lock = lock
		end
	
		function Config:addCallback(enum, fn, a, b, c, d, e, f, g, h)
			AlphaAPI.addCallback(self.mod, enum, fn, a, b, c, d, e, f, g, h)
		end
	
		local EntityConfig = class(Config)
		function EntityConfig:constructor(mod, id, variant, subtype)
			Config.constructor(self, mod)
			self.id = id
			self.variant = variant
			self.subtype = subtype
		end
	
		function EntityConfig:addCallback(enum, fn, a, b, c, d, e, f, g)
			if enum == AlphaAPI.Callbacks.ENTITY_APPEAR or
			enum == AlphaAPI.Callbacks.ENTITY_UPDATE or
			enum == AlphaAPI.Callbacks.ENTITY_DEATH or
			enum == AlphaAPI.Callbacks.ENTITY_RENDER or
			enum == AlphaAPI.Callbacks.ENTITY_DAMAGE then
				AlphaAPI.addCallback(self.mod, enum, fn, self.id, self.variant, self.subtype)
			elseif enum == AlphaAPI.Callbacks.FAMILIAR_INIT or
			enum == AlphaAPI.Callbacks.FAMILIAR_UPDATE then
				AlphaAPI.addCallback(self.mod, enum, fn, self.variant, self.subtype)
			else
				AlphaAPI.addCallback(self.mod, enum, fn, a, b, c, d, e, f, g)
			end
		end
	
		function EntityConfig:spawn(position, velocity, spawner)
			return Isaac.Spawn(
				self.id,
				self.variant or 0,
				self.subtype or 0,
				position,
				velocity,
				spawner
			)
		end
		--[[ args:
			number          chance (one in X)
			number          id
			number          variant
			number          subtype
			RoomType[]      roomList -- TODO: alt stages
			LevelStage[]    stageList
			number          limitPerRoom -- not implemented
			function        condition
			-- limit per floor, run ???
		--]]
		function EntityConfig:setAsVariant(args)
			local id, variant, subtype = args.id, args.variant, args.subtype
			local key = "e"
			if id then
				key = key..id
				if variant then
					key = key.."."..variant
					if subtype then
						key = key.."."..subtype
					end
				end
			end
			local conditions = args.condition
			if conditions and type(conditions) ~= "table" then
				conditions = {conditions}
			end
			if not self.mod.entityVariants[key] then
				self.mod.entityVariants[key] = {}
			end
			self.mod.entityVariants[key][#self.mod.entityVariants[key]+1] = { -- candidate
				config = self,
				probability = 1/args.chance,
				roomList = args.roomList,
				stageList = args.stageList,
				limitPerRoom = args.limitPerRoom,
				conditions = conditions
			}
		end
		LocalAPI.ref:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
			if (not LocalAPI.data.run.transformedEntities) or AlphaAPI.event.FLOOR_CHANGED then
				LocalAPI.data.run.transformedEntities = {}
			end
		end)
		AlphaAPI.addCallback(LocalAPI.dummyMod, AlphaAPI.Callbacks.ENTITY_APPEAR, function(e)
			-- Check that it itsn't a pickup dropped by the player
			if e.Type == EntityType.ENTITY_PICKUP and
			(e.Variant == PickupVariant.PICKUP_TAROTCARD or
			e.Variant == PickupVariant.PICKUP_PILL or
			e.Variant == PickupVariant.PICKUP_TRINKET) then
				if e.SpawnerType and e.SpawnerType == EntityType.ENTITY_PLAYER then
					return
				end
			end
			-- Check that it's not already been transformed
			if LocalAPI.data.run.transformedEntities == nil or LocalAPI.data.run.transformedEntities[tostring(e.InitSeed)] then
				return
			end
	
	
			local keys = LocalAPI.generateEntityKeys(e)
			local game = AlphaAPI.GAME_STATE.GAME
			local roomType = AlphaAPI.GAME_STATE.ROOM:GetType()
			local stageType = AlphaAPI.GAME_STATE.LEVEL:GetStage()
			local list = {}
			for _, mod in ipairs(LocalAPI.registeredMods) do
				for _, key in ipairs(keys) do
					local variantCandidates = mod.entityVariants[key]
					if variantCandidates then
						for _, candidate in ipairs(variantCandidates) do
							if not candidate.config.lock or candidate.config.lock:isUnlocked() then
								local isAllGood = true
								if candidate.roomList or candidate.stageList then
									local isRoomGood = false
									if candidate.roomList then
										for _, r in pairs(candidate.roomList) do
											if r == roomType then
												isRoomGood = true
												break
											end
										end
									else
										isRoomGood = true
									end
									local isStageGood = false
									if candidate.stageList then
										for _, s in pairs(candidate.stageList) do
											if s == stageType then
												isStageGood = true
												break
											end
										end
									else
										isStageGood = true
									end
									if (not isStageGood) or (not isRoomGood) then
										isAllGood = false
									end
								end
								if isAllGood and candidate.conditions then
									for _, fn in pairs(candidate.conditions) do
										if not fn(e) then
											isAllGood = false
											break
										end
									end
								end
								if isAllGood and candidate.limitPerRoom then
									local count = 0
									for _, e in pairs(AlphaAPI.entities.all) do
										if ((not candidate.config.id) or
										e.Type == candidate.config.id) then
											if ((not candidate.config.variant) or
											e.Variant == candidate.config.variant) then
												if ((not candidate.config.subtype) or
												e.SubType == candidate.config.subtype) then
													count = count + 1
												end
											end
										end
									end
									if count >= candidate.limitPerRoom then
										isAllGood = false
									end
								end
	
								if isAllGood and AlphaAPI.hasFlag(e, AlphaAPI.CustomFlags.NO_TRANSFORM) then
									isAllGood = false
								end
	
								if isAllGood then
									list[#list+1] = candidate -- we good now
								end
							end
						end
					end
				end
			end
			if #list > 0 then
				local pCumul = {}
				local sum = 0
				for i, candidate in ipairs(list) do
					sum = sum + candidate.probability
					pCumul[i] = sum
				end
	
				rng:SetSeed(e.InitSeed, 0)
				local r = rng:RandomFloat()
				if r <= sum then
					for i, p in ipairs(pCumul) do
						if r <= p then
							local choice = list[i]
							if e.Type == EntityType.ENTITY_PICKUP
							and choice.config.id == EntityType.ENTITY_PICKUP then
								e:ToPickup():Morph(
									choice.config.id,
									choice.config.variant or 0,
									choice.config.subtype or 0,
									true
								)
							elseif e.Type >= 10 and e.Type < 1000
							and choice.config.id >= 10 and choice.config.id < 1000 then
								e:ToNPC():Morph(
									choice.config.id,
									choice.config.variant or 0,
									choice.config.subtype or 0,
									-1
								)
								e.HitPoints = e.MaxHitPoints
							else
								e:Remove()
								e = choice.config:spawn(e.Position, e.Velocity, e.SpawnerEntity)
							end
							LocalAPI.data.run.transformedEntities[tostring(e.InitSeed)] = 1
							break -- end
						end
					end
				end
			end
		end)
	
		local PickupConfig = class(EntityConfig)
		function PickupConfig:constructor(mod, variant, subtype)
			EntityConfig.constructor(
				self,
				mod,
				EntityType.ENTITY_PICKUP,
				variant,
				subtype
			)
			self.dropSound = nil
			self.dropCallback = false
			self.collectSound = nil
			self.collisionClass = EntityCollisionClass.ENTCOLL_ALL
			self:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, function(entity, data)
				entity.EntityCollisionClass = self.collisionClass
			end)
	
			self.radius2 = 24*24
		end
		function PickupConfig:setDropSound(soundId)
			self.dropSound = soundId
			if not self.dropCallback then
				self.dropCallback = true
				EntityConfig.addCallback(
					self,
					AlphaAPI.Callbacks.ENTITY_UPDATE,
					function(entity, data)
						local sprite = entity:GetSprite()
						if (not entity:IsDead()) and
						sprite:IsPlaying("Appear") and
						sprite:IsEventTriggered("DropSound") then
							if self.dropSound then
								SFXManager():Play(self.dropSound, 1, 0, false, 1)
							end
						end
					end
				)
			end
		end
		function PickupConfig:setCollectSound(soundId)
			self.collectSound = soundId
		end
		function PickupConfig:setRadius(r)
			self.radius2 = r*r
		end
		function PickupConfig:setCollisionClass(coll_class)
			self.collisionClass = coll_class
		end
		function PickupConfig:addCallback(enum, fn, a, b, c, d, e, f, g)
			if enum == AlphaAPI.Callbacks.PICKUP_PICKUP then
				EntityConfig.addCallback(
					self,
					AlphaAPI.Callbacks.ENTITY_UPDATE,
					function(entity, data)
						local player = AlphaAPI.GAME_STATE.PLAYERS[1]
						if (not entity:IsDead()) and
						player:CanPickupItem() and
						(not entity:GetSprite():IsPlaying("Appear")) and
						(player.Position - entity.Position):LengthSquared() < self.radius2 then
							local ret = fn(player, entity, data)
							if ret then
								if self.collectSound then
									SFXManager():Play(self.collectSound, 1, 0, false, 1)
								end
								entity:GetSprite():Play("Collect", true)
								entity:Die()
							end
						end
					end
				)
			else
				EntityConfig.addCallback(self, enum, fn, a, b, c, d, e, f, g)
			end
		end
	
		local CardConfig = class(PickupConfig)
		function CardConfig:constructor(mod, name)
			local card_id = Isaac.GetCardIdByName(name)
			if card_id == -1 then
				error("CARD ID IS -1. This probably means you gave the wrong name. Reminder: Cards take the hud = '' attribute in the XML as name for some reason!", 2)
				return
			end
	
			PickupConfig.constructor(
				self,
				mod,
				PickupVariant.PICKUP_TAROTCARD,
				card_id
			)
			self.name = name
		end
		function CardConfig:setBackAnimation(anm2)
			self:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, function(e)
				local roomFrame = AlphaAPI.GAME_STATE.ROOM:GetFrameCount()
				local sprite = e:GetSprite()
				sprite:Load(anm2, true)
				if roomFrame <= 1 or e:ToPickup():IsShopItem() then
					sprite:Play("Idle", true)
				else
					sprite:Play("Appear", true)
				end
			end)
		end
		function CardConfig:addCallback(enum, fn, a, b, c, d, e, f, g)
			if enum == AlphaAPI.Callbacks.CARD_USE then
				AlphaAPI.addCallback(self.mod, enum, fn, self.subtype)
			else
				PickupConfig.addCallback(self, enum, fn, a, b, c, d, e, f, g)
			end
		end
	
		local CurseConfig = class(Config)
		function CurseConfig:constructor(mod, name, chance)
			Config.constructor(self, mod)
			self.name = name
	
			local curse_id = Isaac.GetCurseIdByName(name)
			if curse_id == -1 then
				error("Curse not found. Either not properly defined in the XML or you are searching for the wrong name!", 2)
				return
			end
	
			self.id = 1 << (curse_id - 1)
			self.chance = chance
		end
	
		function CurseConfig:addCallback(enum, fn, h, i, j, k, l, m, n)
			if enum == AlphaAPI.Callbacks.CURSE_TRIGGER or
			enum == AlphaAPI.Callbacks.CURSE_UPDATE then
				self.mod:addCallback(enum, fn, self)
			else
				self.mod:addCallback(enum, function(a, b, c, d, e, f, g)
					if AlphaAPI.GAME_STATE.LEVEL:GetCurses() & self.id == self.id then
						return fn(a, b, c, d, e, f, g)
					end
				end, h, i, j, k, l, m, n)
			end
		end
	
		local ModObject = LocalAPI.ModObject
		function ModObject:getCurseConfig(name, chance)
			chance = chance or 20
			local curseConfig
			for _, curse in ipairs(self.curseConfigs) do
				if curse.name == name then
					curseConfig = curse
					break
				end
			end
	
			if not curseConfig then
				curseConfig = CurseConfig.instantiate(self, name, chance)
				self.curseConfigs[#self.curseConfigs + 1] = curseConfig
			end
	
			return curseConfig
		end
	
		function ModObject:getEntityConfig(name, subtype, c)
			local id
			local variant
	
			if type(name) == "string" then
				variant = Isaac.GetEntityVariantByName(name)
				id = Isaac.GetEntityTypeByName(name)
			else
				id = name
				variant = subtype
				subtype = c
			end
	
			local key = "e"
			if id then
				key = key..id
				if variant then
					key = key.."."..variant
					if subtype then
						key = key.."."..subtype
					end
				end
			end
			local entityConfig
			for _, cfg in ipairs(self.entityConfigs) do
				if cfg.key == key then
					entityConfig = cfg
					break
				end
			end
			if not entityConfig then
				entityConfig = EntityConfig.instantiate(self, id, variant, subtype)
				entityConfig.key = key
			end
			self.entityConfigs[#self.entityConfigs+1] = entityConfig
			return entityConfig
		end
		function ModObject:getPickupConfig(variant, subtype)
			local pickupConfig
			if type(variant) == "string" then
				variant = Isaac.GetEntityVariantByName(variant)
			end
	
			for _, cfg in ipairs(self.pickupConfigs) do
				if cfg.variant == variant and cfg.subtype == subtype then
					pickupConfig = cfg
					break
				end
			end
			if not pickupConfig then
				pickupConfig = PickupConfig.instantiate(self, variant, subtype)
			end
			self.pickupConfigs[#self.pickupConfigs+1] = pickupConfig
			return pickupConfig
		end
		function ModObject:getCardConfig(name)
			local cardConfig
			for _, cfg in ipairs(self.cardConfigs) do
				if cfg.name == name then
					cardConfig = cfg
					break
				end
			end
			if not cardConfig then
				cardConfig = CardConfig.instantiate(self, name)
			end
			self.cardConfigs[#self.cardConfigs+1] = cardConfig
			return cardConfig
		end
	end
	
	-- Call the "start" function of
	-- mods that loaded before this API
	if __alphaInit then
		for _, fn in pairs(__alphaInit) do
			fn()
		end
		__alphaInit = {}
	end
	
end
