return function(center)

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Walkie Talkie'
    center.loc_txt.text = {
        'Next card of same {C:attention}rank{} as first',
        'is {C:attention}retriggered{} as many times',
        'as first was retriggered in played hand',
    }

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_walkie_talkie then
        G.localization.descriptions.Joker.j_walkie_talkie.text = center.loc_txt.text
    end

    center.loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end

    if not rawget(_G, 'VP_WALKIE_STATE') then
        _G.VP_WALKIE_STATE = {}
    end

    local function get_card_rank(card)
        if not card or not card.base then return nil end
        return card.base.id
    end

    center.calculate = function(self, card, context)
        if context and context.before and context.full_hand then
            _G.VP_WALKIE_STATE = {}
        end

        if context and context.repetition and context.cardarea == G.play 
           and context.other_card and context.scoring_hand then
            
            local card_rank = get_card_rank(context.other_card)
            if not card_rank then return nil end

            local current_index, first_index = nil, nil
            for i = 1, #context.scoring_hand do
                local hand_card = context.scoring_hand[i]
                if hand_card == context.other_card then
                    current_index = i
                elseif not first_index and get_card_rank(hand_card) == card_rank then
                    first_index = i
                end
            end

            if first_index and current_index and first_index < current_index then
                local cards_between = 0
                for i = first_index + 1, current_index - 1 do
                    if get_card_rank(context.scoring_hand[i]) == card_rank then
                        cards_between = cards_between + 1
                    end
                end
                
                if cards_between == 0 then
                    local first_card = context.scoring_hand[first_index]
                    local retriggered_count = _G.VP_WALKIE_STATE[tostring(first_card)] or 0
                    
                    if retriggered_count > 0 then
                        _G.VP_WALKIE_STATE['rank_' .. card_rank] = true
                        
                        return {
                            message = localize('k_again_ex'),
                            repetitions = retriggered_count,
                            card = card
                        }
                    end
                end
            end
        end
        
        return nil
    end

    if not rawget(_G,'VP_WALKIE_TALKIE_SIMPLE_PATCHED') and rawget(_G,'Card') and Card.calculate_joker then
        local old_calculate_joker = Card.calculate_joker
        function Card:calculate_joker(context)
            if self.ability and self.ability.name == 'Walkie Talkie' and not self.debuff then
                if context and context.individual and context.cardarea == G.play then
                    return nil
                end
                
            end
            
            local result = old_calculate_joker(self, context)
            
            if result and result.repetitions and context and context.repetition and context.cardarea == G.play 
               and context.other_card and self.ability and self.ability.name ~= 'Walkie Talkie' then
                
                local has_walkie_talkie = false
                if rawget(_G, 'G') and G.jokers and G.jokers.cards then
                    for i = 1, #G.jokers.cards do
                        local joker = G.jokers.cards[i]
                        if joker and joker.ability and joker.ability.name == 'Walkie Talkie' and not joker.debuff then
                            has_walkie_talkie = true
                            break
                        end
                    end
                end
                
                if has_walkie_talkie then
                    local card_key = tostring(context.other_card)
                    local current_count = _G.VP_WALKIE_STATE[card_key] or 0
                    _G.VP_WALKIE_STATE[card_key] = current_count + result.repetitions
                end
            end
            
            return result
        end
        _G.VP_WALKIE_TALKIE_SIMPLE_PATCHED = true
    end

    if not rawget(_G,'VP_WALKIE_RED_SEAL_PATCHED') and rawget(_G,'Card') and Card.calculate_seal then
        local old_calculate_seal = Card.calculate_seal
        function Card:calculate_seal(context)
            local result = old_calculate_seal(self, context)
            
            if result and result.repetitions and context and context.repetition and context.cardarea == G.play 
               and self.seal == 'Red' then
                
                local has_walkie_talkie = false
                if rawget(_G, 'G') and G.jokers and G.jokers.cards then
                    for i = 1, #G.jokers.cards do
                        local joker = G.jokers.cards[i]
                        if joker and joker.ability and joker.ability.name == 'Walkie Talkie' and not joker.debuff then
                            has_walkie_talkie = true
                            break
                        end
                    end
                end
                
                if has_walkie_talkie then
                    local card_key = tostring(self)
                    local current_count = _G.VP_WALKIE_STATE[card_key] or 0
                    _G.VP_WALKIE_STATE[card_key] = current_count + result.repetitions
                end
            end
            
            return result
        end
        _G.VP_WALKIE_RED_SEAL_PATCHED = true
    end

    center.config = center.config or {}
    center.config.extra = center.config.extra or {}

    if rawget(_G,'G') and G.P_CENTERS and G.P_CENTERS.j_walkie_talkie then
        G.P_CENTERS.j_walkie_talkie.mod = nil
        G.P_CENTERS.j_walkie_talkie.modded = false
        G.P_CENTERS.j_walkie_talkie.discovered = true
    end

    return center
end