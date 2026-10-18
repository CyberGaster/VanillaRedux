SMODS.Joker:take_ownership('marble', {
    loc_txt = {
        name = 'Marble Joker',
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
        local sliced = (context.blueprint_card or card).getting_sliced

        local function add_stone_card_with_edition()
            G.E_MANAGER:add_event(Event({
                func = function()
                    local front = pseudorandom_element(G.P_CARDS, pseudoseed('marb_fr'))
                    G.playing_card = (G.playing_card and G.playing_card + 1) or 1
                    local stone_card = Card(G.play.T.x + G.play.T.w/2, G.play.T.y, G.CARD_W, G.CARD_H, front, G.P_CENTERS.m_stone, {playing_card = G.playing_card})

                    if pseudorandom('marble_edition') < ((G.GAME.probabilities.normal or 1) / 4) then
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
            playing_card_joker_effects({true})
        end

        if context.setting_blind and not sliced then
            add_stone_card_with_edition()
            return {
                message = localize('k_plus_stone'),
                colour = G.C.SECONDARY_SET.Enhanced,
                card = context.blueprint_card or card
            }
        end

        if context.end_of_round and not context.individual and not context.repetition and not sliced then
            add_stone_card_with_edition()
            return {
                message = localize('k_plus_stone'),
                colour = G.C.SECONDARY_SET.Enhanced,
                card = context.blueprint_card or card
            }
        end
    end,
})