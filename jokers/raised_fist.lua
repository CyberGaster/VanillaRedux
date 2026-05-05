SMODS.Joker:take_ownership('raised_fist', {
    loc_txt = {
        name = 'Raised Fist',
        text = {
            'Adds {C:attention}triple{} the rank',
            'of {C:attention}lowest{} ranked card',
            'held in hand to Mult'
        }
    },
    calculate = function(self, card, context)
        if context.end_of_round then return nil end
        if context.individual and context.cardarea == G.hand then
            local temp_Mult, temp_ID = 15, 15
            local raised_card = nil
            for i = 1, #G.hand.cards do
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
                        h_mult = 3 * temp_Mult,
                        card = card,
                    }
                end
            end
        end
    end,
})