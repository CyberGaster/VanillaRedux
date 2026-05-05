SMODS.Joker:take_ownership('green_joker', {
    loc_txt = {
        name = 'Green Joker',
        text = {
            'Gains {X:mult,C:white}X#1#{} Mult per hand played',
            'Decrease Mult by {X:mult,C:white}X#2#{} per discard',
            '{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult)'
        }
    },
    config = { extra = { hand_add = 0.05, discard_sub = 0.05 } },
    set_ability = function(self, card, initial, delay_sprites)
        card.ability.x_mult = card.ability.x_mult or 1
    end,
    loc_vars = function(self, info_queue, card)
        local extra = (card and card.ability and card.ability.extra) or { hand_add = 0.05, discard_sub = 0.05 }
        local x = (card and card.ability and card.ability.x_mult) or 1
        return { vars = { extra.hand_add, extra.discard_sub, x } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            card.ability.x_mult = (card.ability.x_mult or 1) + (card.ability.extra.hand_add or 0.05)
            return {}
        end

        if context.discard and not context.blueprint
           and context.other_card == context.full_hand[#context.full_hand] then
            local prev = card.ability.x_mult or 1
            local step = card.ability.extra.discard_sub or 0.05
            card.ability.x_mult = prev - step
            return {}
        end

        if context.joker_main then
            local x = card.ability.x_mult or 1
            return { x_mult = x }
        end
    end,
})