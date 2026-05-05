local function choose_target(card)
    if not (G and G.jokers and G.jokers.cards) then return nil end
    local pool = {}
    for i = 1, #G.jokers.cards do
        local j = G.jokers.cards[i]
        if j ~= card and j.config and j.config.center
           and j.config.center.rarity and j.config.center.rarity < 4
           and (j.config.center.blueprint_compat ~= false) then
            table.insert(pool, j)
        end
    end
    return #pool > 0 and pseudorandom_element(pool, pseudoseed('abstract')) or nil
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
            local tgt = choose_target(card)
            card.ability._abstract_target = tgt
            local name = 'none'
            if tgt and tgt.config and tgt.config.center then
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
        card.ability._abstract_target = nil
        card.ability._abstract_name = 'none'
        card.ability._abstract_round_chosen = false
        if not context.game_over then
            card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_reset')})
        end
        return nil
    end

    local tgt = card.ability._abstract_target
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

if not rawget(_G, 'VP_ABSTRACT_CASHOUT_PATCHED') and rawget(_G, 'G') and G.FUNCS and G.FUNCS.cash_out then
    local orig_cash_out = G.FUNCS.cash_out
    G.FUNCS.cash_out = function(e)
        if G.jokers and G.jokers.cards then
            for _, j in ipairs(G.jokers.cards) do
                if j and j.ability and j.ability.name == 'Abstract Joker' then
                    j.ability._abstract_target = nil
                    j.ability._abstract_name = 'none'
                    j.ability._abstract_round_chosen = false
                end
            end
        end
        orig_cash_out(e)
    end
    _G.VP_ABSTRACT_CASHOUT_PATCHED = true
end
