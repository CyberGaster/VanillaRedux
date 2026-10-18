local FIB_MULT = 21
local FIB_RANKS = { [14] = true, [2] = true, [3] = true, [5] = true, [8] = true, [13] = true }

SMODS.Joker:take_ownership('fibonacci', {
    loc_txt = {
        name = 'Fibonacci',
        text = {
            'Played {C:attention}Ace{}, {C:attention}2{}, {C:attention}3{}, {C:attention}5{}, {C:attention}8{},',
            'or {C:attention}King{} give {C:mult}+#1#{} Mult when scored',
        }
    },
    config = { extra = FIB_MULT },
    loc_vars = function(self, info_queue, card)
        return { vars = { FIB_MULT } }
    end,
    blueprint_compat = true,
})

if not rawget(_G, 'VP_FIB_OVERRIDE') and rawget(_G, 'Card') and Card.calculate_joker then
    local old_calculate_joker = Card.calculate_joker
    function Card:calculate_joker(context)
        if self.ability and self.ability.name == 'Fibonacci' and not self.debuff then
            if context and context.individual and context.cardarea == G.play
               and context.other_card and not context.other_card.debuff then
                local cid = context.other_card:get_id()
                if FIB_RANKS[cid] then
                    local src = (context.blueprint_card or self)
                    src.ability = src.ability or {}
                    local round_id = tostring((G and G.GAME and G.GAME.round) or 0)
                    local hand_id = tostring((G and G.GAME and G.GAME.current_round
                        and G.GAME.current_round.hands_played) or 0)
                    local mark = round_id .. '_' .. hand_id
                    if src.ability._vp_fib_mark ~= mark then
                        src.ability._vp_fib_mark = mark
                        src.ability._vp_fib_seen = {}
                    end
                    local seen = src.ability._vp_fib_seen or {}
                    if not seen[cid] then
                        seen[cid] = true
                        src.ability._vp_fib_seen = seen
                        return {
                            mult = FIB_MULT,
                            card = src
                        }
                    end
                end
            end
            return nil
        end
        return old_calculate_joker(self, context)
    end
    _G.VP_FIB_OVERRIDE = true
end