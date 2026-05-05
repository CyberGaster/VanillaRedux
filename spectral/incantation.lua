local function is_face_card(c)
    if not c then return false end
    if find_joker and G.jokers then
        local pareidolia = find_joker("Pareidolia")
        if pareidolia and next(pareidolia) then return true end
    end
    if c.is_face then return c:is_face(true) end
    if c.get_id then
        local id = c:get_id()
        return id == 11 or id == 12 or id == 13
    end
    return false
end

SMODS.Consumable:take_ownership('c_incantation', {
    loc_txt = {
        name = 'Incantation',
        text = {
            'Destroy {C:attention}1{} random',
            '{C:attention}face card{} in your hand,',
            'add {C:attention}#1#{} random {C:attention}Enhanced',
            '{C:attention}numbered cards{} to your hand',
        }
    },
    config = { extra = 4 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra } }
    end,
    can_use = function(self, card)
        if G.hand and G.hand.cards then
            for _, c in ipairs(G.hand.cards) do
                if is_face_card(c) then return true end
            end
        end
        return false
    end,
    use = function(self, card, area, copier)
        local face_cards = {}
        for _, c in ipairs(G.hand.cards) do
            if is_face_card(c) then
                face_cards[#face_cards + 1] = c
            end
        end

        if #face_cards > 0 then
            local destroyed_card = pseudorandom_element(face_cards, pseudoseed('incantation_destroy'))

            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
                play_sound('tarot1')
                card:juice_up(0.3, 0.5)
                return true
            end}))

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.1,
                func = function()
                    if destroyed_card.ability and destroyed_card.ability.name == 'Glass Card' then
                        destroyed_card:shatter()
                    else
                        destroyed_card:start_dissolve()
                    end
                    return true
                end
            }))

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.7,
                func = function()
                    local cards = {}
                    for i = 1, (card.ability.extra or 4) do
                        cards[i] = true
                        local _rank = pseudorandom_element({'2', '3', '4', '5', '6', '7', '8', '9', 'T', 'A'}, pseudoseed('incantation_create'))
                        local _suit = pseudorandom_element({'S','H','D','C'}, pseudoseed('incantation_create'))

                        local cen_pool = {}
                        for _, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
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
                end
            }))
        end
    end,
})
