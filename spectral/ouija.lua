return function(center)

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Ouija'
    center.loc_txt.text = {
        'Converts all cards',
        'in hand to a single',
        'random {C:attention}rank{}',
        '{C:red}-1{} hand size for',
        'next {C:attention}3{} rounds',
    }

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Spectral and G.localization.descriptions.Spectral.c_ouija then
        G.localization.descriptions.Spectral.c_ouija.text = center.loc_txt.text
    end

    if rawget(_G, 'Card') and Card.use_consumeable then
        local current_impl = Card.use_consumeable
        if (not _G.VP_OUIJA_PATCHED_USE) or (_G.VP_OUIJA_PATCHED_USE ~= current_impl) then
            function Card:use_consumeable(area, copier)
                local is_ouija = self and self.ability and (self.ability.name == 'Ouija')
                local ret = current_impl(self, area, copier)

                if is_ouija and rawget(_G,'G') then
                    if G and G.hand and G.hand.change_size then
                        G.hand:change_size(1)
                    end

                    G.GAME._vp_ouija_temp = G.GAME._vp_ouija_temp or { rounds_left = 0, applied_round = -1 }
                    G.GAME._vp_ouija_temp.rounds_left = (G.GAME._vp_ouija_temp.rounds_left or 0) + 3
                end

                return ret
            end
            _G.VP_OUIJA_PATCHED_USE = Card.use_consumeable
        end
    end

    if rawget(_G, 'Game') and Game.update_draw_to_hand then
        local orig_draw_to_hand = Game.update_draw_to_hand
        if (not _G.VP_OUIJA_PATCHED_DRAW_FUNC) or (_G.VP_OUIJA_PATCHED_DRAW_FUNC ~= orig_draw_to_hand) then
            function Game:update_draw_to_hand(dt)
                if rawget(_G,'G') and G.GAME and G.hand then
                    local mod = G.GAME._vp_ouija_temp
                    if mod and (mod.rounds_left or 0) > 0 then
                        local current_round = (G and G.GAME and G.GAME.round) or 0
                        if mod.applied_round ~= current_round then
                            G.hand:change_size(-1)
                            G.GAME.round_resets.temp_handsize = (G.GAME.round_resets.temp_handsize or 0) - 1
                            mod.applied_round = current_round
                            mod.rounds_left = mod.rounds_left - 1
                        end
                    end
                end

                return orig_draw_to_hand(self, dt)
            end
            _G.VP_OUIJA_PATCHED_DRAW_FUNC = Game.update_draw_to_hand
        end
    end

end