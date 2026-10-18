SMODS.Joker:take_ownership('reserved_parking', {
    loc_txt = {
        name = 'Reserved Parking',
        text = {
            'Each {C:attention}face{} card',
            'held in hand has',
            'a {C:green}#2# in #3#{} chance',
            'to give {C:money}$#1#{}'
        }
    },
    cost = 4,
    config = { extra = { dollars = 2, odds = 2 } },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, 'parking')
        return { vars = { card.ability.extra.dollars, numerator, denominator } }
    end,
})