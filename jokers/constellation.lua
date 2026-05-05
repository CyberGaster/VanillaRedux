local function get_planets_used()
    if rawget(_G, 'G') and G.GAME then
        return G.GAME.constellation_planets_used or 0
    end
    return 0
end

local function get_x_mult()
    return 1 + get_planets_used() * 0.1
end

if not rawget(_G, 'VP_CONSTELLATION_PATCHED') then
    _G.VP_CONSTELLATION_PATCHED = true

    if rawget(_G, 'set_consumeable_usage') then
        local old_set_consumeable_usage = set_consumeable_usage
        function set_consumeable_usage(card)
            local result = old_set_consumeable_usage(card)

            if card and card.config and card.config.center and card.config.center.set == 'Planet' then
                if G.GAME then
                    G.GAME.constellation_planets_used = (G.GAME.constellation_planets_used or 0) + 1
                end
            end

            return result
        end
    end
end

SMODS.Joker:take_ownership('constellation', {
    loc_txt = {
        name = 'Constellation',
        text = {
            'This Joker gains {X:mult,C:white}X0.1{} Mult',
            'every time a {C:planet}Planet{} card',
            'is used in this run',
            '{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)',
        }
    },
    rarity = 3,
    cost = 8,
    loc_vars = function(self, info_queue, card)
        return { vars = { get_x_mult() } }
    end,
    calculate = function(self, card, context)
        if context.using_consumeable then
            if context.consumeable.config.center.set == 'Planet' then
                return {
                    message = localize{type='variable', key='a_xmult', vars={get_x_mult()}},
                    colour = G.C.MULT,
                    card = card
                }
            end
        end
        if context.joker_main then
            local xm = get_x_mult()
            if xm > 1 then
                return {
                    x_mult = xm
                }
            end
            return {}
        end
    end,
})