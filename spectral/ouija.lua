local get_ouija_stacks

SMODS.Consumable:take_ownership('c_ouija', {
    loc_txt = {
        name = 'Ouija',
        text = {
            'Converts all cards',
            'in hand to a single',
            'random {C:attention}rank{}',
            '{C:red}-1{} hand size for',
            'next {C:attention}3{} rounds',
        }
    },
    can_use = function(self, card)
        return G.hand and #G.hand.cards > 1
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            play_sound('tarot1')
            card:juice_up(0.3, 0.5)
            return true
        end}))
        for i = 1, #G.hand.cards do
            local percent = 1.15 - (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.15, func = function()
                G.hand.cards[i]:flip()
                play_sound('card1', percent)
                G.hand.cards[i]:juice_up(0.3, 0.3)
                return true
            end}))
        end
        delay(0.2)

        local _rank = pseudorandom_element({'2','3','4','5','6','7','8','9','T','J','Q','K','A'}, pseudoseed('ouija'))
        for i = 1, #G.hand.cards do
            G.E_MANAGER:add_event(Event({func = function()
                local c = G.hand.cards[i]
                local suit_prefix = string.sub(c.base.suit, 1, 1) .. '_'
                c:set_base(G.P_CARDS[suit_prefix .. _rank])
                return true
            end}))
        end

        for i = 1, #G.hand.cards do
            local percent = 0.85 + (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.15, func = function()
                G.hand.cards[i]:flip()
                play_sound('tarot2', percent, 0.6)
                G.hand.cards[i]:juice_up(0.3, 0.3)
                return true
            end}))
        end
        delay(0.5)

        local stacks = get_ouija_stacks()
        stacks[#stacks + 1] = { rounds_left = 3, applied_round = -1 }
    end,
})

get_ouija_stacks = function()
    local state = G.GAME._vp_ouija_temp or {}
    if not state.stacks then
        local legacy_rounds = state.rounds_left or 0
        state = { stacks = {} }
        if legacy_rounds > 0 then
            state.stacks[1] = { rounds_left = legacy_rounds, applied_round = G.GAME._vp_ouija_temp.applied_round or -1 }
        end
        G.GAME._vp_ouija_temp = state
    end
    return state.stacks
end

local orig_draw_to_hand = Game.update_draw_to_hand
function Game:update_draw_to_hand(dt)
    if G.GAME and G.hand and G.GAME._vp_ouija_temp then
        local stacks = get_ouija_stacks()
        local current_round = G.GAME.round or 0
        for i = #stacks, 1, -1 do
            local stack = stacks[i]
            if stack.rounds_left > 0 and stack.applied_round ~= current_round then
                G.hand:change_size(-1)
                G.GAME.round_resets.temp_handsize = (G.GAME.round_resets.temp_handsize or 0) - 1
                stack.applied_round = current_round
                stack.rounds_left = stack.rounds_left - 1
            elseif stack.rounds_left <= 0 and stack.applied_round ~= current_round then
                table.remove(stacks, i)
            end
        end
    end
    return orig_draw_to_hand(self, dt)
end