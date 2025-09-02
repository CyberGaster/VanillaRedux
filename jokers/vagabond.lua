return function(center)

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Vagabond'
    center.loc_txt.text = {
        'Create a {C:tarot}Tarot{}, {C:spectral}Spectral{},',
        'or {C:planet}Planet{} card if hand is played with',
        '{C:money}$#1#{} or less',
        '{C:inactive}(Must have room){}'
    }
    center.no_mod_display = true
    center.blueprint_compat = true
    center.config = center.config or {}
    center.config.extra = 2

    local function compute_loc_vars(info_queue, card)
        return { vars = { 2 } }
    end
    center.loc_vars = function(self, info_queue, card)
        return compute_loc_vars(info_queue, card)
    end

    local function normalize_center_tags()
        if rawget(_G,'G') and G.P_CENTERS and G.P_CENTERS.j_vagabond then
            local c = G.P_CENTERS.j_vagabond
            c.mod = nil; c.mod_id = nil; c.modded = false; c.discovered = true; c.no_mod_display = true
            c.blueprint_compat = true
            c.config = c.config or {}
            c.config.extra = 2
        end
        if rawget(_G,'G') and G.localization and G.localization.descriptions
            and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_vagabond then
            G.localization.descriptions.Joker.j_vagabond.text = center.loc_txt.text
            G.localization.descriptions.Joker.j_vagabond.loc_vars = function(_self, info_queue, card)
                return compute_loc_vars(info_queue, card)
            end
        end
    end

    local function vagabond_new_calculate(self, context)
        if not self or self.debuff then return nil end
        if self.ability then self.ability.extra = 2 end

        if not (context and context.joker_main) then
            return nil
        end
        if not (rawget(_G,'G') and G.consumeables and G.consumeables.cards and G.consumeables.config and G.GAME) then
            return nil
        end
        local current = (#G.consumeables.cards or 0) + (tonumber(G.GAME.consumeable_buffer) or 0)
        local limit = tonumber(G.consumeables.config.card_limit) or 0
        if current >= limit then return nil end

        local dollars = tonumber(G.GAME.dollars) or 0
        if dollars > 2 then return nil end

        G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
        local src = (context and context.blueprint_card) or self

        local round_id = (G and G.GAME and G.GAME.round) or 0
        local hand_idx = (G and G.GAME and G.GAME.current_round and G.GAME.current_round.hands_played) or 0
        local seed = 'vag_3way_'..tostring(round_id)..'_'..tostring(hand_idx)..'_'..tostring(src and src.unique_val or 0)
        local roll = pseudorandom(pseudoseed(seed))
        local chosen_kind = (roll < (1/3)) and 'Tarot' or ((roll < (2/3)) and 'Spectral' or 'Planet')

        G.E_MANAGER:add_event(Event({
            trigger = 'before',
            delay = 0.0,
            func = (function()
                if (#G.consumeables.cards or 0) >= (tonumber(G.consumeables.config.card_limit) or 0) then
                    G.GAME.consumeable_buffer = 0
                    return true
                end
                local newc
                if chosen_kind == 'Tarot' then
                    newc = create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, 'vag')
                elseif chosen_kind == 'Spectral' then
                    newc = create_card('Spectral', G.consumeables, nil, nil, true, nil, nil, 'vag')
                else
                    newc = create_card('Planet', G.consumeables, nil, nil, true, nil, nil, 'vag')
                end
                if newc then
                    newc:add_to_deck()
                    if chosen_kind == 'Spectral' then
                        newc:start_materialize({G.C.SECONDARY_SET.Spectral}, true, 0.6)
                        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.05, func = function()
                            if newc and newc.children and newc.children.particles then newc.children.particles:fade(0.1) end
                            return true
                        end }))
                    elseif chosen_kind == 'Planet' then
                        if G.C.SECONDARY_SET and G.C.SECONDARY_SET.Planet then
                            newc:start_materialize({G.C.SECONDARY_SET.Planet}, true, 0.6)
                        end
                        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.05, func = function()
                            if newc and newc.children and newc.children.particles then newc.children.particles:fade(0.1) end
                            return true
                        end }))
                    end
                    G.consumeables:emplace(newc)
                end
                G.GAME.consumeable_buffer = 0
                return true
            end)
        }))

        local msg_key = (chosen_kind == 'Tarot') and 'k_plus_tarot' or ((chosen_kind == 'Spectral') and 'k_plus_spectral' or 'k_plus_planet')
        local colour = (chosen_kind == 'Tarot') and ((G.C.SECONDARY_SET and G.C.SECONDARY_SET.Tarot) or G.C.PURPLE)
            or ((chosen_kind == 'Spectral') and ((G.C.SECONDARY_SET and G.C.SECONDARY_SET.Spectral) or G.C.PURPLE)
            or ((G.C.SECONDARY_SET and G.C.SECONDARY_SET.Planet) or G.C.PURPLE))
        return {
            message = localize(msg_key),
            colour = colour,
            card = src
        }
    end

    local function patch_calculate_for_vagabond()
        if rawget(_G,'VP_VAGABOND_CALC_PATCHED') then return end
        if rawget(_G,'Card') and Card.calculate_joker then
            local base_calculate = Card.calculate_joker
            function Card:calculate_joker(context)
                if self and self.ability and self.ability.name == 'Vagabond' then
                    local res = vagabond_new_calculate(self, context)
                    if res ~= nil then return res end
                end
                return base_calculate(self, context)
            end
            _G.VP_VAGABOND_CALC_PATCHED = true
        end
    end

    if SMODS and SMODS.Hook then
        SMODS.Hook.add('post_game_init', function()
            normalize_center_tags()
            patch_calculate_for_vagabond()
        end)
    else
        if rawget(_G,'G') then
            normalize_center_tags()
            patch_calculate_for_vagabond()
        end
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_vagabond then
        G.localization.descriptions.Joker.j_vagabond.text = center.loc_txt.text
        G.localization.descriptions.Joker.j_vagabond.loc_vars = function(_self, info_queue, card)
            return compute_loc_vars(info_queue, card)
        end
    end

end