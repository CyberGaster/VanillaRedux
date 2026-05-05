local function get_total_mult()
    local level = 1
    if rawget(_G, 'G') and G.GAME and G.GAME.hands and G.GAME.hands['Three of a Kind'] then
        level = G.GAME.hands['Three of a Kind'].level or 1
    end
    return 12 + 3 * math.max(0, level - 1)
end

SMODS.Joker:take_ownership('zany', {
    loc_txt = {
        name = 'Zany Joker',
        text = {
            '{C:mult}+12{} Mult if played hand',
            'contains a {C:attention}Three of a Kind{}',
            '{C:mult}+3{} mult for each level',
            'of the {C:attention}Three of a Kind{} poker hand',
            '{C:inactive}(Currently {C:mult}+#1#{} {C:inactive}Mult)'
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { get_total_mult() } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and context.poker_hands['Three of a Kind'] and next(context.poker_hands['Three of a Kind']) then
                return {
                    mult = get_total_mult()
                }
            end
            return {}
        end
    end,
})