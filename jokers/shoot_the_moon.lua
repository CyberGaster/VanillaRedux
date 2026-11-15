SMODS.Joker:take_ownership('shoot_the_moon', {
    loc_txt = {
        name = 'Shoot the Moon',
        text = {
            "Gives {C:mult}+#1#{} Mult for each",
            "{C:hearts}Heart{} card held in hand",
            "when Queen of {C:spades}Spades{} is scored"
        }
    },
    config = { extra = 13 },
    rarity = 2,
    cost = 7,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand and context.other_card and not context.other_card.debuff then
            local sh = context.scoring_hand or {}
            local has_qs = false
            for i = 1, #sh do
                local sc = sh[i]
                if sc and not sc.debuff and sc:get_id() == 12 and sc:is_suit('Spades') then
                    has_qs = true
                    break
                end
            end
            -- is_suit handles Wild Cards and Smeared Joker, and Stone Cards have no suit.
            if has_qs and context.other_card:is_suit('Hearts') then
                return { h_mult = card.ability.extra, card = card }
            end
            return {}
        end
    end,
    blueprint_compat = true,
})