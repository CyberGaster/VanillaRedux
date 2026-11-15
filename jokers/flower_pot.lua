local VANILLA_SUITS = { 'Hearts', 'Diamonds', 'Spades', 'Clubs' }

local function suit_order()
    local order, seen = {}, {}
    for _, key in ipairs(VANILLA_SUITS) do order[#order + 1] = key; seen[key] = true end
    for _, key in ipairs((SMODS.Suit and SMODS.Suit.obj_buffer) or {}) do
        if not seen[key] then order[#order + 1] = key; seen[key] = true end
    end
    return order
end

local function count_unique_suits(scoring_hand)
    if not scoring_hand or #scoring_hand == 0 then return 0 end
    local order = suit_order()
    local found, count = {}, 0

    local function take_suit(c)
        for _, suit in ipairs(order) do
            if not found[suit] and c:is_suit(suit) then
                found[suit] = true
                count = count + 1
                return
            end
        end
    end

    for _, wild_pass in ipairs({ false, true }) do
        for i = 1, #scoring_hand do
            local c = scoring_hand[i]
            if c and c.ability and not c.debuff and (c.ability.name == 'Wild Card') == wild_pass then
                take_suit(c)
            end
        end
    end
    return count
end

SMODS.Joker:take_ownership('flower_pot', {
    loc_txt = {
        name = 'Flower Pot',
        text = {
            '{X:mult,C:white}X1.5{} Mult if poker hand',
            'contains {C:attention}2{} unique {C:attention}suits{}',
            '{X:mult,C:white}X2.25{} if {C:attention}3{} unique {C:attention}suits{}',
            '{X:mult,C:white}X3{} if {C:attention}4{} unique {C:attention}suits{}'
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local unique_count = count_unique_suits(context.scoring_hand)
            if unique_count == 2 then
                return { x_mult = 1.5 }
            elseif unique_count == 3 then
                return { x_mult = 2.25 }
            elseif unique_count >= 4 then
                return { x_mult = 3 }
            end
            return {}
        end
    end,
})