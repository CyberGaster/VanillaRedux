if G and G.ARGS and G.ARGS.LOC_COLOURS then
    G.ARGS.LOC_COLOURS.black = G.ARGS.LOC_COLOURS.black or HEX('000000')
end


local function rand01(seed)
    local key = tostring(seed or 'todo')
    if rawget(_G, 'pseudorandom') and rawget(_G, 'G') and G.GAME and G.GAME.pseudorandom then
        local ok, v = pcall(pseudorandom, key)
        if ok and type(v) == 'number' then return v end
    end
    local h = 0
    for i = 1, #key do h = (h * 31 + key:byte(i)) % 0x100000000 end
    h = (1664525 * h + 1013904223) % 0x100000000
    return h / 0x100000000
end

-- Task difficulty. Every task has an easy end and a hard end, and its "tension" (0 = easy end,
-- 1 = hard end) says where in between it lands.
--   start, finish  Tension at Ante 1 and from `ramp_ante` on. It rises with the Ante and then levels
--                  off, so late Antes stop getting harder.
--   per_stake      Extra tension for every Stake above the first, up to `max`.
--   stake_edge     Every Stake above the first also moves both ends of the hands, discards and card
--                  tasks up by this share of what is available. The ranges are narrow, so tension
--                  alone barely changes the numbers; this is what makes a higher Stake felt.
--   spread         The five tasks share one tension budget (the average). The easiest task of a list
--                  sits `spread` below the average and the hardest `spread` above it, so a hard task
--                  is paid for by an easy one.
--   jitter         Small random nudge per task, so lists with the same tasks still differ.
--   pace_loss      Stronger runs win in fewer hands, so the hands and discards the tasks are sized
--                  from shrink by this much each Ante, down to `pace_floor`.
--   fixed          Tension of tasks that have no range (Skip Blind). It is taken from the budget as is.
local TUNING = {
    start = 0.5, finish = 0.62, ramp_ante = 8,
    per_stake = 0.02, max = 0.85, stake_edge = 0.01,
    spread = 0.24, jitter = 0.05,
    pace_loss = 0.008, pace_floor = 0.9,
    fixed = { skip_blind = 0.85 },
}

local function base_tension(ante, stake)
    local progress = math.min(1, math.max(0, (ante - 1) / math.max(1, TUNING.ramp_ante - 1)))
    local tension = TUNING.start + (TUNING.finish - TUNING.start) * progress + (stake - 1) * TUNING.per_stake
    return math.min(TUNING.max, tension)
end

local function pace_factor(ante)
    return math.max(TUNING.pace_floor, 1 - TUNING.pace_loss * (ante - 1))
end

local function stake_edge(stake)
    return TUNING.stake_edge * (stake - 1)
end

local function with_edge(fraction, edge)
    return math.min(1, fraction + edge)
end

local function shuffle(t, seed)
    for i = #t, 2, -1 do
        local j = math.floor(rand01(seed .. '_' .. i) * i) + 1
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function is_enhanced(c)
    return c and c.ability and c.ability.set == 'Enhanced' or false
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
        in_round = false, hands_left = 4, discards_left = 3,
        deck_back = 'default',
        has_faces = true,
    }
    if not rawget(_G, 'G') or not G.GAME then return ctx end

    local rr = G.GAME.round_resets or {}
    ctx.ante = VanillaRedux.to_number(rr.ante, 1)
    ctx.stake = tonumber(G.GAME.stake) or 1
    ctx.hands = tonumber(rr.hands) or 4
    ctx.discards = tonumber(rr.discards) or 3

    local states = rr.blind_states or {}
    local r = 0
    for _, k in ipairs({'Small','Big','Boss'}) do
        local st = states[k] or 'Upcoming'
        if st == 'Current' or st == 'Upcoming' or st == 'Select' then r = r + 1 end
        if st == 'Current' then ctx.in_round = true end
    end
    ctx.rounds_left = math.max(1, r)

    local cr = G.GAME.current_round
    if ctx.in_round and cr then
        ctx.hands_left = tonumber(cr.hands_left) or ctx.hands
        ctx.discards_left = tonumber(cr.discards_left) or ctx.discards
    end

    if G.GAME.selected_back and G.GAME.selected_back.name then
        ctx.deck_back = G.GAME.selected_back.name
    end
    if ctx.deck_back == 'Abandoned Deck' then ctx.has_faces = false end

    local choices = rr.blind_choices or {}
    ctx.boss_key = choices.Boss or nil
    ctx.boss_upcoming = (states.Boss == 'Upcoming' or states.Boss == 'Select')

    return ctx
end

-- The next Ante's blinds and its boss are only rolled when the player cashes out of the boss round.
-- Until then the blinds still describe the Ante that just ended, so new tasks have to wait for them.
local function blinds_follow_ante(ante)
    local rr = G and G.GAME and G.GAME.round_resets
    if not rr then return true end
    return VanillaRedux.to_number(rr.blind_ante, ante) >= ante
end

local HAND_DIFFICULTY = {
    ['High Card'] = 1, ['Pair'] = 1,
    ['Two Pair'] = 2, ['Three of a Kind'] = 2,
    ['Straight'] = 3, ['Flush'] = 3, ['Full House'] = 3,
    ['Four of a Kind'] = 4, ['Straight Flush'] = 5,
    ['Royal Flush'] = 5, ['Flush House'] = 5,
    ['Five of a Kind'] = 5, ['Flush Five'] = 5,
}

local function pick_poker_hand(seed)
    if not G or not G.GAME or not G.GAME.hands then return 'High Card' end
    local pool, total = {}, 0
    local hand_names = {}
    for hand_name in pairs(G.GAME.hands) do hand_names[#hand_names + 1] = hand_name end
    table.sort(hand_names)
    for _, name in ipairs(hand_names) do
        local data = G.GAME.hands[name]
        if data and data.visible ~= false then
            local lvl = VanillaRedux.to_number(data.level, 1)
            local played = VanillaRedux.to_number(data.played, 0)
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

local function poker_hand_range(hand_name, total_hands)
    local tier = HAND_DIFFICULTY[hand_name] or 3
    local played = 0
    if G and G.GAME and G.GAME.hands and G.GAME.hands[hand_name] then
        played = VanillaRedux.to_number(G.GAME.hands[hand_name].played, 0)
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
    return lo, hi
end

local function clamp_range(lo, hi, cap)
    cap = math.floor(cap)
    hi = math.min(hi, cap)
    lo = math.min(lo, hi)
    return lo, hi
end

-- Turns the easy..hard range of every task into a number. The tasks share one tension budget
-- (tension x number of tasks): tasks without a range spend their share first and the rest is spread
-- around the average, so a list never ends up with only hard or only easy tasks.
local function assign_needed(tasks, tension, seed)
    local budget, flexible = tension * #tasks, {}
    for _, t in ipairs(tasks) do
        if t.lo and t.hi and t.hi > t.lo then
            flexible[#flexible + 1] = t
        else
            if t.lo then t.needed = t.lo end
            budget = budget - (TUNING.fixed[t.type] or tension)
        end
    end

    local count = #flexible
    if count > 0 then
        local spread = TUNING.spread
        local half = spread / 2
        local average = math.max(half, math.min(1 - half, budget / count))
        local offsets = {}
        for i = 1, count do
            offsets[i] = count == 1 and 0 or (-spread + 2 * spread * (i - 1) / (count - 1))
        end
        shuffle(offsets, seed .. '_tension')
        for i, t in ipairs(flexible) do
            local jitter = (rand01(seed .. '_jitter_' .. i) - 0.5) * 2 * TUNING.jitter
            local position = math.max(0, math.min(1, average + offsets[i] + jitter))
            t.needed = t.lo + math.floor((t.hi - t.lo) * position + 0.5)
        end
    end

    for _, t in ipairs(tasks) do t.lo, t.hi = nil, nil end
end

local function cards_per_discard()
    local params = rawget(_G, 'G') and G.GAME and G.GAME.starting_params
    local limit = tonumber(params and params.discard_limit) or 5
    return math.max(1, math.min(4, math.floor(limit)))
end

local function can_skip_blind(ctx)
    if ctx.rounds_left <= 1 or not (G and G.GAME and G.GAME.round_resets) then return false end
    local states = G.GAME.round_resets.blind_states or {}
    if states.Boss == 'Current' then return false end
    for _, k in ipairs({ 'Small', 'Big' }) do
        local st = states[k] or 'Upcoming'
        if st == 'Select' or st == 'Upcoming' then return true end
    end
    return false
end

local function generate_tasks(card)
    local ctx = get_game_ctx()
    local stats = get_deck_stats()
    local seed = 'todo_' .. ctx.ante .. '_' .. ctx.stake

    local tension = base_tension(ctx.ante, ctx.stake)
    local pace = pace_factor(ctx.ante)

    local upcoming_rounds = ctx.rounds_left - (ctx.in_round and 1 or 0)
    local total_hands = upcoming_rounds * ctx.hands + (ctx.in_round and ctx.hands_left or 0)
    local total_discards = upcoming_rounds * ctx.discards + (ctx.in_round and ctx.discards_left or 0)
    local hands_before_boss = total_hands - (ctx.boss_upcoming and ctx.hands or 0)

    if ctx.boss_upcoming and ctx.boss_key then
        if ctx.boss_key == 'bl_needle' then
            total_hands = total_hands - (ctx.hands - 1)
        end
        if ctx.boss_key == 'bl_water' then
            total_discards = total_discards - ctx.discards
        end
    end

    local skip_blind = can_skip_blind(ctx) and rand01(seed .. '_skip') < 0.1
    if skip_blind then
        total_hands = total_hands - ctx.hands
        total_discards = total_discards - ctx.discards
        hands_before_boss = hands_before_boss - ctx.hands
    end

    total_hands = math.max(1, total_hands)
    total_discards = math.max(0, total_discards)
    hands_before_boss = math.max(0, hands_before_boss)
    local sized_hands = math.max(1, math.floor(total_hands * pace + 0.5))
    local sized_discards = math.floor(total_discards * pace + 0.5)
    local discard_cap = sized_discards * cards_per_discard()

    local candidates = {}
    local function push(t) candidates[#candidates + 1] = t end

    local edge = stake_edge(ctx.stake)

    local h_lo = math.max(3, math.floor(sized_hands * with_edge(0.4, edge)))
    local h_hi = math.max(h_lo + 1, math.floor(sized_hands * with_edge(0.75, edge)))
    h_lo, h_hi = clamp_range(h_lo, h_hi, sized_hands)
    push({ type = 'hands', lo = h_lo, hi = h_hi })

    if total_discards > 0 then
        local d_lo = math.max(2, math.floor(sized_discards * with_edge(0.25, edge)))
        local d_hi = math.max(d_lo + 1, math.floor(sized_discards * with_edge(0.55, edge)))
        d_lo, d_hi = clamp_range(d_lo, d_hi, sized_discards)
        push({ type = 'discards', lo = d_lo, hi = d_hi })
    end

    local target_hand = pick_poker_hand(seed .. '_ph')
    local ph_lo, ph_hi = poker_hand_range(target_hand, sized_hands)
    local ph_cap = sized_hands
    if ctx.boss_upcoming and ctx.boss_key == 'bl_eye' then
        ph_cap = math.min(ph_cap, hands_before_boss + 1)
    end
    if skip_blind then
        ph_cap = math.min(ph_cap, math.max(1, math.floor(total_hands * 0.35)))
    end
    ph_lo, ph_hi = clamp_range(ph_lo, ph_hi, ph_cap)
    push({ type = 'poker_hand', lo = ph_lo, hi = ph_hi, target_hand = target_hand })

    if ctx.has_faces and stats.face > 0 and total_discards > 0 then
        local cap = math.min(stats.face, discard_cap)
        local f_lo = math.max(2, math.floor(cap * with_edge(0.3, edge)))
        local f_hi = math.max(f_lo, math.floor(cap * with_edge(0.6, edge)))
        f_lo, f_hi = clamp_range(f_lo, f_hi, cap)
        push({ type = 'discard_face', lo = f_lo, hi = f_hi })
    end

    if stats.number > 0 and total_discards > 0 then
        local cap = math.min(stats.number, discard_cap)
        local n_lo = math.max(2, math.floor(cap * with_edge(0.25, edge)))
        local n_hi = math.max(n_lo, math.floor(cap * with_edge(0.5, edge)))
        n_lo, n_hi = clamp_range(n_lo, n_hi, cap)
        push({ type = 'discard_number', lo = n_lo, hi = n_hi })
    end

    local best_suit, best_cnt = nil, 0
    for _, suit in ipairs({ 'Hearts', 'Diamonds', 'Clubs', 'Spades' }) do
        local cnt = stats.suits[suit] or 0
        if cnt > best_cnt then best_suit, best_cnt = suit, cnt end
    end
    if best_suit and best_cnt > 0 and total_discards > 0 then
        local cap = math.min(best_cnt, discard_cap)
        local s_lo = math.max(2, math.floor(cap * with_edge(0.25, edge)))
        local s_hi = math.max(s_lo, math.floor(cap * with_edge(0.5, edge)))
        s_lo, s_hi = clamp_range(s_lo, s_hi, cap)
        push({ type = 'discard_suit', suit = best_suit, lo = s_lo, hi = s_hi })
    end

    if stats.enhanced > 0 then
        local e_lo = 1
        local e_hi = math.max(1, math.min(stats.enhanced, math.floor(sized_hands * 0.4)))
        push({ type = 'play_enhanced', lo = e_lo, hi = e_hi })
    end

    local other_jokers = 0
    if G.jokers and G.jokers.cards then
        for _, j in ipairs(G.jokers.cards) do
            if j ~= card then other_jokers = other_jokers + 1 end
        end
    end
    if other_jokers > 0 then
        local j_lo = math.max(2, math.floor(other_jokers * sized_hands * with_edge(0.25, edge)))
        local j_hi = math.max(j_lo, math.floor(other_jokers * sized_hands * with_edge(0.6, edge)))
        j_lo, j_hi = clamp_range(j_lo, j_hi, other_jokers * sized_hands)
        push({ type = 'jokers', lo = j_lo, hi = j_hi })
    end

    local slots = (G.consumeables and G.consumeables.config and tonumber(G.consumeables.config.card_limit)) or 0
    if slots > 0 then
        local c_lo = math.max(2, math.floor(slots * 0.5))
        local c_hi = math.max(c_lo, math.floor(slots * ctx.rounds_left * 0.7))
        push({ type = 'consumables', lo = c_lo, hi = c_hi })
    end

    if skip_blind then
        push({ type = 'skip_blind', needed = 1 })
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
        tasks[#tasks + 1] = { type = 'hands', needed = math.min(sized_hands, math.max(2, math.floor(sized_hands * 0.5))) }
    end
    assign_needed(tasks, tension, seed)

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

local function run_is_live()
    return G and G.STAGES and G.STAGE == G.STAGES.RUN
        and G.GAME and G.GAME.round_resets and not G.OVERLAY_MENU
end

local function example_tasks()
    local tasks = {
        { type = 'hands', needed = 8 },
        { type = 'discards', needed = 4 },
        { type = 'poker_hand', needed = 2, target_hand = 'Flush' },
        { type = 'discard_face', needed = 6 },
        { type = 'consumables', needed = 2 },
    }
    for _, t in ipairs(tasks) do
        t.current = 0; t.completed = false
    end
    return tasks
end

local function advance_task(card, task, amount)
    task.current = (task.current or 0) + (amount or 1)
    if task.current >= task.needed and not task.completed then
        task.completed = true
        if card_eval_status_text then
            card_eval_status_text(card, 'extra', nil, nil, nil, { message = 'Completed!', colour = G.C.GREEN })
        end
    end
end

local TODO_REWARD = 25

local function claim_reward_if_done(card)
    if card.ability.todo_reward_claimed then return end
    for _, t in ipairs(card.ability.todo_tasks or {}) do
        if not t.completed then return end
    end
    card.ability.todo_reward_claimed = true
    local reward = TODO_REWARD
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
        local tasks = (card and card.ability and card.ability.todo_tasks) or example_tasks()
        sync_loc(self, tasks)
        return { vars = { TODO_REWARD } }
    end,

    set_ability = function(self, card, initial, delay_sprites)
        card.ability.todo_reward = TODO_REWARD
        if initial and run_is_live() then
            card.ability.todo_tasks = generate_tasks(card)
            card.ability.todo_ante = (G and G.GAME and G.GAME.round_resets and VanillaRedux.to_number(G.GAME.round_resets.ante, 1)) or 1
            card.ability.todo_reward_claimed = false
            sync_loc(self, card.ability.todo_tasks)
        end
    end,

    calculate = function(self, card, context)
        if card.debuff then return nil end

        if not card.ability.todo_tasks then
            card.ability.todo_tasks = generate_tasks(card)
            card.ability.todo_ante = (G and G.GAME and G.GAME.round_resets and VanillaRedux.to_number(G.GAME.round_resets.ante, 1)) or 1
            card.ability.todo_reward_claimed = false
            sync_loc(self, card.ability.todo_tasks)
        end

        local tasks = card.ability.todo_tasks

        local cur_ante = (G and G.GAME and G.GAME.round_resets and VanillaRedux.to_number(G.GAME.round_resets.ante, 1)) or 1
        if cur_ante > VanillaRedux.to_number(card.ability.todo_ante, 0) and blinds_follow_ante(cur_ante) then
            card.ability.todo_tasks = generate_tasks(card)
            card.ability.todo_ante = cur_ante
            card.ability.todo_reward_claimed = false
            tasks = card.ability.todo_tasks
            sync_loc(self, tasks)
            return nil
        end

        local updated = false

        local function advance(task, amount)
            advance_task(card, task, amount)
            updated = true
        end

        if context.joker_main then
            for _, t in ipairs(tasks) do
                if t.type == 'hands' and not t.completed then advance(t) end
            end
        end

        local played_hand = context.scoring_name or (G.GAME and G.GAME.last_hand_played)
        if context.joker_main and played_hand then
            for _, t in ipairs(tasks) do
                if t.type == 'poker_hand' and not t.completed and t.target_hand == played_hand then
                    advance(t)
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
                    if t.type == 'play_enhanced' and not t.completed then advance(t, n) end
                end
            end
        end

        -- The Hook's random discard is not the player's discard: only its cards count, for the card tasks below.
        if context.pre_discard and not context.hook then
            for _, t in ipairs(tasks) do
                if t.type == 'discards' and not t.completed then advance(t) end
            end
        end

        if context.discard and context.other_card then
            local oc = context.other_card
            local is_face = oc.is_face and oc:is_face(true)
            local id = oc.get_id and oc:get_id() or 0
            for _, t in ipairs(tasks) do
                if not t.completed then
                    if t.type == 'discard_face' then
                        if is_face then advance(t) end
                    elseif t.type == 'discard_number' then
                        if not is_face and id >= 2 and id <= 10 then advance(t) end
                    elseif t.type == 'discard_suit' then
                        if t.suit and oc.is_suit and oc:is_suit(t.suit) then advance(t) end
                    end
                end
            end
        end

        if context.using_consumeable then
            for _, t in ipairs(tasks) do
                if t.type == 'consumables' and not t.completed then advance(t) end
            end
        end

        if context.skip_blind then
            for _, t in ipairs(tasks) do
                if t.type == 'skip_blind' and not t.completed then advance(t) end
            end
        end

        if updated then sync_loc(self, tasks) end

        claim_reward_if_done(card)

        if context.repetition then return nil end
        return {}
    end,

    blueprint_compat = false,
})

local ADDITIVE_KEYS = { 'chips', 'h_chips', 'chip_mod', 'mult', 'h_mult', 'mult_mod', 'dollars', 'h_dollars', 'p_dollars' }
local MULTIPLIER_KEYS = { 'x_mult', 'Xmult', 'xmult', 'Xmult_mod', 'x_chips', 'xchips', 'Xchip_mod' }
local NOT_SCORING_CONTEXTS = { 'discard', 'pre_discard', 'retrigger_joker_check', 'post_trigger', 'mod_probability',
    'fix_probability', 'check_enhancement', 'modify_scoring_hand', 'evaluate_poker_hand', 'debuff_hand' }

local function is_hand_scoring(context)
    if not (context and context.full_hand) then return false end
    for _, key in ipairs(NOT_SCORING_CONTEXTS) do
        if context[key] then return false end
    end
    return (context.joker_main or context.individual or context.repetition or context.before
        or context.after or context.other_joker) and true or false
end

local function has_effect(res, depth)
    if type(res) ~= 'table' or (depth or 0) > 4 then return false end
    for _, key in ipairs(ADDITIVE_KEYS) do
        if res[key] ~= nil and res[key] ~= 0 then return true end
    end
    for _, key in ipairs(MULTIPLIER_KEYS) do
        if res[key] ~= nil and res[key] ~= 1 then return true end
    end
    if type(res.repetitions) == 'number' and res.repetitions > 0 then return true end
    if res.message or res.level_up then return true end
    return has_effect(res.extra, (depth or 0) + 1)
end

local function count_joker_trigger(joker)
    if joker.debuff or not (joker.ability and joker.ability.set == 'Joker') then return end
    if not (G.jokers and G.jokers.cards and joker.area == G.jokers) then return end
    if joker.config and joker.config.center and joker.config.center.key == 'j_todo_list' then return end

    local cur_ante = VanillaRedux.to_number(G.GAME.round_resets.ante, 1)
    for _, todo in ipairs(G.jokers.cards) do
        local tasks = todo.ability and todo.ability.todo_tasks
        if todo ~= joker and not todo.debuff and tasks and todo.config.center.key == 'j_todo_list'
           and VanillaRedux.to_number(todo.ability.todo_ante, 0) >= cur_ante then
            local updated = false
            for _, t in ipairs(tasks) do
                if t.type == 'jokers' and not t.completed then
                    advance_task(todo, t, 1)
                    updated = true
                end
            end
            if updated then
                sync_loc(todo.config.center, tasks)
                claim_reward_if_done(todo)
            end
        end
    end
end

if not rawget(_G, 'VR_TODO_TRIGGER_PATCHED') and rawget(_G, 'Card') and Card.calculate_joker then
    local old_calculate_joker = Card.calculate_joker
    function Card:calculate_joker(context)
        local outermost = context and not context.blueprint
        local res, triggered = old_calculate_joker(self, context)
        if outermost and is_hand_scoring(context) and has_effect(res) then
            count_joker_trigger(self)
        end
        return res, triggered
    end
    _G.VR_TODO_TRIGGER_PATCHED = true
end
