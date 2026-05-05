SMODS.Joker:take_ownership('joker', {
    loc_txt = {
        name = 'Joker',
        text = {
            '{C:mult}+#1#{} Mult',
            'Doubles {C:mult}Mult{} when',
            '{C:attention}Boss Blind{} is defeated'
        }
    },
    config = { mult = 4 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                mult = card.ability.mult
            }
        end

        if context.end_of_round and not context.individual and not context.repetition then
            if G.GAME.blind and G.GAME.blind.boss then
                card.ability.mult = card.ability.mult * 2
                
                G.E_MANAGER:add_event(Event({
                    func = function()
                        card:juice_up(0.8, 0.8)
                        return true
                    end
                }))

                return {
                    message = localize('k_upgrade_ex'),
                    colour = G.C.MULT
                }
            end
        end
    end,
})