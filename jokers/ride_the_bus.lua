SMODS.Joker:take_ownership('ride_the_bus', {
    loc_txt = {
        name = 'Ride the Bus',
        text = {
            'This Joker gains {X:mult,C:white}X#1#{} Mult',
            'per {C:attention}consecutive{} hand',
            'played without a',
            'scoring {C:attention}face{} card',
            '{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)'
        }
    },
    config = { extra = 0.05 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra, card.ability.x_mult or 1 } }
    end,
    set_ability = function(self, card, initial, delay_sprites)
        card.ability.x_mult = card.ability.x_mult or 1
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            card.ability.mult = 0
            card.ability.x_mult = card.ability.x_mult or 1
            local has_face = false
            if context.scoring_hand then
                for i = 1, #context.scoring_hand do
                    if context.scoring_hand[i]:is_face() then
                        has_face = true
                        break
                    end
                end
            end
            if has_face then
                if card.ability.x_mult > 1 then
                    SMODS.reset_card(card, {
                        ref_table = card.ability,
                        ref_value = 'x_mult',
                        reset_value = 1,
                    })
                end
            else
                SMODS.scale_card(card, {
                    ref_table = card.ability,
                    ref_value = 'x_mult',
                    scalar_value = 'extra',
                    no_message = true,
                })
            end
            return {}
        end
        if context.joker_main then
            local x = card.ability.x_mult or 1
            if x > 1 then
                return { x_mult = x }
            end
            return {}
        end
    end,
    blueprint_compat = true,
})