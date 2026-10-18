local SCHOLAR_GAIN = 4

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
    table.sort(weighted_hands, function(a, b) return a.hand < b.hand end)

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

local function current_mult(card)
    local extra = card and card.ability and card.ability.extra
    if type(extra) == 'table' then
        return tonumber(extra.mult) or 0
    end
    return 0
end

local function hand_has_ace(scoring_hand)
    for _, c in ipairs(scoring_hand or {}) do
        if c and not c.debuff and c:get_id() == 14 then
            return true
        end
    end
    return false
end

SMODS.Joker:take_ownership('scholar', {
    loc_txt = {
        name = 'Scholar',
        text = {
            'This Joker gains {C:mult}+#1#{} Mult if played',
            'hand is a {C:attention}#2#{} containing an {C:attention}Ace{},',
            'poker hand changes when played',
            '{C:inactive}(Currently {C:mult}+#3#{C:inactive} Mult)'
        }
    },
    config = { extra = { mult = 0 } },
    loc_vars = function(self, info_queue, card)
        local target = (card and card.ability and card.ability.target_hand) or 'High Card'
        local target_loc = target
        if rawget(_G,'localize') then
            local ok, loc = pcall(localize, target, 'poker_hands')
            if ok and loc then target_loc = loc end
        end
        return { vars = { SCHOLAR_GAIN, target_loc, current_mult(card) } }
    end,
    set_ability = function(self, card, initial, delay_sprites)
        if not card or not card.ability then return end
        if type(card.ability.extra) ~= 'table' then card.ability.extra = {} end
        card.ability.extra.mult = tonumber(card.ability.extra.mult) or 0
        if not card.ability.target_hand then
            local seed = 'scholar_init_'..((G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante) or 1)..'_'..(card.sort_id or 0)
            card.ability.target_hand = choose_hand_by_levels(card, seed)
        end
    end,
    calculate = function(self, card, context)
        if context.before and context.scoring_name and not context.blueprint then
            if card.ability.target_hand and context.scoring_name == card.ability.target_hand then
                if type(card.ability.extra) ~= 'table' then card.ability.extra = {} end
                local seed = 'scholar_next_'..((G and G.GAME and G.GAME.round) or 0)..'_'..((G and G.GAME and G.GAME.hands_played) or 0)..'_'..(card.sort_id or 0)
                local upgraded = hand_has_ace(context.scoring_hand)
                if upgraded then
                    card.ability.extra.mult = current_mult(card) + SCHOLAR_GAIN
                end
                card.ability.target_hand = choose_hand_by_levels(card, seed)
                if upgraded then
                    return { message = localize('k_upgrade_ex'), colour = G.C.MULT, card = card }
                end
                return {}
            end
            return nil
        end
        if context.individual and context.cardarea == G.play then
            return {}
        end
        if context.joker_main then
            local mult = current_mult(card)
            if mult > 0 then
                return { mult = mult }
            end
            return {}
        end
        return nil
    end,
})
