return function(center)

    center.loc_txt = {
        name = 'Certificate',
        text = {
            'If {C:attention}first hand{} of round',
            'has only {C:attention}1{} card, add a',
            '{C:attention}random seal{} to it and',
            'return it to the {C:attention}deck{}'
        }
    }

    local function apply_random_seal_to_card(target_card)
        if not target_card or target_card.removed then return end
        local seal_roll = pseudorandom(pseudoseed('cert_seal'))
        if seal_roll > 0.75 then
            target_card:set_seal('Red', false, true)
        elseif seal_roll > 0.5 then
            target_card:set_seal('Blue', false, true)
        elseif seal_roll > 0.25 then
            target_card:set_seal('Gold', false, true)
        else
            target_card:set_seal('Purple', false, true)
        end
    end

    local function choose_random_seal()
        local r = pseudorandom(pseudoseed('cert_seal'))
        if r > 0.75 then return 'Red'
        elseif r > 0.5 then return 'Blue'
        elseif r > 0.25 then return 'Gold'
        else return 'Purple' end
    end

    if SMODS and SMODS.Joker then
        SMODS.Joker:take_ownership('j_certificate', {
            no_mod_display = true,
            loc_txt = center.loc_txt,
        })
    end

    if not rawget(_G, 'VP_CERTIFICATE_PATCHED') and rawget(_G, 'Card') and Card.calculate_joker then
        local old_calculate_joker = Card.calculate_joker
        function Card:calculate_joker(context)
            if self.ability and self.ability.name == 'Certificate' then
                if context and context.first_hand_drawn and not context.blueprint then
                    local eval = function() return G.GAME and G.GAME.current_round and G.GAME.current_round.hands_played == 0 end
                    juice_card_until(self, eval, true)
                    return nil
                end

                local function get_index(name)
                    if not (G and G.jokers and G.jokers.cards) then return nil end
                    for i = 1, #G.jokers.cards do
                        local j = G.jokers.cards[i]
                        if j and j.ability and j.ability.name == name then return i end
                    end
                end

                if context and context.before and context.cardarea == G.jokers and G.GAME and G.GAME.current_round
                   and G.GAME.current_round.hands_played == 0 and context.full_hand and #context.full_hand == 1 and not context.blueprint then
                    local cert_idx = get_index('Certificate')
                    local dna_idx = get_index('DNA')
                    local should_apply_now = (not dna_idx) or (cert_idx and dna_idx and cert_idx < dna_idx)
                    if should_apply_now then
                        local target = context.full_hand[1]
                        if target and (target.area == G.play) and not target.destroyed and not target.shattered and not target._vrx_cert_marked then
                            target._vrx_cert_marked = true
                            if not target:get_seal(true) then
                                local seal = choose_random_seal()
                                target:set_seal(seal, false, true)
                                play_sound('gold_seal', 1.2, 0.4)
                                self:juice_up(0.6, 0.6)
                            end
                        end
                    end
                end

                if context and context.joker_main and context.cardarea == G.jokers and G.GAME and G.GAME.current_round
                   and G.GAME.current_round.hands_played == 0 and context.full_hand and #context.full_hand == 1 and not context.blueprint then
                    local target = context.full_hand[1]
                    if target and (target.area == G.play) and not target.destroyed and not target.shattered and not target._vrx_cert_marked then
                        target._vrx_cert_marked = true
                        if not target:get_seal(true) then
                            local seal = choose_random_seal()
                            target:set_seal(seal, false, true)
                            play_sound('gold_seal', 1.2, 0.4)
                            self:juice_up(0.6, 0.6)
                        end
                    end
                end
            end
            return old_calculate_joker(self, context)
        end
        _G.VP_CERTIFICATE_PATCHED = true
    end

    if not rawget(_G, 'VP_CERTIFICATE_RETURN_PATCHED') and rawget(_G, 'G') and G.FUNCS and type(G.FUNCS.draw_from_play_to_discard) == 'function' then
        G.FUNCS.draw_from_play_to_discard = function(e)
            local play_count = #G.play.cards
            local it = 1
            local moved_to_deck = false
            for k, v in ipairs(G.play.cards) do
                if (not v.shattered) and (not v.destroyed) then
                    if v._vrx_cert_marked then
                        if v.facing == 'back' then v:flip() end
                        v.ability.wheel_flipped = nil
                        draw_card(G.play, G.deck, it*100/play_count, 'up', nil, v)
                        moved_to_deck = true
                        v._vrx_cert_marked = nil
                        it = it + 1
                    else
                        draw_card(G.play, G.discard, it*100/play_count, 'down', false, v)
                        it = it + 1
                    end
                end
            end
            if moved_to_deck then
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.05,
                    func = function()
                        local n = #G.deck.cards
                        if n > 1 and G.deck.cards[1] then
                            local j = math.random(n)
                            if j < 1 then j = 1 end
                            if SWAP then SWAP(G.deck.cards, 1, j) else G.deck.cards[1], G.deck.cards[j] = G.deck.cards[j], G.deck.cards[1] end
                            G.deck:set_ranks(); G.deck:align_cards()
                        end
                        return true
                    end
                }))
            end
        end
        _G.VP_CERTIFICATE_RETURN_PATCHED = true
    end

    local function normalize_center_tags()
        if G.P_CENTERS and G.P_CENTERS.j_certificate then
            G.P_CENTERS.j_certificate.mod = nil
            G.P_CENTERS.j_certificate.mod_id = nil
            G.P_CENTERS.j_certificate.modded = false
            G.P_CENTERS.j_certificate.discovered = true
            G.P_CENTERS.j_certificate.blueprint_compat = true
            G.P_CENTERS.j_certificate.perishable_compat = true
            G.P_CENTERS.j_certificate.eternal_compat = true
        end

        if G.localization and G.localization.descriptions and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_certificate then
            G.localization.descriptions.Joker.j_certificate.name = center.loc_txt.name
            G.localization.descriptions.Joker.j_certificate.text = center.loc_txt.text
        end
    end

    if SMODS and SMODS.Hook then
        SMODS.Hook.add('post_game_init', function() normalize_center_tags() end)
    else
        if rawget(_G, 'G') then normalize_center_tags() end
    end
end