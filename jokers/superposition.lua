SMODS.Joker:take_ownership('superposition', {
    loc_txt = {
        name = 'Superposition',
        text = {
            '{C:green}#1# in #2#{} chance to give',
            '{C:chips}+#3#{} Chips or {C:mult}+#4#{} Mult',
            'if poker hand contains an {C:attention}Ace{}'
        }
    },
    config = { extra = { chips = 50, mult = 50, odds = 2 } },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, 'vr_superposition')
        return { vars = {
            numerator,
            denominator,
            card.ability.extra.chips,
            card.ability.extra.mult
        } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local has_ace = false
            if context.scoring_hand then
                for i = 1, #context.scoring_hand do
                    if context.scoring_hand[i]:get_id() == 14 then
                        has_ace = true
                        break
                    end
                end
            end
            if has_ace then
                if SMODS.pseudorandom_probability(card, 'superposition', 1, card.ability.extra.odds, 'vr_superposition') then
                    if pseudorandom('superposition_choice') < 0.5 then
                        return { chips = card.ability.extra.chips }
                    else
                        return { mult = card.ability.extra.mult }
                    end
                end
            end
            return {}
        end
    end,
    blueprint_compat = true,
})