return function(center)

    local function current_mult()
        local ante = (rawget(_G,'G') and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante) or 1
        return 2 ^ ante
    end

    center.config = center.config or {}
    center.config.mult = 2

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Joker'
    center.loc_txt.text = {
        '{C:mult}+#1#{} Mult',
        'Doubles its value after',
        'each completed {C:attention}Ante{}'
    }

    local orig_calc = center.calculate
    center.calculate = function(self, card, context)
        if context and context.joker_main then
            card.ability = card.ability or {}
            local m = card.ability.mult or 2
            return {
                mult_mod = m,
                message = localize{type='variable', key='a_mult', vars={m}}
            }
        end
        return orig_calc and orig_calc(self, card, context) or nil
    end

    local orig_update = center.update
    center.update = function(self, card, dt)
        if orig_update then orig_update(self, card, dt) end
        if card and card.ability then
            local ante = (rawget(_G,'G') and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante) or 1
            if card.ability._vp_prev_ante == nil then
                card.ability._vp_prev_ante = ante
                card.ability.mult = card.ability.mult or 2
            end
            if ante > card.ability._vp_prev_ante then
                local diff = ante - card.ability._vp_prev_ante
                card.ability.mult = (card.ability.mult or 2) * (2 ^ diff)
                card.ability._vp_prev_ante = ante
                card:juice_up(0.8,0.8)
                if rawget(_G,'card_eval_status_text') then
                    card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_upgrade_ex')})
                end
            elseif ante < card.ability._vp_prev_ante then
                card.ability._vp_prev_ante = ante
            end
        end
    end

    if not rawget(_G,'VP_BASEJOKER_PATCHED') and rawget(_G,'Card') and Card.update then
        local old_card_update = Card.update
        function Card:update(dt)
            old_card_update(self, dt)
            if self.ability and self.ability.name == 'Joker' then
                local ante = (rawget(_G,'G') and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante) or 1
                if self.ability._vp_prev_ante == nil then
                    self.ability._vp_prev_ante = ante
                    self.ability.mult = self.ability.mult or 2
                end
                if ante > self.ability._vp_prev_ante then
                    local diff = ante - self.ability._vp_prev_ante
                    self.ability.mult = (self.ability.mult or 2) * (2 ^ diff)
                    self.ability._vp_prev_ante = ante
                elseif ante < self.ability._vp_prev_ante then
                    self.ability._vp_prev_ante = ante
                end
            end
        end
        _G.VP_BASEJOKER_PATCHED = true
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_joker then
        G.localization.descriptions.Joker.j_joker.text = center.loc_txt.text
    end
end