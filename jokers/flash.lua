SMODS.Joker:take_ownership('flash', {
    loc_txt = {
        name = 'Flash Card',
        text = {
            'Gains {C:mult}+10{} Mult at end of round',
            'if {C:attention}Blind{} defeated in {C:attention}1 hand{},',
            '{C:mult}+5{} Mult if in {C:attention}2 hands{}',
            '{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)'
        }
    },
    config = { extra = { mult = 0 } },
    cost = 6,
    loc_vars = function(self, info_queue, card)
        local mult = (card and card.ability and card.ability.extra and card.ability.extra.mult) or 0
        return { vars = { mult } }
    end,
    calculate = function(self, card, context)
        if context.reroll_shop then
            return {}
        end

        if context.joker_main then
            if card.ability.extra.mult > 0 then
                return {
                    mult = card.ability.extra.mult
                }
            end
            return {}
        end

        if context.end_of_round and context.main_eval and not context.blueprint then
            local hands_played = (G.GAME and G.GAME.current_round and G.GAME.current_round.hands_played) or 0
            local gain = hands_played == 1 and 10 or hands_played == 2 and 5 or 0
            if gain > 0 then
                SMODS.scale_card(card, {
                    ref_table = card.ability.extra,
                    ref_value = 'mult',
                    scalar_table = { gain = gain },
                    scalar_value = 'gain',
                    message_key = 'a_mult',
                    message_colour = G.C.MULT,
                })
                return nil, true
            end
        end
    end,
})