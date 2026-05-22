local function pr_float(seed_key, min_v, max_v)
    local base = pseudorandom(seed_key)
    return min_v + (max_v - min_v) * base
end

SMODS.Joker:take_ownership('misprint', {
    loc_txt = {
        name = 'Misprint',
        text = { '' }
    },
    config = { extra = { min = 0, max = 27, x_min = 0.5, x_max = 2.0 } },
    calculate = function(self, card, context)
        if context.joker_main then
            local extra = card.ability.extra
            local plus_mult = pseudorandom('misprint_plus', extra.min, extra.max)
            local x_seed = 'misprint_x_'..tostring(G.GAME.hands_played or 0)
            local x_val = pr_float(x_seed, extra.x_min, extra.x_max)
            x_val = math.floor(x_val * 100 + 0.5) / 100
            return {
                mult = plus_mult,
                x_mult = x_val
            }
        end
    end,
})

if not rawget(_G, 'VP_MISPRINT_PATCHED') then
local old_generate = Card.generate_UIBox_ability_table
function Card:generate_UIBox_ability_table()
    local t = old_generate(self)
    if self and self.ability and self.ability.set == 'Joker' and self.ability.name == 'Misprint'
       and not self.debuff and t and type(t) == 'table' and t.main then
        local extra = self.ability.extra or {}
        local x_min = extra.x_min or 0.5
        local x_max = extra.x_max or 2.0
        local steps = math.max(1, math.floor((x_max - x_min) * 100))
        local r_x = {}
        for s = 0, steps do
            local v = x_min + (x_max - x_min) * (s / steps)
            r_x[#r_x + 1] = ('%.2f'):format(v)
        end
        local loc_mult = ' '..(localize('k_mult'))..' '
        t.main[#t.main + 1] = {
            {n=G.UIT.R, config={}},
            {n=G.UIT.T, config={text = '  X', colour = G.C.XMULT, scale = 0.32}},
            {n=G.UIT.O, config={object = DynaText({string = r_x, colours = {G.C.RED}, pop_in_rate = 9999999, silent = true, random_element = true, pop_delay = 0.5, scale = 0.32, min_cycle_time = 0})}},
            {n=G.UIT.O, config={object = DynaText({string = {
                {string = 'rand()', colour = G.C.JOKER_GREY},
                {string = "#@"..(G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.id or 11)..(G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.suit:sub(1,1) or 'D'), colour = G.C.RED},
                loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult, loc_mult
            }, colours = {G.C.UI.TEXT_DARK}, pop_in_rate = 9999999, silent = true, random_element = true, pop_delay = 0.2011, scale = 0.32, min_cycle_time = 0})}},
        }
    end
    return t
end
_G.VP_MISPRINT_PATCHED = true
end
