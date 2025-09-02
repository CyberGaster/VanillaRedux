return function(center)

    center.config = {extra = {chips = 0, chip_mod = 15}}
    center.rarity = 1
    center.cost = 5
    center.discovered = true

    center.loc_txt = {
        name = 'Runner',
        text = {
            'Get {C:chips}+#2#{} chips if played',
            'hand contains a {C:attention}Straight{}',
            'Joker gains {C:chips}+5{} Chips for',
            'each next played {C:attention}Straight{}',
            '{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)'
        }
    }

    center.loc_vars = function(self, info_queue, card)
        local chips = 0
        local chip_mod = 15
        
        if card and card.ability and card.ability.extra then
            chips = card.ability.extra.chips or 0
            chip_mod = card.ability.extra.chip_mod or 15
        end
        
        return { vars = { chips, chip_mod } }
    end

    local original_set_ability = center.set_ability
    center.set_ability = function(self, card, initial, delay_sprites)
        if original_set_ability then
            original_set_ability(self, card, initial, delay_sprites)
        end
        
        card.ability = card.ability or {}
        card.ability.extra = card.ability.extra or {}
        card.ability.extra.chips = card.ability.extra.chips or 0
        card.ability.extra.chip_mod = card.ability.extra.chip_mod or 15
        card.ability.extra.straights_played = card.ability.extra.straights_played or 0
    end

    local orig_update = center.update
    center.update = function(self, card, dt)
        if orig_update then orig_update(self, card, dt) end
        if card and card.ability and card.ability.extra then
            card.ability.extra.chip_mod = 15 + (card.ability.extra.straights_played or 0) * 5
        end
    end

    if not rawget(_G,'VP_RUNNER_BLOCKED') and rawget(_G,'Card') and Card.calculate_joker then
        local old_calculate_joker = Card.calculate_joker
        function Card:calculate_joker(context)
            if self.ability and self.ability.name == 'Runner' and not self.debuff 
               and context and context.cardarea == G.jokers then
               
                self.ability.extra = self.ability.extra or {}
                self.ability.extra.chips = self.ability.extra.chips or 0
                self.ability.extra.chip_mod = self.ability.extra.chip_mod or 15
                self.ability.extra.straights_played = self.ability.extra.straights_played or 0

                local has_straight = context.poker_hands and context.poker_hands['Straight'] and next(context.poker_hands['Straight'])
                
                if context.before and has_straight and not context.blueprint then
                    self.ability.extra.straights_played = self.ability.extra.straights_played + 1
                    local chips_to_add = 15 + (self.ability.extra.straights_played - 1) * 5
                    self.ability.extra.chips = self.ability.extra.chips + chips_to_add
                    self.ability.extra.chip_mod = 15 + self.ability.extra.straights_played * 5
                    
                    return {
                        message = localize('k_upgrade_ex'),
                        colour = G.C.CHIPS,
                        card = self
                    }
                elseif context.joker_main and has_straight and self.ability.extra.chips > 0 then
                    return {
                        chip_mod = self.ability.extra.chips,
                        message = localize{type='variable', key='a_chips', vars={self.ability.extra.chips}}
                    }
                end
                
                return nil
            end
            
            return old_calculate_joker(self, context)
        end
        _G.VP_RUNNER_BLOCKED = true
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_runner then
        G.localization.descriptions.Joker.j_runner.text = center.loc_txt.text
    end

    if SMODS and SMODS.Hook then
        SMODS.Hook.add('post_game_init', function()
            if G.jokers and G.jokers.cards then
                for i = 1, #G.jokers.cards do
                    local card = G.jokers.cards[i]
                    if card.ability and card.ability.name == 'Runner' then
                        card.ability.extra = card.ability.extra or {}
                        card.ability.extra.chips = card.ability.extra.chips or 0
                        card.ability.extra.chip_mod = card.ability.extra.chip_mod or 15
                        card.ability.extra.straights_played = card.ability.extra.straights_played or 0
                        card.ability.extra.chip_mod = 15 + card.ability.extra.straights_played * 5
                    end
                end
            end
            
            if G.localization and G.localization.descriptions and G.localization.descriptions.Joker then
                G.localization.descriptions.Joker.j_runner = {
                    name = "Runner",
                    text = center.loc_txt.text
                }
            end
        end)
    end
end