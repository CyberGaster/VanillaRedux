return function(center)
    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'The Hermit'
    center.loc_txt.text = {
        'Doubles money',
        '{C:inactive}(Max of {C:money}$25{C:inactive})',
    }

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Tarot and G.localization.descriptions.Tarot.c_hermit then
        G.localization.descriptions.Tarot.c_hermit.text = center.loc_txt.text
    end

    if center.config then
        center.config.extra = 25
    end
end
