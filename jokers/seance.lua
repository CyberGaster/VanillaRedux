local function seance_do_replacements(source_card)
    local replaced = 0
    if not (G and G.consumeables and G.consumeables.cards) then return 0 end
    local threshold = (G.GAME and G.GAME.probabilities and G.GAME.probabilities.normal or 1) / 4
    local to_check = {}
    for i = 1, #G.consumeables.cards do
        local c = G.consumeables.cards[i]
        if c and c.ability and (c.ability.set == 'Tarot' or c.ability.set == 'Planet') then
            to_check[#to_check+1] = c
        end
    end
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

SMODS.Joker:take_ownership('seance', {
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
    calculate = function(self, card, context)
        if context.setting_blind then
            local source = (context.blueprint and context.blueprint_card) or card
            G.GAME._vp_seance = G.GAME._vp_seance or { _last_round = -1 }
            local round_id = G.GAME.round or 0
            local key = 'start_' .. round_id .. '_' .. (source.unique_val or 0)
            if G.GAME._vp_seance._last_round ~= round_id then
                G.GAME._vp_seance = { _last_round = round_id }
            end
            if not G.GAME._vp_seance[key] then
                G.GAME._vp_seance[key] = true
                G.E_MANAGER:add_event(Event({ func = function() seance_do_replacements(source); return true end }))
            end
            return {}
        end
        if context.joker_main then
            return {}
        end
    end,
    blueprint_compat = true,
})