----------------------------------------------------------------------------
-- Item: Rocket Shoes
-- Originally from Pack 3
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")

local rocketShoes = Item("Rock Shoes", false)
rocketShoes.NullCostume = Isaac.GetCostumeIdByPath("gfx/animations/costumes/accessories/animation_costume_rocketshoes.anm2")

rocketShoes:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player, flag)
    if player:GetLastActionTriggers() & ActionTriggers.ACTIONTRIGGER_MOVED ~= 0 then
        local max_speed = player.MoveSpeed * 5
        if player.Velocity:Length() < max_speed then
            player.Velocity = player:GetMovementVector():Resized(max_speed)
        end
    elseif player:GetLastActionTriggers() & ActionTriggers.ACTIONTRIGGER_MOVED == 0 then
        player.Velocity = player.Velocity * 0
    end
end)

rocketShoes:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, player_type)
    if flag == CacheFlag.CACHE_SPEED then
        player.MoveSpeed = player.MoveSpeed + 0.1
    end
    player:AddNullCostume(rocketShoes.NullCostume)
end)