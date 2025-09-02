return function(center)
	
	center.config = center.config or {}
	center.config.extra = 1

	center.loc_txt = center.loc_txt or {}
	center.loc_txt.name = 'Chaos the Clown'
	center.loc_txt.text = {
		'{C:attention}#1#{} free {C:green}Reroll per shop',
		'Gains {C:attention}+1{} free Reroll when',
		'{C:attention}Boss Blind{} defeated',
		'{C:inactive}(resets when sold)'
	}

	if rawget(_G,'G') and G.localization and G.localization.descriptions
		and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_chaos then
		G.localization.descriptions.Joker.j_chaos.text = center.loc_txt.text
	end

	center.loc_vars = function(self, info_queue, card)
		local extra = card and card.ability.extra or center.config.extra
		return { vars = { extra } }
	end

	local function find_chaos_jokers()
		local out = {}
		if rawget(_G, 'G') and G.jokers and G.jokers.cards then
			for _, v in pairs(G.jokers.cards) do
				if v and v.ability and v.ability.name == 'Chaos the Clown' and not v.debuff then
					table.insert(out, v)
				end
			end
		end
		return out
	end

	local function total_chaos_rerolls()
		local total = 0
		for _, v in ipairs(find_chaos_jokers()) do
			local ex = v.ability and v.ability.extra
			if type(ex) ~= 'number' or ex <= 0 then ex = 1 end
			total = total + ex
		end
		return total
	end

	if not rawget(_G, 'VP_CHAOS_FIND_JOKER_PATCHED') and rawget(_G, 'find_joker') then
		local old_find_joker = find_joker
		function find_joker(name, non_debuff)
			if name == 'Chaos the Clown' then return {} end
			return old_find_joker(name, non_debuff)
		end
		_G.VP_CHAOS_FIND_JOKER_PATCHED = true
	end

	if not rawget(_G, 'VP_CHAOS_NEW_ROUND_PATCHED') and rawget(_G, 'new_round') then
		local old_new_round = new_round
		function new_round()
			local ok = pcall(function() if old_new_round then old_new_round() end end)
			if not ok or not (rawget(_G, 'G') and G.E_MANAGER and G.GAME and G.GAME.current_round) then return end
			G.E_MANAGER:add_event(Event({
				trigger = 'after', delay = 0.1, func = function()
					local total = total_chaos_rerolls()
					G.GAME.current_round.free_rerolls = total
					if rawget(_G, 'calculate_reroll_cost') then calculate_reroll_cost(true) end
					return true
				end
			}))
		end
		_G.VP_CHAOS_NEW_ROUND_PATCHED = true
	end

	if not rawget(_G, 'VP_CHAOS_REMOVE_PATCHED') and rawget(_G, 'Card') and Card.remove_from_deck then
		local old_remove_from_deck = Card.remove_from_deck
		function Card:remove_from_deck(from_debuff)
			local was_chaos = self and self.ability and self.ability.name == 'Chaos the Clown'
			local ok, res = pcall(old_remove_from_deck, self, from_debuff)
			if was_chaos and rawget(_G, 'G') and G.GAME and G.GAME.current_round then
				local remaining_total = total_chaos_rerolls()
				local current_free = G.GAME.current_round.free_rerolls or 0
				if current_free < 0 then current_free = 0 end
				G.GAME.current_round.free_rerolls = math.min(remaining_total, current_free + 1)
				if rawget(_G, 'calculate_reroll_cost') then calculate_reroll_cost(true) end
			end
			if ok then return res end
		end
		_G.VP_CHAOS_REMOVE_PATCHED = true
	end

	if not rawget(_G, 'VP_CHAOS_CALC_PATCHED') and rawget(_G, 'Card') and Card.calculate_joker then
		local old_calc = Card.calculate_joker
		function Card:calculate_joker(context)
			if not self or not self.ability or self.ability.name ~= 'Chaos the Clown' then
				local ok, r = pcall(old_calc, self, context)
				if ok then return r else return end
			end
			local ok, r = pcall(function()
				if not self.ability.extra or self.ability.extra <= 0 then self.ability.extra = 1 end
				if context and context.end_of_round and not context.individual and not context.repetition and not context.game_over then
					if rawget(_G, 'G') and G.GAME and G.GAME.round_resets and G.GAME.round_resets.blind then
						local b = G.GAME.round_resets.blind
						if b and b ~= G.P_BLINDS.bl_small and b ~= G.P_BLINDS.bl_big then
							self.ability.extra = self.ability.extra + 1
							G.E_MANAGER:add_event(Event({
								trigger = 'after', delay = 0.1, func = function()
									if rawget(_G, 'G') and G.GAME and G.GAME.current_round then
										G.GAME.current_round.free_rerolls = total_chaos_rerolls()
										if rawget(_G, 'calculate_reroll_cost') then calculate_reroll_cost(true) end
									end
									return true
								end
							}))
							return { message = "+1 Reroll", colour = G.C.GREEN, card = self }
						end
					end
				end
				if context and context.selling_self then
					self.ability.extra = 1
					return
				end
				return
			end)
			if ok then return r else local ok2, r2 = pcall(old_calc, self, context); return ok2 and r2 or nil end
		end
		_G.VP_CHAOS_CALC_PATCHED = true
	end

	center.calculate = function(self, card, context)
		pcall(function()
			if not card or not card.ability then return end
			if not card.ability.extra or card.ability.extra <= 0 then card.ability.extra = 1 end
		end)
		return
	end

	return center
end