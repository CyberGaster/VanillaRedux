return function(center)
    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'The Wheel of Fortune'
    center.loc_txt.text = {
        '{C:green}#1# in #2#{} chance to add',
        '{C:dark_edition}Foil{}, {C:dark_edition}Holographic{}, {C:dark_edition}Polychrome{},',
        'or {C:dark_edition}Negative{} edition to a random {C:attention}Joker',
    }

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Tarot and G.localization.descriptions.Tarot.c_wheel_of_fortune then
        G.localization.descriptions.Tarot.c_wheel_of_fortune.text = center.loc_txt.text
        if G.FUNCS and G.FUNCS.card_focus and type(G.FUNCS.card_focus) == 'function' then end
    end

    if rawget(_G, 'Card') and Card.use_consumeable then
        local current_impl = Card.use_consumeable
        if (not _G.VR_WHEEL_PATCHED_USE) or (_G.VR_WHEEL_PATCHED_USE ~= current_impl) then
            function Card:use_consumeable(area, copier)
                local is_wheel = self and self.ability and (self.ability.name == 'The Wheel of Fortune')
                local original_name
                if is_wheel then
                    original_name = self.ability.name
                    self.ability.name = '_Wheel_of_Fortune_VR'
                end

                local ret = current_impl(self, area, copier)

                if is_wheel and rawget(_G,'G') and G.jokers then
                    self.ability.name = original_name

                    local pool = self.eligible_strength_jokers
                    if not (pool and next(pool)) then
                        pool = {}
                        for _, v in ipairs(G.jokers.cards) do
                            if v.ability and v.ability.set == 'Joker' and (not v.edition) then
                                pool[#pool+1] = v
                            end
                        end
                    end

                    local roll_pass = pseudorandom('wheel_of_fortune') < (G.GAME.probabilities.normal / (self.ability and self.ability.extra or 4))
                    if next(pool) and roll_pass then
                        local target = pseudorandom_element(pool, pseudoseed('wheel_of_fortune'))

                        local r = pseudorandom('wheel_of_fortune_edition')
                        local edition
                        if r < 0.40 then
                            edition = {foil = true}
                        elseif r < 0.70 then
                            edition = {holo = true}
                        elseif r < 0.90 then
                            edition = {polychrome = true}
                        else
                            edition = {negative = true}
                        end

                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 0.4,
                            func = function()
                                if target then
                                    target:set_edition(edition, true)
                                    if check_for_unlock then check_for_unlock({type = 'have_edition'}) end
                                end
                                self:juice_up(0.3, 0.5)
                                return true
                            end
                        }))
                    else
                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 0.4,
                            func = function()
                                attention_text({
                                    text = localize('k_nope_ex'),
                                    scale = 1.3,
                                    hold = 1.4,
                                    major = self,
                                    backdrop_colour = G.C.SECONDARY_SET.Tarot,
                                    align = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and 'tm' or 'cm',
                                    offset = {x = 0, y = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and -0.2 or 0},
                                    silent = true
                                })
                                G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.06*G.SETTINGS.GAMESPEED, blockable = false, blocking = false, func = function()
                                    play_sound('tarot2', 0.76, 0.4);return true end}))
                                play_sound('tarot2', 1, 0.4)
                                self:juice_up(0.3, 0.5)
                                return true
                            end
                        }))
                    end
                    delay(0.6)
                end

                return ret
            end
            _G.VR_WHEEL_PATCHED_USE = Card.use_consumeable
        end
    end
end