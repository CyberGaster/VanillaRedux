local function choose_random_seal()
    local r = pseudorandom(pseudoseed('cert_seal'))
    if r > 0.75 then return 'Red'
    elseif r > 0.5 then return 'Blue'
    elseif r > 0.25 then return 'Gold'
    else return 'Purple' end
end

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
})

if not rawget(_G, 'VP_CERTIFICATE_PATCHED') and rawget(_G, 'Card') and Card.calculate_joker then
    local old_calculate_joker = Card.calculate_joker
    function Card:calculate_joker(context)
        if self.ability and self.ability.name == 'Certificate' and not self.debuff then
            if context.first_hand_drawn and not context.blueprint then
                local eval = function() return G.GAME and G.GAME.current_round and G.GAME.current_round.hands_played == 0 end
                juice_card_until(self, eval, true)
                return nil
            end
            if context.before and G.GAME.current_round.hands_played == 0
               and context.full_hand and #context.full_hand == 1 then
                local target = context.full_hand[1]
                if target and not target.destroyed and not target.shattered and not target:get_seal(true) then
                    local seal = choose_random_seal()
                    target:set_seal(seal, false, true)
                    play_sound('gold_seal', 1.2, 0.4)
                    self:juice_up(0.6, 0.6)
                end
            end
            return nil
        end
        return old_calculate_joker(self, context)
    end
    _G.VP_CERTIFICATE_PATCHED = true
end