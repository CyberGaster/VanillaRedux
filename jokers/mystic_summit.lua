SMODS.Joker:take_ownership('mystic_summit', {
    loc_txt = {
        name = 'Mystic Summit',
        text = {
            'Gains {C:mult}+3{} Mult when {C:attention}0{} discards',
            'remaining at end of round',
            '{C:inactive}(Currently {C:mult}+#1#{} {C:inactive}Mult)'
        }
    },
    config = { extra = { mult = 0, mult_gain = 3 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if card.ability.extra.mult > 0 then
                return { mult = card.ability.extra.mult }
            end
            return {}
        end
        if context.end_of_round and not context.repetition and not context.individual and not context.blueprint then
            if (G.GAME.current_round.discards_left or 0) == 0 then
                SMODS.scale_card(card, {
                    ref_table = card.ability.extra,
                    ref_value = 'mult',
                    scalar_value = 'mult_gain',
                    message_colour = G.C.MULT,
                })
                return nil, true
            end
        end
    end,
})
