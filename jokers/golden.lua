if not rawget(_G,'VP_GOLDEN_HELPERS') then
    function count_rare_legendary_jokers_golden()
        local count = 0
        if rawget(_G,'G') and G.jokers and G.jokers.cards then
            for i = 1, #G.jokers.cards do
                local joker = G.jokers.cards[i]
                if joker.config and joker.config.center and joker.config.center.rarity 
                   and joker.config.center.rarity >= 3 then
                    count = count + 1
                end
            end
        end
        return count
    end

    function get_current_payout_golden()
        local base_payout = 4
        local bonus_count = count_rare_legendary_jokers_golden()
        return base_payout + bonus_count * 2
    end
    
    _G.VP_GOLDEN_HELPERS = true
end

return function(center)
    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Golden Joker'
    center.loc_txt.text = {
        'Earn {C:money}$#1#{} at end of round',
        'Payout increases by {C:money}$2{}',
        'for each {C:red}rare{} or {C:legendary}legendary{} joker'
    }

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_golden then
        G.localization.descriptions.Joker.j_golden.text = center.loc_txt.text
    end

    if not rawget(_G,'VP_GOLDEN_PATCHED') and rawget(_G,'Card') and Card.calculate_dollar_bonus then
        local orig_calculate_dollar_bonus = Card.calculate_dollar_bonus
        
        Card.calculate_dollar_bonus = function(self)
            if self.debuff then return end
            if self.ability.set == "Joker" then
                if self.ability.name == 'Golden Joker' then
                    return get_current_payout_golden()
                end
            end

            return orig_calculate_dollar_bonus(self)
        end

        _G.VP_GOLDEN_PATCHED = true
    end

    if not rawget(_G,'VP_GOLDEN_UPDATE_PATCHED') and rawget(_G,'Card') and Card.update then
        local orig_update = Card.update
        
        Card.update = function(self, dt)
            if orig_update then orig_update(self, dt) end
            
            if self.ability and self.ability.name == 'Golden Joker' then
                self.ability.extra = get_current_payout_golden()
            end
        end
        
        _G.VP_GOLDEN_UPDATE_PATCHED = true
    end

    center.loc_vars = function(self, info_queue, card)
        local current_payout = get_current_payout_golden()
        return { vars = { current_payout } }
    end

    center.config = center.config or {}
    center.config.extra = 4
end