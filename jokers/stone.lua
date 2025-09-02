return function(center)

    center.config = center.config or {}
    center.config.extra = 3
    
    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Stone Joker'
    center.loc_txt.text = {
        "Gives {C:chips}+#1#{} Chips and {C:mult}+#1#{} Mult",
        "for each {C:attention}Stone Card",
        "in your {C:attention}full deck",
        "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips and {C:mult}+#2#{C:inactive} Mult)"
    }
    
    center.calculate = function(self, card, context)
        if context and context.joker_main then
            if card.ability.stone_tally and card.ability.stone_tally > 0 then
                local chip_bonus = (card.ability.extra or 3) * card.ability.stone_tally
                local mult_bonus = (card.ability.extra or 3) * card.ability.stone_tally
                
                if rawget(_G, 'card_eval_status_text') then
                    card_eval_status_text(card, 'extra', nil, nil, nil, {
                        message = chip_bonus.." chips + "..mult_bonus.." mult",
                        colour = G.C.PURPLE,
                        delay = 1.0
                    })
                end
                
                return {
                    chip_mod = chip_bonus,
                    mult_mod = mult_bonus
                }
            end
        end
        return nil
    end
    
    center.loc_vars = function(self, info_queue, card)
        return {vars = {card.ability.extra or 3, (card.ability.extra or 3) * (card.ability.stone_tally or 0)}}
    end
    
    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_stone then
        G.localization.descriptions.Joker.j_stone.name = "Stone Joker"
        G.localization.descriptions.Joker.j_stone.text = center.loc_txt.text
    end
    
    if rawget(_G,'G') and G.P_CENTERS and G.P_CENTERS.j_stone then
        G.P_CENTERS.j_stone.config.extra = 3
    end
end