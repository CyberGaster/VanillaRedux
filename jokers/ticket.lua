-- Extra money a held Gold Card gets from Golden Ticket. Every Joker is asked, so Steamodded's copying
-- answers for Blueprint, Brainstorm and chains of them, and each working copy adds its own bonus.
local function ticket_bonus(card)
    if not (G and G.jokers and G.jokers.cards) then return 0 end
    local bonus = 0
    for _, joker in ipairs(G.jokers.cards) do
        local ok, res = pcall(joker.calculate_joker, joker, { vr_ticket_bonus = true, other_card = card })
        if ok and type(res) == 'table' and type(res.h_dollars) == 'number' then
            bonus = bonus + res.h_dollars
        end
    end
    return bonus
end

local function is_paying_gold(card)
    return card and card.ability and card.ability.name == 'Gold Card' and not card.debuff
        and type(card.ability.h_dollars) == 'number' and card.ability.h_dollars > 0
end

SMODS.Joker:take_ownership('ticket', {
    loc_txt = {
        name = 'Golden Ticket',
        text = {
            'Played {C:attention}Gold{} cards',
            'earn {C:money}$#1#{} when scored',
            'Gold cards held in hand',
            'give {C:money}$#2#{} more at end of round'
        }
    },
    config = { extra = 5 },
    set_ability = function(self, card, initial, delay_sprites)
        card.ability.eor_bonus = card.ability.eor_bonus or 2
    end,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra, card.ability.eor_bonus or 2 } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card and context.other_card.ability and context.other_card.ability.name == 'Gold Card' then
                return { dollars = card.ability.extra }
            end
            return {}
        end

        if context.vr_ticket_bonus then
            return { h_dollars = card.ability.eor_bonus or 2 }
        end
    end,
    blueprint_compat = true,
})

if not rawget(_G, 'VP_TICKET_GOLD_PATCHED') then
    -- The bonus is part of the Gold Card's own payout, so it is paid in one go.
    local orig_get_eor = Card.get_end_of_round_effect
    function Card:get_end_of_round_effect(context)
        local ret = orig_get_eor(self, context) or {}
        if is_paying_gold(self) and ret.h_dollars then
            local bonus = ticket_bonus(self)
            if bonus > 0 then ret.h_dollars = ret.h_dollars + bonus end
        end
        return ret
    end

    -- The Gold Card tooltip reads ability.h_dollars, so it shows the same total while it is built.
    local orig_ability_table = Card.generate_UIBox_ability_table
    function Card:generate_UIBox_ability_table(...)
        local bonus = is_paying_gold(self) and ticket_bonus(self) or 0
        if bonus <= 0 then return orig_ability_table(self, ...) end
        local base = self.ability.h_dollars
        self.ability.h_dollars = base + bonus
        local ok, a, b, c = pcall(orig_ability_table, self, ...)
        self.ability.h_dollars = base
        if not ok then error(a, 0) end
        return a, b, c
    end
    _G.VP_TICKET_GOLD_PATCHED = true
end
