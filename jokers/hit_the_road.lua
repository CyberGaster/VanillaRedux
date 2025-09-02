return function(center)

    center.config = center.config or {}
    center.config.extra = 0.04

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Hit the Road'
    center.loc_txt.text = {
        'This Joker gains {X:mult,C:white} X#1# {} Mult',
        'for every {C:attention}Jack{} discarded',
        '{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)',
    }

    center.loc_vars = function(self, info_queue, card)
        local step = (self and self.config and self.config.extra) or 0.04
        local current_x = 1
        if card and card.ability then
            current_x = card.ability.x_mult or 1
            if card.ability.extra then step = card.ability.extra end
        end
        return { vars = { step, current_x } }
    end

    local original_set_ability = center.set_ability
    center.set_ability = function(self, card, initial, delay_sprites)
        if original_set_ability then original_set_ability(self, card, initial, delay_sprites) end
        card.ability = card.ability or {}
        card.ability.x_mult = card.ability.x_mult or 1
        card.ability.extra = (self and self.config and self.config.extra) or 0.04
    end

    if not rawget(_G,'VP_HITTHEROAD_BLOCKED') and rawget(_G,'Card') and Card.calculate_joker then
        local old_calculate_joker = Card.calculate_joker
        function Card:calculate_joker(context)
            if self.ability and self.ability.name == 'Hit the Road' and not self.debuff and context then
                if context.end_of_round and not context.blueprint then
                    return nil
                end
                if context.discard and not context.blueprint then
                    if context.other_card and not context.other_card.debuff and context.other_card.get_id and context.other_card:get_id() == 11 then
                        self.ability.x_mult = (self.ability.x_mult or 1) + (self.ability.extra or 0.04)
                        return {
                            message = localize{type='variable', key='a_xmult', vars={self.ability.x_mult}},
                            colour = G.C.RED,
                            delay = 0.45,
                            card = self
                        }
                    end
                end
            end
            return old_calculate_joker(self, context)
        end
        _G.VP_HITTHEROAD_BLOCKED = true
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_hit_the_road then
        G.localization.descriptions.Joker.j_hit_the_road.text = center.loc_txt.text
    end

    if SMODS and SMODS.Hook then
        SMODS.Hook.add('post_game_init', function()
            if G.jokers and G.jokers.cards then
                for i = 1, #G.jokers.cards do
                    local card = G.jokers.cards[i]
                    if card and card.ability and card.ability.name == 'Hit the Road' then
                        card.ability.x_mult = card.ability.x_mult or 1
                        card.ability.extra = card.ability.extra or 0.04
                    end
                end
            end
            if G.localization and G.localization.descriptions and G.localization.descriptions.Joker then
                G.localization.descriptions.Joker.j_hit_the_road = {
                    name = 'Hit the Road',
                    text = center.loc_txt.text
                }
            end
        end)
    end

end