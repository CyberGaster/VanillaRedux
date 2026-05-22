local ice_cream_round_start_time = nil
local ice_cream_pause_start_time = nil
local ice_cream_total_paused_time = 0
local ice_cream_last_time_penalty = 0

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
    if not G or not G.STATES or not G.TIMERS then return end

    if G.STATE == G.STATES.SELECTING_HAND or G.STATE == G.STATES.DRAW_TO_HAND then
        if not ice_cream_round_start_time then
            ice_cream_round_start_time = G.TIMERS.REAL
            ice_cream_total_paused_time = 0
            ice_cream_last_time_penalty = 0
            G.ICE_CREAM_LAST_PROCESSED_PENALTY = nil
        end
        if ice_cream_pause_start_time then
            ice_cream_total_paused_time = ice_cream_total_paused_time + (G.TIMERS.REAL - ice_cream_pause_start_time)
            ice_cream_pause_start_time = nil
        end
    else
        if ice_cream_round_start_time and not ice_cream_pause_start_time then
            ice_cream_pause_start_time = G.TIMERS.REAL
        end
        return
    end

    local effective_time = (G.TIMERS.REAL - ice_cream_round_start_time) - ice_cream_total_paused_time
    local time_penalties = math.floor(effective_time / 10)

    if G.ICE_CREAM_LAST_PROCESSED_PENALTY == time_penalties then return end
    if time_penalties <= ice_cream_last_time_penalty then return end

    local penalties_to_apply = (time_penalties - ice_cream_last_time_penalty) * 5
    G.ICE_CREAM_LAST_PROCESSED_PENALTY = time_penalties
    ice_cream_last_time_penalty = time_penalties

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
    ice_cream_round_start_time = nil
    ice_cream_pause_start_time = nil
    ice_cream_total_paused_time = 0
    ice_cream_last_time_penalty = 0
    G.ICE_CREAM_LAST_PROCESSED_PENALTY = nil
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