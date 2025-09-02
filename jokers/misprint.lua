return function(center)
    center.config = center.config or {}
    center.config.extra = center.config.extra or {}
    center.config.extra.plus_min = 0
    center.config.extra.plus_max = 27
    center.config.extra.x_min = 0.5
    center.config.extra.x_max = 2.0

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Misprint'
    center.loc_txt.text = { '' }

    local function pr_float(seed_key, min_v, max_v)
        local base = pseudorandom(seed_key)
        return min_v + (max_v - min_v) * base
    end

    local orig_calculate = center.calculate
    center.calculate = function(self, card, context)
        return orig_calculate and orig_calculate(self, card, context) or nil
    end

    if not rawget(_G,'VP_MISPRINT_CALC_PATCHED') and rawget(_G,'Card') and Card.calculate_joker then
        local old_card_calc = Card.calculate_joker
        function Card:calculate_joker(context)
            if context and context.other_joker and context.other_joker == self and self.ability and self.ability._vp_misprint_pending_x and (not context.blueprint or context.blueprint_card == self) then
                local x_mult = self.ability._vp_misprint_pending_x
                self.ability._vp_misprint_pending_x = nil
                local hand_id = (rawget(_G,'G') and G.GAME and G.GAME.hands_played) or 0
                self.ability._vp_misprint_released_x = {hand = hand_id, x = x_mult}
                return { message = localize{type='variable', key='a_xmult', vars={x_mult}}, Xmult_mod = x_mult, focus = self }
            end
            if self and self.ability and self.ability.set == 'Joker' and self.ability.name == 'Misprint' and not self.debuff then
                local add_min = (self.ability.extra and self.ability.extra.plus_min) or center.config.extra.plus_min
                local add_max = (self.ability.extra and self.ability.extra.plus_max) or center.config.extra.plus_max
                local x_min = (self.ability.extra and self.ability.extra.x_min) or center.config.extra.x_min
                local x_max = (self.ability.extra and self.ability.extra.x_max) or center.config.extra.x_max
                if context and context.joker_main then
                    local plus_mult = pseudorandom('misprint_plus', add_min, add_max)
                    local hand_id = (rawget(_G,'G') and G.GAME and G.GAME.hands_played) or 0
                    self.ability._vp_misprint_plus_last = {hand = hand_id, plus = plus_mult}
                    if context.blueprint and context.blueprint_card then
                        local seed_key = 'misprint_x_bp_'..tostring(context.blueprint or 0)..'_'..tostring(context.blueprint_card)
                        local x_bp = pr_float(seed_key, x_min, x_max)
                        x_bp = math.floor(x_bp * 100 + 0.5) / 100
                        context.blueprint_card.ability = context.blueprint_card.ability or {}
                        context.blueprint_card.ability._vp_misprint_pending_x = x_bp
                        return { message = localize{type='variable', key='a_mult', vars={plus_mult}}, mult_mod = plus_mult }
                    else
                        local h_played = (rawget(_G,'G') and G.GAME and G.GAME.hands_played) or 0
                        local seed_key = 'misprint_x_orig_'..tostring(self)..'_'..tostring(h_played)
                        local x_orig = pr_float(seed_key, x_min, x_max)
                        x_orig = math.floor(x_orig * 100 + 0.5) / 100
                        self.ability._vp_misprint_pending_x = x_orig
                        return { message = localize{type='variable', key='a_mult', vars={plus_mult}}, mult_mod = plus_mult }
                    end
                end
            end
            return old_card_calc(self, context)
        end
        _G.VP_MISPRINT_CALC_PATCHED = true
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_misprint then
        G.localization.descriptions.Joker.j_misprint.text = center.loc_txt.text
    end

    local orig_set_ability = center.set_ability
    center.set_ability = function(self, card, initial, delay_sprites)
        if orig_set_ability then orig_set_ability(self, card, initial, delay_sprites) end
        card.ability = card.ability or {}
        card.ability.extra = card.ability.extra or {}
        card.ability.extra.plus_min = center.config.extra.plus_min
        card.ability.extra.plus_max = center.config.extra.plus_max
        card.ability.extra.x_min = center.config.extra.x_min
        card.ability.extra.x_max = center.config.extra.x_max
    end

    if not rawget(_G,'VP_MISPRINT_UI_PATCHED') and rawget(_G,'Card') then
        local old_generate = Card.generate_UIBox_ability_table
        function Card:generate_UIBox_ability_table()
            local t = old_generate(self)
            if self and self.ability and self.ability.set == 'Joker' and self.ability.name == 'Misprint' and t and type(t) == 'table' and t.main then
                if self.debuff then return t end
                if self.ability and self.ability.extra then
                    self.ability.extra.min = (self.ability.extra.plus_min or center.config.extra.plus_min)
                    self.ability.extra.max = (self.ability.extra.plus_max or center.config.extra.plus_max)
                end
                local x_min = (self.ability.extra and self.ability.extra.x_min) or center.config.extra.x_min
                local x_max = (self.ability.extra and self.ability.extra.x_max) or center.config.extra.x_max
                local steps = math.max(1, math.floor((x_max - x_min) * 100))
                local r_x = {}
                for s = 0, steps do
                    local v = x_min + (x_max - x_min) * (s/steps)
                    r_x[#r_x+1] = ('%.2f'):format(v)
                end
                local loc_mult = ' '..(localize('k_mult'))..' '
                local extra_nodes = {
                    {n=G.UIT.R, config={}},
                    {n=G.UIT.T, config={text = '  X', colour = G.C.XMULT, scale = 0.32}},
                    {n=G.UIT.O, config={object = DynaText({string = r_x, colours = {G.C.RED}, pop_in_rate = 9999999, silent = true, random_element = true, pop_delay = 0.5, scale = 0.32, min_cycle_time = 0})}},
                    {n=G.UIT.O, config={object = DynaText({string = {
                        {string = 'rand()', colour = G.C.JOKER_GREY},
                        {string = "#@"..(G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.id or 11)..(G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.suit:sub(1,1) or 'D'), colour = G.C.RED},
                        loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult
                    }, colours = {G.C.UI.TEXT_DARK}, pop_in_rate = 9999999, silent = true, random_element = true, pop_delay = 0.2011, scale = 0.32, min_cycle_time = 0})}},
                }
                t.main[#t.main+1] = extra_nodes
            end
            return t
        end
        _G.VP_MISPRINT_UI_PATCHED = true
    end
end