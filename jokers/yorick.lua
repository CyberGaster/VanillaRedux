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
    set_ability = function(self, card, initial, delay_sprites)
        card.ability.yorick_discards = card.ability.extra.discards
    end,
    calculate = function(self, card, context)
        if context.pre_discard and not context.blueprint then
            if card.ability.yorick_discards <= 1 then
                card.ability.yorick_discards = card.ability.extra.discards
                card.ability.x_mult = card.ability.x_mult + card.ability.extra.xmult
                return {
                    delay = 0.2,
                    message = localize{type='variable',key='a_xmult',vars={card.ability.x_mult}},
                    colour = G.C.RED
                }
            else
                card.ability.yorick_discards = card.ability.yorick_discards - 1
            end
            return {}
        end
        if context.joker_main then
            if card.ability.x_mult > 1 then
                return { x_mult = card.ability.x_mult }
            end
            return {}
        end
    end,
    blueprint_compat = true,
})