SMODS.Joker:take_ownership('matador', {
    loc_txt = {
        name = 'Matador',
        text = {
            '{X:mult,C:white}X#1#{} for each played {C:hearts}Heart{} card',
            'if {C:attention}Boss Blind{} is selected',
            'Earn {C:money}$#2#{} when {C:attention}Boss Blind{} is defeated',
        }
    },
    config = { extra = { xmult_per_heart = 1.5, boss_reward = 12 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult_per_heart, card.ability.extra.boss_reward } }
    end,
    calculate = function(self, card, context)
        local is_boss = G.GAME.blind and G.GAME.blind.boss

        if context.setting_blind and is_boss and not context.blueprint then
            return {
                message = localize('k_active_ex'),
                colour = G.C.FILTER,
                card = card
            }
        end

        if context.individual and context.cardarea == G.play and is_boss then
            local c = context.other_card
            if c and c:is_suit('Hearts', nil, true) and not c.debuff then
                return {
                    x_mult = card.ability.extra.xmult_per_heart,
                    card = card
                }
            end
        end

        if context.end_of_round and not context.individual and not context.repetition then
            if is_boss and not context.blueprint then
                card.ability.extra._boss_defeated = true
            end
        end
    end,
    calc_dollar_bonus = function(self, card)
        if card.ability.extra._boss_defeated then
            card.ability.extra._boss_defeated = nil
            return card.ability.extra.boss_reward
        end
    end,
})