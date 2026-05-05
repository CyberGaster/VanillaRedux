SMODS.Joker:take_ownership('ceremonial', {
    loc_txt = {
        name = 'Ceremonial Dagger',
        text = {
            'When {C:attention}Blind{} is selected,',
            'destroy Joker to the right',
            'and permanently add {C:attention}triple',
            'its sell value to this {C:red}Mult',
            '{C:inactive}(Currently {C:mult}+#1#{}{C:inactive} Mult)'
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { (card and card.ability and card.ability.mult) or 0 } }
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not card.getting_sliced and not context.blueprint then
            local my_pos = nil
            for i = 1, #G.jokers.cards do
                if G.jokers.cards[i] == card then my_pos = i; break end
            end
            local target = my_pos and G.jokers.cards[my_pos + 1] or nil
            if target and not target.ability.eternal and not target.getting_sliced then
                local sell_cost = target.sell_cost or 0
                local gain = sell_cost * 3
                target.getting_sliced = true
                G.E_MANAGER:add_event(Event({
                    func = function()
                        card:juice_up(0.8, 0.8)
                        target:start_dissolve({HEX('57ecab')}, nil, 1.6)
                        play_sound('slice1', 0.96 + math.random() * 0.08)
                        return true
                    end
                }))
                card.ability.mult = (card.ability.mult or 0) + gain
                return {
                    message = localize{type='variable', key='a_mult', vars={gain}},
                    colour = G.C.MULT
                }
            end
        end
        if context.joker_main then
            if card.ability.mult > 0 then
                return {
                    mult = card.ability.mult
                }
            end
            return {}
        end
    end,
})