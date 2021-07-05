----------------------------------------------------------------------------
-- Item: Cool Bean
-- Originally from Pack 1
-- Freezes nearby enemies
----------------------------------------------------------------------------

local utils = include("code/utils")
local random = utils.random

local cool_bean = {
	ENABLED = true,
	NAME = "Cool Bean",
	TYPE = "Active",
	COOL_BEAN_RANGE = 160,
	COOL_BEAN_FREEZE_DURATION = 150,
	AB_REF = nil,
	ITEM_REF = nil
}

function cool_bean.setup(Alphabirth)
	cool_bean.AB_REF = Alphabirth
	Alphabirth.ITEMS.ACTIVE.COOL_BEAN = Alphabirth.API_MOD:registerItem(cool_bean.NAME)
	cool_bean.ITEM_REF = Alphabirth.ITEMS.ACTIVE.COOL_BEAN
	cool_bean.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_USE, cool_bean.trigger)
end

function cool_bean.trigger()
	local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	for _, entity in ipairs(AlphaAPI.entities.all) do
		if entity:IsActiveEnemy() then
			local distance_to_enemy = player.Position:Distance(entity.Position)
			if distance_to_enemy < cool_bean.COOL_BEAN_RANGE then
				entity:AddFreeze(
					EntityRef(player),
					cool_bean.COOL_BEAN_FREEZE_DURATION
				)
			end
		end
	end

	Isaac.Spawn(cool_bean.AB_REF.ENTITIES.ICE_FART.id,
				cool_bean.AB_REF.ENTITIES.ICE_FART.variant,  	-- Variant
				0,                          					-- Subtype
				player.Position,
				utils.VECTOR_ZERO,          					-- Velocity
				player)                    				 		-- Spawner
	cool_bean.AB_REF.SFX_MANAGER:Play(SoundEffect.SOUND_FART,1.0,0,false,1.0)
end

return cool_bean