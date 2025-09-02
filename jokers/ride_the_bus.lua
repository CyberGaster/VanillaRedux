return function()
    
    local X_INCREASE_PER_HAND = 0.02
    if SMODS and SMODS.Joker then
        SMODS.Joker:take_ownership('ride_the_bus', {
            no_mod_display = true,
            loc_txt = {
                name = 'Ride the Bus',
                text = {
                    'This Joker gains {X:mult,C:white}X#1#{} Mult',
                    'per {C:attention}consecutive{} hand',
                    'played without a',
                    'scoring {C:attention}face{} card',
                    '{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)'
                }
            },
            config = { extra = X_INCREASE_PER_HAND },
            loc_vars = function(self, _info, card)
                local step = (self and self.config and self.config.extra) or X_INCREASE_PER_HAND
                local x_mult = 1
                if card and card.ability and card.ability.x_mult then
                    x_mult = card.ability.x_mult
                end
                return { vars = { step, x_mult } }
            end,
            set_ability = function(self, card, initial, delay_sprites)
                if card and card.ability then
                    card.ability.x_mult = card.ability.x_mult or 1
                    card.ability.mult = card.ability.x_mult
                    card.ability.extra = card.ability.extra or X_INCREASE_PER_HAND
                end
            end,
        })
    end

    if not rawget(_G, 'VR_PATCHED_RIDE_THE_BUS') and rawget(_G, 'Card') and Card.calculate_joker then
        _G.VR_PATCHED_RIDE_THE_BUS = true
        local base_calculate_joker = Card.calculate_joker

        local function ride_the_bus_calculate(card, context)
            if not card or card.debuff then return nil end
            card.ability.extra = card.ability.extra or X_INCREASE_PER_HAND
            if card.ability.x_mult == nil then card.ability.x_mult = 1 end
            if context and context.before and not context.blueprint then
                local has_face_in_scoring = false
                if context.scoring_hand then
                    for i = 1, #context.scoring_hand do
                        local c = context.scoring_hand[i]
                        if c and c.is_face and c:is_face() then
                            has_face_in_scoring = true
                            break
                        end
                    end
                end
                if has_face_in_scoring then
                    local last = card.ability.x_mult or 1
                    card.ability.x_mult = 1
                    card.ability.mult = card.ability.x_mult
                    if last and last > 1 then
                        return {
                            card = card,
                            message = localize('k_reset')
                        }
                    end
                else
                    card.ability.x_mult = (card.ability.x_mult or 1) + (card.ability.extra or X_INCREASE_PER_HAND)
                    card.ability.mult = card.ability.x_mult
                end
                return nil
            end
            if context and context.joker_main then
                local x = card.ability.x_mult or 1
                if x and x > 1 then
                    return {
                        message = localize{type='variable', key='a_xmult', vars={x}},
                        Xmult_mod = x,
                        card = card
                    }
                end
            end

            return nil
        end

        function Card:calculate_joker(context)
            if self.ability and self.ability.name == 'Ride the Bus' then
                return ride_the_bus_calculate(self, context)
            end
            return base_calculate_joker(self, context)
        end
    end

    if SMODS and SMODS.Hook then
        SMODS.Hook.add('post_game_init', function()
            if G.P_CENTERS and G.P_CENTERS.j_ride_the_bus then
                local c = G.P_CENTERS.j_ride_the_bus
                c.mod = nil; c.mod_id = nil; c.modded = false; c.discovered = true; c.no_mod_display = true
            end
            if rawget(_G,'G') and G.localization and G.localization.descriptions
                and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_ride_the_bus then
                G.localization.descriptions.Joker.j_ride_the_bus.text = {
                    'This Joker gains {X:mult,C:white}X#1#{} Mult',
                    'per {C:attention}consecutive{} hand',
                    'played without a',
                    'scoring {C:attention}face{} card',
                    '{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)'
                }
            end
        end)
    else
        if G.P_CENTERS and G.P_CENTERS.j_ride_the_bus then
            local c = G.P_CENTERS.j_ride_the_bus
            c.mod = nil; c.mod_id = nil; c.modded = false; c.discovered = true; c.no_mod_display = true
        end
        if rawget(_G,'G') and G.localization and G.localization.descriptions
            and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_ride_the_bus then
            G.localization.descriptions.Joker.j_ride_the_bus.text = {
                'This Joker gains {X:mult,C:white}X#1#{} Mult',
                'per {C:attention}consecutive{} hand',
                'played without a',
                'scoring {C:attention}face{} card',
                '{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)'
            }
        end
    end
end


