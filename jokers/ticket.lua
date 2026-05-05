SMODS.Joker:take_ownership('ticket', {
    loc_txt = {
        name = 'Golden Ticket',
        text = {
            'Played {C:attention}Gold{} cards',
            'earn {C:money}$#1#{} when scored',
            'Gold cards held in hand',
            'give {C:money}$#2#{} more at end of round'
        }
    },
    config = { extra = 5 },
    set_ability = function(self, card, initial, delay_sprites)
        card.ability.eor_bonus = card.ability.eor_bonus or 2
    end,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra, card.ability.eor_bonus or 2 } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card and context.other_card.ability and context.other_card.ability.name == 'Gold Card' then
                return { dollars = card.ability.extra }
            end
            return {}
        end
    end,
    blueprint_compat = true,
})

if not rawget(_G, 'VP_TICKET_EOR_PATCHED') then
    local orig_get_eor = Card.get_end_of_round_effect
    Card.get_end_of_round_effect = function(self, context)
        local ret = orig_get_eor(self, context) or {}
        if self.ability and self.ability.name == 'Gold Card' and ret.h_dollars and ret.h_dollars > 0 then
            if G.jokers and G.jokers.cards then
                local bonus = 0
                for i = 1, #G.jokers.cards do
                    local jk = G.jokers.cards[i]
                    if jk and not jk.debuff then
                        if jk.config.center.key == 'j_ticket' then
                            bonus = bonus + (jk.ability.eor_bonus or 2)
                        elseif jk.config.center.key == 'j_blueprint' then
                            local right = G.jokers.cards[i + 1]
                            if right and not right.debuff and right.config.center.key == 'j_ticket' then
                                bonus = bonus + (right.ability.eor_bonus or 2)
                            end
                        elseif jk.config.center.key == 'j_brainstorm' then
                            local left = G.jokers.cards[1]
                            if left and not left.debuff and left.config.center.key == 'j_ticket' then
                                bonus = bonus + (left.ability.eor_bonus or 2)
                            end
                        end
                    end
                end
                if bonus > 0 then
                    ret.h_dollars = ret.h_dollars + bonus
                end
            end
        end
        return ret
    end
    _G.VP_TICKET_EOR_PATCHED = true
end