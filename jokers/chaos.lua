SMODS.Joker:take_ownership('chaos', {
    config = { extra = 1 },
    loc_txt = {
        name = 'Chaos the Clown',
        text = {
            '{C:attention}#1#{} free {C:green}Reroll{} per shop',
            'Gains {C:attention}+1{} free {C:green}Reroll{} when',
            '{C:attention}Boss Blind{} defeated',
            '{C:inactive}(resets when sold)'
        }
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or 1
        return { vars = { extra } }
    end,
})

local function find_chaos_jokers()
    local out = {}
    if rawget(_G, 'G') and G.jokers and G.jokers.cards then
        for _, v in ipairs(G.jokers.cards) do
            if v and v.ability and v.ability.name == 'Chaos the Clown' and not v.debuff then
                table.insert(out, v)
            end
        end
    end
    return out
end

local function total_chaos_rerolls()
    local total = 0
    for _, v in ipairs(find_chaos_jokers()) do
        local ex = v.ability and v.ability.extra
        if type(ex) ~= 'number' or ex <= 0 then ex = 1 end
        total = total + ex
    end
    return total
end

if not rawget(_G, 'VP_CHAOS_FIND_JOKER_PATCHED') and rawget(_G, 'find_joker') then
    local old_find_joker = find_joker
    function find_joker(name, non_debuff)
        if name == 'Chaos the Clown' then return {} end
        return old_find_joker(name, non_debuff)
    end
    _G.VP_CHAOS_FIND_JOKER_PATCHED = true
end

if not rawget(_G, 'VP_CHAOS_NEW_ROUND_PATCHED') and rawget(_G, 'new_round') then
    local old_new_round = new_round
    function new_round()
        old_new_round()
        if not (rawget(_G, 'G') and G.E_MANAGER and G.GAME and G.GAME.current_round) then return end
        G.E_MANAGER:add_event(Event({
            trigger = 'after', delay = 0.1, func = function()
                G.GAME.current_round.free_rerolls = total_chaos_rerolls()
                if rawget(_G, 'calculate_reroll_cost') then calculate_reroll_cost(true) end
                return true
            end
        }))
    end
    _G.VP_CHAOS_NEW_ROUND_PATCHED = true
end

if not rawget(_G, 'VP_CHAOS_REMOVE_PATCHED') and rawget(_G, 'Card') and Card.remove_from_deck then
    local old_remove_from_deck = Card.remove_from_deck
    function Card:remove_from_deck(from_debuff)
        local was_chaos = self.ability and self.ability.name == 'Chaos the Clown'
        local res = old_remove_from_deck(self, from_debuff)
        if was_chaos and rawget(_G, 'G') and G.GAME and G.GAME.current_round then
            local remaining = total_chaos_rerolls()
            local current_free = G.GAME.current_round.free_rerolls or 0
            if current_free < 0 then current_free = 0 end
            G.GAME.current_round.free_rerolls = math.min(remaining, current_free + 1)
            if rawget(_G, 'calculate_reroll_cost') then calculate_reroll_cost(true) end
        end
        return res
    end
    _G.VP_CHAOS_REMOVE_PATCHED = true
end

if not rawget(_G, 'VP_CHAOS_CALC_PATCHED') and rawget(_G, 'Card') and Card.calculate_joker then
    local old_calc = Card.calculate_joker
    function Card:calculate_joker(context)
        if self.ability and self.ability.name == 'Chaos the Clown' and not self.debuff then
            if not self.ability.extra or self.ability.extra <= 0 then self.ability.extra = 1 end
            if context.end_of_round and not context.individual and not context.repetition and not context.game_over then
                if G.GAME and G.GAME.round_resets and G.GAME.round_resets.blind then
                    local b = G.GAME.round_resets.blind
                    if b and b ~= G.P_BLINDS.bl_small and b ~= G.P_BLINDS.bl_big then
                        self.ability.extra = self.ability.extra + 1
                        G.E_MANAGER:add_event(Event({
                            trigger = 'after', delay = 0.1, func = function()
                                if G.GAME and G.GAME.current_round then
                                    G.GAME.current_round.free_rerolls = total_chaos_rerolls()
                                    if rawget(_G, 'calculate_reroll_cost') then calculate_reroll_cost(true) end
                                end
                                return true
                            end
                        }))
                        return { message = "+1 Reroll", colour = G.C.GREEN, card = self }
                    end
                end
            end
            if context.selling_self then
                self.ability.extra = 1
            end
            return nil
        end
        return old_calc(self, context)
    end
    _G.VP_CHAOS_CALC_PATCHED = true
end