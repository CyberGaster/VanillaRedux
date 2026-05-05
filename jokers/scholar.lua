local DEFAULTS = { mult_step = 1, ace_mult = 1 }

local function to_number_level(raw)
    if type(raw) == 'number' then return raw end
    if type(raw) == 'table' then
        if type(raw.level) == 'number' then return raw.level end
        if type(raw[1]) == 'number' then return raw[1] end
        if type(raw.sign) == 'number' then return raw.sign end
    end
    return 1
end

local function choose_hand_by_levels(card, seed_str)
    local weighted_hands = {}
    local total_weight = 0
    if rawget(_G,'G') and G.GAME and G.GAME.hands then
        for hand_name, hand_data in pairs(G.GAME.hands) do
            if hand_data then
                local visible = hand_data.visible ~= false
                local level_val = to_number_level(hand_data.level)
                level_val = tonumber(level_val) or 1
                if level_val < 0 then level_val = 0 end
                if visible and level_val > 0 then
                    weighted_hands[#weighted_hands+1] = {hand = hand_name, weight = level_val}
                    total_weight = total_weight + level_val
                end
            end
        end
    end

    local last_hand = card and card.ability and card.ability.target_hand
    if #weighted_hands == 0 or total_weight <= 0 then
        return last_hand or 'High Card'
    end
    local attempts = 0
    while attempts < 5 do
        local r = pseudorandom((seed_str or 'scholar_weight') .. '_' .. attempts) * total_weight
        local acc = 0
        for _, item in ipairs(weighted_hands) do
            acc = acc + item.weight
            if r <= acc then
                if item.hand ~= last_hand or #weighted_hands <= 1 then
                    return item.hand
                end
                break
            end
        end
        attempts = attempts + 1
    end
    for _, item in ipairs(weighted_hands) do
        if item.hand ~= last_hand then return item.hand end
    end
    return weighted_hands[1].hand
end

SMODS.Joker:take_ownership('scholar', {
    loc_txt = {
        name = 'Scholar',
        text = {
            'Played {C:attention}Aces{} give {C:mult}+#2#{} Mult when scored',
            'Gains {C:mult}+1{} Mult when a {C:attention}#1#{} is played,',
            'poker hand changes at end of round',
            '{C:inactive}(Currently {C:mult}+#2#{} {C:inactive}Mult){}'
        }
    },
    config = { extra = { mult_step = DEFAULTS.mult_step, ace_mult = DEFAULTS.ace_mult } },
    loc_vars = function(self, info_queue, card)
        local target = (card and card.ability and card.ability.target_hand) or 'High Card'
        local ace = (card and card.ability and card.ability.ace_mult) or DEFAULTS.ace_mult
        local ace_val = tonumber(ace) or DEFAULTS.ace_mult
        local ace_str = tostring(math.floor(ace_val + 0.0001))
        local target_loc = target
        if rawget(_G,'localize') then
            local ok, loc = pcall(localize, target, 'poker_hands')
            if ok and loc then target_loc = loc end
        end
        return { vars = { target_loc, ace_str } }
    end,
    set_ability = function(self, card, initial, delay_sprites)
        if not card or not card.ability then return end
        card.ability.mult = card.ability.mult or 0
        card.ability.mult_step = card.ability.mult_step or DEFAULTS.mult_step
        card.ability.ace_mult = card.ability.ace_mult or DEFAULTS.ace_mult
        if not card.ability.target_hand then
            local seed = 'scholar_init_'..((G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante) or 1)..'_'..(card.sort_id or 0)
            card.ability.target_hand = choose_hand_by_levels(card, seed)
        end
    end,
    calculate = function(self, card, context)
        if context.setting_blind then
            card.ability.changed_this_round = nil
            return nil
        end
        if context.before and context.scoring_name and not context.blueprint then
            if card.ability.target_hand and context.scoring_name == card.ability.target_hand then
                card.ability.ace_mult = (card.ability.ace_mult or DEFAULTS.ace_mult) + (card.ability.mult_step or DEFAULTS.mult_step)
                return nil
            end
        end
        if context.after and not card.ability.changed_this_round then
            local chip_total = (G.GAME and G.GAME.current_round and G.GAME.current_round.current_hand and G.GAME.current_round.current_hand.chip_total) or 0
            local projected = (G.GAME and G.GAME.chips or 0) + (tonumber(chip_total) or 0)
            local req = (G.GAME and G.GAME.blind and G.GAME.blind.chips) or math.huge
            if projected >= req then
                local seed = 'scholar_after_'..((G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante) or 1)..'_'..(G and G.GAME and G.GAME.round or 0)..'_'..(card.sort_id or 0)
                card.ability.target_hand = choose_hand_by_levels(card, seed)
                card.ability.changed_this_round = true
                return nil
            end
        end
        if context.individual and context.cardarea == G.play and context.other_card and not context.other_card.debuff then
            if context.other_card:get_id() == 14 then
                local amt = card.ability.ace_mult or DEFAULTS.ace_mult
                if amt ~= 0 then return { mult = amt, card = card } end
            end
        end
        if context.end_of_round and not card.ability.changed_this_round then
            local seed = 'scholar_next_'..((G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante) or 1)..'_'..(G and G.GAME and G.GAME.round or 0)..'_'..(card.sort_id or 0)
            card.ability.target_hand = choose_hand_by_levels(card, seed)
            card.ability.changed_this_round = true
            return nil
        end
        return nil
    end,
})