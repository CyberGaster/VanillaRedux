return function(center)

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Ceremonial Dagger'
    center.loc_txt.text = {
        'When {C:attention}Blind{} is selected,',
        'destroy Joker to the right',
        'and permanently add {C:attention}quadruple',
        'its sell value to this {C:red}Mult',
        '{C:inactive}(Currently {C:mult}+#1#{}{C:inactive} Mult)'
    }

    if rawget(_G, 'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_ceremonial then
        G.localization.descriptions.Joker.j_ceremonial.text = center.loc_txt.text
    end

    center.loc_vars = function(self, info_queue, card)
        return { vars = { self.ability and self.ability.mult or 0 } }
    end

    if not rawget(_G, 'VP_CEREMONIAL_PATCHED') and rawget(_G, 'Card') and Card.update then
        local old_card_update = Card.update

        function Card:update(dt)
            old_card_update(self, dt)

            if self.ability and self.ability.name == 'Ceremonial Dagger' then
                self.ability._vp_prev_mult = self.ability._vp_prev_mult or self.ability.mult or 0
                local diff = (self.ability.mult or 0) - self.ability._vp_prev_mult

                if diff > 0 and diff % 2 == 0 then
                    if not self.ability._vp_quad_applied then
                        local extra = diff
                        self.ability.mult = (self.ability.mult or 0) + extra
                        self.ability._vp_quad_applied = true
                        self.ability._vp_prev_mult = self.ability.mult
                    end
                else
                    self.ability._vp_quad_applied = false
                    self.ability._vp_prev_mult = self.ability.mult or 0
                end
            end
        end

        _G.VP_CEREMONIAL_PATCHED = true
    end

    if not rawget(_G, 'VP_CEREMONIAL_TEXT_PATCHED') and rawget(_G, 'card_eval_status_text') then
        local _old_cest = card_eval_status_text

        function card_eval_status_text(card, tag, v1, v2, v3, opts)
            if card and card.ability and card.ability.name == 'Ceremonial Dagger' and opts and opts.message then
                local right_cost = nil
                if rawget(_G,'G') and G.jokers and card.area == G.jokers then
                    local my_pos
                    for i=1,#G.jokers.cards do
                        if G.jokers.cards[i] == card then my_pos = i; break end
                    end
                    local sliced = my_pos and G.jokers.cards[my_pos+1] or nil
                    if sliced and sliced.sell_cost then right_cost = sliced.sell_cost end
                end

                if right_cost then
                    opts.message = localize{type='variable', key='a_mult', vars={right_cost*4}}
                end
            end
            return _old_cest(card, tag, v1, v2, v3, opts)
        end

        _G.VP_CEREMONIAL_TEXT_PATCHED = true
    end
end