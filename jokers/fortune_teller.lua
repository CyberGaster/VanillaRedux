if not rawget(_G, 'VR_FT_SHOP_PATCHED') and rawget(_G, 'create_card_for_shop') then
    local old_create_card_for_shop = create_card_for_shop
    function create_card_for_shop(area)
        local prev = G.GAME and G.GAME.tarot_rate or 4
        local ft_count = 0
        if G and G.jokers and G.jokers.cards then
            for i = 1, #G.jokers.cards do
                local c = G.jokers.cards[i]
                if c and c.ability and c.ability.name == 'Fortune Teller' and not c.debuff then
                    ft_count = ft_count + 1
                end
            end
        end
        if ft_count > 0 and prev and prev > 0 then
            G.GAME.tarot_rate = prev + (prev * 0.2 * ft_count)
        end
        local result = old_create_card_for_shop(area)
        if ft_count > 0 then G.GAME.tarot_rate = prev end
        return result
    end
    _G.VR_FT_SHOP_PATCHED = true
end

SMODS.Joker:take_ownership('fortune_teller', {
    loc_txt = {
        name = 'Fortune Teller',
        text = {
            'This Joker gains {X:mult,C:white}X#1#{} Mult',
            'per {C:tarot}Tarot{} card used this run',
            'Increases chance of {C:tarot}Tarot{} in shop',
            '{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)',
        }
    },
    config = { extra = 0.05 },
    rarity = 2,
    cost = 7,
    loc_vars = function(self, info_queue, card)
        local gain = (card and card.ability and card.ability.extra) or 0.05
        local used = (G.GAME and G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.tarot) or 0
        local x = 1 + used * gain
        return { vars = { gain, x } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local gain = card.ability.extra or 0.05
            local used = (G.GAME and G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.tarot) or 0
            local x = 1 + used * gain
            if x > 1 then
                return { x_mult = x }
            end
            return {}
        end

        if context.using_consumeable and context.consumeable
           and context.consumeable.ability and context.consumeable.ability.set == 'Tarot' then
            local gain = card.ability.extra or 0.05
            local used = (G.GAME and G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.tarot) or 0
            local x = 1 + used * gain
            return {
                message = localize{type='variable', key='a_xmult', vars={x}},
                colour = G.C.MULT,
                card = card
            }
        end
    end,
})