return function(center)

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Showman'
    center.loc_txt.text = {
        '{C:attention}Joker{}, {C:tarot}Tarot{}, {C:planet}Planet{},',
        'and {C:spectral}Spectral{} cards may',
        'appear multiple times',
        '{C:legendary}Legendary{} Jokers can appear',
        'in the shop with a very low chance'
    }

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_ring_master then
        G.localization.descriptions.Joker.j_ring_master.text = center.loc_txt.text
    end

    if not rawget(_G,'VP_RING_MASTER_PATCHED') and rawget(_G, 'create_card') then
        local _orig_create_card = create_card
        function create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
            if not legendary and _type == 'Joker' then
                local in_shop = (rawget(_G,'G') and ((area == G.shop_jokers) or (key_append == 'sho'))) or (key_append == 'sho')
                local has_showman = rawget(_G,'find_joker') and next(find_joker('Showman'))
                if in_shop and has_showman then
                    local ante = (rawget(_G,'G') and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante) or 0
                    local shop_count = (rawget(_G,'G') and G.shop_jokers and G.shop_jokers.cards and #G.shop_jokers.cards) or 0
                    local roll = pseudorandom(pseudoseed('ring_leg'..ante..':'..shop_count))
                    if roll > 1 - 0.0015 then
                        legendary = true
                    end
                end
            end
            return _orig_create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
        end
        _G.VP_RING_MASTER_PATCHED = true
    end

end