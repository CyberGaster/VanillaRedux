return function(center)
    center.config = center.config or {}
    center.config.extra = 0.02

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Fortune Teller'
    center.loc_txt.text = {
        'Increases chance of a {C:tarot}Tarot{} card',
        'appearing in the shop',
        'Gains {X:mult,C:white}X#1#{} per {C:tarot}Tarot{} card used this run',
        '{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult){}',
    }

    local original_set_ability = center.set_ability
    center.set_ability = function(self, card, initial, delay_sprites)
        if original_set_ability then original_set_ability(self, card, initial, delay_sprites) end
        if card and card.ability then
            card.ability.extra = 0.02
        end
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_fortune_teller then
        G.localization.descriptions.Joker.j_fortune_teller.text = center.loc_txt.text
    end

    if not rawget(_G,'VR_FT_CALC_PATCHED') and rawget(_G,'Card') and Card.calculate_joker then
        local old_calculate_joker = Card.calculate_joker
        function Card:calculate_joker(context)
            if self.ability and self.ability.name == 'Fortune Teller' and not self.debuff then
                local gain = self.ability.extra or 0.02
                local used = (G.GAME and G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.tarot) or 0

                if context and context.joker_main then
                    local x = 1 + used * gain
                    if x > 1 then
                        return {
                            message = localize{type='variable', key='a_xmult', vars={x}},
                            Xmult_mod = x,
                        }
                    else
                        return nil
                    end
                end
                
                if context and context.using_consumeable and not context.blueprint
                   and context.consumeable and context.consumeable.ability
                   and context.consumeable.ability.set == 'Tarot' then
                    return nil
                end
            end
            return old_calculate_joker(self, context)
        end
        _G.VR_FT_CALC_PATCHED = true
    end

    if not rawget(_G,'VR_FT_SHOP_PATCHED') and rawget(_G,'create_card_for_shop') then
        local old_create_card_for_shop = create_card_for_shop
        function create_card_for_shop(area)
            local prev = G.GAME and G.GAME.tarot_rate or 4
            local has_ft = false
            if rawget(_G,'G') and G.jokers and G.jokers.cards then
                for i = 1, #G.jokers.cards do
                    local c = G.jokers.cards[i]
                    if c and c.ability and c.ability.name == 'Fortune Teller' and not c.debuff then
                        has_ft = true
                        break
                    end
                end
            end
            if has_ft and prev and prev > 0 then
                G.GAME.tarot_rate = prev + (prev * 0.5)
            end
            local result = old_create_card_for_shop(area)
            if has_ft then G.GAME.tarot_rate = prev end
            return result
        end
        _G.VR_FT_SHOP_PATCHED = true
    end

    if not rawget(_G,'VR_FT_LOCVARS_PATCHED') and rawget(_G,'Card') and Card.generate_UIBox_ability_table then
        local old_generate_UIBox = Card.generate_UIBox_ability_table
        function Card:generate_UIBox_ability_table()
            if self.ability and self.ability.name == 'Fortune Teller' then
                local gain = self.ability.extra or 0.02
                local used = (G.GAME and G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.tarot) or 0
                local x = 1 + used * gain

                local old_extra = self.ability.extra
                local had_usage_table = (G and G.GAME and G.GAME.consumeable_usage_total) and true or false
                local old_used = had_usage_table and G.GAME.consumeable_usage_total.tarot or nil
                local created_usage_table = false

                self.ability.extra = gain
                if G and G.GAME then
                    if not had_usage_table then
                        G.GAME.consumeable_usage_total = { tarot = x }
                        created_usage_table = true
                    else
                        G.GAME.consumeable_usage_total.tarot = x
                    end
                end

                local result = old_generate_UIBox(self)

                self.ability.extra = old_extra
                if G and G.GAME then
                    if created_usage_table then
                        G.GAME.consumeable_usage_total = nil
                    else
                        if had_usage_table then G.GAME.consumeable_usage_total.tarot = old_used end
                    end
                end
                return result
            end
            return old_generate_UIBox(self)
        end
        _G.VR_FT_LOCVARS_PATCHED = true
    end
end