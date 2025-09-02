return function(center)
    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Hex'
    center.loc_txt.text = {
        'Add {C:dark_edition}Polychrome{} to a',
        'random {C:attention}Joker{}, destroy',
        'a random {C:attention}Joker{}',
    }

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Spectral and G.localization.descriptions.Spectral.c_hex then
        G.localization.descriptions.Spectral.c_hex.text = center.loc_txt.text
    end

    if rawget(_G, 'Card') and Card.use_consumeable then
        local current_impl = Card.use_consumeable
        if (not _G.VR_HEX_PATCHED_USE) or (_G.VR_HEX_PATCHED_USE ~= current_impl) then
            function Card:use_consumeable(area, copier)
                local is_hex = self and self.ability and (self.ability.name == 'Hex')
                local original_name
                if is_hex then
                    original_name = self.ability.name
                    self.ability.name = '_Hex_VR'
                end

                local ret = current_impl(self, area, copier)

                if is_hex and rawget(_G,'G') and G.jokers then
                    self.ability.name = original_name

                    local pool = (self.eligible_editionless_jokers and next(self.eligible_editionless_jokers)) and self.eligible_editionless_jokers or {}
                    if not next(pool) then
                        for _, v in ipairs(G.jokers.cards) do
                            if not v.edition then pool[#pool+1] = v end
                        end
                    end
                    local target = next(pool) and pseudorandom_element(pool, pseudoseed('hex_vr_target')) or nil

                    local deletable = {}
                    for _, v in ipairs(G.jokers.cards) do
                        if not (v.ability and v.ability.eternal) then deletable[#deletable+1] = v end
                    end
                    local to_destroy = nil
                    if #deletable > 0 then
                        to_destroy = pseudorandom_element(deletable, pseudoseed('hex_vr_destroy'))
                        if target and to_destroy == target and #deletable > 1 then
                            local alt = {}
                            for _, v in ipairs(deletable) do if v ~= target then alt[#alt+1] = v end end
                            if #alt > 0 then to_destroy = pseudorandom_element(alt, pseudoseed('hex_vr_destroy2')) end
                        end
                    end

                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.4,
                        func = function()
                            if target then
                                target:set_edition({polychrome = true}, true)
                                if check_for_unlock then check_for_unlock({type = 'have_edition'}) end
                            end
                            if to_destroy and to_destroy.area == G.jokers then
                                to_destroy:start_dissolve(nil, true)
                            end
                            return true
                        end
                    }))
                end

                return ret
            end
            _G.VR_HEX_PATCHED_USE = Card.use_consumeable
        end
    end
end