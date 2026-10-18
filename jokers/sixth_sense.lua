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

local function get_sixth_state(source_card)
    if not (G and G.GAME) then return nil end
    local cur_round = G.GAME.round or 0
    if not G.GAME._vp_sixth_state or G.GAME._vp_sixth_state.round ~= cur_round then
        G.GAME._vp_sixth_state = { round = cur_round, by_id = {} }
    end
    local id = (source_card and source_card.unique_val) or 0
    local st = G.GAME._vp_sixth_state.by_id[id]
    if not st then
        st = { created = false }
        G.GAME._vp_sixth_state.by_id[id] = st
    end
    return st
end

local vr_sixth_start_run = Game.start_run
function Game:start_run(args)
    vr_sixth_start_run(self, args)
    if Cartomancer and Cartomancer.juice_joker_before_hand and not Cartomancer.vr_sixth_patched then
        local orig_juice = Cartomancer.juice_joker_before_hand
        Cartomancer.juice_joker_before_hand = function(joker)
            if joker and joker.config and joker.config.center and joker.config.center.key == 'j_sixth_sense' then
                return false
            end
            return orig_juice(joker)
        end
        Cartomancer.vr_sixth_patched = true
    end
end

SMODS.Joker:take_ownership('sixth_sense', {
    loc_txt = {
        name = 'Sixth Sense',
        text = {
            'For each {C:attention}6{} in your scoring hand,',
            '{C:green}#1# in 6{} chance to create',
            'a random {C:spectral}Spectral{} card',
            '{C:inactive}(Must have room)',
            '{C:inactive}(one card per round){}'
        }
    },
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { ''..(G.GAME and G.GAME.probabilities.normal or 1) } }
    end,
    calculate = function(self, card, context)
        if context.destroying_card then
            return {}
        end
        if context.individual and context.cardarea == G.play and context.other_card and not context.other_card.debuff then
            if context.other_card:get_id() ~= 6 then return {} end
            if not (G.consumeables and G.consumeables.cards and G.consumeables.config) then return {} end
            if #G.consumeables.cards >= (G.consumeables.config.card_limit or 0) then return {} end

            local source = (context.blueprint and context.blueprint_card) or card
            local state = get_sixth_state(source)
            if not state or state.created then return {} end

            local hand_mark = tostring(G.GAME.round or 0)..'_'..tostring((G.GAME.current_round and G.GAME.current_round.hands_played) or 0)
            local seed = 'sixth_sense_ind_'..hand_mark..'_'..tostring(context.other_card.unique_val or 0)..'_'..tostring(source.unique_val or 'src')
            local threshold = (G.GAME.probabilities.normal or 1) / 6
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
                                delay = extra_delay * 1.25,
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
                    card = source
                }
            end
            return {}
        end
    end,
})