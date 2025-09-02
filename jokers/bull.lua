return function(center)

    center.config = center.config or {}
    center.config.extra = center.config.extra or {}

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Bull'
    center.loc_txt.text = {
        '{C:chips}+#1#{} Chips for each {C:money}$1{} earned',
        '{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)'
    }

    center.loc_vars = function(self, info_queue, card)
        local current_chips = 0
        if card and card.ability then
            local c = card.ability._vp_bull_chips
            if type(c) == 'number' then current_chips = c end
        end
        return { vars = { 1, current_chips } }
    end

    local orig_set_ability = center.set_ability
    center.set_ability = function(self, card, initial, delay_sprites)
        if orig_set_ability then orig_set_ability(self, card, initial, delay_sprites) end
        card.ability = card.ability or {}
        if type(card.ability.extra) == 'table' then
            local stored = tonumber(card.ability.extra.chips) or 0
            if (not card.ability._vp_bull_chips) or card.ability._vp_bull_chips == 0 then
                card.ability._vp_bull_chips = stored
            end
            local default_extra = (self and self.config and type(self.config.extra) == 'number') and self.config.extra or 1
            card.ability.extra = default_extra
        end
        if card.ability._vp_bull_chips == nil then
            local persisted = (rawget(_G, 'G') and G.GAME and G.GAME.vp_bull_persist_chips) or 0
            card.ability._vp_bull_chips = persisted
        end
    end

    if not rawget(_G, 'VP_BULL_EASE_PATCHED') and rawget(_G, 'ease_dollars') then
        local original_ease_dollars = ease_dollars
        local function _bull_to_number(x)
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
        function ease_dollars(mod, instant)
            local mod_num = _bull_to_number(mod)
            if mod_num > 0 and rawget(_G, 'G') and G.jokers and G.jokers.cards then
                local selling_lock = G.CONTROLLER and G.CONTROLLER.locks and G.CONTROLLER.locks.selling_card
                if not selling_lock then
                    for i = 1, #G.jokers.cards do
                        local jk = G.jokers.cards[i]
                        if jk and jk.ability and jk.ability.name == 'Bull' and not jk.debuff then
                            jk.ability._vp_bull_chips = (jk.ability._vp_bull_chips or 0) + math.floor(mod_num)
                        end
                    end
                end
            end
            return original_ease_dollars(mod, instant)
        end
        _G.VP_BULL_EASE_PATCHED = true
    end

    if not rawget(_G, 'VP_BULL_CALC_PATCHED') and rawget(_G, 'Card') and Card.calculate_joker then
        local old_calculate_joker = Card.calculate_joker
        function Card:calculate_joker(context)
            if self.ability and self.ability.name == 'Bull' and not self.debuff then
                if context and context.selling_self then
                    if rawget(_G, 'G') then
                        G.GAME.vp_bull_persist_chips = (self.ability and self.ability._vp_bull_chips) or 0
                    end
                elseif context and context.cardarea == G.jokers then
                    if context.joker_main then
                        local chips = (self.ability and self.ability._vp_bull_chips) or 0
                        if chips > 0 then
                            return {
                                message = localize{type='variable', key='a_chips', vars={chips}} .. ' Chips',
                                chip_mod = chips,
                                colour = G.C.CHIPS,
                                card = self
                            }
                        else
                            return { chip_mod = 0 }
                        end
                    end
                end
            end
            return old_calculate_joker(self, context)
        end
        _G.VP_BULL_CALC_PATCHED = true
    end

    if not rawget(_G, 'VP_BULL_UI_PATCHED') and rawget(_G, 'Card') and Card.generate_UIBox_ability_table then
        local old_generate_UIBox = Card.generate_UIBox_ability_table
        function Card:generate_UIBox_ability_table()
            if self.ability and self.ability.set == 'Joker' and self.ability.name == 'Bull' then
                local chips = (self.ability and type(self.ability._vp_bull_chips) == 'number') and self.ability._vp_bull_chips or 0
                local saved_extra = self.ability.extra
                local saved_dollars = rawget(_G,'G') and G.GAME and G.GAME.dollars
                self.ability.extra = 1
                if rawget(_G,'G') and G.GAME then G.GAME.dollars = chips end
                local result = old_generate_UIBox(self)
                self.ability.extra = saved_extra
                if rawget(_G,'G') and G.GAME and saved_dollars ~= nil then G.GAME.dollars = saved_dollars end
                return result
            end
            return old_generate_UIBox(self)
        end
        _G.VP_BULL_UI_PATCHED = true
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_bull then
        G.localization.descriptions.Joker.j_bull.text = center.loc_txt.text
    end
end