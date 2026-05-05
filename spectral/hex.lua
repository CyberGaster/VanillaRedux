SMODS.Consumable:take_ownership('c_hex', {
    loc_txt = {
        name = 'Hex',
        text = {
            'Add {C:dark_edition}Polychrome{} to a',
            'random {C:attention}Joker{}, destroy',
            'a random {C:attention}Joker{}',
        }
    },
    use = function(self, card, area, copier)
        local pool = {}
        for _, v in ipairs(G.jokers.cards) do
            if not v.edition then pool[#pool + 1] = v end
        end
        local target = #pool > 0 and pseudorandom_element(pool, pseudoseed('hex_vr_target')) or nil

        local deletable = {}
        for _, v in ipairs(G.jokers.cards) do
            if not (v.ability and v.ability.eternal) then deletable[#deletable + 1] = v end
        end
        local to_destroy = nil
        if #deletable > 0 then
            to_destroy = pseudorandom_element(deletable, pseudoseed('hex_vr_destroy'))
            if target and to_destroy == target and #deletable > 1 then
                local alt = {}
                for _, v in ipairs(deletable) do if v ~= target then alt[#alt + 1] = v end end
                if #alt > 0 then to_destroy = pseudorandom_element(alt, pseudoseed('hex_vr_destroy2')) end
            end
        end

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                if target then
                    target:set_edition({polychrome = true}, true)
                    if check_for_unlock then check_for_unlock({type = 'have_edition'}) end
                end
                if to_destroy and to_destroy.area == G.jokers then
                    to_destroy:start_dissolve(nil, true)
                end
                return true
            end
        }))
    end,
})