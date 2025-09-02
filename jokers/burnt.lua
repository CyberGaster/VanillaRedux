return function(center)

	local function to_num(v)
		if type(v) == 'number' then return v end
		if type(v) == 'string' then local n = tonumber(v); if n then return n end end
		if type(v) == 'table' then
			if type(v.toNumber) == 'function' then local ok,res = pcall(v.toNumber, v); if ok and type(res) == 'number' then return res end end
			if type(v.tonumber) == 'function' then local ok,res = pcall(v.tonumber, v); if ok and type(res) == 'number' then return res end end
			if type(v.to_number) == 'function' then local ok,res = pcall(v.to_number, v); if ok and type(res) == 'number' then return res end end
			if type(v.value) == 'number' then return v.value end
			if type(v.val) == 'number' then return v.val end
			if type(v.chips) == 'number' then return v.chips end
			local mt = getmetatable(v)
			if mt and type(mt.__tostring) == 'function' then local s = tostring(v); local n = tonumber(s); if n then return n end end
			if type(v.tostring) == 'function' then local ok, s = pcall(v.tostring, v); if ok then local n = tonumber(s); if n then return n end end end
			if type(v.toString) == 'function' then local ok, s = pcall(v.toString, v); if ok then local n = tonumber(s); if n then return n end end end
		end
		return 0
	end

	local function try_wrap_update_hand_text()
		if rawget(_G,'VP_BURNT_UHT_WRAPPED') then return end
		if type(rawget(_G,'update_hand_text')) ~= 'function' then return end
		_G.VP_BURNT_UHT_WRAPPED = true
		local _old = update_hand_text
		update_hand_text = function(config, vals)
			if vals and vals.chip_total ~= nil and rawget(_G,'G') and G.GAME then
				G.GAME._vp_burnt_chip_total = to_num(vals.chip_total)
			end
			return _old(config, vals)
		end
	end

	center.loc_txt = center.loc_txt or {}
	center.loc_txt.name = 'Burnt Joker'
	center.loc_txt.text = {
        "Upgrade the level of the {C:attention}played hand{}",
        "when score is {C:red}burning{}"
	}

	local function current_hand_id() return (rawget(_G,'G') and G.GAME and G.GAME.hands_played) or 0 end
	local function blind_required() local req = (rawget(_G,'G') and G.GAME and G.GAME.blind and G.GAME.blind.chips) or math.huge; return to_num(req) end
	local function base_earned_for(hand_name)
		if not (rawget(_G,'G') and G.GAME and G.GAME.hands and G.GAME.hands[hand_name]) then return 0 end
		local h = G.GAME.hands[hand_name]
		local chips_raw = (rawget(_G,'mod_chips') and mod_chips(h.chips)) or h.chips
		local mult_raw  = (rawget(_G,'mod_mult') and mod_mult(h.mult)) or h.mult
		local chips = to_num(chips_raw)
		local mult  = to_num(mult_raw)
		return math.floor(chips * mult)
	end
	local function final_chip_total()
		local cr = rawget(_G,'G') and G.GAME and G.GAME.current_round and G.GAME.current_round.current_hand
		return cr and to_num(cr.chip_total) or 0
	end

	local orig_calc = center.calculate
	center.calculate = function(self, card, context)
		if not card or card.debuff then return orig_calc and orig_calc(self, card, context) or nil end
		try_wrap_update_hand_text()
		card.ability = card.ability or {}
		card.ability._vp_burnt = card.ability._vp_burnt or {}
		if context and context.setting_blind then
			card.ability._vp_burnt = { _hand_id = current_hand_id(), done = false }
			return orig_calc and orig_calc(self, card, context) or nil
		end
		local ses = card.ability._vp_burnt
		if not ses or ses._hand_id ~= current_hand_id() then card.ability._vp_burnt = { _hand_id = current_hand_id(), done = false }; ses = card.ability._vp_burnt end
		if context and context.before and context.scoring_name and not ses.done then
			local earned, req = base_earned_for(context.scoring_name), blind_required()
			if to_num(earned) >= to_num(req) and to_num(req) > 0 then ses.done = true; return {level_up = true, message = localize('k_upgrade_ex'), card = card} end
		end
		if context and context.after and context.scoring_name and not ses.done then
			local hand_name = context.scoring_name
			if rawget(_G,'G') and G.E_MANAGER and rawget(_G,'Event') then
				G.E_MANAGER:add_event(Event({
					trigger = 'after', delay = 0.62,
					func = function()
						local req = blind_required()
						local ct = to_num((rawget(_G,'G') and G.GAME and G.GAME._vp_burnt_chip_total) or 0); if ct == 0 then ct = final_chip_total() end
						local _ses = card.ability and card.ability._vp_burnt
						if _ses and not _ses.done and to_num(req) > 0 and to_num(ct) >= to_num(req) then
							_ses.done = true
							if rawget(_G,'update_hand_text') and rawget(_G,'G') and G.GAME and G.GAME.hands and G.GAME.hands[hand_name] then
								local h = G.GAME.hands[hand_name]
								update_hand_text({sound = 'button', volume = 0.7, pitch = 0.8, delay = 0}, {handname = localize(hand_name, 'poker_hands'), chips = h.chips, mult = h.mult, level = h.level})
							end
							if rawget(_G,'level_up_hand') then level_up_hand(card, hand_name) end
							if rawget(_G,'G') and G.E_MANAGER and rawget(_G,'Event') then
								G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 1.35, func = function() if rawget(_G,'update_hand_text') then update_hand_text({immediate = true, delay = 0}, {mult = 0, chips = 0, handname = '', level = ''}) end; return true end }))
							end
						end
						return true
					end
				}))
			end
		end
		return orig_calc and orig_calc(self, card, context) or nil
	end

	if not rawget(_G,'VP_BURNT_REWORKED') and rawget(_G,'Card') and Card.calculate_joker then
		_G.VP_BURNT_REWORKED = true
		local base_calculate_joker = Card.calculate_joker
		function Card:calculate_joker(context)
			if self.ability and self.ability.name == 'Burnt Joker' and not self.debuff then
				try_wrap_update_hand_text()
				self.ability._vp_burnt = self.ability._vp_burnt or { _hand_id = current_hand_id(), done = false }
				local ses = self.ability._vp_burnt
				if context and context.setting_blind then self.ability._vp_burnt = { _hand_id = current_hand_id(), done = false }; return nil end
				if not ses or ses._hand_id ~= current_hand_id() then self.ability._vp_burnt = { _hand_id = current_hand_id(), done = false }; ses = self.ability._vp_burnt end
				if context and context.pre_discard and not (context and context.hook) then return nil end
				if context and context.before and context.scoring_name and not ses.done then
					local earned, req = base_earned_for(context.scoring_name), blind_required()
					if to_num(earned) >= to_num(req) and to_num(req) > 0 then ses.done = true; return { level_up = true, message = localize('k_upgrade_ex') } end
				end
				if context and context.after and context.scoring_name and not ses.done then
					local hand_name = context.scoring_name
					if rawget(_G,'G') and G.E_MANAGER and rawget(_G,'Event') then
						G.E_MANAGER:add_event(Event({
							trigger = 'after', delay = 0.62,
							func = function()
								local req = blind_required()
								local ct = to_num((rawget(_G,'G') and G.GAME and G.GAME._vp_burnt_chip_total) or 0); if ct == 0 then ct = final_chip_total() end
								local _ses = self.ability and self.ability._vp_burnt
								if _ses and not _ses.done and to_num(req) > 0 and to_num(ct) >= to_num(req) then
									_ses.done = true
									if rawget(_G,'update_hand_text') and rawget(_G,'G') and G.GAME and G.GAME.hands and G.GAME.hands[hand_name] then
										local h = G.GAME.hands[hand_name]
										update_hand_text({sound = 'button', volume = 0.7, pitch = 0.8, delay = 0}, {handname = localize(hand_name, 'poker_hands'), chips = h.chips, mult = h.mult, level = h.level})
									end
									if rawget(_G,'level_up_hand') then level_up_hand(self, hand_name) end
									G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 1.35, func = function() if rawget(_G,'update_hand_text') then update_hand_text({immediate = true, delay = 0}, {mult = 0, chips = 0, handname = '', level = ''}) end; return true end }))
								end
								return true
							end
						}))
					end
					return nil
				end
				return nil
			end
			return base_calculate_joker(self, context)
		end
	end

	if rawget(_G,'G') and G.localization and G.localization.descriptions and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_burnt then
		G.localization.descriptions.Joker.j_burnt.name = center.loc_txt.name
		G.localization.descriptions.Joker.j_burnt.text = center.loc_txt.text
	end

end