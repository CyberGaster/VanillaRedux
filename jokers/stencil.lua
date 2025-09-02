return function(center)

    local function count_negative_jokers()
        local count = 0
        if G.jokers and G.jokers.cards then
            for i = 1, #G.jokers.cards do
                local card = G.jokers.cards[i]
                if card and card.edition and card.edition.negative then
                    count = count + 1
                end
            end
        end
        return count
    end

    center.config = center.config or {}
    center.config.x_mult = 1
    
    local orig_set_ability = center.set_ability
    center.set_ability = function(self, card, initial, delay_sprites)
        if orig_set_ability then orig_set_ability(self, card, initial, delay_sprites) end
        card.ability = card.ability or {}
        card.ability.x_mult = 1
    end
    
    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Joker Stencil'
    center.loc_txt.text = {
        '{X:red,C:white} X1 {} Mult for each',
        '{C:dark_edition}Negative{} Joker',
        '{s:0.8}Joker Stencil included',
        '{C:inactive}(Currently {X:red,C:white} X#1# {C:inactive})'
    }

    local orig_calc = center.calculate
    center.calculate = function(self, card, context)
        if context and context.joker_main then
            local negative_count = count_negative_jokers()
            card.ability = card.ability or {}
            card.ability.x_mult = negative_count + 1
            
            if card.ability.x_mult > 1 then
                return {
                    message = localize{type='variable', key='a_xmult', vars={card.ability.x_mult}},
                    Xmult_mod = card.ability.x_mult
                }
            else
                return {
                    Xmult_mod = 1
                }
            end
        end
        return orig_calc and orig_calc(self, card, context) or nil
    end

    local orig_update = center.update
    center.update = function(self, card, dt)
        if orig_update then orig_update(self, card, dt) end
        if card and card.ability then
            if card.ability.x_mult == nil then
                card.ability.x_mult = 1
            end
            local new_count = count_negative_jokers()
            card.ability.x_mult = new_count + 1
        end
    end

    center.loc_vars = function(self, info_queue, card)
        local negative_count = count_negative_jokers()
        return { vars = { negative_count + 1 } }
    end

    if not rawget(_G,'VP_STENCIL_PATCHED') and rawget(_G,'Card') and Card.update then
        local old_card_update = Card.update
        function Card:update(dt)
            old_card_update(self, dt)
            if self.ability and self.ability.name == 'Joker Stencil' then
                if self.ability.x_mult == nil then
                    self.ability.x_mult = 1
                end
                local negative_count = 0
                if G.jokers and G.jokers.cards then
                    for i = 1, #G.jokers.cards do
                        local joker_card = G.jokers.cards[i]
                        if joker_card and joker_card.edition and joker_card.edition.negative then
                            negative_count = negative_count + 1
                        end
                    end
                end
                self.ability.x_mult = negative_count + 1
            end
        end
        _G.VP_STENCIL_PATCHED = true
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_stencil then
        G.localization.descriptions.Joker.j_stencil.text = center.loc_txt.text
    end
end