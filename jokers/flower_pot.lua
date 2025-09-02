return function(center)

	local function count_unique_suits(scoring_hand)
		if not scoring_hand or #scoring_hand == 0 then return 0 end
		local suits = {Hearts = 0, Diamonds = 0, Spades = 0, Clubs = 0}

		for i = 1, #scoring_hand do
			local c = scoring_hand[i]
			if c and c.ability and c.ability.name ~= 'Wild Card' and not c.debuff then
				if c:is_suit('Hearts') and suits.Hearts == 0 then suits.Hearts = 1 end
				if c:is_suit('Diamonds') and suits.Diamonds == 0 then suits.Diamonds = 1 end
				if c:is_suit('Spades') and suits.Spades == 0 then suits.Spades = 1 end
				if c:is_suit('Clubs') and suits.Clubs == 0 then suits.Clubs = 1 end
			end
		end

		for i = 1, #scoring_hand do
			local c = scoring_hand[i]
			if c and c.ability and c.ability.name == 'Wild Card' and not c.debuff then
				if c:is_suit('Hearts') and suits.Hearts == 0 then
					suits.Hearts = 1
				elseif c:is_suit('Diamonds') and suits.Diamonds == 0 then
					suits.Diamonds = 1
				elseif c:is_suit('Spades') and suits.Spades == 0 then
					suits.Spades = 1
				elseif c:is_suit('Clubs') and suits.Clubs == 0 then
					suits.Clubs = 1
				end
			end
		end

		return (suits.Hearts + suits.Diamonds + suits.Spades + suits.Clubs)
	end

	center.loc_txt = center.loc_txt or {}
	center.loc_txt.name = 'Flower Pot'
	center.loc_txt.text = {
		'{X:mult,C:white}X1.5{} if poker hand contains',
		'{C:attention}2{} unique {C:attention}suits{} when scored',
		'{X:mult,C:white}X2.75{} if {C:attention}3{} unique {C:attention}suits{}',
		'{X:mult,C:white}X4{} if {C:attention}4{} unique {C:attention}suits{}'
	}

	if rawget(_G,'G') and G.localization and G.localization.descriptions
		and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_flower_pot then
		G.localization.descriptions.Joker.j_flower_pot.text = center.loc_txt.text
	end

	local orig_calculate = center.calculate
	center.calculate = function(self, card, context)
		if context and context.joker_main then
			local unique_count = count_unique_suits(context.scoring_hand)
			local mult = nil
			if unique_count == 2 then
				mult = 1.5
			elseif unique_count == 3 then
				mult = 2.75
			elseif unique_count >= 4 then
				mult = 4
			end
			if mult then
				return { x_mult = mult, card = card }
			end
		end
		return orig_calculate and orig_calculate(self, card, context) or nil
	end

end