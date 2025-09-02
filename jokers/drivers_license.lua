return function(center)
    local STEP_PER_ENHANCED = 0.2

    local function count_enhanced_cards_in_full_deck()
        if not (rawget(_G, 'G') and G.playing_cards) then return 0 end
        local count = 0
        for _, v in pairs(G.playing_cards) do
            if v and v.ability and v.ability.set == 'Enhanced' then
                count = count + 1
            end
        end
        return count
    end

    center.cost = 9
    center.config = center.config or {}
    center.config.extra = STEP_PER_ENHANCED

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = "Driver's License"
    center.loc_txt.text = {
        'This Joker gains {X:mult,C:white}X#1#{} Mult',
        'for each {C:attention}Enhanced{} card',
        'in your full deck',
        '{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)'
    }

    center.loc_vars = function(self, info_queue, card)
        local step = (card and card.ability and card.ability.extra) or (self and self.config and self.config.extra) or STEP_PER_ENHANCED
        local enhanced_count = count_enhanced_cards_in_full_deck()
        local current_x = 1 + (enhanced_count * step)
        return { vars = { step, current_x } }
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_drivers_license then
        G.localization.descriptions.Joker.j_drivers_license.text = center.loc_txt.text
        G.localization.descriptions.Joker.j_drivers_license.loc_vars = function(_self, info_queue, card)
            local step = (card and card.ability and card.ability.extra) or (center and center.config and center.config.extra) or STEP_PER_ENHANCED
            local enhanced_count = count_enhanced_cards_in_full_deck()
            local current_x = 1 + (enhanced_count * step)
            return { vars = { step, current_x } }
        end
    end

    local orig_set_ability = center.set_ability
    center.set_ability = function(self, card, initial, delay_sprites)
        if orig_set_ability then orig_set_ability(self, card, initial, delay_sprites) end
        if card and card.ability then
            card.ability.extra = self.config and self.config.extra or STEP_PER_ENHANCED
        end
    end

    if not rawget(_G, 'VR_PATCHED_DRIVERS_LICENSE') and rawget(_G, 'Card') and Card.calculate_joker then
        _G.VR_PATCHED_DRIVERS_LICENSE = true
        local base_calculate_joker = Card.calculate_joker

        local function drivers_calculate(card, context)
            if not card or card.debuff then return nil end
            card.ability.extra = card.ability.extra or STEP_PER_ENHANCED
            if context and context.joker_main then
                local step = card.ability.extra or STEP_PER_ENHANCED
                local enhanced_count = count_enhanced_cards_in_full_deck()
                local x = 1 + (enhanced_count * step)
                if x and x > 1 then
                    return {
                        message = localize{type='variable', key='a_xmult', vars={x}},
                        Xmult_mod = x,
                        card = card
                    }
                end
            end
            return nil
        end

        function Card:calculate_joker(context)
            if self.ability and self.ability.name == "Driver's License" then
                return drivers_calculate(self, context) or base_calculate_joker(self, context)
            end
            return base_calculate_joker(self, context)
        end
    end

    if not rawget(_G, 'VR_DRIVERS_LICENSE_UPDATE') and rawget(_G, 'Card') and Card.update then
        _G.VR_DRIVERS_LICENSE_UPDATE = true
        local old_update = Card.update
        function Card:update(dt)
            old_update(self, dt)
            if self.ability and self.ability.name == "Driver's License" then
                local step = (self.ability and self.ability.extra) or STEP_PER_ENHANCED
                local enhanced_count = count_enhanced_cards_in_full_deck()
                self.ability.driver_tally = 1 + (enhanced_count * step)
            end
        end
    end
end