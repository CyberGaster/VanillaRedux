return function(center)

    center.config = center.config or {}
    center.config.extra = center.config.extra or {}

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Fibonacci'
    center.loc_txt.text = {
        'Played {C:attention}Ace{}, {C:attention}2{}, {C:attention}3{}, {C:attention}5{}, or {C:attention}8{}',
        'give {C:mult}+21{} Mult when scored'
    }

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_fibonacci then
        G.localization.descriptions.Joker.j_fibonacci.text = center.loc_txt.text
    end

    center.calculate = function(self, card, context)
        if context and context.individual and context.cardarea == G.play and context.other_card and not context.other_card.debuff then
            local cid = context.other_card.get_id and context.other_card:get_id()
            if cid == 14 or cid == 2 or cid == 3 or cid == 5 or cid == 8 then
                local src = (context.blueprint_card or card)
                src.ability = src.ability or {}
                local round_id = tostring((G and G.GAME and G.GAME.round) or 0)
                local hand_id = tostring((G and G.GAME and G.GAME.current_round and G.GAME.current_round.hands_played) or 0)
                local mark = round_id .. '_' .. hand_id
                if src.ability._vp_fib_mark ~= mark then
                    src.ability._vp_fib_mark = mark
                    src.ability._vp_fib_seen = {}
                end
                local seen = src.ability._vp_fib_seen or {}
                if not seen[cid] then
                    seen[cid] = true
                    src.ability._vp_fib_seen = seen
                    return {
                        mult = 21,
                        card = src,
                        no_popup = true
                    }
                end
            end
        end
        return nil
    end

    center.loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end

    if not rawget(_G,'VP_FIB_OVERRIDE') and rawget(_G,'Card') and Card.calculate_joker then
        local old_calculate_joker = Card.calculate_joker
        function Card:calculate_joker(context)
            if self.ability and self.ability.name == 'Fibonacci' and not self.debuff then
                if context and context.individual and context.cardarea == G.play and context.other_card and not context.other_card.debuff then
                    local cid = context.other_card.get_id and context.other_card:get_id()
                    if cid == 14 or cid == 2 or cid == 3 or cid == 5 or cid == 8 then
                        local src = (context.blueprint_card or self)
                        src.ability = src.ability or {}
                        local round_id = tostring((G and G.GAME and G.GAME.round) or 0)
                        local hand_id = tostring((G and G.GAME and G.GAME.current_round and G.GAME.current_round.hands_played) or 0)
                        local mark = round_id .. '_' .. hand_id
                        if src.ability._vp_fib_mark ~= mark then
                            src.ability._vp_fib_mark = mark
                            src.ability._vp_fib_seen = {}
                        end
                        local seen = src.ability._vp_fib_seen or {}
                        if not seen[cid] then
                            seen[cid] = true
                            src.ability._vp_fib_seen = seen
                            return {
                                mult = 21,
                                card = src,
                                no_popup = true
                            }
                        end
                        return nil
                    end
                end
                return nil
            end
            return old_calculate_joker(self, context)
        end
        _G.VP_FIB_OVERRIDE = true
    end
end