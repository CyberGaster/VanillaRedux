SMODS.Joker:take_ownership('loyalty_card', {
    loc_txt = {
        name = 'Loyalty Card',
        text = {
            '{X:red,C:white} X#1# {} Mult every',
            '{C:attention}#2#{} hands played',
            '{C:inactive}(#3#){}'
        }
    },
    config = { extra = { Xmult = 5, every = 4 } },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.Xmult,
            card.ability.extra.every + 1,
            localize{type = 'variable', key = (card.ability.loyalty_remaining == 0 and 'loyalty_active' or 'loyalty_inactive'), vars = {card.ability.loyalty_remaining}}
        }}
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            card.ability.loyalty_remaining = (card.ability.extra.every - 1 - (G.GAME.hands_played - card.ability.hands_played_at_create)) % (card.ability.extra.every + 1)
            if card.ability.loyalty_remaining == 0 then
                local eval = function(c) return (c.ability.loyalty_remaining == 0) end
                juice_card_until(card, eval, true)
            elseif card.ability.loyalty_remaining == card.ability.extra.every then
                return {
                    x_mult = card.ability.extra.Xmult
                }
            end
        end
    end,
})