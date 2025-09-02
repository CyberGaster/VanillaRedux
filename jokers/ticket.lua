return function(center)

    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Golden Ticket'
    center.loc_txt.text = {
        'Played {C:attention}Gold{} cards',
        'earn {C:money}$#1#{} when scored',
        'Gold cards held in hand',
        'give {C:money}$2{} more at end of round'
    }

    if rawget(_G, 'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_ticket then
        G.localization.descriptions.Joker.j_ticket.text = center.loc_txt.text
    end

    center.config = center.config or {}
    center.config.extra = 5

    center.loc_vars = function(self, info_queue, card)
        local payout = 5
        if card and card.ability and card.ability.extra then payout = card.ability.extra end
        return { vars = { payout } }
    end

    if not rawget(_G, 'VP_TICKET_EOR_PATCHED') and rawget(_G, 'Card') and Card.get_end_of_round_effect then
        local orig_get_end_of_round_effect = Card.get_end_of_round_effect
        Card.get_end_of_round_effect = function(self, context)
            local ret = orig_get_end_of_round_effect and orig_get_end_of_round_effect(self, context) or {}
            if self and self.ability and self.ability.name == 'Gold Card' and ret and ret.h_dollars and ret.h_dollars > 0 then
                local has_ticket = false
                if rawget(_G, 'G') and G.jokers and G.jokers.cards then
                    for i = 1, #G.jokers.cards do
                        local jk = G.jokers.cards[i]
                        if jk and jk.ability and jk.ability.name == 'Golden Ticket' then
                            has_ticket = true; break
                        end
                    end
                end
                if has_ticket then
                    ret.h_dollars = ret.h_dollars + 2
                    ret.card = ret.card or self
                end
            end
            return ret
        end
        _G.VP_TICKET_EOR_PATCHED = true
    end

    if not rawget(_G, 'VP_TICKET_UPDATE_PATCHED') and rawget(_G, 'Card') and Card.update then
        local orig_update = Card.update
        Card.update = function(self, dt)
            if orig_update then orig_update(self, dt) end
            if self and self.ability and self.ability.name == 'Golden Ticket' then
                self.ability.extra = 5
            end
        end
        _G.VP_TICKET_UPDATE_PATCHED = true
    end
end