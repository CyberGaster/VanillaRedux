SMODS.Joker:take_ownership('certificate', {
    loc_txt = {
        name = 'Certificate',
        text = {
            'If {C:attention}first hand{} of round',
            'has only {C:attention}1{} card, add a',
            '{C:attention}random seal{} to it'
        }
    },
    rarity = 1,
    cost = 5,
    blueprint_compat = false,
    calculate = function(self, card, context)
        -- Returning `nil, true` here stops the vanilla Certificate, which creates a new card.
        if context.first_hand_drawn then
            if not context.blueprint then
                local eval = function() return G.GAME and G.GAME.current_round and G.GAME.current_round.hands_played == 0 end
                juice_card_until(card, eval, true)
            end
            return nil, true
        end
        if context.before and not context.blueprint and G.GAME.current_round.hands_played == 0
           and context.full_hand and #context.full_hand == 1 then
            local target = context.full_hand[1]
            if target and not target.destroyed and not target.shattered and not target:get_seal(true) then
                -- poll_seal also includes seals added by other mods.
                target:set_seal(SMODS.poll_seal({ guaranteed = true, type_key = 'cert_seal' }), false, true)
                play_sound('gold_seal', 1.2, 0.4)
                card:juice_up(0.6, 0.6)
                return nil, true
            end
        end
    end,
})