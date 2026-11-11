local function pack_is_open()
    local state, states = G.STATE, G.STATES
    return state == states.TAROT_PACK or state == states.SPECTRAL_PACK
        or (states.SMODS_BOOSTER_OPENED ~= nil and state == states.SMODS_BOOSTER_OPENED)
end

SMODS.Consumable:take_ownership('c_wheel_of_fortune', {
    loc_txt = {
        name = 'The Wheel of Fortune',
        text = {
            '{C:green}#1# in #2#{} chance to add',
            '{C:dark_edition}Foil{}, {C:dark_edition}Holographic{}, {C:dark_edition}Polychrome{},',
            'or {C:dark_edition}Negative{} edition to a random {C:attention}Joker',
        }
    },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(card, 1, card.ability.extra or 4, 'vr_wheel_of_fortune')
        return { vars = { numerator, denominator } }
    end,
    use = function(self, card, area, copier)
        local eligible = {}
        for _, v in ipairs(G.jokers.cards) do
            if v.ability and v.ability.set == 'Joker' and (not v.edition) then
                eligible[#eligible + 1] = v
            end
        end

        local roll = SMODS.pseudorandom_probability(card, 'wheel_of_fortune', 1, card.ability.extra or 4, 'vr_wheel_of_fortune')

        if #eligible > 0 and roll then
            local target = pseudorandom_element(eligible, pseudoseed('wheel_of_fortune'))
            local r = pseudorandom('wheel_of_fortune_edition')
            local edition
            if r < 0.40 then
                edition = {foil = true}
            elseif r < 0.70 then
                edition = {holo = true}
            elseif r < 0.90 then
                edition = {polychrome = true}
            else
                edition = {negative = true}
            end

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.4,
                func = function()
                    target:set_edition(edition, true)
                    if check_for_unlock then check_for_unlock({type = 'have_edition'}) end
                    card:juice_up(0.3, 0.5)
                    return true
                end
            }))
        else
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.4,
                func = function()
                    attention_text({
                        text = localize('k_nope_ex'),
                        scale = 1.3,
                        hold = 1.4,
                        major = card,
                        backdrop_colour = G.C.SECONDARY_SET.Tarot,
                        align = pack_is_open() and 'tm' or 'cm',
                        offset = {x = 0, y = pack_is_open() and -0.2 or 0},
                        silent = true
                    })
                    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.06*G.SETTINGS.GAMESPEED, blockable = false, blocking = false, func = function()
                        play_sound('tarot2', 0.76, 0.4); return true end}))
                    play_sound('tarot2', 1, 0.4)
                    card:juice_up(0.3, 0.5)
                    return true
                end
            }))
        end
        delay(0.6)
    end,
})