SMODS.Joker:take_ownership('stuntman', {
    loc_txt = {
        name = 'Stuntman',
        text = {
            '{C:chips}+#1#{} Chips',
            '{C:attention}-#2#{} hand size',
            '{C:blue}-#3#{} hand each round',
        }
    },
    config = { extra = { chip_mod = 300, h_size = 1, h_plays = 1 } },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.chip_mod,
            card.ability.extra.h_size,
            card.ability.extra.h_plays
        } }
    end,
    add_to_deck = function(self, card, from_debuff)
        G.GAME.round_resets.hands = G.GAME.round_resets.hands - card.ability.extra.h_plays
    end,
    remove_from_deck = function(self, card, from_debuff)
        G.GAME.round_resets.hands = G.GAME.round_resets.hands + card.ability.extra.h_plays
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                chips = card.ability.extra.chip_mod
            }
        end
    end,
    blueprint_compat = true,
})
