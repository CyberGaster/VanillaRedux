local function get_total_chips()
    local level = 1
    if rawget(_G, 'G') and G.GAME and G.GAME.hands and G.GAME.hands['Flush'] then
        level = G.GAME.hands['Flush'].level or 1
    end
    return 80 + 8 * math.max(0, level - 1)
end

SMODS.Joker:take_ownership('crafty', {
    loc_txt = {
        name = 'Crafty Joker',
        text = {
            '{C:chips}+80{} Chips if played',
            'hand contains a {C:attention}Flush{}',
            '{C:chips}+8{} chips for each level',
            'of the {C:attention}Flush{} poker hand',
            '{C:inactive}(Currently {C:chips}+#1#{} {C:inactive}Chips)'
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { get_total_chips() } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and context.poker_hands['Flush'] and next(context.poker_hands['Flush']) then
                return {
                    chips = get_total_chips()
                }
            end
            return {}
        end
    end,
})