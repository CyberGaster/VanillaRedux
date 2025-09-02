return function(center)
    
    local original_calculate_patched = false
    
    local function patch_original_calculate()
        if original_calculate_patched then return end
        
        if rawget(_G, 'Card') and Card.calculate_joker then
            local old_calculate_joker = Card.calculate_joker
            function Card:calculate_joker(context)
                if self.config and self.config.center and self.config.center.key == 'j_superposition' then
                    return superposition_new_calculate(self, context)
                end
                return old_calculate_joker(self, context)
            end
            original_calculate_patched = true
        end
    end
    
    function superposition_new_calculate(card, context)
        if not card or card.debuff then return nil end
        
        if not card.ability.extra then
            card.ability.extra = {chips = 50, mult = 50, odds = 2}
        end
        
        if context and context.joker_main then
            if pseudorandom('superposition') < ((G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal or 1) / (card.ability.extra.odds or 2)) then
                if pseudorandom('superposition_choice') < 0.5 then
                    return {
                        chip_mod = card.ability.extra.chips,
                        message = localize{type='variable', key='a_chips', vars={card.ability.extra.chips}},
                        colour = G.C.CHIPS,
                        card = card
                    }
                else
                    return {
                        mult_mod = card.ability.extra.mult,
                        message = localize{type='variable', key='a_mult', vars={card.ability.extra.mult}},
                        colour = G.C.MULT,
                        card = card
                    }
                end
            end
        end
        
        return nil
    end
    
    if SMODS and SMODS.Joker then
        patch_original_calculate()
        
        SMODS.Joker:take_ownership('superposition', {
            no_mod_display = true,
            loc_txt = {
                name = "Superposition",
                text = {
                    '{C:green}#1# in #2#{} chance to give',
                    '{C:chips}+#3#{} Chips or {C:mult}+#4#{} Mult',
                    'when hand is played'
                }
            },
            
            config = {
                extra = {chips = 50, mult = 50, odds = 2}
            },
            
            loc_vars = function(self, info_queue, card)
                local chips, mult, odds = 50, 50, 2
                
                if card and card.ability and card.ability.extra then
                    chips = card.ability.extra.chips or 50
                    mult = card.ability.extra.mult or 50
                    odds = card.ability.extra.odds or 2
                elseif self and self.config and self.config.extra then
                    chips = self.config.extra.chips or 50
                    mult = self.config.extra.mult or 50
                    odds = self.config.extra.odds or 2
                end
                
                
                return { vars = { ''..(G.GAME and G.GAME.probabilities.normal or 1), odds, chips, mult } }
            end,
            
            calculate = superposition_new_calculate,
            
            set_ability = function(self, card, initial, delay_sprites)
                card.ability.extra = card.ability.extra or {chips = 50, mult = 50, odds = 2}
                if initial then
                    self.config.extra = self.config.extra or {}
                    self.config.extra.chips = card.ability.extra.chips
                    self.config.extra.mult = card.ability.extra.mult
                    self.config.extra.odds = card.ability.extra.odds
                end
            end
        })
    else
        patch_original_calculate()
        
        if rawget(_G,'G') and G.localization and G.localization.descriptions
            and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_superposition then
            G.localization.descriptions.Joker.j_superposition.name = 'Superposition'
            G.localization.descriptions.Joker.j_superposition.text = {
                '{C:green}1 in 2{} chance to give',
                '{C:chips}+50{} Chips or {C:mult}+50{} Mult',
                'when hand is played'
            }
        end
    end
    
    if SMODS and SMODS.Hook then
        SMODS.Hook.add('post_game_init', function()
            if G.P_CENTERS.j_superposition then
                G.P_CENTERS.j_superposition.mod = nil
                G.P_CENTERS.j_superposition.modded = false
                G.P_CENTERS.j_superposition.discovered = true
                
                if G.P_CENTERS.j_superposition.calculate then
                    G.P_CENTERS.j_superposition.calculate = superposition_new_calculate
                end
            end
            patch_original_calculate()
        end)
    else
        if rawget(_G,'G') and G.P_CENTERS and G.P_CENTERS.j_superposition then
            G.P_CENTERS.j_superposition.mod = nil
            G.P_CENTERS.j_superposition.modded = false
            G.P_CENTERS.j_superposition.discovered = true
            
            if G.P_CENTERS.j_superposition.calculate then
                G.P_CENTERS.j_superposition.calculate = superposition_new_calculate
            end
        end
    end
end