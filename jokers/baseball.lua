SMODS.Joker:take_ownership('baseball', {
    cost = 9,
    loc_txt = {
        name = 'Baseball Card',
        text = {
            '{C:blue}Common{} Jokers each give {X:mult,C:white}X1.25{} Mult',
            '{C:green}Uncommon{} Jokers each give {X:mult,C:white}X1.5{} Mult',
            '{C:red}Rare{} Jokers each give {X:mult,C:white}X2{} Mult',
            'Baseball Card not included'
        }
    },
    calculate = function(self, card, context)
        if context.other_joker and card ~= context.other_joker then
            local other_joker = context.other_joker

            if other_joker.config.center.key == 'j_baseball' then
                return nil
            end

            local rarity = other_joker.config.center.rarity
            local mult_value = nil

            if rarity == 1 then
                mult_value = 1.25
            elseif rarity == 2 then
                mult_value = 1.5
            elseif rarity == 3 then
                mult_value = 2.0
            end

            if mult_value then
                G.E_MANAGER:add_event(Event({
                    func = function()
                        other_joker:juice_up(0.5, 0.5)
                        return true
                    end
                }))

                return {
                    x_mult = mult_value,
                    colour = G.C.MULT,
                    card = card
                }
            end
        end
    end,
})