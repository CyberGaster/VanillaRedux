local ice_cream_round_start_time = nil
local ice_cream_pause_start_time = nil
local ice_cream_total_paused_time = 0
local ice_cream_last_time_penalty = 0

local patched = false

local function update_ice_cream_time_penalty()
    if not G or not G.STATES or not G.TIMERS then 
        return 
    end
    
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
    
    local total_real_time = G.TIMERS.REAL - ice_cream_round_start_time
    local effective_time = total_real_time - ice_cream_total_paused_time
    local time_penalties = math.floor(effective_time / 10)
    
    if G.ICE_CREAM_LAST_PROCESSED_PENALTY == time_penalties then
        return
    end
    
    if time_penalties > ice_cream_last_time_penalty then
        local penalties_to_apply = (time_penalties - ice_cream_last_time_penalty) * 5
        
        G.ICE_CREAM_LAST_PROCESSED_PENALTY = time_penalties
        ice_cream_last_time_penalty = time_penalties
        
        if not G.jokers or not G.jokers.cards or type(G.jokers.cards) ~= 'table' then 
            return 
        end
        
        local ice_cream_jokers_found = 0
        local first_ice_cream_card = nil
        
        for i = 1, #G.jokers.cards do
            local card = G.jokers.cards[i]
            local is_ice_cream = card and card.ability and card.ability.extra and 
                                 ((card.ability.name == 'Ice Cream') or 
                                  (card.config and card.config.center and card.config.center.key == 'j_ice_cream') or
                                  (card.config and card.config.center_key == 'j_ice_cream'))
            
            if is_ice_cream and not card.debuff then
                ice_cream_jokers_found = ice_cream_jokers_found + 1
                if not first_ice_cream_card then
                    first_ice_cream_card = card
                end
                
                card.ability.extra.chips = (card.ability.extra.chips or 200) - penalties_to_apply
                
                if card.ability.extra.chips <= 0 then
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
                                    return true; end})) 
                            return true
                        end
                    }))
                end
            end
        end
        
        if ice_cream_jokers_found > 0 and first_ice_cream_card and penalties_to_apply > 0 then
            card_eval_status_text(first_ice_cream_card, 'extra', nil, nil, nil, {
                message = localize{type='variable',key='a_chips_minus',vars={penalties_to_apply}},
                colour = G.C.CHIPS,
                delay = 0.45
            })
        end
    end
end

return function(center)
    center.config = {extra = {chips = 150, chip_mod = 10}}
    
    local orig_calc = center.calculate
    center.calculate = function(self, card, context)
        if card and card.ability then
            card.ability.name = card.ability.name or 'Ice Cream'
            card.ability.extra = card.ability.extra or {chips = 150, chip_mod = 10}
        end
        return orig_calc and orig_calc(self, card, context) or nil
    end
    
    if not patched then
        patched = true
        
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
        
        G.localization.descriptions.Joker.j_ice_cream = {
            name = "Ice Cream",
            text = {
                "{C:chips}+#1#{} Chips",
                "{C:chips}-#2#{} Chips for",
                "every hand played",
                "{C:chips}-5{} Chips every",
                "{C:attention}10 seconds{} in round"
            }
        }
    end
end