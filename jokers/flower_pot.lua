local function count_unique_suits(scoring_hand)
    if not scoring_hand or #scoring_hand == 0 then return 0 end
    local suits = { Hearts = 0, Diamonds = 0, Spades = 0, Clubs = 0 }

    for i = 1, #scoring_hand do
        local c = scoring_hand[i]
        if c and c.ability and c.ability.name ~= 'Wild Card' and not c.debuff then
            if c:is_suit('Hearts') and suits.Hearts == 0 then suits.Hearts = 1
            elseif c:is_suit('Diamonds') and suits.Diamonds == 0 then suits.Diamonds = 1
            elseif c:is_suit('Spades') and suits.Spades == 0 then suits.Spades = 1
            elseif c:is_suit('Clubs') and suits.Clubs == 0 then suits.Clubs = 1
            end
        end
    end

    for i = 1, #scoring_hand do
        local c = scoring_hand[i]
        if c and c.ability and c.ability.name == 'Wild Card' and not c.debuff then
            if c:is_suit('Hearts') and suits.Hearts == 0 then
                suits.Hearts = 1
            elseif c:is_suit('Diamonds') and suits.Diamonds == 0 then
                suits.Diamonds = 1
            elseif c:is_suit('Spades') and suits.Spades == 0 then
                suits.Spades = 1
            elseif c:is_suit('Clubs') and suits.Clubs == 0 then
                suits.Clubs = 1
            end
        end
    end

    return (suits.Hearts + suits.Diamonds + suits.Spades + suits.Clubs)
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