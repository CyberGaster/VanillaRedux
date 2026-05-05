if G and G.ARGS and G.ARGS.LOC_COLOURS then
    G.ARGS.LOC_COLOURS.black = G.ARGS.LOC_COLOURS.black or HEX('000000')
end


local function rand01(seed)
    local s = tostring(seed or 'todo')
    if rawget(_G, 'pseudoseed') then
        local ok, v = pcall(pseudoseed, s)
        if ok and type(v) == 'number' then
            v = v % 1; if v < 0 then v = v + 1 end
            return v
        end
    end
    local h = 0
    for i = 1, #s do h = (h * 31 + s:byte(i)) % 0x100000000 end
    h = (1664525 * h + 1013904223) % 0x100000000
    return h / 0x100000000
end

local function wrand(lo, hi, seed)
    if hi <= lo then return lo end
    local range = hi - lo + 1
    local center = (lo + hi) / 2
    local weights, total = {}, 0
    for i = 1, range do
        local d = math.abs((lo + i - 1) - center) / ((hi - lo) / 2 + 0.01)
        local w = math.exp(-2 * d * d)
        weights[i] = w; total = total + w
    end
    local r = rand01(seed) * total
    local cum = 0
    for i = 1, range do
        cum = cum + weights[i]
        if r <= cum then return lo + i - 1 end
    end
    return hi
end

local function shuffle(t, seed)
    for i = #t, 2, -1 do
        local j = math.floor(rand01(seed .. '_' .. i) * i) + 1
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function is_enhanced(c)
    if not c or not c.ability then return false end
    if c.ability.effect == 'Stone Card' then return true end
    local n = c.ability.name
    return n == 'Bonus Card' or n == 'Mult Card'
        or n == 'Glass Card' or n == 'Gold Card' or n == 'Steel Card'
        or n == 'Wild Card' or n == 'Lucky Card'
end

local function get_deck_cards()
    local cards = {}
    if not rawget(_G, 'G') then return cards end
    for _, area in ipairs({G.deck, G.hand, G.play, G.discard}) do
        if area and area.cards then
            for i = 1, #area.cards do cards[#cards + 1] = area.cards[i] end
        end
    end
    return cards
end

local function get_deck_stats()
    local stats = { suits = {}, face = 0, number = 0, enhanced = 0, total = 0 }
    for _, suit in ipairs({'Hearts','Diamonds','Clubs','Spades'}) do stats.suits[suit] = 0 end
    local cards = get_deck_cards()
    for _, c in ipairs(cards) do
        stats.total = stats.total + 1
        if c.is_suit then
            for suit, _ in pairs(stats.suits) do
                if c:is_suit(suit) then stats.suits[suit] = stats.suits[suit] + 1 end
            end
        end
        if c.is_face and c:is_face(true) then
            stats.face = stats.face + 1
        else
            local id = c.get_id and c:get_id() or 0
            if id >= 2 and id <= 10 then stats.number = stats.number + 1 end
        end
        if is_enhanced(c) then stats.enhanced = stats.enhanced + 1 end
    end
    return stats
end

local function get_game_ctx()
    local ctx = {
        ante = 1, stake = 1,
        hands = 4, discards = 3,
        rounds_left = 3,
        deck_back = 'default',
        has_faces = true,
    }
    if not rawget(_G, 'G') or not G.GAME then return ctx end

    local rr = G.GAME.round_resets or {}
    ctx.ante = tonumber(rr.ante) or 1
    ctx.stake = tonumber(G.GAME.stake) or 1
    ctx.hands = tonumber(rr.hands) or 4
    ctx.discards = tonumber(rr.discards) or 3

    local states = rr.blind_states or {}
    local r = 0
    for _, k in ipairs({'Small','Big','Boss'}) do
        local st = states[k] or 'Upcoming'
        if st == 'Current' or st == 'Upcoming' or st == 'Select' then r = r + 1 end
    end
    ctx.rounds_left = math.max(1, r)

    if G.GAME.selected_back and G.GAME.selected_back.name then
        ctx.deck_back = G.GAME.selected_back.name
    end
    if ctx.deck_back == 'Abandoned Deck' then ctx.has_faces = false end

    local choices = rr.blind_choices or {}
    ctx.boss_key = choices.Boss or nil
    ctx.boss_upcoming = (states.Boss == 'Upcoming' or states.Boss == 'Select')

    return ctx
end

local HAND_DIFFICULTY = {
    ['High Card'] = 1, ['Pair'] = 1,
    ['Two Pair'] = 2, ['Three of a Kind'] = 2,
    ['Straight'] = 3, ['Flush'] = 3, ['Full House'] = 3,
    ['Four of a Kind'] = 4, ['Straight Flush'] = 5,
    ['Royal Flush'] = 5, ['Flush House'] = 5,
    ['Five of a Kind'] = 5, ['Flush Five'] = 5,
}

local HAND_PARENTS = {
    ['Flush House']    = { 'Full House', 'Flush' },
    ['Royal Flush']    = { 'Straight Flush', 'Flush', 'Straight' },
    ['Straight Flush'] = { 'Flush', 'Straight' },
    ['Flush Five']     = { 'Flush', 'Five of a Kind' },
    ['Five of a Kind'] = { 'Four of a Kind', 'Three of a Kind' },
    ['Four of a Kind'] = { 'Three of a Kind' },
    ['Full House']     = { 'Three of a Kind', 'Pair', 'Two Pair' },
    ['Flush']          = {},
    ['Straight']       = {},
    ['Three of a Kind']= { 'Pair' },
    ['Two Pair']       = { 'Pair' },
    ['Pair']           = { 'High Card' },
}

local function hand_matches(played, target)
    if played == target then return true end
    local parents = HAND_PARENTS[played]
    if parents then
        for _, p in ipairs(parents) do
            if p == target then return true end
        end
    end
    return false
end

local function pick_poker_hand(seed)
    if not G or not G.GAME or not G.GAME.hands then return 'High Card' end
    local pool, total = {}, 0
    for name, data in pairs(G.GAME.hands) do
        if data and data.visible ~= false then
            local lvl = tonumber(data.level) or 1
            local played = tonumber(data.played) or 0
            local w = math.max(1, lvl) * (played + 1)
            pool[#pool + 1] = { name = name, w = w }
            total = total + w
        end
    end
    if #pool == 0 then return 'High Card' end
    local r = rand01(seed) * total
    local cum = 0
    for _, entry in ipairs(pool) do
        cum = cum + entry.w
        if r <= cum then return entry.name end
    end
    return pool[#pool].name
end

local function poker_hand_count(hand_name, total_hands, seed)
    local tier = HAND_DIFFICULTY[hand_name] or 3
    local played = 0
    if G and G.GAME and G.GAME.hands and G.GAME.hands[hand_name] then
        played = tonumber(G.GAME.hands[hand_name].played) or 0
    end
    local lo, hi
    if tier <= 1 then
        lo, hi = 3, math.min(6, total_hands)
    elseif tier == 2 then
        lo, hi = 2, math.min(4, total_hands)
    elseif tier == 3 then
        lo, hi = 1, math.min(3, total_hands)
    else
        lo, hi = 1, math.min(2, total_hands)
    end
    if played >= 10 then
        lo = lo + 1; hi = hi + 1
    elseif played >= 5 then
        hi = hi + 1
    end
    hi = math.min(hi, total_hands)
    lo = math.min(lo, hi)
    return wrand(lo, hi, seed)
end

local function generate_tasks(card)
    local ctx = get_game_ctx()
    local stats = get_deck_stats()
    local seed = 'todo_' .. (card and card.sort_id or 0) .. '_' .. ctx.ante .. '_' .. ctx.stake

    local diff = 1.0 + (ctx.stake - 1) * 0.07

    local total_hands = ctx.hands * ctx.rounds_left
    local total_discards = ctx.discards * ctx.rounds_left

    if ctx.boss_upcoming and ctx.boss_key then
        if ctx.boss_key == 'bl_needle' then
            total_hands = total_hands - (ctx.hands - 1)
        end
        if ctx.boss_key == 'bl_water' then
            total_discards = total_discards - ctx.discards
        end
    end
    total_hands = math.max(1, total_hands)
    total_discards = math.max(0, total_discards)

    local ante_scale = math.max(1, 0.8 + ctx.ante * 0.1)

    local candidates = {}
    local function push(t) candidates[#candidates + 1] = t end

    local h_lo = math.max(3, math.floor(total_hands * 0.5 * diff * ante_scale))
    local h_hi = math.max(h_lo + 1, math.floor(total_hands * 0.85 * diff))
    h_hi = math.min(h_hi, total_hands)
    push({ type = 'hands', needed = wrand(h_lo, h_hi, seed .. '_h') })

    if total_discards > 0 then
        local d_lo = math.max(2, math.floor(total_discards * 0.4 * diff * ante_scale))
        local d_hi = math.max(d_lo + 1, math.floor(total_discards * 0.75 * diff))
        d_hi = math.min(d_hi, total_discards)
        push({ type = 'discards', needed = wrand(d_lo, d_hi, seed .. '_d') })
    end

    local target_hand = pick_poker_hand(seed .. '_ph')
    local ph_needed = poker_hand_count(target_hand, total_hands, seed .. '_pn')
    if ctx.boss_upcoming and ctx.boss_key == 'bl_eye' then
        local non_boss_hands = ctx.hands * math.max(0, ctx.rounds_left - 1)
        ph_needed = math.min(ph_needed, non_boss_hands + 1)
    end
    push({ type = 'poker_hand', needed = ph_needed, target_hand = target_hand })

    if ctx.has_faces and stats.face > 0 and total_discards > 0 then
        local cap = math.min(stats.face, total_discards * 4)
        local f_lo = math.max(2, math.floor(cap * 0.3 * ante_scale))
        local f_hi = math.max(f_lo, math.floor(cap * 0.6 * diff))
        f_hi = math.min(f_hi, cap)
        push({ type = 'discard_face', needed = wrand(f_lo, f_hi, seed .. '_df') })
    end

    if stats.number > 0 and total_discards > 0 then
        local cap = math.min(stats.number, total_discards * 4)
        local n_lo = math.max(2, math.floor(cap * 0.3 * ante_scale))
        local n_hi = math.max(n_lo, math.floor(cap * 0.6 * diff))
        n_hi = math.min(n_hi, cap)
        push({ type = 'discard_number', needed = wrand(n_lo, n_hi, seed .. '_dn') })
    end

    local best_suit, best_cnt = nil, 0
    for suit, cnt in pairs(stats.suits) do
        if cnt > best_cnt then best_suit, best_cnt = suit, cnt end
    end
    if best_suit and best_cnt > 0 and total_discards > 0 then
        local cap = math.min(best_cnt, total_discards * 4)
        local s_lo = math.max(2, math.floor(cap * 0.25 * ante_scale))
        local s_hi = math.max(s_lo, math.floor(cap * 0.5 * diff))
        s_hi = math.min(s_hi, cap)
        push({ type = 'discard_suit', suit = best_suit, needed = wrand(s_lo, s_hi, seed .. '_ds') })
    end

    if stats.enhanced > 0 then
        local e_lo = 1
        local e_hi = math.max(1, math.min(stats.enhanced, math.floor(total_hands * 0.4)))
        push({ type = 'play_enhanced', needed = wrand(e_lo, e_hi, seed .. '_en') })
    end

    local other_jokers = 0
    if G.jokers and G.jokers.cards then
        for _, j in ipairs(G.jokers.cards) do
            if j ~= card then other_jokers = other_jokers + 1 end
        end
    end
    if other_jokers > 0 then
        local j_lo = math.max(2, math.floor(other_jokers * total_hands * 0.3))
        local j_hi = math.max(j_lo, math.floor(other_jokers * total_hands * 0.7))
        push({ type = 'jokers', needed = wrand(j_lo, j_hi, seed .. '_jk') })
    end

    local slots = (G.consumeables and G.consumeables.config and tonumber(G.consumeables.config.card_limit)) or 0
    if slots > 0 then
        local c_lo = math.max(2, math.floor(slots * 0.5))
        local c_hi = math.max(c_lo, math.floor(slots * ctx.rounds_left * 0.7))
        push({ type = 'consumables', needed = wrand(c_lo, c_hi, seed .. '_cs') })
    end

    local can_skip = false
    if ctx.rounds_left > 1 and G.GAME and G.GAME.round_resets then
        local bs = G.GAME.round_resets.blind_states or {}
        local boss = bs.Boss or 'Upcoming'
        if boss ~= 'Current' then
            can_skip = (bs.Small == 'Select' or bs.Small == 'Current' or bs.Small == 'Upcoming')
                    or (bs.Big == 'Select' or bs.Big == 'Current' or bs.Big == 'Upcoming')
        end
    end
    if can_skip and rand01(seed .. '_skip') < 0.1 then
        push({ type = 'skip_blind', needed = 1 })
    end

    local has_skip = false
    for _, c in ipairs(candidates) do
        if c.type == 'skip_blind' then has_skip = true; break end
    end
    if has_skip and ctx.rounds_left > 1 then
        local reduced_hands = ctx.hands * (ctx.rounds_left - 1)
        local reduced_discards = ctx.discards * (ctx.rounds_left - 1)
        for _, c in ipairs(candidates) do
            if c.type == 'hands' then
                local rh_lo = math.max(3, math.floor(reduced_hands * 0.5 * diff * ante_scale))
                local rh_hi = math.max(rh_lo + 1, math.floor(reduced_hands * 0.85 * diff))
                c.needed = math.min(c.needed, wrand(rh_lo, math.min(rh_hi, reduced_hands), seed .. '_h_adj'))
            elseif c.type == 'discards' then
                local rd_lo = math.max(2, math.floor(reduced_discards * 0.4 * diff * ante_scale))
                local rd_hi = math.max(rd_lo + 1, math.floor(reduced_discards * 0.75 * diff))
                c.needed = math.min(c.needed, wrand(rd_lo, math.min(rd_hi, reduced_discards), seed .. '_d_adj'))
            elseif c.type == 'poker_hand' then
                c.needed = math.min(c.needed, math.max(1, math.floor(reduced_hands * 0.35)))
            end
        end
    end

    shuffle(candidates, seed .. '_shuf')
    local tasks = {}
    local core = { hands = true, discards = true, poker_hand = true }
    local used = {}

    for _, c in ipairs(candidates) do
        if core[c.type] and not used[c.type] and #tasks < 5 then
            tasks[#tasks + 1] = c; used[c.type] = true
        end
    end
    for _, c in ipairs(candidates) do
        if #tasks >= 5 then break end
        if not used[c.type] or c.type == 'discard_suit' then
            local dup = false
            for _, t in ipairs(tasks) do
                if t == c then dup = true; break end
            end
            if not dup then
                tasks[#tasks + 1] = c; used[c.type] = true
            end
        end
    end
    while #tasks > 5 do table.remove(tasks) end
    while #tasks < 5 do
        tasks[#tasks + 1] = { type = 'hands', needed = math.max(2, math.floor(total_hands * 0.5)) }
    end

    for _, t in ipairs(tasks) do
        t.current = 0; t.completed = false
    end
    return tasks
end

local function format_task(task)
    if not task then return ' ' end
    local rem = math.max(0, task.needed - (task.current or 0))
    if task.completed then rem = 0 end
    local T = task.type
    local line

    if T == 'hands' then
        line = ('Play {C:blue}%d{} %s'):format(rem, rem == 1 and 'hand' or 'hands')
    elseif T == 'discards' then
        line = ('Make {C:red}%d{} %s'):format(rem, rem == 1 and 'discard' or 'discards')
    elseif T == 'poker_hand' then
        local name = task.target_hand or 'High Card'
        if localize then
            local ok, loc = pcall(localize, name, 'poker_hands')
            if ok and loc then name = loc end
        end
        line = ('Play {C:attention}%d{} {C:attention}%s{}'):format(rem, name)
    elseif T == 'discard_face' then
        line = ('Discard {C:attention}%d{} face %s'):format(rem, rem == 1 and 'card' or 'cards')
    elseif T == 'discard_number' then
        line = ('Discard {C:attention}%d{} number %s'):format(rem, rem == 1 and 'card' or 'cards')
    elseif T == 'discard_suit' then
        local suit = task.suit or 'Hearts'
        local color = suit:lower()
        if localize then
            local ok, loc = pcall(localize, suit, rem == 1 and 'suits_singular' or 'suits_plural')
            if ok and loc then suit = loc end
        end
        line = ('Discard {C:attention}%d{} {C:%s}%s{}'):format(rem, color, suit)
    elseif T == 'play_enhanced' then
        line = ('Play {C:dark_edition}%d{} enhanced %s'):format(rem, rem == 1 and 'card' or 'cards')
    elseif T == 'jokers' then
        line = ('Trigger Jokers {C:attention}%d{} %s'):format(rem, rem == 1 and 'time' or 'times')
    elseif T == 'consumables' then
        line = ('Use {C:purple}%d{} %s'):format(rem, rem == 1 and 'consumable' or 'consumables')
    elseif T == 'skip_blind' then
        line = ('Skip {C:attention}%d{} Blind'):format(rem)
    end

    if not line then return ' ' end
    if task.completed then
        local plain = line:gsub('{[^}]*}', '')
        return '{C:black,st:black}' .. plain
    end
    return line
end

local function sync_loc(self, tasks)
    if not self or not self.loc_txt then return end
    for i = 1, 5 do
        self.loc_txt.text[2 + i] = format_task(tasks and tasks[i])
    end
    if G and G.localization and G.localization.descriptions
       and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_todo_list then
        local entry = G.localization.descriptions.Joker.j_todo_list
        entry.text = entry.text or {}
        for i = 1, 5 do
            entry.text[2 + i] = self.loc_txt.text[2 + i]
            if loc_parse_string then
                entry.text_parsed = entry.text_parsed or {}
                entry.text_parsed[2 + i] = loc_parse_string(entry.text[2 + i])
            end
        end
    end
end

SMODS.Joker:take_ownership('todo_list', {
    loc_txt = {
        name = 'To Do List',
        text = {
            'Earn {C:money}$#1#{} by completing all tasks',
            'before defeating {C:attention}Boss Blind{}:',
            ' ', ' ', ' ', ' ', ' ',
            'Tasks reset each {C:attention}Ante{}'
        }
    },
    config = { extra = { to_do_poker_hand = 'High Card', dollars = 4 } },
    loc_vars = function(self, info_queue, card)
        local tasks = card and card.ability and card.ability.todo_tasks
        if tasks then sync_loc(self, tasks) end
        return { vars = { card.ability.todo_reward or 20 } }
    end,

    set_ability = function(self, card, initial, delay_sprites)
        card.ability.todo_reward = card.ability.todo_reward or 20
        if initial then
            card.ability.todo_tasks = generate_tasks(card)
            card.ability.todo_ante = (G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante) or 1
            card.ability.todo_reward_claimed = false
            sync_loc(self, card.ability.todo_tasks)
        end
    end,

    calculate = function(self, card, context)
        if card.debuff then return nil end

        if not card.ability.todo_tasks then
            card.ability.todo_tasks = generate_tasks(card)
            card.ability.todo_ante = (G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante) or 1
            card.ability.todo_reward_claimed = false
            sync_loc(self, card.ability.todo_tasks)
        end

        local tasks = card.ability.todo_tasks

        local cur_ante = (G and G.GAME and G.GAME.round_resets and tonumber(G.GAME.round_resets.ante)) or 1
        if tonumber(card.ability.todo_ante or 0) ~= cur_ante then
            card.ability.todo_tasks = generate_tasks(card)
            card.ability.todo_ante = cur_ante
            card.ability.todo_reward_claimed = false
            tasks = card.ability.todo_tasks
            sync_loc(self, tasks)
            return nil
        end

        local updated = false

        local function complete(task)
            task.completed = true
            if card_eval_status_text then
                card_eval_status_text(card, 'extra', nil, nil, nil, { message = 'Completed!', colour = G.C.GREEN })
            end
        end

        local function advance(task, amount)
            task.current = (task.current or 0) + (amount or 1)
            if task.current >= task.needed and not task.completed then
                complete(task)
            end
            updated = true
        end

        if context.joker_main then
            for _, t in ipairs(tasks) do
                if t.type == 'hands' and not t.completed then advance(t); break end
            end
        end

        if context.joker_main and G.GAME and G.GAME.last_hand_played then
            for _, t in ipairs(tasks) do
                if t.type == 'poker_hand' and not t.completed then
                    if hand_matches(G.GAME.last_hand_played, t.target_hand) then advance(t) end
                    break
                end
            end
        end

        if context.joker_main and context.scoring_hand then
            local n = 0
            for _, c in ipairs(context.scoring_hand) do
                if is_enhanced(c) then n = n + 1 end
            end
            if n > 0 then
                for _, t in ipairs(tasks) do
                    if t.type == 'play_enhanced' and not t.completed then advance(t, n); break end
                end
            end
        end

        if context.pre_discard then
            for _, t in ipairs(tasks) do
                if t.type == 'discards' and not t.completed then advance(t); break end
            end
        end

        if context.discard and context.other_card then
            local oc = context.other_card
            for _, t in ipairs(tasks) do
                if not t.completed then
                    if t.type == 'discard_face' and oc.is_face and oc:is_face(true) then
                        advance(t); break
                    elseif t.type == 'discard_number' then
                        local id = oc.get_id and oc:get_id() or 0
                        if not (oc.is_face and oc:is_face(true)) and id >= 2 and id <= 10 then
                            advance(t); break
                        end
                    elseif t.type == 'discard_suit' and t.suit and oc.is_suit and oc:is_suit(t.suit) then
                        advance(t); break
                    end
                end
            end
        end

        if context.other_joker and context.other_joker ~= card then
            for _, t in ipairs(tasks) do
                if t.type == 'jokers' and not t.completed then advance(t); break end
            end
        end

        if context.using_consumeable then
            for _, t in ipairs(tasks) do
                if t.type == 'consumables' and not t.completed then advance(t); break end
            end
        end

        if context.skip_blind then
            for _, t in ipairs(tasks) do
                if t.type == 'skip_blind' and not t.completed then advance(t); break end
            end
        end

        if updated then sync_loc(self, tasks) end

        if not card.ability.todo_reward_claimed then
            local all_done = true
            for _, t in ipairs(tasks) do
                if not t.completed then all_done = false; break end
            end
            if all_done then
                card.ability.todo_reward_claimed = true
                local reward = card.ability.todo_reward or 20
                G.E_MANAGER:add_event(Event({ func = function()
                    if not card.debuff then
                        ease_dollars(reward)
                        card_eval_status_text(card, 'extra', nil, nil, nil, {
                            message = localize('$') .. reward,
                            colour = G.C.MONEY, delay = 0.45
                        })
                    end
                    return true
                end }))
            end
        end

        if context.repetition then return nil end
        return {}
    end,

    blueprint_compat = false,
})
