----------------------------------------------------------------------------
-- Item: Satan's Contract
-- Originally from Pack 1
-- Doubles the player's damage and damage taken
----------------------------------------------------------------------------

local utils = include("code/utils")

local SATANS_CONTRACT = {
	ENABLED = true,
	NAME = "Satan's Contract",
	TYPE = "Passive",
	COSTUME = "gfx/animations/costumes/accessories/animation_costume_contract.anm2",
	AB_REF = nil,
	ITEM_REF = nil
}

function SATANS_CONTRACT.setup(Alphabirth)
	SATANS_CONTRACT.AB_REF = Alphabirth
	Alphabirth.ITEMS.PASSIVE.SATANS_CONTRACT = Alphabirth.API_MOD:registerItem(SATANS_CONTRACT.NAME, SATANS_CONTRACT.COSTUME)
	SATANS_CONTRACT.ITEM_REF = Alphabirth.ITEMS.PASSIVE.SATANS_CONTRACT
	SATANS_CONTRACT.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, SATANS_CONTRACT.evaluate)
	Alphabirth.MOD:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, SATANS_CONTRACT.entityDamage)
end

function SATANS_CONTRACT.evaluate(player, cache_flag)
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

function SATANS_CONTRACT.entityDamage(entity, damage_amount, damage_flags, damage_source, invincibility_frames)
	if entity.Type == EntityType.ENTITY_PLAYER then
		local player = entity:ToPlayer()
		if player:HasCollectible(SATANS_CONTRACT.ITEM_REF.id)
		and not SATANS_CONTRACT.AB_REF.hasProtection(player, damage_flags, damage_source) then
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
	else
		if AlphaAPI.hasFlag(entity, SATANS_CONTRACT.AB_REF.ENTITY_FLAGS.DOUBLE_DAMAGE) then
			entity.HitPoints = entity.HitPoints - damage_amount
		end
	end
end

return SATANS_CONTRACT