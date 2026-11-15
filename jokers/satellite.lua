local function planet_dollars(card)
    local unique = 0
    for _, v in pairs((G.GAME and G.GAME.consumeable_usage) or {}) do
        if v.set == 'Planet' then unique = unique + 1 end
    end
    return card.ability.extra * unique
end

SMODS.Joker:take_ownership('satellite', {
    loc_txt = {
        name = 'Satellite',
        text = {
            "{C:planet}Planet{} cards used",
            "are twice as effective",
            "Earn {C:money}$#1#{} at end of round",
            "per unique {C:planet}Planet{} card",
            "used this run",
            "{C:inactive}(Currently {C:money}$#2#{C:inactive})",
        }
    },
    cost = 7,
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra, planet_dollars(card) } }
    end,
    calc_dollar_bonus = function(self, card)
        local dollars = planet_dollars(card)
        if dollars > 0 then return dollars end
    end,
    calculate = function(self, card, context)
        if context.vr_planet_retrigger then
            local planet, hand_type = context.vr_planet_retrigger, context.vr_hand_type
            return {
                message = localize('k_again_ex'),
                func = function()
                    level_up_hand(planet, hand_type)
                end,
            }
        end
        if context.vr_satellite_dollars then
            local dollars = planet_dollars(card)
            if dollars > 0 then
                return { vr_dollars = dollars }
            end
        end
    end,
})

if not rawget(_G, 'VP_SATELLITE_HOOKS') and rawget(_G, 'Card') and Card.use_consumeable and Card.calculate_dollar_bonus then
    local base_use_consumeable = Card.use_consumeable
    function Card:use_consumeable(area, copier)
        local ret = base_use_consumeable(self, area, copier)
        local hand_type = self.ability.set == 'Planet' and not self.debuff
            and self.ability.consumeable and self.ability.consumeable.hand_type
        if hand_type then
            SMODS.calculate_context({ vr_planet_retrigger = copier or self, vr_hand_type = hand_type })
        end
        return ret
    end

    local base_calculate_dollar_bonus = Card.calculate_dollar_bonus
    function Card:calculate_dollar_bonus()
        local dollars = base_calculate_dollar_bonus(self)
        if self.ability.set == 'Joker' and (self.ability.name == 'Blueprint' or self.ability.name == 'Brainstorm')
            and self:can_calculate() then
            local copied = self:calculate_joker({ vr_satellite_dollars = true })
            if copied and copied.vr_dollars then
                dollars = (dollars or 0) + copied.vr_dollars
            end
        end
        return dollars
    end
    _G.VP_SATELLITE_HOOKS = true
end