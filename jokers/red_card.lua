SMODS.Joker:take_ownership('red_card', {
    loc_txt = {
        name = 'Red Card',
        text = {
            'On the {C:attention}last discard{} of the round,',
            'draw {C:attention}1 card{} from your deck',
            'to form your best-scoring {C:attention}poker hand{}'
        }
    },
    blueprint_compat = false,
})

local SUITS, RANKS
local get_suit, get_rank, count_by_suit, count_by_rank
local _ensure_state, build_remaining_hand, compute_expected_draw_space, plan_for_best_hand
local _find_red_card, _start_shake_loop, _stop_shake_loop

_ensure_state = function()
    G.GAME._vp_redcard = G.GAME._vp_redcard or { pending_plan = {}, round = -1 }
    if G.GAME._vp_redcard.round ~= G.GAME.round then
        G.GAME._vp_redcard.pending_plan = {}
        G.GAME._vp_redcard.round = G.GAME.round
        G.GAME._vp_redcard.ready_wiggle_done = nil
        G.GAME._vp_redcard.shake_loop_running = nil
        G.GAME._vp_redcard.shake_loop_stop = nil
    end
    return G.GAME._vp_redcard
end

SUITS = {'Spades','Hearts','Diamonds','Clubs'}
RANKS = {2,3,4,5,6,7,8,9,10,11,12,13,14}

get_suit = function(card)
    return card and card.base and card.base.suit or nil
end
get_rank = function(card)
    if not card or not card.get_id then return nil end
    return card:get_id()
end

count_by_suit = function(cards)
    local t = {Spades=0,Hearts=0,Diamonds=0,Clubs=0}
    for i=1, #cards do
        local s = get_suit(cards[i])
        if s and t[s] ~= nil then t[s] = t[s] + 1 end
    end
    return t
end
count_by_rank = function(cards)
    local t = {}
    for _, r in ipairs(RANKS) do t[r] = 0 end
    for i=1, #cards do
        local r = get_rank(cards[i])
        if r then t[r] = (t[r] or 0) + 1 end
    end
    return t
end

_find_red_card = function()
    if not (G and G.jokers and G.jokers.cards) then return nil end
    for i=1, #G.jokers.cards do
        local j = G.jokers.cards[i]
        if j and j.ability and j.ability.name == 'Red Card' and not j.debuff then return j end
    end
    return nil
end

_stop_shake_loop = function()
    local st = _ensure_state()
    st.shake_loop_stop = true
    st.shake_loop_running = nil
    st.loyalty_shake_started = nil
end

_start_shake_loop = function(joker_ref)
    local st = _ensure_state()
    if st.loyalty_shake_started then return end
    st.loyalty_shake_started = true
    local j = joker_ref or _find_red_card()
    if not j then return end
    local eval = function(card)
        local cr = G.GAME and G.GAME.current_round
        return cr and ((cr.discards_left or 0) == 1)
    end
    juice_card_until(j, eval, true)
end

build_remaining_hand = function(full_hand_to_discard)
    local discard_set = {}
    for i=1, #full_hand_to_discard do
        discard_set[full_hand_to_discard[i]] = true
    end
    local remain = {}
    for i=1, #G.hand.cards do
        local c = G.hand.cards[i]
        if not discard_set[c] then table.insert(remain, c) end
    end
    return remain
end

compute_expected_draw_space = function(remain_count)
    local space = math.min(#G.deck.cards, math.max(0, G.hand.config.card_limit - remain_count))
    if G.GAME.blind and G.GAME.blind.name == 'The Serpent' and not G.GAME.blind.disabled then
        local hands_played = G.GAME.current_round.hands_played or 0
        local discards_used = (G.GAME.current_round.discards_used or 0) + 1
        if (hands_played > 0 or discards_used > 0) then
            space = math.min(#G.deck.cards, math.min(space, 3))
        end
    end
    return space
end

local function hand_score(name)
    local h = G.GAME.hands[name]
    if not h then return -1 end
    return (h.chips or 0) * (h.mult or 1)
end

plan_for_best_hand = function(remain, draw_n, exclude_top_n)
    if draw_n <= 0 then return nil, nil end
    local deck_cards = {}
    local limit = math.max(0, #G.deck.cards - (exclude_top_n or 0))
    for i=1, limit do deck_cards[i] = G.deck.cards[i] end

    local best_card, best_name, best_score, best_fb = nil, nil, nil, -1
    local names_priority = {
        'Flush Five','Five of a Kind','Straight Flush','Flush House',
        'Four of a Kind','Full House','Flush','Straight',
        'Three of a Kind','Two Pair','Pair','High Card'
    }

    local function get_rank_index(name)
        for idx, n in ipairs(names_priority) do
            if n == name then return (#names_priority - idx + 1) end
        end
        return 0
    end
    local function score_name(name)
        local h = G.GAME.hands[name]
        if not h then return nil, get_rank_index(name) end
        local chips, mult = h.chips, h.mult
        local cnum = (type(chips) == 'number') and chips or tonumber(chips)
        local mnum = (type(mult) == 'number') and mult or tonumber(mult)
        if cnum and mnum then return (cnum * mnum), get_rank_index(name) end
        return nil, get_rank_index(name)
    end

    local function choose_better(card, name)
        if not name then return end
        local sc_num, sc_fb = score_name(name)
        local better = false
        if type(sc_num) == 'number' and type(best_score) == 'number' then
            better = sc_num > best_score
        elseif type(sc_num) == 'number' and best_score == nil then
            better = true
        elseif type(sc_num) ~= 'number' and type(best_score) == 'number' then
            better = false
        else
            better = (sc_fb or 0) > (best_fb or -1)
        end
        if better then
            best_score = sc_num
            best_fb = sc_fb or best_fb
            best_card = card
            best_name = name
        end
    end

    local four_fingers = next(find_joker and find_joker('Four Fingers') or {}) and true or false
    local target_size = 5 - (four_fingers and 1 or 0)

    local function best_name_from_results(results)
        local best_n, sc_best, fb_best = nil, nil, -1
        for _, name in ipairs(names_priority) do
            if results[name] and next(results[name]) then
                local sc_num, sc_fb = score_name(name)
                local better
                if type(sc_num) == 'number' and type(sc_best) == 'number' then
                    better = sc_num > sc_best
                elseif type(sc_num) == 'number' and sc_best == nil then
                    better = true
                elseif type(sc_num) ~= 'number' and type(sc_best) == 'number' then
                    better = false
                else
                    better = (sc_fb or 0) > (fb_best or -1)
                end
                if better then sc_best = sc_num; fb_best = sc_fb; best_n = name end
            end
        end
        return best_n
    end

    local function evaluate_pool(pool)
        if #pool < target_size then return nil end
        if #pool == target_size then
            if not rawget(_G,'evaluate_poker_hand') then return nil end
            local ok, results = pcall(evaluate_poker_hand, pool)
            if ok and results then return best_name_from_results(results) end
            return nil
        end
        local rc, sc = {}, {}
        local rs = {}
        for _, c in ipairs(pool) do
            local r = get_rank(c)
            local s = get_suit(c)
            if r then rc[r] = (rc[r] or 0) + 1 end
            if s then sc[s] = (sc[s] or 0) + 1 end
            if r and s then
                rs[s] = rs[s] or {}
                rs[s][r] = (rs[s][r] or 0) + 1
            end
        end
        local m1, m2 = 0, 0
        for _, cnt in pairs(rc) do
            if cnt > m1 then m2 = m1; m1 = cnt
            elseif cnt > m2 then m2 = cnt end
        end
        local fl_suit = nil
        for s, cnt in pairs(sc) do
            if cnt >= target_size then fl_suit = s; break end
        end
        local urank = {}
        for r, _ in pairs(rc) do urank[#urank+1] = r end
        table.sort(urank)
        if rc[14] then table.insert(urank, 1, 1) end
        local has_str = false
        local run = 1
        for i = 2, #urank do
            if urank[i] == urank[i-1] + 1 then
                run = run + 1
                if run >= target_size then has_str = true; break end
            elseif urank[i] ~= urank[i-1] then run = 1 end
        end
        local has_sf = false
        if fl_suit then
            local fr = {}
            for r, _ in pairs(rs[fl_suit] or {}) do fr[#fr+1] = r end
            table.sort(fr)
            if rs[fl_suit] and rs[fl_suit][14] then table.insert(fr, 1, 1) end
            local frun = 1
            for i = 2, #fr do
                if fr[i] == fr[i-1] + 1 then
                    frun = frun + 1
                    if frun >= target_size then has_sf = true; break end
                elseif fr[i] ~= fr[i-1] then frun = 1 end
            end
        end
        local has_fh = false
        if fl_suit then
            local fm1, fm2 = 0, 0
            for _, cnt in pairs(rs[fl_suit] or {}) do
                if cnt > fm1 then fm2 = fm1; fm1 = cnt
                elseif cnt > fm2 then fm2 = cnt end
            end
            has_fh = (fm1 >= 3 and fm2 >= 2)
        end
        local has_f5 = false
        if m1 >= 5 then
            for _, rr in pairs(rs) do
                for _, cnt in pairs(rr) do
                    if cnt >= 5 then has_f5 = true end
                end
            end
        end
        local pcnt = 0
        for _, cnt in pairs(rc) do
            if cnt >= 2 then pcnt = pcnt + 1 end
        end
        local valid = {}
        if has_f5 then valid['Flush Five'] = true end
        if m1 >= 5 then valid['Five of a Kind'] = true end
        if has_sf then valid['Straight Flush'] = true end
        if has_fh then valid['Flush House'] = true end
        if m1 >= 4 then valid['Four of a Kind'] = true end
        if m1 >= 3 and m2 >= 2 then valid['Full House'] = true end
        if fl_suit then valid['Flush'] = true end
        if has_str then valid['Straight'] = true end
        if m1 >= 3 then valid['Three of a Kind'] = true end
        if pcnt >= 2 then valid['Two Pair'] = true end
        if pcnt >= 1 then valid['Pair'] = true end
        valid['High Card'] = true
        local best_n, vsc_best, vfb_best = nil, nil, -1
        for _, name in ipairs(names_priority) do
            if valid[name] then
                local vsc, vfb = score_name(name)
                local better
                if type(vsc) == 'number' and type(vsc_best) == 'number' then
                    better = vsc > vsc_best
                elseif type(vsc) == 'number' and vsc_best == nil then
                    better = true
                elseif type(vsc) ~= 'number' and type(vsc_best) == 'number' then
                    better = false
                else
                    better = (vfb or 0) > (vfb_best or -1)
                end
                if better then vsc_best = vsc; vfb_best = vfb; best_n = name end
            end
        end
        return best_n
    end

    for i=1, #deck_cards do
        local c = deck_cards[i]
        local pool = {unpack(remain)}
        pool[#pool+1] = c
        local best_for_c = evaluate_pool(pool)
        if best_for_c then choose_better(c, best_for_c) end
    end

    if best_card then return {best_card}, best_name end
    return nil, nil
end

local old_draw = G.FUNCS.draw_from_deck_to_hand
G.FUNCS.draw_from_deck_to_hand = function(e)
    local st = _ensure_state()
    local cr = G.GAME and G.GAME.current_round
    if cr and (cr.discards_left or 0) == 1 and not st.shake_loop_running then
        local rc = _find_red_card()
        if rc then _start_shake_loop(rc) end
    end
    if st.defer_plan and #G.deck.cards > 0 then
        local hand_space = math.min(#G.deck.cards, G.hand.config.card_limit - #G.hand.cards)
        if G.GAME.blind and G.GAME.blind.name == 'The Serpent' and not G.GAME.blind.disabled
           and (G.GAME.current_round.hands_played > 0 or (G.GAME.current_round.discards_used or 0) > 0) then
            hand_space = math.min(hand_space, 3)
        end
        if hand_space > 0 then
            local normal_draws = hand_space - 1
            local upcoming = {}
            for idx = #G.deck.cards, math.max(1, #G.deck.cards - normal_draws + 1), -1 do
                table.insert(upcoming, G.deck.cards[idx])
            end
            local tmp_hand = {}
            for i = 1, #G.hand.cards do tmp_hand[#tmp_hand+1] = G.hand.cards[i] end
            for i = 1, #upcoming do tmp_hand[#tmp_hand+1] = upcoming[i] end
            local plan, target_name = plan_for_best_hand(tmp_hand, 1, normal_draws)
            if plan and plan[1] then
                local target_pos = #G.deck.cards - hand_space + 1
                for i = 1, #G.deck.cards do
                    if G.deck.cards[i] == plan[1] then
                        if i ~= target_pos then
                            G.deck.cards[i], G.deck.cards[target_pos] = G.deck.cards[target_pos], G.deck.cards[i]
                        end
                        break
                    end
                end
                local ref = st.red_card_ref
                if ref and target_name then
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.4,
                        func = function()
                            if rawget(_G, 'card_eval_status_text') then
                                card_eval_status_text(ref, 'extra', nil, nil, nil, {message = localize(target_name, 'poker_hands')})
                            end
                            return true
                        end
                    }))
                end
            end
        end
        st.defer_plan = nil
        st.red_card_ref = nil
    end
    return old_draw(e)
end

local old_discard = G.FUNCS.discard_cards_from_highlighted
G.FUNCS.discard_cards_from_highlighted = function(e, hook)
    local cr = G.GAME and G.GAME.current_round
    if cr and (cr.discards_left or 0) == 1 and #G.hand.highlighted > 0 then
        local has_red = false
        local red_card_ref = nil
        if G.jokers and G.jokers.cards then
            for i=1, #G.jokers.cards do
                local j = G.jokers.cards[i]
                if j and j.ability and j.ability.name == 'Red Card' and not j.debuff then
                    has_red = true
                    red_card_ref = j
                    break
                end
            end
        end
        if has_red and G and G.deck and G.hand then
            local remain = build_remaining_hand(G.hand.highlighted)
            local draw_n = math.min(#G.deck.cards, math.max(0, G.hand.config.card_limit - (#G.hand.cards - #G.hand.highlighted)))
            if G.GAME.blind and G.GAME.blind.name == 'The Serpent' and not G.GAME.blind.disabled then
                local hands_played = G.GAME.current_round.hands_played or 0
                local discards_used = (G.GAME.current_round.discards_used or 0) + 1
                if (hands_played > 0 or discards_used > 0) then
                    draw_n = math.min(#G.deck.cards, math.min(draw_n, 3))
                end
            end
            if draw_n > 0 then
                local st = _ensure_state()
                st.defer_plan = true
                st.red_card_ref = red_card_ref
                _stop_shake_loop()
            end
        end
    end
    return old_discard(e, hook)
end

local base_calculate_joker = Card.calculate_joker
function Card:calculate_joker(context)
    if self.ability and self.ability.name == 'Red Card' and not self.debuff then
        local is_bp = context and context.blueprint
        local sliced = context and (context.blueprint_card or self).getting_sliced

        if context and context.pre_discard and not is_bp and not sliced then
            local cr = G.GAME and G.GAME.current_round
            if cr and (cr.discards_left or 0) == 1 and context.full_hand and G and G.deck and G.hand then
                local st = _ensure_state()
                local remain = build_remaining_hand(context.full_hand)
                local draw_n = compute_expected_draw_space(#remain)
                if draw_n > 0 then
                    st.defer_plan = true
                    st.red_card_ref = self
                    _stop_shake_loop()
                end
            end
        end
        return nil
    end
    return base_calculate_joker(self, context)
end