return function(center)

	center.config = center.config or {}
	center.config.extra = center.config.extra or {}
	center.config.extra.hand_add = 0.01
	center.config.extra.discard_sub = 0.01

	center.loc_txt = center.loc_txt or {}
	center.loc_txt.name = 'Green Joker'
	center.loc_txt.text = {
		'Gains {X:mult,C:white}X#1#{} Mult per hand played',
		'Decrease Mult by {X:mult,C:white}X#2#{} per discard',
		'{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult)'
	}

	local orig_set_ability = center.set_ability
	center.set_ability = function(self, card, initial, delay_sprites)
		if orig_set_ability then orig_set_ability(self, card, initial, delay_sprites) end
		card.ability = card.ability or {}
		card.ability.extra = card.ability.extra or {}
		card.ability.extra.hand_add = center.config.extra.hand_add
		card.ability.extra.discard_sub = center.config.extra.discard_sub
		card.ability.x_mult = card.ability.x_mult or 1
		card.ability.mult = card.ability.x_mult
	end

	center.loc_vars = function(self, info_queue, card)
		local hand_add = center.config.extra and center.config.extra.hand_add or 0.01
		local discard_sub = center.config.extra and center.config.extra.discard_sub or 0.01
		local current_x = 1
		if card and card.ability then
			current_x = (card.ability.x_mult or card.ability.mult or 1)
		end
		return { vars = { hand_add, discard_sub, current_x } }
	end

	local function clamp_xmult(x)
		if x < 0 then return 0 end
		return x
	end

	if not rawget(_G,'VP_GREENJOKER_PATCHED_CALC') and rawget(_G,'Card') and Card.calculate_joker then
		local base_calculate_joker = Card.calculate_joker
		function Card:calculate_joker(context)
			if self.ability and self.ability.name == 'Green Joker' and not self.debuff then
				self.ability.x_mult = self.ability.x_mult or 1
				self.ability.mult = self.ability.x_mult
				if context then
					if context.joker_main then
						local x = clamp_xmult(self.ability.x_mult or 1)
						if x ~= 1 then
							return {
								message = localize{type='variable', key='a_xmult', vars={x}},
								Xmult_mod = x
							}
						else
							return { Xmult_mod = x }
						end
					end

					if context.cardarea == G.jokers then
						if context.before and not context.blueprint then
							self.ability.x_mult = (self.ability.x_mult or 1) + (self.ability.extra and self.ability.extra.hand_add or 0.01)
							self.ability.mult = self.ability.x_mult
						end
					end

					if context.discard and not context.blueprint and context.full_hand and (context.other_card == context.full_hand[#context.full_hand]) then
						local prev = self.ability.x_mult or 1
						local step = (self.ability.extra and self.ability.extra.discard_sub) or 0.01
						local new_val = clamp_xmult(prev - step)
						if new_val ~= prev then
							self.ability.x_mult = new_val
							self.ability.mult = self.ability.x_mult
						end
					end
				end
				return nil
			end
			return base_calculate_joker(self, context)
		end
		_G.VP_GREENJOKER_PATCHED_CALC = true
	end

	local orig_update = center.update
	center.update = function(self, card, dt)
		if orig_update then orig_update(self, card, dt) end
		if card and card.ability then
			if card.ability.x_mult == nil then card.ability.x_mult = 1 end
			card.ability.mult = card.ability.x_mult
		end
	end

	if rawget(_G,'G') and G.localization and G.localization.descriptions
		and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_green_joker then
		G.localization.descriptions.Joker.j_green_joker.text = center.loc_txt.text
	end

end