return function(center)
     
    SMODS.Joker:take_ownership('marble', {
        no_mod_display = true,
        loc_txt = {
            name = "Marble Joker",
            text = {
                'Adds one {C:attention}Stone{} card to deck',
                'when {C:attention}Blind{} is selected and',
                'when {C:attention}Blind{} is defeated',
                '{C:green}#1# in 4{} chance each {C:attention}Stone{}',
                'card gains a random {C:edition}Edition{}'
            }
        },
        
        loc_vars = function(self, info_queue, card)
            return { vars = { ''..(G.GAME and G.GAME.probabilities.normal or 1) } }
        end,
        
        calculate = function(self, card, context)
            card.ability = card.ability or {}
            card.ability._vp = card.ability._vp or {}

            local current_round = (rawget(_G, 'G') and G.GAME and G.GAME.round) or -1
            local is_blueprint = context and context.blueprint
            local sliced = (context.blueprint_card or card).getting_sliced
            
            if not G.GAME._vp_marble_tracking then
                G.GAME._vp_marble_tracking = {}
            end
            
            if G.GAME._vp_marble_tracking._last_round and G.GAME._vp_marble_tracking._last_round < current_round then
                G.GAME._vp_marble_tracking = {_last_round = current_round}
            elseif not G.GAME._vp_marble_tracking._last_round then
                G.GAME._vp_marble_tracking._last_round = current_round
            end

            local function add_stone_card_with_edition()
                G.E_MANAGER:add_event(Event({
                    func = function() 
                        local front = pseudorandom_element(G.P_CARDS, pseudoseed('marb_fr'))
                        G.playing_card = (G.playing_card and G.playing_card + 1) or 1
                        local stone_card = Card(G.play.T.x + G.play.T.w/2, G.play.T.y, G.CARD_W, G.CARD_H, front, G.P_CENTERS.m_stone, {playing_card = G.playing_card})
                        
                        if pseudorandom('marble_edition') < ((G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal or 1)/4) then
                            local editions = {'foil', 'holo', 'polychrome'}
                            local random_edition = pseudorandom_element(editions, pseudoseed('marble_ed'))
                            stone_card:set_edition({[random_edition] = true})
                        end
                        
                        stone_card:start_materialize({G.C.SECONDARY_SET.Enhanced})
                        G.play:emplace(stone_card)
                        table.insert(G.playing_cards, stone_card)
                        return true
                    end
                }))
                
                G.E_MANAGER:add_event(Event({
                    func = function() 
                        G.deck.config.card_limit = G.deck.config.card_limit + 1
                        return true
                    end
                }))
                
                draw_card(G.play, G.deck, 90, 'up', nil)
            end

            if context.setting_blind and not is_blueprint and not sliced then
                local tracking_key = "setting_blind_" .. current_round .. "_" .. (card.unique_val or 0)
                if not G.GAME._vp_marble_tracking[tracking_key] then
                    add_stone_card_with_edition()
                    G.GAME._vp_marble_tracking[tracking_key] = true
                    return {
                        message = localize('k_plus_stone'),
                        colour = G.C.SECONDARY_SET.Enhanced,
                        card = card
                    }
                end
                return
            end

            if context.end_of_round and not context.individual and not context.repetition and not sliced then
                local owner_card = (context.blueprint and context.blueprint_card) or card
                local tracking_key = "end_of_round_" .. current_round .. "_" .. (owner_card.unique_val or 0)
                if not G.GAME._vp_marble_tracking[tracking_key] then
                    add_stone_card_with_edition()
                    G.GAME._vp_marble_tracking[tracking_key] = true
                    return {
                        message = localize('k_plus_stone'),
                        colour = G.C.SECONDARY_SET.Enhanced,
                        card = owner_card
                    }
                end
                return
            end
        end
    })
    
    if SMODS and SMODS.Hook then
        SMODS.Hook.add('post_game_init', function()
            if G.P_CENTERS.j_marble then
                G.P_CENTERS.j_marble.mod = nil
                G.P_CENTERS.j_marble.mod_id = nil
                G.P_CENTERS.j_marble.modded = false
                G.P_CENTERS.j_marble.discovered = true
            end
            
            if G.localization and G.localization.descriptions and G.localization.descriptions.Joker then
                local old_loc_vars = nil
                if G.localization.descriptions.Joker.j_marble and G.localization.descriptions.Joker.j_marble.loc_vars then
                    old_loc_vars = G.localization.descriptions.Joker.j_marble.loc_vars
                end
                
                G.localization.descriptions.Joker.j_marble = {
                    name = "Marble Joker",
                    text = {
                        'Adds one {C:attention}Stone{} card to deck',
                        'when {C:attention}Blind{} is selected and',
                        'when {C:attention}Blind{} is defeated',
                        '{C:green}#1# in 4{} chance each {C:attention}Stone{}',
                        'card gains a random {C:edition}Edition{}'
                    },
                    loc_vars = old_loc_vars
                }
            end
        end)
    else
        if rawget(_G,'G') and G.localization and G.localization.descriptions
            and G.localization.descriptions.Joker then
            local old_loc_vars = nil
            if G.localization.descriptions.Joker.j_marble and G.localization.descriptions.Joker.j_marble.loc_vars then
                old_loc_vars = G.localization.descriptions.Joker.j_marble.loc_vars
            end
            
            G.localization.descriptions.Joker.j_marble = {
                name = "Marble Joker",
                text = {
                    'Adds one {C:attention}Stone{} card to deck',
                    'when {C:attention}Blind{} is selected and',
                    'when {C:attention}Blind{} is defeated',
                    '{C:green}#1# in 4{} chance each {C:attention}Stone{}',
                    'card gains a random {C:edition}Edition{}'
                },
                loc_vars = old_loc_vars
            }
            
            if G.P_CENTERS.j_marble then
                G.P_CENTERS.j_marble.mod = nil
                G.P_CENTERS.j_marble.mod_id = nil
                G.P_CENTERS.j_marble.modded = false
                G.P_CENTERS.j_marble.discovered = true
            end
        end
    end
end