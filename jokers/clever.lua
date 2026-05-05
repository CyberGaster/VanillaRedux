local function get_total_chips()
    local level = 1
    if rawget(_G, 'G') and G.GAME and G.GAME.hands and G.GAME.hands['Two Pair'] then
        level = G.GAME.hands['Two Pair'].level or 1
    end
    return 80 + 8 * math.max(0, level - 1)
end

SMODS.Joker:take_ownership('clever', {
    loc_txt = {
        name = 'Clever Joker',
        text = {
            '{C:chips}+80{} Chips if played',
            'hand contains a {C:attention}Two Pair{}',
            '{C:chips}+8{} chips for each level',
            'of the {C:attention}Two Pair{} poker hand',
            '{C:inactive}(Currently {C:chips}+#1#{} {C:inactive}Chips)'
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { get_total_chips() } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and context.poker_hands['Two Pair'] and next(context.poker_hands['Two Pair']) then
                return {
                    chips = get_total_chips()
                }
            end
            return {}
        end
    end,
})