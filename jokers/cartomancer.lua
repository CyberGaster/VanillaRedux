local function spawn_tarot(card)
    local current = (#G.consumeables.cards or 0) + (G.GAME and (G.GAME.consumeable_buffer or 0) or 0)
    local limit = (G.consumeables and G.consumeables.config and G.consumeables.config.card_limit) or 0
    if current < limit then
        G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
        G.E_MANAGER:add_event(Event({
            func = function()
                G.E_MANAGER:add_event(Event({
                    func = function()
                        local tarot = create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, 'car')
                        tarot:add_to_deck()
                        G.consumeables:emplace(tarot)
                        G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 1) - 1)
                        return true
                    end
                }))
                card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_plus_tarot'), colour = G.C.PURPLE})
                return true
            end
        }))
        return true
    end
    return false
end

SMODS.Joker:take_ownership('cartomancer', {
    rarity = 1,
    cost = 5,
    loc_txt = {
        name = 'Cartomancer',
        text = {
            'Create a {C:tarot}Tarot{} card',
            'when {C:attention}Blind{} is selected and',
            'when {C:attention}Blind{} is defeated',
            '{C:inactive}(Must have room){}'
        }
    },
    calculate = function(self, card, context)
        if context.end_of_round and not context.individual and not context.repetition and not context.game_over then
            if not card.getting_sliced then
                spawn_tarot(card)
            end
        end
    end,
})