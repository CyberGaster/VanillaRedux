local function get_total_mult()
    local level = 1
    if rawget(_G, 'G') and G.GAME and G.GAME.hands and G.GAME.hands['Straight'] then
        level = G.GAME.hands['Straight'].level or 1
    end
    return 12 + 3 * math.max(0, level - 1)
end

SMODS.Joker:take_ownership('crazy', {
    loc_txt = {
        name = 'Crazy Joker',
        text = {
            '{C:mult}+12{} Mult if played hand',
            'contains a {C:attention}Straight{}',
            '{C:mult}+3{} mult for each level',
            'of the {C:attention}Straight{} poker hand',
            '{C:inactive}(Currently {C:mult}+#1#{} {C:inactive}Mult)'
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { get_total_mult() } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and context.poker_hands['Straight'] and next(context.poker_hands['Straight']) then
                return {
                    mult = get_total_mult()
                }
            end
            return {}
        end
    end,
})