return function(center)

    center.cost = 4
    
    center.config = center.config or {}
    center.config.extra = center.config.extra or {}
    center.config.extra.dollars = 2
    center.config.extra.odds = 2
    
    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Reserved Parking'
    center.loc_txt.text = {
        'Each {C:attention}face{} card',
        'held in hand has',
        'a {C:green}#2# in #3#{} chance',
        'to give {C:money}$#1#{}'
    }
    
    center.loc_vars = function(self, info_queue, card)
        local dollars = 2
        local odds = 2
        if card and card.ability and card.ability.extra then
            dollars = card.ability.extra.dollars or 2
            odds = card.ability.extra.odds or 2
        elseif self and self.config and self.config.extra then
            dollars = self.config.extra.dollars or 2
            odds = self.config.extra.odds or 2
        end
        return { vars = { dollars, '1', odds } }
    end
    
    if rawget(_G, 'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_reserved_parking then
        G.localization.descriptions.Joker.j_reserved_parking.text = center.loc_txt.text
    end
end