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
    loc_vars = function(self, info_queue, card)
        local mult = (card and card.ability and card.ability.extra and card.ability.extra.mult) or 0
        return { vars = { mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if card.ability.extra.mult > 0 then
                return {
                    mult = card.ability.extra.mult
                }
            end
            return {}
        end

        if context.end_of_round and not context.individual and not context.repetition then
            if not context.blueprint then
                local hands_played = (G.GAME and G.GAME.current_round and G.GAME.current_round.hands_played) or 0
                local gain = 0
                if hands_played == 1 then
                    gain = 10
                elseif hands_played == 2 then
                    gain = 5
                end
                if gain > 0 then
                    card.ability.extra.mult = card.ability.extra.mult + gain
                    return {
                        message = localize{type='variable', key='a_mult', vars={gain}},
                        colour = G.C.MULT
                    }
                end
            end
        end
    end,
})