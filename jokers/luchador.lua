SMODS.Joker:take_ownership('luchador', {
    loc_txt = {
        name = 'Luchador',
        text = {
            'Sell this card to disable',
            'the current {C:attention}Boss Blind{} and',
            'reduce required score by {C:attention}10%{}'
        }
    },
    calculate = function(self, card, context)
        if context.selling_self then
            local blind = G.GAME and G.GAME.blind
            if blind and blind.boss and not blind.disabled then
                local before = blind.chips or 0
                local reduced = math.max(0, math.floor(before * 0.9))
                if reduced < before then
                    blind.chips = reduced
                    blind.chip_text = number_format(blind.chips)
                    local hud = G.HUD_blind and G.HUD_blind:get_UIE_by_ID('HUD_blind_count')
                    if hud then hud:juice_up() end
                end
                card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('ph_boss_disabled')})
                blind:disable()
            end
        end
    end,
})