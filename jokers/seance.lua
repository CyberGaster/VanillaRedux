return function(center)
    
    if SMODS and SMODS.Joker then
        SMODS.Joker:take_ownership('seance', {
            no_mod_display = true,
            loc_txt = {
                name = 'Seance',
                text = {
                    'At the start of each round,',
                    'for each {C:tarot}Tarot{} or {C:planet}Planet{} you hold,',
                    '{C:green}#1# in 4{} chance to replace it with',
                    'a random {C:spectral}Spectral{} card'
                }
            },
            loc_vars = function(self, info_queue, card)
                return { vars = { ''..(G.GAME and G.GAME.probabilities.normal or 1) } }
            end,
        })
    end

    local function seance_do_replacements(source_card)
        local replaced = 0
        if not (G and G.consumeables and G.consumeables.cards) then return 0 end
        local threshold = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal or 1) / 4
        local to_check = {}
        for i = 1, #G.consumeables.cards do local c = G.consumeables.cards[i]; if c and c.ability and c.ability.set == 'Tarot' then to_check[#to_check+1] = c end end
        for i = 1, #G.consumeables.cards do local c = G.consumeables.cards[i]; if c and c.ability and c.ability.set == 'Planet' then to_check[#to_check+1] = c end end
        for idx, old in ipairs(to_check) do
            if old.area == G.consumeables and old.config and old.config.center and old.ability then
                local seed = 'seance_replace_'..tostring(old.unique_val or idx)..'_'..tostring((source_card and source_card.unique_val) or 'src')
                if pseudorandom(pseudoseed(seed)) < threshold then
                    local had_negative = old.edition and old.edition.negative
                    if old.children and old.children.use_button then old.children.use_button:remove(); old.children.use_button = nil end
                    if old.children and old.children.sell_button then old.children.sell_button:remove(); old.children.sell_button = nil end
                    if old.area then old.area:remove_card(old) end
                    old:start_dissolve(nil, true, 0.6, true)
                    local newc = create_card('Spectral', G.consumeables, nil, nil, true, nil, nil, 'seance')
                    if had_negative then newc:set_edition({negative = true}) end
                    newc:add_to_deck()
                    newc:start_materialize({G.C.SECONDARY_SET.Spectral}, true, 0.6)
                    G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.05, func = function()
                        if newc and newc.children and newc.children.particles then newc.children.particles:fade(0.1) end
                        return true
                    end }))
                    G.consumeables:emplace(newc)
                    replaced = replaced + 1
                end
            end
        end
        if replaced > 0 then
            card_eval_status_text(source_card, 'extra', nil, nil, nil, { message = localize('k_plus_spectral'), colour = G.C.SECONDARY_SET.Spectral })
            play_sound('tarot1')
        end
        return replaced
    end

    if not rawget(_G,'VR_PATCHED_SEANCE') and rawget(_G,'Card') and Card.calculate_joker then
        _G.VR_PATCHED_SEANCE = true
        local base_calculate_joker = Card.calculate_joker
        function Card:calculate_joker(context)
            if self.ability and self.ability.name == 'Seance' and not self.debuff then
                local is_blueprint = context and context.blueprint
                local sliced = (context and (context.blueprint_card or self).getting_sliced)
                if context and context.setting_blind and not sliced then
                    local source = (is_blueprint and context.blueprint_card) or self
                    G.GAME._vp_seance = G.GAME._vp_seance or { _last_round = -1 }
                    local round_id = (G.GAME and G.GAME.round) or 0
                    local key = 'start_' .. round_id .. '_' .. (source.unique_val or 0)
                    if G.GAME._vp_seance._last_round ~= round_id then G.GAME._vp_seance = { _last_round = round_id } end
                    if not G.GAME._vp_seance[key] then
                        G.GAME._vp_seance[key] = true
                        G.E_MANAGER:add_event(Event({ func = function() seance_do_replacements(source); return true end }))
                    end
                    return
                end
                return nil
            end
            return base_calculate_joker(self, context)
        end
    end

    if SMODS and SMODS.Hook then
        SMODS.Hook.add('post_game_init', function()
            if G.P_CENTERS and G.P_CENTERS.j_seance then
                G.P_CENTERS.j_seance.mod = nil
                G.P_CENTERS.j_seance.mod_id = nil
                G.P_CENTERS.j_seance.modded = false
                G.P_CENTERS.j_seance.discovered = true
            end
        end)
    else
        if G.P_CENTERS and G.P_CENTERS.j_seance then
            G.P_CENTERS.j_seance.mod = nil
            G.P_CENTERS.j_seance.mod_id = nil
            G.P_CENTERS.j_seance.modded = false
            G.P_CENTERS.j_seance.discovered = true
        end
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_seance then
        G.localization.descriptions.Joker.j_seance.text = {
            'At the start of each round, for each',
            '{C:tarot}Tarot{} or {C:planet}Planet{} you hold,',
            '{C:green}#1# in 4{} chance to replace it with a',
            'random {C:spectral}Spectral{} card'
        }
    end
end