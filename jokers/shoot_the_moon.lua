return function(center)

	center.config = center.config or {}
	center.config.extra = center.config.extra or 13

	center.loc_txt = center.loc_txt or {}
	center.loc_txt.name = 'Shoot the Moon'
	center.loc_txt.text = {
		"Gives {C:mult}+#1#{} Mult for each",
		"{C:hearts}Heart{} card held in hand",
		"when Queen of {C:spades}Spades{} played"
	}

	if rawget(_G,'G') and G.localization and G.localization.descriptions
		and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_shoot_the_moon
		and G.SETTINGS and G.SETTINGS.language == 'en-us' then
		G.localization.descriptions.Joker.j_shoot_the_moon.text = center.loc_txt.text
	end

	center.loc_vars = function(self, info_queue, card)
		local mult = (card and card.ability and card.ability.extra) or center.config.extra or 13
		return { vars = { mult } }
	end

	if not rawget(_G,'VP_SHOOTTHEMOON_REWORKED') and rawget(_G,'Card') and Card.calculate_joker then
		local old_calculate_joker = Card.calculate_joker
		function Card:calculate_joker(context)
			if self.ability and self.ability.name == 'Shoot the Moon' and not self.debuff then
				self.ability.extra = self.ability.extra or (center.config.extra or 13)
				if context and context.individual and context.cardarea == G.hand and context.other_card and not context.other_card.debuff then
					local sh = context.scoring_hand or {}
					local has_qs = false
					for i = 1, #sh do
						local sc = sh[i]
						if sc and (not sc.debuff) and sc:get_id() == 12 then
							if (sc.ability and sc.ability.name == 'Wild Card') or (sc.base and sc.base.suit == 'Spades') then
								has_qs = true; break
							end
						end
					end
					if has_qs then
						local c = context.other_card
						if (c.ability and c.ability.name == 'Wild Card') or (c.base and c.base.suit == 'Hearts') then
							return { h_mult = self.ability.extra, card = self }
						end
					end
				end
				return nil
			end
			return old_calculate_joker(self, context)
		end
		_G.VP_SHOOTTHEMOON_REWORKED = true
	end

	if rawget(_G,'G') and G.P_CENTERS and G.P_CENTERS.j_shoot_the_moon then
		G.P_CENTERS.j_shoot_the_moon.mod = nil
		G.P_CENTERS.j_shoot_the_moon.modded = false
		G.P_CENTERS.j_shoot_the_moon.discovered = true
	end

	return center
end