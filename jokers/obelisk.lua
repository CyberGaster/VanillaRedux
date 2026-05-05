SMODS.Joker:take_ownership('obelisk', {
    loc_txt = {
        name = 'Obelisk',
        text = {
            'This Joker gains {X:mult,C:white} X#1# {} Mult',
            'per hand played without playing',
            'your most played {C:attention}poker hand',
            '{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)',
        }
    },
    config = { extra = 0.05, Xmult = 1 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra, card.ability.x_mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if card.ability.x_mult > 1 then
                return { x_mult = card.ability.x_mult }
            end
        end
    end,
})

local _orig_calc = Card.calculate_joker
function Card:calculate_joker(context)
    if self.ability and self.ability.name == 'Obelisk' and not self.debuff
       and context and context.before then
        if not context.blueprint and context.scoring_name then
            local play_more_than = G.GAME.hands[context.scoring_name].played or 0
            local should_increment = false
            for k, v in pairs(G.GAME.hands) do
                if k ~= context.scoring_name and v.visible and v.played >= play_more_than then
                    should_increment = true
                    break
                end
            end
            if should_increment then
                self.ability.x_mult = self.ability.x_mult + self.ability.extra
            end
        end
        local saved = context.blueprint
        context.blueprint = true
        local r = _orig_calc(self, context)
        context.blueprint = saved
        return r
    end
    return _orig_calc(self, context)
end