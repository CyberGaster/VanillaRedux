local function get_total_mult()
    local level = 1
    if rawget(_G, 'G') and G.GAME and G.GAME.hands and G.GAME.hands['Pair'] then
        level = G.GAME.hands['Pair'].level or 1
    end
    return 8 + 1 * math.max(0, level - 1)
end

SMODS.Joker:take_ownership('jolly', {
    loc_txt = {
        name = 'Jolly Joker',
        text = {
            '{C:mult}+8{} Mult if played hand',
            'contains a {C:attention}Pair{}',
            '{C:mult}+1{} mult for each level',
            'of the {C:attention}Pair{} poker hand',
            '{C:inactive}(Currently {C:mult}+#1#{} {C:inactive}Mult)'
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { get_total_mult() } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and context.poker_hands['Pair'] and next(context.poker_hands['Pair']) then
                return {
                    mult = get_total_mult()
                }
            end
            return {}
        end
    end,
})