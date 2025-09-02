local function init_constellation_global()
    if G.GAME then
        G.GAME.constellation_planets_used = G.GAME.constellation_planets_used or 0
    end
end

local function get_constellation_planets()
    if G.GAME and G.GAME.constellation_planets_used then
        return G.GAME.constellation_planets_used
    end
    return 0
end

local function increment_constellation_planets()
    init_constellation_global()
    if G.GAME then
        G.GAME.constellation_planets_used = (G.GAME.constellation_planets_used or 0) + 1
        return G.GAME.constellation_planets_used
    end
    return 0
end

return function(center)
    if not rawget(_G,'CONSTELLATION_GLOBAL_PATCHED') then
        _G.CONSTELLATION_GLOBAL_PATCHED = true
        
        if rawget(_G,'set_consumeable_usage') then
            local old_set_consumeable_usage = set_consumeable_usage
            function set_consumeable_usage(card)
                local result = old_set_consumeable_usage(card)
                
                if card and card.config and card.config.center and card.config.center.set == 'Planet' then
                    local new_count = increment_constellation_planets()
                    
                    if G.jokers and G.jokers.cards then
                        for i = 1, #G.jokers.cards do
                            local joker = G.jokers.cards[i]
                            if joker.ability and joker.ability.name == 'Constellation' and not joker.debuff then
                                joker.ability.x_mult = 1 + (new_count * 0.05)
                            end
                        end
                    end
                    
                    if G.shop_jokers and G.shop_jokers.cards then
                        for i = 1, #G.shop_jokers.cards do
                            local joker = G.shop_jokers.cards[i]
                            if joker.ability and joker.ability.name == 'Constellation' then
                                joker.ability.x_mult = 1 + (new_count * 0.05)
                            end
                        end
                    end
                end
                
                return result
            end
        end
    end

    SMODS.Joker:take_ownership('constellation', {
        loc_txt = {
            name = "Constellation",
            text = {
                "This Joker gains {X:mult,C:white}X0.05{} Mult",
                "every time a {C:planet}Planet{} card",
                "is used in this run",
                "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)"
            }
        },
        
        config = {
            extra = 0.05,
            Xmult = 1
        },
        
        rarity = 3,    
        cost = 8,      
        
        loc_vars = function(self, info_queue, card)
            local planets_used = get_constellation_planets()
            local x_mult = 1 + (planets_used * 0.05)
            
            if card and card.ability then
                card.ability.x_mult = x_mult
            end
            
            return { vars = { x_mult } }
        end,
        
        calculate = function(self, card, context)
            init_constellation_global()
            
            local planets_used = get_constellation_planets()
            card.ability.x_mult = 1 + (planets_used * 0.05)
            
            if context.joker_main then  
                if card.ability.x_mult and card.ability.x_mult > 1 then
                    return {
                        message = localize{type='variable',key='a_xmult',vars={card.ability.x_mult}},
                        Xmult_mod = card.ability.x_mult
                    }
                end
            end
            
            return nil
        end,
        
        set_ability = function(self, card, initial, delay_sprites)
            if self.set_ability_base then 
                self.set_ability_base(self, card, initial, delay_sprites) 
            end
            
            init_constellation_global()
            local planets_used = get_constellation_planets()
            card.ability.x_mult = 1 + (planets_used * 0.05)
        end
    })
    
    if SMODS and SMODS.Hook then
        SMODS.Hook.add('post_game_init', function()
            if G.P_CENTERS.j_constellation then
                G.P_CENTERS.j_constellation.mod = nil
                G.P_CENTERS.j_constellation.modded = false
                G.P_CENTERS.j_constellation.discovered = true
            end
        end)
    else
        if G.P_CENTERS.j_constellation then
            G.P_CENTERS.j_constellation.mod = nil
            G.P_CENTERS.j_constellation.modded = false
            G.P_CENTERS.j_constellation.discovered = true
        end
    end
end