local function get_total_chips()
    local level = 1
    if rawget(_G, 'G') and G.GAME and G.GAME.hands and G.GAME.hands['Pair'] then
        level = G.GAME.hands['Pair'].level or 1
    end
    return 50 + 5 * math.max(0, level - 1)
end

SMODS.Joker:take_ownership('sly', {
    loc_txt = {
        name = 'Sly Joker',
        text = {
            '{C:chips}+50{} Chips if played',
            'hand contains a {C:attention}Pair{}',
            '{C:chips}+5{} chips for each level',
            'of the {C:attention}Pair{} poker hand',
            '{C:inactive}(Currently {C:chips}+#1#{} {C:inactive}Chips)'
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { get_total_chips() } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and context.poker_hands['Pair'] and next(context.poker_hands['Pair']) then
                return {
                    chips = get_total_chips()
                }
            end
            return {}
        end
    end,
})