local function _to_number(x)
    if type(x) == 'number' then return x end
    if type(x) == 'table' then
        local ok, v
        if x.to_number then ok, v = pcall(function() return x:to_number() end); if ok and type(v) == 'number' then return v end end
        if x.toNumber then ok, v = pcall(function() return x:toNumber() end); if ok and type(v) == 'number' then return v end end
    end
    return tonumber(tostring(x)) or 0
end

SMODS.Joker:take_ownership('mr_bones', {
    loc_txt = {
        name = 'Mr. Bones',
        text = {
            'Prevents Death if chips scored',
            'are at least {C:attention}#1#{} of required chips',
            'After saving, threshold increases',
            'by {C:attention}#2#{} and sets money to {C:money}$0{}'
        }
    },
    config = { extra = { threshold_pct = 25, max_pct = 90, increments = {30, 35}, step_idx = 1 } },
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        local current = math.min(extra.threshold_pct, extra.max_pct)
        local inc = extra.increments[extra.step_idx]
        if inc and current < extra.max_pct then
            return { vars = { tostring(math.floor(current))..'%', tostring(inc)..'%' } }
        else
            return { vars = { tostring(math.floor(current))..'%' }, key = 'j_mr_bones_maxed' }
        end
    end,
    calculate = function(self, card, context)
        if context.game_over then
            local chips_n = _to_number(G.GAME.chips)
            local blind_n = _to_number(G.GAME.blind.chips)
            if blind_n <= 0 then blind_n = 1 end
            local extra = card.ability.extra
            local threshold = math.min(extra.threshold_pct, extra.max_pct)

            if chips_n / blind_n >= threshold * 0.01 then
                G.E_MANAGER:add_event(Event({
                    func = function()
                        G.hand_text_area.blind_chips:juice_up()
                        G.hand_text_area.game_chips:juice_up()
                        play_sound('tarot1')
                        if G.GAME.dollars and G.GAME.dollars ~= 0 then
                            ease_dollars(-G.GAME.dollars, true)
                        end
                        return true
                    end
                }))

                local inc = extra.increments[extra.step_idx]
                if inc then
                    extra.threshold_pct = math.min(extra.threshold_pct + inc, extra.max_pct)
                    extra.step_idx = extra.step_idx + 1
                end

                return {
                    message = localize('k_saved_ex'),
                    saved = true,
                    colour = G.C.RED
                }
            end
            return {}
        end
    end,
})

G.localization.descriptions.Joker.j_mr_bones_maxed = {
    name = 'Mr. Bones',
    text = {
        'Prevents Death if chips scored',
        'are at least {C:attention}#1#{} of required chips',
        'Sets money to {C:money}$0{} when saved'
    }
}
