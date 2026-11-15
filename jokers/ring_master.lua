local LEGENDARY_SHOP_CHANCE = 0.01

SMODS.Joker:take_ownership('ring_master', {
    loc_txt = {
        name = 'Showman',
        text = {
            '{C:attention}Joker{}, {C:tarot}Tarot{}, {C:planet}Planet{}, and {C:spectral}Spectral{}',
            'cards may appear multiple times',
            '{C:legendary}Legendary{} Jokers can appear',
            'in the shop with a very low chance'
        }
    },
    calculate = function(self, card, context)
        if context.create_shop_card and context.set == 'Joker' and not context.blueprint
           and SMODS.find_card('j_ring_master')[1] == card then
            -- One seed stream for the whole run, so the save file does not collect a key per shop slot.
            if pseudorandom(pseudoseed('vr_showman_legendary')) > 1 - LEGENDARY_SHOP_CHANCE then
                -- key = false drops a Joker the shop may have picked already, so a Legendary is rolled instead.
                return { shop_create_flags = { set = 'Joker', legendary = true, key = false } }
            end
        end
    end,
})
