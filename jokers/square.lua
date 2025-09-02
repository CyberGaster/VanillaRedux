return function(center)
    
    center.config = {extra = {mult = 0, mult_mod = 4}}
    center.rarity = 1
    center.cost = 4
    center.discovered = true
    
    center.loc_txt = {
        name = "Square Joker",
        text = {
            "This Joker gains {C:mult}+#2#{} Mult",
            "if played hand has",
            "exactly {C:attention}4{} cards",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        }
    }
    
    center.loc_vars = function(self, info_queue, card)
        local mult = 0
        local mult_mod = 4
        
        if card and card.ability and card.ability.extra then
            mult = card.ability.extra.mult or 0
            mult_mod = card.ability.extra.mult_mod or 4
        elseif self and self.extra then
            mult = self.extra.mult or 0
            mult_mod = self.extra.mult_mod or 4
        end
        
        return { vars = { mult, mult_mod } }
    end
    
    local original_set_ability = center.set_ability
    center.set_ability = function(self, card, initial, delay_sprites)
        if original_set_ability then
            original_set_ability(self, card, initial, delay_sprites)
        end
        
        card.ability = card.ability or {}
        card.ability.extra = card.ability.extra or {}
        card.ability.extra.mult = card.ability.extra.mult or 0
        card.ability.extra.mult_mod = card.ability.extra.mult_mod or 4
        
        card.ability.extra.chips = nil
        card.ability.extra.chip_mod = nil
    end
    
    if not rawget(_G,'VP_SQUARE_BLOCKED') and rawget(_G,'Card') and Card.calculate_joker then
        local old_calculate_joker = Card.calculate_joker
        function Card:calculate_joker(context)
            if self.ability and self.ability.name == 'Square Joker' and not self.debuff 
               and context and context.cardarea == G.jokers then
               
                self.ability.extra = self.ability.extra or {}
                self.ability.extra.mult = self.ability.extra.mult or 0
                self.ability.extra.mult_mod = self.ability.extra.mult_mod or 4
                
                if context.before then
                    if context.full_hand and #context.full_hand == 4 and not context.blueprint then
                        self.ability.extra.mult = self.ability.extra.mult + self.ability.extra.mult_mod
                        return {
                            message = localize('k_upgrade_ex'),
                            colour = G.C.MULT,
                            card = self
                        }
                    end
                elseif context.joker_main then
                    if self.ability.extra.mult > 0 then
                        return {
                            mult_mod = self.ability.extra.mult,
                            message = localize{type='variable', key='a_mult', vars={self.ability.extra.mult}}
                        }
                    end
                end
                
                return nil
            end
            
            return old_calculate_joker(self, context)
        end
        _G.VP_SQUARE_BLOCKED = true
    end
    
    if not rawget(_G,'VP_SQUARE_LOCVARS_PATCHED') and rawget(_G,'Card') and Card.generate_UIBox_ability_table then
        local old_generate_UIBox = Card.generate_UIBox_ability_table
        function Card:generate_UIBox_ability_table()
            if self.ability and self.ability.name == 'Square Joker' then
                self.ability.extra = self.ability.extra or {}
                self.ability.extra.mult = self.ability.extra.mult or 0
                self.ability.extra.mult_mod = self.ability.extra.mult_mod or 4
                self.ability.extra.chips = self.ability.extra.mult
                self.ability.extra.chip_mod = self.ability.extra.mult_mod
                
                local result = old_generate_UIBox(self)
                
                self.ability.extra.chips = nil
                self.ability.extra.chip_mod = nil
                
                return result
            end
            return old_generate_UIBox(self)
        end
        _G.VP_SQUARE_LOCVARS_PATCHED = true
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_square then
        G.localization.descriptions.Joker.j_square.text = center.loc_txt.text
    end
end
