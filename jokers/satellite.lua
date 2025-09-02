return function(center)

	if SMODS and SMODS.Joker then
		SMODS.Joker:take_ownership('satellite', {
			no_mod_display = true,
			blueprint_compat = false,
			loc_txt = {
				name = 'Satellite',
				text = {
					"{C:planet}Planet{} cards used",
					"are twice as effective",
					"Earn {C:money}$#1#{} at end of round",
					"per unique {C:planet}Planet{} card",
					"used this run",
					"{C:inactive}(Currently {C:money}$#2#{C:inactive})",
				}
			},
			calculate = function(self, card, context)
				if card.debuff then return nil end
				if context and context.using_consumeable and not context.blueprint and context.consumeable and card.area == G.jokers then
					local c = context.consumeable
					if c.ability and c.ability.set == 'Planet' then
						local ht = c.ability.consumeable and c.ability.consumeable.hand_type
						if ht then
							G.E_MANAGER:add_event(Event({
								trigger = 'after', delay = 0.05, func = function()
									play_sound('card1', 0.85, 0.6)
									card:juice_up(0.9, 0.6)
									return true
								end
							}))
							G.E_MANAGER:add_event(Event({
								trigger = 'after', delay = 0.35, func = function()
									update_hand_text({sound = 'button', volume = 0.7, pitch = 0.8, delay = 0.3}, {handname=localize(ht, 'poker_hands'), chips = G.GAME.hands[ht].chips, mult = G.GAME.hands[ht].mult, level = G.GAME.hands[ht].level})
									level_up_hand(c, ht)
									update_hand_text({sound = 'button', volume = 0.7, pitch = 1.1, delay = 0}, {mult = 0, chips = 0, handname = '', level = ''})
									return true
								end
							}))
						end
						return nil
					end
				end
				return nil
			end,
		})
	end

	if SMODS and SMODS.Hook then
		SMODS.Hook.add('post_game_init', function()
			if G.P_CENTERS and G.P_CENTERS.j_satellite then
				G.P_CENTERS.j_satellite.mod = nil
				G.P_CENTERS.j_satellite.modded = false
				G.P_CENTERS.j_satellite.discovered = true
			end
		end)
	else
		if G.P_CENTERS and G.P_CENTERS.j_satellite then
			G.P_CENTERS.j_satellite.mod = nil
			G.P_CENTERS.j_satellite.modded = false
			G.P_CENTERS.j_satellite.discovered = true
		end
	end

	if rawget(_G,'G') and G.localization and G.localization.descriptions
		and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_satellite then
		G.localization.descriptions.Joker.j_satellite.text = {
			"{C:planet}Planet{} cards used",
			"are twice as effective",
			"Earn {C:money}$#1#{} at end of round ",
			"per unique {C:planet}Planet{} card used this run",
			"{C:inactive}(Currently {C:money}$#2#{C:inactive})",
		}
	end
end