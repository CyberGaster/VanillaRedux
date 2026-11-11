SMODS.Joker:take_ownership('ancient', {
    rarity = 2,
    cost = 7,
    loc_txt = {
        name = "Ancient Joker",
        text = {
            '{C:attention}Stone{} cards count as',
            'the same rank for poker hands',
        }
    },
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            return {}
        end
    end,
})

local function ancient_is_active()
    if not (G and G.jokers and G.jokers.cards) then return false end
    for i = 1, #G.jokers.cards do
        local j = G.jokers.cards[i]
        if j and j.ability and j.ability.name == 'Ancient Joker' and not j.debuff then
            return true
        end
    end
    return false
end

-- Stone cards are added as one more rank group where the game builds its rank groups, so
-- Two Pair, Full House and every other hand built on them see the Stones like any other rank.
if not rawget(_G, 'VP_ANCIENT_GROUPS_PATCHED') and rawget(_G, 'get_X_same') then
    local old_get_X_same = get_X_same
    function get_X_same(num, hand, or_more)
        if num < 2 or not ancient_is_active() then
            return old_get_X_same(num, hand, or_more)
        end

        local stones, others = {}, {}
        for i = 1, #hand do
            local c = hand[i]
            if c and c.ability and c.ability.effect == 'Stone Card' then
                stones[#stones + 1] = c
            else
                others[#others + 1] = c
            end
        end
        if #stones < 2 then
            return old_get_X_same(num, hand, or_more)
        end

        local groups = old_get_X_same(num, others, or_more)
        if (or_more and #stones >= num) or #stones == num then
            groups[#groups + 1] = stones
        end
        return groups
    end
    _G.VP_ANCIENT_GROUPS_PATCHED = true
end