return function(center)
    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Ankh'
    center.loc_txt.text = {
        'Create a copy of a',
        'random {C:attention}Joker{}, destroy',
        'a random {C:attention}Joker{}',
        '{C:inactive}(Removes {C:dark_edition}Negative{} {C:inactive}from copy){}'
    }

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Spectral and G.localization.descriptions.Spectral.c_ankh then
        G.localization.descriptions.Spectral.c_ankh.text = center.loc_txt.text
    end

    if rawget(_G, 'Card') and Card.use_consumeable then
        local current_impl = Card.use_consumeable
        if (not _G.VR_ANKH_PATCHED_USE) or (_G.VR_ANKH_PATCHED_USE ~= current_impl) then
            function Card:use_consumeable(area, copier)
                local is_ankh = self and self.ability and (self.ability.name == 'Ankh')
                local original_name
                if is_ankh then
                    original_name = self.ability.name
                    self.ability.name = '_Ankh_VR'
                end

                local ret = current_impl(self, area, copier)

                if is_ankh and rawget(_G,'G') and G.jokers then
                    self.ability.name = original_name

                    local chosen_joker = (#G.jokers.cards > 0) and pseudorandom_element(G.jokers.cards, pseudoseed('ankh_choice_vr')) or nil

                    local deletable = {}
                    for _, v in ipairs(G.jokers.cards) do
                        if not (v.ability and v.ability.eternal) then
                            deletable[#deletable+1] = v
                        end
                    end
                    local to_destroy = nil
                    if #deletable > 0 then
                        to_destroy = pseudorandom_element(deletable, pseudoseed('ankh_destroy_vr'))
                        if chosen_joker and to_destroy == chosen_joker and #deletable > 1 then
                            local pool = {}
                            for _, v in ipairs(deletable) do if v ~= chosen_joker then pool[#pool+1] = v end end
                            if #pool > 0 then to_destroy = pseudorandom_element(pool, pseudoseed('ankh_destroy_vr2')) end
                        end
                    end

                    if to_destroy then
                        G.E_MANAGER:add_event(Event({
                            trigger = 'before',
                            delay = 0.75,
                            func = function()
                                if to_destroy and to_destroy.area and to_destroy.area == G.jokers then
                                    to_destroy:start_dissolve(nil, true)
                                end
                                return true
                            end
                        }))
                    end

                    if chosen_joker then
                        G.E_MANAGER:add_event(Event({
                            trigger = 'before',
                            delay = 0.4,
                            func = function()
                                local card = copy_card(chosen_joker, nil, nil, nil, chosen_joker.edition and chosen_joker.edition.negative)
                                card:start_materialize()
                                card:add_to_deck()
                                if card.edition and card.edition.negative then
                                    card:set_edition(nil, true)
                                end
                                G.jokers:emplace(card)
                                return true
                            end
                        }))
                    end
                end

                return ret
            end
            _G.VR_ANKH_PATCHED_USE = Card.use_consumeable
        end
    end
end