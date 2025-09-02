return function(center)

	center.config = center.config or {}
	center.config.extra = center.config.extra or {
		base_threshold_pct = 30,
		max_threshold_pct = 90,
		increments = {5, 7, 8, 10, 15, 15}
	}

	center.loc_txt = {
		name = 'Mr. Bones',
		text = {
			'Prevents Death if chips scored',
			'are at least {C:attention}#1#{} of required chips',
			'After saving, increase threshold by {C:attention}#2#{}',
			'Sets money to {C:money}$0{}'
		}
	}

	center.loc_vars = function(self, info_queue, card)
		local base = tonumber(self.config and self.config.extra and self.config.extra.base_threshold_pct) or 30
		local maxp = tonumber(self.config and self.config.extra and self.config.extra.max_threshold_pct) or 90
		local incr = (self.config and self.config.extra and self.config.extra.increments) or {5,7,8,10,15,15}
		local current = base
		local step_idx = 1
		if card and card.ability and card.ability.extra then
			local cval = tonumber(card.ability.extra.threshold_pct)
			if cval then current = cval end
			local sidx = tonumber(card.ability.extra.step_idx)
			if sidx then step_idx = sidx end
		end
		if current > maxp then current = maxp end
		local next_inc = tonumber(incr[step_idx]) or 0
		if current >= maxp then next_inc = 0 end
		current = math.floor(current + 0.5)
		next_inc = math.floor(next_inc + 0.5)
		local current_str = tostring(current or 0)..'%'
		local next_inc_str = tostring(next_inc or 0)..'%'
		return { vars = { current_str, next_inc_str } }
	end

	local function _compute_loc_vars_for(card)
		local cfg = center and center.config and center.config.extra or nil
		local base = tonumber(cfg and cfg.base_threshold_pct) or 30
		local maxp = tonumber(cfg and cfg.max_threshold_pct) or 90
		local incr = (cfg and cfg.increments) or {5,7,8,10,15,15}
		local current = base
		local step_idx = 1
		if card and card.ability and card.ability.extra then
			local cval = tonumber(card.ability.extra.threshold_pct)
			if cval then current = cval end
			local sidx = tonumber(card.ability.extra.step_idx)
			if sidx then step_idx = sidx end
		end
		if current > maxp then current = maxp end
		local next_inc = tonumber(incr[step_idx]) or 0
		if current >= maxp then next_inc = 0 end
		current = math.floor(current + 0.5)
		next_inc = math.floor(next_inc + 0.5)
		local current_str = tostring(current or 0)..'%'
		local next_inc_str = tostring(next_inc or 0)..'%'
		return { vars = { current_str, next_inc_str } }
	end

	local orig_set_ability = center.set_ability
	center.set_ability = function(self, card, initial, delay_sprites)
		if orig_set_ability then orig_set_ability(self, card, initial, delay_sprites) end
		card.ability = card.ability or {}
		card.ability.extra = card.ability.extra or {}
		local cfg = center.config and center.config.extra or {}
		if card.ability.extra.threshold_pct == nil then
			card.ability.extra.threshold_pct = cfg.base_threshold_pct or 30
		end
		if card.ability.extra.step_idx == nil then
			card.ability.extra.step_idx = 1
		end
		card.ability.extra.max_pct = cfg.max_threshold_pct or 90
		card.ability.extra.increments = card.ability.extra.increments or (cfg.increments or {5,7,8,10,15,15})

		if rawget(_G,'G') and G.GAME and G.GAME._vp_mr_bones_state then
			local st = G.GAME._vp_mr_bones_state
			if tonumber(st.threshold) then
				card.ability.extra.threshold_pct = math.min(tonumber(st.threshold) or card.ability.extra.threshold_pct, card.ability.extra.max_pct or 90)
			end
			if tonumber(st.step) then
				card.ability.extra.step_idx = tonumber(st.step) or card.ability.extra.step_idx
			end
		end
	end

	if rawget(_G,'G') and G.localization and G.localization.descriptions and G.localization.descriptions.Joker then
		G.localization.descriptions.Joker.j_mr_bones = G.localization.descriptions.Joker.j_mr_bones or {}
		G.localization.descriptions.Joker.j_mr_bones.name = center.loc_txt.name
		G.localization.descriptions.Joker.j_mr_bones.text = center.loc_txt.text
		G.localization.descriptions.Joker.j_mr_bones.loc_vars = function(_self, info_queue, card)
			return _compute_loc_vars_for(card)
		end
	end

	if SMODS and SMODS.Joker then
		SMODS.Joker:take_ownership('mr_bones', {
			no_mod_display = true,
			loc_txt = { name = center.loc_txt.name, text = center.loc_txt.text },
			loc_vars = function(self, info_queue, card)
				return _compute_loc_vars_for(card)
			end,
		})
	end

	local function normalize_center_tags()
		if rawget(_G,'G') and G.localization and G.localization.descriptions
			and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_mr_bones then
			G.localization.descriptions.Joker.j_mr_bones.name = center.loc_txt.name
			G.localization.descriptions.Joker.j_mr_bones.text = center.loc_txt.text
			G.localization.descriptions.Joker.j_mr_bones.loc_vars = function(_self, info_queue, card)
				return _compute_loc_vars_for(card)
			end
		end
		if rawget(_G,'G') and G.P_CENTERS and G.P_CENTERS.j_mr_bones then
			local c = G.P_CENTERS.j_mr_bones
			c.mod = nil; c.mod_id = nil; c.modded = false; c.no_mod_display = true; c.discovered = true
		end
	end

	if SMODS and SMODS.Hook then
		SMODS.Hook.add('post_game_init', function()
			normalize_center_tags()
		end)
	else
		if rawget(_G,'G') then normalize_center_tags() end
	end

	if not rawget(_G,'VP_MR_BONES_LOCVARS_PATCHED') and rawget(_G,'Card') and Card.generate_UIBox_ability_table then
		local old_generate_UIBox = Card.generate_UIBox_ability_table
		function Card:generate_UIBox_ability_table()
			local is_bones = self and self.ability and self.ability.name == 'Mr. Bones'
			if not is_bones and self and self.config and self.config.center and self.config.center.key == 'j_mr_bones' then
				is_bones = true
			end
			if is_bones then
				if rawget(_G,'G') and G.localization and G.localization.descriptions and G.localization.descriptions.Joker then
					local cfg = center and center.config and center.config.extra or nil
					local base = tonumber(cfg and cfg.base_threshold_pct) or 30
					local maxp = tonumber(cfg and cfg.max_threshold_pct) or 90
					local incr = (cfg and cfg.increments) or {5,7,8,10,15,15}
					local function compute_vars(card)
						local current = base
						local step_idx = 1
						if card and card.ability and card.ability.extra then
							local cval = tonumber(card.ability.extra.threshold_pct)
							if cval then current = cval end
							local sidx = tonumber(card.ability.extra.step_idx)
							if sidx then step_idx = sidx end
						end
						if current > maxp then current = maxp end
						local next_inc = tonumber(incr[step_idx]) or 0
						if current >= maxp then next_inc = 0 end
						current = math.floor(current + 0.5)
						next_inc = math.floor(next_inc + 0.5)
						local current_str = tostring(current or 0)..'%'
						local next_inc_str = tostring(next_inc or 0)..'%'
						return { vars = { current_str, next_inc_str } }
					end
					local entry = G.localization.descriptions.Joker.j_mr_bones or {}
					entry.name = center.loc_txt.name
					entry.text = center.loc_txt.text
					entry.loc_vars = function(_self, info_queue, _card)
						return compute_vars(self)
					end
					G.localization.descriptions.Joker.j_mr_bones = entry
				end
			end
			return old_generate_UIBox(self)
		end
		_G.VP_MR_BONES_LOCVARS_PATCHED = true
	end

	if not rawget(_G,'VP_MR_BONES_PATCHED') and rawget(_G,'Card') and Card.calculate_joker then
		local old_calculate_joker = Card.calculate_joker
		local function _to_number(x)
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
		function Card:calculate_joker(context)
			if self.ability and self.ability.name == 'Mr. Bones' and not self.debuff and context and context.game_over then
				local chips = rawget(_G,'G') and G.GAME and G.GAME.chips or 0
				local blind_chips = (rawget(_G,'G') and G.GAME and G.GAME.blind and G.GAME.blind.chips) or 1
				local chips_n = _to_number(chips)
				local blind_n = _to_number(blind_chips)
				if blind_n <= 0 then blind_n = 1 end

				self.ability.extra = self.ability.extra or {}
				local threshold_pct = tonumber(self.ability.extra.threshold_pct) or 30
				local max_pct = tonumber(self.ability.extra.max_pct) or 90
				local ratio = (chips_n / blind_n)

				if ratio >= (threshold_pct * 0.01) then
					self.ability._vp_prevent_vanilla = true
					local original_start_dissolve = self.start_dissolve
					self.start_dissolve = function() return true end
					G.E_MANAGER:add_event(Event({
						func = function()
							if rawget(_G,'G') and G.hand_text_area then
								G.hand_text_area.blind_chips:juice_up()
								G.hand_text_area.game_chips:juice_up()
							end
							play_sound('tarot1')
							if rawget(_G,'G') and G.GAME and G.GAME.dollars and G.GAME.dollars ~= 0 then
								if rawget(_G,'ease_dollars') then
									ease_dollars(-G.GAME.dollars, true)
								else
									G.GAME.dollars = 0
								end
							end
							return true
						end
					}))
					G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0, blockable = false, func = function()
						self.start_dissolve = original_start_dissolve
						G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.5, blockable = false, func = function()
							if self and self.ability then self.ability._vp_prevent_vanilla = nil end
							return true
						end}))
						return true
					end}))

					local increments = self.ability.extra.increments or {5,7,8,10,15,15}
					local step_idx = tonumber(self.ability.extra.step_idx or 1) or 1
					local inc_val = tonumber(increments[step_idx] or 0) or 0
					local new_threshold = threshold_pct + inc_val
					if new_threshold > max_pct then new_threshold = max_pct end
					self.ability.extra.threshold_pct = new_threshold
					self.ability.extra.step_idx = step_idx + 1

					return {
						message = localize('k_saved_ex'),
						saved = true,
						colour = G.C.RED
					}
				end
				return nil
			end

			if self.ability and self.ability.name == 'Mr. Bones' and context and context.selling_self then
				self.ability.extra = self.ability.extra or {}
				local max_pct = tonumber(self.ability.extra.max_pct) or 90
				local thr = tonumber(self.ability.extra.threshold_pct) or (center and center.config and center.config.extra and center.config.extra.base_threshold_pct) or 30
				if thr > max_pct then thr = max_pct end
				local step = tonumber(self.ability.extra.step_idx) or 1

				if rawget(_G,'G') then
					G.GAME = G.GAME or {}
					G.GAME._vp_mr_bones_state = { threshold = thr, step = step }
					if G.P_CENTERS and G.P_CENTERS.j_mr_bones then
						G.P_CENTERS.j_mr_bones.config = G.P_CENTERS.j_mr_bones.config or {}
						G.P_CENTERS.j_mr_bones.config.extra = G.P_CENTERS.j_mr_bones.config.extra or {}
						G.P_CENTERS.j_mr_bones.config.extra.base_threshold_pct = thr
					end
				end
				return nil
			end
			return old_calculate_joker(self, context)
		end
		_G.VP_MR_BONES_PATCHED = true
	end

	if not rawget(_G,'VP_MR_BONES_DISSOLVE_GUARD') and rawget(_G,'Card') and Card.start_dissolve then
		local _orig_start_dissolve = Card.start_dissolve
		function Card:start_dissolve(dissolve_colours, silent, dissolve_time_fac, no_juice)
			if self and self.ability and self.ability.name == 'Mr. Bones' and self.ability._vp_prevent_vanilla then
				return true
			end
			return _orig_start_dissolve(self, dissolve_colours, silent, dissolve_time_fac, no_juice)
		end
		_G.VP_MR_BONES_DISSOLVE_GUARD = true
	end

end