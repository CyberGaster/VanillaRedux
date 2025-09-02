return function(center)

	center.config = center.config or {}
	center.config.extra = center.config.extra or 0.2

	center.loc_txt = center.loc_txt or {}
	center.loc_txt.name = 'Steel Joker'
	center.loc_txt.text = {
		'Steel card gives {X:mult,C:white}X1.75{} Mult', 
		'Gives {X:mult,C:white}X#1#{} Mult',
		'for each {C:attention}Steel Card{}',
		'in your {C:attention}full deck',
		'{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)'
	}

	if not rawget(_G, 'VP_STEELJOKER_PATCHED_HX') and rawget(_G, 'Card') and Card.get_chip_h_x_mult then
		local old_get_chip_h_x_mult = Card.get_chip_h_x_mult
		function Card:get_chip_h_x_mult()
			local base_value = old_get_chip_h_x_mult(self)
			if not self.debuff and self.config and self.config.center == (rawget(_G,'G') and G.P_CENTERS and G.P_CENTERS.m_steel) then
				local has_steel_joker = rawget(_G, 'find_joker') and (#find_joker('Steel Joker', true) > 0)
				if has_steel_joker then
					return 1.75
				end
			end
			return base_value
		end
		_G.VP_STEELJOKER_PATCHED_HX = true
	end

	if rawget(_G,'G') and G.localization and G.localization.descriptions
		and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_steel_joker then
		G.localization.descriptions.Joker.j_steel_joker.text = center.loc_txt.text
	end
end