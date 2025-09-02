return function(center)

    center.config = center.config or {}
    center.config.extra = 1

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Delayed Gratification'
    center.loc_txt.text = {
        'Earn {C:red}$#1#{} for each discard',
        'remaining at the end of round',
        'Payout increases by {C:red}$1{}',
        'after round without discards',
        'Resets payout if discard has been used'
    }

    if not rawget(_G,'VP_DG_DOLLAR_PATCHED') and rawget(_G,'Card') and Card.calculate_dollar_bonus then
        local old_calc = Card.calculate_dollar_bonus
        function Card:calculate_dollar_bonus()
            if self.debuff then return end
            if self.ability.set == 'Joker' and self.ability.name == 'Delayed Gratification' then
                self.ability.extra = self.ability.extra or 1
                local discards_used = G.GAME.current_round.discards_used or 0
                local disc_left = G.GAME.current_round.discards_left or 0

                local payout_per = self.ability.extra or 1
                local should_upgrade = false
                
                if discards_used > 0 then
                    payout_per = 1
                    self.ability.extra = 1
                else
                    should_upgrade = true
                    self.ability.extra = payout_per + 1
                end

                if should_upgrade and not self.debuff then
                    if rawget(_G,'card_eval_status_text') then
                        card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize('k_upgrade_ex')})
                    end
                end

                if disc_left <= 0 then return nil end
                local total = payout_per * disc_left

                self.ability._dg_left = disc_left
                self.ability._dg_total = total

                return total
            end
            return old_calc(self)
        end
        _G.VP_DG_DOLLAR_PATCHED = true
    end

    if not rawget(_G,'VP_DG_UPDATE_PATCHED') and rawget(_G,'Card') and Card.update then
        local old_update = Card.update
        function Card:update(dt)
            if self.ability and self.ability.set == 'Joker' and self.ability.name == 'Delayed Gratification' and not self.debuff then
                local cur_used = G.GAME.current_round and G.GAME.current_round.discards_used or 0
                self.ability._last_used = self.ability._last_used or 0
                if cur_used > self.ability._last_used then
                    if self.ability.extra and self.ability.extra > 1 then
                        self.ability.extra = 1
                        self:juice_up(0.5,0.5)
                        if rawget(_G,'card_eval_status_text') then
                            card_eval_status_text(self, 'extra', nil, nil, nil, {message = 'Reset'})
                        end
                    end
                    self.ability._last_used = cur_used
                end
            end
            return old_update(self, dt)
        end
        _G.VP_DG_UPDATE_PATCHED = true
    end

    center.loc_vars = function(self, info_queue, card)
        local payout = (card and card.ability and card.ability.extra) or center.config.extra or 1
        local disc_left = (rawget(_G,'G') and G.GAME and G.GAME.current_round and (G.GAME.current_round.discards_left or 0)) or 0
        local total = payout * disc_left
        return { vars = { payout } }
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_delayed_grat then
        G.localization.descriptions.Joker.j_delayed_grat.text = center.loc_txt.text
    end
end