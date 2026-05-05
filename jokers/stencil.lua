local function count_negative_jokers()
    local count = 0
    if G.jokers and G.jokers.cards then
        for i = 1, #G.jokers.cards do
            local card = G.jokers.cards[i]
            if card and card.edition and card.edition.negative then
                count = count + 1
            end
        end
    end
    return count
end

SMODS.Joker:take_ownership('stencil', {
    loc_txt = {
        name = 'Joker Stencil',
        text = {
            '{X:red,C:white} X2 {} Mult for each',
            '{C:dark_edition}Negative{} Joker',
            '{C:inactive}(Currently {X:red,C:white} X#1# {C:inactive})'
        }
    },
    config = { x_mult = 1 },
    loc_vars = function(self, info_queue, card)
        local negative_count = count_negative_jokers()
        return { vars = { negative_count * 2 + 1 } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local negative_count = count_negative_jokers()
            local x_mult = negative_count * 2 + 1
            if x_mult > 1 then
                return { x_mult = x_mult }
            end
            return {}
        end
    end,
    blueprint_compat = true,
})