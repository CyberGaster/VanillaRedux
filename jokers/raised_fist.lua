return function(center)
    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Raised Fist'
    center.loc_txt.text = {
        'Adds {C:attention}triple{} the rank',
        'of {C:attention}lowest{} ranked card',
        'held in hand to Mult'
    }

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_raised_fist then
        G.localization.descriptions.Joker.j_raised_fist.text = center.loc_txt.text
    end

    local original_calculate = center.calculate
    center.calculate = function(self, card, context)
        if context.end_of_round then return nil end
        
        if context.individual and context.cardarea == G.hand and not context.half_joker_check then
            local temp_Mult, temp_ID = 15, 15
            local raised_card = nil
            for i=1, #G.hand.cards do
                if temp_ID >= G.hand.cards[i].base.id and G.hand.cards[i].ability.effect ~= 'Stone Card' then 
                    temp_Mult = G.hand.cards[i].base.nominal
                    temp_ID = G.hand.cards[i].base.id
                    raised_card = G.hand.cards[i] 
                end
            end
            if raised_card == context.other_card then 
                if context.other_card.debuff then
                    return {
                        message = localize('k_debuffed'),
                        colour = G.C.RED,
                        card = card,
                    }
                else
                    return {
                        h_mult = 3*temp_Mult,
                        card = card,
                    }
                end
            end
        end
        
        if original_calculate then
            return original_calculate(self, card, context)
        end
    end
end