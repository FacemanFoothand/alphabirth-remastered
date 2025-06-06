----------------------------------------------------------------------------
-- Item: Rocket Shoes
-- Originally from Pack 3
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")

local rocket_shoes = Item("Rocket Shoes") ---@type Item
rocket_shoes.desc = include("ab_src.integrations.eid").rocket_shoes

---@param player EntityPlayer
rocket_shoes:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player)
    local count =  player:GetCollectibleNum(rocket_shoes.ID)
    if count < 1 then
        return
    end
    if player:GetLastActionTriggers() & ActionTriggers.ACTIONTRIGGER_MOVED ~= 0 then
        local max_speed = player.MoveSpeed * 5
        if player.Velocity:Length() < max_speed then
            player.Velocity = player:GetMovementVector():Resized(max_speed)
        end
    elseif player:GetLastActionTriggers() & ActionTriggers.ACTIONTRIGGER_MOVED == 0 then
        player.Velocity = player.Velocity * 0
    end
end)

---@param player EntityPlayer
---@param flag CacheFlag
rocket_shoes:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, flag)
    local count =  player:GetCollectibleNum(rocket_shoes.ID)
    if flag == CacheFlag.CACHE_SPEED then
        player.MoveSpeed = player.MoveSpeed + 0.1 * count
    end
end)

return rocket_shoes
