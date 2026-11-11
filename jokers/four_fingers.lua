local function count_other_active_four_fingers(card)
    local count = 0
    for _, j in ipairs((G.jokers and G.jokers.cards) or {}) do
        if j ~= card and not j.debuff and j.config and j.config.center
           and j.config.center.key == 'j_four_fingers' then
            count = count + 1
        end
    end
    return count
end

-- Overridden at load time rather than in add_to_deck: loading a saved run does not call
-- add_to_deck, so a patch installed there is missing after a restart and the vanilla
-- 4-card Straight/Flush returns.
function SMODS.four_fingers(hand_type)
    return 5
end

SMODS.Joker:take_ownership('four_fingers', {
    loc_txt = {
        name = 'Four Fingers',
        text = {
            '{C:blue}+#1#{} hand each round',
            'Can only play {C:attention}#2#{} cards per hand'
        }
    },
    rarity = 1,
    cost = 5,
    config = { extra = { hands = 1, play_limit = -1 } },
    loc_vars = function(self, info_queue, card)
        local extra = (card and card.ability and card.ability.extra) or { hands = 1, play_limit = -1 }
        return { vars = { extra.hands, 5 + extra.play_limit } }
    end,
    add_to_deck = function(self, card, from_debuff)
        G.GAME.round_resets.hands = G.GAME.round_resets.hands + (card.ability.extra.hands or 1)
        G.GAME.current_round.hands_left = G.GAME.current_round.hands_left + (card.ability.extra.hands or 1)
        if count_other_active_four_fingers(card) == 0 then
            SMODS.change_play_limit(card.ability.extra.play_limit or -1)
        end
    end,
    remove_from_deck = function(self, card, from_debuff)
        G.GAME.round_resets.hands = G.GAME.round_resets.hands - (card.ability.extra.hands or 1)
        G.GAME.current_round.hands_left = math.max(0, G.GAME.current_round.hands_left - (card.ability.extra.hands or 1))
        if count_other_active_four_fingers(card) == 0 then
            SMODS.change_play_limit(-(card.ability.extra.play_limit or -1))
        end
    end,
})