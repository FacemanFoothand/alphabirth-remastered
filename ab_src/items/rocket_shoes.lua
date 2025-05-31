----------------------------------------------------------------------------
-- Item: Rocket Shoes
-- Originally from Pack 3
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")

local desc = {
    ["en_us"] = {"Rocket Shoes", "{{ArrowUp}} +0.1 Speed#{{SpeedSmall}} Instant acceleration to max speed"},
    ["pt_br"] = {"Sapatos Foguete", "{{ArrowUp}} +0.1 Velocidade#{{SpeedSmall}} Aceleração isntantânea para a velocidade máxima"},
}

local rocket_shoes = Item("Rocket Shoes", desc)

rocket_shoes:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player, player_type)
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

rocket_shoes:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, flag)
    local count =  player:GetCollectibleNum(rocket_shoes.ID)
    if flag == CacheFlag.CACHE_SPEED then
        player.MoveSpeed = player.MoveSpeed + 0.1 * count
    end
end)
