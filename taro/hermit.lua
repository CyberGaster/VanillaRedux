SMODS.Consumable:take_ownership('c_hermit', {
    loc_txt = {
        name = 'The Hermit',
        text = {
            'Doubles money',
            '{C:inactive}(Max of {C:money}$#1#{C:inactive})',
        }
    },
    config = { extra = 25 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra } }
    end,
})
