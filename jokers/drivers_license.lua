local STEP_PER_ENHANCED = 0.2

local function count_enhanced_cards_in_full_deck()
    if not (rawget(_G, 'G') and G.playing_cards) then return 0 end
    local count = 0
    for _, v in pairs(G.playing_cards) do
        if v and v.ability and v.ability.set == 'Enhanced' then
            count = count + 1
        end
    end
    return count
end

SMODS.Joker:take_ownership('drivers_license', {
    loc_txt = {
        name = "Driver's License",
        text = {
            'This Joker gains {X:mult,C:white}X#1#{} Mult',
            'for each {C:attention}Enhanced{} card',
            'in your full deck',
            '{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)'
        }
    },
    config = { extra = STEP_PER_ENHANCED },
    cost = 9,
    loc_vars = function(self, info_queue, card)
        local step = (card and card.ability and card.ability.extra) or STEP_PER_ENHANCED
        local enhanced_count = count_enhanced_cards_in_full_deck()
        local current_x = 1 + (enhanced_count * step)
        return { vars = { step, current_x } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local step = card.ability.extra or STEP_PER_ENHANCED
            local enhanced_count = count_enhanced_cards_in_full_deck()
            local x = 1 + (enhanced_count * step)
            if x > 1 then
                return {
                    x_mult = x
                }
            end
            return {}
        end
    end,
})