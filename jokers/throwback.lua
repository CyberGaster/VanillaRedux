SMODS.Joker:take_ownership('throwback', {
    loc_txt = {
        name = 'Throwback',
        text = {
            '{X:mult,C:white}X#1#{} Mult for each Blind',
            'skipped this run',
            '{X:mult,C:white}X#2#{} Mult instead if in hand',
            '{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult)'
        }
    },
    config = { extra = 0.25 },
    set_ability = function(self, card, initial, delay_sprites)
    end,
    loc_vars = function(self, info_queue, card)
        local skips = (G.GAME and G.GAME.skips) or 0
        local owned = (G.GAME and G.GAME.throwback_owned_skips) or 0
        local current = 1 + card.ability.extra * skips + card.ability.extra * owned
        return { vars = { card.ability.extra, card.ability.extra * 2, current } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local skips = (G.GAME and G.GAME.skips) or 0
            local owned = (G.GAME and G.GAME.throwback_owned_skips) or 0
            local x_mult = 1 + card.ability.extra * skips + card.ability.extra * owned
            if x_mult > 1 then
                return { x_mult = x_mult }
            end
            return {}
        end
        if context.skip_blind and not context.blueprint then
            G.GAME.throwback_owned_skips = (G.GAME.throwback_owned_skips or 0) + 1
            return { message = localize('k_upgrade_ex') }
        end
    end,
    blueprint_compat = true,
})