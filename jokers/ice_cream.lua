-- Active time of the current round is kept in G.GAME, which is saved with the run, so restarting the
-- game does not reset the countdown. Only the last real-time reading lives outside the save.
local ice_cream_last_real = nil

local function ice_cream_timer()
    G.GAME.vr_ice_cream = G.GAME.vr_ice_cream or { elapsed = 0, applied = 0 }
    return G.GAME.vr_ice_cream
end

local function destroy_ice_cream(card)
    G.E_MANAGER:add_event(Event({
        func = function()
            play_sound('tarot1')
            card.T.r = -0.2
            card:juice_up(0.3, 0.4)
            card.states.drag.is = true
            card.children.center.pinch.x = true
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.3, blockable = false,
                func = function()
                    G.jokers:remove_card(card)
                    card:remove()
                    card = nil
                    return true
                end}))
            return true
        end
    }))
end

local function update_ice_cream_time_penalty()
    if not G or not G.STATES or not G.TIMERS or not G.GAME then return end

    if G.STATE ~= G.STATES.SELECTING_HAND and G.STATE ~= G.STATES.DRAW_TO_HAND then
        ice_cream_last_real = nil
        return
    end

    local now = G.TIMERS.REAL
    local timer = ice_cream_timer()
    if ice_cream_last_real then
        timer.elapsed = timer.elapsed + math.max(0, now - ice_cream_last_real)
    end
    ice_cream_last_real = now

    local time_penalties = math.floor(timer.elapsed / 10)
    if time_penalties <= timer.applied then return end

    local penalties_to_apply = (time_penalties - timer.applied) * 5
    timer.applied = time_penalties

    if not G.jokers or not G.jokers.cards then return end

    for i = 1, #G.jokers.cards do
        local card = G.jokers.cards[i]
        if card and card.config and card.config.center and card.config.center.key == 'j_ice_cream'
           and not card.debuff and card.ability and card.ability.extra then
            card.ability.extra.chips = (card.ability.extra.chips or 150) - penalties_to_apply
            if card.ability.extra.chips <= 0 then
                destroy_ice_cream(card)
            else
                card_eval_status_text(card, 'extra', nil, nil, nil, {
                    message = localize{type='variable', key='a_chips_minus', vars={penalties_to_apply}},
                    colour = G.C.CHIPS,
                    delay = 0.45
                })
            end
        end
    end
end

if not rawget(_G, 'VP_ICE_CREAM_PATCHED') then
local original_new_round = new_round
function new_round()
    local result = original_new_round and original_new_round() or nil
    ice_cream_last_real = nil
    if G.GAME then G.GAME.vr_ice_cream = { elapsed = 0, applied = 0 } end
    return result
end

local original_game_update = Game.update
function Game:update(dt)
    if original_game_update then
        original_game_update(self, dt)
    end
    update_ice_cream_time_penalty()
end
_G.VP_ICE_CREAM_PATCHED = true
end

SMODS.Joker:take_ownership('ice_cream', {
    loc_txt = {
        name = 'Ice Cream',
        text = {
            '{C:chips}+#1#{} Chips',
            '{C:chips}-#2#{} Chips for',
            'every hand played',
            '{C:chips}-5{} Chips every',
            '{C:attention}10 seconds{} in round'
        }
    },
    config = { extra = { chips = 150, chip_mod = 10 } },
    loc_vars = function(self, info_queue, card)
        local extra = (card and card.ability and card.ability.extra) or { chips = 150, chip_mod = 10 }
        return { vars = { extra.chips, extra.chip_mod } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if card.ability.extra.chips > 0 then
                return { chips = card.ability.extra.chips }
            end
            return { calculated = true }
        end

        if context.after and not context.blueprint then
            card.ability.extra.chips = card.ability.extra.chips - card.ability.extra.chip_mod
            if card.ability.extra.chips <= 0 then
                destroy_ice_cream(card)
            end
            return { calculated = true }
        end

        if context.repetition then
            return nil
        end

        if context.end_of_round then
            return { calculated = true }
        end
    end,
})