----------------------------------------------------------------------------
-- Item: Mutant Fetus
-- Originally from Pack 1
-- Has a chance to spawn a bomb when you hit an enemy
----------------------------------------------------------------------------

local Item = include("ab_src.api.item")
local Flag = include("ab_src.api.flag")
local utils = include("ab_src.modules.utils")

local desc = {
    ["en_us"] = {"Mutant Fetus", "Chance to shoot bomb tears#Bomb tears turn into a bomb on collision with an enemy#{{Bomb}} 1 in 200 chance of the bomb turning into a Super Troll Bomb#{{Luck}} 50% chance to shoot a bomb tear at 14 Luck"},
    ["pt_br"] = {"Feto Mutante", "Chance de disparar lágrima bomba#Lágrimas bomba se transformam em bombas ao colidir com um inimigo#{{Bomb}} 1 em 200 de chance da bomba se transformar em uma Super Troll Bomb#{{Luck}} 50% de chance de disparar uma lágrima bomba com 14 Sorte"},
    ["synergy"] = {
        [CollectibleType.COLLECTIBLE_SAD_BOMBS] = {
            ["en_us"] = {
                ["up"] = "The bomb tears will spawn Sad Bombs",
                ["down"] = "Mutant Fetus tears will spawn Sad Bombs",
            },
            ["pt_br"] = {
                ["up"] = "As lágrimas bomba irão gerar Sad Bombs",
                ["down"] = "As lágrimas do Feto Mutante irão gerar Sad Bombs",
            }
        },
        [CollectibleType.COLLECTIBLE_BUTT_BOMBS] = {
            ["en_us"] = {
                ["up"] = "Bomb tears cause a gas cloud on explosion",
                ["down"] = "Mutant Fetus tears release a gas cloud when they explode",
            },
            ["pt_br"] = {
                ["up"] = "Lágrimas bomba causam uma nuvem de gás ao explodirem",
                ["down"] = "Lágrimas do Feto Mutante liberam uma nuvem de gás ao explodirem",
            }
        },
        [CollectibleType.COLLECTIBLE_HOT_BOMBS] = {
            ["en_us"] = {
                ["up"] = "Bomb tears leave a trail of fire",
                ["down"] = "Mutant Fetus tears create flames on impact",
            },
            ["pt_br"] = {
                ["up"] = "Lágrimas bomba deixam um rastro de fogo",
                ["down"] = "Lágrimas do Feto Mutante criam chamas ao impactar",
            }
        },
        [CollectibleType.COLLECTIBLE_BOMBER_BOY] = {
            ["en_us"] = {
                ["up"] = "Bomb tears explode in a cross pattern",
                ["down"] = "Fetus tears have a cross-pattern explosion",
            },
            ["pt_br"] = {
                ["up"] = "Lágrimas bomba explodem em padrão de cruz",
                ["down"] = "Lágrimas do Feto Mutante explodem em formato de cruz",
            }
        },
        [CollectibleType.COLLECTIBLE_SCATTER_BOMBS] = {
            ["en_us"] = {
                ["up"] = "Bomb tears scatter into mini-bombs",
                ["down"] = "Fetus tears release mini-bombs on explosion",
            },
            ["pt_br"] = {
                ["up"] = "Lágrimas bomba se espalham em mini-bombas",
                ["down"] = "Lágrimas do Feto Mutante soltam mini-bombas ao explodirem",
            }
        },
        [CollectibleType.COLLECTIBLE_STICKY_BOMBS] = {
            ["en_us"] = {
                ["up"] = "Bomb tears stick to enemies",
                ["down"] = "Mutant Fetus tears attach to enemies before exploding",
            },
            ["pt_br"] = {
                ["up"] = "Lágrimas bomba grudam nos inimigos",
                ["down"] = "Lágrimas do Feto Mutante grudam nos inimigos antes de explodirem",
            }
        },
        [CollectibleType.COLLECTIBLE_GLITTER_BOMBS] = {
            ["en_us"] = {
                ["up"] = "Bomb tears may drop pickups",
                ["down"] = "Fetus bomb explosions can spawn pickups",
            },
            ["pt_br"] = {
                ["up"] = "Lágrimas bomba podem gerar pickups",
                ["down"] = "Explosões das lágrimas do Feto Mutante podem gerar pickups",
            }
        },
        [CollectibleType.COLLECTIBLE_FAST_BOMBS] = {
            ["en_us"] = {
                ["up"] = "Shorter delay between bomb tears",
                ["down"] = "Fetus tears can be fired more rapidly",
            },
            ["pt_br"] = {
                ["up"] = "Menor intervalo entre lágrimas bomba",
                ["down"] = "Lágrimas do Feto Mutante podem ser disparadas mais rapidamente",
            }
        },
        [CollectibleType.COLLECTIBLE_NANCY_BOMBS] = {
            ["en_us"] = {
                ["up"] = "Bomb tears have random effects",
                ["down"] = "Mutant Fetus tears inherit random Nancy Bombs effects",
            },
            ["pt_br"] = {
                ["up"] = "Lágrimas bomba ganham efeitos aleatórios",
                ["down"] = "Lágrimas do Feto Mutante recebem efeitos aleatórios de Nancy Bombs",
            }
        },
        [CollectibleType.COLLECTIBLE_BLOOD_BOMBS] = {
            ["en_us"] = {
                ["up"] = "Bomb tears heal on explosion",
                ["down"] = "Fetus tears grant red hearts when they explode near enemies",
            },
            ["pt_br"] = {
                ["up"] = "Lágrimas bomba curam ao explodirem",
                ["down"] = "Lágrimas do Feto Mutante concedem corações vermelhos ao explodirem perto de inimigos",
            }
        },
        [CollectibleType.COLLECTIBLE_BRIMSTONE_BOMBS] = {
            ["en_us"] = {
                ["up"] = "Bomb tears shoot brimstone lasers",
                ["down"] = "Mutant Fetus tears trigger brimstone on explosion",
            },
            ["pt_br"] = {
                ["up"] = "Lágrimas bomba disparam lasers de brimstone",
                ["down"] = "Lágrimas do Feto Mutante disparam brimstone ao explodirem",
            }
        },
        [CollectibleType.COLLECTIBLE_GHOST_BOMBS] = {
            ["en_us"] = {
                ["up"] = "Bomb tears are spectral and slow enemies",
                ["down"] = "Fetus tears pass through objects and slow enemies on explosion",
            },
            ["pt_br"] = {
                ["up"] = "Lágrimas bomba são espectrais e desaceleram inimigos",
                ["down"] = "Lágrimas do Feto Mutante atravessam objetos e desaceleram inimigos ao explodirem",
            }
        },
        [CollectibleType.COLLECTIBLE_EPIC_FETUS] = {
            ["en_us"] = {
                ["up"] = "{{ColorYellow}}Overrides{{CR}} Mutant Fetus",
                ["down"] = "Mutant Fetus has no effect while Epic Fetus is active",
            },
            ["pt_br"] = {
                ["up"] = "{{ColorYellow}}Substitui{{CR}} Feto Mutante",
                ["down"] = "Feto Mutante não tem efeito enquanto Epic Fetus estiver ativo",
            }
        },
        [CollectibleType.COLLECTIBLE_DR_FETUS] = {
            ["en_us"] = {
                ["up"] = "{{ColorYellow}}Overrides{{CR}} Mutant Fetus",
                ["down"] = "{{ColorYellow}}Mutant Fetus{{CR}} has no effect while Dr. Fetus is active",
            },
            ["pt_br"] = {
                ["up"] = "{{ColorYellow}}Substitui{{CR}} Feto Mutante",
                ["down"] = "Feto Mutante não tem efeito enquanto Dr. Fetus estiver ativo",
            }
        },
    }
}

local mutant_fetus = Item("Mutant Fetus", desc)
mutant_fetus.TearFlag = Flag("mutant_fetus_tear")

mutant_fetus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(player, entity, damage_amount, damage_flags, damage_source, invincibility_frames, entity_type)
	if mutant_fetus.TearFlag:EntityHas(damage_source) and entity:IsActiveEnemy(false) then
		mutant_fetus.TearFlag:Clear(damage_source)
		local bomb_roll = utils.random(1, 200)
		if bomb_roll == 1 then
			Isaac.Spawn(
				EntityType.ENTITY_BOMBDROP,
				BombVariant.BOMB_SUPERTROLL,
				0,
				entity.Position,
				utils.VECTOR_ZERO,
				player
			)
		else
			player:FireBomb( entity.Position, utils.VECTOR_ZERO )
		end
	end
end)

mutant_fetus:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, function(player, tear)
	if tear.Variant ~= TearVariant.CHAOS_CARD and utils.getLuckRNG(player, 7, 3) then
		mutant_fetus.TearFlag:Apply(tear)
		local tear_sprite = tear:GetSprite()
		tear_sprite:Load("gfx/animations/effects/animation_tears_mutantfetus.anm2", true)
		tear_sprite:Play("Idle")
		tear_sprite:LoadGraphics()
	end
end)

return mutant_fetus
