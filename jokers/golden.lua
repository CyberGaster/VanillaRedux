local function count_rare_legendary()
    local count = 0
    if G and G.jokers and G.jokers.cards then
        for i = 1, #G.jokers.cards do
            local joker = G.jokers.cards[i]
            local rarity = joker.config and joker.config.center and joker.config.center.rarity
            if type(rarity) == 'number' and rarity >= 3 then
                count = count + 1
            end
        end
    end
    return count
end

SMODS.Joker:take_ownership('golden', {
    loc_txt = {
        name = 'Golden Joker',
        text = {
            'Earn {C:money}$#1#{} at end of round',
            'Payout increases by {C:money}$#2#{} for',
            'each {C:red}rare{} or {C:legendary}legendary{} joker'
        }
    },
    config = { extra = { base = 4, per_rare = 2 } },
    set_ability = function(self, card, initial, delay_sprites)
        if type(card.ability.extra) ~= 'table' then
            card.ability.extra = { base = 4, per_rare = 2 }
        end
    end,
    loc_vars = function(self, info_queue, card)
        local extra = (card and card.ability and card.ability.extra) or { base = 4, per_rare = 2 }
        local payout = extra.base + count_rare_legendary() * extra.per_rare
        return { vars = { payout, extra.per_rare } }
    end,
    calc_dollar_bonus = function(self, card)
        local extra = card.ability.extra or { base = 4, per_rare = 2 }
        return extra.base + count_rare_legendary() * extra.per_rare
    end,
})