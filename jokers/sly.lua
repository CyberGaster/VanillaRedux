return function(center)

    local function get_pair_level()
        if rawget(_G,'G') and G.GAME and G.GAME.hands and G.GAME.hands['Pair'] then
            return G.GAME.hands['Pair'].level or 1
        end
        return 1
    end

    local function compute_level_bonus()
        local level = get_pair_level()
        return 5 * math.max(0, level - 1)
    end

    center.config = center.config or {}
    center.config.t_chips = 0
    center.config.extra = compute_level_bonus()

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Sly Joker'
    center.loc_txt.text = {
        '{C:chips}+50{} Chips if played',
        'hand contains a {C:attention}Pair{}',
        '{C:chips}+5{} chips for each level',
        'of the {C:attention}Pair{} poker hand',
        '{C:inactive}(Currently {C:chips}+#1#{} {C:inactive}Chips)'
    }

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_sly then
        G.localization.descriptions.Joker.j_sly.text = center.loc_txt.text
    end

    center.calculate = function(self, card, context)
        if card.ability.extra == nil then
            card.ability.extra = compute_level_bonus()
        end

        card.ability.extra = compute_level_bonus()

        if context and context.joker_main then
            local has_pair = false
            if context.poker_hands and context.poker_hands['Pair'] and next(context.poker_hands['Pair']) then
                has_pair = true
            end

            if has_pair then
                local base_chips = 50
                local level_bonus = card.ability.extra
                local total_chips = base_chips + level_bonus
                
                return {
                    chip_mod = total_chips,
                    message = localize{type='variable', key='a_chips', vars={total_chips}}
                }
            end
        end
        
        return nil
    end

    center.loc_vars = function(self, info_queue, card)
        local pair_level = 1
        if rawget(_G,'G') and G.GAME and G.GAME.hands and G.GAME.hands['Pair'] then
            pair_level = G.GAME.hands['Pair'].level or 1
        end
        
        local level_bonus = 5 * math.max(0, pair_level - 1)
        local total_chips = 50 + level_bonus
        
        if card and card.ability then
            card.ability.extra = level_bonus
        end
        
        return { vars = { total_chips } }
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
            card.ability.t_chips = 50 + (card.ability.extra or 0)
        end
    end

    if not rawget(_G,'VP_SLY_PATCHED') and rawget(_G,'Card') and Card.update then
        local old_card_update = Card.update
        function Card:update(dt)
            old_card_update(self, dt)
            if self.config and self.config.center and self.config.center.key == 'j_sly' and self.ability then
                local level_bonus = compute_level_bonus()
                self.ability.extra = level_bonus
                self.ability.t_chips = 50 + level_bonus
            end
        end
        _G.VP_SLY_PATCHED = true
    end

    if not rawget(_G,'VP_SLY_CALC_PATCHED') and rawget(_G,'Card') and Card.calculate_joker then
        local old_calculate_joker = Card.calculate_joker
        function Card:calculate_joker(context)
            if self.config and self.config.center and self.config.center.key == 'j_sly' and self.ability then
                local level_bonus = compute_level_bonus()
                self.ability.extra = level_bonus
                self.ability.t_chips = 50 + level_bonus
            end
            return old_calculate_joker(self, context)
        end
        _G.VP_SLY_CALC_PATCHED = true
    end
end