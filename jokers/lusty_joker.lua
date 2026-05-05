local function count_suit_in_deck()
    if not rawget(_G, 'G') or not G.playing_cards then return 0 end
    local count = 0
    for i = 1, #G.playing_cards do
        local c = G.playing_cards[i]
        if c and c.is_suit and c:is_suit("Hearts") then
            count = count + 1
        end
    end
    return count
end

local function get_x_mult()
    return 1 + 0.01 * count_suit_in_deck()
end

SMODS.Joker:take_ownership('lusty_joker', {
    loc_txt = {
        name = 'Lusty Joker',
        text = {
            'Played cards with {C:hearts}Heart{} suit',
            'give {X:mult,C:white} X#1# {} Mult when scored',
            '{X:mult,C:white} X0.01 {} per {C:hearts}Heart{} in full deck',
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { string.format("%.2f", get_x_mult()) } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card:is_suit("Hearts") then
                return {
                    x_mult = get_x_mult(),
                    card = card
                }
            end
        end
    end,
})
