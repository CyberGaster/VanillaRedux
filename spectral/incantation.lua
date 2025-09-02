return function(center)

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Incantation'
    center.loc_txt.text = {
        'Destroy {C:attention}1{} random',
        '{C:attention}face card{} in your hand,',
        'add {C:attention}#1#{} random {C:attention}Enhanced',
        '{C:attention}numbered cards{} to your hand'
    }
    
    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Spectral and G.localization.descriptions.Spectral.c_incantation then
        G.localization.descriptions.Spectral.c_incantation.text = center.loc_txt.text
    end
    
    local function is_face_card(card)
        if not card then return false end
        
        if rawget(_G, 'find_joker') and rawget(_G, 'G') and G.jokers then
            local pareidolia = find_joker("Pareidolia")
            if pareidolia and next(pareidolia) then
                return true
            end
        end
        
        if card.is_face then
            return card:is_face(true)
        end
        
        if card.get_id then
            local id = card:get_id()
            return id == 11 or id == 12 or id == 13
        end
        return false
    end
    
    local function count_face_cards(cards)
        local count = 0
        for _, card in ipairs(cards) do
            if is_face_card(card) then
                count = count + 1
            end
        end
        return count
    end
    
    -- Patch can_use_consumeable
    if rawget(_G, 'Card') and Card.can_use_consumeable then
        local original_can_use = Card.can_use_consumeable
        if (not _G.VR_INCANTATION_PATCHED_CAN_USE) or (_G.VR_INCANTATION_PATCHED_CAN_USE ~= original_can_use) then
            function Card:can_use_consumeable(any_state, skip_check)
                local is_incantation = self and self.ability and (self.ability.name == 'Incantation')
                
                if is_incantation then
                    if not skip_check and ((G.play and #G.play.cards > 0) or
                        (G.CONTROLLER.locked) or
                        (G.GAME.STOP_USE and G.GAME.STOP_USE > 0))
                        then return false end
                    
                    if G.STATE ~= G.STATES.HAND_PLAYED and G.STATE ~= G.STATES.DRAW_TO_HAND and G.STATE ~= G.STATES.PLAY_TAROT or any_state then
                        -- Check if there are face cards in hand
                        if G.hand and G.hand.cards then
                            local face_count = count_face_cards(G.hand.cards)
                            if face_count > 0 then
                                return true
                            end
                        end
                        return false
                    end
                    return false
                else
                    return original_can_use(self, any_state, skip_check)
                end
            end
            _G.VR_INCANTATION_PATCHED_CAN_USE = Card.can_use_consumeable
        end
    end
    
    -- Patch use_consumeable
    if rawget(_G, 'Card') and Card.use_consumeable then
        local original_use = Card.use_consumeable
        if (not _G.VR_INCANTATION_PATCHED_USE) or (_G.VR_INCANTATION_PATCHED_USE ~= original_use) then
            function Card:use_consumeable(area, copier)
                local is_incantation = self and self.ability and (self.ability.name == 'Incantation')
                
                if not is_incantation then
                    return original_use(self, area, copier)
                end
                
                if rawget(_G,'G') and G.hand then
                    -- Get face cards from hand
                    local face_cards = {}
                    for _, card in ipairs(G.hand.cards) do
                        if is_face_card(card) then
                            face_cards[#face_cards + 1] = card
                        end
                    end
                    
                    if #face_cards > 0 then
                        local destroyed_card = pseudorandom_element(face_cards, pseudoseed('incantation_destroy'))
                        local destroyed_cards = {destroyed_card}
                        
                        stop_use()
                        if not copier then set_consumeable_usage(self) end
                        if self.area and self.area == G.consumeables then
                            self:remove_from_deck()
                        end
                        
                        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
                            play_sound('tarot1')
                            self:juice_up(0.3, 0.5)
                            return true
                        end }))
                        
                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 0.1,
                            func = function()
                                for i=#destroyed_cards, 1, -1 do
                                    local card = destroyed_cards[i]
                                    if card.ability and card.ability.name == 'Glass Card' then
                                        card:shatter()
                                    else
                                        card:start_dissolve(nil, i ~= #destroyed_cards)
                                    end
                                end
                                return true
                            end }))
                        
                        -- Create enhanced numbered cards
                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 0.7,
                            func = function()
                                local cards = {}
                                for i=1, (self.ability.extra or 4) do
                                    cards[i] = true
                                    -- Create numbered cards (2-10 and A)
                                    local _rank = pseudorandom_element({'2', '3', '4', '5', '6', '7', '8', '9', 'T', 'A'}, pseudoseed('incantation_create'))
                                    local _suit = pseudorandom_element({'S','H','D','C'}, pseudoseed('incantation_create'))
                                    
                                    -- Build enhanced pool excluding Stone Card
                                    local cen_pool = {}
                                    for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                                        if v.name ~= 'Stone Card' then
                                            cen_pool[#cen_pool + 1] = v
                                        end
                                    end
                                    
                                    create_playing_card({
                                        front = G.P_CARDS[_suit..'_'.._rank], 
                                        center = pseudorandom_element(cen_pool, pseudoseed('incantation_create'))
                                    }, G.hand, nil, i ~= 1, {G.C.SECONDARY_SET.Spectral})
                                end
                                playing_card_joker_effects(cards)
                                return true
                            end }))
                    end
                end
            end
            _G.VR_INCANTATION_PATCHED_USE = Card.use_consumeable
        end
    end
end
