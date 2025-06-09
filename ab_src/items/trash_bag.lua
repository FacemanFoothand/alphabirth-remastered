----------------------------------------------------------------------------
-- Item: Trash Bag
-- Originally from Pack 1
-- 28% chance for 3 blue flies, 28% chance for 3 blue spiders,
-- 41% chance for a random pickup, 3% chance for a trinket
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local trash_bag = Item("Trash Bag") ---@type Item
trash_bag.description = include("ab_src.integrations.eid").trash_bag

---@param player EntityPlayer
trash_bag:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, player)
    local spider_fly_chance = utils.random(1, 2)
    if spider_fly_chance == 1 then
        for _ = 1, utils.random(1, 4) do
            player:AddBlueSpider(player.Position)
        end
    else
        player:AddBlueFlies(utils.random(1, 4), player.Position, nil)
    end

    local blue_fly_chance = utils.random(1, 4)
    if blue_fly_chance == 1 then
        player:AddBlueFlies(utils.random(1, 4), player.Position, nil)
    end

    local blue_spider_chance = utils.random(1, 4)
    if blue_spider_chance == 1 then
        for _ = 1, utils.random(1, 4) do
            player:AddBlueSpider(player.Position)
        end
    end

    local pickup_chance = utils.random(1, (100 - (player.Luck * 2)))
    if pickup_chance <= 50 then
        local pickups = {
            PickupVariant.PICKUP_HEART,
            PickupVariant.PICKUP_COIN,
            PickupVariant.PICKUP_KEY,
            PickupVariant.PICKUP_GRAB_BAG,
            PickupVariant.PICKUP_PILL,
            PickupVariant.PICKUP_LIL_BATTERY,
            PickupVariant.PICKUP_TAROTCARD,
            PickupVariant.PICKUP_BOMB,
        }

        local spawn_position = g.room:FindFreePickupSpawnPosition(player.Position, 1, true)
        Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            pickups[utils.random(1, #pickups)],
            0,
            spawn_position,
            Vector.Zero,
            player
        )
    end

    local trinket_chance = utils.random(1, 15)
    if trinket_chance == 1 then
        local spawn_position = g.room:FindFreePickupSpawnPosition(player.Position, 1, true)
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, 0, spawn_position, Vector.Zero, player)
    end

    local item_chance = utils.random(1, 150)
    if item_chance == 1 then
        local spawn_position = g.room:FindFreePickupSpawnPosition(player.Position, 1, true)
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 0, spawn_position, Vector.Zero, player)
    end

    return true
end)

return trash_bag
