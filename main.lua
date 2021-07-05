if AlphaAPI then
	print("API Already loaded!")
else
	include("alpha_api.lua")
end

--------------------------------------------------
----------- Alphabirth: Remastered -------------
-- This pack requires the Team Alpha API to run --
--------------------------------------------------

-- You can find it here: http://steamcommunity.com/sharedfiles/filedetails/?id=908404046
-- (sorry for the formatting. -DeadInfinity / meowlala)

-- Imports
local utils = include("code/utils")
local itemLoader = include("code/item_loader")

local mod = RegisterMod("Alphabirth: Remastered", 1) -- Mod variable for callbacks only!
local api_mod -- The AlphaAPI ModObject created for this mod
local Alphabirth = {
	API_MOD = api_mod,
	MOD = mod,
}

-------------------
--  Variable Init
-------------------
Alphabirth.CONFIG = {
	START_ROOM_ENABLED_PACK1 = false,
    START_ROOM_ENABLED_PACK2 = false,
	START_ROOM_ENABLED_PACK3 = true,
    UNLOCKS_ENABLED = true,
    NEW_RUNE_CHANCE = 24,
    ABYSS_PULL_RADIUS = 300,
    CURSE_CHANCES = 8,
    PEANUTBUTTER_CONTROLLER_SWITCH_CHANCE = 240,
    APPARITION_VOLUME = 0.60,
    PLANETOID_MAXSPEED = 10,
    LITTLEMINER_FINDCHANCE = 15,
    LITTLEMINER_MAXPICKUPSPERROOM = 1,
    ITFOLLOWSLASER_SLOWAMOUNT = 1.5,
    INFECTION_TEARCHANCE = 10,
    INFECTION_SPREADCHANCE = 12,
    PEANUTBUTTER_BANNEDENTITIES = {
		EntityType.ENTITY_BUTTLICKER,
		EntityType.ENTITY_SQUIRT,
		EntityType.ENTITY_DINGA,
		EntityType.ENTITY_BIGSPIDER,
		EntityType.ENTITY_MULLIGAN,
		EntityType.ENTITY_HIVE,
		EntityType.ENTITY_NEST,
		EntityType.ENTITY_DUKIE,
		EntityType.ENTITY_SWARMER,
		EntityType.ENTITY_GUTS,
        EntityType.ENTITY_BRAIN
    }
}
Alphabirth.COSTUMES = {}
Alphabirth.CURSES = {}
Alphabirth.ITEMS = {
	ACTIVE = {},
	PASSIVE = {},
	TRINKET = {},
	POCKET = {}
}
Alphabirth.TRANSFORMATIONS = {}
Alphabirth.ENTITIES = {}
Alphabirth.CHALLENGES = {}
Alphabirth.RUN_PARAMS = {}
Alphabirth.ENTITY_FLAGS = {}
Alphabirth.LOCKS = {}
Alphabirth.FAMILIARS = {}
Alphabirth.SOUNDS = {}
Alphabirth.SYNERGIES = {}
Alphabirth.SFX_MANAGER = nil
Alphabirth.PLAYER_TYPES = {}

local stage_number
local frame
local room_frame
local sfx_manager
local beggarscup_previous_total

-- Miscellaneous variables
Alphabirth.PLAYER_TYPES.NULL = Isaac.GetPlayerTypeByName("_NULL")
Alphabirth.PLAYER_TYPES.ENDOR = Isaac.GetPlayerTypeByName("Endor")
Alphabirth.DYNAMIC_ACTIVE_ITEMS = {}
Alphabirth.ITEM_SPRITES = {}

local needs_to_tp_emperor_crown = false
local birthControl_pool

-------------------
--  API Start
-------------------
local function start()
	sfx_manager = SFXManager()
	Alphabirth.SFX_MANAGER = sfx_manager
    Alphabirth.API_MOD = AlphaAPI.registerMod(mod) -- Register the mod with the AlphaAPI

	Alphabirth.itemSetup()
	Alphabirth.entitySetup()
	Alphabirth.setupMiscCallbacks()
	Alphabirth.transformationSetup()
	Alphabirth.curseSetup()
	Alphabirth.miscTablesSetup()
	Alphabirth.miscEntityHandling()
	Alphabirth.activeItemRenderSetup()

	Alphabirth.SOUNDS = {
		SHATTER = Isaac.GetSoundIdByName("Shatter"),
		CANDLE_BLOW = Isaac.GetSoundIdByName("Candle blow"),
        APPARITION_DEATH = Isaac.GetSoundIdByName("Apparition Death")
    }

    Alphabirth.CHALLENGES =
    {
		-- Pack 1
		SHI7TIEST_DAY_EVER = Isaac.GetChallengeIdByName("$#!7tiest day ever!"),
		EXPLODING_HEAD_SYNDROME = Isaac.GetChallengeIdByName("Exploding Head Syndrome!"),
		FAUST = Isaac.GetChallengeIdByName("Faust"),
		-- Pack 2
		EMPTY = Isaac.GetChallengeIdByName("Empty"),
		THE_COLLECTOR = Isaac.GetChallengeIdByName("The Collector"),
		FOR_THE_HOARD = Isaac.GetChallengeIdByName("For the hoard!"),
		RESTLESS_LEG_SYNDROME = Isaac.GetChallengeIdByName("Restless Leg Syndrome!"),
		-- Pack 3
		IT_FOLLOWS = Isaac.GetChallengeIdByName("It follows!")
	}

	-- Register the Waxed transformation along with its trigger callback
	Alphabirth.TRANSFORMATIONS.WAXED = Alphabirth.API_MOD:registerTransformation("Waxed",
	{
		Alphabirth.ITEMS.ACTIVE.GREEN_CANDLE.id,
		Alphabirth.ITEMS.PASSIVE.WHITE_CANDLE.id,
		Alphabirth.ITEMS.PASSIVE.CANDLE_KIT.id,
		CollectibleType.COLLECTIBLE_RED_CANDLE,
		CollectibleType.COLLECTIBLE_CANDLE,
		CollectibleType.COLLECTIBLE_BLACK_CANDLE
	}, 3)

	Alphabirth.API_MOD:addCallback(AlphaAPI.Callbacks.TRANSFORMATION_TRIGGER, function()
        local player = AlphaAPI.GAME_STATE.PLAYERS[1] -- TODO: PASS PLAYER IN TRANDFORMATION FUNC
		player:AddNullCostume(COSTUMES.WAXED)
		AlphaAPI.playOverlay(AlphaAPI.OverlayType.STREAK,"gfx/ui/streak/waxed_streak.png")
		Alphabirth.SFX_MANAGER:Play(SoundEffect.SOUND_POWERUP_SPEWER,1,0,false,1)
	end, Alphabirth.TRANSFORMATIONS.WAXED)

	----------------------------------------
	-- Waxed Transformation
	----------------------------------------


	-- New Room Logic
	function Alphabirth:postNewRoom()
		local room = AlphaAPI.GAME_STATE.ROOM
		local game = AlphaAPI.GAME_STATE.GAME
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]

	    -- Give Null their costume every room so that it never gets overwritten
	    if player:GetPlayerType() == character_null then
	        player:AddNullCostume(COSTUMES.NULL)
	    end


		if game.Challenge == CHALLENGES.IT_FOLLOWS and level:GetCurrentRoomIndex() ~= level:GetStartingRoomIndex() then
			AlphaAPI.callDelayed(function()
				local room = AlphaAPI.GAME_STATE.ROOM
				local laser = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HUSH_LASER, 0, room:GetCenterPos(), Vector(0, 0), nil)
				laser:GetData().itFollowsLaser = true
			end, 10)
		end
	end

    function Alphabirth.floorChanged()
        Alphabirth.API_MOD.data.run.seenTreasure = false
		Alphabirth.API_MOD.data.run.miniatureMeteorBonus = 0
		Alphabirth.API_MOD.data.run.apparitionRooms = {}
    end

	Alphabirth.MOD:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Alphabirth.postNewRoom)
    Alphabirth.MOD:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, Alphabirth.floorChanged)

	----------------------------------------
	-- Callbacks
	----------------------------------------
	function Alphabirth:modUpdate()
		frame = AlphaAPI.GAME_STATE.GAME:GetFrameCount()
		room_frame = AlphaAPI.GAME_STATE.ROOM:GetFrameCount()
	    stage_number = AlphaAPI.GAME_STATE.LEVEL:GetStage()
        local challenge = AlphaAPI.GAME_STATE.GAME.Challenge
        local player = AlphaAPI.GAME_STATE.PLAYERS[1]

        if challenge == CHALLENGES.FAUST and not player:HasTrinket(ITEMS.TRINKET.EMPEROR_CROWN.id) then
            player:AddTrinket(ITEMS.TRINKET.EMPEROR_CROWN.id)
            local trinkets = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, -1, false, false)
            for _, trinket in ipairs(trinkets) do
                trinket:Remove()
            end
        elseif challenge == CHALLENGES.SHI7TIEST_DAY_EVER and not player:HasTrinket(ITEMS.TRINKET.BROWN_EYE.id) then
            player:AddTrinket(ITEMS.TRINKET.BROWN_EYE.id)
            local trinkets = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, -1, false, false)
            for _, trinket in ipairs(trinkets) do
                trinket:Remove()
            end
        end
		if needs_to_tp_emperor_crown then
			player:UseCard(Card.CARD_EMPEROR)
			needs_to_tp_emperor_crown = false
		end
	end
	mod:AddCallback(ModCallbacks.MC_POST_UPDATE, Alphabirth.modUpdate)
	mod:AddCallback(ModCallbacks.MC_POST_RENDER, Alphabirth.handleHumilityEffect)

	function Alphabirth:PostGameStarted(continued)
		if not continued then
			local player = AlphaAPI.GAME_STATE.PLAYERS[1]
			api_mod.data.run.seenTreasure = false
			api_mod.data.run.seenDevil = false
			api_mod.data.run.controller_respawn = 0

		    -- Give Null their starting item and costume
		    if player:GetPlayerType() == character_null then
		        player:AddNullCostume(COSTUMES.NULL)
				-- This line breaks everything idk
	        	-- player:GetSprite():Load("gfx/animations/costumes/players/animation_character_null.anm2",true)
		        local seed = random()
		        seed = math.floor(seed * 8999999999 + 1000000000)
		        player:AddCollectible(AlphaAPI.GAME_STATE.GAME:GetItemPool():GetCollectible(AlphaAPI.GAME_STATE.GAME:GetItemPool():GetLastPool(), true, seed), 0, true)
		        player:AddTrinket(TrinketType.TRINKET_ERROR)

		        for i = 1, 2 do
		            local heart_to_give = random(1,3)
		            if heart_to_give == 1 then
		                player:AddMaxHearts(2)
		                player:AddHearts(2)
		            elseif heart_to_give == 2 then
		                player:AddSoulHearts(2)
		            else
		                player:AddBlackHearts(2)
		            end
				end

				--Add 3 Consumables
				local consumable_count = 3
				while(consumable_count > 0) do
					local type = random(0, 2)
					if type == 0 then
						player:AddKeys(1)
					elseif type == 1 then
						player:AddBombs(1)
					elseif type == 2 then
						player:AddCoins(1)
					end
					consumable_count = consumable_count - 1
				end

		    end

		    if CONFIG.START_ROOM_ENABLED_PACK1 then
	            local new_items = {
	                    ITEMS.ACTIVE.LIFELINE.id,
	                    ITEMS.ACTIVE.ISAAC_APPLE.id,
	                    ITEMS.ACTIVE.COOL_BEAN.id,
	                    ITEMS.ACTIVE.BLACK_PEPPER.id,
	                    ITEMS.ACTIVE.GREEN_CANDLE.id,
	                    ITEMS.ACTIVE.TEARLEPORTER.id,
	                    ITEMS.ACTIVE.DELIRIUMS_BRAIN.id,
	                    ITEMS.ACTIVE.TRASH_BAG.id,
	                    ITEMS.PASSIVE.ADDICTED.id,
	                    ITEMS.PASSIVE.SATANS_CONTRACT.id,
	                    ITEMS.PASSIVE.STONED_BUDDY.id,
	                    ITEMS.PASSIVE.MUTANT_FETUS.id,
	                    ITEMS.PASSIVE.COLOGNE.id,
	                    ITEMS.PASSIVE.BEGGARS_CUP.id,
	                    ITEMS.PASSIVE.FURNACE.id,
	                    ITEMS.PASSIVE.WHITE_CANDLE.id,
						ITEMS.PASSIVE.PSEUDOBULBAR_AFFECT.id,
						ITEMS.PASSIVE.TALISMAN_OF_ABSORPTION.id,
						ITEMS.PASSIVE.DIVINE_WRATH.id,
						ITEMS.PASSIVE.DILIGENCE.id,
						ITEMS.PASSIVE.CHARITY.id,
						ITEMS.PASSIVE.PATIENCE.id,
						ITEMS.PASSIVE.TEMPERANCE.id,
						ITEMS.PASSIVE.CHASTITY.id,
						ITEMS.PASSIVE.HUMILITY.id,
						ITEMS.PASSIVE.KINDNESS.id,
						ITEMS.PASSIVE.CANDLE_KIT.id,
						ITEMS.TRINKET.EMPEROR_CROWN.id,
						ITEMS.TRINKET.BROWN_EYE.id,
						ITEMS.PASSIVE.OLD_CONTROLLER.id,
						ITEMS.PASSIVE.GRAPHICS_ERROR.id
				}
	            local row = 31
	            for i, item in ipairs(new_items) do
	                -- Usable grid indexes start at 16 with 16 per "row"
	                -- This places them in the second row of the room
	                Isaac.DebugString("Spawning: " .. item)
	                local position = AlphaAPI.GAME_STATE.ROOM:GetGridPosition(i + row)
	                if item < 500 then
	                    Isaac.Spawn(
	                                EntityType.ENTITY_PICKUP,       -- Type
	                                PickupVariant.PICKUP_TRINKET,   -- Variant
	                                item,                           -- Subtype
	                                position,                       -- Position
	                                Vector(0, 0),                   -- Velocity
	                                player                          -- Spawner
	                            )
	                else
	                    Isaac.Spawn(EntityType.ENTITY_PICKUP,
	                                PickupVariant.PICKUP_COLLECTIBLE,
	                                item,
	                                position,
	                                Vector(0, 0),
	                                player
	                            )
	                end

	                if i % 11 == 0 then
	                    row = row + 19
	                end
	            end
		    end

			if CONFIG.START_ROOM_ENABLED_PACK2 then
	            local new_items = {
	                    ITEMS.ACTIVE.SURGEON_SIMULATOR.id,
	                    ITEMS.ACTIVE.CAULDRON.id,
	                    ITEMS.ACTIVE.MIRROR.id,
	                    ITEMS.ACTIVE.BIONIC_ARM.id,
	                    ITEMS.ACTIVE.BLACKLIGHT.id,
	                    ITEMS.ACTIVE.BLOOD_DRIVE.id,
	                    ITEMS.ACTIVE.CHALICE_OF_BLOOD.id,
	                    ITEMS.ACTIVE.STONE_NUGGET.id,
						ITEMS.ACTIVE.BOOK_OF_THE_DEAD.id,
						ITEMS.ACTIVE.BLASPHEMOUS.id,
	                    ITEMS.PASSIVE.CRACKED_ROCK.id,
	                    ITEMS.PASSIVE.HEMOPHILIA.id,
	                    ITEMS.PASSIVE.GLOOM_SKULL.id,
	                    ITEMS.PASSIVE.TECH_ALPHA.id,
	                    ITEMS.PASSIVE.AIMBOT.id,
	                    ITEMS.PASSIVE.BRUNCH.id,
	                    ITEMS.PASSIVE.BIRTH_CONTROL.id,
	                    ITEMS.PASSIVE.QUILL_FEATHER.id,
						ITEMS.PASSIVE.JUDAS_FEZ.id,
						ITEMS.PASSIVE.HOT_COALS.id,
						ITEMS.PASSIVE.ABYSS.id,
						ITEMS.PASSIVE.HOARDER.id,
						ITEMS.PASSIVE.POSSESSED_SHOT.id,
						ITEMS.PASSIVE.ENDOR_HAT.id,
						ITEMS.PASSIVE.OWL_TOTEM.id,
						ITEMS.PASSIVE.SUBCONSCIOUS.id,
						ITEMS.PASSIVE.BLOODERFLY.id,
						ITEMS.PASSIVE.SPIRIT_EYE.id,
						ITEMS.PASSIVE.INFESTED_BABY.id,
				}
	            local row = 31
	            for i, item in ipairs(new_items) do
	                -- Usable grid indexes start at 16 with 16 per "row"
	                -- This places them in the second row of the room
	                Isaac.DebugString("Spawning: " .. item)
	                local position = AlphaAPI.GAME_STATE.ROOM:GetGridPosition(i + row)
	                if item < 500 then
	                    Isaac.Spawn(
	                                EntityType.ENTITY_PICKUP,       -- Type
	                                PickupVariant.PICKUP_TRINKET,   -- Variant
	                                item,                           -- Subtype
	                                position,                       -- Position
	                                Vector(0, 0),                   -- Velocity
	                                player                          -- Spawner
	                            )
	                else
	                    Isaac.Spawn(EntityType.ENTITY_PICKUP,
	                                PickupVariant.PICKUP_COLLECTIBLE,
	                                item,
	                                position,
	                                Vector(0, 0),
	                                player
	                            )
	                end

	                if i % 11 == 0 then
	                    row = row + 19
	                end
	            end
		    end


			if CONFIG.START_ROOM_ENABLED_PACK3 then
				local items = {
					ITEMS.ACTIVE.ALASTORS_CANDLE.id,
					ITEMS.ACTIVE.ISAACS_SKULL.id,
					ITEMS.PASSIVE.SMART_BOMBS.id,
					ITEMS.PASSIVE.THE_COSMOS.id,
					ITEMS.PASSIVE.ROCKET_SHOES.id,
					ITEMS.PASSIVE.MINIATURE_METEOR.id,
					ITEMS.PASSIVE.ENTROPY.id,
					ITEMS.PASSIVE.PAINT_PALETTE.id,
					ITEMS.PASSIVE.CRYSTALLIZED.id,
					ITEMS.PASSIVE.POLYMITOSIS.id,
					ITEMS.PASSIVE.HUSHY_FLY.id,
					ITEMS.PASSIVE.SHOOTING_STAR.id,
					ITEMS.PASSIVE.MR_SQUISHY.id,
					ITEMS.PASSIVE.PEANUT_BUTTER.id,
					ITEMS.PASSIVE.LIL_MINER.id,
					ITEMS.PASSIVE.HIVE_HEAD.id,
					ITEMS.PASSIVE.LEAK_BOMBS.id,
					ITEMS.PASSIVE.INFECTION.id,
					ITEMS.PASSIVE.LIL_ALASTOR.id,
					ITEMS.PASSIVE.FAITHFUL_AMBIVALENCE.id,
					ITEMS.TRINKET.MOONROCK.id
				}
				local row = 31
				for i, item in ipairs(items) do
					local position = AlphaAPI.GAME_STATE.ROOM:GetGridPosition(i + row)
					if item < 500 then
						Isaac.Spawn(
							EntityType.ENTITY_PICKUP,       -- Type
							PickupVariant.PICKUP_TRINKET,   -- Variant
							item,                           -- Subtype
							position,                       -- Position
							Vector(0, 0),                   -- Velocity
							nil                         -- Spawner
						)
					else
						Isaac.Spawn(EntityType.ENTITY_PICKUP,
							PickupVariant.PICKUP_COLLECTIBLE,
							item,
							position,
							Vector(0, 0),
							nil
						)
					end
					if i % 11 == 0 then
						row = row + 19
					end
				end
			end

		    -- Give challenge items
		    local challenge = Isaac.GetChallenge()
		    if challenge == CHALLENGES.SHI7TIEST_DAY_EVER then
		        player:AddCollectible(CollectibleType.COLLECTIBLE_NINE_VOLT, 0, false)
		        player:AddCollectible(CollectibleType.COLLECTIBLE_POOP, 1, false)
		        player:AddCollectible(CollectibleType.COLLECTIBLE_HABIT, 0, false)
		        player:AddCollectible(CollectibleType.COLLECTIBLE_BROTHER_BOBBY, 0, false)
		        player:AddTrinket(ITEMS.TRINKET.BROWN_EYE.id)
		    elseif challenge == CHALLENGES.EXPLODING_HEAD_SYNDROME then
		        player:AddCollectible(CollectibleType.COLLECTIBLE_IPECAC, 0, false)
		        player:AddCollectible(CollectibleType.COLLECTIBLE_CONTINUUM, 0, false)
		        player:AddCollectible(ITEMS.PASSIVE.PSEUDOBULBAR_AFFECT.id, 0, false)
		    elseif challenge == CHALLENGES.FAUST then
		        player:AddCollectible(CollectibleType.COLLECTIBLE_GOAT_HEAD, 0, false)
		        player:AddCollectible(CollectibleType.COLLECTIBLE_CHAOS, 0, false)
		        player:AddTrinket(ITEMS.TRINKET.EMPEROR_CROWN.id)
		    end
		end
	end
	mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, Alphabirth.PostGameStarted)


	function Alphabirth:updateCache(player, cache_flag)
	    if player:GetPlayerType() == character_null then
	        player.CanFly = true
	    end
	end
	mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Alphabirth.updateCache)
end

function Alphabirth.hushLaserUpdate(entity, data)
    if data.itFollowsLaser then
        entity.Friction = entity.Friction / CONFIG.ITFOLLOWSLASER_SLOWAMOUNT
    end
end

function Alphabirth.miscTablesSetup()
    birthControl_pool = {
        ITEMS.PASSIVE.INFESTED_BABY.id,
        ITEMS.PASSIVE.BLOODERFLY.id,
        ITEMS.PASSIVE.SPIRIT_EYE.id,
        CollectibleType.COLLECTIBLE_BROTHER_BOBBY,
        CollectibleType.COLLECTIBLE_SISTER_MAGGY,
        CollectibleType.COLLECTIBLE_LITTLE_CHUBBY,
        CollectibleType.COLLECTIBLE_ROBO_BABY,
        CollectibleType.COLLECTIBLE_LITTLE_CHAD,
        CollectibleType.COLLECTIBLE_LITTLE_STEVEN,
        CollectibleType.COLLECTIBLE_GUARDIAN_ANGEL,
        CollectibleType.COLLECTIBLE_DEMON_BABY,
        CollectibleType.COLLECTIBLE_DEAD_BIRD,
        CollectibleType.COLLECTIBLE_BUM_FRIEND,
        CollectibleType.COLLECTIBLE_GHOST_BABY,
        CollectibleType.COLLECTIBLE_HARLEQUIN_BABY,
        CollectibleType.COLLECTIBLE_RAINBOW_BABY,
        CollectibleType.COLLECTIBLE_ABEL,
        CollectibleType.COLLECTIBLE_DRY_BABY,
        CollectibleType.COLLECTIBLE_ROBO_BABY_2,
        CollectibleType.COLLECTIBLE_ROTTEN_BABY,
        CollectibleType.COLLECTIBLE_HEADLESS_BABY,
        CollectibleType.COLLECTIBLE_LIL_BRIMSTONE,
        CollectibleType.COLLECTIBLE_LIL_HAUNT,
        CollectibleType.COLLECTIBLE_DARK_BUM,
        CollectibleType.COLLECTIBLE_PUNCHING_BAG,
        CollectibleType.COLLECTIBLE_MONGO_BABY,
        CollectibleType.COLLECTIBLE_INCUBUS,
        CollectibleType.COLLECTIBLE_SWORN_PROTECTOR,
        CollectibleType.COLLECTIBLE_FATES_REWARD,
        CollectibleType.COLLECTIBLE_CHARGED_BABY,
        CollectibleType.COLLECTIBLE_BUMBO,
        CollectibleType.COLLECTIBLE_LIL_GURDY,
        CollectibleType.COLLECTIBLE_KEY_BUM,
        CollectibleType.COLLECTIBLE_SERAPHIM,
        CollectibleType.COLLECTIBLE_FARTING_BABY,
        CollectibleType.COLLECTIBLE_SUCCUBUS,
        CollectibleType.COLLECTIBLE_LIL_LOKI,
        CollectibleType.COLLECTIBLE_HUSHY,
        CollectibleType.COLLECTIBLE_LIL_MONSTRO,
        CollectibleType.COLLECTIBLE_KING_BABY,
        CollectibleType.COLLECTIBLE_BIG_CHUBBY,
        CollectibleType.COLLECTIBLE_ACID_BABY,
        Isaac.GetItemIdByName("Lil Delirium")
    }
end

function Alphabirth.curseSetup()
    local lonely_curse = api_mod:getCurseConfig(
        "Curse of the Lonely",
        CONFIG.CURSE_CHANCES
    )

    local duality_blessing = api_mod:getCurseConfig(
        "Blessing of Duality",
        CONFIG.CURSE_CHANCES
    )

    local freedom_blessing = api_mod:getCurseConfig(
        "Blessing of Freedom",
        CONFIG.CURSE_CHANCES
    )

    local knowledge_blessing = api_mod:getCurseConfig(
        "Blessing of Knowledge",
        CONFIG.CURSE_CHANCES
    )

    lonely_curse:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.handleLonelyCurse, EntityType.ENTITY_PICKUP)
    duality_blessing:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.pickupSpawnDuality, EntityType.ENTITY_PICKUP)
    knowledge_blessing:addCallback(AlphaAPI.Callbacks.CURSE_TRIGGER, Alphabirth.triggerKnowledge)
    freedom_blessing:addCallback(AlphaAPI.Callbacks.CURSE_UPDATE, Alphabirth.handleFreedom)
end

function Alphabirth.miscEntityHandling()
    api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.collectibleUpdate, EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE)
    api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.onBloodProjectileAppear, EntityType.ENTITY_PROJECTILE)
    api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.onDartFlyAppear, EntityType.ENTITY_DART_FLY)
    api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.tearUpdate, EntityType.ENTITY_TEAR)
    api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.laserUpdate, EntityType.ENTITY_LASER)
    api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.blackHeartUpdate, EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLACK)
    api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.tearAppear, EntityType.ENTITY_TEAR)

    ENTITY_FLAGS = {
		DOUBLE_DAMAGE = AlphaAPI.createFlag(),
		KINDNESS = AlphaAPI.createFlag(),
		MUTANT_TEAR = AlphaAPI.createFlag(),
        VOID = AlphaAPI.createFlag(),
        ABYSS_SHOT = AlphaAPI.createFlag(),
        QUILL_FEATHER_SHOT = AlphaAPI.createFlag(),
        CRACKED_ROCK_SHOT = AlphaAPI.createFlag(),
        HEMOPHILIA_APPLIED = AlphaAPI.createFlag(),
        MORPH_TRIED = AlphaAPI.createFlag(),
		LOCKED_ATTEMPT = AlphaAPI.createFlag(),
		SMART_BOMB = AlphaAPI.createFlag(),
        METEOR_SHOT = AlphaAPI.createFlag(),
        ENTROPY_TEAR = AlphaAPI.createFlag(),
        PAINTED = AlphaAPI.createFlag(),
        CRYSTAL = AlphaAPI.createFlag(),
        POLYMITOSIS_TEAR = AlphaAPI.createFlag(),
        SHOOTINGSTAR_TEAR = AlphaAPI.createFlag(),
        PEANUTBUTTER_TEAR = AlphaAPI.createFlag(),
        PEANUTBUTTER_STICKY = AlphaAPI.createFlag(),
        SQUISHY_TEAR = AlphaAPI.createFlag(),
        TEAR_IGNORE = AlphaAPI.createFlag(),
        INFECTION_TEAR = AlphaAPI.createFlag(),
        INFECTED = AlphaAPI.createFlag()
    }

end

function Alphabirth.transformationSetup()
    local cyborg_pool = {
        CollectibleType.COLLECTIBLE_TECHNOLOGY,
        CollectibleType.COLLECTIBLE_TECH_X,
        CollectibleType.COLLECTIBLE_TECHNOLOGY_2,
        CollectibleType.COLLECTIBLE_TECH_5,
        ITEMS.PASSIVE.AIMBOT,
        ITEMS.PASSIVE.TECH_ALPHA,
        ITEMS.ACTIVE.BIONIC_ARM
    }

    local damned_pool = {
        ITEMS.PASSIVE.GLOOM_SKULL,
        ITEMS.ACTIVE.CHALICE_OF_BLOOD,
        ITEMS.ACTIVE.BLASPHEMOUS,
        CollectibleType.COLLECTIBLE_PENTAGRAM,
        CollectibleType.COLLECTIBLE_CONTRACT_FROM_BELOW,
        CollectibleType.COLLECTIBLE_PACT,
        CollectibleType.COLLECTIBLE_MARK
    }

    local SATANS_CONTRACT_ID = Isaac.GetItemIdByName("Satan's Contract")
    if SATANS_CONTRACT_ID > 0 then
        damned_pool[#damned_pool + 1] = SATANS_CONTRACT_ID
    end

    local cyborg_transformation = api_mod:registerTransformation("Cyborg", cyborg_pool)
    api_mod:addCallback(AlphaAPI.Callbacks.TRANSFORMATION_TRIGGER, Alphabirth.cyborgTrigger, cyborg_transformation)
    api_mod:addCallback(AlphaAPI.Callbacks.TRANSFORMATION_CACHE, Alphabirth.applyCyborgCache, cyborg_transformation)
    api_mod:addCallback(AlphaAPI.Callbacks.TRANSFORMATION_UPDATE, Alphabirth.cyborgUpdate, cyborg_transformation)

    local damned_transformation = api_mod:registerTransformation("Damned", damned_pool)
    local function onDeath(player)
        if AlphaAPI.hasTransformation(damned_transformation) and not api_mod.data.run.damnedHasRespawned then
            api_mod.data.run.damnedHasRespawned = true
            player:UseActiveItem(CollectibleType.COLLECTIBLE_FORGET_ME_NOW, false, true, true, false)
            player:Revive()
            player:AddSoulHearts(-1)
            player:AddBlackHearts(6)
        end
    end

    api_mod:addCallback(AlphaAPI.Callbacks.TRANSFORMATION_TRIGGER, Alphabirth.damnedTrigger, damned_transformation)
    api_mod:addCallback(AlphaAPI.Callbacks.TRANSFORMATION_CACHE, Alphabirth.applyDamnedCache, damned_transformation)
    api_mod:addCallback(AlphaAPI.Callbacks.PLAYER_DIED, onDeath)
end


-- Setup Function for Item Callbacks
function Alphabirth.itemSetup()
	---------------------------------------
    -- ITEM DECLARATION/CALLBACKS
    ---------------------------------------
    --ITEMS.PASSIVE.NEW_ITEM = api_mod:registerItem(name, costume, sGtats)
    --stats = AlphaAPI.createStat(cache_flag, number, modifier ("+", "-", "*", "/", "="") )

	COSTUMES = {
		-- Pack 1
		NULL  = Isaac.GetCostumeIdByPath("gfx/animations/costumes/accessories/animation_costume_null.anm2"),
		WAXED = Isaac.GetCostumeIdByPath("gfx/animations/costumes/accessories/animation_transformation_waxed.anm2"),
        -- Pack 2
		CHALICE_OF_BLOOD_COSTUME = Isaac.GetCostumeIdByPath("gfx/animations/costumes/accessories/animation_costume_chaliceofblood.anm2"),

        CYBORG_COSTUME = Isaac.GetCostumeIdByPath("gfx/animations/costumes/accessories/animation_transformation_cyborg.anm2"),
        DAMNED_COSTUME = Isaac.GetCostumeIdByPath("gfx/animations/costumes/accessories/animation_transformation_damned.anm2"),

        ENDOR_BODY_COSTUME = Isaac.GetCostumeIdByPath("gfx/animations/costumes/players/animation_character_endorbody.anm2"),
        ENDOR_HEAD_COSTUME = Isaac.GetCostumeIdByPath("gfx/animations/costumes/players/animation_character_endorhead.anm2")
    }


	-------------
	-- Actives --
	-------------
	ITEMS.ACTIVE.DEBUG = api_mod:registerItem("Debug")
	ITEMS.ACTIVE.DEBUG:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.triggerDebug)

	-- 28% chance for 3 blue flies, 28% chance for 3 blue spiders,
	-- 41% chance for a random pickup, 3% chance for a trinket
	ITEMS.ACTIVE.TRASH_BAG = api_mod:registerItem("Trash Bag")
	ITEMS.ACTIVE.TRASH_BAG:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.triggerTrashBag)

	-- Reverse trajectory of all tears and damages enemies
	ITEMS.ACTIVE.DELIRIUMS_BRAIN = api_mod:registerItem("Delirium's Brain")
	ITEMS.ACTIVE.DELIRIUMS_BRAIN:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.triggerDeliriumsBrain)

	--------------
	-- Passives --
	--------------
	-- Has a chance to swallow a random pill when damage is taken
	ITEMS.PASSIVE.ADDICTED = api_mod:registerItem("Addicted", "gfx/animations/costumes/accessories/animation_costume_addicted.anm2")

	-- Doubles the player's damage and damage taken
	ITEMS.PASSIVE.SATANS_CONTRACT = api_mod:registerItem("Satan's Contract", "gfx/animations/costumes/accessories/animation_costume_contract.anm2")
	ITEMS.PASSIVE.SATANS_CONTRACT:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateSatansContract)

	-- Has a chance to spawn a bomb when you hit an enemy
	ITEMS.PASSIVE.MUTANT_FETUS = api_mod:registerItem("Mutant Fetus", "gfx/animations/costumes/accessories/animation_costume_mutantfetus.anm2")

    -- Bombs become Bugged Bombs, which have tear flags randomly applied to them.
	LOCKS.BUGGED_BOMBS = api_mod:createUnlock("alphaBuggedBombs")
    ITEMS.PASSIVE.BUGGED_BOMBS = api_mod:registerItem("Bugged Bombs")
    ITEMS.PASSIVE.BUGGED_BOMBS:addCallback(AlphaAPI.Callbacks.ITEM_PICKUP, Alphabirth.pickupBuggedBombs)
	ITEMS.PASSIVE.BUGGED_BOMBS:addLock(LOCKS.BUGGED_BOMBS)

	-- Chance to charm nearby enemies
	ITEMS.PASSIVE.COLOGNE = api_mod:registerItem("Cologne", "gfx/animations/costumes/accessories/animation_costume_cologne.anm2")
	ITEMS.PASSIVE.COLOGNE:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handleCologne)
	ITEMS.PASSIVE.COLOGNE:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateCologne)

	-- Gives the player more luck the fewer consumables they have
	ITEMS.PASSIVE.BEGGARS_CUP = api_mod:registerItem("Beggar's Cup", "gfx/animations/costumes/accessories/animation_costume_beggarscup.anm2")
	ITEMS.PASSIVE.BEGGARS_CUP:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handleBeggarsCup)
	ITEMS.PASSIVE.BEGGARS_CUP:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateBeggarsCup)

	-- Shoots fires in all directions on damage taken
	ITEMS.PASSIVE.FURNACE = api_mod:registerItem("Furnace", "gfx/animations/costumes/accessories/animation_costume_furnace.anm2")

	-- Pseudobulbar Affect
	ITEMS.PASSIVE.PSEUDOBULBAR_AFFECT = api_mod:registerItem("Pseudobulbar Affect", "gfx/animations/costumes/accessories/animation_costume_pseudobulbaraffect.anm2")
	ITEMS.PASSIVE.PSEUDOBULBAR_AFFECT:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handlePseudobulbarAffect)


	-- Immunity to lasers plus healing from lasers
	ITEMS.PASSIVE.TALISMAN_OF_ABSORPTION = api_mod:registerItem("Talisman of Absorption", "gfx/animations/costumes/accessories/animation_costume_talismanofabsorption.anm2")

	-- Immunity to fire, spikes, and bombs. 20% chance to dodge all damage
	ITEMS.PASSIVE.DILIGENCE = api_mod:registerItem("Diligence", "gfx/animations/costumes/accessories/animation_costume_diligence.anm2")

	-- Damage up the longer you're in a room
	ITEMS.PASSIVE.PATIENCE = api_mod:registerItem("Patience", "gfx/animations/costumes/accessories/animation_costume_patience.anm2")
	ITEMS.PASSIVE.PATIENCE:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handlePatience)
	ITEMS.PASSIVE.PATIENCE:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluatePatience)

	-- Marks a random enemy in the room that takes increased damage
	ITEMS.PASSIVE.HUMILITY = api_mod:registerItem("Humility", "gfx/animations/costumes/accessories/animation_costume_humility.anm2")
	ITEMS.PASSIVE.HUMILITY:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handleHumility)

	-- Stats up if you haven't gone to the DEVIL room this run
	ITEMS.PASSIVE.CHASTITY = api_mod:registerItem("Chastity", "gfx/animations/costumes/accessories/animation_costume_chastity.anm2", {CacheFlag.CACHE_DAMAGE, CacheFlag.CACHE_RANGE, CacheFlag.CACHE_SHOTSPEED, CacheFlag.CACHE_SPEED})
	ITEMS.PASSIVE.CHASTITY:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateChastity)

	-- Randomly charms enemies. Chance to spawn hearts on killing enemies
	ITEMS.PASSIVE.KINDNESS = api_mod:registerItem("Kindness", "gfx/animations/costumes/accessories/animation_costume_kindness.anm2")
	ITEMS.PASSIVE.KINDNESS:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handleKindness)

	-- Ludovico-esque hush laser.
	ITEMS.PASSIVE.DIVINE_WRATH = api_mod:registerItem("Divine Wrath", "gfx/animations/costumes/accessories/animation_costume_divinewrath.anm2")
	ITEMS.PASSIVE.DIVINE_WRATH:addCallback(AlphaAPI.Callbacks.ITEM_PICKUP, Alphabirth.pickupDivineWrath, true)
	ITEMS.PASSIVE.DIVINE_WRATH:addCallback(AlphaAPI.Callbacks.ITEM_REMOVE, Alphabirth.removeDivineWrath, true)

	-- Spawns a familiar that persues the nearest enemy, pushing them away and blocking tears
	ITEMS.PASSIVE.STONED_BUDDY = api_mod:registerItem("Stoned Buddy")
    ITEMS.PASSIVE.STONED_BUDDY:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateStonedBuddy)

	-- Grants two Candle orbitals that burn nearby enemies and deal contact damage.
	ITEMS.PASSIVE.CANDLE_KIT = api_mod:registerItem("Candle Kit")
    ITEMS.PASSIVE.CANDLE_KIT:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateCandleKit)

	LOCKS.OLD_CONTROLLER = api_mod:createUnlock("alphaOldController")
	ITEMS.PASSIVE.OLD_CONTROLLER = api_mod:registerItem("Old Controller", "gfx/animations/costumes/accessories/animation_costume_oldcontroller.anm2")
	ITEMS.PASSIVE.OLD_CONTROLLER:addCallback(AlphaAPI.Callbacks.ITEM_PICKUP, Alphabirth.initDeathVariable)
	ITEMS.PASSIVE.OLD_CONTROLLER:addLock(LOCKS.OLD_CONTROLLER)

	LOCKS.GRAPHICS_ERROR = api_mod:createUnlock("alphaGraphicsError")
	ITEMS.PASSIVE.GRAPHICS_ERROR = api_mod:registerItem("Graphics Error", "gfx/animations/costumes/accessories/animation_costume_graphicserror.anm2")
	ITEMS.PASSIVE.GRAPHICS_ERROR:addLock(LOCKS.GRAPHICS_ERROR)

	-- Teleports you to the boss room every time you enter a new floor
	LOCKS.EMPEROR_CROWN = api_mod:createUnlock("alphaEmperorsCrown")
	ITEMS.TRINKET.EMPEROR_CROWN = api_mod:registerTrinket("Emperor's Crown")
    ITEMS.TRINKET.EMPEROR_CROWN:addCallback( AlphaAPI.Callbacks.FLOOR_CHANGED, Alphabirth.handleEmperorCrown)
	ITEMS.TRINKET.EMPEROR_CROWN:addLock(LOCKS.EMPEROR_CROWN)

	-- All poop in a room will shoot at the nearest enemy
	LOCKS.BROWN_EYE = api_mod:createUnlock("alphaBrownEye")
	ITEMS.TRINKET.BROWN_EYE = api_mod:registerTrinket("Brown Eye")
	ITEMS.TRINKET.BROWN_EYE:addCallback(AlphaAPI.Callbacks.TRINKET_UPDATE, Alphabirth.handleBrownEye)
	ITEMS.TRINKET.BROWN_EYE:addLock(LOCKS.BROWN_EYE)

	--------------
	--  PACK 2  --
	--------------

    ITEMS.ACTIVE.MIRROR = api_mod:registerItem("Mirror")
    ITEMS.ACTIVE.MIRROR:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.triggerMirror)

    ITEMS.ACTIVE.CAULDRON = api_mod:registerItem("Cauldron")
    ITEMS.ACTIVE.CAULDRON:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.triggerCauldron)

    ITEMS.ACTIVE.SURGEON_SIMULATOR = api_mod:registerItem("Surgeon Simulator")
    ITEMS.ACTIVE.SURGEON_SIMULATOR:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.triggerSurgeonSimulator)

    ITEMS.ACTIVE.BIONIC_ARM = api_mod:registerItem("Bionic Arm")
    ITEMS.ACTIVE.BIONIC_ARM:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.triggerBionicArm)
    ITEMS.ACTIVE.BIONIC_ARM:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.applyBionicArmCache)

    ITEMS.ACTIVE.BLOOD_DRIVE = api_mod:registerItem("Blood Drive")
    ITEMS.ACTIVE.BLOOD_DRIVE:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.triggerBloodDrive)

    ITEMS.ACTIVE.BLACKLIGHT = api_mod:registerItem("Blacklight")
    ITEMS.ACTIVE.BLACKLIGHT:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.triggerBlacklight)

    ITEMS.ACTIVE.STONE_NUGGET = api_mod:registerItem("Stone Nugget")
    ITEMS.ACTIVE.STONE_NUGGET:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.triggerStoneNugget)

    ITEMS.ACTIVE.BLASPHEMOUS = api_mod:registerItem("Blasphemous")
    ITEMS.ACTIVE.BLASPHEMOUS:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.triggerBlasphemous)

    ITEMS.ACTIVE.CHALICE_OF_BLOOD = api_mod:registerItem("Chalice of Blood")
    ITEMS.ACTIVE.CHALICE_OF_BLOOD:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handleChaliceOfBlood)
    ITEMS.ACTIVE.CHALICE_OF_BLOOD:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.triggerChaliceOfBlood)
    ITEMS.ACTIVE.CHALICE_OF_BLOOD:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.applyChaliceOfBloodCache)

    ITEMS.ACTIVE.BOOK_OF_THE_DEAD = api_mod:registerItem("Book of the Dead")
    ITEMS.ACTIVE.BOOK_OF_THE_DEAD:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handleBookOfTheDead)
    ITEMS.ACTIVE.BOOK_OF_THE_DEAD:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.triggerBookOfTheDead)

    ITEMS.PASSIVE.CRACKED_ROCK = api_mod:registerItem("Cracked Rock", "gfx/animations/costumes/accessories/animation_costume_crackedrock.anm2")
    ITEMS.PASSIVE.CRACKED_ROCK:getEntityConfig():setAsVariant{
        id = EntityType.ENTITY_PICKUP,
        variant = PickupVariant.PICKUP_COLLECTIBLE,
        subtype = Isaac.GetItemIdByName("The Small Rock"),
        chance = 3
    }

    LOCKS.ENDOR_HAT = api_mod:createUnlock("alphaEndorHat")
    ITEMS.PASSIVE.ENDOR_HAT = api_mod:registerItem("Endor's Hat", "gfx/animations/costumes/accessories/animation_costume_endors_hat.anm2")
    ITEMS.PASSIVE.ENDOR_HAT:addCallback(AlphaAPI.Callbacks.ROOM_CLEARED, Alphabirth.endorHatRoomClear)
    ITEMS.PASSIVE.ENDOR_HAT:addLock(LOCKS.ENDOR_HAT)

    LOCKS.OWL_TOTEM = api_mod:createUnlock("alphaOwlTotem")
    ITEMS.PASSIVE.OWL_TOTEM = api_mod:registerItem("Owl Totem", "gfx/animations/costumes/accessories/animation_costume_owltotem.anm2")
    ITEMS.PASSIVE.OWL_TOTEM:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handleOwlTotem)
    ITEMS.PASSIVE.OWL_TOTEM:addLock(LOCKS.OWL_TOTEM)

    LOCKS.SUBCONSCIOUS = api_mod:createUnlock("alphaSubconscious")
    ITEMS.PASSIVE.SUBCONSCIOUS = api_mod:registerItem("Subconscious")
    ITEMS.PASSIVE.SUBCONSCIOUS:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alphabirth.playerTakeDamage, EntityType.ENTITY_PLAYER)
    ITEMS.PASSIVE.SUBCONSCIOUS:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateSubconscious)
    ITEMS.PASSIVE.SUBCONSCIOUS:addLock(LOCKS.SUBCONSCIOUS)

    ITEMS.PASSIVE.GLOOM_SKULL = api_mod:registerItem("Gloom Skull", "gfx/animations/costumes/accessories/animation_costume_gloomskull.anm2")
    ITEMS.PASSIVE.GLOOM_SKULL:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.applyGloomSkullCache)

    ITEMS.PASSIVE.BIRTH_CONTROL = api_mod:registerItem("Birth Control", "gfx/animations/costumes/accessories/animation_costume_birthcontrol.anm2")
    ITEMS.PASSIVE.BIRTH_CONTROL:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handleBirthControl)
    ITEMS.PASSIVE.BIRTH_CONTROL:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.applyBirthControlCache)
    ITEMS.PASSIVE.BIRTH_CONTROL:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.useBoxOfFriends, CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS)

    ITEMS.PASSIVE.QUILL_FEATHER = api_mod:registerItem("Quill Feather", "gfx/animations/costumes/accessories/animation_costume_quillfeather.anm2")

    ITEMS.PASSIVE.POSSESSED_SHOT = api_mod:registerItem("Possessed Shot", "gfx/animations/costumes/accessories/animation_costume_possessedshot.anm2")
    ITEMS.PASSIVE.POSSESSED_SHOT:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.applyPossessedShotCache)
    ITEMS.PASSIVE.POSSESSED_SHOT:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alphabirth.triggerPossessedShot)

    ITEMS.PASSIVE.SPIRIT_EYE = api_mod:registerItem("Spirit Eye")
    ITEMS.PASSIVE.SPIRIT_EYE:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateSpiritEye)

    ITEMS.PASSIVE.INFESTED_BABY = api_mod:registerItem("Infested Baby")
    ITEMS.PASSIVE.INFESTED_BABY:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateInfestedBaby)

    ITEMS.PASSIVE.BLOODERFLY = api_mod:registerItem("Blooderfly")
    ITEMS.PASSIVE.BLOODERFLY:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateBlooderfly)

    ITEMS.PASSIVE.BRUNCH = api_mod:registerItem("Brunch")
    ITEMS.PASSIVE.BRUNCH:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.applyBrunchCache)
    ITEMS.PASSIVE.BRUNCH:addCallback(AlphaAPI.Callbacks.ITEM_PICKUP, Alphabirth.pickupBrunch)

    ITEMS.PASSIVE.HEMOPHILIA = api_mod:registerItem("Hemophilia", "gfx/animations/costumes/accessories/animation_costume_hemophilia.anm2")
    ITEMS.PASSIVE.HEMOPHILIA:addCallback(AlphaAPI.Callbacks.ENTITY_DEATH, Alphabirth.triggerHemophilia)

    ITEMS.PASSIVE.HOARDER = api_mod:registerItem("Hoarder", "gfx/animations/costumes/accessories/animation_costume_hoarder.anm2")
    ITEMS.PASSIVE.HOARDER:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handleHoarder)
    ITEMS.PASSIVE.HOARDER:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.applyHoarderCache)

    ITEMS.PASSIVE.JUDAS_FEZ = api_mod:registerItem("Judas' Fez", "gfx/animations/costumes/accessories/animation_costume_judasfez.anm2")
    ITEMS.PASSIVE.JUDAS_FEZ:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handleJudasFez)
    ITEMS.PASSIVE.JUDAS_FEZ:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.applyJudasFezCache)

    ITEMS.PASSIVE.HOT_COALS = api_mod:registerItem("Hot Coals", "gfx/animations/costumes/accessories/animation_costume_hotcoals.anm2")
    ITEMS.PASSIVE.HOT_COALS:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handleHotCoals)
    ITEMS.PASSIVE.HOT_COALS:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateHotCoals)

    ITEMS.PASSIVE.ABYSS = api_mod:registerItem("Abyss", "gfx/animations/costumes/accessories/animation_costume_abyss.anm2")
    ITEMS.PASSIVE.ABYSS:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handleAbyss)

    ITEMS.PASSIVE.AIMBOT = api_mod:registerItem("Aimbot", "gfx/animations/costumes/accessories/animation_costume_aimbot.anm2")

    ITEMS.PASSIVE.TECH_ALPHA = api_mod:registerItem("Tech Alpha", "gfx/animations/costumes/accessories/animation_costume_techalpha.anm2")
    ITEMS.PASSIVE.TECH_ALPHA:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handleTechAlpha)
    ITEMS.PASSIVE.TECH_ALPHA:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.applyTechAlphaCache)

    LOCKS.GEBO = api_mod:createUnlock("alphaGeboLock")
    ITEMS.POCKET.GEBO = api_mod:getCardConfig("Gebo")
    ITEMS.POCKET.GEBO:setBackAnimation("gfx/animations/pickups/custom_rune.anm2")
    ITEMS.POCKET.GEBO:setAsVariant{id = EntityType.ENTITY_PICKUP, variant = PickupVariant.PICKUP_TAROTCARD, chance = CONFIG.NEW_RUNE_CHANCE}
    ITEMS.POCKET.GEBO:addLock(LOCKS.GEBO)
    ITEMS.POCKET.GEBO:addCallback(AlphaAPI.Callbacks.CARD_USE, Alphabirth.triggerGeboEffect)

    LOCKS.NAUDIZ = api_mod:createUnlock("alphaNaudizLock")
    ITEMS.POCKET.NAUDIZ = api_mod:getCardConfig("Naudiz")
    ITEMS.POCKET.NAUDIZ:setBackAnimation("gfx/animations/pickups/custom_rune.anm2")
    ITEMS.POCKET.NAUDIZ:setAsVariant{id = EntityType.ENTITY_PICKUP, variant = PickupVariant.PICKUP_TAROTCARD, chance = CONFIG.NEW_RUNE_CHANCE}
    ITEMS.POCKET.NAUDIZ:addLock(LOCKS.NAUDIZ)
    ITEMS.POCKET.NAUDIZ:addCallback(AlphaAPI.Callbacks.CARD_USE, Alphabirth.triggerNaudizEffect)

    LOCKS.FEHU = api_mod:createUnlock("alphaFehuLock")
    ITEMS.POCKET.FEHU = api_mod:getCardConfig("Fehu")
    ITEMS.POCKET.FEHU:setBackAnimation("gfx/animations/pickups/custom_rune.anm2")
    ITEMS.POCKET.FEHU:setAsVariant{id = EntityType.ENTITY_PICKUP, variant = PickupVariant.PICKUP_TAROTCARD, chance = CONFIG.NEW_RUNE_CHANCE}
    ITEMS.POCKET.FEHU:addLock(LOCKS.FEHU)
    ITEMS.POCKET.FEHU:addCallback(AlphaAPI.Callbacks.CARD_USE, Alphabirth.triggerFehuEffect)

    LOCKS.SOWILO = api_mod:createUnlock("alphaSowiloLock")
    ITEMS.POCKET.SOWILO = api_mod:getCardConfig("Sowilo")
    ITEMS.POCKET.SOWILO:setBackAnimation("gfx/animations/pickups/custom_rune.anm2")
    ITEMS.POCKET.SOWILO:setAsVariant{id = EntityType.ENTITY_PICKUP, variant = PickupVariant.PICKUP_TAROTCARD, chance = CONFIG.NEW_RUNE_CHANCE}
    ITEMS.POCKET.SOWILO:addLock(LOCKS.SOWILO)
    ITEMS.POCKET.SOWILO:addCallback(AlphaAPI.Callbacks.CARD_USE, Alphabirth.triggerSowiloEffect)

	--------------
	--  PACK 3  --
	--------------

	ITEMS.ACTIVE.ALASTORS_CANDLE = api_mod:registerItem("Alastor's Candle")
    ITEMS.ACTIVE.ALASTORS_CANDLE:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.useAlastorsCandle)

    ITEMS.ACTIVE.ISAACS_SKULL = api_mod:registerItem("Isaac's Skull")
    ITEMS.ACTIVE.ISAACS_SKULL:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.useIsaacsSkull)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Alphabirth.isaacsSkullNewRoom)

    ITEMS.PASSIVE.FAITHFUL_AMBIVALENCE = api_mod:registerItem("Faithful Ambivalence", "gfx/animations/costumes/accessories/animation_costume_faithfulambivalence.anm2")
    ITEMS.PASSIVE.FAITHFUL_AMBIVALENCE:addCallback(AlphaAPI.Callbacks.ROOM_NEW, Alphabirth.faithfulAmbivalenceNewRoom)

    ITEMS.PASSIVE.LIL_ALASTOR = api_mod:registerItem("Lil Alastor")
    ITEMS.PASSIVE.LIL_ALASTOR:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateLilAlastor)

    -- PASSIVES
    ITEMS.PASSIVE.SMART_BOMBS = api_mod:registerItem("Smart Bombs")
    ITEMS.PASSIVE.SMART_BOMBS:addCallback(AlphaAPI.Callbacks.ITEM_PICKUP, Alphabirth.onPickupBombItem)

    ITEMS.PASSIVE.LEAK_BOMBS = api_mod:registerItem("Leaking Bombs", "gfx/animations/costumes/accessories/animation_costume_leakybombs.anm2")
    ITEMS.PASSIVE.LEAK_BOMBS:addCallback(AlphaAPI.Callbacks.ITEM_PICKUP, Alphabirth.onPickupBombItem)
    ITEMS.PASSIVE.LEAK_BOMBS:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.leakingBombsUpdate, EntityType.ENTITY_BOMBDROP)
    ITEMS.PASSIVE.LEAK_BOMBS:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.leakingBombsCreepUpdate, EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_BLACKPOWDER)
    ITEMS.PASSIVE.LEAK_BOMBS:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alphabirth.leakingBombsDamage)

    ITEMS.PASSIVE.ROCKET_SHOES = api_mod:registerItem("Rocket Shoes", "gfx/animations/costumes/accessories/animation_costume_rocketshoes.anm2")
    ITEMS.PASSIVE.ROCKET_SHOES:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handleRocketShoes)
    ITEMS.PASSIVE.ROCKET_SHOES:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateRocketShoes)

    ITEMS.PASSIVE.THE_COSMOS = api_mod:registerItem("The Cosmos")
    ITEMS.PASSIVE.THE_COSMOS:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alphabirth.cosmosDamage)
    ITEMS.PASSIVE.THE_COSMOS:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateCosmos)

    ITEMS.PASSIVE.MINIATURE_METEOR = api_mod:registerItem("Miniature Meteor", "gfx/animations/costumes/accessories/animation_costume_miniaturemeteor.anm2")
    ITEMS.PASSIVE.MINIATURE_METEOR:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alphabirth.miniatureMeteorDamage)
    ITEMS.PASSIVE.MINIATURE_METEOR:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.miniatureMeteorAppear, EntityType.ENTITY_TEAR)
    ITEMS.PASSIVE.MINIATURE_METEOR:addCallback(AlphaAPI.Callbacks.ITEM_PICKUP, Alphabirth.onMeteorPickup)

    ITEMS.PASSIVE.ENTROPY = api_mod:registerItem("Entropy", "gfx/animations/costumes/accessories/animation_costume_entropy.anm2")
    ITEMS.PASSIVE.ENTROPY:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.entropyCache)
    ITEMS.PASSIVE.ENTROPY:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.entropyNewTear, EntityType.ENTITY_TEAR)

    ITEMS.PASSIVE.PAINT_PALETTE = api_mod:registerItem("Paint Palette", "gfx/animations/costumes/accessories/animation_costume_palette.anm2")
    ITEMS.PASSIVE.PAINT_PALETTE:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alphabirth.paintPaletteDamage)
    ITEMS.PASSIVE.PAINT_PALETTE:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.onPaintPaletteTearUpdate, EntityType.ENTITY_TEAR)
    ITEMS.PASSIVE.PAINT_PALETTE:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.onPaintPaletteTearUpdate, EntityType.ENTITY_LASER)

    ITEMS.PASSIVE.CRYSTALLIZED = api_mod:registerItem("Crystallized", "gfx/animations/costumes/accessories/animation_costume_crystallized.anm2")
    ITEMS.PASSIVE.CRYSTALLIZED:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alphabirth.crystalTearDamage)
    ITEMS.PASSIVE.CRYSTALLIZED:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.crystallizedUpdate)
    ITEMS.PASSIVE.CRYSTALLIZED:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateCrystallized)

    ITEMS.PASSIVE.POLYMITOSIS = api_mod:registerItem("Poly-Mitosis", "gfx/animations/costumes/accessories/animation_costume_polymitosis.anm2")
    ITEMS.PASSIVE.POLYMITOSIS:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.polyMitosisNewTear, EntityType.ENTITY_TEAR)
    ITEMS.PASSIVE.POLYMITOSIS:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.polyMitosisUpdate, EntityType.ENTITY_TEAR)
    ITEMS.PASSIVE.POLYMITOSIS:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.polyMitosisCache)

    ITEMS.PASSIVE.SHOOTING_STAR = api_mod:registerItem("Shooting Star", "gfx/animations/costumes/accessories/animation_costume_shootingstar.anm2")
    ITEMS.PASSIVE.SHOOTING_STAR:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alphabirth.shootingStarBounce)
    ITEMS.PASSIVE.SHOOTING_STAR:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.shootingStarNewTear, EntityType.ENTITY_TEAR)
    ITEMS.PASSIVE.SHOOTING_STAR:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.shootingStarTearUpdate, EntityType.ENTITY_TEAR)

    ITEMS.PASSIVE.PEANUT_BUTTER = api_mod:registerItem("Peanut Butter", "gfx/animations/costumes/accessories/animation_costume_peanutbutter.anm2")
    ITEMS.PASSIVE.PEANUT_BUTTER:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.peanutButterCache)
    ITEMS.PASSIVE.PEANUT_BUTTER:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.peanutButterNewTear, EntityType.ENTITY_TEAR)
    ITEMS.PASSIVE.PEANUT_BUTTER:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.peanutButterEntityUpdate)
    ITEMS.PASSIVE.PEANUT_BUTTER:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alphabirth.peanutButterDamage)

    ITEMS.PASSIVE.MR_SQUISHY = api_mod:registerItem("Mr. Squishy", "gfx/animations/costumes/accessories/animation_costume_mrsquishy.anm2")
    ITEMS.PASSIVE.MR_SQUISHY:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.mrSquishyNewTear, EntityType.ENTITY_TEAR)
    ITEMS.PASSIVE.MR_SQUISHY:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.mrSquishyTearUpdate, EntityType.ENTITY_TEAR)

    ITEMS.PASSIVE.INFECTION = api_mod:registerItem("Infection", "gfx/animations/costumes/accessories/animation_costume_infection.anm2")
    ITEMS.PASSIVE.INFECTION:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.infectionTearAppear, EntityType.ENTITY_TEAR)
    ITEMS.PASSIVE.INFECTION:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.infectionUpdate)
    ITEMS.PASSIVE.INFECTION:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alphabirth.infectionDamage)

    ITEMS.PASSIVE.HUSHY_FLY = api_mod:registerItem("Hushy Fly")
    ITEMS.PASSIVE.HUSHY_FLY:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateHushyFly)

    ITEMS.PASSIVE.LIL_MINER = api_mod:registerItem("Lil Miner")
    ITEMS.PASSIVE.LIL_MINER:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluateLilMiner)

	ITEMS.PASSIVE.HIVE_HEAD = api_mod:registerItem( "Hive Head", "gfx/animations/costumes/accessories/animation_costume_hivehead.anm2" )
	ITEMS.PASSIVE.HIVE_HEAD:addCallback(AlphaAPI.Callbacks.ROOM_CLEARED, Alphabirth.onHiveHeadRoomClear)
	ITEMS.PASSIVE.HIVE_HEAD:addCallback(AlphaAPI.Callbacks.ITEM_PICKUP, Alphabirth.onHiveHeadPickup)

    -- TRINKETS
    ITEMS.TRINKET.MOONROCK = api_mod:registerTrinket("Moonrock")
    ITEMS.TRINKET.MOONROCK:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.moonrockNewTear, EntityType.ENTITY_TEAR)

end

-- Setup Function for Entities
function Alphabirth.entitySetup()
	ENTITIES.ICE_FART = api_mod:getEntityConfig("Ice Fart")
	ENTITIES.GREEN_CANDLE = api_mod:getEntityConfig("Green Candle", 20)

	ENTITIES.BOMB_DIP = api_mod:getEntityConfig("Bomb Dip")
	ENTITIES.BOMB_DIP:addCallback(AlphaAPI.Callbacks.ENTITY_DEATH, Alphabirth.onBombDipDie)
    ENTITIES.BOMB_DIP:setAsVariant{
        chance = 22,
        id = EntityType.ENTITY_DIP
    }

	LOCKS.GLITCH_PICKUP = api_mod:createUnlock("alphaGlitchedPickups")
	ENTITIES.GLITCH_PICKUP = api_mod:getPickupConfig("Glitched Pickups")
	ENTITIES.GLITCH_PICKUP:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.glitchConsumableUpdate)
	ENTITIES.GLITCH_PICKUP:addCallback(AlphaAPI.Callbacks.PICKUP_PICKUP, Alphabirth.glitchConsumablePickup)
	ENTITIES.GLITCH_PICKUP:setAsVariant{
		chance = 22,
		id = EntityType.ENTITY_PICKUP,
		variant = PickupVariant.PICKUP_COIN,
        condition = function(coin)
            if coin.SubType == CoinSubType.COIN_DOUBLEPACK or coin.SubType == CoinSubType.COIN_PENNY then
                return true
            else
                return false
            end
        end
	}

	ENTITIES.GLITCH_PICKUP:setAsVariant{
		chance = 22,
		id = EntityType.ENTITY_PICKUP,
		variant = PickupVariant.PICKUP_LIL_BATTERY
	}

	ENTITIES.GLITCH_PICKUP:setAsVariant{
		chance = 22,
		id = EntityType.ENTITY_PICKUP,
		variant = PickupVariant.PICKUP_HEART,
        condition = function(heart)
            if heart.SubType == HeartSubType.HEART_HALF or heart.SubType == HeartSubType.HEART_FULL or heart.SubType == HeartSubType.HEART_SCARED or heart.SubType == HeartSubType.HEART_DOUBLEPACK then
                return true
            else
                return false
            end
        end
	}
	ENTITIES.GLITCH_PICKUP:addLock(LOCKS.GLITCH_PICKUP)

	ENTITIES.STONED_BUDDY = api_mod:getEntityConfig("Stoned Buddy")
	ENTITIES.STONED_BUDDY:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.updateStonedBuddy)
	ENTITIES.STONED_BUDDY:addCallback(AlphaAPI.Callbacks.FAMILIAR_INIT, Alphabirth.initStonedBuddy)

	ENTITIES.DIVINE_WRATH = api_mod:getEntityConfig("Divine Wrath")
	ENTITIES.DIVINE_WRATH:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.updateDivineWrath)
	ENTITIES.DIVINE_WRATH:addCallback(AlphaAPI.Callbacks.FAMILIAR_INIT, Alphabirth.initDivineWrath)

	ENTITIES.CANDLE_KIT = api_mod:getEntityConfig("Candle Kit")
	ENTITIES.CANDLE_KIT:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.updateCandleKit)
    ENTITIES.CANDLE_KIT:addCallback(AlphaAPI.Callbacks.FAMILIAR_INIT, Alphabirth.initCandleKit)

    -- Familiars
    ENTITIES.BLOODERFLY = api_mod:getEntityConfig("Blooderfly", 0)
    ENTITIES.BLOODERFLY:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.onBlooderflyUpdate)
    ENTITIES.BLOODERFLY:addCallback(AlphaAPI.Callbacks.FAMILIAR_INIT, Alphabirth.initBlooderfly)

    ENTITIES.SPIRIT_EYE = api_mod:getEntityConfig("Spirit Eye", 0)
    ENTITIES.SPIRIT_EYE:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.onSpiritEyeUpdate)

    ENTITIES.INFESTED_BABY = api_mod:getEntityConfig("Infested Baby", 0)
    ENTITIES.INFESTED_BABY:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.onInfestedBabyUpdate)
    ENTITIES.INFESTED_BABY:addCallback(AlphaAPI.Callbacks.FAMILIAR_INIT, Alphabirth.onInfestedBabyInit)

    ENTITIES.SUBCONSCIOUS = api_mod:getEntityConfig("Subconscious", 0)
    ENTITIES.SUBCONSCIOUS:addCallback(AlphaAPI.Callbacks.FAMILIAR_INIT, Alphabirth.onSubconsciousInit)
    ENTITIES.SUBCONSCIOUS:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.onSubconsciousUpdate)

    ENTITIES.STONE_NUGGET = api_mod:getEntityConfig("Stone Nugget", 0)
    ENTITIES.STONE_NUGGET:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onStonePooterUpdate)

    ENTITIES.BLASPHEMOUS_LASER = api_mod:getEntityConfig("Blasphemous Laser", 0)
    ENTITIES.BLASPHEMOUS_LASER:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.onBlasphemousLaserUpdate)

	-------------------------------
	-- 			PACK 2			 --
	-------------------------------


    -- EFFECTS
    ENTITIES.CHALICE_OF_BLOOD = api_mod:getEntityConfig("Chalice of Blood", 0)
    ENTITIES.BOOK_OF_THE_DEAD_BONES = api_mod:getEntityConfig("BookOfTheDeadEffect", 0)

    -- TEARS
    ENTITIES.ABYSS_TEAR = api_mod:getEntityConfig("Abyss Tear", 0)
    ENTITIES.BONES_TEAR = api_mod:getEntityConfig("Bones Tear", 0)
    ENTITIES.CRACKED_ROCK_TEAR = api_mod:getEntityConfig("Cracked Rock Tear", 0)

    -- ENEMIES
    ENTITIES.ZYGOTE = api_mod:getEntityConfig("Zygote", 0)
    ENTITIES.ZYGOTE:setAsVariant{id = EntityType.ENTITY_EMBRYO, chance = 16, limitPerRoom = 1}
    ENTITIES.ZYGOTE:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onZygoteUpdate)

    ENTITIES.LOBOTOMY = api_mod:getEntityConfig("Lobotomy", 0)
    ENTITIES.LOBOTOMY:setAsVariant{id = EntityType.ENTITY_GAPER, chance = 16}
    ENTITIES.LOBOTOMY:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onLobotomyUpdate)
    ENTITIES.LOBOTOMY:addCallback(AlphaAPI.Callbacks.ENTITY_DEATH, Alphabirth.onLobotomyDie)

    ENTITIES.HEADLESS_ROUND_WORM = api_mod:getEntityConfig("Injured Round Worm", 0)
    ENTITIES.HEADLESS_ROUND_WORM:setAsVariant{id = EntityType.ENTITY_ROUND_WORM, chance = 16}
    ENTITIES.HEADLESS_ROUND_WORM:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onHeadlessRoundWormUpdate)

    ENTITIES.ROUND_WORM_TRIO = api_mod:getEntityConfig("Round Worm Trio", 0)
    ENTITIES.ROUND_WORM_TRIO:setAsVariant{id = EntityType.ENTITY_ROUND_WORM, chance = 18}
    ENTITIES.ROUND_WORM_TRIO:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onRoundWormTrioUpdate)

    ENTITIES.FOUR_EYED_NIGHT_CRAWLER = api_mod:getEntityConfig("3 Eyed Night Crawler", 0)
    ENTITIES.FOUR_EYED_NIGHT_CRAWLER:setAsVariant{id = EntityType.ENTITY_NIGHT_CRAWLER, chance = 12}
    ENTITIES.FOUR_EYED_NIGHT_CRAWLER:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onFourEyedNightCrawlerUpdate)

    ENTITIES.DIP_ULCER = api_mod:getEntityConfig("Dip Ulcer", 0)
    ENTITIES.DIP_ULCER:setAsVariant{id = EntityType.ENTITY_ULCER, chance = 16}
    ENTITIES.DIP_ULCER:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onDipUlcerUpdate)

    ENTITIES.LEECH_CREEP = api_mod:getEntityConfig("Leech Creep", 0)
    ENTITIES.LEECH_CREEP:setAsVariant{id = EntityType.ENTITY_BLIND_CREEP, chance = 18}
    ENTITIES.LEECH_CREEP:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onLeechCreepUpdate)

    ENTITIES.KAMIKAZE_FLY = api_mod:getEntityConfig("Kamikaze Fly", 200)
    ENTITIES.KAMIKAZE_FLY:setAsVariant{id = EntityType.ENTITY_BOOMFLY, variant = 0, chance = 16}
    ENTITIES.KAMIKAZE_FLY:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onKamikazeFlyUpdate)

    ENTITIES.DEVOURER_GLOBIN = api_mod:getEntityConfig("Devourer Globin", 1)
    ENTITIES.DEVOURER_GLOBIN:setAsVariant{id = EntityType.ENTITY_GLOBIN, chance = 12, limitPerRoom = 1}
    ENTITIES.DEVOURER_GLOBIN:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onDevourerGlobinUpdate)

    ENTITIES.DEVIL_BONY = api_mod:getEntityConfig("Devil Bony", 1)
    ENTITIES.DEVIL_BONY:setAsVariant{id = EntityType.ENTITY_BLACK_BONY, chance = 16}
    ENTITIES.DEVIL_BONY:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onDevilBonyUpdate)

    ENTITIES.OOZING_KNIGHT = api_mod:getEntityConfig("Oozing Knight", 1)
    ENTITIES.OOZING_KNIGHT:setAsVariant{
        id = EntityType.ENTITY_KNIGHT,
        chance = 18,
        stagelist = {
            LevelStage.STAGE3_1,
            LevelStage.STAGE3_2
        }
    }
    ENTITIES.OOZING_KNIGHT:setAsVariant{
        id = EntityType.ENTITY_KNIGHT,
        chance = 2,
        stagelist = {
            LevelStage.STAGE3_1,
            LevelStage.STAGE3_2
        },
        condition = function()
            Isaac.DebugString("Oozing knight spawn chance")
            local level = AlphaAPI.GAME_STATE.LEVEL
            if level:GetStageType() ~= StageType.STAGETYPE_AFTERBIRTH then
                return false
            else
                return true
            end
        end
    }
    ENTITIES.OOZING_KNIGHT:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onOozingKnightUpdate)

	-------------------------------
	-- 			PACK 3			 --
	-------------------------------

	FAMILIARS.MERCURY = api_mod:getEntityConfig("Cosmos Mercury", 0)
	FAMILIARS.VENUS = api_mod:getEntityConfig("Cosmos Venus", 0)
	FAMILIARS.PLUTO = api_mod:getEntityConfig("Cosmos Pluto", 0)

	FAMILIARS.HUSHY_FLY = api_mod:getEntityConfig("Hushy Fly", 0)
	FAMILIARS.LIL_MINER = api_mod:getEntityConfig("Lil Miner", 0)
	FAMILIARS.HIVE_HEAD = api_mod:getEntityConfig("Hive Head Orbital", 0)

	FAMILIARS.LIL_ALASTOR = api_mod:getEntityConfig("Lil Alastor", 0)
	FAMILIARS.ALASTORS_FLAME = api_mod:getEntityConfig("Alastor's Flame", 0)

	ENTITIES.METEOR_SHARD = api_mod:getPickupConfig("Meteor Shard", 0)
	ENTITIES.APPARITION = api_mod:getEntityConfig("Apparition", 0)
	ENTITIES.MEATHEAD = api_mod:getEntityConfig("Meathead", 0)
	ENTITIES.CRYSTAL = api_mod:getEntityConfig("Crystal", 0)
	ENTITIES.WIZEEKER = api_mod:getEntityConfig("Wizeeker", 0)
	ENTITIES.PLANETOID = api_mod:getEntityConfig("Planetoid Orbital")
	ENTITIES.LASERUP = api_mod:getEntityConfig("Laser Up", 1)
	ENTITIES.LASERDOWN = api_mod:getEntityConfig("Laser Down", 2)
	ENTITIES.STARGAZER = api_mod:getEntityConfig("Star Gazer", 0)
	ENTITIES.BRIMSTONE_HOST = api_mod:getEntityConfig("Brimstone Host", 20)
	ENTITIES.LARGESACK = api_mod:getPickupConfig("Large Sack", 0)

    FAMILIARS.ALASTORS_FLAME:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.updateAlastorsFlame)
    FAMILIARS.LIL_ALASTOR:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.updateLilAlastor)

    ENTITIES.LARGESACK:addCallback(AlphaAPI.Callbacks.PICKUP_PICKUP, Alphabirth.onLargeSackPickup)

    -- Spawn Familiars
    api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.smartBombsEntityAppear, EntityType.ENTITY_BOMBDROP)
    api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.smartBombsEntityUpdate, EntityType.ENTITY_BOMBDROP)

    ENTITIES.LASERUP:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onLaserUpUpdate)
    ENTITIES.LASERDOWN:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onLaserDownUpdate)
    ENTITIES.STARGAZER:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onStarGazerUpdate)

    ENTITIES.BRIMSTONE_HOST:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.onBrimstoneHostUpdate)

    ENTITIES.METEOR_SHARD:addCallback(AlphaAPI.Callbacks.PICKUP_PICKUP, Alphabirth.meteorShardPickup)

    LOCKS.APPARITION = api_mod:createUnlock("alphaApparitionLock")
    ENTITIES.APPARITION:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.apparitionUpdate)
    ENTITIES.APPARITION:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alphabirth.apparitionDamage)
    ENTITIES.APPARITION:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.apparitionAppear)

    ENTITIES.MEATHEAD:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.meatheadUpdate)

	ENTITIES.WIZEEKER:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.wizeekerUpdate)

    ENTITIES.PLANETOID:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.planetoidAppear)
    ENTITIES.PLANETOID:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.planetoidUpdate)
    ENTITIES.PLANETOID:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alphabirth.planetoidTakeDamage)

    ENTITIES.CRYSTAL:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.crystalUpdate)

    FAMILIARS.MERCURY:addCallback(AlphaAPI.Callbacks.FAMILIAR_INIT, Alphabirth.initializeMercury)
    FAMILIARS.MERCURY:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.updateMercury)

    FAMILIARS.VENUS:addCallback(AlphaAPI.Callbacks.FAMILIAR_INIT, Alphabirth.initializeVenus)
    FAMILIARS.VENUS:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.updateVenus)

    FAMILIARS.PLUTO:addCallback(AlphaAPI.Callbacks.FAMILIAR_INIT, Alphabirth.initializePluto)
    FAMILIARS.PLUTO:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.updatePluto)

    FAMILIARS.HUSHY_FLY:addCallback(AlphaAPI.Callbacks.FAMILIAR_INIT, Alphabirth.initializeHushyFly)
    FAMILIARS.HUSHY_FLY:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.updateHushyFly)

    FAMILIARS.LIL_MINER:addCallback(AlphaAPI.Callbacks.FAMILIAR_INIT, Alphabirth.initializeLilMiner)
    FAMILIARS.LIL_MINER:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.updateLilMiner)

	FAMILIARS.HIVE_HEAD:addCallback(AlphaAPI.Callbacks.FAMILIAR_INIT, Alphabirth.initializeHiveHead)
    FAMILIARS.HIVE_HEAD:addCallback(AlphaAPI.Callbacks.FAMILIAR_UPDATE, Alphabirth.updateHiveHead)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, Alphabirth.updateHiveHeadMod, -FAMILIARS.HIVE_HEAD.variant)

    api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.hushLaserUpdate, EntityType.ENTITY_EFFECT, EffectVariant.HUSH_LASER)
     api_mod:addCallback(AlphaAPI.Callbacks.CHALLENGE_COMPLETED, Alphabirth.completeChallenge)

end

function Alphabirth.activeItemRenderSetup()
	dynamicActiveItems = {

	cauldron = {
			item = ITEMS.ACTIVE.CAULDRON.id,
			sprite = "gfx/animations/animation_collectible_cauldron.anm2",
			functionality = Alphabirth.cauldronUpdate
			},
	chalice = {
			item = ITEMS.ACTIVE.CHALICE_OF_BLOOD.id,
			sprite = "gfx/animations/animation_collectible_chaliceofblood.anm2",
			functionality = Alphabirth.chaliceOfBloodUpdate
			},
	}

	for k,v in pairs(dynamicActiveItems) do
		if itemSprites[k] == nil then
			itemSprites[k] = Sprite()
			itemSprites[k]:Load(v.sprite, true)
		end
	end
end

-- Setup Function for Miscellaneous Callbacks
function Alphabirth.setupMiscCallbacks()
	api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alphabirth.entityTakeDamage)
    api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.bugBombsAppear, EntityType.ENTITY_BOMBDROP)
    api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alphabirth.bugBombsUpdate, EntityType.ENTITY_BOMBDROP)
	api_mod:addCallback(AlphaAPI.Callbacks.PLAYER_DIED, Alphabirth.handleOldController)
	api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_DEATH, Alphabirth.handleGraphicsError)

	-- Take Damage
	mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Alphabirth.triggerCrackedRockEffect)
	mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Alphabirth.triggerAbyss)
	mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Alphabirth.entityTakeDmgBookOfTheDead)
	mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Alphabirth.entityTakeDmgStoneNugget)
	mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Alphabirth.triggerQuillFeather)

	-- Mod Updates
	mod:AddCallback(ModCallbacks.MC_POST_UPDATE, Alphabirth.modUpdate)
	mod:AddCallback(ModCallbacks.MC_POST_RENDER, Alphabirth.ActiveItemRender)
	mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Alphabirth.evaluateCache)

	-- Player Init
	mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Alphabirth.playerInit)
	api_mod:addCallback(AlphaAPI.Callbacks.RUN_STARTED, Alphabirth.runStarted)
	api_mod:addCallback(AlphaAPI.Callbacks.ROOM_CHANGED, Alphabirth.roomChanged)
	api_mod:addCallback(AlphaAPI.Callbacks.CHALLENGE_COMPLETED, Alphabirth.completeChallenge)

	api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_DEATH, Alphabirth.killDelirium, 412)
	api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_DEATH, Alphabirth.killHush, EntityType.ENTITY_HUSH)
	api_mod:addCallback(AlphaAPI.Callbacks.ENTITY_DEATH, Alphabirth.killMegaSatan, EntityType.ENTITY_MEGA_SATAN_2)
end

function Alphabirth.playerInit(_, player)
    if player:GetPlayerType() == endor_type then
        player:GetSprite():Load("gfx/animations/costumes/players/animation_character_endor.anm2", true)
    end
end

function Alphabirth.completeChallenge(challenge)
	if challenge == CHALLENGES.EXPLODING_HEAD_SYNDROME then
		if not LOCKS.GLITCH_PICKUP:isUnlocked() then
			AlphaAPI.playOverlay(AlphaAPI.OverlayType.UNLOCK, "gfx/ui/achievement/achievement_glitchedpickups.png")
			LOCKS.GLITCH_PICKUP:setUnlocked(true)
		end
	elseif challenge == CHALLENGES.FAUST then
		if not LOCKS.EMPEROR_CROWN:isUnlocked() then
			AlphaAPI.playOverlay(AlphaAPI.OverlayType.UNLOCK, "gfx/ui/achievement/achievement_emperorscrown.png")
			LOCKS.EMPEROR_CROWN:setUnlocked(true)
		end
	elseif challenge == CHALLENGES.SHI7TIEST_DAY_EVER then
		if not LOCKS.BROWN_EYE:isUnlocked() then
			AlphaAPI.playOverlay(AlphaAPI.OverlayType.UNLOCK, "gfx/ui/achievement/achievement_browneye.png")
			LOCKS.BROWN_EYE:setUnlocked(true)
		end
	elseif challenge == CHALLENGES.EMPTY and not LOCKS.GEBO:isUnlocked() then
		LOCKS.FEHU:setUnlocked(true)
		AlphaAPI.playOverlay(AlphaAPI.OverlayType.UNLOCK, "gfx/ui/achievement/achievement_fehu.png")
	elseif challenge == CHALLENGES.FOR_THE_HOARD and not LOCKS.NAUDIZ:isUnlocked() then
		LOCKS.NAUDIZ:setUnlocked(true)
		AlphaAPI.playOverlay(AlphaAPI.OverlayType.UNLOCK, "gfx/ui/achievement/achievement_naudiz.png")
	elseif challenge == CHALLENGES.RESTLESS_LEG_SYNDROME and not LOCKS.SOWILO:isUnlocked() then
		LOCKS.SOWILO:setUnlocked(true)
		AlphaAPI.playOverlay(AlphaAPI.OverlayType.UNLOCK, "gfx/ui/achievement/achievement_sowilo.png")
	elseif challenge == CHALLENGES.THE_COLLECTOR and not LOCKS.FEHU:isUnlocked() then
		LOCKS.GEBO:setUnlocked(true)
		AlphaAPI.playOverlay(AlphaAPI.OverlayType.UNLOCK, "gfx/ui/achievement/achievement_gebo.png")
	elseif challenge == CHALLENGES.IT_FOLLOWS then
        LOCKS.APPARITION:setUnlocked(true)
        AlphaAPI.playOverlay(AlphaAPI.OverlayType.UNLOCK, "gfx/ui/achievement/achievement_apparition.png")
	end
end

function Alphabirth.killDelirium()
	local player_type = AlphaAPI.GAME_STATE.PLAYERS[1]:GetPlayerType()
	if player_type == character_null and not LOCKS.OLD_CONTROLLER:isUnlocked() then
		AlphaAPI.playOverlay(AlphaAPI.OverlayType.UNLOCK, "gfx/ui/achievement/achievement_oldcontroller.png")
		LOCKS.OLD_CONTROLLER:setUnlocked(true)
	end
	if player_type == endor_type and not LOCKS.SUBCONSCIOUS:isUnlocked() then
		AlphaAPI.playOverlay(AlphaAPI.OverlayType.UNLOCK, "gfx/ui/Achievement/achievement_subconscious.png")
		LOCKS.SUBCONSCIOUS:setUnlocked(true)
	end
end

function Alphabirth.killHush()
	local player_type = AlphaAPI.GAME_STATE.PLAYERS[1]:GetPlayerType()
	if player_type == character_null and not LOCKS.BUGGED_BOMBS:isUnlocked() then
		AlphaAPI.playOverlay(AlphaAPI.OverlayType.UNLOCK, "gfx/ui/achievement/achievement_buggedbombs.png")
		LOCKS.BUGGED_BOMBS:setUnlocked(true)
	end
	if player_type == endor_type and not LOCKS.ENDOR_HAT:isUnlocked() then
		AlphaAPI.playOverlay(AlphaAPI.OverlayType.UNLOCK, "gfx/ui/Achievement/achievement_endorshat.png")
		LOCKS.ENDOR_HAT:setUnlocked(true)
	end
end

function Alphabirth.killMegaSatan()
	local player_type = AlphaAPI.GAME_STATE.PLAYERS[1]:GetPlayerType()
	if player_type == character_null and not LOCKS.GRAPHICS_ERROR:isUnlocked() then
		AlphaAPI.playOverlay(AlphaAPI.OverlayType.UNLOCK, "gfx/ui/achievement/achievement_graphicserror.png")
		LOCKS.GRAPHICS_ERROR:setUnlocked(true)
	end
	local player_type = AlphaAPI.GAME_STATE.PLAYERS[1]:GetPlayerType()
	if player_type == endor_type and not LOCKS.ENDOR_HAT:isUnlocked() then
		AlphaAPI.playOverlay(AlphaAPI.OverlayType.UNLOCK, "gfx/ui/Achievement/achievement_endorshat.png")
		LOCKS.ENDOR_HAT:setUnlocked(true)
	end
end

---------------------------------------
-- Player synergies
---------------------------------------
local PLAYER_SYNERGY = {
    DR_FETUS = 1,
    TECH_X = 1 << 1,
    TECHNOLOGY = 1 << 2,
    TECHNOLOGY_2 = 1 << 3,
    BRIMSTONE = 1 << 4,
    MOMS_KNIFE = 1 << 5,
    EPIC_FETUS = 1 << 6
}

local function getPlayerSynergies()
    local s = 0
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    for k, v in pairs(PLAYER_SYNERGY) do
        -- maybe want to use HasCollectibleEffect ?
        if player:HasCollectible(CollectibleType["COLLECTIBLE_"..k]) then
            s = s | v
        end
    end
    return s
end

---------------------------------------
-- Curses & Blessings
---------------------------------------
function Alphabirth.handleLonelyCurse(ent)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    if ent.Variant ~= 100 and player.Position:Distance(ent.Position) <= 35 then
        local direction_vector = (ent.Position - player.Position):Normalized()
        ent.Velocity = ent.Velocity + direction_vector * 2
    end
end

local DUALITY_VARIANTS = {
    PickupVariant.PICKUP_HEART,
    PickupVariant.PICKUP_COIN,
    PickupVariant.PICKUP_BOMB,
    PickupVariant.PICKUP_KEY
}

local EFFECTED_HEARTS = {
    HeartSubType.HEART_FULL,
    HeartSubType.HEART_HALF,
    HeartSubType.HEART_SCARED
}
function Alphabirth.pickupSpawnDuality(entity, data)
    entity = entity:ToPickup()
    if AlphaAPI.tableContains(DUALITY_VARIANTS, entity.Variant) then
        if entity.Variant == PickupVariant.PICKUP_HEART then
            if AlphaAPI.tableContains(EFFECTED_HEARTS, entity.SubType) then
                entity:Morph(entity.Type, entity.Variant, HeartSubType.HEART_DOUBLEPACK, true)
            end
        end

        if entity.Variant == PickupVariant.PICKUP_BOMB and entity.SubType == BombSubType.BOMB_NORMAL then
            entity:Morph(entity.Type, entity.Variant, BombSubType.BOMB_DOUBLEPACK, true)
        end

        if entity.Variant == PickupVariant.PICKUP_KEY and entity.SubType == KeySubType.KEY_NORMAL then
            entity:Morph(entity.Type, entity.Variant, KeySubType.KEY_DOUBLEPACK, true)
        end

        if entity.Variant == PickupVariant.PICKUP_COIN and entity.SubType == CoinSubType.COIN_PENNY then
            entity:Morph(entity.Type, entity.Variant, CoinSubType.COIN_DOUBLEPACK, true)
        end
    end
end

function Alphabirth.triggerKnowledge()
    AlphaAPI.callDelayed(function()
        local level = AlphaAPI.GAME_STATE.LEVEL
        level:ApplyCompassEffect(true)
    end, 5)
end

local DOOR_SLOTS = {
    DoorSlot.DOWN0,
    DoorSlot.DOWN1,
    DoorSlot.LEFT0,
    DoorSlot.LEFT1,
    DoorSlot.RIGHT0,
    DoorSlot.RIGHT1,
    DoorSlot.UP0,
    DoorSlot.UP1
}

function Alphabirth.handleFreedom()
    local room = AlphaAPI.GAME_STATE.ROOM
    if room:IsClear() then
        for _, doorSlot in ipairs(DOOR_SLOTS) do
            local door = room:GetDoor(doorSlot)
            if door then
                if not door:IsOpen() then
                    if not (door:IsRoomType(RoomType.ROOM_SUPERSECRET)
                    or door:IsRoomType(RoomType.ROOM_SECRET)
                    or door:IsRoomType(RoomType.ROOM_BARREN)
                    or door:IsRoomType(RoomType.ROOM_BLACK_MARKET)
                    or door:IsRoomType(RoomType.ROOM_GREED_EXIT)
                    or door:IsRoomType(RoomType.ROOM_DEVIL)
                    or door:IsRoomType(RoomType.ROOM_ANGEL)) then
                        door:SetLocked(false)
                    end
                end
            end
        end
    end
end

---------------------------------------
-- Functions
---------------------------------------

--[[ File name things to prepend later when calling AlphaAPI.playOverlay()

filename = ""..filename
filename = "gfx/ui/achievement/"..filename

]]

local STREAK_OVERLAY_TEXT = {
    CYBORG = "gfx/ui/streak/cyborg.png",
    DAMNED = "gfx/ui/streak/damned.png"
}

---------------------------------------
-- Variables that need to be loaded early
---------------------------------------
local BOTD_BLACKLIST = {
	EntityType.ENTITY_MOM,
    EntityType.ENTITY_FISTULA_BIG,
    EntityType.ENTITY_FISTULA_MEDIUM,
    EntityType.ENTITY_FISTULA_SMALL,
    EntityType.ENTITY_SATAN,
    EntityType.ENTITY_MEGA_SATAN,
    EntityType.ENTITY_MEGA_SATAN_2,
    EntityType.ENTITY_THE_HAUNT,
    EntityType.ENTITY_FORSAKEN,
    EntityType.ENTITY_MASK_OF_INFAMY,
    EntityType.ENTITY_BROWNIE,
    EntityType.ENTITY_MAMA_GURDY,
    EntityType.ENTITY_MOMS_HEART,
    EntityType.ENTITY_HUSH,
    EntityType.ENTITY_ISAAC,
    EntityType.ENTITY_THE_LAMB,
    EntityType.ENTITY_ENVY,
    EntityType.ENTITY_DART_FLY,
    EntityType.ENTITY_RING_OF_FLIES,
    EntityType.ENTITY_HEART,
    EntityType.ENTITY_MASK
}

-- Active Item Function Definitions
do
	----------------------------------------
	-- Debug Logic
	----------------------------------------
	function Alphabirth.triggerDebug()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		ENTITIES.GLITCH_PICKUP:spawn(player.Position, player.Velocity, player)
	end

	---------------------------------------
	-- Trash Bag Logic
	---------------------------------------
	function Alphabirth.triggerTrashBag()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	    -- Always spawns either spiders or flies
	    -- 25% chance to spawn extra spiders, 25% for extra flies,
	    -- 50% to spawn a pickup, 3% to spawn a pickup, 0.2% to spawn an item
	    local spider_fly_chance = random(1, 2)
	    if spider_fly_chance == 1 then
	        for i = 1, random(1, 4) do
	            player:AddBlueSpider(player.Position)
	        end
	    else
	        player:AddBlueFlies(random(1, 4),
	            player.Position,
	            nil)
	    end

	    local blue_fly_chance = random(1, 4)
	    if blue_fly_chance == 1 then
	        player:AddBlueFlies(random(1, 4),
	            player.Position,
	            nil)
	    end

	    local blue_spider_chance = random(1, 4)
	    if blue_spider_chance == 1 then
	        for i = 1, random(1, 4) do
	            player:AddBlueSpider(player.Position)
	        end
	    end

	    local pickup_chance = random(1, (100 - (player.Luck * 2)))
	    if pickup_chance <= 50 then
	        local pickup_type = random(1, 7)
	        local subtype_to_spawn = 0 -- seems to be random for most pickups
	        local pickup_to_spawn = nil
	        if pickup_type == 1 then
	            pickup_to_spawn = PickupVariant.PICKUP_HEART
	        elseif pickup_type == 2 then
	            pickup_to_spawn = PickupVariant.PICKUP_COIN
	        elseif pickup_type == 3 then
	            pickup_to_spawn = PickupVariant.PICKUP_KEY
	        elseif pickup_type == 4 then
	            pickup_to_spawn = PickupVariant.PICKUP_GRAB_BAG
	        elseif pickup_type == 5 then
	            pickup_to_spawn = PickupVariant.PICKUP_PILL
	        elseif pickup_type == 6 then
	            pickup_to_spawn = PickupVariant.PICKUP_LIL_BATTERY
	        elseif pickup_type == 7 then
	            pickup_to_spawn = PickupVariant.PICKUP_TAROTCARD
	        end

	        local spawn_position = AlphaAPI.GAME_STATE.ROOM:FindFreePickupSpawnPosition(player.Position, 1, true)
	        Isaac.Spawn(EntityType.ENTITY_PICKUP,
	            pickup_to_spawn,
	            subtype_to_spawn,
	            spawn_position,
	            Vector(0, 0),
	            player)
	    end

	    local trinket_chance = random(1, 33)
	    if trinket_chance == 1 then
	        local spawn_position = AlphaAPI.GAME_STATE.ROOM:FindFreePickupSpawnPosition(player.Position, 1, true)
	        Isaac.Spawn(EntityType.ENTITY_PICKUP,
	            PickupVariant.PICKUP_TRINKET,
	            0,
	            spawn_position,
	            Vector(0, 0),
	            player)
	    end

	    local item_chance = random(1, 500)
	    if item_chance == 1 then
	        local spawn_position = AlphaAPI.GAME_STATE.ROOM:FindFreePickupSpawnPosition(player.Position, 1, true)
	        Isaac.Spawn(EntityType.ENTITY_PICKUP,
	            PickupVariant.PICKUP_COLLECTIBLE,
	            0,
	            spawn_position,
	            Vector(0, 0),
	            player)
	    end
	    return true
	end

	----------------------------------------
	-- Delirium's Brain Logic
	----------------------------------------
	function Alphabirth.triggerDeliriumsBrain()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	    for _, entity in ipairs(AlphaAPI.entities.all) do
	        if entity.Type == EntityType.ENTITY_TEAR or entity.Type == EntityType.ENTITY_PROJECTILE then
	            local tear_position = entity.Position
	            local reverse_tear_velocity = Vector(-entity.Velocity.X, -entity.Velocity.Y)

	            -- Find Tear Synergies
	            if player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) then
	                player:FireTechLaser(tear_position,
	                                     LaserOffset.LASER_TECH1_OFFSET,
	                                     reverse_tear_velocity,
	                                     false,
	                                     false)
	            elseif player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then
	                player:FireTechXLaser(tear_position, reverse_tear_velocity, 1) -- radius
	            elseif player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then
	                player:FireDelayedBrimstone(reverse_tear_velocity:GetAngleDegrees(), entity)
	            elseif player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) then
	                player:FireBomb(tear_position, reverse_tear_velocity)
	            else
	                -- NOTE: Mom's Knife WILL NOT work
	                player:FireTear(
	                    tear_position,          -- position
	                    reverse_tear_velocity,  -- velocity
	                    false,                  -- From API: CanBeEye?
	                    false,                  -- From API: NoTractorBeam
	                    false                   -- From API: CanTriggerStreakEnd
	                )
	            end

	            -- Remove The Old Tear
	            entity:Die()
	        end
	    end
	    return true
	end

	-------------------------------------------------------------------------------
	---- PACK 2
	-------------------------------------------------------------------------------

	---------------------------------------
	-- Cauldron Logic
	---------------------------------------
	function Alphabirth.triggerCauldron()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
			return
		end

		if api_mod.data.run.cauldron_points >= 25 then
			local free_position = AlphaAPI.GAME_STATE.ROOM:FindFreePickupSpawnPosition(player.Position, 1, true)
			local pool = random(ItemPoolType.POOL_TREASURE, ItemPoolType.POOL_BOMB_BUM)
			local id = AlphaAPI.GAME_STATE.GAME:GetItemPool():GetCollectible(pool, true, AlphaAPI.GAME_STATE.ROOM:GetAwardSeed())
			local spawned_item = Isaac.Spawn(EntityType.ENTITY_PICKUP,
				PickupVariant.PICKUP_COLLECTIBLE,
				id,
				free_position,
				Vector(0,0),
				player)
			AlphaAPI.addFlag(spawned_item, ENTITY_FLAGS.MORPH_TRIED)
			api_mod.data.run.cauldron_points = api_mod.data.run.cauldron_points - 25
			player:AnimateHappy()
		else
			for _, entity in ipairs(AlphaAPI.entities.friendly) do
				if entity.Type == EntityType.ENTITY_PICKUP and not entity:IsDead() then
					if entity.Variant ~= PickupVariant.PICKUP_COLLECTIBLE and
							entity.Variant ~= PickupVariant.PICKUP_BIGCHEST and
							entity.Variant ~= PickupVariant.PICKUP_BED and
							entity.Variant ~= PickupVariant.PICKUP_TROPHY then
						if entity.Variant == PickupVariant.PICKUP_TRINKET then
							api_mod.data.run.cauldron_points = api_mod.data.run.cauldron_points + 5
						elseif entity.Variant == PickupVariant.PICKUP_COIN then
							if entity.SubType == CoinSubType.COIN_DIME then
								api_mod.data.run.cauldron_points = api_mod.data.run.cauldron_points + 10
							elseif entity.SubType == CoinSubType.COIN_DOUBLEPACK then
								api_mod.data.run.cauldron_points = api_mod.data.run.cauldron_points + 2
							elseif entity.SubType == CoinSubType.COIN_NICKEL or
									entity.SubType == CoinSubType.COIN_STICKYNICKEL then
								api_mod.data.run.cauldron_points = api_mod.data.run.cauldron_points + 5
							else
								api_mod.data.run.cauldron_points = api_mod.data.run.cauldron_points + 1
							end
						elseif entity.Variant == PickupVariant.PICKUP_BOMB then
							if entity.SubType == BombSubType.BOMB_DOUBLEPACK then
								api_mod.data.run.cauldron_points = api_mod.data.run.cauldron_points + 2
							elseif entity.SubType == BombSubType.BOMB_GOLDEN then
								api_mod.data.run.cauldron_points = api_mod.data.run.cauldron_points + 3
							else
								api_mod.data.run.cauldron_points = api_mod.data.run.cauldron_points + 1
							end
						elseif entity.Variant == PickupVariant.PICKUP_KEY then
							if entity.SubType == KeySubType.KEY_DOUBLEPACK then
								api_mod.data.run.cauldron_points = api_mod.data.run.cauldron_points + 2
							elseif entity.SubType == KeySubType.KEY_GOLDEN then
								api_mod.data.run.cauldron_points = api_mod.data.run.cauldron_points + 3
							else
								api_mod.data.run.cauldron_points = api_mod.data.run.cauldron_points + 1
							end
						elseif entity.Variant == PickupVariant.PICKUP_ETERNALCHEST or
								entity.Variant == PickupVariant.PICKUP_LOCKEDCHEST or
								entity.Variant == PickupVariant.PICKUP_BOMBCHEST then
							api_mod.data.run.cauldron_points = api_mod.data.run.cauldron_points + 3
						else
							api_mod.data.run.cauldron_points = api_mod.data.run.cauldron_points + 1
						end

						pickup_entity = entity:ToPickup()
						pickup_entity.Timeout = 1

						Isaac.Spawn(
							EntityType.ENTITY_EFFECT,
							EffectVariant.POOF01,
							0,            -- Entity Subtype
							pickup_entity.Position,
							Vector(0, 0), -- Velocity
							player
						)

						player:AnimateHappy()
					end
				end
			end
		end
	end

	---------------------------------------
	-- Surgeon Simulator Logic
	---------------------------------------
	function Alphabirth.triggerSurgeonSimulator()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
			return
		end

		local spawnPos = AlphaAPI.GAME_STATE.ROOM:FindFreePickupSpawnPosition(player.Position, 1, true)
		if player:GetHearts() == 2 then
			player:AddHearts(-1)
			Isaac.Spawn(5, 10, 2, spawnPos, Vector(0, 0), player)
		end
		if player:GetHearts() > 2 then
			player:AddHearts(-2)
			Isaac.Spawn(5, 10, 1, spawnPos, Vector(0, 0), player)
		end
		return true
	end

	----------------------------------------
	-- Mirror Logic
	----------------------------------------
	function Alphabirth.triggerMirror()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		local room = AlphaAPI.GAME_STATE.ROOM
		if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
			return
		end

		-- Get room entities.
		local ents = AlphaAPI.entities.enemies

		-- Get number of entities, and generate a random number between 1 and the number of entities.
		local num_ents = #ents

		local rand_key = random(num_ents)

		-- Make sure the entity is an enemy, not a fire, and not a portal.
		-- Switch Isaac's position with the entity's position.
		-- Animate the teleportation.
		-- Further randomize the selection.
		if room:GetAliveEnemiesCount() > 0 then
			for rand_key, entity in pairs(ents) do
				if entity.Type ~= 306 and -- Portals
						entity.Type ~= 304 and -- The Thing
						entity.Type ~= EntityType.ENTITY_RAGE_CREEP and
						entity.Type ~= EntityType.ENTITY_BLIND_CREEP and
						entity.Type ~= EntityType.ENTITY_WALL_CREEP and
						entity.Velocity:Length() > 0.1 then
					local player_pos = player.Position
					local entity_pos = entity.Position

					player.Position = entity_pos
					entity.Position = player_pos

					player:AnimateTeleport()

					rand_key = random(1, num_ents)
				end
			end
		else
			local teleport_pos = room:FindFreePickupSpawnPosition(room:GetDoorSlotPosition(random(DoorSlot.LEFT0, DoorSlot.DOWN0)), 1, true)
			player.Position = teleport_pos
			player:AnimateTeleport()
		end
	end

	----------------------------------------
	-- Bionic Arm Logic
	----------------------------------------

	local bionicDamage = 200
	function Alphabirth.triggerBionicArm()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
			return
		end

		local ents = AlphaAPI.entities.enemies
		for _, e in ipairs(ents) do
			e:TakeDamage(bionicDamage, 0, EntityRef(player), 0)
		end

		return true
	end

	function Alphabirth.applyBionicArmCache(player, cache_flag)
		local charge = player:GetActiveCharge()
		if cache_flag == CacheFlag.CACHE_DAMAGE then
			player.Damage = player.Damage + (charge/6)
		end
	end

	---------------------------------------
	-- Blood Drive Logic
	---------------------------------------
	function Alphabirth.handleBloodDrive()
		local currentRoom = AlphaAPI.GAME_STATE.ROOM
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if api_mod.data.run.bloodDriveTimesUsed > 0 then
			for _, ent in ipairs(AlphaAPI.entities.enemies) do
				if ent.FrameCount == 1 then
					ent.MaxHitPoints = ent.MaxHitPoints - ent.MaxHitPoints/(12/api_mod.data.run.bloodDriveTimesUsed)
					ent.HitPoints = ent.MaxHitPoints
					for i=1, api_mod.data.run.bloodDriveTimesUsed do
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 0, ent.Position, Vector(0,0), player)
					end
				end
			end
		end
	end

	function Alphabirth.triggerBloodDrive()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
			return
		end

		local total_hearts = player:GetMaxHearts()
		if total_hearts > 2 and player:GetPlayerType() ~= PlayerType.PLAYER_XXX then
			api_mod.data.run.bloodDriveTimesUsed = api_mod.data.run.bloodDriveTimesUsed + 1
			player:AddMaxHearts(-2)
			AlphaAPI.GAME_STATE.GAME:Darken(1, 8)
			player:AnimateSad()
		end
	end

	---------------------------------------
	-- Chalice of Blood Logic
	---------------------------------------
	local chalice
	local soul_limit = 15
	function Alphabirth.applyChaliceOfBloodCache(player, cache_flag)
		if cache_flag == CacheFlag.CACHE_DAMAGE then
			player.Damage = player.Damage * api_mod.data.run.CHALICE_STATS.DAMAGE
		elseif cache_flag == CacheFlag.CACHE_SHOTSPEED then
			player.ShotSpeed = player.ShotSpeed + api_mod.data.run.CHALICE_STATS.SHOTSPEED
		end
	end

	function Alphabirth.triggerChaliceOfBlood()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		local room = AlphaAPI.GAME_STATE.ROOM

		if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
			return
		end

		if api_mod.data.run.chaliceSouls < soul_limit then

			if chalice ~= nil then
			chalice:Remove()
			end

			chalice = ENTITIES.CHALICE_OF_BLOOD:spawn(
				player.Position,
				Vector(0,0),
				player
			)
		else
			api_mod.data.run.CHALICE_STATS.DAMAGE = 2
			api_mod.data.run.CHALICE_STATS.SHOTSPEED = 0.4
			player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
			player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
			player:AddNullCostume(COSTUMES.CHALICE_OF_BLOOD_COSTUME)
			player:EvaluateItems()
			playSound(SoundEffect.SOUND_VAMP_GULP, 1, 0, false, 1)
			api_mod.data.run.chaliceSouls = 0
		end
		return true
	end

	function Alphabirth.handleChaliceOfBlood()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		local room = AlphaAPI.GAME_STATE.ROOM

		-- Remove Chalice if room is clear
		if room:GetFrameCount() == 1 then
			player:TryRemoveNullCostume(COSTUMES.CHALICE_OF_BLOOD_COSTUME)
			api_mod.data.run.CHALICE_STATS.DAMAGE = 1
			api_mod.data.run.CHALICE_STATS.SHOTSPEED = 0
			player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
			player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
			player:EvaluateItems()
		end

		if room:IsClear() and chalice ~= nil then
			Isaac.Spawn(
				EntityType.ENTITY_EFFECT,
				EffectVariant.POOF01,
				0,            -- Entity Subtype
				chalice.Position,
				Vector(0, 0), -- Velocity
				nil
			)
			chalice:Remove()
			chalice = nil
		end

		if chalice ~= nil then
			for _, entity in ipairs(AlphaAPI.entities.all) do
				if entity.Type == EntityType.ENTITY_PLAYER and entity.Position:Distance(chalice.Position) <= 140 and AlphaAPI.GAME_STATE.GAME:GetFrameCount() % 15 == 0 then
					Isaac.Spawn(EntityType.ENTITY_EFFECT,EffectVariant.PLAYER_CREEP_RED,0,player.Position,Vector(0, 0),player)
				end

				local entity_is_close = entity.Position:Distance(chalice.Position) <= 140
				if entity:IsDead() and entity:ToNPC() and entity_is_close and not entity:IsBoss() then
					playSound(SoundEffect.SOUND_SUMMONSOUND, 0.5, 0, false, 0.8)
					Isaac.Spawn(
						EntityType.ENTITY_EFFECT,
						EffectVariant.POOF02,
						0,            -- Entity Subtype
						entity.Position,
						Vector(0, 0), -- Velocity
						nil
					)
					api_mod.data.run.chaliceSouls = api_mod.data.run.chaliceSouls + 1
				end
			end
		end

		if api_mod.data.run.chaliceSouls >= soul_limit and chalice ~= nil then
			playSound(SoundEffect.SOUND_SUMMONSOUND, 0.5, 0, false, 0.9)
			Isaac.Spawn(
				EntityType.ENTITY_EFFECT,
				EffectVariant.POOF01,
				0,            -- Entity Subtype
				chalice.Position,
				Vector(0, 0), -- Velocity
				nil
			)
			chalice:Remove()
			chalice = nil
		end
	end

	----------------------------------------
	-- Blacklight Logic
	----------------------------------------
	local timesTillMax = 20

	function Alphabirth.triggerBlacklight()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
			return
		end

		if api_mod.data.run.blacklightUses < timesTillMax then
			api_mod.data.run.blacklightUses = api_mod.data.run.blacklightUses + 1
			api_mod.data.run.darkenCooldown = 0
			for i, entity in ipairs(AlphaAPI.entities.enemies) do
				entity:TakeDamage(40, 0, EntityRef(player), 30)
			end

			return true
		end
	end

	----------------------------------------
	-- Blasphemous Logic
	----------------------------------------

	function Alphabirth.triggerBlasphemous()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
			return
		end

		local laser = ENTITIES.BLASPHEMOUS_LASER:spawn(
			player.Position,
			Vector(0, 0),
			player
		)

		laser:GetData().roomIdx = AlphaAPI.GAME_STATE.LEVEL:GetCurrentRoomIndex()
		return true
	end

	function Alphabirth.onBlasphemousLaserUpdate(laser)
		local currentRoomIdx = AlphaAPI.GAME_STATE.LEVEL:GetCurrentRoomIndex()
		local room = AlphaAPI.GAME_STATE.ROOM
		if laser:GetData().roomIdx ~= currentRoomIdx or room:GetFrameCount() == 1 then
			laser:Remove()
		end

		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		laser:FollowPosition(player.Position)
		laser.Velocity = laser.Velocity * 0.4
		laser.CollisionDamage = (player.Damage / player.MaxFireDelay) * 7

		local gridposition = room:GetGridIndex(laser.Position)
		local gridentity = room:GetGridEntity(gridposition)


		if gridentity then
			local type = gridentity.Desc.Type
			if not gridentity:ToDoor() and type ~= GridEntityType.GRID_WALL then
				gridentity:Destroy(true)
			end
		end

		for _, entity in ipairs(AlphaAPI.entities.all) do
			if entity.Type == EntityType.ENTITY_FIREPLACE then
				if laser.Position:Distance(entity.Position) < 20 then
					entity:TakeDamage(laser.CollisionDamage, 0, EntityRef(player), 0)
				end
			end
			if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == 51 then
				if laser.Position:Distance(entity.Position) < 20 then
					entity:ToPickup():TryOpenChest()
				end
			end
			if entity.Type == EntityType.ENTITY_SLOT then
				if laser.Position:Distance(entity.Position) < 20 then
					entity:TakeDamage(laser.CollisionDamage, DamageFlag.DAMAGE_EXPLOSION, EntityRef(player), 0)
				end
			end
		end
	end

	----------------------------------------
	-- Stone Nugget Logic
	----------------------------------------

	function Alphabirth.triggerStoneNugget()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
			return
		end

		local pooter = ENTITIES.STONE_NUGGET:spawn(
			player.Position,
			Vector(0, 0),
			player)
		pooter:GetData().roomIdx = AlphaAPI.GAME_STATE.LEVEL:GetCurrentRoomIndex()
		return true
	end

	local function Lerp(v1, v2, t)
		return Vector(
			(1 - t) * v1.X + t * v2.X,
			(1 - t) * v1.Y + t * v2.Y
		)
	end

	function Alphabirth.onStonePooterUpdate(pooter)
		local currentRoomIdx = AlphaAPI.GAME_STATE.LEVEL:GetCurrentRoomIndex()
		if pooter:GetData().roomIdx ~= currentRoomIdx then
			pooter:Remove()
		end
		if random(1, 100) == 1 then
			pooter.FlipX = not pooter.FlipX
		end

		local e_frame = pooter.FrameCount
		if e_frame % 2 == 0 then
			e_frame = 1.0 - math.cos(e_frame * math.pi * 0.5)
			local nearest_enemy = AlphaAPI.findNearestEntity(pooter, AlphaAPI.entities.enemies)
			if nearest_enemy then
				local direction = (nearest_enemy.Position - pooter.Position):GetAngleDegrees()
				local move_direction = Vector.FromAngle(random(direction - 35, direction + 35))
				pooter.Velocity = Lerp(pooter.Velocity, move_direction * (random(50, 150) * 0.01), e_frame)
			end
		end
	end

	function Alphabirth:entityTakeDmgStoneNugget(target, dmg, flag, source, frames)
		if not source or
		(source.Type ~= ENTITIES.STONE_NUGGET.id and
		source.Variant ~= ENTITIES.STONE_NUGGET.variant) then
			return
		end
		if target.HitPoints - dmg <= 0 then
			local player = AlphaAPI.GAME_STATE.PLAYERS[1]
			if player:GetActiveItem() == ITEMS.ACTIVE.STONE_NUGGET.id then
				player:SetActiveCharge(1)
			end
		end
	end

	---------------------------------------
	-- Book of the Dead Logic
	---------------------------------------
	function Alphabirth.triggerBookOfTheDead()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
			return
		end

		api_mod.data.run.BOTD_ents = {}
		for i, entity in ipairs(AlphaAPI.entities.effects) do
			if entity.Type == ENTITIES.BOOK_OF_THE_DEAD_BONES.id and
					entity.Variant == ENTITIES.BOOK_OF_THE_DEAD_BONES.variant then
				local data = entity:GetData()["BOTD_data"]
				data.id = #api_mod.data.run.BOTD_ents + 1

				local spawned = Isaac.Spawn(
					data.TYPE,
					data.VARIANT,
					data.SUBTYPE,
					entity.Position,
					Vector(0,0),
					entity
				)

				AlphaAPI.addFlag(spawned, AlphaAPI.CustomFlags.NO_TRANSFORM)
				spawned:GetData()["BOTD_spawned"] = data
				api_mod.data.run.BOTD_ents[#api_mod.data.run.BOTD_ents + 1] = data

				spawned.Color = Color(0.8, 1, 0.8, 0.6, 0, 0, 0)
				spawned:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
				spawned:AddEntityFlags(EntityFlag.FLAG_CHARM)

				entity:Remove()
			end
		end

		return true
	end

	function Alphabirth:entityTakeDmgBookOfTheDead(damaged_entity, damage_amount, damage_flag, damage_source, invincible_frames)
		if damaged_entity:IsVulnerableEnemy() and
				damaged_entity.HitPoints - damage_amount <= 0 and
				AlphaAPI.GAME_STATE.PLAYERS[1]:HasCollectible(ITEMS.ACTIVE.BOOK_OF_THE_DEAD.id) and
				AlphaAPI.GAME_STATE.PLAYERS[1]:GetActiveCharge() >= 4 and not
				AlphaAPI.tableContains(BOTD_BLACKLIST, damaged_entity.Type) and not
				damaged_entity:GetData()["BOTD_spawned"] then
			local bones = ENTITIES.BOOK_OF_THE_DEAD_BONES:spawn(
				damaged_entity.Position,
				Vector(0,0),
				damaged_entity
			)

			bones:ToEffect():SetTimeout(10000)
			local data = {
				TYPE = damaged_entity.Type,
				VARIANT = damaged_entity.Variant,
				SUBTYPE = damaged_entity.SubType,
				hp = damaged_entity.MaxHitPoints,
				id = 0
			}

			bones:GetData()["BOTD_data"] = data
		end
	end

	function Alphabirth.handleBookOfTheDead()
		local room = AlphaAPI.GAME_STATE.ROOM
		for i, entity in ipairs(AlphaAPI.entities.all) do
			if entity:GetData()["BOTD_spawned"] then
				if entity:IsDead() then
					for j, entity_data in ipairs(api_mod.data.run.BOTD_ents) do
						if entity_data and entity_data.id == entity:GetData()["BOTD_spawned"].id then
							api_mod.data.run.BOTD_ents[j] = nil
						end
					end

					entity:GetData()["BOTD_spawned"] = nil
				elseif entity.Variant ~= entity:GetData()["BOTD_spawned"].VARIANT or
						entity.Type ~= entity:GetData()["BOTD_spawned"].TYPE or
						entity.SubType ~= entity:GetData()["BOTD_spawned"].SUBTYPE then
					local spawned = Isaac.Spawn(
						entity:GetData()["BOTD_spawned"].TYPE,
						entity:GetData()["BOTD_spawned"].VARIANT,
						entity:GetData()["BOTD_spawned"].SUBTYPE,
						entity.Position,
						entity.Velocity,
						nil
					)

					AlphaAPI.addFlag(spawned, AlphaAPI.CustomFlags.NO_TRANSFORM)
					spawned:GetData()["BOTD_spawned"] = entity:GetData()["BOTD_spawned"]
					spawned.HitPoints = spawned:GetData()["BOTD_spawned"].hp
					spawned.Color = Color(0.8, 1, 0.8, 0.6, 0, 0, 0)
					spawned:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
					spawned:AddEntityFlags(EntityFlag.FLAG_CHARM)
					entity:Remove()
				end
			end
		end

		if room:GetFrameCount() == 1 then
			for i, entity_data in ipairs(api_mod.data.run.BOTD_ents) do
				if entity_data then
					local spawned = Isaac.Spawn(
						entity_data.TYPE,
						entity_data.VARIANT,
						entity_data.SUBTYPE,
						room:FindFreePickupSpawnPosition(AlphaAPI.GAME_STATE.PLAYERS[1].Position, 1, true),
						Vector(0,0),
						nil
					)

					AlphaAPI.addFlag(spawned, AlphaAPI.CustomFlags.NO_TRANSFORM)
					spawned:GetData()["BOTD_spawned"] = entity_data
					spawned.HitPoints = spawned:GetData()["BOTD_spawned"].hp
					spawned.Color = Color(0.8, 1, 0.8, 0.6, 0, 0, 0)
					spawned:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
					spawned:AddEntityFlags(EntityFlag.FLAG_CHARM)
				end
			end
		end
	end


end

-- Passive Item Function Definitions
do
	----------------------------------------
	-- Cologne Logic
	----------------------------------------
	-- Change tear color for Cologne
	function Alphabirth.evaluateCologne(player, cache_flag)
		if cache_flag == CacheFlag.CACHE_TEARCOLOR then
			player.TearColor = Color(
                                    0.867, 0.627, 0.867,    -- RGB
									1,                      -- Alpha
									0, 0, 0                 -- RGB Offset
                                )
		end
	end

	-- Charm nearby enemies
	local cologne_charm_duration = 100
	local cologne_charm_chance = 100
	function Alphabirth.handleCologne(player)
	    local max_charm_distance = 120 * math.max( player.SpriteScale.X, player.SpriteScale.Y )
        for _, entity in ipairs(AlphaAPI.entities.all) do
            if player.Position:Distance(entity.Position) < max_charm_distance
            and entity:IsVulnerableEnemy() then
                local charm_roll = random(1, cologne_charm_chance)
                if charm_roll == 1 then
                    entity:AddCharmed(EntityRef(player), cologne_charm_duration)
                end
            end
        end
	end

	----------------------------------------
	-- Pseudobulbar Affect Logic
	----------------------------------------
	function Alphabirth.handlePseudobulbarAffect(player)
        local direction = player:GetMovementVector():Normalized()
		local data = player:GetData()
		if not data.pseudoCharge then
			data.pseudoCharge = 0
		end

        if(direction:Length() ~= 0.0) then
			data.pseudoCharge = data.pseudoCharge + 1
            if (data.pseudoCharge % (player.MaxFireDelay) == 0) then
				data.pseudoCharge = 0
				shot_velocity = player:GetTearMovementInheritance(direction) * (4 * player.ShotSpeed)
                player:FireTear(player.Position, shot_velocity, false, false, false)
            end
		else
			data.pseudoCharge = 0
        end
	end

    -- Bugged Bombs Pickup Logic
    function Alphabirth.pickupBuggedBombs(player)
        player:AddBombs(5)
    end

	----------------------------------------
	-- Chastity Logic
	----------------------------------------
	function Alphabirth.evaluateChastity(player, cache_flag)
	    if not api_mod.data.run.seenDevil then
	        if(cache_flag == CacheFlag.CACHE_DAMAGE) then
	            player.Damage = (player.Damage + 1.5) * 1.5
	        elseif(cache_flag == CacheFlag.CACHE_SHOTSPEED) then
	            player.ShotSpeed = player.ShotSpeed + 0.4
	        elseif(cache_flag == CacheFlag.CACHE_RANGE) then
	            player.TearHeight = player.TearHeight - 5
	        elseif (cache_flag == CacheFlag.CACHE_SPEED)then
	            player.MoveSpeed = player.MoveSpeed + 0.2
	        end
	    end
	end

	----------------------------------------
	-- Beggar's Cup Logic
	----------------------------------------
	local beggarscup_luck_modifier = 0
	function Alphabirth.evaluateBeggarsCup(player, cache_flag)
        if(cache_flag == CacheFlag.CACHE_LUCK) then
            player.Luck = player.Luck + beggarscup_luck_modifier
        end
	end

	function Alphabirth.handleBeggarsCup(player)
        local coins = player:GetNumCoins()
        local total = coins / 10

		-- Only run if total has changed
		if total ~= beggarscup_previous_total then

			beggarscup_previous_total = total
			local luck_threshold = 5
            local luck_minimum = 0

			beggarscup_luck_modifier = luck_threshold - total

            if beggarscup_luck_modifier < luck_minimum then
                beggarscup_luck_modifier = luck_minimum
            end

			player:AddCacheFlags(CacheFlag.CACHE_LUCK)
            player:EvaluateItems()
		end
	end

	----------------------------------------
	-- Patience Logic
	----------------------------------------
	local patience_damage_modifier = 0
	local patience_damage_modifier_maximum = 0
	function Alphabirth.evaluatePatience(player, cache_flag)
	    if player:HasCollectible(ITEMS.PASSIVE.PATIENCE.id) then
	        if cache_flag ==  CacheFlag.CACHE_DAMAGE and AlphaAPI.GAME_STATE.ROOM:GetFrameCount() > 1 then
	            player.Damage = player.Damage + patience_damage_modifier
	        end
	    end
	end

	function Alphabirth.handlePatience(player)
	    local second_has_passed = AlphaAPI.GAME_STATE.ROOM:GetFrameCount() % 61 == 1
	    local room_is_clear = AlphaAPI.GAME_STATE.ROOM:IsClear()
	    local last_patience_bonus = patience_damage_modifier

	    if player:HasCollectible(ITEMS.PASSIVE.PATIENCE.id)
	        and second_has_passed
	        and not room_is_clear then
	        patience_damage_modifier = math.min(patience_damage_modifier + 0.2, 5.0)
	        if last_patience_bonus ~= patience_damage_modifier then
		        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
		        player:EvaluateItems()
		    end
	    end
	    if AlphaAPI.GAME_STATE.ROOM:GetFrameCount() == 1 then
	        patience_damage_modifier = 0
	    end
	end

	----------------------------------------
	-- Humility Logic
	----------------------------------------
	local humility_chance = 10 -- 1 out of 20
	local humility_application_interval = 10
	local effect_target
	function Alphabirth.handleHumility(player)
        local valid_entities = nil
		local humility_active = false
		local should_find_target = true

        for _, entity in ipairs(AlphaAPI.entities.enemies) do
            if entity:IsActiveEnemy(false) then
                if AlphaAPI.hasFlag(entity, ENTITY_FLAGS.DOUBLE_DAMAGE) then
                    should_find_target = false
                    break
                end

                local enemy = entity:ToNPC()
                if enemy then
                    if not enemy:IsBoss() then
                    	valid_entities = valid_entities or {}
                        valid_entities[#valid_entities + 1] = entity
                    end
                end
            end
        end

        if should_find_target == true and
        	valid_entities ~= nil and
        	#valid_entities > 0 and
        	AlphaAPI.GAME_STATE.GAME:GetFrameCount() % humility_application_interval == 0 and
        	random( 1, math.max( 1, humility_chance - player.Luck ) ) <= 1
        then
            local target_entity_index = 1
            if #valid_entities > 1 then
                target_entity_index = random(#valid_entities)
            end

            local target_entity = valid_entities[target_entity_index]
			effect_target = target_entity
            AlphaAPI.addFlag(target_entity, ENTITY_FLAGS.DOUBLE_DAMAGE)
		end
	end

	local humility_sprite = Sprite()
	humility_sprite:Load("gfx/animations/effects/animation_effect_humility.anm2", true)
	humility_sprite:LoadGraphics()

	function Alphabirth.handleHumilityEffect()
		if effect_target then
			if effect_target:IsDead() then
				effect_target = nil
				return
			end
			humility_sprite:Play("Humility")
			humility_sprite.Offset = effect_target:GetSprite().Offset - Vector(0, effect_target.Size * (effect_target.SizeMulti.Y * 3))
			humility_sprite:RenderLayer(0, AlphaAPI.GAME_STATE.ROOM:WorldToScreenPosition(effect_target.Position))
		end
	end

	----------------------------------------
	-- Kindness Logic
	----------------------------------------
	local kindness_chance = 20 -- 1 out of 100
	local kindness_charm_duration = 100
	local kindness_last_charm_frame = 0
	local kindness_application_interval = 10
	-- If it's been at least 100 frames since the last kindness application, every 10 frames there's a 1 in (10 - Luck) chance an enemy
	-- will have kindness applied
	function Alphabirth.handleKindness(player)
    	local valid_entities = nil
        local should_find_target = false
        local game_frame = AlphaAPI.GAME_STATE.GAME:GetFrameCount()
        if game_frame - kindness_last_charm_frame >= kindness_charm_duration and
        	game_frame % kindness_application_interval == 0 and
        	random( 1, math.max( 1, kindness_chance - player.Luck ) ) <= 1 then
        	should_find_target = true
        end

        for _, entity in ipairs(AlphaAPI.entities.enemies) do
            if entity:HasEntityFlags( EntityFlag.FLAG_CHARM ) and entity:HasMortalDamage() and not entity:IsDead() then
                Isaac.Spawn(
                    EntityType.ENTITY_PICKUP,
                    PickupVariant.PICKUP_HEART,
                    HeartSubType.HEART_HALF,
                    entity.Position,
                    entity.Velocity,
                    entity
                )
            end
            if should_find_target and entity:IsVulnerableEnemy() then
            	valid_entities = valid_entities or {}
                valid_entities[#valid_entities + 1] = entity
            end
        end

        if valid_entities ~= nil and should_find_target and #valid_entities > 0 then
            valid_entities[random(#valid_entities)]:AddCharmed(EntityRef(player), 100)
            kindness_last_charm_frame = game_frame
        end
	end

	----------------------------------------
	-- Old Conctroller Logic
	----------------------------------------
	function Alphabirth.handleOldController()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if api_mod.data.run.controller_respawn > 0 then
			api_mod.data.run.controller_respawn = api_mod.data.run.controller_respawn - 1

			AlphaAPI.callDelayed(function(player)
				player:Revive()
				AlphaAPI.GAME_STATE.LEVEL:ChangeRoom(AlphaAPI.GAME_STATE.LEVEL:GetPreviousRoomIndex())
				player:UseActiveItem(CollectibleType.COLLECTIBLE_CLICKER, false, true, true, false)
				player:UseActiveItem(CollectibleType.COLLECTIBLE_D4, false, true, true, false)
				player:AddSoulHearts(2)
			end, 40, false, player)
		end
	end

	function Alphabirth.initDeathVariable()
		api_mod.data.run.controller_respawn = api_mod.data.run.controller_respawn + 1
	end

	----------------------------------------
	-- Graphics Error Logic
	----------------------------------------
	function Alphabirth.handleGraphicsError(entity, data)
		if AlphaAPI.GAME_STATE.PLAYERS[1]:HasCollectible(ITEMS.PASSIVE.GRAPHICS_ERROR.id) then
			if entity:ToNPC() then
				if math.random(1, math.floor(100 / entity.MaxHitPoints) + 1) == 1 and AlphaAPI.GAME_STATE.PLAYERS[1]:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_GB_BUG) < 5 then
					-- I reaches this point but crashes on the AddCollectibleEffect
					-- AlphaAPI.log("YEP")
					-- AlphaAPI.GAME_STATE.PLAYERS[1]:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_GB_BUG, true)
				end
			end
		end
	end

	----------------------------------------
	-- Satan's Contract Logic
	----------------------------------------
	function Alphabirth.evaluateSatansContract(player, cache_flag)
        if cache_flag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage * 2
        elseif cache_flag == CacheFlag.CACHE_FLYING then
            player.CanFly = true
		elseif cache_flag == CacheFlag.CACHE_TEARCOLOR then
			player.TearColor = Color(
            	0.698, 0.113, 0.113,    -- RGB
				1,                      -- Alpha
            	0, 0, 0                 -- RGB Offset
           )
        end
	end

	-- Brown Eye Logic
	function Alphabirth.handleBrownEye(player)
		-- All poop in the room will shoot at the nearest enemy once every second (61 Frames)
		for i,grid_entity in ipairs(AlphaAPI.entities.grid) do
			if grid_entity then
				local is_poop = grid_entity:ToPoop()
				if (is_poop) then
					local poop = grid_entity
					local closest_entity
					local entity_distance = 100000

					for _, target_entity in ipairs(AlphaAPI.entities.enemies) do
						local distance = target_entity.Position:Distance(poop.Position)
						if distance < entity_distance then
							closest_entity = target_entity
							entity_distance = distance
						end
					end

					if (closest_entity and Isaac:GetFrameCount() % 61 == 0) then
						local difference = (closest_entity.Position - poop.Position):Normalized()
						difference = difference * (13 * player.ShotSpeed)
						player:FireTear(
								poop.Position + (difference * 2),  -- Position
								difference,     -- Velocity
								false,          -- CanBeEye
								false,          -- NoTractorBeam
								false
						)
					end
				end
			end
		end -- End of Brown Eye Logic

		-- Brown Eye sprite replacement
	   --[[ This apparently doesn't work and can crash the game, so on hold for now
	   for i,gridEntity in ipairs(AlphaAPI.entities.grid) do
			local description = gridEntity.Desc
			if description.Type == GridEntityType.GRID_POOP then
				gridEntity.Sprite:ReplaceSpritesheet(0,"gfx/animations/grid_browneyepoop1.png")
				gridEntity.Sprite:LoadGraphics()
			end
		end]]
	end

    -- Handle Emperor's Crown
	function Alphabirth.handleEmperorCrown(level)
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	    local stage = level:GetAbsoluteStage()
	    -- Emperor's Crown Logic
	    -- Activates on all floors except Blue Womb, Chest, Dark Room, Void, and Depths 2
        if stage ~= LevelStage.STAGE3_2             -- Depths 2
                and stage ~= LevelStage.STAGE4_2    -- Womb 2
                and stage ~= LevelStage.STAGE4_3    -- Blue Womb
                and stage ~= LevelStage.STAGE6      -- Dark Room / Chest
                and stage ~= LevelStage.STAGE7 then -- Void
            needs_to_tp_emperor_crown = true
			AlphaAPI.log("HELLO?")
        end
	end

	-----------------------------
	-- Familiar Spawning Logic --
	-----------------------------
	function Alphabirth.pickupDivineWrath(player)
		ENTITIES.DIVINE_WRATH:spawn(player.Position, Vector(0,0), player)
	end

	function Alphabirth.removeDivineWrath()
		for _, entity in ipairs(AlphaAPI.entities.friendly) do
			if AlphaAPI.matchConfig(entity, ENTITIES.DIVINE_WRATH) then
				entity:Remove()
			end
		end
	end

	-------------------------------------------------------------------------------
	---- PACK 2
	-------------------------------------------------------------------------------
	local function vectorFromDirection(direction)
		if direction == Direction.DOWN then
			return Vector(0, 1):Normalized()
		elseif direction == Direction.UP then
			return Vector(0, -1):Normalized()
		elseif direction == Direction.LEFT then
			return Vector(-1, 0):Normalized()
		elseif direction == Direction.RIGHT then
			return Vector(1, 0):Normalized()
		else
			return Vector(0, 0)
		end
	end

	function Alphabirth.handleOwlTotem(player)
		local head_direction = vectorFromDirection(player:GetHeadDirection())
		head_direction = Vector(-head_direction.X, -head_direction.Y)
		local nearest_enemy = AlphaAPI.findNearestEntity(player, AlphaAPI.entities.enemies, nil, nil, nil, 70, player.Position + head_direction * 40)
		if nearest_enemy then
			if player.FrameCount % 30 == 0 then
				local direction_vector = (nearest_enemy.Position - player.Position):Normalized()
				local tear = player:FireTear(player.Position + direction_vector * 8, direction_vector * (player.ShotSpeed * 10), true, true, false)
				tear.Color = Color(0.6, 0, 0.6, 0.5, 0, 0, 0)
				tear.Scale = 1.25
				tear.CollisionDamage = 1.75
				tear.TearFlags = tear.TearFlags | TearFlags.TEAR_KNOCKBACK
				tear.KnockbackMultiplier = 24
				tear.TearFlags = tear.TearFlags | TearFlags.TEAR_HOMING
			end
		end
	end

	function Alphabirth.endorHatRoomClear()
		if random(1, 2) == 1 then
			local player = AlphaAPI.GAME_STATE.PLAYERS[1]
			if player:GetSoulHearts() % 2 ~= 0 then
				player:AddSoulHearts(1)
				sfx_manager:Play(SoundEffect.SOUND_HOLY, 1, 0, false, 1)
			end
		end
	end

	local function GetPlayerHealth(player)
		return player:GetHearts() + player:GetBlackHearts() + player:GetSoulHearts()
	end

	local subconsciousFamiliar
	function Alphabirth.playerTakeDamage(player, amount, flag, source, countdownFrames)
		player = player:ToPlayer()
		if GetPlayerHealth(player) <= amount then
			local redHearts = 0
			local soulHearts = 0
			local blackHearts = 0
			local eternalHearts = 0
			local coins = 0
			for i,friendly in ipairs(AlphaAPI.entities.friendly) do
				if friendly.Type == EntityType.ENTITY_PICKUP and not friendly:GetData().subconsciousCollected then
					local pickup = friendly:ToPickup()
					if pickup.Variant == PickupVariant.PICKUP_HEART then
						if pickup.SubType == HeartSubType.HEART_HALF then
							redHearts = redHearts + 1
						elseif pickup.SubType == HeartSubType.HEART_FULL then
							redHearts = redHearts + 2
						elseif pickup.SubType == HeartSubType.HEART_BLENDED then
							local maxHearts = player:GetMaxHearts()
							local hearts = player:GetHearts()

							local difference = maxHearts - hearts
							if difference > 1 then
								redHearts = redHearts + 2
							elseif difference > 0 then
								redHearts = redHearts + 1
								soulHearts = soulHearts + 1
							else
								soulHearts = soulHearts + 2
							end
						elseif pickup.SubType == HeartSubType.HEART_DOUBLEPACK then
							redHearts = redHearts + 4
						elseif pickup.SubType == HeartSubType.HEART_HALF_SOUL then
							soulHearts = soulHearts + 1
						elseif pickup.SubType == HeartSubType.HEART_SOUL then
							soulHearts = soulHearts + 2
						elseif pickup.SubType == HeartSubType.HEART_BLACK then
							blackHearts = blackHearts + 2
						elseif pickup.SubType == HeartSubType.HEART_ETERNAL then
							eternalHearts = eternalHearts + 1
						end
					elseif pickup.Variant == PickupVariant.PICKUP_COIN then
						if player:GetPlayerType() == PlayerType.PLAYER_KEEPER then
							coins = coins + pickup:GetCoinValue()
						end
					end

					if redHearts > 0 or soulHearts > 0 or blackHearts > 0 or coins > 0 then
						pickup:GetSprite():Play("Collect",true)
						pickup.Timeout = 15
						pickup:GetData().subconsciousCollected = true
						player:AddHearts(redHearts)
						player:AddCoins(coins)
						player:AddSoulHearts(soulHearts)
						player:AddBlackHearts(blackHearts)
						player:AddEternalHearts(eternalHearts)
						if subconsciousFamiliar then
							subconsciousFamiliar:GetSprite():Play("RevivePlayer")
						end
					end
					if GetPlayerHealth(player) > amount then
						break
					end
				end
			end
		end
	end

	function Alphabirth.evaluateSubconscious(player, flag)
		if flag == CacheFlag.CACHE_FAMILIARS then
			player:CheckFamiliar(ENTITIES.SUBCONSCIOUS.variant, 1, rng)
		end
	end

	function Alphabirth.onSubconsciousUpdate(familiar)
		familiar:FollowParent()
		local sprite = familiar:GetSprite()
		if familiar.Velocity:Length() > 1 then
			if not (sprite:IsPlaying("FloatDown") or sprite:IsPlaying("RevivePlayer")) then
				sprite:Play("FloatDown", true)
			end
		end
	end

	function Alphabirth.onSubconsciousInit(familiar)
		subconsciousFamiliar = familiar
		familiar:AddToFollowers()
	end

	---------------------------------------
	-- Brunch "Logic"
	---------------------------------------
	function Alphabirth.applyBrunchCache(player, cache_flag)
		if cache_flag == CacheFlag.CACHE_FIREDELAY then
			if player.MaxFireDelay < 4 then
			elseif player.MaxFireDelay < 6 then
				player.MaxFireDelay = 4
			else
				player.MaxFireDelay = player.MaxFireDelay - 2
			end
		end
	end

	function Alphabirth.pickupBrunch(player)
		player.Color = Color(0,1,0,1,0,0,0)
	end

	---------------------------------------
	-- Cracked Rock Logic
	---------------------------------------
	function Alphabirth:triggerCrackedRockEffect(damaged_entity, damage_amount, damage_flag, damage_source, invincible_frames)
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if AlphaAPI.hasFlag(damage_source, ENTITY_FLAGS.CRACKED_ROCK_SHOT) then
			Isaac.Spawn(
				EntityType.ENTITY_EFFECT,
				EffectVariant.SHOCKWAVE,
				0,            -- Entity Subtype
				damaged_entity.Position,
				Vector(0, 0), -- Velocity
				player
			):ToEffect():SetRadii(5,10)
		end
	end

	---------------------------------------
	-- Tech Alpha Logic
	---------------------------------------
	function Alphabirth.handleTechAlpha()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		for _, entity in ipairs(AlphaAPI.entities.friendly) do
			local entity_will_shoot = nil
			local chance = 3

			if player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then
				chance = chance / 2
			end

			if entity.Type == EntityType.ENTITY_TEAR and not AlphaAPI.hasFlag(entity, ENTITY_FLAGS.TEAR_IGNORE) then
				entity_will_shoot = true
			elseif entity.Type == EntityType.ENTITY_BOMBDROP then
				if player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) then
					if entity:ToBomb().IsFetus then
						entity_will_shoot = true
					end
				end
			elseif entity.Type == EntityType.ENTITY_KNIFE then
				if entity:ToKnife().IsFlying then
					entity_will_shoot = true
				end
			elseif entity.Type == EntityType.ENTITY_LASER then
				if entity:ToLaser():IsCircleLaser() then
					entity_will_shoot = true
				end
			end

			if entity_will_shoot then
				if AlphaAPI.getLuckRNG(chance, 1) then
					local closest_enemy = findClosestEnemy(entity)

					if closest_enemy then
						local direction_vector = closest_enemy.Position - entity.Position
						direction_vector = direction_vector:Normalized() * (player.ShotSpeed * 13)
						if player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then
							player:FireTechXLaser(entity.Position, direction_vector, 30)
						else
							local laser = player:FireTechLaser(entity.Position, 0, direction_vector, false, false):ToLaser()
							laser.DisableFollowParent = true
							laser.Velocity = entity.Velocity
							laser:SetOneHit(true)
						end
					end
				end
			end
		end
	end

	function Alphabirth.applyTechAlphaCache(player, cache_flag)
		if cache_flag == CacheFlag.CACHE_SHOTSPEED then
			player.ShotSpeed = player.ShotSpeed * 0.9
		end
	end

	---------------------------------------
	-- ABYSS Logic
	---------------------------------------
	function Alphabirth:triggerAbyss(damaged_entity, damage_amount, damage_flag, damage_source, invincible_frames)
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if AlphaAPI.hasFlag(damage_source, ENTITY_FLAGS.ABYSS_SHOT) then
			local damaged_npc = damaged_entity:ToNPC()
			if damaged_npc then
				if damaged_entity:IsActiveEnemy(false) and
						damaged_entity:IsVulnerableEnemy() and not
						damaged_npc:IsBoss() then
					local entity_has_void = false
					for _, entity in ipairs(AlphaAPI.entities.enemies) do
						if AlphaAPI.hasFlag(entity, ENTITY_FLAGS.VOID) then
							entity_has_void = true
						end
					end

					if not entity_has_void then
						local effect = Isaac.Spawn(
							EntityType.ENTITY_EFFECT,
							EffectVariant.PULLING_EFFECT,
							0,
							damaged_entity.Position,
							damaged_entity.Velocity,
							damaged_entity
						)
						effect = effect:ToEffect()
						effect:FollowParent(damaged_entity)
						effect:SetTimeout(1000)
						damaged_entity:GetData()["status_timer"] = 180
						AlphaAPI.addFlag(damaged_entity, ENTITY_FLAGS.VOID)
						damaged_entity:AddEntityFlags(EntityFlag.FLAG_FREEZE)
						damaged_entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
					end
				end
				if damaged_entity:IsBoss() then
					damaged_entity:AddFear(EntityRef(player), 180)
				end
			end
		end
	end

	function Alphabirth.handleAbyss()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		for _, entity in ipairs(AlphaAPI.entities.all) do
			local is_void_entity = false
			if AlphaAPI.hasFlag(entity, ENTITY_FLAGS.VOID) then
				is_void_entity = true
				local void_entity = entity
				if colorRawData(entity.Color) ~= colorRawData(Color(0,0,0,1,0,0,0)) then
					entity:GetData()["clr"] = entity.Color
					entity.Color = Color(0,0,0,1,0,0,0)
				end

				for _, entity2 in ipairs(AlphaAPI.entities.all) do
					local entity2_npc = entity2:ToNPC()
					local entity_distance = entity.Position:Distance(entity2.Position)
					if entity2_npc and entity_distance < CONFIG.ABYSS_PULL_RADIUS then
						if entity2:IsActiveEnemy(false) and
								entity2:IsVulnerableEnemy() and not
								entity2_npc:IsBoss() and not
								AlphaAPI.hasFlag(entity2, ENTITY_FLAGS.VOID) then
							local direction_vector = entity.Position - entity2.Position
							direction_vector = direction_vector:Normalized() * 2
							entity2.Velocity = entity2.Velocity + direction_vector
							if entity_distance < CONFIG.ABYSS_PULL_RADIUS * 0.5 then
								entity2:AddFear(EntityRef(void_entity), 1)
							end
						elseif entity2.Type == EntityType.ENTITY_PICKUP and
								entity2.Variant ~= PickupVariant.PICKUP_COLLECTIBLE and
								entity2.Variant ~= PickupVariant.PICKUP_BIGCHEST and
								entity2.Variant ~= PickupVariant.PICKUP_BED then
							local direction_vector = entity.Position - entity2.Position
							direction_vector = direction_vector:Normalized() * 4
							entity2.Velocity = entity2.Velocity + direction_vector
						end
					end
				end

				entity:GetData()["status_timer"] = entity:GetData()["status_timer"] - 1
				if entity:GetData()["status_timer"] == 0 then
					entity.Color = entity:GetData()["clr"]
					AlphaAPI.clearFlag(entity, ENTITY_FLAGS.VOID)
					entity:ClearEntityFlags(EntityFlag.FLAG_FREEZE)
					entity:ClearEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
				end
			end

			if entity.Type == EntityType.ENTITY_EFFECT and
					entity.Variant == EffectVariant.PULLING_EFFECT and not
					AlphaAPI.hasFlag(entity.Parent, ENTITY_FLAGS.VOID) then
				entity:Remove()
			end
		end
	end

	---------------------------------------
	-- Hemophilia Logic
	---------------------------------------

	local explosionRadius = 4
	local tear_cap = 15
	local tear_min = 4
	local tears = {}

	function Alphabirth.triggerHemophilia(entity, data)
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if AlphaAPI.getLuckRNG(25, 2)
		and entity:IsActiveEnemy(true) then
			local numberOfTears = 8 + player.Luck
			local tear_offset = random(-2,2)
			numberOfTears = numberOfTears + tear_offset
			if numberOfTears > tear_cap then
				numberOfTears = tear_cap
			elseif numberOfTears < tear_min then
				numberOfTears = tear_min
			end

			for i=1, numberOfTears do
				tears[i] = player:FireTear(entity.Position,
					Vector(random(-explosionRadius, explosionRadius),
					random(-explosionRadius, explosionRadius)),
					false,
					false,
					true
				)
				tears[i]:ChangeVariant(1)
				tears[i].TearFlags = BitSet128(0)
				tears[i].Scale = 1
				tears[i].Height = -60
				tears[i].FallingSpeed = -4 + random()*-4
				tears[i].FallingAcceleration = random() + 0.5
				AlphaAPI.addFlag(tears[i], ENTITY_FLAGS.TEAR_IGNORE)
			end

			entity:BloodExplode()
			tears = {}
		end
	end

	---------------------------------------
	-- Gloom Skull Logic
	---------------------------------------
	function Alphabirth.applyGloomSkullCache(player, cache_flag)
		if cache_flag == CacheFlag.CACHE_DAMAGE then
			player.Damage = player.Damage + 1.5
			AlphaAPI.GAME_STATE.LEVEL:AddCurse(Isaac.GetCurseIdByName("Curse of Darkness"), false)

			api_mod.data.run.didMaxOutDevilDeal = true
		end
	end

	---------------------------------------
	-- Judas' Fez Logic
	---------------------------------------
	function Alphabirth.applyJudasFezCache(player, cache_flag)
		if cache_flag == CacheFlag.CACHE_DAMAGE then
			player.Damage = player.Damage * 1.35
			if not api_mod.data.run.fezHealthReduced then
				local hearts = player:GetMaxHearts() - 2
				player:AddMaxHearts(hearts * -1)
				player:AddSoulHearts(hearts)
				api_mod.data.run.fezHealthReduced = true
			end
		end
	end

	local combat_rooms_visited = 0
	function Alphabirth.handleJudasFez()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		local room = AlphaAPI.GAME_STATE.ROOM
		if room:IsFirstVisit() and not room:IsClear() and room:GetFrameCount() == 1 then
		combat_rooms_visited = combat_rooms_visited + 1
		if combat_rooms_visited == 3 then
			player:UseCard(Card.CARD_DEVIL)
			combat_rooms_visited = 0
		end
		end
	end


	---------------------------------------
	-- Hot Coals Logic
	---------------------------------------
	local dmg_modifier = 1
	local frame_count = 0
	function Alphabirth.evaluateHotCoals(player, cache_flag)
		if cache_flag == CacheFlag.CACHE_DAMAGE then
			player.Damage = player.Damage * dmg_modifier
		end
	end

	function Alphabirth.handleHotCoals()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		local direction = player:GetMovementVector()
		if (direction:Length() == 0.0) then
			dmg_modifier = 0.8
			frame_count = 0
		else
			dmg_modifier = 1.4
			trail = Isaac.Spawn(EntityType.ENTITY_EFFECT,
				EffectVariant.PLAYER_CREEP_BLACKPOWDER ,
				1,
				player.Position,
				Vector(0, 0),
				player
			):ToEffect()

			trail:SetTimeout(15)
			trail:SetColor(Color(0.5,0,0,0.5,100,100,100), 0, 0, false, false)

			frame_count = frame_count + 1
			if frame_count == 150 then
				Isaac.Spawn(
					EntityType.ENTITY_EFFECT,
					EffectVariant.POOF01,
					0,
					player.Position,
					Vector(0, 0),
					player
				)

				flame = Isaac.Spawn(
					EntityType.ENTITY_EFFECT,
					EffectVariant.RED_CANDLE_FLAME,
					0,
					player.Position,
					Vector(0,0),
					player
				):ToEffect()
				frame_count = 0
			end
		end
		player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
		player:EvaluateItems()
	end

	---------------------------------------
	-- Cyborg Logic
	---------------------------------------
	function Alphabirth.cyborgTrigger()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		player:AddNullCostume(COSTUMES.CYBORG_COSTUME)
		player:AddCacheFlags(CacheFlag.CACHE_ALL)
		player:EvaluateItems()

		AlphaAPI.playOverlay(AlphaAPI.OverlayType.STREAK, STREAK_OVERLAY_TEXT.CYBORG, true)
		playSound(SoundEffect.SOUND_POWERUP_SPEWER, 1, 0, false, 1)
	end

	function Alphabirth.cyborgUpdate()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if player:GetActiveCharge() ~= api_mod.data.run.active_charge then
			player:AddCacheFlags(CacheFlag.CACHE_ALL)
			player:EvaluateItems()
		end


		if AlphaAPI.event.ROOM_CHANGED then
			local room = AlphaAPI.GAME_STATE.ROOM
			local candrop
			if room:IsFirstVisit() and room:IsAmbushActive() == true then
				canDrop = true
			end

			if canDrop then
				canDrop = false
				if AlphaAPI.getLuckRNG(15, 1) == 1 then
					Isaac.Spawn(5,90,0,room:GetCenterPos(), Vector(0,0), player)
				end
			end
		end
	end

	function Alphabirth.applyCyborgCache(player, flag)
		local charge = player:GetActiveCharge()
		if flag == CacheFlag.CACHE_DAMAGE then
			player.Damage = player.Damage + (charge/10)
		elseif flag == CacheFlag.CACHE_LUCK then
			player.Luck = player.Luck + (charge/8)
		elseif flag == CacheFlag.CACHE_SPEED then
			player.MoveSpeed = player.MoveSpeed + (charge/28)
		elseif flag == CacheFlag.CACHE_SHOTSPEED then
			player.ShotSpeed = player.ShotSpeed + (charge/28)
		end
	end

	---------------------------------------
	-- Damned Logic
	---------------------------------------
	function Alphabirth.applyDamnedCache(player, cache_flag)
		if cache_flag == CacheFlag.CACHE_FLYING then
			player.CanFly = true
		end
	end

	function Alphabirth.damnedTrigger()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		player:AddNullCostume(COSTUMES.DAMNED_COSTUME)
		player:AddCacheFlags(CacheFlag.CACHE_FLYING)
		player:EvaluateItems()
		AlphaAPI.playOverlay(AlphaAPI.OverlayType.STREAK, STREAK_OVERLAY_TEXT.DAMNED, true)
		playSound(SoundEffect.SOUND_POWERUP_SPEWER, 1, 0, false, 1)
		local hearts = player:GetMaxHearts()
		local soul_hearts = player:GetSoulHearts()
		player:AddMaxHearts(hearts * -1, true)
		player:AddSoulHearts(soul_hearts * -1)
		player:AddBlackHearts(hearts + soul_hearts)
	end

	---------------------------------------
	-- Birth Control Logic
	---------------------------------------
	function Alphabirth.useBoxOfFriends(player)
		api_mod.data.run.times_used_box_of_friends = api_mod.data.run.times_used_box_of_friends + 1
		player:AddCacheFlags(CacheFlag.CACHE_ALL)
	end

	function Alphabirth.handleBirthControl()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		local frame = AlphaAPI.GAME_STATE.GAME:GetFrameCount()
		if frame % 10 == 0 then
			for _, item in ipairs(birthControl_pool) do
				if player:HasCollectible(item) then
					player:RemoveCollectible(item)
					for _ = 1, 3 do
						local roll = random(1,6)
						if roll == 1 then
							api_mod.data.run.birthControlStats.Damage = api_mod.data.run.birthControlStats.Damage + (random(2, 8) / 10)
						elseif roll == 2 then
							api_mod.data.run.birthControlStats.MoveSpeed = api_mod.data.run.birthControlStats.MoveSpeed + (random(1, 3) / 10)
						elseif roll == 3 then
							api_mod.data.run.birthControlStats.ShotSpeed = api_mod.data.run.birthControlStats.ShotSpeed + (random(1, 3) / 10)
						elseif roll == 4 then
							api_mod.data.run.birthControlStats.Luck = api_mod.data.run.birthControlStats.Luck + (random(10, 20) / 10)
						elseif roll == 5 then
							api_mod.data.run.birthControlStats.Range = api_mod.data.run.birthControlStats.Range + (random(5, 10) / 10)
						elseif roll == 6 then
							api_mod.data.run.birthControlStats.HP = api_mod.data.run.birthControlStats.HP + 2
							player:AddMaxHearts(2, true)
						end
					end
					player:AddCacheFlags(CacheFlag.CACHE_ALL)
					player:EvaluateItems()
				end
			end
		end
	end

	function Alphabirth.applyBirthControlCache(player, flag)
		for i = 1, api_mod.data.run.times_used_box_of_friends do
			if flag == CacheFlag.CACHE_DAMAGE then
				player.Damage = player.Damage + api_mod.data.run.birthControlStats.Damage
			elseif flag == CacheFlag.CACHE_SPEED then
				player.MoveSpeed = player.MoveSpeed + api_mod.data.run.birthControlStats.MoveSpeed
			elseif flag == CacheFlag.CACHE_SHOTSPEED then
				player.ShotSpeed = player.ShotSpeed + api_mod.data.run.birthControlStats.ShotSpeed
			elseif flag == CacheFlag.CACHE_LUCK then
				player.Luck = player.Luck + api_mod.data.run.birthControlStats.Luck
			elseif flag == CacheFlag.CACHE_RANGE then
				player.TearFallingSpeed = player.TearFallingSpeed + api_mod.data.run.birthControlStats.Range
			end
		end
	end

	---------------------------------------
	-- Quill Feather Logic
	---------------------------------------
	local quillFeatherNumberOfTears = 8
	local quill_angle = 30

	function Alphabirth:triggerQuillFeather(dmg_target, dmg_amount, dmg_flags, dmg_source)
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if dmg_source.Entity and AlphaAPI.hasFlag(dmg_source, ENTITY_FLAGS.QUILL_FEATHER_SHOT) then
			Isaac.DebugString("Spawning Quill Feather Tears")
			for i=1, quillFeatherNumberOfTears do
				local direction_vector = dmg_source.Entity.Velocity
				local random_angle = math.rad(random(-math.floor(quill_angle), math.floor(quill_angle)))
				local cos_angle = math.cos(random_angle)
				local sin_angle = math.sin(random_angle)
				local shot_direction = Vector(cos_angle * direction_vector.X - sin_angle * direction_vector.Y,
					sin_angle * direction_vector.X + cos_angle * direction_vector.Y
				)

				local shot_vector = shot_direction * ( (random() * 0.4 + 0.8) * player.ShotSpeed)

				tears[i] = player:FireTear(dmg_source.Position, shot_vector, false, false, true)
				tears[i].Height = -20
				tears[i].TearFlags = tears[i].TearFlags | TearFlags.TEAR_PIERCING
				tears[i]:ChangeVariant(TearVariant.CUPID_BLUE)
				tears[i].Color = Color(0,0,0,1,0,0,0)
				AlphaAPI.addFlag(tears[i], ENTITY_FLAGS.TEAR_IGNORE)
			end

			dmg_source.Entity:Remove()
		end
	end

	---------------------------------------
	-- Hoarder Logic
	---------------------------------------
	local hoarderDamage = 0
	local ratio = 1/25 --1 dmg up for 25 consumables

	function Alphabirth.handleHoarder()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		local consumables = player:GetNumCoins() + player:GetNumBombs() + player:GetNumKeys()
		if consumables * ratio ~= hoarderDamage then
			hoarderDamage = consumables * ratio
			player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
			player:EvaluateItems()
		end
	end

	function Alphabirth.applyHoarderCache(player, cache_flag)
		if cache_flag == CacheFlag.CACHE_DAMAGE then
			player.Damage = player.Damage + hoarderDamage
		end
	end

	---------------------------------------
	-- Possessed Shot Logic
	---------------------------------------
	local POSSESSED_SHOT_BLACKLIST = {
		EntityType.ENTITY_MASK,
		EntityType.ENTITY_HEART
	}


	function Alphabirth.applyPossessedShotCache(player, cache_flag)
		if cache_flag == CacheFlag.CACHE_TEARCOLOR then
			player.TearColor = Color(1,1,0.8,0.7,0,0,0)
		end
	end

	function Alphabirth.triggerPossessedShot(dmg_target, dmg_amount, dmg_flags, dmg_source)
		if dmg_target:IsVulnerableEnemy()
		and not AlphaAPI.hasFlag(dmg_source, ENTITY_FLAGS.TEAR_IGNORE)
		and AlphaAPI.GAME_STATE.ROOM:GetAliveEnemiesCount() > 1 then
			if AlphaAPI.getLuckRNG(6, 2)
			and not dmg_target:ToNPC():IsBoss()
			and not AlphaAPI.tableContains(POSSESSED_SHOT_BLACKLIST, dmg_target.Type) then
				local entities_to_apply = AlphaAPI.findAllRelatives(dmg_target)
				for _, entity in ipairs(entities_to_apply) do
					Isaac.DebugString(entity.Type)
					entity:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
					entity:AddEntityFlags(EntityFlag.FLAG_CHARM)
					entity:GetData()["prevColor"] = entity.Color
					entity.Color = Color(0.8, 1, 0.8, 0.4, 0, 0, 0)
					entity:GetData()["isPossessed"] = 300
				end
			end
		end
	end

	
end

local function handleBlacklight()
	if api_mod.data.run.blacklightUses > 0 and api_mod.data.run.darkenCooldown == 0 then
		AlphaAPI.GAME_STATE.GAME:Darken(3 - (api_mod.data.run.blacklightUses/((timesTillMax)/2)), 200)
		api_mod.data.run.darkenCooldown = 195
	end
	if api_mod.data.run.darkenCooldown > 0 then
		api_mod.data.run.darkenCooldown = api_mod.data.run.darkenCooldown - 1
	end
end

local function handlePossessedShot()
	local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	for i, entity in ipairs(AlphaAPI.entities.enemies) do
		if entity:GetData()["isPossessed"] and entity:GetData()["isPossessed"] > 0 then
			if entity.FrameCount % (player.MaxFireDelay * 6) == 0 then
				local target_entity = findClosestEnemy(entity)
				if target_entity then
					local direction_vector = (target_entity.Position - entity.Position):Normalized()
					local tear_shot = player:FireTear(entity.Position, (direction_vector * (player.ShotSpeed * 8)), false, true, false)
					AlphaAPI.addFlag(tear_shot, ENTITY_FLAGS.TEAR_IGNORE)
				end
			end

			if not AlphaAPI.GAME_STATE.ROOM:IsClear() then
				entity:GetData()["isPossessed"] = entity:GetData()["isPossessed"] - 1
			end

			if entity:GetData()["isPossessed"] == 0 then
				entity:ClearEntityFlags(EntityFlag.FLAG_FRIENDLY)
				entity:ClearEntityFlags(EntityFlag.FLAG_CHARM)
				if entity:GetData()["prevColor"] then
					entity.Color = entity:GetData()["prevColor"]
				end
			end
		end
	end
end

-------------------------------------------------------------------------------
---- RUNE LOGIC
-------------------------------------------------------------------------------

function Alphabirth.triggerNaudizEffect()
    AlphaAPI.playOverlay(AlphaAPI.OverlayType.GIANT_BOOK, "gfx/ui/giantbook/sheet_effect_naudiz.png")
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local coins = player:GetNumCoins()
    local bombs = player:GetNumBombs()
    local keys = player:GetNumKeys()
    local consumables = {coins, bombs, keys}
    local max = 99
    local toGive = 1
    for i=1, #consumables do
        if consumables[i] < max then
            max = consumables[i]
            toGive = i
        end
    end
    if toGive == 1 then
        player:AddCoins(10)
    elseif toGive == 2 then
        player:AddBombs(10)
    elseif toGive == 3 then
        player:AddKeys(10)
    end
    return true
end

function Alphabirth.triggerFehuEffect()
    AlphaAPI.playOverlay(AlphaAPI.OverlayType.GIANT_BOOK, "gfx/ui/giantbook/sheet_effect_fehu.png")
    local room = AlphaAPI.GAME_STATE.ROOM
    for i = 1, room:GetGridSize() do
        if room:IsPositionInRoom(room:GetGridPosition(i), 1) and not room:GetGridEntity(i) and AlphaAPI.getLuckRNG(25, 2) then
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP,
                PickupVariant.PICKUP_COIN,
                0,
                room:GetGridPosition(i),
                Vector(0,0),
                nil
            )
        end
    end
end

function Alphabirth.triggerGeboEffect()
    AlphaAPI.playOverlay(AlphaAPI.OverlayType.GIANT_BOOK, "gfx/ui/giantbook/sheet_effect_gebo.png")
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local room = AlphaAPI.GAME_STATE.ROOM
    local spawn_roll = random(1,100)
    if spawn_roll == 1 then
        Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            PickupVariant.PICKUP_COLLECTIBLE,
            0,
            room:FindFreePickupSpawnPosition(player.Position, 1, false),
            Vector(0,0),
            player
        )
    elseif spawn_roll < 45 then
        Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            PickupVariant.PICKUP_TRINKET,
            0,
            room:FindFreePickupSpawnPosition(player.Position, 1, false),
            Vector(0,0),
            player
        )
    else
        for i = 1, random(1,6) do
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP,
                0,
                0,
                room:FindFreePickupSpawnPosition(player.Position, 1, false),
                Vector(0,0),
                player
            )
        end
    end
end

function Alphabirth.triggerSowiloEffect()
    AlphaAPI.playOverlay(AlphaAPI.OverlayType.GIANT_BOOK, "gfx/ui/giantbook/sheet_effect_sowilo.png")
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    for _, entity in ipairs(AlphaAPI.entities.enemies) do
        entity:AddBurn(EntityRef(player), 180, player.Damage)
    end

    api_mod.data.run.sowiloRooms = api_mod.data.run.sowiloRooms + 3
end

-------------------------------------------------------------------------------
---- ENTITY LOGIC (Familiars, Enemies, Bosses)
-------------------------------------------------------------------------------
---------------------------------------
-- Leech Creep Logic
---------------------------------------
function Alphabirth.onLeechCreepUpdate(creep, data)
    if creep:GetSprite():IsEventTriggered("Shoot") then
        local dart_fly = Isaac.Spawn(
            EntityType.ENTITY_DART_FLY,
            0,
            0,
            creep.Position,
            Vector(0,0),
            creep
        )
        dart_fly:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    end
end

---------------------------------------
-- Oozing Knight Logic
---------------------------------------

function Alphabirth.onOozingKnightUpdate(oozingKnight)
    if oozingKnight:ToNPC().HitPoints > 1 and oozingKnight.FrameCount % 5 == 0 then
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_BLACK, 0, oozingKnight.Position, Vector(0,0), oozingKnight)
    end
end

---------------------------------------
-- 3 Eyed Crawler Logic
---------------------------------------
function Alphabirth.nightCrawlerShoot(night)
    local projectiles = AlphaAPI.fireSpread(0, 1, night.Position, night:GetPlayerTarget().Position, 10, night)
    for _, entity in ipairs(projectiles) do
        entity:GetData().shotPersist = true
    end
end

function Alphabirth.onFourEyedNightCrawlerUpdate(night, data)
    night = night:ToNPC()
    local sprite = night:GetSprite()

    if sprite:IsEventTriggered("Shoot") then -- Attack Frame
        AlphaAPI.callDelayed(Alphabirth.nightCrawlerShoot, 1, false, night)
        AlphaAPI.callDelayed(Alphabirth.nightCrawlerShoot, 5, false, night)
        AlphaAPI.callDelayed(Alphabirth.nightCrawlerShoot, 9, false, night)
    end
end

---------------------------------------
-- Dip Ulcer Logic
---------------------------------------
function Alphabirth.onDipUlcerUpdate(ulcer)
    local ulcer_sprite = ulcer:GetSprite()

    if ulcer_sprite:IsEventTriggered("Shoot") then
        local dip = Isaac.Spawn(
            EntityType.ENTITY_DIP,
            0,
            0,
            ulcer.Position,
            Vector(0, 0),
            ulcer
        )
        dip:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    end
end

function Alphabirth.onDartFlyAppear(entity)
    if entity.SpawnerType == ENTITIES.DIP_ULCER.id
    and entity.SpawnerVariant == ENTITIES.DIP_ULCER.variant then
        entity:Remove()
    end
end

---------------------------------------
-- Round Worm Trio Logic
---------------------------------------
function Alphabirth.onRoundWormTrioUpdate(worm)
    -- Handle Round Worm Trio Logic
    worm = worm:ToNPC()
    local worm_sprite = worm:GetSprite()

    if worm_sprite:IsEventTriggered("Shoot") then -- Attack Frame
        local target = worm:GetPlayerTarget()
        local projectiles = AlphaAPI.fireSpread(15, 3, worm.Position, target.Position, 8, worm)
        for _, entity in ipairs(projectiles) do
            entity:GetData().shotPersist = true
        end
    end
end

---------------------------------------
-- Zygote Logic
---------------------------------------
function Alphabirth.onZygoteUpdate(zygote, data)
    if zygote.FrameCount == 1 then
        if not data.gen then
            data.gen = 1
        end
        data.targetVel = Vector(0, 0)
    end
    local sprite = zygote:GetSprite()
    if sprite:IsPlaying("Walk Neutral") then
        if data.gen < 4 and sprite:GetFrame() == 23 and random(1,4) == 1 then
            sprite:Play("Walk Happy", true)
        end
        if sprite:GetFrame() == 0 then
            data.targetVel = (Isaac.GetRandomPosition() - zygote.Position):Normalized()*3
        end
    elseif sprite:IsPlaying("Walk Happy") then
        if sprite:GetFrame() == 23 then
            sprite:Play("Split", true)
        end
    elseif sprite:IsPlaying("Split") then
        if sprite:IsEventTriggered("Split") then
            local clone = Isaac.Spawn(zygote.Type, zygote.Variant, zygote.SubType, zygote.Position + Vector(-7, 0), Vector(0, 0), zygote)
            clone:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            local cloneSprite = clone:GetSprite()
            cloneSprite:Play("Clone", true)
            local power = 20
            local yVel = random()*power*2 - power
            zygote.Position = zygote.Position + Vector(8, 0)
            zygote.Velocity = zygote.Velocity + Vector(power, yVel)
            clone.Velocity = Vector(-power, -yVel)
            data.gen = data.gen + 1
            clone:GetData().gen = data.gen
            clone.HitPoints = zygote.HitPoints
        end
        if sprite:GetFrame() == 23 then
            data.done = true
            sprite:Play("Walk Neutral", true)
        end
    elseif sprite:IsPlaying("Clone") then
        if sprite:GetFrame() == 23 then
            sprite:Play("Walk Neutral", true)
        end
    else
        sprite:Play("Walk Neutral", true)
    end
    if sprite:IsEventTriggered("Landed") then
        data.targetVel = Vector(0, 0)
        zygote:PlaySound(SoundEffect.SOUND_GOOATTACH0, 1, 0, false, 1)
    end
    zygote.Velocity = zygote.Velocity*0.70 + data.targetVel*0.30
    if zygote.Velocity.X < 0 then
        zygote.FlipX = true
    else
        zygote.FlipX = false
    end
end

---------------------------------------
-- Headless Round Worm Logic
---------------------------------------

function Alphabirth.onHeadlessRoundWormUpdate(entity)
    if entity:ToNPC().State == NpcState.STATE_JUMP then --for roundworms the jump state is going underground
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, entity.Position, Vector(0,0), entity)
    end

    local worm_sprite = entity:GetSprite()

    if worm_sprite:IsEventTriggered("Shoot") then
        local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, entity.Position, Vector(0,0), entity):ToEffect()
        creep:SetTimeout(100)
        creep.Scale = 3
    end
end

---------------------------------------
-- Devil Bony logic
---------------------------------------

function Alphabirth.onDevilBonyUpdate(devilBony, data)
    local bony_sprite = devilBony:GetSprite()

    if bony_sprite:IsEventTriggered("Shoot") then
        local tear = ENTITIES.BONES_TEAR:spawn(
            Vector(devilBony.Position.X + 0, devilBony.Position.Y + 0),
            Vector(0, 0),
            devilBony
        )

        tear = tear:ToTear()

        if devilBony:GetSprite():IsPlaying("AttackDown") then
            tear.Velocity = Vector(0, 4)
            tear.Position = Vector(tear.Position.X, tear.Position.Y + 25)
        elseif devilBony:GetSprite():IsPlaying("AttackUp") then
            tear.Velocity = Vector(0, -4)
            tear.Position = Vector(tear.Position.X, tear.Position.Y - 25)
        elseif devilBony:GetSprite():IsPlaying("AttackHori") and not devilBony:GetSprite().FlipX then
            tear.Velocity = Vector(4, 0)
            tear.Position = Vector(tear.Position.X + 25, tear.Position.Y)
        elseif devilBony:GetSprite():IsPlaying("AttackHori") and devilBony:GetSprite().FlipX then
            tear.Velocity = Vector(-4, 0)
            tear.Position = Vector(tear.Position.X - 25, tear.Position.Y)
        end

        tear.FallingAcceleration = 0.8
        tear.FallingSpeed = -20
        tear.Height = -60
        tear.Scale = 1.5
        tear.TearFlags = tear.TearFlags | TearFlags.TEAR_EXPLOSIVE
    end
end

---------------------------------------
-- Lobotomy logic
---------------------------------------
function Alphabirth.onLobotomyUpdate(lobotomy, data)
    lobotomy = lobotomy:ToNPC()
    if not data.initialized then
        local sprite = lobotomy:GetSprite()
        sprite:PlayOverlay("Head", true)
        data.soundCountdown = 50
        data.targetVel = Vector(0, 0)
        data.died = false
        data.initialized = true
    end

    if random(1, 10) == 1 then
        data.targetVel = (Isaac.GetRandomPosition() - lobotomy.Position):Normalized()*3
    end
    lobotomy.Velocity = lobotomy.Velocity * 0.7 + data.targetVel * 0.3
    lobotomy:AnimWalkFrame("WalkHori", "WalkVert", 0.1)
    if data.soundCountdown < 0 then
        lobotomy:PlaySound(SoundEffect.SOUND_ZOMBIE_WALKER_KID, 0.8, 0, false, 0.9+random()*0.1)
        data.soundCountdown = random(40, 80)
    end
    data.soundCountdown = data.soundCountdown - 1
end

function Alphabirth.onLobotomyDie(lobotomy, data)
    -- using Game::Spawn instead of Isaac.Spawn so
    -- that it never spawns the variant of the brain
    local brain = AlphaAPI.GAME_STATE.GAME:Spawn(32, 0, lobotomy.Position, Vector(0,0), lobotomy, 0, 1):ToNPC()
    local brain_sprite = brain:GetSprite()

    brain_sprite:ReplaceSpritesheet(1, "gfx/animations/enemies/sheet_enemy_lobotomybrain.png")
    brain_sprite:LoadGraphics()

    brain:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    brain.HitPoints = 8
    brain.State = 0
    brain:SetSize(10, Vector(1,1), 12)
    brain.Scale = 0.9
    data.died = true
end

---------------------------------------
-- Devourer Globin logic
---------------------------------------

function Alphabirth.onDevourerGlobinUpdate(devourerGlobin, data)
    devourerGlobin = devourerGlobin:ToNPC()
    if data["full"] then
        devourerGlobin.Velocity = devourerGlobin.Velocity * 1.25
    else
        devourerGlobin.Velocity = devourerGlobin.Velocity * 1.15
    end

    if not data["target"] then
        data["target"] = findClosestEnemy(devourerGlobin)
        if not data["target"] then
            data["target"] = AlphaAPI.GAME_STATE.PLAYERS[1]
        end
    end

    if data["target"]:IsDead() and not data["full"] then
        data["target"] = findClosestEnemy(devourerGlobin)
        if not data["target"] then
            data["target"] = AlphaAPI.GAME_STATE.PLAYERS[1]
        end
    end

    if not devourerGlobin:GetSprite():IsOverlayPlaying("Head") and
            devourerGlobin.State ~= 3 then
        devourerGlobin:GetSprite():PlayOverlay("Head",true)
    elseif devourerGlobin.State == 3 then
        devourerGlobin:GetSprite():RemoveOverlay()
    end

    if devourerGlobin.State ~= 3 then
        devourerGlobin.Target = data["target"]
    end

    for i, entity in ipairs(AlphaAPI.entities.enemies) do
        if devourerGlobin.Position:Distance(entity.Position) <= 40
         and not AlphaAPI.matchConfig(entity, ENTITIES.DEVOURER_GLOBIN)
         and devourerGlobin.FrameCount % 10 == 0 then
            if not data["full"] then
                entity:Kill()
                if random(1, 2) == 1 then
                    data["full"] = true
                    data["target"] = AlphaAPI.GAME_STATE.PLAYERS[1]
                    devourerGlobin:GetSprite():ReplaceSpritesheet(1, "gfx/animations/enemies/sheet_enemy_devourerbloody.png")
                    devourerGlobin:GetSprite():LoadGraphics()
                else

                    data["target"] = findClosestEnemy(devourerGlobin)
                    if not data["target"] then
                        data["target"] = AlphaAPI.GAME_STATE.PLAYERS[1]
                    end
                end

                devourerGlobin.CollisionDamage = devourerGlobin.CollisionDamage + 1
                devourerGlobin:ToNPC().Scale = devourerGlobin:ToNPC().Scale + 0.2
                devourerGlobin:ToNPC().MaxHitPoints = devourerGlobin:ToNPC().MaxHitPoints + 10
                devourerGlobin:ToNPC().HitPoints = devourerGlobin:ToNPC().MaxHitPoints
            else
                data["target"] = AlphaAPI.GAME_STATE.PLAYERS[1]
            end
        end
    end
end

---------------------------------------
-- Kamikaze Fly Logic
---------------------------------------

--Entity Configuration
local kamikazeFlyCooldown = {min = 100, max = 260} --Value between 100 and 260

function Alphabirth.onKamikazeFlyUpdate(kamikazeFly, data)
    --Setup Cooldown
    if not data.shot_delay then
        data.shot_delay = random(kamikazeFlyCooldown.min, kamikazeFlyCooldown.max)
    elseif data.shot_delay > 0 then
        data.shot_delay = data.shot_delay - 1
    end

    if data.shot_delay == 0 then
        data.shot_delay = random(kamikazeFlyCooldown.min, kamikazeFlyCooldown.max)
        data.animation_timer = 28
        kamikazeFly:GetSprite():Play("DropBomb", 1)
    end

    --Attack
    if data.animation_timer then
        if data.animation_timer > 0 then
            kamikazeFly:SetSpriteFrame("DropBomb", 0 + math.abs(data.animation_timer - 28))
            if math.abs(data.animation_timer - 28) == 21 then
                Isaac.Spawn(EntityType.ENTITY_BOMBDROP, 0, 0, kamikazeFly.Position - (Vector(0,-30)), Vector(0,0), kamikazeFly)
            end

            data.animation_timer = data.animation_timer - 1
        else
            data.animation_timer = nil
        end
    end
end

---------------------------------------
-- Blooderfly Logic
---------------------------------------
function Alphabirth.onBlooderflyUpdate(blooderfly)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local data = blooderfly:GetData()

    if data.blooderfly_target == nil then
        blooderfly:FollowParent()
        data.blooderfly_target = findClosestEnemy(blooderfly)
        if data.blooderfly_target then
            local target_data = data.blooderfly_target:GetData()
            if not target_data.isTargetedBlooderfly then
                blooderfly:RemoveFromFollowers()
                target_data.isTargetedBlooderfly = true
            else
                data.blooderfly_target = nil
            end
        end
    else
        local in_range = false
        local dir = data.blooderfly_target.Position - blooderfly.Position
        local hyp = math.sqrt(dir.X * dir.X + dir.Y * dir.Y)
        dir.X = dir.X / hyp
        dir.Y = dir.Y / hyp
        local pos = Vector(0,0)
        pos.X = blooderfly.Position.X + dir.X * 44
        pos.Y = blooderfly.Position.Y + dir.Y * 55

        if data.blooderfly_target.Position:Distance(blooderfly.Position) < 25 then
            in_range = true
            blooderfly:FollowPosition(data.blooderfly_target.Position)
        else
            blooderfly:FollowPosition(pos)
        end
        if data.blooderfly_target:IsDead() then
            data.blooderfly_target = nil
            blooderfly:AddToFollowers()

            if in_range then
                --Hemophilia Effect
                local tears = {}
                for i = 1, 3 do
                    tears[i] = player:FireTear(blooderfly.Position,
                        Vector(random(-4, 4),
                            random(-4, 4)),
                        false,
                        false,
                        true
                    )

                    tears[i]:ChangeVariant(1)
                    tears[i].TearFlags = BitSet128(0)
                    tears[i].Scale = 1
                    tears[i].Height = -30
                    tears[i].FallingSpeed = -4 + random()*-4
                    tears[i].FallingAcceleration = random() + 0.5
                end
                Isaac.Spawn(EntityType.ENTITY_EFFECT,EffectVariant.PLAYER_CREEP_RED,0,blooderfly.Position,Vector(0, 0),player)
                Isaac.Spawn(EntityType.ENTITY_EFFECT,EffectVariant.LARGE_BLOOD_EXPLOSION,0,blooderfly.Position,Vector(0, 0),player)
                tears = {}
                in_range = false
            end

            if AlphaAPI.getLuckRNG(4, 2) then
                Isaac.Spawn(
                    EntityType.ENTITY_PICKUP,
                    PickupVariant.PICKUP_HEART,
                    HeartSubType.HEART_HALF,
                    blooderfly.Position,
                    blooderfly.Velocity,
                    blooderfly
                )
            end
        end
    end
end

function Alphabirth.initBlooderfly(familiar)
    familiar:AddToFollowers()
end

function Alphabirth.evaluateBlooderfly(player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        local amount_to_spawn = player:GetCollectibleNum(ITEMS.PASSIVE.BLOODERFLY.id) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
        player:CheckFamiliar(ENTITIES.BLOODERFLY.variant, amount_to_spawn, rng)
    end
end

---------------------------------------
-- Spirit Eye Logic
---------------------------------------
local homing_tears = {}
local tear_count = 5
local spiritEyeKnife
local spiritEyeLaserRing
local spiritEyeLaserRingDuration = 60
local spirit_angle = 15
local spirit_eye_distance = 25

function Alphabirth.onSpiritEyeUpdate(spirit_eye)
    spirit_eye = spirit_eye:ToFamiliar()
    local frameCount = Isaac.GetFrameCount()
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local player_previous_tearcolor = player.TearColor
    local player_previous_lasercolor = player.LaserColor
    local room = AlphaAPI.GAME_STATE.ROOM

    player.TearColor = Color(0.6, 0, 0.6, 0.5, 0, 0, 0)
    -- Since lasers are bright red by default, I put a very bright blue overlay on top.
    player.LaserColor = Color(1, 0, 0, 1, 0, 0, 255)

    local s = getPlayerSynergies()

    if s == 0 or s == PLAYER_SYNERGY.TECHNOLOGY_2 then
        spirit_eye:MoveDiagonally(0.35)
        for _, entity in ipairs(AlphaAPI.entities.friendly) do
            if entity.Type == EntityType.ENTITY_TEAR and
                    entity.Position:Distance(spirit_eye.Position) <= spirit_eye_distance and not
                    AlphaAPI.hasFlag(entity, ENTITY_FLAGS.TEAR_IGNORE) then
                local direction_vector = entity.Velocity
                local offset = spirit_eye.Position - entity.Position
                entity:Remove()
                local luck_factor = player.Luck
                if luck_factor < 0 then
                    luck_factor = -1
                end

                local random_tear_count = random(tear_count - 3, tear_count + luck_factor)
                if random_tear_count > 15 then
                    random_tear_count = 15
                end

                for i = 1, random_tear_count do
                    local random_angle = math.rad(random(-math.floor(spirit_angle), math.floor(spirit_angle)))
                    local cos_angle = math.cos(random_angle)
                    local sin_angle = math.sin(random_angle)
                    local shot_direction = Vector(cos_angle * direction_vector.X - sin_angle * direction_vector.Y,
                        sin_angle * direction_vector.X + cos_angle * direction_vector.Y
                    )
                    local shot_vector = shot_direction * ( random() * 0.8 + 0.4 )

                    homing_tears[i] = player:FireTear(spirit_eye.Position - offset, shot_vector, false, false, true)
                    homing_tears[i].TearFlags = homing_tears[i].TearFlags | TearFlags.TEAR_HOMING
                    AlphaAPI.addFlag(homing_tears[i], ENTITY_FLAGS.TEAR_IGNORE)
                    homing_tears[i].TearFlags = homing_tears[i].TearFlags & (~(TearFlags.TEAR_QUADSPLIT | TearFlags.TEAR_SPLIT | TearFlags.TEAR_BONE | TearFlags.TEAR_NEEDLE))
                end
            end
        end
    end
    if s & PLAYER_SYNERGY.MOMS_KNIFE > 0 then
        spirit_eye:MoveDiagonally(0.35)
        if not spiritEyeKnife or not spiritEyeKnife:Exists() then
            spiritEyeKnife = player:FireKnife(spirit_eye, 0, false, 0):ToKnife()
        end
        local data = spiritEyeKnife:GetData()
        local playerKnife = player:GetActiveWeaponEntity()
        if playerKnife then
            playerKnife = playerKnife:ToKnife()
            spiritEyeKnife.Rotation = playerKnife.Rotation
            if playerKnife:IsFlying() then
                if data.canShoot then
                    spiritEyeKnife:Shoot(playerKnife.Charge, 100)
                    data.canShoot = false
                end
            else
                data.canShoot = true
            end
        end
    end
    if s & PLAYER_SYNERGY.DR_FETUS > 0 then
        spirit_eye:MoveDiagonally(0.35)
        for _, entity in ipairs(AlphaAPI.entities.friendly) do
            if entity:ToBomb() and entity.Position:Distance(spirit_eye.Position) <= spirit_eye_distance and not AlphaAPI.hasFlag(entity, ENTITY_FLAGS.TEAR_IGNORE) then
                local bomb = entity:ToBomb()
                AlphaAPI.addFlag(bomb, ENTITY_FLAGS.TEAR_IGNORE)
                bomb.ExplosionDamage = bomb.ExplosionDamage * 1.8
                bomb.Color = Color(0.6, 0, 0.6, 0.5, 0, 0, 0)
            end
        end
    end
    if s & PLAYER_SYNERGY.TECH_X > 0 then
        spirit_eye:MoveDiagonally(0.44)
        if not spiritEyeLaserRing or not spiritEyeLaserRing:Exists() and random(1, 80) == 1 then
            spiritEyeLaserRing = player:FireTechXLaser(spirit_eye.Position, spirit_eye.Velocity, 0):ToLaser()
            spiritEyeLaserRing.TearFlags = spiritEyeLaserRing.TearFlags | TearFlags.TEAR_HOMING
            spiritEyeLaserRing:SetTimeout(spiritEyeLaserRingDuration)
        end
        spiritEyeLaserRing.Velocity = spirit_eye.Position+spirit_eye.Velocity*2 - spiritEyeLaserRing.Position
        local maxRadius = 100
        if s & PLAYER_SYNERGY.BRIMSTONE > 0 then
            maxRadius = 60
        end
        spiritEyeLaserRing.Radius = math.abs(math.sin(math.pi*spiritEyeLaserRing.Timeout/spiritEyeLaserRingDuration))*maxRadius
    end
    if s & PLAYER_SYNERGY.TECHNOLOGY > 0 or s & PLAYER_SYNERGY.TECHNOLOGY_2 > 0 then
        spirit_eye:MoveDiagonally(0.44)
        if frameCount % 61 == 0 then
            for i = 1, random(2,5) do
                local direction_vector
                if room:GetAliveEnemiesCount() > 0 then
                    local closest = findClosestEnemy(spirit_eye)
                    if closest ~= nil then
                        direction_vector = Vector.FromAngle((closest.Position - spirit_eye.Position):Normalized():GetAngleDegrees() + random(-90, 90))
                    end
                else
                    direction_vector = RandomVector()
                end

                local laser = player:FireTechLaser(spirit_eye.Position+spirit_eye.Velocity*5, 0, direction_vector, false, false)
                laser.TearFlags = laser.TearFlags | TearFlags.TEAR_HOMING
            end
        end
    end
    if s & PLAYER_SYNERGY.BRIMSTONE > 0 then
        spirit_eye:MoveDiagonally(0.44)
        if frameCount % 60 == 0 and random(1, 2) == 1 and room:GetAliveEnemiesCount() > 0 then
            local laser
            if room:GetAliveEnemiesCount() > 0 then
                local closest = findClosestEnemy(spirit_eye)
                if closest ~= nil then
                    local direction_vector = (closest.Position - spirit_eye.Position):Normalized()
                    laser = player:FireDelayedBrimstone(direction_vector:GetAngleDegrees() + random(-45, 45), spirit_eye)
                end
            else
                laser = player:FireDelayedBrimstone(RandomVector():GetAngleDegrees(), spirit_eye)
            end

            laser.PositionOffset = Vector(0, -20)
            local rotation_roll = random(1, 2)
            local rotation_speed = random(2.0, 3.0)
            if rotation_roll == 1 then
                rotation_speed = -rotation_speed
            end
            laser:SetActiveRotation(0, random(90, 180), rotation_speed, false)
            laser:SetTimeout(24)
        end
    end
    if s & PLAYER_SYNERGY.EPIC_FETUS > 0 then
        spirit_eye:MoveDiagonally(0.5)
        for _, entity in ipairs(AlphaAPI.entities.enemies) do
            if entity.Position:Distance(spirit_eye.Position) <= spirit_eye_distance and random(100) <= 5 then
                entity:AddFreeze(EntityRef(spirit_eye), 100)
            end
        end
    end

    player.TearColor = player_previous_tearcolor
    player.LaserColor = player_previous_lasercolor
    homing_tears = {}
end

function Alphabirth.evaluateSpiritEye(player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        local amount_to_spawn = player:GetCollectibleNum(ITEMS.PASSIVE.SPIRIT_EYE.id) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
        player:CheckFamiliar(ENTITIES.SPIRIT_EYE.variant, amount_to_spawn, rng)
    end
end

---------------------------------------
-- Infested Baby Logic
---------------------------------------
local infestedEntity
local infestedBabySpider
local animationCooldown = 0
local spiderCooldown = 0

function Alphabirth.onInfestedBabyUpdate(familiar)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    familiar = familiar:ToFamiliar()
    familiar.FireCooldown = 999999
    if animationCooldown == 0 then
        familiar:Shoot()
    end

    if infestedBabySpider and infestedBabySpider:IsDead() then
        infestedBabySpider = nil
        spiderCooldown = 25
    end

    local fire_dir = player:GetFireDirection()
    if fire_dir ~= -1 and infestedBabySpider == nil and spiderCooldown == 0 then
        infestedBabySpider = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_SPIDER, 0, familiar.Position, Vector(0,0), familiar)
        if fire_dir == Direction.UP then
            familiar:GetSprite():Play("ShootUp", 1)
        elseif fire_dir == Direction.DOWN then
            familiar:GetSprite():Play("ShootDown", 1)
        elseif fire_dir == Direction.LEFT then
            familiar:GetSprite():Play("ShootSide", 1)
            familiar:GetSprite().FlipX = true
        elseif fire_dir == Direction.RIGHT then
            familiar:GetSprite():Play("ShootSide", 1)
        end

        animationCooldown = 8
        playSound(SoundEffect.SOUND_SPIDER_COUGH, 0.5, 0, false, 1)
    end
    for _, e in ipairs(AlphaAPI.entities.friendly) do
        if e.Parent == familiar and e.Type == EntityType.ENTITY_TEAR then
            e:Remove()
        end
    end
    if animationCooldown > 0 then
        animationCooldown = animationCooldown - 1
    end
    if spiderCooldown > 0 then
        spiderCooldown = spiderCooldown - 1
    end

    familiar:FollowParent()
end

function Alphabirth.onInfestedBabyInit(familiar)
    familiar:AddToFollowers()
end

function Alphabirth.evaluateInfestedBaby(player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        local amount_to_spawn = player:GetCollectibleNum(ITEMS.PASSIVE.INFESTED_BABY.id) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
        player:CheckFamiliar(ENTITIES.INFESTED_BABY.variant, amount_to_spawn, rng)
    end
end


---------------------------------------
-- Post-Update Callback
---------------------------------------

-- Generic Entity Updates
local item_config = Isaac.GetItemConfig()
function Alphabirth.collectibleUpdate(entity)
    local level = AlphaAPI.GAME_STATE.LEVEL
    local room = AlphaAPI.GAME_STATE.ROOM
    if level:GetCurses() & LevelCurse.CURSE_OF_BLIND ~= LevelCurse.CURSE_OF_BLIND then
        if entity.SubType == ITEMS.ACTIVE.CAULDRON.id then
            local sprite = entity:GetSprite()
            if api_mod.data.run.cauldron_points <= 15 and sprite:GetFilename() ~= "gfx/items/collectibles/collectible_cauldron1.png" then
                sprite:ReplaceSpritesheet(1,"gfx/items/collectibles/collectible_cauldron1.png")
                sprite:LoadGraphics()
            elseif api_mod.data.run.cauldron_points < 30 and api_mod.data.run.cauldron_points > 15 and sprite:GetFilename() ~= "gfx/items/collectibles/collectible_cauldron2.png" then
                sprite:ReplaceSpritesheet(1,"gfx/items/collectibles/collectible_cauldron2.png")
                sprite:LoadGraphics()
            elseif sprite:GetFilename() ~= "gfx/items/collectibles/collectible_cauldron3.png" then
                sprite:ReplaceSpritesheet(1,"gfx/items/collectibles/collectible_cauldron3.png")
                sprite:LoadGraphics()
            end
        elseif entity.SubType == ITEMS.ACTIVE.CHALICE_OF_BLOOD.id then
            local sprite = entity:GetSprite()
            if api_mod.data.run.chaliceSouls <= 5 and sprite:GetFilename() ~= "gfx/items/collectibles/collectible_chaliceofblood.png" then
                sprite:ReplaceSpritesheet(1,"gfx/items/collectibles/collectible_chaliceofblood.png")
                sprite:LoadGraphics()
            elseif api_mod.data.run.chaliceSouls <= 10 and sprite:GetFilename() ~= "gfx/items/collectibles/collectible_chaliceofblood2.png" then
                sprite:ReplaceSpritesheet(1,"gfx/items/collectibles/collectible_chaliceofblood2.png")
                sprite:LoadGraphics()
            elseif api_mod.data.run.chaliceSouls < 15 and sprite:GetFilename() ~= "gfx/items/collectibles/collectible_chaliceofblood3.png" then
                sprite:ReplaceSpritesheet(1,"gfx/items/collectibles/collectible_chaliceofblood3.png")
                sprite:LoadGraphics()
            elseif sprite:GetFilename() ~= "gfx/items/collectibles/collectible_chaliceofblood4.png" then
                sprite:ReplaceSpritesheet(1,"gfx/items/collectibles/collectible_chaliceofblood4.png")
                sprite:LoadGraphics()
            end
        end
    elseif entity.SubType == ITEMS.ACTIVE.CAULDRON.id or entity.SubType == ITEMS.ACTIVE.CHALICE_OF_BLOOD.id then
        local sprite = entity:GetSprite()
        if sprite:GetFilename() ~= "gfx/items/collectibles/questionmark.png" then
            sprite:ReplaceSpritesheet(1,"gfx/items/collectibles/questionmark.png")
            sprite:LoadGraphics()
        end
    end

    local challenge = AlphaAPI.GAME_STATE.GAME.Challenge
    if challenge == CHALLENGES.EMPTY then
        if item_config:GetCollectible(entity.SubType).Type ~= ItemType.ITEM_ACTIVE
        and entity.SubType ~= CollectibleType.COLLECTIBLE_BREAKFAST
        and room:GetType() ~= RoomType.ROOM_BOSS
        and not entity:ToPickup().Touched then
            entity:ToPickup():Morph(entity.Type, entity.Variant, 0, true)
        end
    end

    if challenge == CHALLENGES.THE_COLLECTOR then
        if not AlphaAPI.hasFlag(entity, ENTITY_FLAGS.MORPH_TRIED) then
            if not entity.SubType == ITEMS.ACTIVE.CAULDRON.id then
                for i = 1, random(4,8) do
                    Isaac.Spawn(
                        EntityType.ENTITY_PICKUP,
                        0,
                        0,
                        room:FindFreePickupSpawnPosition(entity.Position, 1, false),
                        entity.Velocity,
                        entity
                    )
                end

                entity:Remove()
            end
        end
    end
end

function Alphabirth.onBloodProjectileAppear(entity, data)
    if entity.SpawnerType == ENTITIES.ROUND_WORM_TRIO.id
    and entity.SpawnerVariant == ENTITIES.ROUND_WORM_TRIO.variant then
        if not data.shotPersist then
            entity:Remove()
        end
    elseif entity.SpawnerType == ENTITIES.FOUR_EYED_NIGHT_CRAWLER.id
    and entity.SpawnerVariant == ENTITIES.FOUR_EYED_NIGHT_CRAWLER.variant then
        if not data.shotPersist then
            entity:Remove()
        end
    elseif entity.SpawnerType == ENTITIES.HEADLESS_ROUND_WORM.id
    and entity.SpawnerVariant == ENTITIES.HEADLESS_ROUND_WORM.variant then
        entity:Remove()
    elseif entity.SpawnerType == ENTITIES.LEECH_CREEP.id
    and entity.SpawnerVariant == ENTITIES.LEECH_CREEP.variant then
        entity:Remove()
    elseif entity.SpawnerType == ENTITIES.DEVIL_BONY.id
    and entity.SpawnerVariant == ENTITIES.DEVIL_BONY.variant then
        entity:Remove()
    end
end

local activeCharge
local endor_type = Isaac.GetPlayerTypeByName("Endor")


function Alphabirth:runStarted(fromsave)
	if fromsave then return end
    local challenge = AlphaAPI.GAME_STATE.GAME.Challenge
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local player_type = player:GetPlayerType()

    if challenge == CHALLENGES.EMPTY then
        player:AddCollectible(ITEMS.PASSIVE.ABYSS.id, 12, false)
        player:AddCollectible(CollectibleType.COLLECTIBLE_VOID, 12, false)
    elseif challenge == CHALLENGES.FOR_THE_HOARD then
        player:AddCollectible(CollectibleType.COLLECTIBLE_KEY_BUM, 12, false)
        player:AddCollectible(CollectibleType.COLLECTIBLE_BUM_FRIEND, 12, false)
        player:AddCollectible(ITEMS.PASSIVE.HOARDER.id, 12, false)
    elseif challenge == CHALLENGES.RESTLESS_LEG_SYNDROME then
        player:AddCollectible(ITEMS.PASSIVE.HOT_COALS.id, 12, false)
    elseif challenge == CHALLENGES.THE_COLLECTOR then
        player:AddCollectible(ITEMS.ACTIVE.CAULDRON.id, 12, false)
        player:AddCollectible(ITEMS.PASSIVE.HOARDER.id, 12, false)
    end

    if player:GetPlayerType() == endor_type then
	    player:AddNullCostume(COSTUMES.ENDOR_BODY_COSTUME)
	    player:AddNullCostume(COSTUMES.ENDOR_HEAD_COSTUME)
	    player:AddCollectible(ITEMS.ACTIVE.CAULDRON.id, 0, true)
	    player:AddCollectible(ITEMS.PASSIVE.SPIRIT_EYE.id, 0, true)
	    player:AddMaxHearts(-player:GetMaxHearts())
	    player:AddSoulHearts(4)
	    player:AddEternalHearts(1)
    end

    api_mod.data.run.times_used_box_of_friends = 1
    api_mod.data.run.player_type = nil
    api_mod.data.run.endor_health = 0
    api_mod.data.run.sowiloRooms = 0
    api_mod.data.run.birthControlStats = {
        HP = 0,
        Damage = 0,
        MoveSpeed = 0,
        ShotSpeed = 0,
        Luck = 0,
        Range = 0
    }
    api_mod.data.run.damnedHasRespawned = false
    api_mod.data.run.fezHealthReduced = false
    api_mod.data.run.didMaxOutDevilDeal = false
    api_mod.data.run.BOTD_ents = {}
    api_mod.data.run.blacklightUses = 0
    api_mod.data.run.darkenCooldown = 0
    api_mod.data.run.chaliceSouls = 0
    api_mod.data.run.CHALICE_STATS = {
        DAMAGE = 1,
        SHOTSPEED = 0
    }
    api_mod.data.run.bloodDriveTimesUsed = 0
    api_mod.data.run.cauldron_points = 0
    api_mod.data.run.active_charge = nil



    player:AddCacheFlags(CacheFlag.CACHE_ALL)
    player:EvaluateItems()

    -- Spawn items in starting room
    if CONFIG.START_ROOM_ENABLED then
        Isaac.DebugString("Spawning all new items!")
        local row = 31
        local items_to_spawn = {}
        for key, value in pairs(ITEMS.ACTIVE) do
            items_to_spawn[#items_to_spawn + 1] = value
        end

        for key, value in pairs(ITEMS.PASSIVE) do
            items_to_spawn[#items_to_spawn + 1] = value
        end

        for i, item in ipairs(items_to_spawn) do
            -- Usable grid indexes start at 16 with 16 per "row"
            -- This places them in the second row of the room
            Isaac.DebugString("Spawning: " .. item)
            local position = room:GetGridPosition(i + row)
            if item < 500 then
                Isaac.Spawn(
                            EntityType.ENTITY_PICKUP,       -- Type
                            PickupVariant.PICKUP_TRINKET,   -- Variant
                            item,                           -- Subtype
                            position,                       -- Position
                            Vector(0, 0),                   -- Velocity
                            player                          -- Spawner
                        )
            else
                Isaac.Spawn(EntityType.ENTITY_PICKUP,
                            PickupVariant.PICKUP_COLLECTIBLE,
                            item,
                            position,
                            Vector(0, 0),
                            player
                        )
            end

            if i % 11 == 0 then
                row = row + 19
            end
        end
    end
	api_mod:saveData()
end

function Alphabirth.roomChanged(room)
    -- Max Deal with the Devil chance
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    if api_mod.data.run.didMaxOutDevilDeal == true then
        player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_GOAT_HEAD, false)
    end

    api_mod.data.run.times_used_box_of_friends = 1
    if not api_mod.data.run.sowiloRooms then
        api_mod.data.run.sowiloRooms = 0
    end

    if api_mod.data.run.sowiloRooms > 0 and room:GetAliveEnemiesCount() > 0 then
        for _, entity in ipairs(AlphaAPI.entities.enemies) do
            entity:AddBurn(EntityRef(player), 180, player.Damage)
        end

        api_mod.data.run.sowiloRooms = api_mod.data.run.sowiloRooms - 1
    end
end

-- Aimbot Logic
local aimbotSpeedMod = 3
function Alphabirth.tearUpdate(entity, data)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    if entity.SpawnerType == EntityType.ENTITY_PLAYER then
        if player:HasCollectible(ITEMS.PASSIVE.AIMBOT.id) then
            entity = entity:ToTear()

            local enemy = findClosestEnemy(entity)
            if enemy and enemy.Position:Distance(entity.Position) <= 100 then
                entity.Velocity = Vector(-(entity.Position.X - enemy.Position.X) / aimbotSpeedMod, -(entity.Position.Y - enemy.Position.Y) / aimbotSpeedMod)
                entity.TearFlags = entity.TearFlags | TearFlags.TEAR_SPECTRAL
            end
        end
    elseif entity.SpawnerType == ENTITIES.DEVIL_BONY.type and entity.SpawnerVariant == ENTITIES.DEVIL_BONY.variant then
        if entity.Height > -3 then
            Isaac.Explode(entity.Position, entity, 2)
        end
    end
end

function Alphabirth.laserUpdate(entity, data)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    if player:HasCollectible(ITEMS.PASSIVE.AIMBOT.id) and entity.SpawnerType and entity.SpawnerType == EntityType.ENTITY_PLAYER then
        entity = entity:ToLaser()
        local enemy = findClosestEnemy(entity)
        if enemy then
            if not entity:IsCircleLaser() then
                local direction_angle = (enemy.Position - player.Position):GetAngleDegrees()
                entity.Angle = direction_angle
            else
                if enemy.Position:Distance(e.Position) <= 250 then
                    entity.Velocity = Vector(-(entity.Position.X - enemy.Position.X) / aimbotSpeedMod, -(entity.Position.Y - enemy.Position.Y) / aimbotSpeedMod)
                    entity.Radius = 20
                end
            end
        end
    end
end

function Alphabirth.blackHeartUpdate(entity, data)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    if player_type == endor_type
    and entity.Position:Distance(player.Position) < 30  then
        player:TakeDamage(2, 0, EntityRef(player), 0)
        entity:Remove()
    end
end

function Alphabirth:modUpdate()
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local game = AlphaAPI.GAME_STATE.GAME
    local level = AlphaAPI.GAME_STATE.LEVEL
    local room = AlphaAPI.GAME_STATE.ROOM
    local frame = game:GetFrameCount()
    local player_type = player:GetPlayerType()

    --Endor
    if player_type == endor_type and frame > 1 then
        if player:GetMaxHearts() > api_mod.data.run.endor_health then
            local health_change = player:GetMaxHearts() - api_mod.data.run.endor_health
            player:AddEternalHearts(health_change / 2)
            player:AddMaxHearts(-health_change, false)
            api_mod.data.run.endor_health = api_mod.data.run.endor_health + health_change
        end

        if player:GetMaxHearts() + player:GetEternalHearts() * 2 > api_mod.data.run.endor_health then
            api_mod.data.run.endor_health = api_mod.data.run.endor_health + 2
        end

        if player:GetMaxHearts() + player:GetEternalHearts() * 2 < api_mod.data.run.endor_health then
            local health_change = api_mod.data.run.endor_health - player:GetMaxHearts()
            api_mod.data.run.endor_health = api_mod.data.run.endor_health - health_change
        end

        for i = 1, 24 do
            if player:IsBlackHeart(i) then
                player:RemoveBlackHeart(i)
            end
        end
    end

    if AlphaAPI.event.PLAYER_CHANGED then
        if player_type ~= endor_type then
            player:TryRemoveNullCostume(COSTUMES.ENDOR_BODY_COSTUME)
            player:TryRemoveNullCostume(COSTUMES.ENDOR_HEAD_COSTUME)
        else
            player:AddNullCostume(COSTUMES.ENDOR_BODY_COSTUME)
            player:AddNullCostume(COSTUMES.ENDOR_HEAD_COSTUME)
        end
    end

    -- Restless Leg Syndrome Logic
    if Isaac.GetChallenge() == CHALLENGES.RESTLESS_LEG_SYNDROME then
        if not player:GetData()["StillFrames"] then
            player:GetData()["StillFrames"] = 1
        elseif player.Velocity:Length() < 0.1 then
            player:GetData()["StillFrames"] = player:GetData()["StillFrames"] + 1
            if player:GetData()["StillFrames"] == 41 then
                Isaac.Spawn(
                    EntityType.ENTITY_BOMBDROP,
                    BombVariant.BOMB_TROLL,
                    0,
                    player.Position,
                    player.Velocity,
                    player
                )
                player:GetData()["StillFrames"] = 1
            end
        end
    end

    --Bionic Arm Extra Logic
    local charge = player:GetActiveCharge()
    if player:HasCollectible(ITEMS.ACTIVE.BIONIC_ARM.id) and charge ~= activeCharge then
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:EvaluateItems()
    end

    if api_mod.data.run.bloodDriveTimesUsed > 0 then
        handleBloodDrive()
    end
    handlePossessedShot()
    handleBlacklight()

	Alphabirth.apparitionSpawnCheck()
	Alphabirth.checkEnemyFlames()
	if globalStargazerCountdown > 0 then
		globalStargazerCountdown = globalStargazerCountdown - 1
	end

end

function Alphabirth.cauldronUpdate(sprite)
	if api_mod.data.run.cauldron_points <= 5 then
		sprite:Play("State1",false)
	elseif api_mod.data.run.cauldron_points <= 15 then
		sprite:Play("State2",false)
	elseif api_mod.data.run.cauldron_points < 25 then
		sprite:Play("State3",false)
	else
		sprite:Play("State4",false)
	end
end

function Alphabirth.chaliceOfBloodUpdate(sprite)
	if api_mod.data.run.chaliceSouls <= 5 then
		sprite:Play("State1",false)
	elseif api_mod.data.run.chaliceSouls <= 10 then
		sprite:Play("State2",false)
	elseif api_mod.data.run.chaliceSouls < 15 then
		sprite:Play("State3",false)
	else
		sprite:Play("State4",false)
	end
end

function Alphabirth.activeItemRenderSetup()
	dynamicActiveItems = {

	cauldron = {
			item = ITEMS.ACTIVE.CAULDRON.id,
			sprite = "gfx/animations/animation_collectible_cauldron.anm2",
			functionality = Alphabirth.cauldronUpdate
			},
	chalice = {
			item = ITEMS.ACTIVE.CHALICE_OF_BLOOD.id,
			sprite = "gfx/animations/animation_collectible_chaliceofblood.anm2",
			functionality = Alphabirth.chaliceOfBloodUpdate
			},
	}

	for k,v in pairs(dynamicActiveItems) do
		if itemSprites[k] == nil then
			itemSprites[k] = Sprite()
			itemSprites[k]:Load(v.sprite, true)
		end
	end
end

local visible = Color(1,1,1,1,0,0,0)
local invisible = Color(1,1,1,0,0,0,0)
local spriteTimeout = 30
local spriteFadeSpeed = 0.1
local spriteTimer = 0

function Alphabirth.ActiveItemRender()
	local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	--search through all actives and stop on the first active the player has (assuming player will never have more than 1 active)
	local sprite
	for k,v in pairs(dynamicActiveItems) do
		if player:HasCollectible(v.item) then
			sprite = itemSprites[k]
			v.functionality(sprite) --call the update for the sprite
			break
		end
	end
	if not sprite then return end

	--if the game is paused for more than 30 frames, start fading out, and stop rendering when the alpha is low enough
	local rendering = sprite.Color.A > 0.1 or AlphaAPI.GAME_STATE.GAME:GetFrameCount() < 1
	if AlphaAPI.GAME_STATE.GAME:IsPaused() then
		spriteTimer = spriteTimer + 1
		if spriteTimer >= spriteTimeout and rendering then
			sprite.Color = Color.Lerp(sprite.Color,invisible,spriteFadeSpeed)
		end
	else
		spriteTimer = 0
		sprite.Color = visible
	end

	if rendering then
		sprite:RenderLayer(0, Vector(16, 16))
	end

	Alphabirth.peanutButter60FPS()
end

---------------------------------------
-- Callbacks
---------------------------------------
function Alphabirth:evaluateCache(player, cache_flag)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    if AlphaAPI.GAME_STATE.GAME.Challenge == CHALLENGES.CYBORG and cache_flag == CacheFlag.CACHE_LUCK then
        player.Luck = player.Luck + 15
    end

    if player:GetPlayerType() == endor_type then
        player.CanFly = true
        if cache_flag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage * 0.7
        elseif cache_flag == CacheFlag.CACHE_SPEED then
            player.MoveSpeed = player.MoveSpeed + 0.2
        elseif cache_flag == CacheFlag.CACHE_FIREDELAY then
            if player.MaxFireDelay < 4 then
            elseif player.MaxFireDelay < 7 then
                player.MaxFireDelay = 4
            else
                player.MaxFireDelay = player.MaxFireDelay - 3
            end
        end
    end
end

----------------------------------------------------------------

local function hasTalismanProtection(damage_flags)
	if (
		damage_flags & DamageFlag.DAMAGE_LASER == DamageFlag.DAMAGE_LASER
	) then
		return true
	end
end

local function hasDiligenceProtection(damage_flags, damage_source)
	if (
		damage_flags & DamageFlag.DAMAGE_FIRE == DamageFlag.DAMAGE_FIRE
		or (damage_flags & DamageFlag.DAMAGE_SPIKES == DamageFlag.DAMAGE_SPIKES and AlphaAPI.GAME_STATE.ROOM:GetType() ~= RoomType.ROOM_SACRIFICE)
		or damage_flags & DamageFlag.DAMAGE_EXPLOSION == DamageFlag.DAMAGE_EXPLOSION
		or damage_flags & DamageFlag.DAMAGE_POOP == DamageFlag.DAMAGE_POOP
		or damage_source.Type == EntityType.ENTITY_FIREPLACE
	) then
		return true
	end
end

local function hasWaxedProtection(damage_flags, damage_source)
	if (
		damage_flags & DamageFlag.DAMAGE_FIRE == DamageFlag.DAMAGE_FIRE
		or damage_source.Type == EntityType.ENTITY_FIREPLACE
	) then
		return true
	end
end

local function hasProtection(player, damage_flags, damage_source)
	return
	(AlphaAPI.hasTransformation(TRANSFORMATIONS.WAXED) and hasWaxedProtection(damage_flags, damage_source))
	or (player:HasCollectible(ITEMS.PASSIVE.DILIGENCE.id) and hasDiligenceProtection(damage_flags, damage_source))
	or (player:HasCollectible(ITEMS.PASSIVE.TALISMAN_OF_ABSORPTION.id) and hasTalismanProtection(damage_flags))
end

local direction_list = {
	Vector(-1, 0),  -- West
	Vector(0, 1),   -- North
	Vector(1, 0),   -- East
	Vector(0, -1),  -- South
	Vector(1, 1),   -- North East
	Vector(1, -1),  -- South East
	Vector(-1, 1),  -- North West
	Vector(-1, -1)  -- South West
}

local addictionValidEffects = {
    PillEffect.PILLEFFECT_48HOUR_ENERGY,
    PillEffect.PILLEFFECT_ADDICTED,
    PillEffect.PILLEFFECT_AMNESIA,
    PillEffect.PILLEFFECT_BAD_GAS,
    PillEffect.PILLEFFECT_BALLS_OF_STEEL,
    PillEffect.PILLEFFECT_BOMBS_ARE_KEYS,
    PillEffect.PILLEFFECT_EXPLOSIVE_DIARRHEA,
    PillEffect.PILLEFFECT_FRIENDS_TILL_THE_END,
    PillEffect.PILLEFFECT_FULL_HEALTH,
    PillEffect.PILLEFFECT_GULP,
    PillEffect.PILLEFFECT_HEALTH_UP,
    PillEffect.PILLEFFECT_HORF,
    PillEffect.PILLEFFECT_I_FOUND_PILLS,
    PillEffect.PILLEFFECT_IM_DROWSY,
    PillEffect.PILLEFFECT_IM_EXCITED,
    PillEffect.PILLEFFECT_INFESTED_EXCLAMATION,
    PillEffect.PILLEFFECT_INFESTED_QUESTION,
    PillEffect.PILLEFFECT_LARGER,
    PillEffect.PILLEFFECT_LEMON_PARTY,
    PillEffect.PILLEFFECT_LUCK_DOWN,
    PillEffect.PILLEFFECT_LUCK_UP,
    PillEffect.PILLEFFECT_PRETTY_FLY,
    PillEffect.PILLEFFECT_RANGE_DOWN,
    PillEffect.PILLEFFECT_RANGE_UP,
    PillEffect.PILLEFFECT_SPEED_DOWN,
    PillEffect.PILLEFFECT_SPEED_UP,
    PillEffect.PILLEFFECT_TEARS_DOWN,
    PillEffect.PILLEFFECT_TEARS_UP,
    PillEffect.PILLEFFECT_TELEPILLS,
    PillEffect.PILLEFFECT_PARALYSIS,
    PillEffect.PILLEFFECT_SEE_FOREVER,
    PillEffect.PILLEFFECT_PHEROMONES,
    PillEffect.PILLEFFECT_WIZARD,
    PillEffect.PILLEFFECT_PERCS,
    PillEffect.PILLEFFECT_RELAX,
    PillEffect.PILLEFFECT_QUESTIONMARK,
    PillEffect.PILLEFFECT_SMALLER,
    PillEffect.PILLEFFECT_POWER,
    PillEffect.PILLEFFECT_RETRO_VISION,
    PillEffect.PILLEFFECT_X_LAX,
    PillEffect.PILLEFFECT_SOMETHINGS_WRONG,
    PillEffect.PILLEFFECT_SUNSHINE,
    PillEffect.PILLEFFECT_VURP
}

-- Take Damage Handling
function Alphabirth.entityTakeDamage(entity, damage_amount, damage_flags, damage_source, invincibility_frames)
	if entity.Type == EntityType.ENTITY_PLAYER then
		local player = entity:ToPlayer()
		if player:HasCollectible(ITEMS.PASSIVE.TALISMAN_OF_ABSORPTION.id) and hasTalismanProtection(damage_flags) then
			player:AddHearts(2)
			return false
		end

		if player:HasCollectible(ITEMS.PASSIVE.DILIGENCE.id) then
			ignore_damage = random(1, 5)
			if ignore_damage == 1 then
				return false
			end

			if hasDiligenceProtection(damage_flags, damage_source) then
				return false
			end
		end

		if AlphaAPI.hasTransformation(TRANSFORMATIONS.WAXED) then
			if hasWaxedProtection(damage_flags, damage_source) then
				return false
			end

			local fires_to_spawn = random(2, 5)
			for i = 1, fires_to_spawn do
				Isaac.Spawn(EntityType.ENTITY_EFFECT,
					EffectVariant.RED_CANDLE_FLAME,
					0,
					player.Position,
					(RandomVector() * player.ShotSpeed) * 14,
					player
				)
			end
		end

	    if player:HasCollectible(ITEMS.PASSIVE.SATANS_CONTRACT.id)
		and not hasProtection(player, damage_flags, damage_source) then
	        for i = 1, damage_amount do
	            if player:GetSoulHearts() > 0 then
	                player:AddSoulHearts(-1)
	            else
	                player:AddHearts(-1)
	            end
	        end

	        if player:GetHearts() == 0 and player:GetSoulHearts() == 0 then
	            player:Die()
	        end
	    end

		if player:HasCollectible(ITEMS.PASSIVE.WHITE_CANDLE.id)
		and not hasProtection(player, damage_flags, damage_source) then
			local num_lasers = random(2, 8)
			for i = 1, num_lasers do
				local entities = AlphaAPI.entities.all
				local chance_to_hit = random(1, 2)
				if chance_to_hit == 1 and #entities then
					local vulnerable_entities = {}
					for _, entity in ipairs(entities) do
						if entity:IsVulnerableEnemy() then
							vulnerable_entities[#vulnerable_entities + 1] = entity
						end
					end

					if #vulnerable_entities then
						local entity = nil
						if #vulnerable_entities ~= 1 then
							entity = vulnerable_entities[random(1, #vulnerable_entities)]
						else
							entity = vulnerable_entities[1]
						end

						local position_to_hit = entity.Position
						Isaac.Spawn(
							EntityType.ENTITY_EFFECT,
							EffectVariant.CRACK_THE_SKY,
							0,              -- Subtype
							position_to_hit,
							Vector(0, 0),   -- Velocity
							player          -- Spawner
						)
					end
				else
					Isaac.Spawn(
						EntityType.ENTITY_EFFECT,
						EffectVariant.CRACK_THE_SKY,
						0,              -- Subtype
						AlphaAPI.GAME_STATE.ROOM:GetRandomPosition(0),
						Vector(0, 0),   -- Velocity
						player          -- Spawner
					)
				end
			end
		end

		if player:HasCollectible(ITEMS.PASSIVE.ADDICTED.id)
		and not hasProtection(player, damage_flags, damage_source) then
			local pill_chance = random(1, 6)
			if pill_chance == 1 then
                local chosen_pill = addictionValidEffects[random(1, #addictionValidEffects)]
				player:UsePill(chosen_pill, PillColor.PILL_BLUE_BLUE)
			end
		end

		if player:HasCollectible(ITEMS.PASSIVE.FURNACE.id)
		and not hasProtection(player, damage_flags, damage_source) then
			for _, direction in ipairs(direction_list) do
				Isaac.Spawn(
					EntityType.ENTITY_EFFECT,
					EffectVariant.RED_CANDLE_FLAME,
					0,
					player.Position,
					direction * (10 * player.ShotSpeed),
					player
				)
			end
		end
	else
		if AlphaAPI.hasFlag(entity, ENTITY_FLAGS.DOUBLE_DAMAGE) then
			entity.HitPoints = entity.HitPoints - damage_amount
		end

		if AlphaAPI.hasFlag(damage_source, ENTITY_FLAGS.MUTANT_TEAR)
		and entity:IsActiveEnemy(false) then
			AlphaAPI.clearFlag(damage_source, ENTITY_FLAGS.MUTANT_TEAR)
			local bomb_roll = random(1, 200)
			if bomb_roll == 1 then
				Isaac.Spawn(
					EntityType.ENTITY_BOMBDROP,
					BombVariant.BOMB_SUPERTROLL,
					0,
					entity.Position,
					Vector(0, 0),
					player
				)
			else
				local player = AlphaAPI.GAME_STATE.PLAYERS[1]
				player:FireBomb( entity.Position, Vector(0, 0) )
			end
		end
	end

	local ply = entity:ToPlayer()
	if ply ~= nil then
		Alphabirth.removeFlies()
 	end

    if damage_source ~= nil then

        if entity.Type == EntityType.ENTITY_FIREPLACE then
           return
        end

		if entity:IsVulnerableEnemy() and damage_source.SpawnerVariant == Alphabirth.FlameSpawnerVariant then
			return false
		end

    end
end

-- Entity Handling
do
	-- Mutant Fetus Tear Chance
	function Alphabirth.tearAppear(entity)
		entity = entity:ToTear()
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
		if entity.SpawnerType == EntityType.ENTITY_PLAYER then
			if player:HasCollectible(ITEMS.PASSIVE.MUTANT_FETUS.id) and AlphaAPI.getLuckRNG(7, 3) and entity.Variant ~= TearVariant.CHAOS_CARD then
				AlphaAPI.addFlag(entity, ENTITY_FLAGS.MUTANT_TEAR)
				local tear_sprite = entity:GetSprite()
				tear_sprite:Load("gfx/animations/effects/animation_tears_mutantfetus.anm2", true)
				tear_sprite:Play("Idle")
				tear_sprite:LoadGraphics()
			end
		end

		local tear = entity:ToTear()
		if tear.SpawnerType and tear.SpawnerType == EntityType.ENTITY_PLAYER and tear.Variant ~= TearVariant.CHAOS_CARD then
			local player = AlphaAPI.GAME_STATE.PLAYERS[1]
			local effect_granted
			if AlphaAPI.getLuckRNG(9, 3) then
				local potential_tear_effects = {}
				if player:HasCollectible(ITEMS.PASSIVE.QUILL_FEATHER.id) and not AlphaAPI.hasFlag(tear, ENTITY_FLAGS.TEAR_IGNORE) then
					potential_tear_effects[#potential_tear_effects + 1] = {
						name = "QuillFeather",
						weight = 1
					}
				end
	
				if player:HasCollectible(ITEMS.PASSIVE.CRACKED_ROCK.id) then
					potential_tear_effects[#potential_tear_effects + 1] = {
						name = "CrackedRock",
						weight = 1
					}
				end
	
				if player:HasCollectible(ITEMS.PASSIVE.ABYSS.id) then
					potential_tear_effects[#potential_tear_effects + 1] = {
						name = "Abyss",
						weight = 1
					}
				end
	
				local tear_effect
				if #potential_tear_effects > 0 then
					tear_effect = AlphaAPI.getWeightedRNG(potential_tear_effects)
				end
	
				if tear_effect then
					effect_granted = true
				end
	
				if tear_effect == "QuillFeather" then
					tear.Color = Color(0,0,0,1,0,0,0)
					AlphaAPI.addFlag(tear, ENTITY_FLAGS.QUILL_FEATHER_SHOT)
					tear:ChangeVariant(TearVariant.CUPID_BLUE)
					tear.TearFlags = tear.TearFlags | TearFlags.TEAR_PIERCING
				elseif tear_effect == "CrackedRock" then
					local sprite = tear:GetSprite()
					if sprite:GetFilename() ~= "gfx/animations/effects/animation_tears_crackedrock.anm2" then
						sprite:Load("gfx/animations/effects/animation_tears_crackedrock.anm2", true)
						sprite:Play("Stone3Move", true)
					end
	
					AlphaAPI.addFlag(tear, ENTITY_FLAGS.CRACKED_ROCK_SHOT)
				elseif tear_effect == "Abyss" then
					abyss_sprite = tear:GetSprite()
					abyss_sprite:Load("gfx/animations/effects/animation_tears_abyss.anm2", true)
					abyss_sprite:Play("Idle", true)
					AlphaAPI.addFlag(tear, ENTITY_FLAGS.ABYSS_SHOT)
				end
			end
	
	
			if player:HasCollectible(ITEMS.PASSIVE.HEMOPHILIA.id) and entity.Variant ~= TearVariant.BLOOD and not effect_granted then
				tear:ChangeVariant(TearVariant.BLOOD)
			end
		end
	end

    local bombFlags = {
        "TEAR_BURN",
        "TEAR_SAD_BOMB",
        "TEAR_GLITTER_BOMB",
        "TEAR_BUTT_BOMB",
        "TEAR_STICKY",
        "TEAR_SPECTRAL",
        "TEAR_HOMING",
        "TEAR_POISON"
    }

    function Alphabirth.bugBombsAppear(entity, data)
        local player = AlphaAPI.GAME_STATE.PLAYERS[1]
        if player:HasCollectible(ITEMS.PASSIVE.BUGGED_BOMBS.id) and entity.Variant ~= BombVariant.BOMB_SUPERTROLL and entity.Variant ~= BombVariant.BOMB_TROLL and entity.SpawnerType == EntityType.ENTITY_PLAYER then
            local bomb_sprite = entity:GetSprite()
            if bomb_sprite:GetFilename() ~= "gfx/animations/effects/animation_effect_buggedbombs.anm2" then
                bomb_sprite:Load("gfx/animations/effects/animation_effect_buggedbombs.anm2", true)
                bomb_sprite:Play("Idle")
            end
        end
    end

    function Alphabirth.bugBombsUpdate(entity, data)
        local player = AlphaAPI.GAME_STATE.PLAYERS[1]
        if player:HasCollectible(ITEMS.PASSIVE.BUGGED_BOMBS.id) and entity.Variant ~= BombVariant.BOMB_SUPERTROLL and entity.Variant ~= BombVariant.BOMB_TROLL and entity.SpawnerType == EntityType.ENTITY_PLAYER then
            local bomb = entity:ToBomb()
            if entity.FrameCount % 15 == 0 then
                bomb.Flags = bomb.Flags | TearFlags[bombFlags[random(1, #bombFlags)]]
            end
        end
    end

    local glitch_pickup_animations = {"Battery", "Heart", "Bomb", "Coin", "Key"}

	-- Glitched Consumables
	function Alphabirth.glitchConsumableUpdate(entity, data)
		local consumable_sprite = entity:GetSprite()
		if consumable_sprite:IsEventTriggered("Finish") then
			local to_play = random(1, 5)
			if to_play == 1 and not consumable_sprite:IsPlaying("Battery") then
				consumable_sprite:Play("Battery")
			elseif to_play == 2 and not consumable_sprite:IsPlaying("Heart") then
				consumable_sprite:Play("Heart")
			elseif to_play == 3 and not consumable_sprite:IsPlaying("Bomb") then
				consumable_sprite:Play("Bomb")
			elseif to_play == 4 and not consumable_sprite:IsPlaying("Coin") then
				consumable_sprite:Play("Coin")
			elseif to_play == 5 and not consumable_sprite:IsPlaying("Key") then
				consumable_sprite:Play("Key")
            else                                -- Theis a fallback for if it decides to convert into itself. Most efficient way I could think of at the time.
                if to_play < 5 then
                    consumable_sprite:Play(glitch_pickup_animations[to_play + 1])
                else
                    consumable_sprite:Play(glitch_pickup_animations[to_play - 1])
                end
			end
		end
	end

		function Alphabirth.glitchConsumablePickup(player, pickup)
			local pickup_sprite = pickup:GetSprite()
			if pickup_sprite:IsPlaying("Coin") then
				sfx_manager:Play(SoundEffect.SOUND_PENNYPICKUP, 1.0, 0, false, 1.0)
				player:AddCoins(1)
				return true
			elseif pickup_sprite:IsPlaying("Bomb") then
				sfx_manager:Play(SoundEffect.SOUND_SCAMPER, 1.0, 0, false, 1.0)
				player:AddBombs(1)
				return true
			elseif pickup_sprite:IsPlaying("Key") then
				sfx_manager:Play(SoundEffect.SOUND_KEYPICKUP_GAUNTLET, 1.0, 0, false, 1.0)
				player:AddKeys(1)
				return true
			elseif pickup_sprite:IsPlaying("Heart") then
				if not player:HasFullHearts() then
					sfx_manager:Play(SoundEffect.SOUND_KISS_LIPS1, 1.0, 0, false, 1.0)
					player:AddHearts(2)
					return true
				end
			elseif pickup_sprite:IsPlaying("Battery") then
				if player:NeedsCharge() then
					player:FullCharge()
					return true
				end
			end
		end

	----------------------------------------
	-- Divine Wrath Logic
	----------------------------------------
	local divine_wrath_previous_pos = nil
	function Alphabirth.updateDivineWrath(familiar)
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	    local grid_position = AlphaAPI.GAME_STATE.ROOM:GetGridIndex(familiar.Position)
	    local grid_entity = AlphaAPI.GAME_STATE.ROOM:GetGridEntity(grid_position)

	    player.FireDelay = 1

	    -- Grid entities it touches get hurt every sixth of a second / Excludes secret doors.
	    if grid_entity then
	        local is_door = grid_entity.Desc.Type == GridEntityType.GRID_DOOR
	        local is_wall = grid_entity.Desc.Type == GridEntityType.GRID_WALL

	        if not is_door and not is_wall then
	            grid_entity:Destroy(true)
	        end
	    end

	    if not AlphaAPI.GAME_STATE.ROOM:IsPositionInRoom(familiar.Position, 0) then
	        familiar.Position = divine_wrath_previous_pos
	    end

	    familiar.CollisionDamage = player.Damage * 1.5

	    -- Destroy fireplaces.
	    for _, entity in ipairs(AlphaAPI.entities.all) do
	        if entity.Type == EntityType.ENTITY_FIREPLACE then
	            if familiar.Position:Distance(entity.Position) < 20 then
	                entity:TakeDamage(familiar.CollisionDamage, 0, EntityRef(player), 0)
	            end
	        elseif entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == 51 then
	            if familiar.Position:Distance(entity.Position) < 20 then
	                entity:ToPickup():TryOpenChest()
	            end
	        elseif entity.Type == EntityType.ENTITY_SLOT then
	            if familiar.Position:Distance(entity.Position) < 20 then
	                --Isaac.DebugString("Slot")
	                entity:TakeDamage(familiar.CollisionDamage, DamageFlag.DAMAGE_EXPLOSION, EntityRef(player), 0)
	            end
	        end
	    end

	    local aim_direction = player:GetAimDirection()
	    aim_direction = aim_direction * (player.ShotSpeed)
	    if aim_direction:Length() == 0.0 then
	        -- familiar.Velocity = Vector(0, 0)
	    else
	        familiar:AddVelocity(aim_direction)
	    end

	    divine_wrath_previous_pos = familiar.Position
	end

	function Alphabirth.initDivineWrath(familiar)
	    familiar.GridCollisionClass = GridCollisionClass.COLLISION_NONE
	end

	function Alphabirth.onBombDipDie(entity)
		Isaac.Explode(entity.Position, entity, 1.0)
	end

	----------------------------------------
	-- Stoned Buddy Logic
	----------------------------------------
	local function findTarget(familiar)
		for _, entity in ipairs(AlphaAPI.entities.enemies) do
			if entity.Type ~= 306 then
				local enemy = entity:ToNPC()
				if not enemy:IsBoss() then
					return enemy
				end
			end
		end
		return nil
	end

		local function chooseStonedBuddyTarget(familiar)
			local player = AlphaAPI.GAME_STATE.PLAYERS[1]
			local data = familiar:GetData()

			if not data.pathfinder then
				data.pathfinder = AlphaAPI.getEntityPathfinder(
					familiar,
					0.5,
					25
				)
			end

			if not data.stoned_target then
				familiar:FollowParent()
				data.stoned_target = findTarget(familiar)
			else
				if data.stoned_target:IsDead() then
					data.stoned_target = nil
					familiar:AddToFollowers()
				end

				data.pathfinder:aStarPathing(data.stoned_target.Position,
					3,
					function()
						familiar:FollowPosition(data.stoned_target.Position)
						data.stoned_target:AddFear(EntityRef(familiar),1)
						return
					end
				)
			end
		end

	function Alphabirth.initStonedBuddy(familiar)
        familiar:AddToFollowers()
	    familiar.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
	    familiar.GridCollisionClass = GridCollisionClass.COLLISION_WALLS
	end

	function Alphabirth.updateStonedBuddy(familiar)
	    chooseStonedBuddyTarget(familiar)
		AlphaAPI.animateEntityCardinals(familiar, "WalkUp", "WalkDown", "WalkRight", "WalkLeft", "Idle", false, 0.2)
	end

    function Alphabirth.evaluateStonedBuddy(player, flag)
        if flag == CacheFlag.CACHE_FAMILIARS then
            local amount_to_spawn = player:GetCollectibleNum(ITEMS.PASSIVE.STONED_BUDDY.id) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
            player:CheckFamiliar(ENTITIES.STONED_BUDDY.variant, amount_to_spawn, rng)
        end
    end

	----------------------------------------
	-- Candle Kit Logic
	----------------------------------------
	function Alphabirth.updateCandleKit(candleEnt)
		local player = AlphaAPI.GAME_STATE.PLAYERS[1]
        candleEnt.OrbitDistance = EntityFamiliar.GetOrbitDistance(candleEnt.OrbitLayer)
        local target_position = candleEnt:GetOrbitPosition(player.Position)
        candleEnt.Velocity = target_position - candleEnt.Position
        candleEnt.CollisionDamage = player.Damage * 0.8
        for i, e in ipairs(AlphaAPI.entities.enemies) do
            if  e.Position:Distance(candleEnt.Position) < 55 and random(60) == 1 then
                e:AddBurn(EntityRef(candleEnt), 120, 1.0)
            end
        end
	end

    function Alphabirth.initCandleKit(familiar)
        familiar.OrbitLayer = 4
        familiar:RecalculateOrbitOffset(familiar.OrbitLayer, true)
    end

    function Alphabirth.evaluateCandleKit(player, flag)
        if flag == CacheFlag.CACHE_FAMILIARS then
            local amount_to_spawn = (player:GetCollectibleNum(ITEMS.PASSIVE.CANDLE_KIT.id) * 2) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
            player:CheckFamiliar(ENTITIES.CANDLE_KIT.variant, amount_to_spawn, rng)
        end
    end
end

-------------------------------------------------------------------------------
---- ALASTOR'S RAGE ITEMS AND FAMILIARS
------------------------------------------------------------------------------
-------------------
-- Alastor's Candle
-------------------
function Alphabirth.useAlastorsCandle()
	local player = AlphaAPI.GAME_STATE.PLAYERS[1]

    if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
        return
    end

    local offset
    for i = 1, 2 do
        local flame = FAMILIARS.ALASTORS_FLAME:spawn(player.Position, Vector(0,0), nil)
        local data = flame:GetData()
        if i == 1 then
            offset = math.pi
        elseif i == 2 then
            offset = 0
        end
        data.offset = offset
        data.roomIdx = AlphaAPI.GAME_STATE.LEVEL:GetCurrentRoomIndex()
        data.center_distance = 100
    end

    return true
end

local dist_modifier
function Alphabirth.updateAlastorsFlame(flame)
    local room = AlphaAPI.GAME_STATE.ROOM
    local room_index = AlphaAPI.GAME_STATE.LEVEL:GetCurrentRoomIndex()
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]

    local frame = AlphaAPI.GAME_STATE.GAME:GetFrameCount()
    local data = flame:GetData()

    if data.roomIdx ~= room_index or room:GetFrameCount() == 1 then
        flame:Remove()
    end

    if data.center_distance == 100 then
        dist_modifier = 1
    elseif data.center_distance == 30 then
        dist_modifier = -1
    end

    local off = (frame / 10) + data.offset

    local x_offset = math.cos(off) * data.center_distance
    local y_offset = math.sin(off) * data.center_distance
    flame.Velocity = Vector(player.Position.X + x_offset, player.Position.Y + y_offset) - flame.Position

    data.center_distance = data.center_distance - dist_modifier

    --Add Fear to Nearby entities
    for _, entity in ipairs(AlphaAPI.entities.enemies) do
        if entity.Position:Distance(flame.Position) < 60 and math.random(100) == 1 then
            entity:AddFear(EntityRef(flame), 60)
        end
    end
end

-------------------
-- Isaac's Skull
-------------------
function Alphabirth.useIsaacsSkull()
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    if not api_mod.data.run.godheads then
        api_mod.data.run.godheads = 0
    end

    if not api_mod.data.run.brimstones then
        api_mod.data.run.brimstones = 0
    end

    if random() > 0.5 then
        player:AddCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE, 0, false)
        api_mod.data.run.brimstones = api_mod.data.run.brimstones + 1
    else
        player:AddCollectible(CollectibleType.COLLECTIBLE_GODHEAD, 0, false)
        api_mod.data.run.godheads = api_mod.data.run.godheads + 1
    end

    return true
end

function Alphabirth.isaacsSkullNewRoom()
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    if api_mod.data.run.godheads or api_mod.data.run.brimstones then
        for i = 1, api_mod.data.run.godheads do
            player:RemoveCollectible(CollectibleType.COLLECTIBLE_GODHEAD)
        end

        for i = 1, api_mod.data.run.brimstones do
            player:RemoveCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE)
        end

        api_mod.data.run.godheads = 0
        api_mod.data.run.brimstones = 0
    end
end

-------------------
-- Lil Alastor
-------------------
function Alphabirth.evaluateLilAlastor(player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        local amount_to_spawn = player:GetCollectibleNum(ITEMS.PASSIVE.LIL_ALASTOR.id) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
        player:CheckFamiliar(FAMILIARS.LIL_ALASTOR.variant, amount_to_spawn, modRNG)
    end
end

function Alphabirth.updateLilAlastor(familiar)
    local data = familiar:GetData()
    local sprite = familiar:GetSprite()
	if data.ShootCD then
	    if data.ShootCD > 0 then
			data.ShootCD = data.ShootCD - 1
		end
	else
		data.ShootCD = 0
	end

	familiar:FollowParent()
    local frame = AlphaAPI.GAME_STATE.GAME:GetFrameCount()

	local player = familiar.Player or AlphaAPI.GAME_STATE.PLAYERS[1]
	local fireDelay = 50
	local animationFrames = 4
	if not data.charge then
		data.charge = fireDelay
	end

	if player:GetFireDirection() ~= -1 then
		if data.charge > 0 then
			data.charge = data.charge - 1
		end
		if data.charge == 0 then
			familiar.Color = Color(1, 1, 1, 1, (frame % 30)*2, 1, 1)
		end
		local fireDirAnm
		if player:GetFireDirection() == 0 then
			fireDirAnm = "FloatChargeSide"
			data.direction = "Left"
			sprite.FlipX = true
		elseif player:GetFireDirection() == 1 then
			fireDirAnm = "FloatChargeUp"
			data.direction = "Up"
			sprite.FlipX = false
		elseif player:GetFireDirection() == 2 then
			fireDirAnm = "FloatChargeSide"
			data.direction = "Right"
			sprite.FlipX = false
		elseif player:GetFireDirection() == 3 then
			fireDirAnm = "FloatChargeDown"
			data.direction = "Down"
			sprite.FlipX = false
		end
		sprite:SetFrame(fireDirAnm, math.floor((fireDelay - data.charge)/animationFrames))
	else
		familiar.Color = Color(1, 1, 1, 1, 1, 1, 1)
		if data.charge < 5 then
			if data.direction == "Left" then
				direction = Vector(-1, 0)
			elseif data.direction == "Up" then
				direction = Vector(0, -1)
			elseif data.direction == "Right" then
				direction = Vector(1, 0)
			elseif data.direction == "Down" then
				direction = Vector(0, 1)
			end
			local fire = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.RED_CANDLE_FLAME, 0, familiar.Position, direction*10, familiar)
			fire:ToEffect().CollisionDamage = 7
			if data.direction ~= "Left" or data.direction ~= "Right" then
				sprite:SetFrame("FloatShoot"..data.direction, 0)
			else
				sprite:SetFrame("FloatShootSide", 0)
			end
			data.ShootCD = 10
		else
			sprite:Play("IdleDown")
		end
		data.charge = fireDelay
	end
end

-------------------
-- Faithful Ambivalence
-------------------
function Alphabirth.faithfulAmbivalenceNewRoom(room)
    local type = room:GetType()
    local pool = AlphaAPI.GAME_STATE.GAME:GetItemPool()
    if room:IsFirstVisit() and type == RoomType.ROOM_ANGEL or type == RoomType.ROOM_DEVIL then
        local item
        if type == RoomType.ROOM_ANGEL then
            item = pool:GetCollectible(ItemPoolType.POOL_DEVIL, true, room:GetSpawnSeed())
        else
            item = pool:GetCollectible(ItemPoolType.POOL_ANGEL, true, room:GetSpawnSeed())
        end

        if item then
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP,
                PickupVariant.PICKUP_COLLECTIBLE,
                item,
                room:GetCenterPos() + Vector(0, 10),
                VECTOR_ZERO,
                nil
            )
        end
    end
end

-------------------------------------------------------------------------------
---- PASSIVE ITEM LOGIC
------------------------------------------------------------------------------
-------------------
-- Smart Bombs
-------------------

local DOOR_SLOTS = {
    DoorSlot.LEFT0,
    DoorSlot.UP0,
    DoorSlot.RIGHT0,
    DoorSlot.DOWN0,
    DoorSlot.LEFT1,
    DoorSlot.UP1,
    DoorSlot.RIGHT1,
    DoorSlot.DOWN1
}

function Alphabirth.onPickupBombItem()
    AlphaAPI.GAME_STATE.PLAYERS[1]:AddBombs(5)
end

function Alphabirth.smartBombsEntityAppear(bomb, data)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local room = AlphaAPI.GAME_STATE.ROOM
    if player:HasCollectible(ITEMS.PASSIVE.SMART_BOMBS.id)
    and bomb.SpawnerType == EntityType.ENTITY_PLAYER
    and not AlphaAPI.hasFlag(bomb, ENTITY_FLAGS.SMART_BOMB)
    and room:IsClear() then
        local target_entity
        for i, entity in pairs(AlphaAPI.entities.grid) do
            if entity:ToRock() then --It must be a rock
                local rock_index = entity:GetGridIndex()
                if rock_index == room:GetDungeonRockIdx() then
                    target_entity = entity
                    break
                elseif rock_index == room:GetTintedRockIdx() then
                    target_entity = entity
                    break
                end
            end
        end


        for _, slot in pairs(DOOR_SLOTS) do
            local door = room:GetDoor(slot)
            if door then
                if door:IsRoomType(RoomType.ROOM_SECRET) or door:IsRoomType(RoomType.ROOM_SUPERSECRET) then
                   target_entity = door
                    break
                end
            end
        end

        if target_entity ~= nil then
            if target_entity.State == 2 then
                target_entity = nil
            else
                local smart_bomb = bomb:ToBomb()
                AlphaAPI.addFlag(smart_bomb, ENTITY_FLAGS.SMART_BOMB)
                smart_bomb:GetData().target = target_entity

                --- smart_bomb:ToBomb():SetExplosionCountdown(???)

                local sprite = smart_bomb:GetSprite()
                sprite:Load("gfx/animations/familiars/animation_familiar_smartbombs.anm2", true)
                sprite:Play("LegsAppear", true)
            end
        end
    end
end

function Alphabirth.smartBombsEntityUpdate(entity, data)
    if AlphaAPI.hasFlag(entity, ENTITY_FLAGS.SMART_BOMB) then
        if entity.FrameCount % 20 == 1 then
            local sprite = entity:GetSprite()
            if not sprite:IsPlaying("LegsAppear") and not sprite:IsPlaying("PulseWalk") then
                sprite:Play("PulseWalk", true)
            end
            if sprite:IsPlaying("PulseWalk") then
                local target_position = entity:GetData().target.Position
                local direction_vector = (target_position - entity.Position):Normalized()
                local angle = direction_vector:GetAngleDegrees() + math.random(-50, 50)
                entity.Velocity = entity.Velocity + (Vector.FromAngle(angle) * 6)
            end
        end
    end
end

-------------------
-- Leaking Bombs
-------------------
function Alphabirth.leakingBombsUpdate(bomb, data)
    bomb.Mass = bomb.Mass / 3
    if bomb.SpawnerType == EntityType.ENTITY_PLAYER then
        if bomb.FrameCount % 4 == 0 and bomb.Velocity:Length() > bomb.Size / 4 then
            local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT,
                EffectVariant.PLAYER_CREEP_BLACKPOWDER,
                0,
                bomb.Position,
                Vector(0, 0),
                AlphaAPI.GAME_STATE.PLAYERS[1]
            ):ToEffect()
            creep:SetTimeout(999999)
            creep:GetData().LeakyBomb = bomb
        end
    end
end

function Alphabirth.leakingBombsCreepUpdate(creep, data)
    local leakyBomb = data.LeakyBomb
    if leakyBomb and leakyBomb:GetSprite():IsPlaying("Explode") then
        Isaac.Explode(creep.Position, leakyBomb, leakyBomb.ExplosionDamage)
        creep:SetTimeout(1)
    end
end

function Alphabirth.leakingBombsDamage(entity, amount, flags, source)
    source = AlphaAPI.getEntityFromRef(source)
    if source then
        local data = source:GetData()
        if not data.damagedEntities then
            data.damagedEntities = {entity.Index}
        elseif AlphaAPI.tableContains(data.damagedEntities, entity.Index) then
            return false
        else
            data.damagedEntities[#data.damagedEntities + 1] = entity.Index
        end
    end
end

-------------------
-- Infection
-------------------
local INFECTION_GREEN = Color(0.5, 1, 0.5, 1, 0, 0, 0)
function Alphabirth.infectionTearAppear(tear, data)
    if not AlphaAPI.hasFlag(tear, ENTITY_FLAGS.INFECTION_TEAR) and AlphaAPI.getLuckRNG(CONFIG.INFECTION_TEARCHANCE, 4) then
        tear = tear:ToTear()
        AlphaAPI.addFlag(tear, ENTITY_FLAGS.INFECTION_TEAR)
        tear:SetColor(INFECTION_GREEN, -1, 999, false)
    end
end

local blacklistedInfectionEnts = {
    EntityType.ENTITY_MOM,
    EntityType.ENTITY_MOMS_HEART,
    EntityType.ENTITY_SATAN,
    EntityType.ENTITY_HUSH,
    EntityType.ENTITY_DELIRIUM,
    EntityType.ENTITY_MEGA_SATAN,
    EntityType.ENTITY_MEGA_SATAN_2
}

local function addInfectionToEntity(entity)
    if not AlphaAPI.tableContains(blacklistedInfectionEnts, entity.Type) then
        AlphaAPI.addFlag(entity, ENTITY_FLAGS.INFECTED)
        local infectionEffect = ENTITIES.CRYSTAL:spawn(entity.Position, VECTOR_ZERO, entity):ToEffect()
        infectionEffect.Parent = entity
        infectionEffect:GetData().infected = true
        infectionEffect:GetSprite():Play("Infection", true)
        entity:SetColor(INFECTION_GREEN, -1, 999, false)
    end
end

function Alphabirth.infectionDamage(entity, amount, flags, source)
    source = AlphaAPI.getEntityFromRef(source)
    if source then
        if AlphaAPI.hasFlag(source, ENTITY_FLAGS.INFECTION_TEAR) and not AlphaAPI.hasFlag(entity, ENTITY_FLAGS.INFECTED) and entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
            addInfectionToEntity(entity)
        end

        if source:GetData().infectionCreep then
            if AlphaAPI.getLuckRNG(CONFIG.INFECTION_SPREADCHANCE, 4) and not AlphaAPI.hasFlag(entity, ENTITY_FLAGS.INFECTED) then
                addInfectionToEntity(entity)
            end

            local data = entity:GetData()
            if data.creepDamage then data.creepDamage =  data.creepDamage - 1 end
            if not data.creepDamage then
                entity:TakeDamage(1, 0, EntityRef(AlphaAPI.GAME_STATE.PLAYERS[1]), 1)
                data.creepDamage = 8
            end

            return false
        end
    end
end

function Alphabirth.infectionUpdate(entity, data)
    if AlphaAPI.hasFlag(entity, ENTITY_FLAGS.INFECTED) then
        if entity.FrameCount % 8 == 1 then
            local creep = Isaac.Spawn(
                EntityType.ENTITY_EFFECT,
                EffectVariant.PLAYER_CREEP_GREEN,
                0,
                entity.Position,
                VECTOR_ZERO,
                AlphaAPI.GAME_STATE.PLAYERS[1]
            ):ToEffect()
            creep:SetTimeout(120)
            creep:GetData().infectionCreep = true
        end
    end
end

-------------------
-- Rocket Shoes
-------------------
function Alphabirth.handleRocketShoes()
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    if player:GetLastActionTriggers() & ActionTriggers.ACTIONTRIGGER_MOVED ~= 0 then
        local max_speed = player.MoveSpeed * 5
        if player.Velocity:Length() < max_speed then
            player.Velocity = player:GetMovementVector():Resized(max_speed)
        end
    elseif player:GetLastActionTriggers() & ActionTriggers.ACTIONTRIGGER_MOVED == 0 then
        player.Velocity = player.Velocity * 0
    end
end

function Alphabirth.evaluateRocketShoes(player, cache_flag)
    if cache_flag == CacheFlag.CACHE_SPEED then
        player.MoveSpeed = player.MoveSpeed + 0.1
    end
end

-------------------
-- Miniature Meteor
-------------------

function Alphabirth.onMeteorPickup()
    if not api_mod.data.run.miniatureMeteorBonus then
        api_mod.data.run.miniatureMeteorBonus = 0
    end
end

function Alphabirth.miniatureMeteorAppear(e, _)
    if AlphaAPI.getLuckRNG(10, 3) then
        AlphaAPI.addFlag(e, ENTITY_FLAGS.METEOR_SHOT)
        local tear_sprite = e:GetSprite()
        tear_sprite:Load("gfx/animations/effects/animation_tears_miniaturemeteor.anm2", true)
        local sprite_index = math.floor((api_mod.data.run.miniatureMeteorBonus / 2) + 1)
        if sprite_index > 6 then
            sprite_index = 6
        end
        tear_sprite:Play("Stone"..sprite_index.."Move")
        tear_sprite:LoadGraphics()
        if api_mod.data.run.miniatureMeteorBonus then
            e.CollisionDamage = e.CollisionDamage + (api_mod.data.run.miniatureMeteorBonus * 0.5)
        end
    end
end

function Alphabirth.miniatureMeteorDamage(entity, amount, damage_flag, source, invincibility_frames)
    if AlphaAPI.hasFlag(source.Entity, ENTITY_FLAGS.METEOR_SHOT) and random() < 0.4 then
        Isaac.Spawn(ENTITIES.METEOR_SHARD.id, ENTITIES.METEOR_SHARD.variant, 0, entity.Position, Vector(0,0), AlphaAPI.GAME_STATE.PLAYERS[1])
    end
end

function Alphabirth.meteorShardPickup()
    SFX_MANAGER:Play(SoundEffect.SOUND_SCAMPER, 1, 0, false, 1)
    api_mod.data.run.miniatureMeteorBonus = api_mod.data.run.miniatureMeteorBonus + 1
    return true
end

-------------------
-- Crystallized
-------------------
local crystal_enemies = {}

function Alphabirth.crystalTearDamage(entity, amount, damage_flag, source, invincibility_frames)
    if entity.Type ~= EntityType.ENTITY_PLAYER and entity:IsActiveEnemy() and entity:IsVulnerableEnemy() and not AlphaAPI.hasFlag(entity, ENTITY_FLAGS.CRYSTAL) and source.Type < 10 and not (source.Type == EntityType.ENTITY_FAMILIAR and (source.Variant == FamiliarVariant.BLUE_SPIDER or source.Variant == FamiliarVariant.BLUE_FLY)) then
        AlphaAPI.addFlag(entity, ENTITY_FLAGS.CRYSTAL)
        local crystal = ENTITIES.CRYSTAL:spawn(entity.Position, Vector(0, 0), nil)
        crystal.Parent = entity
        crystal:GetData().crystal = true
        crystal_enemies[#crystal_enemies + 1]  = entity
    end
end

function Alphabirth.crystallizedUpdate()
    for i, ent in ipairs(crystal_enemies) do
        if not ent:Exists() or ent:IsDead() then
            table.remove(crystal_enemies, i)
        end
    end

    local numCrystallized = #crystal_enemies
    local numEnemies = Isaac.CountEnemies()
    if numCrystallized > 2 and ((numCrystallized == numEnemies) or (numCrystallized > numEnemies / 2 and random(1, 1000) == 1)) then
        for _, ent in ipairs(crystal_enemies) do
            AlphaAPI.clearFlag(ent, ENTITY_FLAGS.CRYSTAL)
            ent:GetData().crystalDamage = true
        end

        crystal_enemies = {}
    end
end

function Alphabirth.crystalUpdate(entity, data)
    if entity.Parent then
        if data.crystal and entity.Parent:GetData().crystalDamage then
            local sprite = entity:GetSprite()
            if not sprite:IsPlaying("CrystalBreak") then
                if sprite:IsFinished("CrystalBreak") then
                    SFX_MANAGER:Play(SOUNDS.SHATTER, 1, 0, false, 1)
                    entity.Parent:TakeDamage(AlphaAPI.GAME_STATE.PLAYERS[1].Damage * 2, 0, EntityRef(entity), 0)
                    entity.Parent:GetData().crystalDamage = false
                    entity:Remove()
                    return
                else
                    sprite:Play("CrystalBreak", true)
                end
            end
        end

        if not entity.Parent:Exists() or entity.Parent:IsDead() then
            entity:Remove()
        end

        local target = entity.Parent
        entity:ToEffect().Position = target.Position
        entity:GetSprite().Offset = target:GetSprite().Offset - Vector(0, target.Size * (target.SizeMulti.Y * 3))
        entity.Visible = target.Visible
    else
        entity:Remove()
    end
end

function Alphabirth.evaluateCrystallized(player, flag)
    if flag == CacheFlag.CACHE_TEARCOLOR then
        player.TearColor = Color(0.529, 0.807, 0.98, 0.9, 0, 0, 0)
    end
end

-------------------
-- Paint Palette
-------------------
local TEAR_COLORS = {
    Color(1, 0, 0, 1, 1, 0, 0), -- R
    Color(0, 1, 0, 1, 0, 1, 0), -- G
    Color(0, 0, 1, 1, 0, 0, 1) -- B
}
local COLOR_FLAGS = {
    AlphaAPI.createFlag(), -- R
    AlphaAPI.createFlag(), -- G
    AlphaAPI.createFlag() -- B
}
local tear_index = 1
function Alphabirth.onPaintPaletteTearUpdate(tear, _)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    if tear.SpawnerType ~= EntityType.ENTITY_PLAYER then
        return
    end
    AlphaAPI.addFlag(tear, COLOR_FLAGS[tear_index])
    tear.Color = TEAR_COLORS[tear_index]
    if tear_index == 3 then
        tear_index = 1
    else
        tear_index = tear_index + 1
    end
end

function Alphabirth.paintPaletteDamage(entity, amount, damage_flag, source, invincibility_frames)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    if entity.Type ~= EntityType.ENTITY_PLAYER then
        if AlphaAPI.hasFlag(entity, ENTITY_FLAGS.PAINTED) then
            AlphaAPI.clearFlag(entity, ENTITY_FLAGS.PAINTED)
            return true
        end
        if not AlphaAPI.hasFlag(entity, COLOR_FLAGS[1]) and not AlphaAPI.hasFlag(entity, COLOR_FLAGS[2]) and not AlphaAPI.hasFlag(entity, COLOR_FLAGS[3]) then
            entity.Color = source.Entity.Color
            for _, flag in pairs(COLOR_FLAGS) do
                if AlphaAPI.hasFlag(source.Entity, flag) then
                    AlphaAPI.addFlag(entity, flag)
                end
            end
        else
            for _, flag in pairs(COLOR_FLAGS) do
                if AlphaAPI.hasFlag(entity, flag) then
                    for _, entity2 in pairs(AlphaAPI.entities.enemies) do
                        if AlphaAPI.hasFlag(entity2, flag) and entity2.Index ~= entity.Index then
                            AlphaAPI.addFlag(entity2, ENTITY_FLAGS.PAINTED)
                            entity2:TakeDamage(amount, flag, EntityRef(player), 0)
                        end
                    end
                end
            end
        end
    end
end

local splitFlags = {
    TearFlags.TEAR_SPLIT,
    TearFlags.TEAR_QUADSPLIT,
    TearFlags.TEAR_BONE
}

local allSplitFlag = TearFlags.TEAR_SPLIT | TearFlags.TEAR_QUADSPLIT | TearFlags.TEAR_BONE

-------------------
-- Entropy
-------------------
function Alphabirth.entropyCache(player, flag)
    if flag == CacheFlag.CACHE_FIREDELAY then
        player.MaxFireDelay = player.MaxFireDelay - 3
    end
end

function Alphabirth.entropyNewTear(entity)
    if AlphaAPI.hasFlag(entity, ENTITY_FLAGS.TEAR_IGNORE) then return end
    if not AlphaAPI.hasFlag(entity, ENTITY_FLAGS.ENTROPY_TEAR) and AlphaAPI.getLuckRNG(66, 5) then
        local angle = entity.Velocity:GetAngleDegrees()
        local length = entity.Velocity:Length()
        local oldTear = entity:ToTear()
        local flags = oldTear.TearFlags
        local variance = 10 --in degrees
        local player = AlphaAPI.GAME_STATE.PLAYERS[1]
        local entropyTears = {oldTear}

        for _, flag in ipairs(splitFlags) do
            if flags & flag == flag then
                if AlphaAPI.getLuckRNG(66, 5) then
                    local tear = player:FireTear(player.Position, Vector.FromAngle(angle + random(-variance,variance)):Resized(length), true, false, false)
                    AlphaAPI.addFlag(tear, ENTITY_FLAGS.ENTROPY_TEAR)
                    entropyTears[#entropyTears + 1] = tear
                end
            end
        end

        local tear = player:FireTear(player.Position, Vector.FromAngle(angle + random(-variance,variance)):Resized(length), true, false, false)
        entropyTears[#entropyTears + 1] = tear
        AlphaAPI.addFlag(tear, ENTITY_FLAGS.ENTROPY_TEAR)

        for _, tear in ipairs(entropyTears) do
            tear.TearFlags = tear.TearFlags & ~allSplitFlag
        end
    end
end

-------------------
-- Poly-Mitosis
-------------------
function Alphabirth.polyMitosisNewTear(tear)
    tear = tear:ToTear()
    local data = tear:GetData()
    if not AlphaAPI.hasFlag(tear, ENTITY_FLAGS.POLYMITOSIS_TEAR) and not AlphaAPI.hasFlag(tear, ENTITY_FLAGS.TEAR_IGNORE) then
        AlphaAPI.addFlag(tear, ENTITY_FLAGS.POLYMITOSIS_TEAR)

        data.splitFlags = 0
        for _, flag in ipairs(splitFlags) do
            if tear.TearFlags & flag == flag then
                data.splitFlags = data.splitFlags + 1
            end
        end

        tear.TearFlags = tear.TearFlags & ~allSplitFlag

        tear:GetData().Polymitosis = 0
    end
end

function Alphabirth.polyMitosisUpdate(entity, data)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    if entity.SpawnerType == EntityType.ENTITY_PLAYER and AlphaAPI.hasFlag(entity, ENTITY_FLAGS.POLYMITOSIS_TEAR) and not AlphaAPI.hasFlag(entity, ENTITY_FLAGS.SQUISHY_TEAR) then
        if entity.FrameCount >= 8 and data.Polymitosis < 3 then
            local numTears = 2 + data.splitFlags
            local offset = 60 / (numTears - 1)
            local start = -30
            for i = 1, numTears do
                local tear = player:FireTear(entity.Position, entity.Velocity:Rotated(start + offset * (i - 1)), false, true, true)
                tear.TearFlags = tear.TearFlags & ~allSplitFlag
                AlphaAPI.addFlag(tear, ENTITY_FLAGS.POLYMITOSIS_TEAR)
                AlphaAPI.addFlag(tear, ENTITY_FLAGS.TEAR_IGNORE)
                tear.CollisionDamage = tear.CollisionDamage * 2 / 3
                local newData = tear:GetData()
                newData.Polymitosis = data.Polymitosis + 1
                newData.splitFlags = data.splitFlags
                tear:ToTear().Scale = entity:ToTear().Scale / 1.2
            end

            entity:Remove()
        end
    end
end

function Alphabirth.polyMitosisCache(player, flag)
    if flag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage + 0.5
    elseif flag == CacheFlag.CACHE_FIREDELAY then
        player.MaxFireDelay = player.MaxFireDelay - 1
    end
end

-------------------
-- Shooting Star
-------------------
function Alphabirth.shootingStarNewTear(tear)
    if not AlphaAPI.hasFlag(tear, ENTITY_FLAGS.SHOOTINGSTAR_TEAR) and AlphaAPI.getLuckRNG(35, 4) then
        tear = tear:ToTear()
        AlphaAPI.addFlag(tear, ENTITY_FLAGS.SHOOTINGSTAR_TEAR)
        tear:ChangeVariant(TearVariant.BLUE)
        local tear_sprite = tear:GetSprite()
        tear_sprite:Load("gfx/animations/effects/animation_tears_shootingstar.anm2", true)
        AlphaAPI.resetSpriteScale(tear, "RegularTear")
    end
end

function Alphabirth.shootingStarTearUpdate(tear, data)
    if AlphaAPI.hasFlag(tear, ENTITY_FLAGS.SHOOTINGSTAR_TEAR) then
        tear.SpriteRotation = tear.Velocity:GetAngleDegrees()
    end

    if data.ShootingStar then
        local checkdist = math.huge
        local nearent

        for _,ent in ipairs(AlphaAPI.entities.enemies) do
            local good = true
            for _, struck in ipairs(data.Struck) do
                if AlphaAPI.compareEntities(ent, struck) then
                    good = false
                end
            end

            if good then
                local dist = ent.Position:Distance(tear.Position)
                if dist < checkdist then
                    nearent = ent
                    checkdist = dist
                end
            end
        end

        if nearent then
            local direction = (nearent.Position - tear.Position):Normalized()
            tear.Velocity = (tear.Velocity + direction * 4):Resized(AlphaAPI.GAME_STATE.PLAYERS[1].ShotSpeed * 10)
        end
    end
end

function Alphabirth.shootingStarBounce(entity, damage_amount, damage_flags, damage_source, invincibility_frames)
    local tear = AlphaAPI.getEntityFromRef(damage_source)

    if tear ~= nil and tear:ToTear() then
        local totear = tear:ToTear()

        if AlphaAPI.hasFlag(tear, ENTITY_FLAGS.SHOOTINGSTAR_TEAR) and entity:IsActiveEnemy(false) then
            tear:GetData().ShootingStar = true
            if not tear:GetData().Struck then
                tear:GetData().Struck = {}
            else
                for _, struck in ipairs(tear:GetData().Struck) do
                    if AlphaAPI.compareEntities(entity, struck) then
                        return false
                    end
                end
            end

            tear:GetData().Struck[#tear:GetData().Struck + 1] = entity
            totear.TearFlags = totear.TearFlags | TearFlags.TEAR_PIERCING
            tear.Velocity = (tear.Velocity * -1):Resized(AlphaAPI.GAME_STATE.PLAYERS[1].ShotSpeed * 10)
            totear.FallingSpeed = totear.FallingSpeed - 0.2
        end
    end
end

-------------------
-- Peanut Butter
-------------------

local PEANUTBUTTER_BONDS = {}
local PEANUTBUTTER_COUNTER = 0
local PEANUTBUTTER_COLOR = Color(205.0/255.0, 133.0/255.0, 63.0/255.0, 1, 0, 0, 0)
function Alphabirth.peanutButterCache(player, cache_flag)
    --All these values are susceptible to change. I didn't have numbers to go off
    if cache_flag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage + 0.5
    end
    if cache_flag == CacheFlag.CACHE_SHOTSPEED then
        player.ShotSpeed = player.ShotSpeed - 0.2
    end
end

local frozenFlags = EntityFlag.FLAG_NO_SPRITE_UPDATE | EntityFlag.FLAG_FREEZE

local function isPBOk(entity)
    return entity:IsVulnerableEnemy() and not entity:IsBoss() and not AlphaAPI.hasFlag(entity, ENTITY_FLAGS.PEANUTBUTTER_STICKY) and not AlphaAPI.tableContains(CONFIG.PEANUTBUTTER_BANNEDENTITIES, entity.Type)
end

function Alphabirth.peanutButterNewTear(tear)
    if not AlphaAPI.hasFlag(tear, ENTITY_FLAGS.PEANUTBUTTER_TEAR) and AlphaAPI.getLuckRNG(65, 5) then
        AlphaAPI.addFlag(tear, ENTITY_FLAGS.PEANUTBUTTER_TEAR)
        tear.Color = Color(205.0/255.0, 133.0/255.0, 63.0/255.0, 1, 0, 0, 0)
    end
end

function Alphabirth.peanutButterDamage(entity, damage_amount, damage_flags, damage_source, invincibility_frames)
    local tear = AlphaAPI.getEntityFromRef(damage_source)

    if AlphaAPI.hasFlag(tear, ENTITY_FLAGS.PEANUTBUTTER_TEAR) and isPBOk(entity) then
        for _, bond in pairs(PEANUTBUTTER_BONDS) do
            for _, ent in pairs(bond.ENTITIES) do
                if AlphaAPI.compareEntities(entity, ent) then
                    return
                end
            end
        end

        PEANUTBUTTER_BONDS[tostring(PEANUTBUTTER_COUNTER + 1)] = {
            CONTROLLING = entity,
            ENTITIES = {entity},
            TIMER = 60 * 7
        }
        entity:GetData().bondID = tostring(PEANUTBUTTER_COUNTER + 1)
        PEANUTBUTTER_COUNTER = PEANUTBUTTER_COUNTER + 1
        AlphaAPI.addFlag(entity, ENTITY_FLAGS.PEANUTBUTTER_STICKY)
        entity:SetColor(PEANUTBUTTER_COLOR, 2, 999, false, true)
    end
end

function Alphabirth.peanutButterEntityUpdate(entity, data, sprite)
    if not (entity:IsVulnerableEnemy() and entity:IsActiveEnemy(false)) then return end

    if AlphaAPI.hasFlag(entity, ENTITY_FLAGS.PEANUTBUTTER_STICKY) then
        entity:SetColor(PEANUTBUTTER_COLOR, 1, 999, false, true)
        if entity.FrameCount % 2 == 0 then
            local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT,
                EffectVariant.PLAYER_CREEP_WHITE,
                0,
                entity.Position,
                Vector(0, 0),
                AlphaAPI.GAME_STATE.PLAYERS[1]
            )
            creep:GetSprite():Load("gfx/animations/effects/animation_effect_peanutbuttercreep.anm2", true)
            creep:ToEffect():SetTimeout(10)
            creep:ToEffect().Scale = creep:ToEffect().Scale * 0.15
        end

        local inBond = false
        if data.bondID then
            for _, ent in pairs(PEANUTBUTTER_BONDS[data.bondID].ENTITIES) do
                if AlphaAPI.compareEntities(entity, ent) then
                    inBond = true
                end
            end
        end

        if not inBond then
            AlphaAPI.clearFlag(entity, ENTITY_FLAGS.PEANUTBUTTER_STICKY)
            entity:ClearEntityFlags(frozenFlags)
            data.bondID = nil
        end

        -- Code for merging of bonds
        for bondID, bond in pairs(PEANUTBUTTER_BONDS) do
            if bondID ~= data.bondID then
                local bond2 = PEANUTBUTTER_BONDS[data.bondID]
                for _, ent in pairs(bond.ENTITIES) do
                    if ent.Position:Distance(entity.Position) < ent.Size + entity.Size then
                        local chosenBond = random(1, 2)
                        if chosenBond == 1 then
                            for _, ent2 in pairs(bond.ENTITIES) do
                                bond2.ENTITIES[#bond2.ENTITIES + 1] = ent2
                                ent2:GetData().peanutButterOffset = ent2.Position - bond2.CONTROLLING.Position
                                ent2:GetData().bondID = data.bondID
                                bond2.TIMER = bond2.TIMER + bond.TIMER
                            end

                            PEANUTBUTTER_BONDS[bondID] = nil
                        else
                            for _, ent2 in pairs(bond2.ENTITIES) do
                                bond.ENTITIES[#bond.ENTITIES + 1] = ent2
                                ent2:GetData().peanutButterOffset = ent2.Position - bond.CONTROLLING.Position
                                ent2:GetData().bondID = bondID
                                bond.TIMER = bond.TIMER + bond2.TIMER
                            end

                            PEANUTBUTTER_BONDS[data.bondID] = nil
                        end

                        break
                    end
                end
            end
        end
    else
        -- Code to detect if enemies are within range of a peanut butter bonded entity and if so add them to the bond
        for bondID, bond in pairs(PEANUTBUTTER_BONDS) do
            for _, ent in pairs(bond.ENTITIES) do
                if ent.Position:Distance(entity.Position) < ent.Size + entity.Size and isPBOk(entity) then
                    AlphaAPI.addFlag(entity, ENTITY_FLAGS.PEANUTBUTTER_STICKY)
                    data.peanutButterOffset = entity.Position - bond.CONTROLLING.Position
                    data.bondID = bondID
                    bond.ENTITIES[#bond.ENTITIES + 1] = entity
                    bond.TIMER = bond.TIMER + (60 * 7)
                    entity:AddEntityFlags(frozenFlags)
                    break
                end
            end
        end
    end
end

function Alphabirth.peanutButter60FPS()
    for key, bond in pairs(PEANUTBUTTER_BONDS) do
        if not bond.CONTROLLING:Exists() or bond.CONTROLLING:IsDead() then
            local controllerFound = false
            for _, entity in pairs(bond.ENTITIES) do
                if entity:Exists() and not entity:IsDead() then
                    controllerFound = true
                    bond.CONTROLLING = entity
                    entity:ClearEntityFlags(frozenFlags)
                    for _, ent2 in pairs(bond.ENTITIES) do
                        ent2:GetData().peanutButterOffset = ent2.Position - bond.CONTROLLING.Position
                    end
                    break
                end
            end

            if not controllerFound then
                bond[key] = nil
            end
        end

        for key2, entity in pairs(bond.ENTITIES) do
            if entity:Exists() and not entity:IsDead() then
                if not AlphaAPI.compareEntities(bond.CONTROLLING, entity) then
                    local data = entity:GetData()
                    entity:AddEntityFlags(frozenFlags)
                    entity.Velocity = Vector(0, 0)
                    entity.Position = bond.CONTROLLING.Position + data.peanutButterOffset

                    local switchControllers = random(1, CONFIG.PEANUTBUTTER_CONTROLLER_SWITCH_CHANCE)
                    if switchControllers == 1 then
                        bond.CONTROLLING = entity
                        entity:ClearEntityFlags(frozenFlags)
                        for _, ent2 in pairs(bond.ENTITIES) do
                            ent2:GetData().peanutButterOffset = ent2.Position - bond.CONTROLLING.Position
                        end
                    end
                end
            else
                if entity:Exists() then
                    entity:ClearEntityFlags(frozenFlags)
                end

                bond.ENTITIES[key2] = nil
            end
        end

        bond.TIMER = bond.TIMER - 1
        if bond.TIMER <= 0 then
            for key2, entity in pairs(bond.ENTITIES) do
                AlphaAPI.clearFlag(entity, ENTITY_FLAGS.PEANUTBUTTER_STICKY)
                entity:ClearEntityFlags(frozenFlags)
            end

            PEANUTBUTTER_BONDS[key] = nil
        end
    end
end

-------------------
-- Mr Squishy
-------------------
function Alphabirth.mrSquishyNewTear(tear)
    if AlphaAPI.hasFlag(tear, ENTITY_FLAGS.TEAR_IGNORE) and not tear:GetData().bounce then return end
    if not AlphaAPI.hasFlag(tear, ENTITY_FLAGS.SQUISHY_TEAR) and (AlphaAPI.getLuckRNG(15, 4) or tear:GetData().bounce) then
        tear = tear:ToTear()
        tear.TearFlags = BitSet128(0)
        tear:ChangeVariant(1)
        if not tear:GetData().bounce then
            tear:GetData().bounce = 1
            tear.Velocity = tear.Velocity * 0.6
        end
        tear.FallingSpeed = tear.FallingSpeed - (35 / tear:GetData().bounce)
        tear.FallingAcceleration = tear.FallingAcceleration + (1.8 / tear:GetData().bounce)
        local sprite = tear:GetSprite()
        sprite:Load("gfx/animations/effects/animation_tears_mrsquishy.anm2", true)
        sprite:Play("heart3Move")
        AlphaAPI.addFlag(tear, ENTITY_FLAGS.SQUISHY_TEAR)
    end
end

local function fireTearVolley(position, tear_num)
    local tears = {}
    for i = 1, tear_num do
        tears[i] = AlphaAPI.GAME_STATE.PLAYERS[1]:FireTear(position,
            Vector(random(-4, 4),
                random(-4, 4)),
            false,
            false,
            true
        )
        AlphaAPI.addFlag(tears[i], ENTITY_FLAGS.TEAR_IGNORE)
        tears[i]:ChangeVariant(1)
        tears[i].TearFlags = BitSet128(0)
        tears[i].Scale = 1
        tears[i].Height = -30
        tears[i].FallingSpeed = -4 + random() * -6
        tears[i].FallingAcceleration = random() + 0.5
    end
    tears = nil
    collectgarbage()
end

function Alphabirth.mrSquishyTearUpdate(tear, data)
    tear = tear:ToTear()
    if AlphaAPI.hasFlag(tear, ENTITY_FLAGS.SQUISHY_TEAR) and tear:IsDead() then
        if tear:GetData().bounce == 1 then
            fireTearVolley(tear.Position, 3)
            local new = AlphaAPI.GAME_STATE.PLAYERS[1]:FireTear(tear.Position,
                tear.Velocity * 0.3,
                false,
                false,
                true
            )
        AlphaAPI.addFlag(new, ENTITY_FLAGS.TEAR_IGNORE)
            new:GetData().bounce = 2
        elseif tear:GetData().bounce == 2 then
            fireTearVolley(tear.Position, 8)
        end
        Isaac.Spawn(EntityType.ENTITY_EFFECT,
            EffectVariant.PLAYER_CREEP_RED,
            0,
            tear.Position,
            Vector(0, 0),
            AlphaAPI.GAME_STATE.PLAYERS[1]
        )
    end
end

-------------------------------------------------------------------------------
---- TRINKET LOGIC
-------------------------------------------------------------------------------
-------------------
-- Moonrock
-------------------

function Alphabirth.moonrockNewTear(e)
    if AlphaAPI.getLuckRNG(10, 3) then
        local roll = random(1,2)
        if roll == 1 then
            e:ToTear().TearFlags = e:ToTear().TearFlags | TearFlags.TEAR_ORBIT
        elseif roll == 2 then
            e:ToTear().TearFlags = e:ToTear().TearFlags | TearFlags.TEAR_WAIT
        end
        e:ToTear().TearFlags = e:ToTear().TearFlags | TearFlags.TEAR_CONFUSION
        e.Color = Color(0.7, 0.7, 0.7, 1, 0, 0, 0)
    end
end

-------------------------------------------------------------------------------
---- POCKET ITEMS LOGIC
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
---- FAMILIAR LOGIC
-------------------------------------------------------------------------------
-------------------
-- The Cosmos
-------------------
function Alphabirth.evaluateCosmos(player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        local amount_to_spawn = player:GetCollectibleNum(ITEMS.PASSIVE.THE_COSMOS.id) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
        player:CheckFamiliar(FAMILIARS.MERCURY.variant, amount_to_spawn, modRNG)
        player:CheckFamiliar(FAMILIARS.PLUTO.variant, amount_to_spawn, modRNG)
        player:CheckFamiliar(FAMILIARS.VENUS.variant, amount_to_spawn, modRNG)
    end
end

---MERCURY---
local mercury_burn_chance = 0.05
local mercury_burn_duration = 60
function Alphabirth.initializeMercury(familiar)
    familiar = familiar:ToFamiliar()
    familiar:AddToOrbit(30)
    familiar:GetData().orbit_distance = Vector(40, 40)
end

function Alphabirth.updateMercury(familiar)
	familiar.OrbitDistance = familiar:GetData().orbit_distance
    familiar.OrbitAngleOffset = familiar.OrbitAngleOffset + 0.05
    familiar.Velocity = (familiar:GetOrbitPosition(AlphaAPI.GAME_STATE.PLAYERS[1].Position) - familiar.Position)
end

---VENUS---
local venus_charm_chance = 0.05
local venus_charm_duration = 120
function Alphabirth.initializeVenus(familiar)
    familiar = familiar:ToFamiliar()
    familiar:AddToOrbit(31)
    familiar:GetData().orbit_distance = Vector(60, 60)
end

function Alphabirth.updateVenus(familiar)
    familiar.OrbitDistance = familiar:GetData().orbit_distance
    familiar.OrbitAngleOffset = familiar.OrbitAngleOffset + 0.035
    familiar.Velocity = (familiar:GetOrbitPosition(AlphaAPI.GAME_STATE.PLAYERS[1].Position) - familiar.Position)
end

---PLUTO---
local pluto_freeze_chance = 0.05
local pluto_freeze_duration = 90
function Alphabirth.initializePluto(familiar)
    familiar = familiar:ToFamiliar()
    familiar:AddToOrbit(50)
    familiar:GetData().orbit_distance = Vector(80, 80)
end

function Alphabirth.updatePluto(familiar)
	familiar.OrbitDistance = familiar:GetData().orbit_distance
    familiar.OrbitAngleOffset = familiar.OrbitAngleOffset + 0.02
    familiar.Velocity = (familiar:GetOrbitPosition(AlphaAPI.GAME_STATE.PLAYERS[1].Position) - familiar.Position)
end

---DAMAGE---
function Alphabirth.cosmosDamage(entity, damage_amount, damage_flag, damage_source, invincibility_frames)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    if damage_source.Entity then
        if AlphaAPI.matchConfig(damage_source.Entity, FAMILIARS.MERCURY) then
            if random() < mercury_burn_chance then
                entity:AddBurn(EntityRef(player), mercury_burn_duration, player.Damage)
            end
        elseif AlphaAPI.matchConfig(damage_source.Entity, FAMILIARS.VENUS) then
            if random() < venus_charm_chance then
                entity:AddCharmed(venus_charm_duration)
            end
        elseif AlphaAPI.matchConfig(damage_source.Entity, FAMILIARS.PLUTO) then
            if random() < pluto_freeze_chance then
                entity:AddFreeze(EntityRef(player), pluto_freeze_duration)
            end
        end
    end
end


-------------------
-- Hushy Fly
-------------------
function Alphabirth.evaluateHushyFly(player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        local amount_to_spawn = player:GetCollectibleNum(ITEMS.PASSIVE.HUSHY_FLY.id) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
        player:CheckFamiliar(FAMILIARS.HUSHY_FLY.variant, amount_to_spawn, modRNG)
    end
end

function Alphabirth.initializeHushyFly(fly)
    fly = fly:ToFamiliar()
    fly:AddToOrbit(51)
end

function Alphabirth.updateHushyFly(fly)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    fly.OrbitDistance = Vector(50,50)
	fly.Velocity = (fly:GetOrbitPosition(player.Position) - fly.Position) 
    if player:GetLastActionTriggers() & ActionTriggers.ACTIONTRIGGER_SHOOTING == 0 then
        fly.OrbitAngleOffset = fly.OrbitAngleOffset + 0.1
    end
end

-------------------
-- Lil Miner
-------------------
    function Alphabirth.evaluateLilMiner(player, flag)
        if flag == CacheFlag.CACHE_FAMILIARS then
            local amount_to_spawn = player:GetCollectibleNum(ITEMS.PASSIVE.LIL_MINER.id) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
            player:CheckFamiliar(FAMILIARS.LIL_MINER.variant, amount_to_spawn, modRNG)
        end
    end

    function Alphabirth.initializeLilMiner(miner)
        miner.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        miner.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
        miner:GetData().lilMinerData = {
            digTime = nil,
            digging = false,
            pickupsSpawned = 0,
            roomIDX = AlphaAPI.GAME_STATE.LEVEL:GetCurrentRoomIndex(),
            cooldown = 0
        }
    end

    local possible_pickups = { -- hacky way to make chests rarer.
        PickupVariant.PICKUP_COIN,
        PickupVariant.PICKUP_BOMB,
        PickupVariant.PICKUP_KEY,
        PickupVariant.PICKUP_COIN,
        PickupVariant.PICKUP_BOMB,
        PickupVariant.PICKUP_KEY,
        PickupVariant.PICKUP_COIN,
        PickupVariant.PICKUP_BOMB,
        PickupVariant.PICKUP_KEY,
        PickupVariant.PICKUP_COIN,
        PickupVariant.PICKUP_BOMB,
        PickupVariant.PICKUP_KEY,
        PickupVariant.PICKUP_CHEST,
        PickupVariant.PICKUP_LOCKEDCHEST
    }

    function Alphabirth.updateLilMiner(miner)
        local data = miner:GetData()
        local sprite = miner:GetSprite()
        local room = AlphaAPI.GAME_STATE.ROOM

        if data.roomIDX ~= AlphaAPI.GAME_STATE.LEVEL:GetCurrentRoomIndex() then
            data.pickupsSpawned = 0
            data.roomIDX = AlphaAPI.GAME_STATE.LEVEL:GetCurrentRoomIndex()
        end

        if room:IsClear() or not data.lilMinerData.digging then
            if miner.Position:Distance(AlphaAPI.GAME_STATE.PLAYERS[1].Position) > 160 and room:GetAliveEnemiesCount() == 0 then
                sprite:Play("DigDown")
                if sprite:IsFinished("DigDown") then
                    miner.Position = AlphaAPI.GAME_STATE.PLAYERS[1].Position
                    sprite:Play("DigUp", true)
                end
            else
                if not sprite:IsPlaying("Idle") and not sprite:IsPlaying("DigUp") then
                    sprite:Play("Idle", true)
                end
            end
        end

        if not room:IsClear() and room:GetAliveEnemiesCount() > 0 then
            if not data.lilMinerData.digTime and not data.lilMinerData.digging then
                data.lilMinerData.digTime = random(120, 180)
            end

            if data.lilMinerData.digTime and (miner.FrameCount % data.lilMinerData.digTime == 0) then
                sprite:Play("DigDown")
                data.lilMinerData.digging = true
                data.lilMinerData.digTime = nil
            end

            if data.lilMinerData.digging then
                if sprite:IsFinished("DigDown") then
                    miner.Position = room:FindFreeTilePosition(room:GetRandomPosition(100), -1)
                    sprite:Play("DigUp", true)

                    local nearEnts = Isaac.FindInRadius(miner.Position, 45, EntityPartition.ENEMY)
                    for _, ent in ipairs(nearEnts) do
                        local away = (ent.Position - miner.Position):Normalized()
                        ent:AddVelocity(away * 13)
                        ent:TakeDamage(AlphaAPI.GAME_STATE.PLAYERS[1].Damage * 1.6, 0, EntityRef(miner), 0)
                    end

                    if random(1, 100) < CONFIG.LITTLEMINER_FINDCHANCE + AlphaAPI.GAME_STATE.PLAYERS[1].Luck and data.lilMinerData.pickupsSpawned < CONFIG.LITTLEMINER_MAXPICKUPSPERROOM then
                        Isaac.Spawn(
                            EntityType.ENTITY_PICKUP,
                            possible_pickups[random(1, #possible_pickups)],
                            0,
                            miner.Position,
                            Vector(random(),random()),
                            miner
                        )
                        data.lilMinerData.pickupsSpawned = data.lilMinerData.pickupsSpawned + 1
                    end
                    data.lilMinerData.digging = false
                end
            end
        end
    end

-------------------
-- Hive Head
-------------------
local HiveHead = {
	OrbitalLimit = 6, --max fly orbitals at once
	FlyAwaySpeed = 10, --the speed at which the flies fly away
	CreepSpawnRate = 100, --adds x to the interval
	CreepSpawnRadius = 1000, -- adds math.random(x) - (x/2) to the interval (or math.random(x/2) if its too low or negative)
	OrbitDistance = Vector(50,50),
	OrbitSpeed = 0.05,
	OrbitLayer = 817,
	HoneyColor = Color(1,1,1, 1, 219,167,0),
}

local function Lerp(first, second, percentage)
	return (first + (second - first) * percentage)
end

function Alphabirth.addHiveFlies(ammount)
	local data = api_mod.data.run

	data.HiveHeadFlies = data.HiveHeadFlies ~= nil
	and data.HiveHeadFlies < HiveHead.OrbitalLimit
	and math.min(HiveHead.OrbitalLimit, data.HiveHeadFlies + ammount)

	or data.HiveHeadFlies == nil
	and math.min(HiveHead.OrbitalLimit, ammount)

	or HiveHead.OrbitalLimit

	--bleh
	if HiveHead.OrbitalLimit < 0 then
		HiveHead.OrbitalLimit = 0
	end

	AlphaAPI.GAME_STATE.PLAYERS[1]:CheckFamiliar(FAMILIARS.HIVE_HEAD.variant, data.HiveHeadFlies, modRNG)
	return data.HiveHeadFlies
end

function Alphabirth.removeFlies()
	local data = api_mod.data.run

	data.HiveHeadFlies = 0

	for k,v in ipairs(AlphaAPI.getRoomEntitiesByType(FAMILIARS.HIVE_HEAD)) do
		v:GetData().FlyAway = true
		local fam = v:ToFamiliar()
		fam.OrbitLayer = 0
		fam.Variant = -fam.Variant
	end
end

function Alphabirth.getNewSpawnRate()
	return HiveHead.CreepSpawnRate
	+ math.max(
		math.random(HiveHead.CreepSpawnRadius/2),
		math.random(HiveHead.CreepSpawnRadius) - HiveHead.CreepSpawnRadius/2
	)
end



local invisibleColor = Color(1,1,1, 0, 0,0,0)

function Alphabirth.initializeHiveHead(fam)
	fam:AddToOrbit(HiveHead.OrbitLayer)
	fam.OrbitDistance = HiveHead.OrbitDistance
	fam.OrbitSpeed = HiveHead.OrbitSpeed
--	fam:RecalculateOrbitOffset(HiveHead.OrbitLayer,true)
	fam:GetData().CreepSpawnRate = Alphabirth.getNewSpawnRate()
end

function Alphabirth.updateHiveHead(fam)
	local playerPos = fam.Player.Position
	local d = fam:GetData()

	if d.FlyAway == nil then
		fam.OrbitDistance = HiveHead.OrbitDistance
		fam.OrbitSpeed = HiveHead.OrbitSpeed
		fam.Velocity = fam:GetOrbitPosition(playerPos) - fam.Position


	--[[BLOCKING THE SHOTS]]--
		-- ah yes i love checking for every entity for every entity ! !!!
		for k,ent in ipairs(AlphaAPI.getRoomEntitiesByType(EntityType.ENTITY_PROJECTILE)) do
            if fam.Position:Distance(ent.Position) < 15 then
                ent:Die()
            end
		end

	--[[SPAWNING THE CREEP]]--
		if fam.FrameCount % d.CreepSpawnRate == 0 then
			local creep  = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_BLACK, 0, fam.Position, VECTOR_ZERO, fam)
			creep:SetColor(HiveHead.HoneyColor,-1,999,false,true)
			d.CreepSpawnRate = Alphabirth.getNewSpawnRate()
		end
	else
		local famPos = fam.Position
		local topLeft = AlphaAPI.GAME_STATE.ROOM:GetTopLeftPos()
		local bottomRight = AlphaAPI.GAME_STATE.ROOM:GetBottomRightPos()
		local targetVelocity = ( famPos - playerPos ):Resized(HiveHead.FlyAwaySpeed)
		fam.Velocity = Lerp(fam.Velocity, targetVelocity, 0.2)

		local famPosX = famPos.X
		local famPosY = famPos.Y

		--if the orbital is hitting the borders of the room
		if famPosX < topLeft.X
		or famPosY < topLeft.Y
		or famPosX > bottomRight.X
		or famPosY > bottomRight.Y 	then
		--start fading out
			d.StartFade = true
		end

		if d.StartFade ~= nil then
			--reduce the orbital's colors until almost invisible and then remove them
			local s = fam:GetSprite()

			s.Color = Color.Lerp(s.Color, invisibleColor, 0.04)

			if s.Color.A <= 0.2 then
				fam:Remove()
			end
		end
	end
end

function Alphabirth:updateHiveHeadMod(fam)
	return Alphabirth.updateHiveHead(fam)
end

--[[ debug
mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD ,function(_,cmd, params)
	if cmd == "flies" then
		Alphabirth.addHiveFlies(tonumber(params))
	end
end)
--]]

function Alphabirth.onHiveHeadPickup()
	Alphabirth.addHiveFlies(1)
end

function Alphabirth.onHiveHeadRoomClear()
	Alphabirth.addHiveFlies(1)
end


-------------------------------------------------------------------------------
---- ENEMY LOGIC
-------------------------------------------------------------------------------
-------------------
-- Meathead
-------------------
local vectab = {
	[-1] = VECTOR_ZERO,
	[0] = Vector(-1, 0),
	[1] = Vector(0, -1),
	[2] = Vector(1, 0),
	[3] = Vector(0, 1),
}
vectab["NoDirection"] = vectab[-1]
vectab["Side"] = vectab[2]

vectab["Left"] = vectab[0]
vectab["Up"] = vectab[1]
vectab["Right"] = vectab[2]
vectab["Down"] = vectab[3]

local function vecToString(vec) --used for familiar directions!!
	local x = vec.X
	local y = vec.Y
	local absX = math.abs(x)
	local absY = math.abs(y)
	if absX > absY then
		if x > 0 then 		return "Side"
		elseif x < 0 then	return "Left"
		end
	else
		if y > 0 then 		return "Down"
		elseif y < 0 then	return "Up"
		end
	end
	return "Down"
end

function Alphabirth.meatheadUpdate(entity, data)
    local sprite = entity:GetSprite()
	if sprite:IsPlaying("Appear") then return end
	local entitynpc = entity:ToNPC()
	local d = entitynpc:GetData()
	local target = entitynpc:GetPlayerTarget()

    entitynpc.Target = target

	local targetpos = target.Position
	local selfpos = entitynpc.Position
	local selfvel = entitynpc.Velocity
	local align = targetpos - selfpos
	if d.animation ~= nil then
		sprite:Play(d.animation,false)
		if sprite:IsEventTriggered("Shoot") then
			local adjacentPosition = selfpos + d.direction:Resized(24)
			local speed = d.direction:Resized(5)
			local shockwave = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SHOCKWAVE, 0, adjacentPosition, speed, entitynpc):ToEffect()
			local endpos = AlphaAPI.GAME_STATE.ROOM:GetLaserTarget(adjacentPosition, d.direction)
			local distance = (endpos - adjacentPosition):Length()
			shockwave:SetTimeout(math.floor(distance/5))
			shockwave:SetRadii(6,6)
			shockwave.Parent = entitynpc
		end
		if sprite:IsFinished(d.animation) then
			d.animation = nil
			d.direction = nil
		end
	else
		entitynpc.Pathfinder:FindGridPath(entitynpc.Target.Position, 1, 0, entitynpc.Pathfinder:HasDirectPath())
		if selfvel.Y > 0 then
			entitynpc:AnimWalkFrame("WalkSide", "WalkDown", 2)
		else
			entitynpc:AnimWalkFrame("WalkSide", "WalkUp", 2)
		end
		if (math.abs(align.X) < 15) or (math.abs(align.Y) < 15) then
			entitynpc.Pathfinder:Reset()
			local animdir = vecToString(align)
			d.direction = vectab[animdir]
			sprite.FlipX = false
			if animdir == "Left" then
				animdir = "Side"
				sprite.FlipX = true
			end
			local animation = "Slam"..animdir
			sprite:Play(animation,true)
			d.animation = animation
		end
	end
end

-------------------
-- Wizeeker
-------------------
Alphabirth.FlameSpawnerVariant = 5930 --used to identify the flame in damage callback

function Alphabirth.GetNearAxisPosition(pos, distance)
	local room = AlphaAPI.GAME_STATE.ROOM
	local farpos
	local eligiblesides = {}
	for dir=0, 3 do
		local maxpos = room:GetLaserTarget(pos, vectab[dir])
		local axispos = pos + vectab[dir] * distance
		if maxpos:DistanceSquared(pos) > axispos:DistanceSquared(pos) then
			table.insert(eligiblesides, axispos)
		end
	end
	local resultpos = #eligiblesides > 0 and eligiblesides[math.random(#eligiblesides)] or Isaac.GetFreeNearPosition(pos, 100)
	if resultpos:DistanceSquared(pos) < 10000 then
		return Isaac.GetFreeNearPosition(resultpos, 80)
	else
		return resultpos
	end
end

function Alphabirth.wizeekerUpdate(entity)
	local d = entity:GetData()
	local s = entity:GetSprite()
	local vpos = entity.Position
	local rng = entity:GetDropRNG()
	local player = entity:ToNPC():GetPlayerTarget()
	if d.init == nil then
        entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
		d.init = true
		d.direction = "Down"
		d.position = vpos
		d.state = 0
		s:Play("AppearDown",true)
	end
	entity.Velocity = d.position - vpos
	--spawn state
	if d.state == 0 then
		local anim = "Appear"..d.direction
		s:Play(anim,false)
		if s:IsFinished(anim) then
			d.state = 9
		end
	end
	--vanish state
	if d.state == 9 then
		local anim = "Vanish"..d.direction
		s:Play(anim,false)
		if s:IsFinished(anim) then
			d.state = 3
			d.countdown = 60 + rng:RandomInt(30)
			d.prevcolclass = entity.EntityCollisionClass
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			entity.Visible = false
		end
	end
	--invisible, idle state
	if d.state == 3 then
		if d.countdown and d.countdown > 0 then
			d.countdown = d.countdown - 1
		elseif rng:RandomInt(10) == 0 then
			local ppos = player.Position
			local pos = Alphabirth.GetNearAxisPosition(ppos + player.Velocity, 100)
			if pos then
				local targetpos = ppos - pos
				--converting target position to a string
				local vecstr = vecToString(targetpos)
				if vecstr == "Side" then vecstr = "Right" end
				--setting up direction
				d.direction = vecstr
				d.targetpos = vectab[d.direction]
				--setting positions and making the boy visible
				d.position = pos
				entity.Position = pos
				d.state = 4
				entity.EntityCollisionClass = d.prevcolclass or EntityCollisionClass.ENTCOLL_ENEMIES
				entity.Visible = true
			end
		end
	end
	if d.state == 4 then
		local anim = "Appear"..d.direction
		s:Play(anim,false)
		if s:IsFinished(anim) then
			d.state = 8
		end
	end
	if d.state == 8 then
		local anim = "Shoot"..d.direction
		s:Play(anim,false)
		if s:IsEventTriggered("Shoot") then
			local flame = Isaac.Spawn(EntityType.ENTITY_EFFECT,EffectVariant.HOT_BOMB_FIRE,1,vpos + vectab[d.direction]:Resized(10) ,d.targetpos:Resized(10), entity):ToEffect()
			flame.SpawnerVariant = Alphabirth.FlameSpawnerVariant
			flame.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
			flame.GridCollisionClass = GridCollisionClass.COLLISION_SOLID
			flame:SetSize(flame.Size,flame.SizeMulti,12)
			SFX_MANAGER:Play(SOUNDS.CANDLE_BLOW, 0.35, 0, false, 1)
		end
		if s:IsFinished(anim) then
			d.state = 9
		end
	end
end

-------------------
-- Apparition
-------------------
function Alphabirth.apparitionUpdate(entity, data)
    local sprite = entity:GetSprite()
    if sprite:IsFinished("Full Appear") or sprite:IsFinished("Death") then
        if sprite:IsFinished("Death") then
            local pos = AlphaAPI.GAME_STATE.ROOM:FindFreePickupSpawnPosition(entity.Position, 1, true)
            ENTITIES.LARGESACK:spawn(pos, VECTOR_ZERO, nil)
        end

        entity:Remove()
    end
end

local largeSackDrops = {
    PickupVariant.PICKUP_BOMB,
    PickupVariant.PICKUP_COIN,
    PickupVariant.PICKUP_HEART,
    PickupVariant.PICKUP_LIL_BATTERY,
    PickupVariant.PICKUP_KEY,
    PickupVariant.PICKUP_LOCKEDCHEST,
    PickupVariant.PICKUP_ETERNALCHEST,
    PickupVariant.PICKUP_BOMBCHEST,
    PickupVariant.PICKUP_GRAB_BAG
}

function Alphabirth.onLargeSackPickup(player, pickup)
    for i = 1, random(4, 6) do
        Isaac.Spawn(EntityType.ENTITY_PICKUP, largeSackDrops[random(1, #largeSackDrops)], 0, pickup.Position, RandomVector() * (random(100, 300) * 0.01), nil)
    end

    return true
end

function Alphabirth.apparitionDamage(entity, amount)
    if amount > entity.HitPoints then
        entity:GetSprite():Play("Death")
        SFX_MANAGER:Play(SOUNDS.APPARITION_DEATH, CONFIG.APPARITION_VOLUME, 0, false, 1)
        return false
    end
end

function Alphabirth.apparitionAppear(entity)
    entity:GetSprite():Play("Full Appear", true)
    entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
end

function Alphabirth.apparitionSpawnCheck()
    if LOCKS.APPARITION:isUnlocked() then
        if not api_mod.data.run.apparitionRooms then
            api_mod.data.run.apparitionRooms = {}
        end

        local roomIndex = AlphaAPI.GAME_STATE.LEVEL:GetCurrentRoomIndex()

    	local room = AlphaAPI.GAME_STATE.ROOM
    	if not room:IsClear() and not api_mod.data.run.apparitionRooms[roomIndex] then
    		local chance = random(1, 30000)
    		if chance <= 1 + AlphaAPI.GAME_STATE.PLAYERS[1].Luck then
    			local position = room:GetRandomPosition(0)
    			local valid_position = room:FindFreePickupSpawnPosition(position, 1, true)
                api_mod.data.run.apparitionRooms[roomIndex] = true
    			return ENTITIES.APPARITION:spawn(valid_position, Vector(0, 0), nil)
    		end
    	end

    	return false
    end
end

-------------------------------------
local invisible = Color(1,1,1, 0, 0,0,0)
local function Lerp(first,second,percent)
	return (first + (second - first)*percent)
end

function Alphabirth.checkEnemyFlames()
	for k,v in ipairs(AlphaAPI.entities.effects) do
		if v.SpawnerVariant == Alphabirth.FlameSpawnerVariant then

			v.Velocity = v.Velocity * 0.96

			if v.FrameCount > 150 then
				v.EntityCollisionClass = 0

				local s = v:GetSprite()
				local resultScale = Lerp(s.Scale, VECTOR_ZERO, 0.06)
				s.Scale = resultScale
				s.Color = Color.Lerp(s.Color, invisible, 0.06)
				if resultScale.X < 0.1 then
					v:Remove()
				end
			end
		end
	end
end

-------------------
-- Planetoid
-------------------
function Alphabirth.planetoidAppear(entity, data)
    data.frameOffset = random(1, 1000)
    data.direction = -1
    if random(1, 2) == 1 then data.direction = 1 end
    entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
    entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
end

function Alphabirth.planetoidUpdate(entity, data, sprite)
    if entity.State ~= NpcState.STATE_APPEAR then
        if AlphaAPI.GAME_STATE.ROOM:IsClear() and entity.SubType == 0 then
            sprite:Play("Death")
            entity.Velocity = Vector(0, 0)
        end

        if sprite:IsFinished("Death") then
            entity:Remove()
        end

        if not sprite:IsPlaying("Death") then
            local target = entity:GetPlayerTarget().Position
            local frame = entity.FrameCount + data.frameOffset

            local xvel = math.cos(((frame * data.direction) / 20) + math.pi) * 50
            local yvel = math.sin(((frame * data.direction) / 20) + math.pi) * 50

            local direction = Vector(target.X - xvel, target.Y - yvel) - entity.Position

            if direction:Length() > CONFIG.PLANETOID_MAXSPEED then
                direction:Resize(CONFIG.PLANETOID_MAXSPEED)
            end

            entity.Velocity = direction
        end
    end
end

function Alphabirth.planetoidTakeDamage(entity, amount, flags, source)
    if entity.SubType ~= 1 then
        return false
    end
end

---------------------------------------
-- Brimstone Host Logic
---------------------------------------
function Alphabirth.onBrimstoneHostUpdate(host, data, host_sprite)
    local player = host:GetPlayerTarget()
    local host_sprite = host:GetSprite()
    if host_sprite:IsEventTriggered("Shoot") then
        local player_saved_position = data[0]
        local direction_vector = (player_saved_position - host.Position):Normalized()
        local direction_angle = direction_vector:GetAngleDegrees()
        local brimstone_laser = EntityLaser.ShootAngle(1, host.Position, direction_angle, 15, Vector(0,-10), host)
        brimstone_laser.DepthOffset = 200

        AlphaAPI.callDelayed(function(pos)
            local projectiles = AlphaAPI.getRoomEntitiesByType(EntityType.ENTITY_PROJECTILE)
            for _, projectile in ipairs(projectiles) do
                Isaac.DebugString("Found a projectile!")
                if projectile.Position:Distance(pos) < 20 then
                    projectile:Remove()
                end
            end
        end, 2, false, host.Position)
    elseif host.StateFrame == 20 then -- Attack the position the player was in earlier.
        data[0] = player.Position
    end
end

---------------------------------------
-- Star Gazer logic
---------------------------------------
local laserOffset = Vector(0,2)
local spriteOffset = Vector(2, -20)
local starGazerOffset = Vector(2, 8)
globalStargazerCountdown = 0

function Alphabirth.onLaserUpUpdate(laserUp, data, sprite)
    if sprite:IsFinished("Start") then
        sprite:Play("Loop", true)
    end
    if sprite:IsFinished("End") then
        laserUp:Remove()
    end
	local parent = data.parent
	laserUp.Position = parent.Position + laserOffset
    laserUp.Velocity = parent.Velocity
end

function Alphabirth.onLaserDownUpdate(laserDown, _, sprite)
    local sprite = laserDown:GetSprite()
    if sprite:IsFinished("Start") then
        sprite:Play("Loop", true)
    end
    if sprite:IsFinished("End") then
        laserDown:Remove()
    end
    if not laserDown:IsDead() then
        local player = AlphaAPI.GAME_STATE.PLAYERS[1]
        if (player.Position - laserDown.Position):LengthSquared() < 1000 then
            player:TakeDamage(1, 0, EntityRef(laserDown), 1)
        end
    end
end


function Alphabirth.onStarGazerUpdate(starGazer, data, sprite)
    local player = starGazer:GetPlayerTarget()
	local ppos = player.Position
	local vpos = starGazer.Position

	local diff = ppos - vpos
	local ai = starGazer.Pathfinder

    if not data.initialized then
        data.initialized = true
        sprite:Play("Idle", true)
        data.attackCountdown = 50
        data.evadeCooldown = 40
        data.attacking = false
        data.accel = Vector(0, 0)
        starGazer.HitPoints = 30
        starGazer.SpriteOffset = starGazerOffset
    end

    if not data.attacking then
        if data.evadeCooldown < 1 then
            local dir = diff:Normalized()
            starGazer:AddVelocity(-dir * (random(100, 300) * 0.01))
            data.evadeCooldown = random(7, 25)
        end

        if not sprite:IsPlaying("Idle") then
            sprite:Play("Idle", true)
        end
    end

    if globalStargazerCountdown == 0 and data.attackCountdown < 0 and not data.attacking and random(1, 50) == 1 then
        data.attacking = true
		globalStargazerCountdown = 50
        sprite:Play("Attack", true)
        SFX_MANAGER:Play(SoundEffect.SOUND_SKIN_PULL, 1.5, 0, false, 1)
    end

    if sprite:IsPlaying("Attack") then
        if sprite:IsEventTriggered("Shoot") then
            data.attackPos = ppos

			local laser = Isaac.Spawn(741, 3, 1, starGazer.Position+starGazer.Velocity, starGazer.Velocity, starGazer)
            data.laserUp = laser

            laser:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            laser.GridCollisionClass = GridCollisionClass.COLLISION_NONE
            laser.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            laser:GetData().parent = starGazer
            laser:GetSprite():Play("Start")
            laser.SpriteOffset = spriteOffset

            SFX_MANAGER:Play(SoundEffect.SOUND_GHOST_ROAR, 1, 0, false, 1)
		end
    end

    if sprite:IsFinished("Attack") then
        sprite:Play("Idle", true)
        data.attacking = false
        data.attackCountdown = 100
    end

    if data.laserUp then
        if data.laserUp.FrameCount == 11 then
			local laser = Isaac.Spawn(741, 3, 2, data.attackPos, VECTOR_ZERO, starGazer)
            data.laserDown =laser

            laser:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            laser.GridCollisionClass = GridCollisionClass.COLLISION_NONE
            laser.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            laser:GetSprite():Play("Start")
			laser.Velocity = (ppos - data.laserDown.Position):Resized(5 * AlphaAPI.GAME_STATE.PLAYERS[1].MoveSpeed)

        end


        if sprite:IsEventTriggered("ShootEnd") then
            data.laserUp:GetSprite():Play("End")
            if data.laserDown then
                data.laserDown:GetSprite():Play("End")
            end
        end

    end

    if data.laserDown then
        data.laserDown.Velocity = Lerp(
			data.laserDown.Velocity,
			(ppos - data.laserDown.Position):Resized(5 * AlphaAPI.GAME_STATE.PLAYERS[1].MoveSpeed),
			0.6
		)
    end


    if starGazer:IsDead() then
        if data.laserUp then
            data.laserUp:GetSprite():Play("End")
            if data.laserDown then
                data.laserDown:GetSprite():Play("End")
            end
        end

        sprite:Play("Death")
    end

    data.attackCountdown = data.attackCountdown - 1
    data.evadeCooldown = data.evadeCooldown - 1
end

-------------------
--  API Init
-------------------
local START_FUNC = start

if AlphaAPI then START_FUNC()
else if not __alphaInit then
__alphaInit={} end __alphaInit
[#__alphaInit+1]=START_FUNC end
