return function(center)
center.loc_txt = center.loc_txt or {}
center.loc_txt.name = "Four Fingers"
center.loc_txt.text = {
    "All {C:attention}Flushes{} and {C:attention}Straights{}",
    "can be made with {C:attention}4{} cards",
    "{X:mult,C:white}X2{} Mult if played",
    "hand has {C:attention}5{} cards"
}

SMODS.Joker:take_ownership('four_fingers', {
    no_mod_display = true,
    loc_txt = { name = center.loc_txt.name, text = center.loc_txt.text },
    
    rarity = 1,
    cost = 5,
    
    config = {
        extra = {
            Xmult = 2  
        }
    },
    
    loc_vars = function(self, info_queue, card)
        return { vars = { card and card.ability and card.ability.extra and card.ability.extra.Xmult or 2 } }
    end,
    
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand then
            local played_cards = context.full_hand
            if played_cards and #played_cards == 5 then
                return {
                    message = localize{type='variable', key='a_xmult', vars={card.ability.extra.Xmult or 2}},
                    Xmult_mod = card.ability.extra.Xmult or 2,
                    card = card
                }
            end
        end
        return nil
    end
})

if SMODS and SMODS.Hook then
    SMODS.Hook.add('post_game_init', function()
        if G.P_CENTERS and G.P_CENTERS.j_four_fingers then
            G.P_CENTERS.j_four_fingers.mod = nil
            G.P_CENTERS.j_four_fingers.modded = false
            G.P_CENTERS.j_four_fingers.discovered = true
            G.P_CENTERS.j_four_fingers.blueprint_compat = true
        end
        if G.localization and G.localization.descriptions and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_four_fingers then
            G.localization.descriptions.Joker.j_four_fingers.name = center.loc_txt.name
            G.localization.descriptions.Joker.j_four_fingers.text = center.loc_txt.text
        end
    end)
else
    if rawget(_G,'G') then
        if G.P_CENTERS and G.P_CENTERS.j_four_fingers then
            G.P_CENTERS.j_four_fingers.mod = nil
            G.P_CENTERS.j_four_fingers.modded = false
            G.P_CENTERS.j_four_fingers.discovered = true
            G.P_CENTERS.j_four_fingers.blueprint_compat = true
        end
        if G.localization and G.localization.descriptions and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_four_fingers then
            G.localization.descriptions.Joker.j_four_fingers.name = center.loc_txt.name
            G.localization.descriptions.Joker.j_four_fingers.text = center.loc_txt.text
        end
    end
end

if not rawget(_G,'VP_FOUR_FINGERS_PATCHED') then
    if rawget(_G,'find_joker') then
        local orig_find_joker = find_joker
        function find_joker(name)
            if name == 'Four Fingers' then
                local ret = {}
                if rawget(_G,'G') and G.jokers and G.jokers.cards then
                    for i = 1, #G.jokers.cards do
                        local joker = G.jokers.cards[i]
                        if joker.config and joker.config.center and 
                           (joker.config.center.key == 'j_four_fingers' or 
                            (joker.ability and joker.ability.name == 'Four Fingers')) and 
                           not joker.debuff then
                            ret[#ret+1] = joker
                        end
                    end
                end
                return ret
            end
            return orig_find_joker(name)
        end
    end
    _G.VP_FOUR_FINGERS_PATCHED = true
end
end