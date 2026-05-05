SMODS.Joker:take_ownership('hit_the_road', {
    loc_txt = {
        name = 'Hit the Road',
        text = {
            'This Joker gains {X:mult,C:white} X#1# {} Mult',
            'for every {C:attention}Jack{} discarded',
            '{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)',
        }
    },
    config = { extra = 0.05 },
    set_ability = function(self, card, initial, delay_sprites)
        card.ability.x_mult = card.ability.x_mult or 1
    end,
    loc_vars = function(self, info_queue, card)
        local step = (card and card.ability and card.ability.extra) or 0.05
        local x = (card and card.ability and card.ability.x_mult) or 1
        return { vars = { step, x } }
    end,
    calculate = function(self, card, context)
        if context.discard and not context.blueprint then
            if context.other_card and not context.other_card.debuff
               and context.other_card:get_id() == 11 then
                card.ability.x_mult = (card.ability.x_mult or 1) + (card.ability.extra or 0.05)
                return {
                    message = localize{type='variable', key='a_xmult', vars={card.ability.x_mult}},
                    colour = G.C.RED,
                    delay = 0.45,
                    card = card
                }
            end
        end

        if context.joker_main then
            local x = card.ability.x_mult or 1
            if x > 1 then
                return { x_mult = x }
            end
            return {}
        end
    end,
})