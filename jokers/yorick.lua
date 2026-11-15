SMODS.Joker:take_ownership('yorick', {
    loc_txt = {
        name = 'Yorick',
        text = {
            'This Joker gains',
            '{X:mult,C:white} X#1# {} Mult every {C:attention}#2#{C:inactive} [#3#]{}',
            'cards discarded',
            '{C:inactive}(Currently {X:mult,C:white} X#4# {C:inactive} Mult)',
        }
    },
    config = { extra = { xmult = 1, discards = 21 } },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.xmult,
            card.ability.extra.discards,
            card.ability.yorick_discards or card.ability.extra.discards,
            card.ability.x_mult or 1
        } }
    end,
    calculate = function(self, card, context)
        if context.discard and context.other_card and not context.blueprint then
            if card.ability.yorick_discards <= 1 then
                card.ability.yorick_discards = card.ability.extra.discards
                SMODS.scale_card(card, {
                    ref_table = card.ability,
                    ref_value = 'x_mult',
                    scalar_table = card.ability.extra,
                    scalar_value = 'xmult',
                    message_key = 'a_xmult',
                    message_colour = G.C.RED,
                    message_delay = 0.2,
                })
            else
                card.ability.yorick_discards = card.ability.yorick_discards - 1
            end
            return nil, true
        end
        if context.joker_main then
            if card.ability.x_mult > 1 then
                return { x_mult = card.ability.x_mult }
            end
            return {}
        end
    end,
})