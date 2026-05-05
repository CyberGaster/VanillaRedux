local function is_number_card(card)
    if not card or not card.base then return false end
    local rank_id = card.base.id
    return rank_id and rank_id >= 2 and rank_id <= 10
end

local function is_face_card(card)
    if not card or not card.base then return false end
    local rank_id = card.base.id
    return rank_id == 11 or rank_id == 12 or rank_id == 13
end

local function active_faceless()
    if G and G.jokers and G.jokers.cards then
        for i = 1, #G.jokers.cards do
            local joker = G.jokers.cards[i]
            if joker and joker.config and joker.config.center and joker.config.center.key == 'j_faceless' and not joker.debuff then
                return joker
            end
        end
    end
    return nil
end

if not rawget(_G, 'VR_FACELESS_DEBUFF') then
    _G.VR_FACELESS_DEBUFF = true
    if rawget(_G, 'Blind') and Blind.debuff_card then
        local _original_debuff_card = Blind.debuff_card
        Blind.debuff_card = function(self, c, from_blind)
            _original_debuff_card(self, c, from_blind)
            local faceless = active_faceless()
            if faceless and c and c.area ~= G.jokers and is_face_card(c) then
                c:set_debuff(true)
            end
        end
    end
end

SMODS.Joker:take_ownership('faceless', {
    loc_txt = {
        name = "Faceless Joker",
        text = {
            "All {C:attention}face cards{} are {C:attention}debuffed{}",
            "Retrigger every {C:attention}3rd{} scored",
            "{C:attention}number card{} in a round",
            "{C:inactive}(Currently {C:attention}#1#/3{C:inactive})"
        }
    },
    cost = 5,
    rarity = 2,
    blueprint_compat = true,
    config = { extra = { num_played = 0 } },
    loc_vars = function(self, info_queue, card)
        local num_played = 0
        if card and card.ability and card.ability.extra then
            num_played = card.ability.extra.num_played or 0
        end
        return { vars = { num_played % 3 } }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and context.other_card then
            local played_card = context.other_card
            if is_number_card(played_card) and not played_card.debuff then
                if not context.blueprint_card then
                    card.ability.extra.num_played = (card.ability.extra.num_played or 0) + 1
                end
                if card.ability.extra.num_played % 3 == 0 then
                    return {
                        message = localize('k_again_ex'),
                        repetitions = 1,
                        card = card
                    }
                end
            end
        end

        if context.end_of_round and not context.repetition and not context.individual then
            if not context.blueprint then
                card.ability.extra.num_played = 0
            end
        end
    end,
    set_ability = function(self, card, initial, delay_sprites)
        card.ability.extra = card.ability.extra or {}
        card.ability.extra.num_played = card.ability.extra.num_played or 0
        if initial and G and G.GAME and G.GAME.blind and G.playing_cards then
            for _, v in ipairs(G.playing_cards) do
                G.GAME.blind:debuff_card(v)
            end
            if G.hand and G.hand.cards then
                for _, v in ipairs(G.hand.cards) do
                    G.GAME.blind:debuff_card(v)
                end
            end
        end
    end,
})
