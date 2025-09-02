return function(center)

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Sixth Sense'
    center.loc_txt.text = {
        'For each {C:attention}6{} in your scoring hand,',
        '{C:green}#1# in 6{} chance to create a random',
        '{C:spectral}Spectral{} card',
        '{C:inactive}(one card per round){}'
    }
    center.blueprint_compat = true

    local function compute_loc_vars(info_queue, card)
        return { vars = { ''..(G.GAME and G.GAME.probabilities.normal or 1) } }
    end

    center.loc_vars = function(self, info_queue, card)
        return compute_loc_vars(info_queue, card)
    end

    local function create_spectral_safe(seed_tag)
        if not (G and G.consumeables) then return nil end
        if #G.consumeables.cards >= (G.consumeables.config.card_limit or 0) then return nil end
        local newc = create_card('Spectral', G.consumeables, nil, nil, true, nil, nil, seed_tag or 'six')
        if not newc then return nil end
        newc:add_to_deck()
        newc:start_materialize({G.C.SECONDARY_SET.Spectral}, true, 0.6)
        G.E_MANAGER:add_event(Event({
            trigger = 'after', delay = 0.05, func = function()
                if newc and newc.children and newc.children.particles then
                    newc.children.particles:fade(0.1)
                end
                return true
            end
        }))
        G.consumeables:emplace(newc)
        return newc
    end

    local function _get_source_joker(card, context)
        return (context and context.blueprint_card) or card
    end

    local function _current_round()
        return (G and G.GAME and G.GAME.round) or 0
    end

    local function _get_sixth_state_for(source_card)
        if not (G and G.GAME) then return nil end
        local cur_round = _current_round()
        if not G.GAME._vp_sixth_state or G.GAME._vp_sixth_state.round ~= cur_round then
            G.GAME._vp_sixth_state = { round = cur_round, by_id = {} }
        end
        local by_id = G.GAME._vp_sixth_state.by_id
        local id = (source_card and source_card.unique_val) or 0
        local st = by_id[id]
        if not st then
            st = { created = false }
            by_id[id] = st
        end
        return st
    end

    local function handle_individual_six(card, context)
        if not (context and context.individual and context.cardarea == G.play) then return nil end
        local scored = context.other_card
        if not (scored and scored.get_id and scored:get_id() == 6) then return nil end
        if scored.debuff then return nil end
        if not (G and G.consumeables and G.consumeables.cards and G.consumeables.config) then return nil end
        if #G.consumeables.cards >= (G.consumeables.config.card_limit or 0) then return nil end

        local source_card = _get_source_joker(card, context)
        local state = _get_sixth_state_for(source_card)
        if not state then return nil end
        if state.created then return nil end

        local hand_mark = tostring((G.GAME and G.GAME.round) or 0)..'_'..tostring((G.GAME and G.GAME.current_round and G.GAME.current_round.hands_played) or 0)
        local seed = 'sixth_sense_ind_'..hand_mark..'_'..tostring(scored.unique_val or 0)..'_'..tostring((source_card and source_card.unique_val) or 'src')
        local threshold = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal or 1) / 6
        if pseudorandom(pseudoseed(seed)) < threshold then
            state.created = true
            local extra_delay = 0.75
            return {
                extra = {
                    message = localize('k_plus_spectral'),
                    colour = G.C.SECONDARY_SET.Spectral,
                    delay = extra_delay,
                    func = function()
                        G.E_MANAGER:add_event(Event({
                            trigger = 'before',
                            delay = extra_delay*1.25,
                            func = function()
                                if #G.consumeables.cards >= (G.consumeables.config.card_limit or 0) then return true end
                                create_spectral_safe('six')
                                play_sound('tarot1')
                                return true
                            end
                        }))
                        return true
                    end
                },
                card = source_card
            }
        end
        return nil
    end

    if SMODS and SMODS.Joker then
        SMODS.Joker:take_ownership('sixth_sense', {
            no_mod_display = true,
            loc_txt = { name = center.loc_txt.name, text = center.loc_txt.text },
            loc_vars = function(self, info_queue, card) return compute_loc_vars(info_queue, card) end,
            calculate = function(self, card, context)
                local is_blueprint = context and context.blueprint
                local sliced = (context and (context.blueprint_card or card).getting_sliced)
                if not sliced then
                    local res = handle_individual_six(card, context)
                    if res then return res end
                end
                return nil
            end,
        })
    else
        if rawget(_G,'G') and G.localization and G.localization.descriptions
            and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_sixth_sense then
            G.localization.descriptions.Joker.j_sixth_sense.name = center.loc_txt.name
            G.localization.descriptions.Joker.j_sixth_sense.text = center.loc_txt.text
            G.localization.descriptions.Joker.j_sixth_sense.loc_vars = function(_self, info_queue, card)
                return compute_loc_vars(info_queue, card)
            end
        end
    end

    local function normalize_center_tags()
        if G.P_CENTERS and G.P_CENTERS.j_sixth_sense then
            G.P_CENTERS.j_sixth_sense.mod = nil
            G.P_CENTERS.j_sixth_sense.mod_id = nil
            G.P_CENTERS.j_sixth_sense.modded = false
            G.P_CENTERS.j_sixth_sense.discovered = true
            G.P_CENTERS.j_sixth_sense.blueprint_compat = true
        end
        if G.localization and G.localization.descriptions and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_sixth_sense then
            G.localization.descriptions.Joker.j_sixth_sense.name = center.loc_txt.name
            G.localization.descriptions.Joker.j_sixth_sense.text = center.loc_txt.text
            G.localization.descriptions.Joker.j_sixth_sense.loc_vars = function(_self, info_queue, card)
                return compute_loc_vars(info_queue, card)
            end
        end
    end

    if SMODS and SMODS.Hook then
        SMODS.Hook.add('post_game_init', function() normalize_center_tags() end)
    else
        if rawget(_G,'G') then normalize_center_tags() end
    end
end