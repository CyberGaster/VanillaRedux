SMODS.Joker:take_ownership('shoot_the_moon', {
    loc_txt = {
        name = 'Shoot the Moon',
        text = {
            "Gives {C:mult}+#1#{} Mult for each",
            "{C:hearts}Heart{} card held in hand",
            "when Queen of {C:spades}Spades{} played"
        }
    },
    config = { extra = 13 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand and context.other_card and not context.other_card.debuff then
            local sh = context.scoring_hand or {}
            local has_qs = false
            for i = 1, #sh do
                local sc = sh[i]
                if sc and not sc.debuff and sc:get_id() == 12 then
                    if (sc.ability and sc.ability.name == 'Wild Card') or (sc.base and sc.base.suit == 'Spades') then
                        has_qs = true
                        break
                    end
                end
            end
            if has_qs then
                local c = context.other_card
                if (c.ability and c.ability.name == 'Wild Card') or (c.base and c.base.suit == 'Hearts') then
                    return { h_mult = card.ability.extra, card = card }
                end
            end
            return {}
        end
    end,
    blueprint_compat = true,
})