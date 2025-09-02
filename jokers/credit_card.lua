return function(center)
    center.config = center.config or {}
    center.config.extra = 20
    center.blueprint_compat = false
    
    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Credit Card'
    center.loc_txt.text = {
        'Go up to {C:red}-$#1#{} in debt',
        'Allows you to make {C:attention}1 free purchase{}',
        'to store per round {C:inactive}[except vouchers]{}',
        'Takes {C:attention}25%{} of money received',
        'at end of round'
    }
    
    center.config.extra = center.config.extra or 20

    local orig_calc = center.calculate
    center.calculate = function(self, card, context)
        if orig_calc then return orig_calc(self, card, context) end
        return nil
    end
    local orig_update = center.update
    center.update = function(self, card, dt)
        if orig_update then orig_update(self, card, dt) end
        if not (card and card.ability) then return end
        local current_round = (rawget(_G,'G') and G.GAME and G.GAME.round) or 0
        if card.ability._vp_cc_last_round == nil then
            card.ability._vp_cc_last_round = current_round
            card.ability._vp_cc_shop_state = 'ready'
        elseif current_round > card.ability._vp_cc_last_round then
            card.ability._vp_cc_last_round = current_round
            card.ability._vp_cc_shop_state = 'ready'
            card.ability._vp_cc_coupon_active = nil
            card.ability._vp_cc_coupon_processed = nil
            if G.shop_jokers and G.shop_jokers.cards then
                for i = 1, #G.shop_jokers.cards do
                    local shop_card = G.shop_jokers.cards[i]
                    if shop_card and shop_card.ability and shop_card.ability._vp_cc_display_free then
                        shop_card.ability._vp_cc_display_free = nil
                        if shop_card.set_cost then shop_card:set_cost() end
                    end
                end
            end
            if G.shop_booster and G.shop_booster.cards then
                for i = 1, #G.shop_booster.cards do
                    local shop_card = G.shop_booster.cards[i]
                    if shop_card and shop_card.ability and shop_card.ability._vp_cc_display_free then
                        shop_card.ability._vp_cc_display_free = nil
                        if shop_card.set_cost then shop_card:set_cost() end
                    end
                end
            end
        end
    end
    local function apply_credit_card_patches()
        if not rawget(_G,'VP_CREDIT_CARD_PATCHED') then
            local function _cc_to_number(x)
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
            if rawget(_G,'G') and G.FUNCS and G.FUNCS.can_buy then
                local orig_can_buy = G.FUNCS.can_buy
                G.FUNCS.can_buy = function(e)
                    local has_credit_card = false
                    if G.jokers and G.jokers.cards then
                        for i = 1, #G.jokers.cards do
                            local j = G.jokers.cards[i]
                            if j and j.ability and j.ability.name == 'Credit Card' and not j.debuff then
                                has_credit_card = true
                                break
                            end
                        end
                    end
                    
                    if has_credit_card then
                        local ref = e and e.config and e.config.ref_table
                        if not ref then return orig_can_buy(e) end
                        local cost_n = _cc_to_number(ref.cost)
                        local dollars_n = _cc_to_number(rawget(_G,'G') and G.GAME and G.GAME.dollars)
                        if (cost_n > dollars_n + 20) and (cost_n > 0) then
                            e.config.colour = G.C.UI.BACKGROUND_INACTIVE
                            e.config.button = nil
                        else
                            e.config.colour = G.C.ORANGE
                            e.config.button = 'buy_from_shop'
                        end
                    else
                        orig_can_buy(e)
                    end
                end
            end

            if rawget(_G,'Card') and Card.set_cost then
                local orig_set_cost = Card.set_cost
                function Card:set_cost()
                    orig_set_cost(self)
                    
                    if self.area and (self.area == G.shop_jokers or self.area == G.shop_booster) 
                       and self.ability.set ~= 'Voucher' then
                        
                        local credit_card = nil
                        if G.jokers and G.jokers.cards then
                            for i = 1, #G.jokers.cards do
                                if G.jokers.cards[i].ability.name == 'Credit Card' then
                                    credit_card = G.jokers.cards[i]
                                    break
                                end
                            end
                        end
                        
                        if credit_card and not credit_card.debuff then
                            credit_card.ability = credit_card.ability or {}
                            local cc_state = credit_card.ability._vp_cc_shop_state or 'ready'
                            
                            if self.ability._vp_cc_display_free and cc_state == 'used' then
                                self.ability._vp_cc_display_free = nil
                                orig_set_cost(self)
                                return
                            end
                            
                            if G.GAME.shop_free and not credit_card.ability._vp_cc_coupon_processed then
                                credit_card.ability._vp_cc_coupon_active = true
                                return
                            else
                                if credit_card.ability._vp_cc_coupon_active or credit_card.ability._vp_cc_coupon_processed then
                                    credit_card.ability._vp_cc_coupon_active = nil
                                    credit_card.ability._vp_cc_coupon_processed = nil
                                    
                                    if credit_card.ability._vp_cc_shop_state ~= 'used' then
                                        credit_card.ability._vp_cc_shop_state = 'ready'
                                    end
                                end
                            end
                            
                            if cc_state == 'ready' and not (rawget(_G,'G') and G.GAME and G.GAME._vp_cc_reverting_prices) and _cc_to_number(self.cost) > 0 then
                                local original_cost = _cc_to_number(self.base_cost)
                                local is_couponed = self.ability.couponed
                                
                                if original_cost > 0 and not is_couponed then
                                    self.cost = 0
                                    self.ability._vp_cc_display_free = true
                                end
                            end
                        end
                    end
                end
            end

            if rawget(_G,'G') and G.FUNCS and G.FUNCS.buy_from_shop then
                local orig_buy_from_shop = G.FUNCS.buy_from_shop
                G.FUNCS.buy_from_shop = function(e)
                    local card_to_buy = e.config.ref_table
                    
                    if card_to_buy and card_to_buy:is(Card) and card_to_buy.ability.set ~= 'Voucher' then
                        local credit_card = nil
                        if G.jokers and G.jokers.cards then
                            for i = 1, #G.jokers.cards do
                                if G.jokers.cards[i].ability.name == 'Credit Card' then
                                    credit_card = G.jokers.cards[i]
                                    break
                                end
                            end
                        end
                        
                        if credit_card and not credit_card.debuff and not credit_card.ability._vp_cc_coupon_active then
                            credit_card.ability = credit_card.ability or {}
                            local cc_state = credit_card.ability._vp_cc_shop_state or 'ready'
                            
                            if cc_state == 'ready' and _cc_to_number(card_to_buy.cost) == 0 then
                                local original_cost = _cc_to_number(card_to_buy.base_cost)
                                local is_couponed = card_to_buy.ability.couponed
                                
                                if original_cost > 0 and not is_couponed then
                                    orig_buy_from_shop(e)
                                    
                                    credit_card.ability._vp_cc_shop_state = 'used'
                                    
                                    if G.shop_jokers and G.shop_jokers.cards then
                                        for i = 1, #G.shop_jokers.cards do
                                            local shop_card = G.shop_jokers.cards[i]
                                            if shop_card and shop_card ~= card_to_buy and shop_card.ability and shop_card.ability._vp_cc_display_free then
                                                shop_card.ability._vp_cc_display_free = nil
                                                if shop_card.set_cost then shop_card:set_cost() end
                                            end
                                        end
                                    end
                                    if G.shop_booster and G.shop_booster.cards then
                                        for i = 1, #G.shop_booster.cards do
                                            local shop_card = G.shop_booster.cards[i]
                                            if shop_card and shop_card ~= card_to_buy and shop_card.ability and shop_card.ability._vp_cc_display_free then
                                                shop_card.ability._vp_cc_display_free = nil
                                                if shop_card.set_cost then shop_card:set_cost() end
                                            end
                                        end
                                    end
                                    
                                    credit_card:juice_up(0.8, 0.8)
                                    if rawget(_G,'card_eval_status_text') then
                                        card_eval_status_text(credit_card, 'extra', nil, nil, nil, {
                                            message = 'FREE',
                                            colour = G.C.MONEY
                                        })
                                    end
                                    
                                    return
                                end
                            end
                        end
                    end
                    
                    orig_buy_from_shop(e)
                end
            end
        
            if rawget(_G,'G') and G.FUNCS and G.FUNCS.reroll_shop then
                local orig_reroll_shop = G.FUNCS.reroll_shop
                G.FUNCS.reroll_shop = function(e)
                    local credit_card = nil
                    if G.jokers and G.jokers.cards then
                        for i = 1, #G.jokers.cards do
                            if G.jokers.cards[i].ability.name == 'Credit Card' then
                                credit_card = G.jokers.cards[i]
                                break
                            end
                        end
                    end
                    
                    orig_reroll_shop(e)
                    
                    G.GAME.shop_free = false
                    
                    if credit_card then
                        credit_card.ability._vp_cc_coupon_active = nil
                        credit_card.ability._vp_cc_coupon_processed = true
                        
                        if credit_card.ability._vp_cc_shop_state ~= 'used' then
                            credit_card.ability._vp_cc_shop_state = 'ready'
                            
                            local delays = {0.1, 0.2, 0.3, 0.5}
                            for _, delay in ipairs(delays) do
                                G.E_MANAGER:add_event(Event({
                                    trigger = 'after',
                                    delay = delay,
                                    func = function()
                                        if credit_card.ability then
                                            credit_card.ability._vp_cc_coupon_active = nil
                                        end
                                        force_update_shop_prices()
                                        return true
                                    end
                                }))
                            end
                        end
                    end
                end
            end

            if rawget(_G,'Card') and Card.calculate_joker then
                local old_calculate_joker = Card.calculate_joker
                function Card:calculate_joker(context)
                    if self.ability and self.ability.name == 'Credit Card' and not self.debuff and context and context.selling_self then
                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 0.05,
                            func = function()
                                force_update_shop_prices(true)
                                return true
                            end
                        }))
                    end
                    return old_calculate_joker(self, context)
                end
            end

            function force_update_shop_prices(force_revert)
                local credit_card = nil
                if G.jokers and G.jokers.cards then
                    for i = 1, #G.jokers.cards do
                        if G.jokers.cards[i].ability.name == 'Credit Card' then
                            credit_card = G.jokers.cards[i]
                            break
                        end
                    end
                end
                
                if force_revert or not credit_card or (credit_card and credit_card.debuff) then
                    local function revert_area(area)
                        local changed = false
                        if area and area.cards then
                            if rawget(_G,'G') and G.GAME then G.GAME._vp_cc_reverting_prices = true end
                            for i = 1, #area.cards do
                                local c = area.cards[i]
                                if c and c.ability and c.ability.set ~= 'Voucher' then
                                    if c.ability._vp_cc_display_free then
                                        c.ability._vp_cc_display_free = nil
                                    end
                                    if c.set_cost then c:set_cost() end
                                    changed = true
                                end
                            end
                            if rawget(_G,'G') and G.GAME then G.GAME._vp_cc_reverting_prices = nil end
                        end
                        return changed
                    end
                    local r1 = revert_area(G.shop_jokers)
                    local r2 = revert_area(G.shop_booster)
                    return r1 or r2
                else
                    credit_card.ability = credit_card.ability or {}
                    local cc_state = credit_card.ability._vp_cc_shop_state or 'ready'
                    
                    if credit_card.ability._vp_cc_coupon_processed then
                        credit_card.ability._vp_cc_coupon_active = nil
                        credit_card.ability._vp_cc_coupon_processed = nil
                    end
                    
                    if cc_state == 'ready' and not credit_card.ability._vp_cc_coupon_active then
                        local joker_count = (G.shop_jokers and G.shop_jokers.cards and #G.shop_jokers.cards) or 0
                        local booster_count = (G.shop_booster and G.shop_booster.cards and #G.shop_booster.cards) or 0
                        
                        if joker_count == 0 and booster_count == 0 then
                            return false
                        end
                        
                        local cards_updated = 0
                        
                        if G.shop_jokers and G.shop_jokers.cards then
                            for i = 1, #G.shop_jokers.cards do
                                local shop_card = G.shop_jokers.cards[i]
                                if shop_card and shop_card.ability.set ~= 'Voucher' then
                                    local original_cost = _cc_to_number(shop_card.base_cost)
                                    local is_couponed = shop_card.ability.couponed
                                    
                                    if original_cost > 0 and not is_couponed then
                                        shop_card.cost = 0
                                        shop_card.ability._vp_cc_display_free = true
                                        cards_updated = cards_updated + 1
                                    end
                                end
                            end
                        end
                        
                        if G.shop_booster and G.shop_booster.cards then
                            for i = 1, #G.shop_booster.cards do
                                local shop_card = G.shop_booster.cards[i]
                                if shop_card and shop_card.ability.set ~= 'Voucher' then
                                    local original_cost = _cc_to_number(shop_card.base_cost)
                                    local is_couponed = shop_card.ability.couponed
                                    
                                    if original_cost > 0 and not is_couponed then
                                        shop_card.cost = 0
                                        shop_card.ability._vp_cc_display_free = true
                                        cards_updated = cards_updated + 1
                                    end
                                end
                            end
                        end
                        
                        return cards_updated > 0
                    end
                end
                return false
            end
            if rawget(_G,'create_shop_card_ui') then
                local orig_create_shop_card_ui = create_shop_card_ui
                function create_shop_card_ui(card, type, area)
                    local result = orig_create_shop_card_ui(card, type, area)
                    
                    if card and card.ability.set ~= 'Voucher' then
                        local credit_card = nil
                        if G.jokers and G.jokers.cards then
                            for i = 1, #G.jokers.cards do
                                if G.jokers.cards[i].ability.name == 'Credit Card' then
                                    credit_card = G.jokers.cards[i]
                                    break
                                end
                            end
                        end
                        
                        if credit_card and not credit_card.debuff and credit_card.ability._vp_cc_shop_state == 'ready' and not credit_card.ability._vp_cc_coupon_active then
                            if credit_card.ability._vp_cc_coupon_processed then
                                credit_card.ability._vp_cc_coupon_active = nil
                                credit_card.ability._vp_cc_coupon_processed = nil
                            end
                            
                            local original_cost = _cc_to_number(card.base_cost)
                            local is_couponed = card.ability.couponed
                            
                            if original_cost > 0 and not is_couponed then
                                card.cost = 0
                                card.ability._vp_cc_display_free = true
                            end
                        end
                    end
                    
                    return result
                end
            end

            if rawget(_G,'G') and G.FUNCS and G.FUNCS.use_card then
                local orig_use_card = G.FUNCS.use_card
                G.FUNCS.use_card = function(e, mute, nosave)
                    local card = e.config.ref_table
                    
                    local is_overstock = card and card.ability and card.ability.set == 'Voucher' and 
                                       (card.ability.name == 'Overstock' or card.ability.name == 'Overstock Plus')
                    
                    if card and card.ability.set == 'Booster' and G.STATE == G.STATES.SHOP and _cc_to_number(card.cost) == 0 then
                        local credit_card = nil
                        if G.jokers and G.jokers.cards then
                            for i = 1, #G.jokers.cards do
                                if G.jokers.cards[i].ability.name == 'Credit Card' then
                                    credit_card = G.jokers.cards[i]
                                    break
                                end
                            end
                        end
                        
                        if credit_card and not credit_card.debuff and not credit_card.ability._vp_cc_coupon_active then
                            local cc_state = credit_card.ability._vp_cc_shop_state or 'ready'
                            
                            if cc_state == 'ready' then
                                local original_cost = _cc_to_number(card.base_cost)
                                local is_couponed = card.ability.couponed
                                
                                if original_cost > 0 and not is_couponed then
                                    orig_use_card(e, mute, nosave)
                                    
                                    credit_card.ability._vp_cc_shop_state = 'used'
                                    
                                    if G.shop_jokers and G.shop_jokers.cards then
                                        for i = 1, #G.shop_jokers.cards do
                                            local shop_card = G.shop_jokers.cards[i]
                                            if shop_card and shop_card.ability and shop_card.ability._vp_cc_display_free then
                                                shop_card.ability._vp_cc_display_free = nil
                                                if shop_card.set_cost then shop_card:set_cost() end
                                            end
                                        end
                                    end
                                    if G.shop_booster and G.shop_booster.cards then
                                        for i = 1, #G.shop_booster.cards do
                                            local shop_card = G.shop_booster.cards[i]
                                            if shop_card and shop_card ~= card and shop_card.ability and shop_card.ability._vp_cc_display_free then
                                                shop_card.ability._vp_cc_display_free = nil
                                                if shop_card.set_cost then shop_card:set_cost() end
                                            end
                                        end
                                    end
                                    
                                    credit_card:juice_up(0.8, 0.8)
                                    if rawget(_G,'card_eval_status_text') then
                                        card_eval_status_text(credit_card, 'extra', nil, nil, nil, {
                                            message = 'FREE',
                                            colour = G.C.MONEY
                                        })
                                    end
                                    
                                    return
                                end
                            end
                        end
                    end
                    
                    orig_use_card(e, mute, nosave)
                    
                    if is_overstock then
                        local credit_card = nil
                        if G.jokers and G.jokers.cards then
                            for i = 1, #G.jokers.cards do
                                if G.jokers.cards[i].ability.name == 'Credit Card' then
                                    credit_card = G.jokers.cards[i]
                                    break
                                end
                            end
                        end
                        
                        if credit_card and credit_card.ability._vp_cc_shop_state == 'ready' then
                            G.E_MANAGER:add_event(Event({
                                trigger = 'after',
                                delay = 0.3,
                                func = function()
                                    force_update_shop_prices()
                                    return true
                                end
                            }))
                        end
                    end
                end
            end

            if rawget(_G,'G') and G.FUNCS and G.FUNCS.cash_out then
                local orig_cash_out_cc = G.FUNCS.cash_out
                G.FUNCS.cash_out = function(e)
                    local credit_card = nil
                    if G.jokers and G.jokers.cards then
                        for i = 1, #G.jokers.cards do
                            if G.jokers.cards[i].ability.name == 'Credit Card' then
                                credit_card = G.jokers.cards[i]
                                break
                            end
                        end
                    end
                    
                    if credit_card and not credit_card.debuff and _cc_to_number(G.GAME.current_round.dollars) > 0 then
                        local round_dollars = _cc_to_number(G.GAME.current_round.dollars)
                        local raw_fee = round_dollars * 0.25
                        local decimal_part = raw_fee - math.floor(raw_fee)
                        local credit_fee = decimal_part >= 0.5 and math.ceil(raw_fee) or math.floor(raw_fee)
                        local net_dollars = round_dollars - credit_fee
                        
                        G.GAME.current_round.dollars = net_dollars
                        
                        credit_card:juice_up(0.8, 0.8)
                        if rawget(_G,'card_eval_status_text') then
                            card_eval_status_text(credit_card, 'extra', nil, nil, nil, {
                                message = 'Credit: -$'..credit_fee,
                                colour = G.C.RED
                            })
                        end
                    end
                    
                    orig_cash_out_cc(e)
                    
                    if credit_card then
                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 1.0,
                            func = function()
                                force_update_shop_prices()
                                return true
                            end
                        }))
                    end
                end
            end


            _G.VP_CREDIT_CARD_PATCHED = true
        end
    end

    if SMODS and SMODS.Hook then
        SMODS.Hook.add('post_game_init', function()
            apply_credit_card_patches()
        end)
        SMODS.Hook.add('post_shop_init', function()
            apply_credit_card_patches()
        end)
    else
        local function delayed_patch()
            if rawget(_G,'G') and G.FUNCS and G.FUNCS.buy_from_shop then
                apply_credit_card_patches()
            else
                if love and love.timer then
                    love.timer.sleep(1)
                    delayed_patch()
                end
            end
        end
        delayed_patch()
    end

    do
        local _orig_update = center.update
        center.update = function(self, card, dt)
            if _orig_update then _orig_update(self, card, dt) end
            if not (card and card.ability) then return end
            local was_debuff = card.ability._vp_cc_debuff_last
            local is_debuff = card.debuff and true or false
            if was_debuff == nil then
                card.ability._vp_cc_debuff_last = is_debuff
                return
            end
            if was_debuff ~= is_debuff then
                card.ability._vp_cc_debuff_last = is_debuff
                if is_debuff then
                    if rawget(_G,'force_update_shop_prices') then force_update_shop_prices(true) end
                else
                    if rawget(_G,'force_update_shop_prices') then force_update_shop_prices() end
                end
            end
        end
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_credit_card then
        G.localization.descriptions.Joker.j_credit_card.text = center.loc_txt.text
    end
end
