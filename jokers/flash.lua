return function(center)

    center.config = center.config or {}
    center.config.extra = { mult = 0, mult_gain = 10 }

    center.loc_txt = {
        name = 'Flash Card',
        text = {
            'Gains {C:mult}+10{} Mult at end of round if',
            '{C:attention}Blind{} is defeated in {C:attention}1{} {C:attention}hand{}',
            '{C:mult}+5{} Mult if defeated in {C:attention}2{} {C:attention}hands{}',
            '{C:inactive}(Currently {C:mult}+#2#{} {C:inactive}Mult)'
        }
    }

    center.loc_vars = function(self, info_queue, card)
        local accumulated = 0
        if card and card.ability and card.ability.extra and card.ability.extra.mult ~= nil then
            accumulated = tonumber(card.ability.extra.mult) or 0
        elseif self and self.extra and self.extra.mult ~= nil then
            accumulated = tonumber(self.extra.mult) or 0
        end
        return { vars = { accumulated } }
    end

    local original_set_ability = center.set_ability
    center.set_ability = function(self, card, initial, delay_sprites)
        if original_set_ability then original_set_ability(self, card, initial, delay_sprites) end
        card.ability = card.ability or {}
        card.ability.extra = card.ability.extra or {}
        card.ability.extra.mult = card.ability.extra.mult or 0
        card.ability.extra.mult_gain = card.ability.extra.mult_gain or 10
    end

    local orig_calculate = center.calculate
    center.calculate = function(self, card, context)
        card.ability = card.ability or {}
        card.ability.extra = card.ability.extra or { mult = 0, mult_gain = 10 }

        if context and context.joker_main then
            local accumulated = card.ability.extra.mult or 0
            if accumulated > 0 then
                return {
                    mult_mod = accumulated,
                    message = localize{type='variable', key='a_mult', vars={accumulated}}
                }
            end
        end

        if context and context.end_of_round and not context.individual and not context.repetition and not context.game_over then
            if not context.blueprint and not card.getting_sliced then
                local hands_played = (rawget(_G,'G') and G.GAME and G.GAME.current_round and G.GAME.current_round.hands_played) or 0
                local gain
                if hands_played == 1 then
                    gain = 10
                elseif hands_played == 2 then
                    gain = 5
                end
                if gain and gain > 0 then
                    card.ability.extra.mult = (card.ability.extra.mult or 0) + gain
                    if rawget(_G,'card_eval_status_text') then
                        card_eval_status_text(card, 'extra', nil, nil, nil, {
                            message = localize{type='variable', key='a_mult', vars={gain}},
                            colour = G.C.MULT
                        })
                    end
                end
            end
        end

        return orig_calculate and orig_calculate(self, card, context) or nil
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker then
        if G.localization.descriptions.Joker.j_flash then
            G.localization.descriptions.Joker.j_flash.text = center.loc_txt.text
            G.localization.descriptions.Joker.j_flash.loc_vars = function(_self, info_queue, card)
                local value = 0
                if card and card.ability and card.ability.extra and card.ability.extra.mult ~= nil then
                    value = tonumber(card.ability.extra.mult) or 0
                end
                return { vars = { value } }
            end
        end
    end

    if not rawget(_G,'VP_FLASH_LOCVARS_PATCHED') and rawget(_G,'Card') and Card.generate_UIBox_ability_table then
        local old_generate_UIBox = Card.generate_UIBox_ability_table
        function Card:generate_UIBox_ability_table()
            local is_flash = self and self.ability and (
                self.ability.name == 'Flash' or self.ability.name == 'Flash Card'
            )
            if not is_flash and self and self.config and self.config.center and self.config.center.key == 'j_flash' then
                is_flash = true
            end

            if is_flash then
                self.ability = self.ability or {}
                self.ability.extra = self.ability.extra or {}
                local current_mult = tonumber(self.ability.extra.mult or 0) or 0
                local current_gain = tonumber(self.ability.extra.mult_gain or 10) or 10

                local backup_extra = self.ability.extra
                local backup_mult = self.ability.mult
                self.ability.extra = current_gain
                self.ability.mult = current_mult

                local result = old_generate_UIBox(self)

                self.ability.extra = backup_extra
                self.ability.mult = backup_mult
                return result
            end
            return old_generate_UIBox(self)
        end
        _G.VP_FLASH_LOCVARS_PATCHED = true
    end
end