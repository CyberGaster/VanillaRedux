return function(center)
    if center then center.mod = nil; center.mod_id = nil; center.modded = false; center.no_mod_display = true end
    
    local function is_owned_joker(card)
        if not rawget(_G,'G') or not G.jokers or not G.jokers.cards then return false end
        for i = 1, #G.jokers.cards do
            if G.jokers.cards[i] == card then return true end
        end
        return false
    end

    local function throwback_new_calculate(card, context)
        if not card or card.debuff then return nil end
        card.ability = card.ability or {}
        card.ability.throwback = card.ability.throwback or { owned_skips = 0 }
        
        if not card.ability.extra then
            card.ability.extra = 0.25
        end
        
        if context and context.joker_main then
            local skips = G.GAME and G.GAME.skips or 0
            local base_mult = card.ability.extra or 0.25
            local owned_skips = (card.ability.throwback and card.ability.throwback.owned_skips) or 0
            local total_mult = 1 + base_mult*skips + base_mult*owned_skips
            return {
                Xmult_mod = total_mult,
                message = localize{type='variable', key='a_xmult', vars={total_mult}},
                colour = G.C.MULT,
                card = card
            }
        end

        if context and context.skip_blind then
            local key = (card and card.uuid) or (card and card.config and card.config.center and card.config.center.key) or 'j_throwback'
            G.PERSIST_THROWBACK = G.PERSIST_THROWBACK or {}
            G.PERSIST_THROWBACK[key] = (G.PERSIST_THROWBACK[key] or 0) + (is_owned_joker(card) and 1 or 0)
            if is_owned_joker(card) then
                card.ability.throwback.owned_skips = (card.ability.throwback.owned_skips or 0) + 1
            end
            return nil
        end
        
        return nil
    end
    
    local function patch_update_for_throwback()
        if rawget(_G, 'VP_THROWBACK_UPDATE_PATCHED') then return end
        if rawget(_G, 'Card') and Card.update then
            local old_update = Card.update
            function Card:update(dt)
                local result = old_update(self, dt)
                if self and self.config and self.config.center and self.config.center.key == 'j_throwback' then
                    if self.config and self.config.center then
                        self.config.center.mod = nil
                        self.config.center.mod_id = nil
                        self.config.center.modded = false
                        self.config.center.no_mod_display = true
                    end
                    local skips = (rawget(_G,'G') and G.GAME and G.GAME.skips) or 0
                    self.ability = self.ability or {}
                    self.ability.throwback = self.ability.throwback or { owned_skips = 0 }
                    local owned_skips = self.ability.throwback.owned_skips or 0
                    local key = (self and self.uuid) or (self and self.config and self.config.center and self.config.center.key) or 'j_throwback'
                    if rawget(_G,'G') and G.PERSIST_THROWBACK and G.PERSIST_THROWBACK[key] then
                        owned_skips = math.max(owned_skips, G.PERSIST_THROWBACK[key])
                        self.ability.throwback.owned_skips = owned_skips
                    end
                    self.ability = self.ability or {}
                    self.ability.extra = 0.25
                    local bonus = 0.25*owned_skips
                    self.ability.x_mult = 1 + 0.25*skips + bonus
                end
                return result
            end
            _G.VP_THROWBACK_UPDATE_PATCHED = true
        end
    end

    local function patch_calculate_for_throwback()
        if rawget(_G,'VP_THROWBACK_CALC_PATCHED') then return end
        if rawget(_G,'Card') and Card.calculate_joker then
            local base_calculate = Card.calculate_joker
            function Card:calculate_joker(context)
                if self and self.config and self.config.center and self.config.center.key == 'j_throwback' then
                    return throwback_new_calculate(self, context)
                end
                return base_calculate(self, context)
            end
            _G.VP_THROWBACK_CALC_PATCHED = true
        end
    end

    if SMODS and SMODS.Joker then
        patch_update_for_throwback()
        patch_calculate_for_throwback()
        SMODS.Joker:take_ownership('throwback', {
            no_mod_display = true,
            loc_txt = {
                name = "Throwback",
                text = {
                    '{X:mult,C:white}X#1#{} Mult for each',
                    'Blind skipped this run',
                    '{X:mult,C:white}X#2#{} Mult if Joker in hand',
                    '{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult)'
                }
            },
            config = {extra = 0.25},
            pos = {x = 5, y = 7},
            rarity = 2,
            cost = 6,
            unlocked = true,
            discovered = true,
            blueprint_compat = true,
            eternal_compat = true,
            perishable_compat = true,
            loc_vars = function(self, info_queue, card)
                local skips = (G and G.GAME and G.GAME.skips) or 0
                local base_mult = 0.25
                local current_mult = 1
                
                if skips > 0 then
                    local owned_skips = 0
                    if card and card.ability and card.ability.throwback then
                        owned_skips = card.ability.throwback.owned_skips or 0
                    end
                    local key = (card and card.uuid) or (card and card.config and card.config.center and card.config.center.key) or 'j_throwback'
                    if rawget(_G,'G') and G.PERSIST_THROWBACK and G.PERSIST_THROWBACK[key] then
                        owned_skips = math.max(owned_skips, G.PERSIST_THROWBACK[key])
                    end
                    local owned_bonus = base_mult * owned_skips
                    current_mult = 1 + base_mult*skips + owned_bonus
                end
                
                return {
                    vars = {
                        base_mult,
                        base_mult * 2,
                        current_mult
                    }
                }
            end
        })
        
        if SMODS.Hook then
            SMODS.Hook.add('post_game_init', function()
                if G.P_CENTERS and G.P_CENTERS.j_throwback then
                    local c = G.P_CENTERS.j_throwback
                    c.mod = nil; c.mod_id = nil; c.modded = false; c.discovered = true; c.no_mod_display = true
                end
                if G.localization and G.localization.descriptions and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_throwback then
                    G.localization.descriptions.Joker.j_throwback.text = {
                        '{X:mult,C:white}X#1#{} Mult for each',
                        'Blind skipped this run',
                        '{X:mult,C:white}X#2#{} Mult if Joker in hand',
                        '{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult)'
                    }
                end
            end)
        end
    end
end