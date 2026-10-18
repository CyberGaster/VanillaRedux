
local function choose_target(card)
    if not (G and G.jokers and G.jokers.cards) then return nil end
    local pool = {}
    for i = 1, #G.jokers.cards do
        local j = G.jokers.cards[i]
        if j ~= card and not j.getting_sliced and not j.removed
           and j.config and j.config.center
           and type(j.config.center.rarity) == 'number' and j.config.center.rarity < 4
           and (j.config.center.blueprint_compat ~= false) then
            table.insert(pool, j)
        end
    end
    return #pool > 0 and pseudorandom_element(pool, pseudoseed('abstract')) or nil
end

local function snapshot_value(value, depth, seen)
    local kind = type(value)
    if kind == 'number' or kind == 'string' or kind == 'boolean' then return value end
    if kind ~= 'table' or depth > 8 or seen[value] or getmetatable(value) then return nil end
    seen[value] = true
    local out = {}
    for k, v in pairs(value) do
        if type(k) == 'string' or type(k) == 'number' then
            local copied = snapshot_value(v, depth + 1, seen)
            if copied ~= nil then out[k] = copied end
        end
    end
    seen[value] = nil
    return out
end

local function refresh_snapshot(card)
    local tgt = card.vr_abstract_target
    if type(tgt) == 'table' and tgt.ability then
        card.ability._abstract_snapshot = snapshot_value(tgt.ability, 0, {})
    end
end

local function remove_ghost(card)
    local ghost = card.vr_abstract_ghost
    card.vr_abstract_ghost = nil
    if ghost and not ghost.removed then ghost:remove() end
end

local function clear_target(card)
    remove_ghost(card)
    card.vr_abstract_target = nil
    card.ability._abstract_target = nil
    card.ability._abstract_key = nil
    card.ability._abstract_sort_id = nil
    card.ability._abstract_snapshot = nil
    card.ability._abstract_name = 'none'
    card.ability._abstract_round_chosen = false
end

local function create_ghost(card, key)
    local center = G.P_CENTERS[key]
    if not center then return nil end
    local ghost = Card(-10, -10, G.CARD_W, G.CARD_H, G.P_CARDS.empty, center,
        { bypass_discovery_center = true, bypass_discovery_ui = true })
    ghost.states.visible = false
    ghost.states.collide.can = false
    ghost.states.hover.can = false
    ghost.states.click.can = false
    ghost.states.drag.can = false
    for k, v in pairs(card.ability._abstract_snapshot or {}) do
        ghost.ability[k] = snapshot_value(v, 0, {})
    end
    card.vr_abstract_ghost = ghost
    return ghost
end

local function resolve_target(card)
    local live = card.vr_abstract_target
    if type(live) == 'table' and live.ability then return live end

    local key = card.ability._abstract_key
    if not key then return nil end

    local sort_id = card.ability._abstract_sort_id
    for _, j in ipairs((G.jokers and G.jokers.cards) or {}) do
        if j ~= card and j.sort_id == sort_id and j.config and j.config.center
           and j.config.center.key == key then
            card.vr_abstract_target = j
            return j
        end
    end

    local ghost = create_ghost(card, key)
    card.vr_abstract_target = ghost
    return ghost
end

local function check_effect(res)
    if not res or type(res) ~= 'table' then return false end
    return (res.mult and res.mult ~= 0) or (res.mult_mod and res.mult_mod ~= 0) or
           (res.chips and res.chips ~= 0) or (res.chip_mod and res.chip_mod ~= 0) or
           (res.x_mult and res.x_mult ~= 1) or (res.Xmult and res.Xmult ~= 1) or
           (res.Xmult_mod and res.Xmult_mod ~= 1) or (res.xmult and res.xmult ~= 1) or
           (res.x_chips and res.x_chips ~= 1) or (res.xchips and res.xchips ~= 1) or
           (res.dollars and res.dollars ~= 0) or (res.h_dollars and res.h_dollars ~= 0) or
           res.extra or res.remove or res.saved or res.level_up or
           (res.repetitions and res.repetitions > 0) or res.swap or res.balance or res.func
end

local function do_abstract_logic(card, context)
    if card.debuff then return nil end  

    if context.setting_blind and not card.getting_sliced then
        if not card.ability._abstract_round_chosen then
            clear_target(card)
            local tgt = choose_target(card)
            local name = 'none'
            if tgt and tgt.config and tgt.config.center then
                card.vr_abstract_target = tgt
                card.ability._abstract_key = tgt.config.center.key
                card.ability._abstract_sort_id = tgt.sort_id
                refresh_snapshot(card)
                local ln = localize({type = 'name', key = tgt.config.center.key, set = 'Joker'})
                name = (type(ln) == 'string') and ln or tgt.config.center.name
            end
            card.ability._abstract_name = name
            card.ability._abstract_round_chosen = true
            if tgt and name ~= 'none' then
                card_eval_status_text(card, 'extra', nil, nil, nil, {message = tostring(name), colour = G.C.FILTER})
            end
        end
        return nil
    end

    if context.end_of_round and not context.individual and not context.repetition then
        clear_target(card)
        if not context.game_over then
            card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_reset')})
        end
        return nil
    end

    local tgt = card.ability._abstract_round_chosen and resolve_target(card)
    if tgt and tgt ~= card and tgt.ability then
        local prev_count = context.blueprint
        local prev_blueprint_card = context.blueprint_card
        context.blueprint = (context.blueprint or 0) + 1
        context.blueprint_card = card
        if context.blueprint > (#G.jokers.cards + 1) then
            context.blueprint = prev_count
            context.blueprint_card = prev_blueprint_card
            return nil
        end
        local res = tgt:calculate_joker(context)
        context.blueprint = prev_count
        context.blueprint_card = prev_blueprint_card

        if res then
            if res == true then return true end
            if check_effect(res) then
                res.card = card
                res.colour = G.C.GREY
                return res
            end
        end
    end
    return nil
end

SMODS.Joker:take_ownership('abstract', {
    rarity = 2,
    cost = 8,
    loc_txt = {
        name = 'Abstract Joker',
        text = {
            'At beginning of each round,',
            'randomly copies the effect of',
            'any other {C:attention}non-legendary{} Joker',
            '{C:inactive}Resets effect at end of round{}',
            '{C:inactive}(Currently copying {C:attention}#1#{}{C:inactive})'
        }
    },
    config = { extra = 0 },
    loc_vars = function(self, info_queue, card)
        return { vars = { tostring((card and card.ability and card.ability._abstract_name) or 'none') } }
    end,
    set_ability = function(self, card, initial, delay_sprites)
        card.ability._abstract_name = card.ability._abstract_name or 'none'
        card.ability._abstract_round_chosen = card.ability._abstract_round_chosen or false
    end,
    remove_from_deck = function(self, card, from_debuff)
        if not from_debuff then remove_ghost(card) end
    end,
})

if not rawget(_G, 'VP_ABSTRACT_CALC_PATCHED') and rawget(_G, 'Card') and Card.calculate_joker then
    local orig_calc = Card.calculate_joker
    function Card:calculate_joker(context)
        if self.ability and self.ability.name == 'Abstract Joker' and not self.debuff then
            return do_abstract_logic(self, context)
        end
        return orig_calc(self, context)
    end
    _G.VP_ABSTRACT_CALC_PATCHED = true
end

if not rawget(_G, 'VP_ABSTRACT_SAVE_PATCHED') and rawget(_G, 'Card') and Card.save then
    local orig_save = Card.save
    function Card:save()
        if self.ability and self.ability.name == 'Abstract Joker' then
            refresh_snapshot(self)
        end
        return orig_save(self)
    end
    _G.VP_ABSTRACT_SAVE_PATCHED = true
end

if not rawget(_G, 'VP_ABSTRACT_CASHOUT_PATCHED') and rawget(_G, 'G') and G.FUNCS and G.FUNCS.cash_out then
    local orig_cash_out = G.FUNCS.cash_out
    G.FUNCS.cash_out = function(e)
        if G.jokers and G.jokers.cards then
            for _, j in ipairs(G.jokers.cards) do
                if j and j.ability and j.ability.name == 'Abstract Joker' then
                    clear_target(j)
                end
            end
        end
        orig_cash_out(e)
    end
    _G.VP_ABSTRACT_CASHOUT_PATCHED = true
end
