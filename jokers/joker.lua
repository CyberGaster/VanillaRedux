SMODS.Joker:take_ownership('joker', {
    loc_txt = {
        name = 'Joker',
        text = {
            '{C:mult}+#1#{} Mult',
            'Doubles {C:mult}Mult{} when',
            '{C:attention}Boss Blind{} is defeated'
        }
    },
    config = { mult = 4 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                mult = card.ability.mult
            }
        end

        if context.end_of_round and context.main_eval and context.beat_boss and not context.blueprint then
            SMODS.scale_card(card, {
                ref_table = card.ability,
                ref_value = 'mult',
                scalar_table = { factor = 2 },
                scalar_value = 'factor',
                operation = 'X',
                message_colour = G.C.MULT,
            })
            return nil, true
        end
    end,
})