local JACK_STEP = 0.1

SMODS.Joker:take_ownership('hit_the_road', {
    loc_txt = {
        name = 'Hit the Road',
        text = {
            'This Joker gains {X:mult,C:white} X#1# {} Mult',
            'for every {C:attention}Jack{} discarded,',
            '{E:2}resets{} when {C:attention}Boss Blind{} is defeated',
            '{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)',
        }
    },
    config = { extra = JACK_STEP },
    loc_vars = function(self, info_queue, card)
        local x = (card and card.ability and card.ability.x_mult) or 1
        return { vars = { JACK_STEP, x } }
    end,
    calculate = function(self, card, context)
        if context.discard and not context.blueprint then
            if context.other_card and not context.other_card.debuff
               and context.other_card:get_id() == 11 then
                SMODS.scale_card(card, {
                    ref_table = card.ability,
                    ref_value = 'x_mult',
                    scalar_table = { step = JACK_STEP },
                    scalar_value = 'step',
                    message_key = 'a_xmult',
                    message_colour = G.C.RED,
                    message_delay = 0.45,
                })
                return nil, true
            end
        end

        if context.end_of_round and not context.individual and not context.repetition then
            if context.main_eval and context.beat_boss and not context.blueprint
               and (card.ability.x_mult or 1) > 1 then
                SMODS.reset_card(card, {
                    ref_table = card.ability,
                    ref_value = 'x_mult',
                    reset_value = 1,
                    message_colour = G.C.RED,
                })
            end
            -- Returning a table stops the vanilla code, which would reset the Joker after every round.
            return {}
        end

        if context.joker_main then
            local x = card.ability.x_mult or 1
            if x > 1 then
                return { x_mult = x }
            end
            return {}
        end
    end,
})