local function count_stone_in_deck()
    local count = 0
    if rawget(_G, 'G') and G.playing_cards then
        for i = 1, #G.playing_cards do
            local c = G.playing_cards[i]
            if c and c.config and c.config.center == G.P_CENTERS.m_stone then
                count = count + 1
            end
        end
    end
    return count
end

SMODS.Joker:take_ownership('stone', {
    loc_txt = {
        name = 'Stone Joker',
        text = {
            'Gives {X:mult,C:white}X#1#{} Mult for each',
            '{C:attention}Stone Card{} in your full deck',
            '{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)'
        }
    },
    config = { extra = 0.1 },
    loc_vars = function(self, info_queue, card)
        local stone_count = count_stone_in_deck()
        local current_mult = 1 + stone_count * card.ability.extra
        return { vars = { card.ability.extra, current_mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local stone_count = count_stone_in_deck()
            local x_mult = 1 + stone_count * card.ability.extra
            if stone_count > 0 then
                return { x_mult = x_mult }
            end
            return {}
        end
    end,
    blueprint_compat = true,
})