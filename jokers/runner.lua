SMODS.Joker:take_ownership('runner', {
    loc_txt = {
        name = 'Runner',
        text = {
            'Gains {C:chips}+15{} Chips if played',
            'hand contains a {C:attention}Straight{}',
            'Gain increases by {C:chips}+5{} for',
            'each subsequent {C:attention}Straight{}',
            '{C:inactive}(Next gain: {C:chips}+#2#{C:inactive})',
            '{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)'
        }
    },
    config = { extra = { chips = 0, chip_mod = 15, straights_played = 0 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.chip_mod } }
    end,
    set_ability = function(self, card, initial, delay_sprites)
        card.ability.extra = card.ability.extra or {}
        card.ability.extra.chips = card.ability.extra.chips or 0
        card.ability.extra.chip_mod = card.ability.extra.chip_mod or 15
        card.ability.extra.straights_played = card.ability.extra.straights_played or 0
    end,
    update = function(self, card, dt)
        if card.ability and card.ability.extra then
            card.ability.extra.chip_mod = 15 + (card.ability.extra.straights_played or 0) * 5
        end
    end,
    calculate = function(self, card, context)
        local has_straight = context.poker_hands
            and context.poker_hands['Straight']
            and next(context.poker_hands['Straight'])

        if context.before and not context.blueprint then
            if has_straight then
                card.ability.extra.straights_played = card.ability.extra.straights_played + 1
                local chips_to_add = 15 + (card.ability.extra.straights_played - 1) * 5
                card.ability.extra.chips = card.ability.extra.chips + chips_to_add
                card.ability.extra.chip_mod = 15 + card.ability.extra.straights_played * 5
                return {
                    message = localize('k_upgrade_ex'),
                    colour = G.C.CHIPS,
                    card = card
                }
            end
            return {}
        end
        if context.joker_main then
            if card.ability.extra.chips > 0 then
                return {
                    chip_mod = card.ability.extra.chips,
                    message = localize{type='variable', key='a_chips', vars={card.ability.extra.chips}}
                }
            end
            return {}
        end
    end,
    blueprint_compat = true,
})