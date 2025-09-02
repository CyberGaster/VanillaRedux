return function(center)

	center.config = center.config or {}
	center.config.extra = center.config.extra or {}
	center.no_mod_display = true

	center.loc_txt = center.loc_txt or {}
	center.loc_txt.name = 'Bootstraps'
	center.loc_txt.text = {
		'{C:mult}+1{} Mult for each {C:money}$2{} earned',
		'{C:inactive}(Currently {C:mult}+#3#{C:inactive} Mult)'
	}

	center.loc_vars = function(self, info_queue, card)
		local current_mult = 0
		if card and card.ability then
			local m = card.ability._vp_boot_mult
			if type(m) == 'number' then current_mult = m end
		end
		return { vars = { 1, 2, current_mult } }
	end

	local orig_set_ability = center.set_ability
	center.set_ability = function(self, card, initial, delay_sprites)
		if orig_set_ability then orig_set_ability(self, card, initial, delay_sprites) end

		card.ability = card.ability or {}

		if card.ability._vp_boot_mult == nil then
			local stored = nil
			if type(card.ability.extra) == 'table' then
				stored = tonumber(card.ability.extra.mult_stored)
			end
			if stored == nil and rawget(_G, 'G') and G.GAME then
				stored = G.GAME.vp_bootstraps_persist_mult
			end
			card.ability._vp_boot_mult = tonumber(stored) or 0
		end

		if card.ability._vp_boot_carry == nil then
			local c = nil
			if type(card.ability.extra) == 'table' then
				c = tonumber(card.ability.extra.carry_stored)
			end
			if c == nil and rawget(_G, 'G') and G.GAME then
				c = G.GAME.vp_bootstraps_persist_carry
			end
			card.ability._vp_boot_carry = math.max(0, math.floor(tonumber(c) or 0) % 2)
		end

		card.ability._vp_boot_chunk = 2
	end

	if not rawget(_G, 'VP_BOOTSTRAPS_EASE_PATCHED') and rawget(_G, 'ease_dollars') then
		local original_ease_dollars = ease_dollars
		local function _boot_to_number(x)
			if type(x) == 'number' then return x end
			if type(x) == 'string' then return tonumber(x) or 0 end
			if type(x) == 'table' then
				local ok, v
				if x.toNumber then ok, v = pcall(function() return x:toNumber() end); if ok and type(v) == 'number' then return v end end
				if x.to_number then ok, v = pcall(function() return x:to_number() end); if ok and type(v) == 'number' then return v end end
				local s = tostring(x)
				local n = tonumber(s)
				if n then return n end
			end
			return 0
		end
		function ease_dollars(mod, instant)
			local mod_num = _boot_to_number(mod)
			if mod_num > 0 and rawget(_G, 'G') and G.jokers and G.jokers.cards then
				local selling_lock = G.CONTROLLER and G.CONTROLLER.locks and G.CONTROLLER.locks.selling_card
				if not selling_lock then
					for i = 1, #G.jokers.cards do
						local jk = G.jokers.cards[i]
						if jk and jk.ability and jk.ability.name == 'Bootstraps' and not jk.debuff then
							local chunk = (jk.ability and jk.ability._vp_boot_chunk) or 2
							local carry = (jk.ability and jk.ability._vp_boot_carry) or 0
							local total = carry + mod_num
							local gained = math.floor(total / chunk)
							jk.ability._vp_boot_carry = total - gained * chunk
							if gained > 0 then
								jk.ability._vp_boot_mult = (jk.ability._vp_boot_mult or 0) + gained
							end
						end
					end
				end
			end
			return original_ease_dollars(mod, instant)
		end
		_G.VP_BOOTSTRAPS_EASE_PATCHED = true
	end

	if not rawget(_G, 'VP_BOOTSTRAPS_CALC_PATCHED') and rawget(_G, 'Card') and Card.calculate_joker then
		local old_calculate_joker = Card.calculate_joker
		function Card:calculate_joker(context)
			if self.ability and self.ability.name == 'Bootstraps' and not self.debuff then
				if context and context.selling_self then
					if rawget(_G, 'G') then
						G.GAME.vp_bootstraps_persist_mult = (self.ability and self.ability._vp_boot_mult) or 0
						G.GAME.vp_bootstraps_persist_carry = (self.ability and self.ability._vp_boot_carry) or 0
					end
				elseif context and context.cardarea == G.jokers then
					if context.joker_main then
						local mult = (self.ability and self.ability._vp_boot_mult) or 0
						if mult > 0 then
							return {
								message = localize{type='variable', key='a_mult', vars={mult}},
								mult_mod = mult,
								colour = G.C.MULT,
								card = self
							}
						else
							return { mult_mod = 0 }
						end
					end
				end
			end
			return old_calculate_joker(self, context)
		end
		_G.VP_BOOTSTRAPS_CALC_PATCHED = true
	end

	if not rawget(_G, 'VP_BOOTSTRAPS_UI_PATCHED') and rawget(_G, 'Card') and Card.generate_UIBox_ability_table then
		local old_generate_UIBox = Card.generate_UIBox_ability_table
		function Card:generate_UIBox_ability_table()
			if self.ability and self.ability.set == 'Joker' and self.ability.name == 'Bootstraps' then
				local mult = (self.ability and type(self.ability._vp_boot_mult) == 'number') and self.ability._vp_boot_mult or 0
				local saved_extra = self.ability.extra
				local saved_dollars = rawget(_G,'G') and G.GAME and G.GAME.dollars
				local saved_buffer = rawget(_G,'G') and G.GAME and G.GAME.dollar_buffer
				self.ability.extra = { mult = 1, dollars = 1 }
				if rawget(_G,'G') and G.GAME then
					G.GAME.dollars = mult
					G.GAME.dollar_buffer = 0
				end
				local result = old_generate_UIBox(self)
				self.ability.extra = saved_extra
				if rawget(_G,'G') and G.GAME then
					G.GAME.dollars = saved_dollars
					G.GAME.dollar_buffer = saved_buffer
				end
				return result
			end
			return old_generate_UIBox(self)
		end
		_G.VP_BOOTSTRAPS_UI_PATCHED = true
	end

	if rawget(_G,'G') and G.localization and G.localization.descriptions
		and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_bootstraps then
		G.localization.descriptions.Joker.j_bootstraps.text = center.loc_txt.text
	end
end