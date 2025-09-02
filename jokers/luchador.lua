return function(center)

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Luchador'
    center.loc_txt.text = {
        'Sell this card to disable ',
        'the current {C:attention}Boss Blind{} and',
        'reduce required round score by {C:attention}10%{}'
    }

    center.loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end


    if rawget(_G, 'Card') and Card.calculate_joker then
        local current_impl = Card.calculate_joker
        if (not _G.VP_LUCHADOR_PATCHED_FUNC) or (_G.VP_LUCHADOR_PATCHED_FUNC ~= current_impl) then
            function Card:calculate_joker(context)
                if self and self.ability and self.ability.name == 'Luchador' and context and context.selling_self then
                    local game = rawget(_G, 'G') and G or nil
                    local blind = (game and game.GAME and game.GAME.blind) or nil
                    local is_boss = false
                    if blind then
                        if blind.boss == true then
                            is_boss = true
                        elseif blind.get_type then
                            is_boss = (blind:get_type() == 'Boss')
                        else
                            local mt = getmetatable(blind)
                            if mt and mt.get_type then
                                is_boss = (mt.get_type(blind) == 'Boss')
                            end
                        end
                    end

                    if is_boss and blind then
                        local before = blind.chips or 0
                        local reduced = math.max(0, math.floor(before * 0.9))
                        if reduced < before then
                            blind.chips = reduced
                            blind.chip_text = number_format(blind.chips)
                            if game and game.HUD_blind then
                                local hud = game.HUD_blind:get_UIE_by_ID('HUD_blind_count')
                                if hud and hud.config and hud.config.object and hud.config.object.pop_in then
                                    hud:juice_up()
                                end
                            end
                        end

                        if not blind.disabled then
                            if rawget(_G, 'card_eval_status_text') then
                                card_eval_status_text(context.blueprint_card or self, 'extra', nil, nil, nil, {message = localize('ph_boss_disabled')})
                            end
                            if blind.disable then blind:disable() end
                        end
                        return
                    end

                    return
                end
                return current_impl(self, context)
            end
            _G.VP_LUCHADOR_PATCHED_FUNC = Card.calculate_joker
        end
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_luchador then
        G.localization.descriptions.Joker.j_luchador.text = center.loc_txt.text
    end
end