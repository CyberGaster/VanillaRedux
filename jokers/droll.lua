local function get_total_mult()
    local level = 1
    if rawget(_G, 'G') and G.GAME and G.GAME.hands and G.GAME.hands['Flush'] then
        level = G.GAME.hands['Flush'].level or 1
    end
    return 10 + 2 * math.max(0, level - 1)
end

SMODS.Joker:take_ownership('droll', {
    loc_txt = {
        name = 'Droll Joker',
        text = {
            '{C:mult}+10{} Mult if played hand',
            'contains a {C:attention}Flush{}',
            '{C:mult}+2{} mult for each level',
            'of the {C:attention}Flush{} poker hand',
            '{C:inactive}(Currently {C:mult}+#1#{} {C:inactive}Mult)'
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { get_total_mult() } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and context.poker_hands['Flush'] and next(context.poker_hands['Flush']) then
                return {
                    mult = get_total_mult()
                }
            end
            return {}
        end
    end,
})