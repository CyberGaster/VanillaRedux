local function count_steel_in_hand()
    local count = 0
    if rawget(_G, 'G') and G.hand and G.hand.cards then
        for i = 1, #G.hand.cards do
            local card = G.hand.cards[i]
            if card and not card.highlighted and card.config and card.config.center == G.P_CENTERS.m_steel then
                count = count + 1
            end
        end
    end
    return count
end

SMODS.Joker:take_ownership('steel_joker', {
    loc_txt = {
        name = 'Steel Joker',
        text = {
            'Gives {X:mult,C:white}X#1#{} Mult for each',
            '{C:attention}Steel Card{} held in hand',
            '{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)'
        }
    },
    config = { extra = 0.75 },
    loc_vars = function(self, info_queue, card)
        local steel_count = count_steel_in_hand()
        local current_mult = 1 + steel_count * card.ability.extra
        return { vars = { card.ability.extra, current_mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local steel_count = count_steel_in_hand()
            local x_mult = 1 + steel_count * card.ability.extra
            if steel_count > 0 then
                return { x_mult = x_mult }
            end
            return {}
        end
    end,
    blueprint_compat = true,
})