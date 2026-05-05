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
        card.ability.mult = card.ability.x_mult
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
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
                local last = card.ability.x_mult or 1
                card.ability.x_mult = 1
                card.ability.mult = card.ability.x_mult
                if last > 1 then
                    return {
                        card = card,
                        message = localize('k_reset')
                    }
                end
            else
                card.ability.x_mult = (card.ability.x_mult or 1) + (card.ability.extra or 0.05)
                card.ability.mult = card.ability.x_mult
            end
            return {}
        end
        if context.joker_main then
            local x = card.ability.x_mult or 1
            if x > 1 then
                return {
                    message = localize{type='variable', key='a_xmult', vars={x}},
                    Xmult_mod = x,
                    card = card
                }
            end
            return {}
        end
    end,
    blueprint_compat = true,
})