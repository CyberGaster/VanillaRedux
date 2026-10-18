SMODS.Joker:take_ownership('satellite', {
    loc_txt = {
        name = 'Satellite',
        text = {
            "{C:planet}Planet{} cards used",
            "are twice as effective",
            "Earn {C:money}$#1#{} at end of round",
            "per unique {C:planet}Planet{} card",
            "used this run",
            "{C:inactive}(Currently {C:money}$#2#{C:inactive})",
        }
    },
    blueprint_compat = false,
    loc_vars = function(self, info_queue, card)
        local unique = 0
        for _, v in pairs((G.GAME and G.GAME.consumeable_usage) or {}) do
            if v.set == 'Planet' then unique = unique + 1 end
        end
        return { vars = { card.ability.extra, card.ability.extra * unique } }
    end,
    calculate = function(self, card, context)
        if context.using_consumeable and not context.blueprint and context.consumeable and card.area == G.jokers then
            local c = context.consumeable
            if c.ability and c.ability.set == 'Planet' then
                local ht = c.ability.consumeable and c.ability.consumeable.hand_type
                if ht then
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after', delay = 0.05, func = function()
                            play_sound('card1', 0.85, 0.6)
                            card:juice_up(0.9, 0.6)
                            return true
                        end
                    }))
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after', delay = 0.35, func = function()
                            update_hand_text({sound = 'button', volume = 0.7, pitch = 0.8, delay = 0.3}, {handname=localize(ht, 'poker_hands'), chips = G.GAME.hands[ht].chips, mult = G.GAME.hands[ht].mult, level = G.GAME.hands[ht].level})
                            level_up_hand(c, ht)
                            update_hand_text({sound = 'button', volume = 0.7, pitch = 1.1, delay = 0}, {mult = 0, chips = 0, handname = '', level = ''})
                            return true
                        end
                    }))
                end
            end
        end
    end,
})