return function(center)

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Obelisk'
    center.loc_txt.text = {
        'This Joker gains {X:mult,C:white} X#1# {} Mult',
        'per hand played without playing your',
        'most played {C:attention}poker hand',
        '{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)',
    }

    center.config = center.config or {}
    center.config.extra = 0.05
    center.config.Xmult = center.config.Xmult or 1

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_obelisk then
        G.localization.descriptions.Joker.j_obelisk.text = center.loc_txt.text
    end

    if rawget(_G, 'Card') and Card.calculate_joker then
        local current_impl = Card.calculate_joker
        if (not _G.VP_OBELISK_PATCHED_FUNC) or (_G.VP_OBELISK_PATCHED_FUNC ~= current_impl) then
            function Card:calculate_joker(context)
                if self and self.ability and self.ability.name == 'Obelisk' and context and not context.blueprint and not self.debuff and context.cardarea == (rawget(_G,'G') and G.jokers) and context.before then
                    if context.scoring_name then
                        local play_more_than = (rawget(_G,'G') and G.GAME and G.GAME.hands and G.GAME.hands[context.scoring_name] and G.GAME.hands[context.scoring_name].played) or 0
                        local should_increment = false
                        if rawget(_G,'G') and G.GAME and G.GAME.hands then
                            for k, v in pairs(G.GAME.hands) do
                                if k ~= context.scoring_name and v.visible and (v.played >= play_more_than) then
                                    should_increment = true
                                    break
                                end
                            end
                        end
                        if should_increment then
                            self.ability.x_mult = (self.ability.x_mult or 1)
                            self.ability.extra = 0.05
                            self.ability.x_mult = self.ability.x_mult + 0.05
                        end
                        local prev_blueprint = context.blueprint
                        context.blueprint = true
                        local res = current_impl(self, context)
                        context.blueprint = prev_blueprint
                        return res
                    end
                end
                return current_impl(self, context)
            end
            _G.VP_OBELISK_PATCHED_FUNC = Card.calculate_joker
        end
    end

    center.loc_vars = function(self, info_queue, card)
        local step = 0.05
        local cur_x = (card and card.ability and card.ability.x_mult) or (center.config and center.config.Xmult) or 1
        return { vars = { step, cur_x } }
    end

    local orig_set_ability = center.set_ability
    center.set_ability = function(self, card, initial, delay_sprites)
        if orig_set_ability then orig_set_ability(self, card, initial, delay_sprites) end
        card.ability = card.ability or {}
        if card.ability.x_mult == nil then card.ability.x_mult = center.config.Xmult or 1 end
        card.ability.extra = 0.05
    end

end