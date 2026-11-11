-- The vanilla Green Joker (Mult per hand played and per discard) with its own values.
SMODS.Joker:take_ownership('green_joker', {
    config = { extra = { hand_add = 3, discard_sub = 3 } },
})
