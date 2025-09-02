return function(center)
    
    center.rarity = 1
    center.cost = 5
    center.no_mod_display = true

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Cartomancer'
    center.loc_txt.text = {
        'Create a {C:tarot}Tarot{} card',
        'when {C:attention}Blind{} is selected and',
        'when {C:attention}Blind{} is defeated',
        '{C:inactive}(Must have room){}'
    }

    local original_calculate = center.calculate
    center.calculate = function(self, card, context)
        if context and context.end_of_round and not context.individual and not context.repetition and not context.game_over then
            local src = (context.blueprint_card or card)
            if not src.getting_sliced then
                local current = (#G.consumeables.cards or 0) + (G.GAME and (G.GAME.consumeable_buffer or 0) or 0)
                local limit = (G.consumeables and G.consumeables.config and G.consumeables.config.card_limit) or 0
                if current < limit then
                    G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
                    G.E_MANAGER:add_event(Event({
                        func = (function()
                            G.E_MANAGER:add_event(Event({
                                func = function()
                                    local tarot = create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, 'car')
                                    tarot:add_to_deck()
                                    G.consumeables:emplace(tarot)
                                    G.GAME.consumeable_buffer = 0
                                    return true
                                end
                            }))
                            if rawget(_G, 'card_eval_status_text') then
                                card_eval_status_text(src, 'extra', nil, nil, nil, {message = localize('k_plus_tarot'), colour = G.C.PURPLE})
                            end
                            return true
                        end)
                    }))
                end
            end
        end

        if original_calculate then
            return original_calculate(self, card, context)
        end
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_cartomancer then
        G.localization.descriptions.Joker.j_cartomancer.text = center.loc_txt.text
    end

    if rawget(_G,'G') and G.P_CENTERS and G.P_CENTERS.j_cartomancer then
        G.P_CENTERS.j_cartomancer.mod = nil
        G.P_CENTERS.j_cartomancer.mod_id = nil
        G.P_CENTERS.j_cartomancer.modded = false
        G.P_CENTERS.j_cartomancer.discovered = true
    end
end