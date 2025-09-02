return function(center)
    center.config = center.config or {}
    center.config.extra = { mult = 0 }
    
    center.loc_txt = {
        name = 'Mystic Summit',
        text = {
            'Gains {C:mult}+3{} Mult when {C:attention}0{} discards',
            'remaining at end of round',
            '{C:inactive}(Currently {C:mult}+#1#{} {C:inactive}Mult)'
        }
    }
    
    center.calculate = function(self, card, context)
        card.ability = card.ability or {}
        card.ability.extra = card.ability.extra or { mult = 0 }

        if context and context.joker_main then
            local accumulated = card.ability.extra.mult or 0
            if accumulated > 0 then
                return {
                    mult_mod = accumulated,
                    message = localize{type='variable', key='a_mult', vars={accumulated}}
                }
            end
        end

        if context and context.end_of_round and not context.repetition and not context.individual then
            if not context.blueprint then
                local discards_left = G.GAME.current_round.discards_left or 0
                if discards_left == 0 then
                    local mult_to_add = 3
                    card.ability.extra.mult = (card.ability.extra.mult or 0) + mult_to_add
                end
            end
        end
        return nil
    end
    
    center.loc_vars = function(self, info_queue, card)
        local accumulated = 0
        if card and card.ability and card.ability.extra and card.ability.extra.mult then
            accumulated = card.ability.extra.mult
        end
        return { vars = { accumulated } }
    end
    
    center.set_ability = function(self, card, initial, delay_sprites)
        card.ability = card.ability or {}
        card.ability.extra = { mult = 0 }
    end
    
    if rawget(_G, 'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_mystic_summit then
        G.localization.descriptions.Joker.j_mystic_summit.text = center.loc_txt.text
    end
end
