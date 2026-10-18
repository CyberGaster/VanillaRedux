local function _dg_to_number(x)
    if type(x) == 'number' then return x end
    if type(x) == 'string' then return tonumber(x) or 0 end
    if type(x) == 'table' then
        local ok, v
        if x.toNumber then ok, v = pcall(function() return x:toNumber() end); if ok and type(v) == 'number' then return v end end
        if x.to_number then ok, v = pcall(function() return x:to_number() end); if ok and type(v) == 'number' then return v end end
        local s = tostring(x)
        local n = tonumber(s)
        if n then return n end
    end
    return 0
end

local function update_sell_cost(card)
    if not card or not card.ability then return end
    local extra = card.ability.extra
    if type(extra) ~= 'table' then return end
    
    local base = extra.base_sell or 1
    local stored = extra.stored_value or 0
    local total = base + stored + (card.ability.extra_value or 0)
    
    card.sell_cost = math.max(1, math.ceil(total))
    card.sell_cost_label = card.sell_cost
end

SMODS.Joker:take_ownership('delayed_grat', {
    loc_txt = {
        name = 'Delayed Gratification',
        text = {
            'Takes {C:attention}25%{} of earned money at',
            'end of round and adds to {C:money}sell value{}',
            'Sell value increases by {C:attention}50%{}',
            'when {C:attention}Boss Blind{} is defeated'
        }
    },
    config = {
        extra = {
            take_percent = 0.25,
            boss_bonus = 0.5,
            stored_value = 0,
            base_sell = 1
        }
    },
    blueprint_compat = false,
    update = function(self, card, dt)
        if not (card and card.ability) then return end
        local extra = card.ability.extra
        if type(extra) ~= 'table' then
            card.ability.extra = {
                take_percent = 0.25,
                boss_bonus = 0.5,
                stored_value = 0,
                base_sell = 1
            }
        end
        update_sell_cost(card)
    end,
    set_ability = function(self, card, initial, delay_sprites)
        card.ability.extra = card.ability.extra or {}
        if type(card.ability.extra) ~= 'table' then
            card.ability.extra = {
                take_percent = 0.25,
                boss_bonus = 0.5,
                stored_value = 0,
                base_sell = 1
            }
        end
        local extra = card.ability.extra
        extra.take_percent = extra.take_percent or 0.25
        extra.boss_bonus = extra.boss_bonus or 0.5
        extra.stored_value = extra.stored_value or 0
        extra.base_sell = extra.base_sell or 1
        card.sell_cost = extra.base_sell
        card.sell_cost_label = extra.base_sell
    end,
})

    local function apply_delayed_grat_patches()
        if not rawget(_G,'VP_DELAYED_GRAT_PATCHED') then

            if rawget(_G,'Card') and Card.calculate_dollar_bonus then
                local orig_calc_dollar_bonus = Card.calculate_dollar_bonus
                function Card:calculate_dollar_bonus()
                    if self.ability and self.ability.name == 'Delayed Gratification' then
                        return nil
                    end
                    return orig_calc_dollar_bonus(self)
                end
            end

            if rawget(_G,'Card') and Card.calculate_joker then
                local old_calculate_joker_dg = Card.calculate_joker
                function Card:calculate_joker(context)
                    if self.ability and self.ability.name == 'Delayed Gratification' and not self.debuff then
                        if context and context.end_of_round and not context.game_over then
                            local extra = self.ability.extra
                            if type(extra) == 'table' then
                                local is_boss = false
                                local blind = G.GAME and G.GAME.blind
                                if blind then
                                    if blind.boss == true then
                                        is_boss = true
                                    elseif blind.get_type then
                                        is_boss = (blind:get_type() == 'Boss')
                                    else
                                        local mt = getmetatable(blind)
                                        if mt and mt.get_type then
                                            is_boss = (mt.get_type(blind) == 'Boss')
                                        end
                                    end
                                end
                                extra._boss_defeated_this_round = is_boss
                            end
                        end
                    end
                    return old_calculate_joker_dg(self, context)
                end
            end

            if not _G.VP_CASHOUT_HANDLERS then
                _G.VP_CASHOUT_HANDLERS = {}
            end
            _G.VP_CASHOUT_HANDLERS['j_delayed_grat'] = function(card)
                local extra = card.ability.extra
                if type(extra) ~= 'table' then return end

                local round_dollars = _dg_to_number(G.GAME.current_round.dollars)
                if round_dollars > 0 then
                    local raw_take = round_dollars * (extra.take_percent or 0.25)
                    local take_amount = math.ceil(raw_take)
                    if take_amount > 0 then
                        G.GAME.current_round.dollars = round_dollars - take_amount
                        extra.stored_value = (extra.stored_value or 0) + take_amount
                        update_sell_cost(card)
                        card:juice_up(0.8, 0.8)
                        if rawget(_G,'card_eval_status_text') then
                            card_eval_status_text(card, 'extra', nil, nil, nil, {
                                message = '+$'..take_amount,
                                colour = G.C.MONEY
                            })
                        end
                    end
                end

                if extra._boss_defeated_this_round and (extra.stored_value or 0) > 0 then
                    local bonus_mult = extra.boss_bonus or 0.5
                    local current_value = extra.stored_value or 0
                    local bonus = math.ceil(current_value * bonus_mult + 0.001)
                    if bonus > 0 then
                        extra.stored_value = math.ceil(current_value + bonus)
                        update_sell_cost(card)
                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 0.4,
                            func = function()
                                card:juice_up(0.8, 0.8)
                                if rawget(_G,'card_eval_status_text') then
                                    card_eval_status_text(card, 'extra', nil, nil, nil, {
                                        message = '+50%!',
                                        colour = G.C.GOLD
                                    })
                                end
                                return true
                            end
                        }))
                    end
                    extra._boss_defeated_this_round = false
                end
            end


            _G.VP_DELAYED_GRAT_PATCHED = true
        end
    end

apply_delayed_grat_patches()
