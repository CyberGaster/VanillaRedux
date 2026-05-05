local function get_total_chips()
    local level = 1
    if rawget(_G, 'G') and G.GAME and G.GAME.hands and G.GAME.hands['Straight'] then
        level = G.GAME.hands['Straight'].level or 1
    end
    return 100 + 10 * math.max(0, level - 1)
end

SMODS.Joker:take_ownership('devious', {
    loc_txt = {
        name = 'Devious Joker',
        text = {
            '{C:chips}+100{} Chips if played',
            'hand contains a {C:attention}Straight{}',
            '{C:chips}+10{} chips for each level',
            'of the {C:attention}Straight{} poker hand',
            '{C:inactive}(Currently {C:chips}+#1#{} {C:inactive}Chips)'
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { get_total_chips() } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and context.poker_hands['Straight'] and next(context.poker_hands['Straight']) then
                return {
                    chips = get_total_chips()
                }
            end
            return {}
        end
    end,
})