
local function is_legendary_class(rarity)
    if rarity == nil or rarity == 4 or rarity == 'Legendary' then return true end
    if type(rarity) == 'number' then return false end
    local info = SMODS.Rarities and SMODS.Rarities[rarity]
    if not info then return false end
    local pool = info.pools and info.pools.Joker
    local weight = (type(pool) == 'table' and pool.weight) or info.default_weight or 0
    return weight == 0
end

local function choose_target(card)
    if not (G and G.jokers and G.jokers.cards) then return nil end
    local pool = {}
    for i = 1, #G.jokers.cards do
        local j = G.jokers.cards[i]
        if j ~= card and not j.getting_sliced and not j.removed
           and j.config and j.config.center
           and not is_legendary_class(j.config.center.rarity)
           and j.config.center.blueprint_compat then
            table.insert(pool, j)
        end
    end
    return #pool > 0 and pseudorandom_element(pool, pseudoseed('abstract')) or nil
end

-- Talisman and Amulet keep big numbers as objects: cdata in Amulet (reported as 'table' when its
-- compatibility mode is on), tables with OmegaMeta/BigMeta in older Talisman. The save file stores
-- them like plain numbers, so the snapshot keeps them instead of dropping them with other objects.
local function is_big_number(value)
    local big = rawget(_G, 'Big')
    local is = type(big) == 'table' and rawget(big, 'is')
    if type(is) == 'function' then
        local ok, res = pcall(is, value)
        if ok and res then return true end
    end
    local mt = getmetatable(value)
    return mt ~= nil and (mt == rawget(_G, 'OmegaMeta') or mt == rawget(_G, 'BigMeta'))
end

local function snapshot_value(value, depth, seen)
    local kind = type(value)
    if kind == 'number' or kind == 'string' or kind == 'boolean' then return value end
    if (kind == 'table' or kind == 'cdata') and is_big_number(value) then return value end
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

local function joker_display_name(center)
    if not center then return 'none' end
    local key = center.key

    local function usable(value)
        if type(value) == 'table' then value = table.concat(value, ' ') end
        if type(value) ~= 'string' then return nil end
        value = value:gsub('{[^}]*}', ''):gsub('^%s+', ''):gsub('%s+$', '')
        if value == '' or value == 'ERROR' then return nil end
        return value
    end

    local ok, localized = pcall(localize, { type = 'name_text', set = center.set or 'Joker', key = key })
    local name = ok and usable(localized)
    if name then return name end

    name = center.loc_txt and usable(center.loc_txt.name)
    if name then return name end

    name = center.name ~= key and usable(center.name)
    if name then return name end

    return (tostring(key):gsub('^j_', ''):gsub('_', ' '))
end

-- Same contract as SMODS.blueprint_effect (the outer copier stays the owner of the effect, the
-- copier stack is kept), but a non-table result such as `true` is passed through and the context
-- is restored even when the copied Joker errors.
local function copy_effect(card, target, context)
    local center = target and target.config and target.config.center
    if not center or not center.blueprint_compat
       or target == card or target.debuff or context.no_blueprint then
        return nil
    end
    if (context.blueprint or 0) > #G.jokers.cards then return nil end

    local prev_count, prev_owner = context.blueprint, context.blueprint_card
    local stack = context.blueprint_copiers_stack or {}
    context.blueprint = (prev_count or 0) + 1
    context.blueprint_card = prev_owner or card
    context.blueprint_copiers_stack = stack
    stack[#stack + 1] = card
    context.blueprint_copier = card
    local owner = context.blueprint_card

    local ok, res = xpcall(function() return target:calculate_joker(context) end, function(err)
        return debug and debug.traceback and debug.traceback(tostring(err), 2) or err
    end)

    context.blueprint = prev_count
    context.blueprint_card = prev_owner
    stack[#stack] = nil
    context.blueprint_copier = stack[#stack]
    if not ok then error(res, 0) end

    if type(res) == 'table' then res.card = owner end
    return res
end

local function forward_effect(card, context)
    local target = card.ability._abstract_round_chosen and resolve_target(card)
    if not (target and target ~= card and target.ability) then return nil end

    local res = copy_effect(card, target, context)
    if res == true then return true end
    if check_effect(res) then
        res.colour = G.C.GREY
        return res
    end
    return nil
end

-- The reset waits until every Joker has been calculated for this context, so Blueprint and
-- Brainstorm copies of Abstract placed after it still get the target's end of round effect.
local function schedule_reset(card, silent)
    G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = function()
            if not card.removed and card.ability and card.ability._abstract_round_chosen then
                clear_target(card)
                if not silent then
                    card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_reset')})
                end
            end
            return true
        end
    }))
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
                local ln = joker_display_name(tgt.config.center)
                name = (type(ln) == 'string') and ln or tgt.config.center.name
            end
            card.ability._abstract_name = name
            card.ability._abstract_round_chosen = true
            if tgt and name ~= 'none' then
                card_eval_status_text(card, 'extra', nil, nil, nil, {message = tostring(name), colour = G.C.FILTER})
            end
        end
        return forward_effect(card, context)
    end

    if context.end_of_round and not context.individual and not context.repetition then
        local res = forward_effect(card, context)
        if not context.blueprint then
            schedule_reset(card, context.game_over)
        end
        return res
    end

    return forward_effect(card, context)
end

SMODS.Joker:take_ownership('abstract', {
    rarity = 2,
    cost = 8,
    loc_txt = {
        name = 'Abstract Joker',
        text = {
            'When {C:attention}Blind{} is selected,',
            'randomly copies the effect of',
            'any other {C:attention}non-legendary{} Joker',
            '{C:inactive}Resets effect at end of round{}',
            '{C:inactive}(Currently copying {C:attention}#1#{}{C:inactive})'
        }
    },
    config = { extra = 0 },
    loc_vars = function(self, info_queue, card)
        local ability = card and card.ability
        local center = ability and ability._abstract_key and G.P_CENTERS[ability._abstract_key]
        local name = (center and joker_display_name(center)) or (ability and ability._abstract_name) or 'none'
        return { vars = { tostring(name) } }
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
