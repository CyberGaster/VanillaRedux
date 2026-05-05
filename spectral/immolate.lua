SMODS.Consumable:take_ownership('c_immolate', {
    loc_txt = {
        name = 'Immolate',
        text = {
            'Destroys {C:attention}#1#{} random',
            'cards in hand,',
            'gain {C:money}$#2#',
        }
    },
    config = { remove_card = true, extra = { destroy = 5, dollars = 25 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.destroy, card.ability.extra.dollars } }
    end,
})