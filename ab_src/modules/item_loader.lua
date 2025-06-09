--
--  Item Loader Module
--

local itemLoader = {}
itemLoader.loadedItems = {}

local descs = include("ab_src.integrations.eid")

local files = {
	"ab_src.items.addicted",
	"ab_src.items.alastors_candle",
	"ab_src.items.black_pepper",
	"ab_src.items.beggars_cup",
	"ab_src.items.bugged_bombs",
	"ab_src.items.chalice_of_blood",
	"ab_src.items.charity",
	"ab_src.items.chastity",
	"ab_src.items.the_cosmos",
	"ab_src.items.cologne",
	"ab_src.items.cool_bean",
	"ab_src.items.debug",
	"ab_src.items.deliriums_brain",
	"ab_src.items.entropy",
	"ab_src.items.furnace",
	"ab_src.items.green_candle",
	"ab_src.items.isaacs_apple",
	"ab_src.items.isaacs_skull",
	"ab_src.items.lifeline",
	"ab_src.items.rocket_shoes",
	"ab_src.items.satans_contract",
	"ab_src.items.smart_bombs",
	"ab_src.items.tearleporter",
	"ab_src.items.temperance",
	"ab_src.items.trash_bag",
	"ab_src.items.white_candle",
	"ab_src.items.mirror",
	"ab_src.items.miniature_meteor",
	"ab_src.items.candle_kit",
	"ab_src.items.diligence",
	"ab_src.items.divine_wrath",
	"ab_src.items.mutant_fetus",
	"ab_src.items.graphics_error",
	"ab_src.items.humility",
	"ab_src.items.kindness",
	"ab_src.items.old_controller",
	"ab_src.items.patience",
	"ab_src.items.pseudobulbar_affect",
	"ab_src.items.talisman_of_absorption",
    "ab_src.items.surgeon_simulator",
    "ab_src.items.stoned_buddy",
    "ab_src.items.brunch",
    "ab_src.items.blacklight",
    "ab_src.items.infested_baby",
    "ab_src.items.quill_feather",
    "ab_src.items.stone_nugget",
    "ab_src.items.judas_fez",
    "ab_src.items.hoarder",
    "ab_src.items.possessed_shot",
    "ab_src.items.hushy_fly",
}

function itemLoader.loadAll(Alphabirth)
    for _, file in ipairs(files) do
		print("Loading item: "..file)
        local mod = include(file)
        if EID and mod and mod.desc then
            descs.push(mod.ID, mod.desc)
        end
		itemLoader.loadedItems[#itemLoader.loadedItems + 1] = mod
    end
    if EID then
        EID['loaded_ab'] = true
    end
end

return itemLoader
