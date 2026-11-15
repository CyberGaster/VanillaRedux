local function owned_skips(card)
    return card.ability.vr_owned_skips or (G.GAME and G.GAME.throwback_owned_skips) or 0
end

local function current_xmult(card)
    local skips = (G.GAME and G.GAME.skips) or 0
    return 1 + card.ability.extra * skips + card.ability.extra * owned_skips(card)
end

SMODS.Joker:take_ownership('throwback', {
    loc_txt = {
        name = 'Throwback',
        text = {
            '{X:mult,C:white}X#1#{} Mult for each Blind',
            'skipped this run',
            '{X:mult,C:white}X#2#{} for Blinds skipped',
            'with this Joker',
            '{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult)'
        }
    },
    config = { extra = 0.25 },
    set_ability = function(self, card, initial, delay_sprites)
        card.ability.vr_owned_skips = card.ability.vr_owned_skips or 0
    end,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra, card.ability.extra * 2, current_xmult(card) } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local x_mult = current_xmult(card)
            if x_mult > 1 then
                return { x_mult = x_mult }
            end
            return {}
        end
        if context.skip_blind and not context.blueprint then
            card.ability.vr_owned_skips = owned_skips(card) + 1
            return { message = localize('k_upgrade_ex') }
        end
    end,
    blueprint_compat = true,
})

if not rawget(_G, 'VR_THROWBACK_UPDATE_PATCHED') and rawget(_G, 'Card') and Card.update then
    local old_update = Card.update
    function Card:update(dt)
        old_update(self, dt)
        if self.ability and self.ability.name == 'Throwback' and type(self.ability.extra) == 'number'
           and G.STAGE == G.STAGES.RUN then
            self.ability.x_mult = current_xmult(self)
        end
    end
    _G.VR_THROWBACK_UPDATE_PATCHED = true
end
