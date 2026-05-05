SMODS.Joker:take_ownership('banner', {
    loc_txt = {
        name = 'Banner',
        text = {
            'Gains {C:chips}+15{} Chips per remaining',
            '{C:discard}discard{} at end of round',
            '{C:inactive}(Currently {C:chips}+#1#{} {C:inactive}Chips)'
        }
    },
    config = { extra = 0 },
    loc_vars = function(self, info_queue, card)
        return { vars = { (card and card.ability and card.ability.extra) or 0 } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if card.ability.extra > 0 then
                return {
                    chips = card.ability.extra
                }
            end
            return {}
        end

        if context.end_of_round and not context.repetition and not context.individual then
            if not context.blueprint then
                local discards_left = G.GAME.current_round.discards_left or 0
                if discards_left > 0 then
                    card.ability.extra = card.ability.extra + (discards_left * 15)
                    return {
                        message = 'Upgrade!',
                        colour = G.C.CHIPS
                    }
                end
            end
        end
    end,
})