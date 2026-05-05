SMODS.Consumable:take_ownership('c_ankh', {
    loc_txt = {
        name = 'Ankh',
        text = {
            'Create a copy of a',
            'random {C:attention}Joker{}, destroy',
            'a random {C:attention}Joker{}',
            '{C:inactive}(Removes {C:dark_edition}Negative{} {C:inactive}from copy){}',
        }
    },
    use = function(self, card, area, copier)
        local chosen_joker = (#G.jokers.cards > 0) and pseudorandom_element(G.jokers.cards, pseudoseed('ankh_choice_vr')) or nil

        local deletable = {}
        for _, v in ipairs(G.jokers.cards) do
            if not (v.ability and v.ability.eternal) then
                deletable[#deletable + 1] = v
            end
        end
        local to_destroy = nil
        if #deletable > 0 then
            to_destroy = pseudorandom_element(deletable, pseudoseed('ankh_destroy_vr'))
            if chosen_joker and to_destroy == chosen_joker and #deletable > 1 then
                local pool = {}
                for _, v in ipairs(deletable) do if v ~= chosen_joker then pool[#pool + 1] = v end end
                if #pool > 0 then to_destroy = pseudorandom_element(pool, pseudoseed('ankh_destroy_vr2')) end
            end
        end

        if to_destroy then
            G.E_MANAGER:add_event(Event({
                trigger = 'before',
                delay = 0.75,
                func = function()
                    if to_destroy and to_destroy.area and to_destroy.area == G.jokers then
                        to_destroy:start_dissolve(nil, true)
                    end
                    return true
                end
            }))
        end

        if chosen_joker then
            G.E_MANAGER:add_event(Event({
                trigger = 'before',
                delay = 0.4,
                func = function()
                    local c = copy_card(chosen_joker, nil, nil, nil, chosen_joker.edition and chosen_joker.edition.negative)
                    c:start_materialize()
                    c:add_to_deck()
                    if c.edition and c.edition.negative then
                        c:set_edition(nil, true)
                    end
                    G.jokers:emplace(c)
                    return true
                end
            }))
        end
    end,
})