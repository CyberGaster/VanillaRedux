return function(center)

    local function get_three_kind_level()
        if rawget(_G,'G') and G.GAME and G.GAME.hands and G.GAME.hands['Three of a Kind'] then
            return G.GAME.hands['Three of a Kind'].level or 1
        end
        return 1
    end

    local function compute_level_bonus()
        local level = get_three_kind_level()
        return 3 * math.max(0, level - 1)
    end

    center.config = center.config or {}
    center.config.t_mult = 0
    center.config.extra = compute_level_bonus()

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Zany Joker'
    center.loc_txt.text = {
        '{C:mult}+12{} Mult if played',
        'hand contains a {C:attention}Three of a Kind{}',
        '{C:mult}+3{} mult for each level',
        'of the {C:attention}Three of a Kind{} poker hand',
        '{C:inactive}(Currently {C:mult}+#1#{} {C:inactive}Mult)'
    }

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_zany then
        G.localization.descriptions.Joker.j_zany.text = center.loc_txt.text
    end

    center.calculate = function(self, card, context)
        if card.ability.extra == nil then
            card.ability.extra = compute_level_bonus()
        end

        card.ability.extra = compute_level_bonus()

        if context and context.joker_main then
            local has_three_kind = false
            if context.poker_hands and context.poker_hands['Three of a Kind'] and next(context.poker_hands['Three of a Kind']) then
                has_three_kind = true
            end

            if has_three_kind then
                local base_mult = 12
                local level_bonus = card.ability.extra
                local total_mult = base_mult + level_bonus
                
                return {
                    mult_mod = total_mult,
                    message = localize{type='variable', key='a_mult', vars={total_mult}}
                }
            end
        end
        
        return nil
    end

    center.loc_vars = function(self, info_queue, card)
        local three_kind_level = 1
        if rawget(_G,'G') and G.GAME and G.GAME.hands and G.GAME.hands['Three of a Kind'] then
            three_kind_level = G.GAME.hands['Three of a Kind'].level or 1
        end
        
        local level_bonus = 3 * math.max(0, three_kind_level - 1)
        local total_mult = 12 + level_bonus
        
        if card and card.ability then
            card.ability.extra = level_bonus
        end
        
        return { vars = { total_mult } }
    end

    center.set_ability = function(self, card, initial, delay_sprites)
        card.ability.extra = compute_level_bonus()
    end

    local orig_update = center.update
    center.update = function(self, card, dt)
        if orig_update then orig_update(self, card, dt) end
        if card and card.ability then
            local new_level_bonus = compute_level_bonus()
            if card.ability.extra ~= new_level_bonus then
                card.ability.extra = new_level_bonus
                if card.set_sprites and card.config and card.config.center then
                    card:set_sprites(card.config.center)
                end
            end
            card.ability.t_mult = 12 + (card.ability.extra or 0)
        end
    end

    if not rawget(_G,'VP_ZANY_PATCHED') and rawget(_G,'Card') and Card.update then
        local old_card_update = Card.update
        function Card:update(dt)
            old_card_update(self, dt)
            if self.config and self.config.center and self.config.center.key == 'j_zany' and self.ability then
                local level_bonus = compute_level_bonus()
                self.ability.extra = level_bonus
                self.ability.t_mult = 12 + level_bonus
            end
        end
        _G.VP_ZANY_PATCHED = true
    end

    if not rawget(_G,'VP_ZANY_CALC_PATCHED') and rawget(_G,'Card') and Card.calculate_joker then
        local old_calculate_joker = Card.calculate_joker
        function Card:calculate_joker(context)
            if self.config and self.config.center and self.config.center.key == 'j_zany' and self.ability then
                local level_bonus = compute_level_bonus()
                self.ability.extra = level_bonus
                self.ability.t_mult = 12 + level_bonus
            end
            return old_calculate_joker(self, context)
        end
        _G.VP_ZANY_CALC_PATCHED = true
    end
end