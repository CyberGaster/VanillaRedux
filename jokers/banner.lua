return function(center)
    
    center.config = {
        extra = 0
    }
    
    center.loc_txt = {
        name = 'Banner',
        text = {
            'Gains {C:chips}+5{} Chips per remaining',
            '{C:discard}discard{} at end of round',
            '{C:inactive}(Currently {C:chips}+#1#{} {C:inactive}Chips)'
        }
    }
    
    center.calculate = function(self, card, context)
        if card.ability.extra == nil then
            card.ability.extra = 0
        end

        if context and context.joker_main then
            local accumulated = card.ability.extra or 0
            if accumulated > 0 then
                return {
                    chip_mod = accumulated,
                    message = localize{type='variable', key='a_chips', vars={accumulated}} .. ' Chips'
                }
            else
                return {
                    chip_mod = 0
                }
            end
        end

        if context and context.end_of_round and not context.repetition and not context.individual then
            if not context.blueprint then
                local discards_left = G.GAME.current_round.discards_left or 0
                if discards_left > 0 then
                    local chips_to_add = discards_left * 5
                    card.ability.extra = (card.ability.extra or 0) + chips_to_add
                end
            end
        end
        return nil
    end
    
    center.loc_vars = function(self, info_queue, card)
        local accumulated = (card and card.ability and card.ability.extra) or 0
        return { vars = { accumulated } }
    end
    
    if rawget(_G, 'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_banner then
        G.localization.descriptions.Joker.j_banner.text = center.loc_txt.text
    end
end