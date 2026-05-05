SMODS.Joker:take_ownership('8_ball', {
    loc_txt = {
        name = '8 Ball',
        text = {
            'For every {C:attention}8{} scored,',
            'a total of {C:green}8{} times,',
            'creates {C:green}2{} {C:tarot}tarot{} cards',
            '{C:inactive}(Must have room){}'
        }
    },
    config = { extra = { eights_count = 0, total_triggers = 0 } },
    set_ability = function(self, card, initial, delay_sprites)
        card.ability.extra = card.ability.extra or {}
        card.ability.extra.eights_count = card.ability.extra.eights_count or 0
        card.ability.extra.total_triggers = card.ability.extra.total_triggers or 0
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card:get_id() == 8
            and not context.other_card.debuff then

            if card.ability.extra.total_triggers < 8 then
                card.ability.extra.eights_count = card.ability.extra.eights_count + 1

                if card.ability.extra.eights_count >= 8 then
                    card.ability.extra.total_triggers = card.ability.extra.total_triggers + 1
                    card.ability.extra.eights_count = 0

                    local free_slots = G.consumeables.config.card_limit - #G.consumeables.cards
                    local to_create = math.min(2, free_slots)

                    return {
                        message = '8/8',
                        colour = G.C.CHIPS,
                        delay = 0.4,
                        func = function()
                            if to_create > 0 then
                                card_eval_status_text(card, 'extra', nil, nil, nil, {
                                    message = '+' .. to_create .. ' Tarot',
                                    colour = G.C.PURPLE
                                })
                                G.E_MANAGER:add_event(Event({
                                    trigger = 'after',
                                    delay = 0.4,
                                    func = function()
                                        for i = 1, to_create do
                                            local tarot = create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, '8ba')
                                            tarot:add_to_deck()
                                            G.consumeables:emplace(tarot)
                                        end
                                        play_sound('tarot1')
                                        return true
                                    end
                                }))
                            else
                                card_eval_status_text(card, 'extra', nil, nil, nil, {
                                    message = localize('k_no_room_ex'),
                                    colour = G.C.RED
                                })
                            end
                            return true
                        end
                    }
                else
                    return {
                        message = card.ability.extra.eights_count .. '/8',
                        colour = G.C.CHIPS
                    }
                end
            end
        end
    end
})