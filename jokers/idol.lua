return function(center)

    center.cost = 9
    center.rarity = 3
    center.config = {extra = 1.5}

    center.loc_txt = {
        name = 'The Idol',
        text = {
            'Each played {C:attention}#2#{} or',
            '{V:1}#3#{} gives {X:mult,C:white}X#1#{} Mult',
            'when scored',
            '{s:0.8}Rank and suit change every round'
        }
    }

    center.loc_vars = function(self, info_queue, card)
        local idol = G.GAME and G.GAME.current_round and G.GAME.current_round.idol_card or {rank = 'A', suit = 'Hearts'}
        return {
            vars = {self.extra, localize(idol.rank, 'ranks'), localize(idol.suit, 'suits_plural')},
            colours = {G.C.SUITS[idol.suit]}
        }
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions 
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_idol then
        G.localization.descriptions.Joker.j_idol.text = center.loc_txt.text
    end

    if not rawget(_G,'VP_IDOL_BLOCKED') and rawget(_G,'Card') and Card.calculate_joker then
        local old_calculate_joker = Card.calculate_joker
        
        function Card:calculate_joker(context)
            if self.ability and self.ability.name == 'The Idol' and not self.debuff 
               and context and context.individual and context.cardarea == G.play 
               and context.other_card and not context.other_card.debuff then
               
                local idol = G.GAME.current_round.idol_card
                if not idol then return old_calculate_joker(self, context) end

                local cid = context.other_card:get_id()
                local rank_match = (cid == idol.id)
                local suit_match = context.other_card:is_suit(idol.suit)

                if rank_match or suit_match then
                    return {
                        x_mult = self.ability.extra,
                        colour = G.C.RED,
                        card = self
                    }
                end
                
                return nil
            end
            
            return old_calculate_joker(self, context)
        end
        _G.VP_IDOL_BLOCKED = true
    end
end