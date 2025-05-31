----------------------------------------------------------------------------
-- Item: Isaac's Skull
-- Originally from Pack 3
----------------------------------------------------------------------------

local Item = include("ab_src.api.item")

local desc = {
    ["en_us"] = {"Isaac's Skull", "{{Timer}} {{Collectible118}} Brimstone or {{Collectible331}} Godhead for the duration of the room#Using multiple times in one room stacks the effects"},
    ["pt_br"] = {"Caveira do Isaac", "{{Timer}} {{Collectible118}} Brimstone ou {{Collectible331}} Godhead para o resto do quarto#Usando varias vezes no mesmo quarto amplifica o efeito"},
    ["synergy"] = {
        [CollectibleType.COLLECTIBLE_DUALITY] = {
            ["en_us"] = {
                ["up"] = "Duality will give both effects at once",
                ["down"] = "Isaac's Skull will give both of its effects every use"
            },
            ["pt_br"] = {
                ["up"] = "Duality dará os dois efeitos sempre",
                ["down"] = "Caveira do Isaac dará os dois efeitos sempre",
            },
        }
    }
}

local isaacsSkull = Item("Isaac's Skull", desc)

isaacsSkull:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
    local effects = player:GetEffects()
    local has_duality = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_DUALITY) > 0

    if has_duality then
        effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_GODHEAD)
        effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_BRIMSTONE)
    else
        if rng:RandomInt(2) == 1 then
            effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_BRIMSTONE)
        else
            effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_GODHEAD)
        end
    end

    return true
end)
