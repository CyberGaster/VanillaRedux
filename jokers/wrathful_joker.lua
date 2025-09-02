return function(center)
    
    local function count_spades_played_before(current_card, context)
        if not context or not context.scoring_hand then return 0 end
        local spades_count = 0
        for i = 1, #context.scoring_hand do
            local card = context.scoring_hand[i]
            if card == current_card then break end
            if card:is_suit("Spades") then spades_count = spades_count + 1 end
        end
        return spades_count
    end

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Wrathful Joker'
    center.loc_txt.text = {
        'Played cards with {C:spades}Spade{} suit',
        'give {X:mult,C:white}X1.05{} Mult when scored',
        'Each additional played {C:spades}Spade{} card',
        'increases mult by {X:mult,C:white}X0.05{} {C:inactive}'
    }

    local orig_calc = center.calculate
    center.calculate = function(self, card, context)
        if context and context.individual and context.cardarea == G.play and not context.other_card.debuff then
            if context.other_card:is_suit("Spades") then
                local spades_before = count_spades_played_before(context.other_card, context)
                local multiplier = 1.05 + (spades_before * 0.05)
                return {
                    x_mult = multiplier,
                    card = card
                }
            end
        end
        
        return orig_calc and orig_calc(self, card, context) or nil
    end

    center.config = center.config or {}
    center.config.extra = center.config.extra or {}
    center.config.extra.base_mult = 1.05
    center.config.extra.increment = 0.05

    center.loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_wrathful_joker then
        G.localization.descriptions.Joker.j_wrathful_joker.text = center.loc_txt.text
    end
end