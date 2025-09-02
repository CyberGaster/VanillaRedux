return function()
    
    local XMULT_PER_HEART = 1.5
    local BOSS_REWARD     = 12

    SMODS.Joker:take_ownership('matador', {
        no_mod_display = true,
        
        loc_txt = {
            name = 'Matador',
            text = {
                '{X:mult,C:white}X#1#{} for each played',
                '{C:hearts}Heart{} card if {C:attention}Boss Blind{}',
                'is selected. Earn {C:money}$#2#{} when',
                '{C:attention}Boss Blind{} is defeated'
            }
        },
        
        config = {
            extra            = BOSS_REWARD,
            xmult_per_heart  = XMULT_PER_HEART
        },

        loc_vars = function(self, _info, card)
            local xmult  = XMULT_PER_HEART
            local reward = BOSS_REWARD
            if card and card.ability then
                xmult  = card.ability.xmult_per_heart or xmult
                reward = card.ability.extra            or reward
            end
            return { vars = { xmult, reward } }
        end, 
    })

    if G.P_CENTERS and G.P_CENTERS.j_matador then
        G.P_CENTERS.j_matador.mod = nil
        G.P_CENTERS.j_matador.mod_id = nil
        G.P_CENTERS.j_matador.modded = false
        G.P_CENTERS.j_matador.discovered = true
        G.P_CENTERS.j_matador.no_mod_display = true
    end

    if not rawget(_G, 'VR_PATCHED_MATADOR') and rawget(_G, 'Card') and Card.calculate_joker then
        _G.VR_PATCHED_MATADOR = true

        local base_calculate_joker = Card.calculate_joker

        function Card:calculate_joker(context)
            
            if self.ability and self.ability.name == 'Matador' and not self.debuff then
                
                if self.ability.xmult_per_heart == nil then
                    self.ability.xmult_per_heart = XMULT_PER_HEART
                end
                if type(self.ability.extra) ~= 'number' then
                    self.ability.extra = BOSS_REWARD
                end

                if context.setting_blind and G.GAME.blind:get_type() == 'Boss' then
                    self._vr_boss_defeated = false
                    return {
                        message = localize('k_active_ex'),
                        colour  = G.C.FILTER,
                        card    = self
                    }
                end

                if context.end_of_round and not context.individual and not context.repetition and not context.game_over then
                    if G.GAME.blind:get_type() == 'Boss' then
                        
                        if context.blueprint and context.blueprint_card then
                            local copier = context.blueprint_card
                            if copier and copier.ability and copier.ability.set == 'Joker' then
                                local current_round = (G and G.GAME and G.GAME.round) or 0
                                if copier.ability.name == 'Abstract Joker' then
                                    if copier.ability._abs_matador_round ~= current_round then
                                        copier.ability._abs_matador_round = current_round
                                        copier.ability._abstract_matador_pending = (copier.ability._abstract_matador_pending or 0) + (self.ability.extra or 0)
                                    end
                                else
                                    if copier._vr_bp_matador_mark_round ~= current_round then
                                        copier._vr_bp_matador_mark_round = current_round
                                        copier._vr_bp_matador_reward_pending = (copier._vr_bp_matador_reward_pending or 0) + (self.ability.extra or 0)
                                    end
                                end
                            end
                        end
                        
                        if not self._vr_boss_defeated then
                            self._vr_boss_defeated = true
                            self._vr_boss_reward_pending = true
                        end
                        
                    end
                end

                if context.individual and context.cardarea == G.play and G.GAME.blind:get_type() == 'Boss' then
                    local c = context.other_card
                    if c and c:is_suit('Hearts', nil, true) and not c.debuff then
                        return {
                            x_mult = self.ability.xmult_per_heart
                        }
                    end
                end

                
                return nil
            end
            return base_calculate_joker(self, context)
        end
    end
    
    if not rawget(_G, 'VR_PATCHED_MATADOR_DOLLARS') and rawget(_G, 'Card') and Card.calculate_dollar_bonus then
        _G.VR_PATCHED_MATADOR_DOLLARS = true
        local base_calculate_dollar_bonus = Card.calculate_dollar_bonus
        function Card:calculate_dollar_bonus()
            if self.ability and self.ability.set == 'Joker' and not self.debuff then
                
                if self.ability.name == 'Matador' and self._vr_boss_reward_pending then
                    self._vr_boss_reward_pending = nil
                    return self.ability.extra
                end
                
                if self.ability.name == 'Abstract Joker' and self.ability._abstract_matador_pending then
                    local amt = self.ability._abstract_matador_pending
                    self.ability._abstract_matador_pending = nil
                    return amt
                end
                
                if self._vr_bp_matador_reward_pending then
                    local amt = self._vr_bp_matador_reward_pending
                    self._vr_bp_matador_reward_pending = nil
                    return amt
                end
            end
            return base_calculate_dollar_bonus(self)
        end
    end
    
    if SMODS and SMODS.Hook then
        SMODS.Hook:register_hook('init_game_object', function()
            if G.P_CENTERS.j_matador then
                G.P_CENTERS.j_matador.mod        = nil
                G.P_CENTERS.j_matador.mod_id     = nil
                G.P_CENTERS.j_matador.modded     = false
                G.P_CENTERS.j_matador.discovered = true
            end
        end)
    end
end