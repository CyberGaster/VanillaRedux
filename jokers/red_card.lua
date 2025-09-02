return function(center)

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Red Card'
    center.loc_txt.text = {
        'On the {C:attention}last discard{} of the round,',
        'draw {C:attention}1 card{} from your deck',
        'to form your best-scoring {C:attention}poker hand{}'
    }
    center.blueprint_compat = false

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
            if not rawget(_G,'evaluate_poker_hand') then return nil end
            if #pool < target_size then return nil end
            if #pool == target_size then
                local ok, results = pcall(evaluate_poker_hand, pool)
                if ok and results then return best_name_from_results(results) end
                return nil
            end
            local n = #pool
            local subset = {}
            local best_n = nil
            local sc_best, fb_best = nil, -1
            local function consider_current()
                local ok, results = pcall(evaluate_poker_hand, subset)
                if not ok or not results then return end
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
            end
            local function gen(start, need)
                if need == 0 then consider_current(); return end
                for i = start, n - need + 1 do
                    subset[#subset+1] = pool[i]
                    gen(i+1, need-1)
                    subset[#subset] = nil
                end
            end
            gen(1, target_size)
            return best_n
        end

        for i=1, #deck_cards do
            local c = deck_cards[i]
            local pool = {unpack(remain)}
            pool[#pool+1] = c
            local best_for_c = evaluate_pool(pool)
            if not best_for_c then
                local remain_suits = count_by_suit(remain)
                local remain_ranks = count_by_rank(remain)
                local r = get_rank(c); local s = get_suit(c)
                if r and s then
                    local after_rank = (remain_ranks[r] or 0) + 1
                    local after_suit = (remain_suits[s] or 0) + 1
                    if after_rank >= 5 then
                        best_for_c = 'Five of a Kind'
                    elseif after_rank == 4 then
                        best_for_c = 'Four of a Kind'
                    elseif after_suit >= 5 then
                        best_for_c = 'Flush'
                    elseif after_rank == 3 then
                        best_for_c = 'Three of a Kind'
                    elseif (remain_ranks[r] or 0) == 1 then
                        local has_other_pair = false
                        for _, rr in ipairs(RANKS) do
                            if rr ~= r and (remain_ranks[rr] or 0) >= 2 then has_other_pair = true; break end
                        end
                        best_for_c = has_other_pair and 'Two Pair' or 'Pair'
                    else
                        best_for_c = 'High Card'
                    end
                end
            end
            if best_for_c then choose_better(c, best_for_c) end
        end

        if best_card then return {best_card}, best_name end
        return nil, nil
    end

    if not rawget(_G,'VP_REDCARD_PATCHED_DRAW') and rawget(_G,'G') then
        _G.VP_REDCARD_PATCHED_DRAW = true
        local old_draw = G.FUNCS.draw_from_deck_to_hand
        G.FUNCS.draw_from_deck_to_hand = function(e)
            local st = _ensure_state()
            if st then
                local cr = G.GAME and G.GAME.current_round
                if cr and (cr.discards_left or 0) == 1 and not st.shake_loop_running then
                    local rc = _find_red_card()
                    if rc then _start_shake_loop(rc) end
                end
                if st.defer_plan then
                    local hand_space = e or math.min(#G.deck.cards, G.hand.config.card_limit - #G.hand.cards)
                    if G.GAME.blind and G.GAME.blind.name == 'The Serpent' and not G.GAME.blind.disabled and (G.GAME.current_round.hands_played > 0 or G.GAME.current_round.discards_used > 0) then
                        hand_space = math.min(#G.deck.cards, 3, hand_space)
                    end
                    if hand_space <= 0 then
                        st.defer_plan = nil
                        return old_draw(e)
                    end
                    delay(0.3)
                    if hand_space == 1 then
                        local remain_now = {}
                        for i=1, #G.hand.cards do remain_now[i] = G.hand.cards[i] end
                        local plan, target_name = plan_for_best_hand(remain_now, 1, 0)
                        if plan and plan[1] then
                            draw_card(G.deck, G.hand, 100, 'up', true, plan[1])
                            if st.red_card_ref and target_name and rawget(_G,'card_eval_status_text') then
                                card_eval_status_text(st.red_card_ref, 'extra', nil, nil, nil, {message = localize(target_name, 'poker_hands')})
                            end
                        else
                            draw_card(G.deck, G.hand, 100, 'up', true)
                        end
                        st.defer_plan = nil; st.red_card_ref = nil
                        return
                    end
                    local rnd = hand_space - 1
                    local pre_deck_count = #G.deck.cards
                    local upcoming = {}
                    if rnd > 0 then
                        for idx = pre_deck_count, math.max(1, pre_deck_count - rnd + 1), -1 do
                            table.insert(upcoming, G.deck.cards[idx])
                        end
                    end
                    local tmp_hand = {unpack(G.hand.cards)}
                    for i=1, #upcoming do tmp_hand[#tmp_hand+1] = upcoming[i] end
                    local plan, target_name = plan_for_best_hand(tmp_hand, 1, rnd)
                    for i=1, rnd do
                        draw_card(G.deck, G.hand, i*100/math.max(1, hand_space), 'up', true)
                    end
                    if plan and plan[1] then
                        draw_card(G.deck, G.hand, 100, 'up', true, plan[1])
                        if st.red_card_ref and target_name and rawget(_G,'card_eval_status_text') then
                            if st.red_card_ref.juice_up then st.red_card_ref:juice_up(0.9, 0.6) end
                            card_eval_status_text(st.red_card_ref, 'extra', nil, nil, nil, {message = localize(target_name, 'poker_hands')})
                        end
                    else
                        draw_card(G.deck, G.hand, 100, 'up', true)
                    end
                    st.defer_plan = nil; st.red_card_ref = nil
                    return
                end
            end
            return old_draw(e)
        end
    end

    if not rawget(_G,'VP_REDCARD_PATCHED_DISCARD') and rawget(_G,'G') and G.FUNCS and G.FUNCS.discard_cards_from_highlighted then
        _G.VP_REDCARD_PATCHED_DISCARD = true
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
    end

    if not rawget(_G,'VP_REDCARD_PATCHED_CALC') and rawget(_G,'Card') and Card.calculate_joker then
        _G.VP_REDCARD_PATCHED_CALC = true
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
    end

    if SMODS and SMODS.Hook then
        SMODS.Hook.add('post_game_init', function()
            if G.localization and G.localization.descriptions and G.localization.descriptions.Joker then
                G.localization.descriptions.Joker.j_red_card = G.localization.descriptions.Joker.j_red_card or {}
                G.localization.descriptions.Joker.j_red_card.name = center.loc_txt.name
                G.localization.descriptions.Joker.j_red_card.text = center.loc_txt.text
            end
            if G.P_CENTERS.j_red_card then
                G.P_CENTERS.j_red_card.mod = nil
                G.P_CENTERS.j_red_card.mod_id = nil
                G.P_CENTERS.j_red_card.modded = false
                G.P_CENTERS.j_red_card.discovered = true
                G.P_CENTERS.j_red_card.blueprint_compat = false
            end
        end)
    end

    if not (SMODS and SMODS.Hook) then
        if rawget(_G,'G') and G.P_CENTERS and G.P_CENTERS.j_red_card then
            G.P_CENTERS.j_red_card.mod = nil
            G.P_CENTERS.j_red_card.mod_id = nil
            G.P_CENTERS.j_red_card.modded = false
            G.P_CENTERS.j_red_card.discovered = true
            G.P_CENTERS.j_red_card.blueprint_compat = false
        end
        if rawget(_G,'G') and G.localization and G.localization.descriptions and G.localization.descriptions.Joker then
            G.localization.descriptions.Joker.j_red_card = G.localization.descriptions.Joker.j_red_card or {}
            G.localization.descriptions.Joker.j_red_card.name = center.loc_txt.name
            G.localization.descriptions.Joker.j_red_card.text = center.loc_txt.text
        end
    end
end