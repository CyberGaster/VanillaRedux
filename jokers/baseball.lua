return function(center)

    center.config = center.config or {}
    center.config.extra = 1.5
    center.cost = 9 


    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Baseball Card'
    center.loc_txt.text = {
        '{C:blue}Common{} Jokers each give {X:mult,C:white}X1.25{} Mult',
        '{C:green}Uncommon{} Jokers each give {X:mult,C:white}X1.5{} Mult',
        '{C:red}Rare{} Jokers each give {X:mult,C:white}X2{} Mult',
        'Baseball Card not included'
    }

    center.calculate = function(self, card, context)
        if context and context.other_joker and self ~= context.other_joker then
            local other_joker = context.other_joker
            
            if other_joker.config and other_joker.config.center and 
               other_joker.config.center.key == 'j_baseball' then
                return nil
            end
            
            if other_joker.config and other_joker.config.center and other_joker.config.center.rarity then
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
                        message = localize{type='variable', key='a_xmult', vars={mult_value}},
                        Xmult_mod = mult_value,
                        colour = G.C.MULT,
                        card = card
                    }
                end
            end
        end
        
        return nil
    end

    center.loc_vars = function(self, info_queue, card)
        return { vars = { 1.25, 1.5, 2.0 } }
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_baseball then
        G.localization.descriptions.Joker.j_baseball.text = center.loc_txt.text
    end

    if rawget(_G,'G') and G.P_CENTERS and G.P_CENTERS.j_baseball then
        G.P_CENTERS.j_baseball.cost = 9
    end
end