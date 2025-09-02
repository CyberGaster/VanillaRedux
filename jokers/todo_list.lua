if not _G.last_random_values then
    _G.last_random_values = {}
end

local function is_enhanced_card(c)
    if not c or not c.ability then return false end
    if c.ability.effect == 'Stone Card' then return true end
    local n = c.ability.name
    return n == 'Glass Card' or n == 'Gold Card' or n == 'Steel Card' or n == 'Wild Card' or n == 'Lucky Card'
end

local function _rand01(seed)
    local s = tostring(seed or 'todo')
    if rawget(_G, 'pseudoseed') then
        local ok, val = pcall(pseudoseed, s)
        if ok and type(val) == 'number' then
            if val >= 1 then val = val % 1 end
            if val < 0 then val = val - math.floor(val) end
            return val
        end
    end
    if rawget(_G, 'pseudohash') then
        local v = pseudohash(s)
        if v >= 1 then v = v % 1 end
        if v < 0 then v = v - math.floor(v) end
        return v
    end
    local a, c, m = 1664525, 1013904223, 2^32
    local hash = 0
    for i = 1, #s do
        hash = (hash * 31 + string.byte(s, i)) % m
    end
    hash = (a * hash + c) % m
    return hash / m
end

local function _iter_area(area, out)
    if area and area.cards then
        for i = 1, #area.cards do out[#out+1] = area.cards[i] end
    end
end

local function get_all_deck_cards()
    local cards = {}
    if not rawget(_G,'G') then return cards end
    _iter_area(G.deck, cards)
    _iter_area(G.hand, cards)
    _iter_area(G.play, cards)
    _iter_area(G.discard, cards)
    return cards
end

local function get_deck_stats()
    local stats = {
        suits = {Hearts = 0, Diamonds = 0, Clubs = 0, Spades = 0},
        face = 0,
        number = 0,
        enhanced = 0,
        total = 0
    }
    local cards = get_all_deck_cards()
    for i = 1, #cards do
        local c = cards[i]
        stats.total = stats.total + 1
        if c.is_suit then
            if c:is_suit('Hearts') then stats.suits.Hearts = stats.suits.Hearts + 1 end
            if c:is_suit('Diamonds') then stats.suits.Diamonds = stats.suits.Diamonds + 1 end
            if c:is_suit('Clubs') then stats.suits.Clubs = stats.suits.Clubs + 1 end
            if c:is_suit('Spades') then stats.suits.Spades = stats.suits.Spades + 1 end
        end
        if c.is_face and c:is_face(true) then
            stats.face = stats.face + 1
        else
            local id = c.get_id and c:get_id() or 0
            if id >= 2 and id <= 10 then stats.number = stats.number + 1 end
        end
        if is_enhanced_card(c) then
            stats.enhanced = stats.enhanced + 1
        end
    end
    return stats
end

local function pseudo_shuffle(t, seed)
    if not t or #t <= 1 then return t end
    for i = #t, 2, -1 do
        local j = math.floor(_rand01((seed or 'todo_shuffle') .. '_' .. i) * i) + 1
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function weighted_random(min_val, max_val, seed_str)
    local range = max_val - min_val + 1
    if range <= 1 then return min_val end
    
    local weights = {}
    local total_weight = 0
    local center = (min_val + max_val) / 2
    
    for i = 1, range do
        local value = min_val + i - 1
        local distance_from_center = math.abs(value - center)
        local max_distance = math.max(math.abs(min_val - center), math.abs(max_val - center))
        
        local normalized_distance = max_distance > 0 and (distance_from_center / max_distance) or 0
        
        local weight = math.exp(-(normalized_distance * normalized_distance * 2))
        weights[i] = weight
        total_weight = total_weight + weight
    end
    
    local attempts = 0
    local max_attempts = 5
    local last_value = _G.last_random_values[seed_str or 'default']
    
    while attempts < max_attempts do
        local rand_val = _rand01((seed_str or 'weighted') .. '_' .. attempts) * total_weight
        local cumulative = 0
        
        for i = 1, range do
            cumulative = cumulative + weights[i]
            if rand_val <= cumulative then
                local selected_value = min_val + i - 1
                
                if selected_value ~= last_value or range <= 2 then
                    _G.last_random_values[seed_str or 'default'] = selected_value
                    return selected_value
                end
                break
            end
        end
        attempts = attempts + 1
    end
    
    for i = 1, range do
        local value = min_val + i - 1
        if value ~= last_value then
            _G.last_random_values[seed_str or 'default'] = value
            return value
        end
    end
    
    return min_val
end

local function weighted_random_centered(min_val, max_val, seed_str, scale)
    local range = max_val - min_val + 1
    if range <= 1 then return min_val end

    local weights = {}
    local total_weight = 0
    local center = (min_val + max_val) / 2
    local s = tonumber(scale) or 6

    for i = 1, range do
        local value = min_val + i - 1
        local distance_from_center = math.abs(value - center)
        local max_distance = math.max(math.abs(min_val - center), math.abs(max_val - center))
        local normalized_distance = (max_distance > 0) and (distance_from_center / max_distance) or 0
        local w = math.exp(-s * normalized_distance * normalized_distance)
        weights[i] = w
        total_weight = total_weight + w
    end

    local attempts = 0
    local max_attempts = 5
    local last_key = (seed_str or 'default_center')
    local last_value = _G.last_random_values[last_key]
    while attempts < max_attempts do
        local rand_val = _rand01((last_key) .. '_' .. attempts) * total_weight
        local cumulative = 0
        for i = 1, range do
            cumulative = cumulative + weights[i]
            if rand_val <= cumulative then
                local selected_value = min_val + i - 1
                if selected_value ~= last_value or range <= 2 then
                    _G.last_random_values[last_key] = selected_value
                    return selected_value
                end
                break
            end
        end
        attempts = attempts + 1
    end
    for i = 1, range do
        local value = min_val + i - 1
        if value ~= last_value then
            _G.last_random_values[last_key] = value
            return value
        end
    end
    return min_val
end

local function weighted_random_low(min_val, max_val, seed_str)
    local range = max_val - min_val + 1
    if range <= 1 then return min_val end

    local weights = {}
    local total_weight = 0
    for i = 1, range do
        local normalized_pos = (i - 1) / (range - 1)
        local w = math.exp(-normalized_pos * 2)
        weights[i] = w
        total_weight = total_weight + w
    end

    local attempts = 0
    local max_attempts = 3
    local last_key = (seed_str or 'default_low')
    local last_value = _G.last_random_values[last_key]
    while attempts < max_attempts do
        local rand_val = _rand01((seed_str or 'weighted_low') .. '_' .. attempts) * total_weight
        local cumulative = 0
        for i = 1, range do
            cumulative = cumulative + weights[i]
            if rand_val <= cumulative then
                local selected_value = min_val + i - 1
                if selected_value ~= last_value or range <= 2 then
                    _G.last_random_values[last_key] = selected_value
                    return selected_value
                end
                break
            end
        end
        attempts = attempts + 1
    end
    for i = 1, range do
        local value = min_val + i - 1
        if value ~= last_value then
            _G.last_random_values[last_key] = value
            return value
        end
    end
    return min_val
end

local function weighted_random_high(min_val, max_val, seed_str)
    local range = max_val - min_val + 1
    if range <= 1 then return min_val end

    local weights = {}
    local total_weight = 0
    for i = 1, range do
        local normalized_pos = (i - 1) / (range - 1)
                    local w = math.exp(normalized_pos * 2 - 2)
        weights[i] = w
        total_weight = total_weight + w
    end

    local attempts = 0
    local max_attempts = 3
    local last_key = (seed_str or 'default_high')
    local last_value = _G.last_random_values[last_key]
    while attempts < max_attempts do
        local rand_val = _rand01((seed_str or 'weighted_high') .. '_' .. attempts) * total_weight
        local cumulative = 0
        for i = 1, range do
            cumulative = cumulative + weights[i]
            if rand_val <= cumulative then
                local selected_value = min_val + i - 1
                if selected_value ~= last_value or range <= 2 then
                    _G.last_random_values[last_key] = selected_value
                    return selected_value
                end
                break
            end
        end
        attempts = attempts + 1
    end
    for i = 1, range do
        local value = min_val + i - 1
        if value ~= last_value then
            _G.last_random_values[last_key] = value
            return value
        end
    end
    return min_val
end

local function choose_plural(n, singular, plural)
    if tonumber(n) == 1 then return singular else return plural end
end

local function _is_active_blind_state(state)
    return state == 'Current' or state == 'Upcoming' or state == 'Select'
end

local function get_rounds_left_to_boss()
    local default_rounds = 3
    if not rawget(_G, 'G') then return default_rounds end
    if not G.GAME or not G.GAME.round_resets then return default_rounds end
    local states = G.GAME.round_resets.blind_states or {}
    local small = states.Small or 'Select'
    local big = states.Big or 'Upcoming'
    local boss = states.Boss or 'Upcoming'

    local rounds = 0
    if _is_active_blind_state(small) then rounds = rounds + 1 end
    if _is_active_blind_state(big) then rounds = rounds + 1 end
    if _is_active_blind_state(boss) then rounds = rounds + 1 end
    if rounds <= 0 then rounds = default_rounds end
    return rounds
end

local function estimate_total_hands_until_boss()
    if not rawget(_G, 'G') then return 12 end
    local rr = G.GAME and G.GAME.round_resets or nil
    if not rr then return 12 end
    local hands_per_round = tonumber(rr.hands or 4) or 4
    if hands_per_round <= 0 then hands_per_round = 4 end
    local rounds_left = get_rounds_left_to_boss()
    
    if rounds_left <= 0 then
        rounds_left = 3
    end
    
    return rounds_left * hands_per_round
end

local function estimate_total_discards_until_boss()
    if not rawget(_G, 'G') then return 9 end
    local rr = G.GAME and G.GAME.round_resets or nil
    if not rr then return 9 end
    local discards_per_round = tonumber(rr.discards or 3) or 3
    if discards_per_round <= 0 then discards_per_round = 3 end
    local rounds_left = get_rounds_left_to_boss()
    
    if rounds_left <= 0 then
        rounds_left = 3
    end
    
    return rounds_left * discards_per_round
end

local function count_other_jokers(this_card)
    if not rawget(_G, 'G') or not G.jokers or not G.jokers.cards then return 0 end
    local n = 0
    for i = 1, #G.jokers.cards do
        local j = G.jokers.cards[i]
        if j and j ~= this_card then n = n + 1 end
    end
    return n
end

local function get_consumable_slots()
    if not rawget(_G, 'G') then return 0 end
    return (G.consumeables and G.consumeables.config and tonumber(G.consumeables.config.card_limit or 0)) or 0
end

local function can_skip_any_blind()
    if not rawget(_G, 'G') or not G.GAME or not G.GAME.round_resets then return false end
    local states = G.GAME.round_resets.blind_states or {}
    local boss = states.Boss or 'Upcoming'
    if boss == 'Current' then return false end
    local function can(s)
        return s == 'Current' or s == 'Upcoming' or s == 'Select'
    end
    return can(states.Small or 'Select') or can(states.Big or 'Upcoming')
end

local function to_number_level(raw)
    if type(raw) == 'number' then return raw end
    if type(raw) == 'table' then
        if type(raw.level) == 'number' then return raw.level end
        if type(raw[1]) == 'number' then return raw[1] end
        if type(raw.sign) == 'number' then return raw.sign end
    end
    return 1
end

local function get_poker_hand_by_levels(seed_str)
    local weighted_hands = {}
    local total_weight = 0
    
    if G and G.GAME and G.GAME.hands then
        for k, v in pairs(G.GAME.hands) do
            local visible = (v and v.visible ~= false)
            if visible then
                local lvl = to_number_level(v and v.level)
                lvl = tonumber(lvl) or 1
                if lvl < 0 then lvl = 0 end
                if lvl > 0 then
                    table.insert(weighted_hands, {hand = k, weight = lvl})
                    total_weight = total_weight + lvl
                end
            end
        end
    end
    
    if #weighted_hands == 0 then
        local fallback_hands = {'High Card', 'Pair', 'Two Pair', 'Three of a Kind', 'Straight', 'Flush', 'Full House', 'Four of a Kind', 'Straight Flush'}
        for _, hand in ipairs(fallback_hands) do
            table.insert(weighted_hands, {hand = hand, weight = 1})
            total_weight = total_weight + 1
        end
    end
    
    if (tonumber(total_weight) or 0) > 0 and #weighted_hands > 0 then
        local last_hand = _G.last_random_values[seed_str .. '_poker_hand']
        local attempts = 0
        local max_attempts = 5
        
        while attempts < max_attempts do
            local random_value = _rand01((seed_str or 'poker_hand_selection') .. '_' .. attempts) * total_weight
            local current_weight = 0
            
            for _, hand_data in ipairs(weighted_hands) do
                current_weight = current_weight + (tonumber(hand_data.weight) or 0)
                if random_value <= current_weight then
                    if hand_data.hand ~= last_hand or #weighted_hands <= 1 then
                        _G.last_random_values[seed_str .. '_poker_hand'] = hand_data.hand
                        return hand_data.hand
                    end
                    break
                end
            end
            attempts = attempts + 1
        end
        
        for _, hand_data in ipairs(weighted_hands) do
            if hand_data.hand ~= last_hand then
                _G.last_random_values[seed_str .. '_poker_hand'] = hand_data.hand
                return hand_data.hand
            end
        end
        
        if #weighted_hands > 0 then
            local selected = weighted_hands[1].hand
            _G.last_random_values[seed_str .. '_poker_hand'] = selected
            return selected
        end
    end
    
    return 'High Card'
end

local function _todo_format_line(task)
    if not task then return ' ' end
    local remain = math.max(0, (task.needed or 0) - (task.current or 0))
    if task.type == 'hands' then
        local label = choose_plural(remain, 'hand', 'hands')
        return ('Play {C:attention}%d{} {C:blue}%s{}'):format(remain, label)
    elseif task.type == 'discards' then
        local label = choose_plural(remain, 'discard', 'discards')
        return ('Make {C:attention}%d{} {C:red}%s{}'):format(remain, label)
    elseif task.type == 'poker_hand' then
        local hand_name = task.target_hand or 'High Card'
        if localize and type(hand_name) == 'string' then
            local ok, loc = pcall(localize, hand_name, 'poker_hands')
            hand_name = (ok and loc) or hand_name
        end
        return ('Play {C:attention}%d{} {C:attention}%s{}'):format(remain, tostring(hand_name))
    elseif task.type == 'jokers' then
        local label = choose_plural(remain, 'time', 'times')
        return ('Trigger other {C:inactive}Jokers{} {C:attention}%d{} %s'):format(remain, label)
    elseif task.type == 'consumables' then
        local label = choose_plural(remain, 'consumable', 'consumables')
        return ('Use {C:attention}%d{} {C:purple}%s{}'):format(remain, label)
    elseif task.type == 'skip_blind' then
        return ('Skip {C:attention}%d{} {C:attention}Blind{}'):format(remain)
    elseif task.type == 'discard_face' then
        local label = choose_plural(remain, 'face card', 'face cards')
        return ('Discard {C:attention}%d{} {C:red}%s{}'):format(remain, label)
    elseif task.type == 'discard_number' then
        local label = choose_plural(remain, 'numbered card', 'numbered cards')
        return ('Discard {C:attention}%d{} {C:red}%s{}'):format(remain, label)
    elseif task.type == 'discard_suit' then
        local suit_name = task.suit or 'Hearts'
        if localize and suit_name then
            local suite_form = (remain == 1) and 'suits_singular' or 'suits_plural'
            local ok, loc = pcall(localize, suit_name, suite_form)
            suit_name = (ok and loc) or suit_name
        end
        local suit_key = string.lower(task.suit or 'hearts')
        local label = choose_plural(remain, 'card', 'cards')
        return ('Discard {C:attention}%d{} {C:%s}%s{}{C:inactive} %s{}'):format(remain, suit_key, tostring(suit_name), label)
    elseif task.type == 'play_enhanced' then
        local label = choose_plural(remain, 'card', 'cards')
        return ('Play {C:attention}%d{} {C:dark_edition}Enhanced{} %s'):format(remain, label)
    end
    return ' '
end

local function set_templates_for_tasks(center, tasks)
    if not center or not tasks then return end
    center.loc_txt = center.loc_txt or {name = 'To Do List', text = center.loc_txt and center.loc_txt.text or {}}
    for i = 1, 5 do
        center.loc_txt.text[2+i] = _todo_format_line(tasks[i])
    end
    if rawget(_G,'G') and G.localization and G.localization.descriptions 
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_todo_list then
        local entry = G.localization.descriptions.Joker.j_todo_list
        entry.text = entry.text or {}
        entry.text_parsed = entry.text_parsed or {}
        for i = 1, 5 do
            entry.text[2+i] = center.loc_txt.text[2+i]
            if rawget(_G, 'loc_parse_string') then
                entry.text_parsed[2+i] = loc_parse_string(entry.text[2+i])
            end
        end
    end
end

local function reset_tasks_for_ante(center, card, current_ante)
    if not card then return end
    card.ability.todo_tasks = nil
    if _G.last_random_values then
        _G.last_random_values = {}
    end
    card.ability.todo_tasks = generate_tasks(card)
    card.ability.todo_reward_claimed = false
    card.ability.todo_ante = current_ante
    card.ability._todo_boss_reset_ante = current_ante
    set_templates_for_tasks(center, card.ability.todo_tasks)
end

local function generate_tasks(card)
    local ante = (G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante) or 1
    local stake = (G and G.GAME and G.GAME.stake) or 1
    local seed_base = 'todo_' .. (card and card.sort_id or 0) .. '_' .. ante .. '_' .. stake
    
    local _ = (G and G.jokers and G.jokers.cards and #G.jokers.cards) or 5
    local __ = (G and G.jokers and G.jokers.config and G.jokers.config.card_limit) or 5
    
    local stats = get_deck_stats()
    local candidates = {}

    local function push(t) candidates[#candidates+1] = t end

    local est_hands_total = estimate_total_hands_until_boss()
    local est_discards_total = estimate_total_discards_until_boss()
    
    local rr = (G and G.GAME and G.GAME.round_resets) or {}
    local hands_per_round = tonumber(rr.hands or 4) or 4
    local discards_per_round = tonumber(rr.discards or 3) or 3
    local can_skip = can_skip_any_blind()
    local rounds_left = get_rounds_left_to_boss() or 3
    if rounds_left <= 0 then rounds_left = 3 end
    local rounds_effective = math.max(1, rounds_left - (can_skip and 1 or 0))
    
    local h_total_eff = math.max(0, est_hands_total or 0)
    if can_skip then h_total_eff = math.max(0, h_total_eff - hands_per_round) end
    local h_min = math.max(1, math.min(rounds_effective, h_total_eff))
    local h_max = math.max(h_min, h_total_eff)
    push({ type = 'hands', needed = weighted_random_centered(h_min, h_max, seed_base .. '_hands', 8), current = 0, completed = false })
    
    local d_total_eff = math.max(0, est_discards_total or 0)
    if can_skip then d_total_eff = math.max(0, d_total_eff - discards_per_round) end
    local d_min = math.max(1, math.min(rounds_effective, d_total_eff))
    local d_max = math.max(d_min, d_total_eff)
    push({ type = 'discards', needed = weighted_random_centered(d_min, d_max, seed_base .. '_discards', 8), current = 0, completed = false })
    
    do
        local p_min = 1
        local p_max = math.max(1, math.min(5, math.floor((h_total_eff or 0) * 0.3)))
        local target = get_poker_hand_by_levels(seed_base .. '_poker')
        push({ type = 'poker_hand', needed = weighted_random_centered(p_min, p_max, seed_base .. '_poker_needed', 8), current = 0, completed = false, target_hand = target })
    end
    
    do
        local other_jokers = count_other_jokers(card)
        if other_jokers > 0 then
            local est_triggers = other_jokers * math.max(1, est_hands_total or 4)
            local j_min = math.max(3, other_jokers * 3)
            local j_max = math.min(est_triggers, math.floor(est_triggers * 0.7))
            if j_max >= j_min then
                push({ type = 'jokers', needed = weighted_random(j_min, j_max, seed_base .. '_jokers'), current = 0, completed = false })
            end
        end
    end
    
    do
        local slots = get_consumable_slots()
        if slots > 0 then
            local rounds = get_rounds_left_to_boss() or 3
            local est_uses = math.max(1, rounds * slots)
            local c_min = math.max(rounds, math.floor(slots * 0.75))
            local c_max = math.min(est_uses, math.floor(est_uses * 0.8))
            if c_max >= c_min then
                push({ type = 'consumables', needed = weighted_random(c_min, c_max, seed_base .. '_consumables'), current = 0, completed = false })
            end
        end
    end

    if can_skip_any_blind() then
        push({ type = 'skip_blind', needed = 1, current = 0, completed = false })
    end

    local discard_card_cap = math.max(0, (tonumber(d_total_eff or 0) or 0) * 5)
    
    
    if (stats.face or 0) > 0 and discard_card_cap > 0 then
        local face_count = stats.face
        local face_min = 1
        local face_max = math.min(face_count, discard_card_cap)
        if face_max < face_min then face_max = face_min end
        push({ type = 'discard_face', needed = weighted_random(face_min, face_max, seed_base .. '_discard_face'), current = 0, completed = false })
    end
    if (stats.number or 0) > 0 and discard_card_cap > 0 then
        local num_count = stats.number
        local num_min = 1
        local num_max = math.min(num_count, discard_card_cap)
        if num_max < num_min then num_max = num_min end
        push({ type = 'discard_number', needed = weighted_random(num_min, num_max, seed_base .. '_discard_number'), current = 0, completed = false })
    end
    
    local available_suits = {}
    for _, suit in ipairs({'Hearts','Diamonds','Clubs','Spades'}) do
        local cnt = (stats.suits and stats.suits[suit]) or 0
        if cnt > 0 then
            table.insert(available_suits, {suit = suit, count = cnt})
        end
    end
    
    if #available_suits > 0 and discard_card_cap > 0 then
        pseudo_shuffle(available_suits, seed_base .. '_suits_shuffle')
        local suits_to_add = math.min(2, #available_suits)
        for i = 1, suits_to_add do
            local suit_data = available_suits[i]
            local suit_count = suit_data.count
            local suit_min = 1
            local suit_max = math.min(suit_count, discard_card_cap)
            if suit_max < suit_min then suit_max = suit_min end
            push({ type = 'discard_suit', suit = suit_data.suit, needed = weighted_random(suit_min, suit_max, seed_base .. '_discard_suit_' .. suit_data.suit), current = 0, completed = false })
        end
    end
    
    if (stats.enhanced or 0) > 0 then
        local enhanced_min = math.max(1, math.floor(stats.enhanced * 0.5))
        local enhanced_max = math.min(stats.enhanced, math.floor((est_hands_total or 12) * 0.5))
        if enhanced_max >= enhanced_min then
            push({ type = 'play_enhanced', needed = weighted_random(enhanced_min, enhanced_max, seed_base .. '_play_enhanced'), current = 0, completed = false })
        end
    end

    pseudo_shuffle(candidates, seed_base .. '_pool')
    local tasks = {}
    
    local base_tasks = {'hands', 'discards', 'poker_hand'}
    local has_base = {}
    
    for i = 1, #candidates do
        for _, base_type in ipairs(base_tasks) do
            if candidates[i].type == base_type and not has_base[base_type] then
                tasks[#tasks + 1] = candidates[i]
                has_base[base_type] = true
                break
            end
        end
    end
    
    for i = 1, #candidates do
        local already_added = false
        for j = 1, #tasks do
            if tasks[j] == candidates[i] then
                already_added = true
                break
            end
        end
        if not already_added and #tasks < 5 then
            tasks[#tasks + 1] = candidates[i]
        end
    end
    
    local used_types = {}
    for _, task in ipairs(tasks) do
        if task.type ~= 'discard_suit' then
            used_types[task.type] = true
        end
    end
    
    while #tasks < 5 do
        if #candidates > 0 then
            local added = false
            for i = 1, #candidates do
                local candidate = candidates[i]
                local already_in_tasks = false
                
                for j = 1, #tasks do
                    if tasks[j] == candidate then
                        already_in_tasks = true
                        break
                    end
                    if candidate.type ~= 'discard_suit' and tasks[j].type == candidate.type then
                        already_in_tasks = true
                        break
                    end
                    if candidate.type == 'discard_suit' and tasks[j].type == 'discard_suit' and tasks[j].suit == candidate.suit then
                        already_in_tasks = true
                        break
                    end
                end
                
                if not already_in_tasks then
                    tasks[#tasks + 1] = candidate
                    if candidate.type ~= 'discard_suit' then
                        used_types[candidate.type] = true
                    end
                    added = true
                    break
                end
            end
            
            if not added then
                break
            end
        else
            break
        end
    end
    
    while #tasks < 5 do
        local fallback_types = {'hands', 'discards', 'poker_hand'}
        local added = false
        for _, ftype in ipairs(fallback_types) do
            if not used_types[ftype] then
                local fneeded = 1
                if ftype == 'hands' then 
                    fneeded = math.max(3, math.floor((est_hands_total or 12) * 0.5))
                elseif ftype == 'discards' then
                    fneeded = math.max(2, math.floor((est_discards_total or 9) * 0.5))
                end
                tasks[#tasks + 1] = { type = ftype, needed = fneeded, current = 0, completed = false }
                used_types[ftype] = true
                added = true
                break
            end
        end
        if not added then break end
    end
    
    while #tasks > 5 do
        table.remove(tasks, #tasks)
    end

    local has_skip = false
    for i = 1, #tasks do
        if tasks[i] and tasks[i].type == 'skip_blind' then has_skip = true; break end
    end
    if has_skip and rawget(_G,'G') and G.GAME and G.GAME.round_resets then
        local rr = G.GAME.round_resets
        local hands_per_round = math.max(0, tonumber(rr.hands or 0) or 0)
        local discards_per_round = math.max(0, tonumber(rr.discards or 0) or 0)
        local other_jokers = count_other_jokers(card)
        local slots = get_consumable_slots()

        if #candidates >= 6 then
            local roll = _rand01('skip_blind_rarity')
            if roll and roll < 0.7 then
                for i = #tasks, 1, -1 do
                    if tasks[i] and tasks[i].type == 'skip_blind' then 
                        table.remove(tasks, i)
                        has_skip = false
                        for j = 1, #candidates do
                            local replacement_found = false
                            for k = 1, #tasks do
                                if tasks[k] == candidates[j] then
                                    replacement_found = true
                                    break
                                end
                            end
                            if not replacement_found and candidates[j].type ~= 'skip_blind' then
                                tasks[#tasks + 1] = candidates[j]
                                break
                            end
                        end
                        break
                    end
                end
            end
        end

        for i = 1, #tasks do
            local t = tasks[i]
            if t then
                if t.type == 'hands' then
                    if hands_per_round > 0 then
                        local min_h = math.max(2, math.floor(hands_per_round * 0.4))
                        local max_h = math.min(hands_per_round, math.floor(hands_per_round * 0.8))
                        t.needed = weighted_random_centered(min_h, max_h, seed_base .. '_hands_scaled2', 8)
                    else
                        t.needed = 2
                    end
                elseif t.type == 'discards' then
                    if discards_per_round > 0 then
                        local min_d = math.max(2, math.floor(discards_per_round * 0.4))
                        local max_d = math.min(discards_per_round, math.floor(discards_per_round * 0.8))
                        t.needed = weighted_random_centered(min_d, max_d, seed_base .. '_discards_scaled2', 8)
                    else
                        t.needed = 2
                    end
                elseif t.type == 'discard_face' then
                    if discards_per_round > 0 and stats then
                        local face_count = stats.face or 0
                        local face_min = math.max(1, math.floor(face_count * 0.2))
                        local face_max = math.min(face_count - 1, math.floor(face_count * 0.4), discard_card_cap)
                        if face_max >= face_min then
                            t.needed = weighted_random(face_min, face_max, seed_base .. '_discard_face_scaled2')
                        else
                            t.needed = math.min(2, face_count)
                        end
                    else
                        t.needed = 2
                    end
                elseif t.type == 'discard_suit' then
                    if discards_per_round > 0 and t.suit and stats and stats.suits then
                        local suit_count = stats.suits[t.suit] or 0
                        local suit_min = math.max(1, math.floor(suit_count * 0.15))
                        local suit_max = math.min(suit_count - 1, math.floor(suit_count * 0.35), discard_card_cap)
                        if suit_max >= suit_min then
                            t.needed = weighted_random(suit_min, suit_max, seed_base .. '_discard_suit_scaled2')
                        else
                            t.needed = math.min(2, suit_count)
                        end
                    else
                        t.needed = 2
                    end
                elseif t.type == 'discard_number' then
                    if discards_per_round > 0 and stats then
                        local num_count = stats.number or 0
                        local num_min = math.max(2, math.floor(num_count * 0.2))
                        local num_max = math.min(num_count - 2, math.floor(num_count * 0.4), discard_card_cap)
                        if num_max >= num_min then
                            t.needed = weighted_random(num_min, num_max, seed_base .. '_discard_number_scaled2')
                        else
                            t.needed = math.min(3, num_count)
                        end
                    else
                        t.needed = 3
                    end
                elseif t.type == 'jokers' then
                    if hands_per_round > 0 and other_jokers > 0 then
                        local max_triggers = math.max(1, other_jokers * hands_per_round)
                        local min_triggers = math.max(1, other_jokers)
                        t.needed = weighted_random(min_triggers, max_triggers, seed_base .. '_jokers_scaled2')
                    else
                        t.needed = 1
                    end
                elseif t.type == 'consumables' then
                    if slots > 0 then
                        local min_c = 1
                        local max_c = math.max(min_c, slots)
                        t.needed = weighted_random(min_c, max_c, seed_base .. '_consumables_scaled2')
                    else
                        t.needed = 1
                    end
                elseif t.type == 'play_enhanced' then
                    if hands_per_round > 0 then
                        local max_e = math.max(1, math.min(stats and stats.enhanced or 1, hands_per_round))
                        t.needed = weighted_random(1, max_e, seed_base .. '_play_enhanced_scaled2')
                    else
                        t.needed = 1
                    end
                end
            end
        end
    end
    
    if #tasks < 5 then
        local used_types_post = {}
        for _, t in ipairs(tasks) do
            if t.type ~= 'discard_suit' then
                used_types_post[t.type] = true
            end
        end
        for i = 1, #candidates do
            if #tasks >= 5 then break end
            local candidate = candidates[i]
            local already_in = false
            for j = 1, #tasks do
                if tasks[j] == candidate then
                    already_in = true; break
                end
                if candidate.type ~= 'discard_suit' and tasks[j].type == candidate.type then
                    already_in = true; break
                end
                if candidate.type == 'discard_suit' and tasks[j].type == 'discard_suit' and tasks[j].suit == candidate.suit then
                    already_in = true; break
                end
            end
            if not already_in then
                tasks[#tasks+1] = candidate
                if candidate.type ~= 'discard_suit' then
                    used_types_post[candidate.type] = true
                end
            end
        end
        local fallback_types = {'hands','discards','poker_hand'}
        while #tasks < 5 do
            local added = false
            for _, ftype in ipairs(fallback_types) do
                if not used_types_post[ftype] then
                    local fneeded = 1
                    if ftype == 'hands' then
                        local est_h = est_hands_total or 12
                        local fmin = math.max(2, math.floor(est_h * 0.4))
                        local fmax = math.max(fmin, math.floor(est_h * 0.6))
                        fneeded = weighted_random_centered(fmin, fmax, seed_base .. '_hands_fallback', 8)
                    elseif ftype == 'discards' then
                        local est_d = est_discards_total or 9
                        local fmin = math.max(1, math.floor(est_d * 0.4))
                        local fmax = math.max(fmin, math.floor(est_d * 0.6))
                        fneeded = weighted_random_centered(fmin, fmax, seed_base .. '_discards_fallback', 8)
                    end
                    tasks[#tasks+1] = { type = ftype, needed = fneeded, current = 0, completed = false }
                    used_types_post[ftype] = true
                    added = true
                    break
                end
            end
            if not added then break end
        end
    end
    while #tasks > 5 do
        table.remove(tasks, #tasks)
    end

    return tasks
end

local function all_tasks_completed(tasks)
    if not tasks or #tasks == 0 then 
        return false 
    end
    
    local completed_count = 0
    local total_count = #tasks
    
    for _, task in ipairs(tasks) do
        if task.completed then
            completed_count = completed_count + 1
        end
    end
    
    return completed_count == total_count
end

SMODS.Joker:take_ownership('j_todo_list', {
    no_mod_display = true,
    loc_txt = {
        name = "To Do List",
        text = {
            'Earn {C:money}$20{} by completing all',
            'tasks before defeating {C:attention}Boss Blind{}:',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            'Tasks reset each complete {C:attention}Ante{}'
        }
    },
    
    config = {
        extra = {
            dollars = 20
        }
    },
    
    loc_vars = function(self, info_queue, card)
        local vars = {}
        local tasks = (card and card.ability and type(card.ability.todo_tasks) == 'table') and card.ability.todo_tasks or {}
        if self and self.loc_txt and self.loc_txt.text and (self.loc_txt.text[3] == ' ' or self.loc_txt.text[3] == '#1#') then
            set_templates_for_tasks(self, tasks)
        end
        for i = 1, 5 do
            local task = tasks[i]
            local remain = task and math.max(0, (task.needed or 0) - (task.current or 0)) or 0
            vars[#vars+1] = remain
            if task and task.type == 'poker_hand' then
                local hand_name = task.target_hand or 'High Card'
                if hand_name and type(hand_name) == 'string' and localize then
                    local ok, loc = pcall(localize, hand_name, 'poker_hands')
                    hand_name = (ok and loc) or hand_name
                end
                vars[#vars+1] = tostring(hand_name)
            elseif task and task.type == 'discard_suit' then
                local suit_name = task.suit or 'Hearts'
                if localize and suit_name then
                    local ok, loc = pcall(localize, suit_name, 'suits_plural')
                    suit_name = (ok and loc) or suit_name
                end
                vars[#vars+1] = tostring(suit_name)
            else
                vars[#vars+1] = ''
            end
        end
        return { vars = vars }
    end,
    
    calculate = function(self, card, context)
        if card.debuff then return nil end
        card.ability.name = 'To Do List+'
        
        if card.ability.to_do_poker_hand then
            card.ability.to_do_poker_hand = nil
        end
        
        if not card.ability.extra then
            card.ability.extra = {
                dollars = 20
            }
        end
        
        if not card.ability.todo_tasks then
            card.ability.todo_tasks = generate_tasks(card)
            card.ability.todo_ante = (G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante) or 1
            card.ability.todo_reward_claimed = false
            set_templates_for_tasks(self, card.ability.todo_tasks)
        end
        
        local tasks = card.ability.todo_tasks
        if not tasks then return end

        local current_ante_val = (G and G.GAME and G.GAME.round_resets and tonumber(G.GAME.round_resets.ante or 0)) or 0
        if tonumber(card.ability.todo_ante or -1) ~= current_ante_val then
            reset_tasks_for_ante(self, card, current_ante_val)
            tasks = card.ability.todo_tasks
            return nil
        end
        
        if context and context.end_of_round and not context.game_over and G and G.GAME and G.GAME.blind and G.GAME.blind.get_type and G.GAME.blind:get_type() == 'Boss' then
            local current_ante = (G and G.GAME and G.GAME.round_resets and tonumber(G.GAME.round_resets.ante or 0)) or 0
            if card.ability._todo_boss_reset_ante ~= current_ante then
                reset_tasks_for_ante(self, card, current_ante)
                tasks = card.ability.todo_tasks
                if card_eval_status_text and not card.debuff then
                    card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Reset", colour = G.C.CHIPS })
                end
            end
            return nil
        end
        
        local updated = false
        
        if context.joker_main and G and G.GAME and G.GAME.current_round then
            for _, task in ipairs(tasks) do
                if task.type == 'hands' and not task.completed then
                    task.current = (task.current or 0) + 1
                    updated = true
                    
                    if task.current >= task.needed then
                        task.completed = true
                        if card_eval_status_text and not card.debuff then
                            card_eval_status_text(card, 'extra', nil, nil, nil, {
                                message = "Completed!",
                                colour = G.C.GREEN
                            })
                        end
                    end
                    break
                end
            end
        end
        
        if context.pre_discard then
            for _, task in ipairs(tasks) do
                if task.type == 'discards' and not task.completed then
                    task.current = (task.current or 0) + 1
                    updated = true
                    
                    if task.current >= task.needed then
                        task.completed = true
                        if card_eval_status_text and not card.debuff then
                            card_eval_status_text(card, 'extra', nil, nil, nil, {
                                message = "Completed!",
                                colour = G.C.GREEN
                            })
                        end
                    end
                    break
                end
            end
        end

        if context.discard and context.other_card then
            for _, task in ipairs(tasks) do
                if not task.completed then
                    if task.type == 'discard_face' and context.other_card.is_face and context.other_card:is_face(true) then
                        task.current = (task.current or 0) + 1
                        updated = true
                        if task.current >= task.needed then
                            task.completed = true
                            if card_eval_status_text and not card.debuff then
                                card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Completed!", colour = G.C.GREEN })
                            end
                        end
                    elseif task.type == 'discard_number' then
                        local id = context.other_card.get_id and context.other_card:get_id() or 0
                        local is_face = context.other_card.is_face and context.other_card:is_face(true)
                        if not is_face and id >= 2 and id <= 10 then
                            task.current = (task.current or 0) + 1
                            updated = true
                            if task.current >= task.needed then
                                task.completed = true
                                if card_eval_status_text and not card.debuff then
                                    card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Completed!", colour = G.C.GREEN })
                                end
                            end
                        end
                    elseif task.type == 'discard_suit' and task.suit and context.other_card.is_suit and context.other_card:is_suit(task.suit) then
                        task.current = (task.current or 0) + 1
                        updated = true
                        if task.current >= task.needed then
                            task.completed = true
                            if card_eval_status_text and not card.debuff then
                                card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Completed!", colour = G.C.GREEN })
                            end
                        end
                    end
                end
            end
        end

        if context.joker_main and G and G.GAME and G.GAME.last_hand_played then
            for _, task in ipairs(tasks) do
                if task.type == 'poker_hand' and not task.completed then
                    if G.GAME.last_hand_played == task.target_hand then
                        task.current = (task.current or 0) + 1
                        updated = true
                        if task.current >= task.needed then
                            task.completed = true
                            if card_eval_status_text and not card.debuff then
                                card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Completed!", colour = G.C.GREEN })
                            end
                        end
                    end
                    break
                end
            end
        end
        
        if context.joker_main and context.scoring_hand then
            local enhanced_in_hand = 0
            for i = 1, #context.scoring_hand do
                if is_enhanced_card(context.scoring_hand[i]) then
                    enhanced_in_hand = enhanced_in_hand + 1
                end
            end
            if enhanced_in_hand > 0 then
                for _, task in ipairs(tasks) do
                    if task.type == 'play_enhanced' and not task.completed then
                        task.current = (task.current or 0) + enhanced_in_hand
                        updated = true
                        if task.current >= task.needed then
                            task.completed = true
                            if card_eval_status_text and not card.debuff then
                                card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Completed!", colour = G.C.GREEN })
                            end
                        end
                        break
                    end
                end
            end
        end

        if context.other_joker and context.other_joker ~= card then
            for _, task in ipairs(tasks) do
                if task.type == 'jokers' and not task.completed then
                    task.current = (task.current or 0) + 1
                    updated = true
                    
                    if task.current >= task.needed then
                        task.completed = true
                        if card_eval_status_text and not card.debuff then
                            card_eval_status_text(card, 'extra', nil, nil, nil, {
                                message = "Completed!",
                                colour = G.C.GREEN
                            })
                        end
                    end
                    break
                end
            end
        end
        
        if context.using_consumeable then
            for _, task in ipairs(tasks) do
                if task.type == 'consumables' and not task.completed then
                    task.current = (task.current or 0) + 1
                    updated = true
                    
                    if task.current >= task.needed then
                        task.completed = true
                        if card_eval_status_text and not card.debuff then
                            card_eval_status_text(card, 'extra', nil, nil, nil, {
                                message = "Completed!",
                                colour = G.C.GREEN
                            })
                        end
                    end
                    break
                end
            end
        end
        
        if context.skip_blind then
            for _, task in ipairs(tasks) do
                if task.type == 'skip_blind' and not task.completed then
                    task.current = (task.current or 0) + 1
                    updated = true
                    if task.current >= task.needed then
                        task.completed = true
                        if card_eval_status_text and not card.debuff then
                            card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Completed!", colour = G.C.GREEN })
                        end
                    end
                    break
                end
            end
        end
        
        if updated then
            set_templates_for_tasks(self, tasks)
        end

        if not card.ability.todo_reward_claimed and all_tasks_completed(tasks) then
            card.ability.todo_reward_claimed = true
            
            G.E_MANAGER:add_event(Event({
                func = function()
                    if not card.debuff then
                        ease_dollars(20)
                        card_eval_status_text(card, 'extra', nil, nil, nil, {
                            message = localize('$')..'20',
                            colour = G.C.MONEY,
                            delay = 0.45
                        })
                    end
                    return true
                end
            }))
            
            return nil
        end
        
        return nil
    end,
    
    set_ability = function(self, card, initial, delay_sprites)
        card.ability.name = 'To Do List+'
        
        card.ability.to_do_poker_hand = nil
        
        card.ability.extra = {
            dollars = 20
        }
        
        if initial then
            card.ability.todo_tasks = generate_tasks(card)
            card.ability.todo_ante = (G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante) or 1
            card.ability.todo_reward_claimed = false
            set_templates_for_tasks(self, card.ability.todo_tasks)
        end
    end,
    
    update = function(self, card, dt)
    end
})

if SMODS and SMODS.Hook then
    SMODS.Hook.add('post_game_init', function()
        if G.P_CENTERS.j_todo_list then
            G.P_CENTERS.j_todo_list.mod = nil
            G.P_CENTERS.j_todo_list.modded = false
            G.P_CENTERS.j_todo_list.discovered = true
        end
    end)
else
    if rawget(_G,'G') and G.P_CENTERS and G.P_CENTERS.j_todo_list then
        G.P_CENTERS.j_todo_list.mod = nil
        G.P_CENTERS.j_todo_list.modded = false  
        G.P_CENTERS.j_todo_list.discovered = true
    end
end