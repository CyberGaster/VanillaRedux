return function(center)
	center.blueprint_compat = true

	local function is_number_card(card)
		if not card or not card.base then return false end
		local rank_id = card.base.id
		return rank_id and rank_id >= 2 and rank_id <= 10
	end

	local function is_face_card(card)
		if not card or not card.base then return false end
		local rank_id = card.base.id
		return rank_id == 11 or rank_id == 12 or rank_id == 13
	end

	local function active_faceless()
		if G and G.jokers and G.jokers.cards then
			for i = 1, #G.jokers.cards do
				local joker = G.jokers.cards[i]
				if joker and joker.config and joker.config.center and joker.config.center.key == 'j_faceless' and not joker.debuff then
					return joker
				end
			end
		end
		return nil
	end

	if G and rawget(_G,'Blind') and not Blind._faceless_debuff_wrapped then
		local _original_debuff_card = Blind.debuff_card
		Blind.debuff_card = function(self, c, from_blind)
			_original_debuff_card(self, c, from_blind)
			local faceless = active_faceless()
			if faceless and c and c.area ~= G.jokers and is_face_card(c) then
				c:set_debuff(true)
			end
		end
		Blind._faceless_debuff_wrapped = true
	end


	SMODS.Joker:take_ownership('faceless', {
		no_mod_display = true,
		loc_txt = {
			name = "Faceless Joker",
			text = {
				"All {C:attention}face cards{} are {C:attention}debuffed{}",
				"{C:green}#1# in #2#{} chance earn {C:money}$1{}",
				"for each {C:attention}number cards{}",
				"{C:green}#3# in #4#{} chance retrigger",
				"each played {C:attention}number cards{}"
			}
		},
		cost = 5,
		rarity = 2,
		config = { extra = { odds_dollar = 3, odds_retrigger = 6 } },
		loc_vars = function(self, info_queue, card)
			local odds_dollar = 3
			local odds_retrigger = 6
			if card and card.ability and card.ability.extra then
				odds_dollar = card.ability.extra.odds_dollar or 3
				odds_retrigger = card.ability.extra.odds_retrigger or 6
			elseif self and self.config and self.config.extra then
				odds_dollar = self.config.extra.odds_dollar or 3
				odds_retrigger = self.config.extra.odds_retrigger or 6
			end
			local numerator = ''..(G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal or 1)
			return { vars = { numerator, odds_dollar, numerator, odds_retrigger } }
		end,
		calculate = function(self, card, context)
			card.ability.extra = card.ability.extra or {}
			if not card.ability.extra.odds_dollar then card.ability.extra.odds_dollar = 3 end
			if not card.ability.extra.odds_retrigger then card.ability.extra.odds_retrigger = 6 end

			if context.individual and context.cardarea == G.play then
				local played_card = context.other_card
				if played_card and is_number_card(played_card) and not played_card.debuff then
					local source_card = (context and context.blueprint_card) or card
					local hand_mark = tostring((G.GAME and G.GAME.round) or 0)..'_'..tostring((G.GAME and G.GAME.current_round and G.GAME.current_round.hands_played) or 0)
					local seed = 'faceless_$'..hand_mark..'_'..tostring(played_card.unique_val or 0)..'_'..tostring((source_card and source_card.unique_val) or 'src')
					if pseudorandom(pseudoseed(seed)) < ((G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal or 1) / (card.ability.extra.odds_dollar or 3)) then
						G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + 1
						G.E_MANAGER:add_event(Event({func = (function() G.GAME.dollar_buffer = 0; return true end)}))
						return { dollars = 1, card = source_card }
					end
				end
			end

			if context.repetition and context.cardarea == G.play and context.other_card then
				local played_card = context.other_card
				if is_number_card(played_card) and not played_card.debuff then
					local source_card = (context and context.blueprint_card) or card
					local hand_mark = tostring((G.GAME and G.GAME.round) or 0)..'_'..tostring((G.GAME and G.GAME.current_round and G.GAME.current_round.hands_played) or 0)
					local seed = 'faceless_rep'..hand_mark..'_'..tostring(played_card.unique_val or 0)..'_'..tostring((source_card and source_card.unique_val) or 'src')
					if pseudorandom(pseudoseed(seed)) < ((G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal or 1) / (card.ability.extra.odds_retrigger or 6)) then
						return { message = localize('k_again_ex'), repetitions = 1, card = source_card }
					end
				end
			end
		end,
		set_ability = function(self, card, initial, delay_sprites)
			card.ability.extra = card.ability.extra or {}
			if initial then
				card.ability.extra.odds_dollar = 3
				card.ability.extra.odds_retrigger = 6
				self.config.extra.odds_dollar = card.ability.extra.odds_dollar
				self.config.extra.odds_retrigger = card.ability.extra.odds_retrigger
				if G and G.GAME and G.GAME.blind and G.playing_cards then
					for _, v in ipairs(G.playing_cards) do
						G.GAME.blind:debuff_card(v)
					end
					if G.hand and G.hand.cards then
						for _, v in ipairs(G.hand.cards) do
							G.GAME.blind:debuff_card(v)
						end
					end
				end
			end
		end
	})

	if SMODS and SMODS.Hook then
		SMODS.Hook.add('post_game_init', function()
			if G.P_CENTERS and G.P_CENTERS.j_faceless then
				G.P_CENTERS.j_faceless.mod = nil
				G.P_CENTERS.j_faceless.mod_id = nil
				G.P_CENTERS.j_faceless.modded = false
				G.P_CENTERS.j_faceless.discovered = true
			end
		end)
	else
		if G.P_CENTERS and G.P_CENTERS.j_faceless then
			G.P_CENTERS.j_faceless.mod = nil
			G.P_CENTERS.j_faceless.mod_id = nil
			G.P_CENTERS.j_faceless.modded = false
			G.P_CENTERS.j_faceless.discovered = true
		end
	end
end
