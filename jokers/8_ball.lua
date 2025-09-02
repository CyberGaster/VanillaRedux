return function(center)
    
    center.config.extra = 0
    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = '8 Ball'
    center.loc_txt.text = {
        'For every {C:attention}8{} scored,',
        'a total of {C:green}8{} times,',
        'creates {C:green}2{} {C:tarot}tarot{} cards',
        '{C:inactive}(Must have room){}'
    }

    local original_calculate = center.calculate
    center.calculate = function(self, card, context)
        if not card.ability.vp_eights_count then
            card.ability.vp_eights_count = 0
        end
        if not card.ability.vp_total_triggers then
            card.ability.vp_total_triggers = 0
        end

        if context.individual and context.cardarea == G.play and context.other_card:get_id() == 8 and not context.other_card.debuff then
            if card.ability.vp_total_triggers < 8 then
                card.ability.vp_eights_count = card.ability.vp_eights_count + 1
                
                if card.ability.vp_eights_count >= 8 then
                    card.ability.vp_total_triggers = card.ability.vp_total_triggers + 1
                    card.ability.vp_eights_count = 0
                    return {
                        message = '8/8',
                        colour = G.C.CHIPS,
                        delay = 0.4,
                        func = function()
                            card_eval_status_text(card, 'extra', nil, nil, nil, {
                                message = '+2 Tarot',
                                colour = G.C.PURPLE
                            })
                            if #G.consumeables.cards <= G.consumeables.config.card_limit - 2 then
                                G.E_MANAGER:add_event(Event({
                                    trigger = 'after',
                                    delay = 0.4,
                                    func = function()
                                        for i = 1, 2 do
                                            local tarot = create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, '8ba')
                                            tarot:add_to_deck()
                                            G.consumeables:emplace(tarot)
                                        end
                                        play_sound('tarot1')
                                        return true
                                    end
                                }))
                            end
                            return true
                        end
                    }
                else
                    return {
                        message = card.ability.vp_eights_count .. '/8',
                        colour = G.C.CHIPS
                    }
                end
            end
        end
        
        if original_calculate then
            return original_calculate(self, card, context)
        end
        
        return nil
    end

    center.loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end

    center.set_ability = function(self, card, initial, delay_sprites)
        if card and card.ability then
            if not card.ability.vp_eights_count then
                card.ability.vp_eights_count = 0
            end
            if not card.ability.vp_total_triggers then
                card.ability.vp_total_triggers = 0
            end
        end
    end

    if rawget(_G, 'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_8_ball then
        G.localization.descriptions.Joker.j_8_ball.text = center.loc_txt.text
    end
end