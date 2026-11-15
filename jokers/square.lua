SMODS.Joker:take_ownership('square', {
    loc_txt = {
        name = 'Square Joker',
        text = {
            'This Joker gains {C:chips}+#2#{} Chips or {C:mult}+#4#{} Mult',
            'if played hand has exactly {C:attention}4{} cards',
            '{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips and {C:mult}+#3#{C:inactive} Mult)',
        }
    },
    cost = 6,
    rarity = 2,
    config = { extra = { chips = 0, chip_mod = 4, mult = 0, mult_mod = 4 } },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.chips,
            card.ability.extra.chip_mod,
            card.ability.extra.mult,
            card.ability.extra.mult_mod,
        } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and context.full_hand and #context.full_hand == 4 then
            local gains_chips = pseudorandom('vr_square') < 0.5
            SMODS.scale_card(card, {
                ref_table = card.ability.extra,
                ref_value = gains_chips and 'chips' or 'mult',
                scalar_value = gains_chips and 'chip_mod' or 'mult_mod',
                message_key = gains_chips and 'a_chips' or 'a_mult',
                message_colour = gains_chips and G.C.CHIPS or G.C.MULT,
            })
            return nil, true
        end
        if context.joker_main then
            local extra = card.ability.extra
            return {
                chips = extra.chips > 0 and extra.chips or nil,
                mult = extra.mult > 0 and extra.mult or nil,
            }
        end
    end,
})
