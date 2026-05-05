SMODS.Joker:take_ownership('idol', {
    loc_txt = {
        name = 'The Idol',
        text = {
            'Each played {C:attention}#2#{} or {V:1}#3#{}',
            'gives {X:mult,C:white}X#1#{} Mult when scored',
            '{s:0.8}Rank and suit change every round'
        }
    },
    cost = 9,
    rarity = 3,
    config = { extra = 1.5 },
    loc_vars = function(self, info_queue, card)
        local idol = G.GAME and G.GAME.current_round and G.GAME.current_round.idol_card or {rank = 'A', suit = 'Hearts'}
        return {
            vars = { card.ability.extra, localize(idol.rank, 'ranks'), localize(idol.suit, 'suits_plural'),
                colours = { G.C.SUITS[idol.suit] }
            }
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card and not context.other_card.debuff then
            local idol = G.GAME.current_round.idol_card
            if idol then
                local rank_match = (context.other_card:get_id() == idol.id)
                local suit_match = context.other_card:is_suit(idol.suit)
                if rank_match or suit_match then
                    return {
                        x_mult = card.ability.extra,
                        colour = G.C.RED,
                        card = card
                    }
                end
            end
        end
    end,
})