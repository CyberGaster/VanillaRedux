    return function(center)

    if SMODS and SMODS.Joker then
        SMODS.Joker:take_ownership('ancient', {
            no_mod_display = true,
            rarity = 2,
            cost = 7,
            loc_txt = {
                name = "Ancient Joker",
                text = {
                    '{C:attention}Stone{} cards count',
                    'as the same rank for poker hands',
                    'Each played {C:attention}Stone{} card',
                    'gives {X:mult,C:white}X1.5{} Mult when scored'
                }
            },
            
            calculate = function(self, card, context)
                if context.individual and context.cardarea == G.play then
                    if context.other_card and context.other_card.ability and context.other_card.ability.effect == 'Stone Card' then
                        return {
                            message = localize{type='variable',key='a_xmult',vars={1.5}},
                            Xmult_mod = 1.5,
                            colour = G.C.MULT
                        }
                    end
                end
            end
        })
        
        if not rawget(_G,'VP_ANCIENT_EVALUATE_PATCHED') and rawget(_G,'evaluate_poker_hand') then
            local old_evaluate_poker_hand = evaluate_poker_hand
            function evaluate_poker_hand(hand)
                local results = old_evaluate_poker_hand(hand)

                local has_ancient = false
                if rawget(_G,'find_joker') then
                    has_ancient = next(find_joker('Ancient Joker')) and true or false
                else
                    if rawget(_G,'G') and G.jokers and G.jokers.cards then
                        for i = 1, #G.jokers.cards do
                            local j = G.jokers.cards[i]
                            if j and j.ability and j.ability.name == 'Ancient Joker' then
                                has_ancient = true; break
                            end
                        end
                    end
                end
                if not has_ancient then return results end

                local stones = {}
                for i = 1, #hand do
                    local c = hand[i]
                    if c and c.ability and c.ability.effect == 'Stone Card' then
                        stones[#stones+1] = c
                    end
                end

                local function ensure_x_of_a_kind(key, needed)
                    if next(results[key]) then return end
                    if #stones >= needed then
                        local group = {}
                        for i = 1, needed do group[i] = stones[i] end
                        results[key] = {group}
                    end
                end

                ensure_x_of_a_kind('Five of a Kind', 5)
                ensure_x_of_a_kind('Four of a Kind', 4)
                ensure_x_of_a_kind('Three of a Kind', 3)
                ensure_x_of_a_kind('Pair', 2)

                return results
            end
            _G.VP_ANCIENT_EVALUATE_PATCHED = true
        end
    end
    
    if rawget(_G,'G') and G.P_CENTERS and G.P_CENTERS.j_ancient then
        G.P_CENTERS.j_ancient.rarity = 2
        G.P_CENTERS.j_ancient.cost = 7
        G.P_CENTERS.j_ancient.discovered = true
        G.P_CENTERS.j_ancient.mod = nil
        G.P_CENTERS.j_ancient.mod_id = nil
        G.P_CENTERS.j_ancient.modded = false
    end
end