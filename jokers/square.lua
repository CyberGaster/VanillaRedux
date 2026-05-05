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
    set_ability = function(self, card, initial, delay_sprites)
        card.ability.extra = card.ability.extra or {}
        card.ability.extra.chips = card.ability.extra.chips or 0
        card.ability.extra.chip_mod = card.ability.extra.chip_mod or 4
        card.ability.extra.mult = card.ability.extra.mult or 0
        card.ability.extra.mult_mod = card.ability.extra.mult_mod or 4
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            if context.full_hand and #context.full_hand == 4 then
                local seed = 'square_'..tostring(G.GAME.round or 0)..'_'..tostring((G.GAME.current_round and G.GAME.current_round.hands_played) or 0)
                if pseudorandom(pseudoseed(seed)) < 0.5 then
                    card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
                    return {
                        message = '+' .. card.ability.extra.chip_mod .. ' Chips',
                        colour = G.C.CHIPS,
                        card = card
                    }
                else
                    card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
                    return {
                        message = '+' .. card.ability.extra.mult_mod .. ' Mult',
                        colour = G.C.MULT,
                        card = card
                    }
                end
            end
            return {}
        end
        if context.joker_main then
            local c = card.ability.extra.chips
            local m = card.ability.extra.mult
            if c > 0 or m > 0 then
                local msg
                if c > 0 and m > 0 then
                    msg = '+' .. c .. ' chips + ' .. m .. ' mult'
                elseif c > 0 then
                    msg = '+' .. c .. ' chips'
                else
                    msg = '+' .. m .. ' mult'
                end
                card_eval_status_text(card, 'extra', nil, nil, nil, {
                    message = msg,
                    colour = G.C.PURPLE,
                    delay = 1.0
                })
                return {
                    chip_mod = c,
                    mult_mod = m,
                }
            end
            return {}
        end
    end,
    blueprint_compat = true,
})
